 /** ******************************************************************
 *  This is a monitor component, its job is to simply watch a bus and report
 *  what is going on. Unlike the master and slave components it does not play
 *  an active role in the bus protocol, it simply watches what is happening.
 *  The monitor component connects to a signal level SystemVerilog interface
 *  (in this case AXI), monitors activity on the signals, and constructs high
 *  level transactions on a second SystemVerilog interface (basically
 *  read and write operations). This high level interface can then be watched
 *  by the test (or by a scoreboard, or a coverage collector) to check what
 *  is going on on the bus, without having to deal with the low level
 *  protocol of read-address-phase, read-data=phase, etc..
 *  ***************************************************************** */

 /** ******************************************************************
 *  The high level systemVerilog Interface.
 *  Consists of a detected Read/Write transfer plus a newSample event which triggers
 *  whenever new data is placed on the interface (allowing whoever is listening to the
 *  interface (test/scoreboard/coverage collector) to know that the data has been updated).
 *  ***************************************************************** */
interface mon_if #(int ADDR_WIDTH = 32,
                   int RDATA_WIDTH = 32,
                   int WDATA_WIDTH = 32,
                   int ID_WIDTH = 1,
                   int USER_WIDTH = 1,
                   int REGION_MAP_SIZE = 16)();
   import uvm_pkg::*;
   import mvc_pkg::*;
   import mgc_axi4_v1_0_pkg::*;
   bit readNotWrite;
   bit [(ADDR_WIDTH-1):0]  addr;
   bit [(RDATA_WIDTH-1):0] rdata [];
   bit [(WDATA_WIDTH-1):0] wdata [];
   bit [(((WDATA_WIDTH / 8)) - 1):0] write_strobes [];
   bit [7:0] burst_length;
   bit [1:0] resp [];
   // Add others here, burst, id, cache, qos, lock, as required
   event newSample;
   // Just for debug - Gives visibility of one item in read/write arrays
   bit [(RDATA_WIDTH-1):0] rdata0;
   bit [(WDATA_WIDTH-1):0] wdata0;
   bit [(((WDATA_WIDTH / 8)) - 1):0] write_strobes0;
   bit [1:0] resp0;
   always @newSample begin
     rdata0 = rdata[0];
     wdata0 = wdata[0];
     write_strobes0 = write_strobes[0];
     resp0 = resp[0];
   end
   // end of Just for debug section
endinterface : mon_if

/** ******************************************************************
 *  The monitor module is a bridge between the pin level AXI4 interface and the high level
 *  interface, it wraps the uvm environment so the listener class described above is not
 *  visible outside this monitor.
 *  ***************************************************************** */
module mentor_qvip_api_axi4_monitor #(int ADDR_WIDTH = 32,
                                      int RDATA_WIDTH = 32,
                                      int WDATA_WIDTH = 32,
                                      int ID_WIDTH = 1,
                                      int USER_WIDTH = 1,
                                      int REGION_MAP_SIZE = 16) (interface AXI4,
                                                                 interface MON);

import uvm_pkg::*;
import mvc_pkg::*;
import mgc_axi4_v1_0_pkg::*;
`include "uvm_macros.svh"

/** ******************************************************************
 *  Default values.
 *  In the case of the monitor model just the names
 *  ***************************************************************** */
string m_name = $sformatf("%m:");
string cg_name = remove_dots($sformatf("%m_cg"));

/** ******************************************************************
 *  uvm Elements.
 *  A single axi4 read/write sequence which responds to AXI4
 *  transactions on the bus by storing Writes in a memory and providing
 *  the appropriate response when asked for a read.
 *  Also the Questa VIP AXI 4 Agent, and the configuration object.
 *  ***************************************************************** */
typedef axi4_master_rw_transaction #(ADDR_WIDTH,
                                     RDATA_WIDTH,
                                     WDATA_WIDTH,
                                     ID_WIDTH,
                                     USER_WIDTH,
                                     REGION_MAP_SIZE) item_t;

typedef axi4_vip_config #(ADDR_WIDTH,
                          RDATA_WIDTH,
                          WDATA_WIDTH,
                          ID_WIDTH,
                          USER_WIDTH,
                          REGION_MAP_SIZE) cfg_t;

/** ******************************************************************
 *  The listener class
 *     An uvm component called a listener, who's job it is to watch for new
 *     data detected in the class based environment and write it out to the
 *     SystemVerilog interface
 *  ***************************************************************** */
class axi_listener extends uvm_subscriber #(mvc_sequence_item_base);
  `uvm_component_utils(axi_listener)
  item_t axi_rw_trans;
  virtual mon_if vif;
  function new( string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  //function void build();
  //  super.build();
  //  vif.sampleNow = 0;
  //endfunction
  virtual function void write (mvc_sequence_item_base t);
    if (!$cast(axi_rw_trans, t))
       $display("ERROR: %s Unexpected type sent to listener", m_name);
    vif.addr = axi_rw_trans.addr;
    if (axi_rw_trans.read_or_write == AXI4_TRANS_READ) begin
      vif.readNotWrite = 1'b1;
      vif.rdata = axi_rw_trans.rdata_words;
      end
    else begin
      vif.readNotWrite = 1'b0;
      vif.wdata = axi_rw_trans.wdata_words;
      vif.write_strobes = axi_rw_trans.write_strobes;
      end
    vif.burst_length = axi_rw_trans.burst_length;
    foreach(axi_rw_trans.resp[i]) begin
      case (axi_rw_trans.resp[i])
        AXI4_OKAY   : vif.resp[i] = 2'b00;
        AXI4_EXOKAY : vif.resp[i] = 2'b01;
        AXI4_SLVERR : vif.resp[i] = 2'b10;
        AXI4_DECERR : vif.resp[i] = 2'b11;
      endcase
    end
    -> vif.newSample;  // Trigger the new event
  endfunction
endclass: axi_listener

/** ******************************************************************
 *  The env class 
 *     An uvm wrapper class that simply creates and connects the above
 *     listener to the existing uvm agent.
 *  ***************************************************************** */
class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  mvc_agent axi4_agent;
  axi_listener axi4_listen;
  virtual mon_if vif;
  cfg_t axi4_cfg;
  function new( string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build();
    axi4_agent  = new($sformatf("%m.axi4_agent"), this);
    axi4_agent.set_mvc_config(axi4_cfg);
    axi4_listen = new($sformatf("%m.axi4_listener"), this);
  endfunction
  function void connect_phase(uvm_phase phase);
  uvm_connect_phase::get().raise_objection( null , "prevent early termination" );
    super.connect();
    axi4_listen.vif = vif;
    axi4_agent.ap["trans_ap"].connect(axi4_listen.analysis_export);
  endfunction
endclass: axi_env

axi_env axi4_env;
cfg_t axi4_monitor_cfg;

/** ******************************************************************
 *  Initial Block - Gets run once at the start of simulation.
 *  Constructs a configuration object, puts a handle to the AXI bus
 *  into the configuration object and calls the task to set configs.
 *  Then Constructs the above environment, which is a combination of
 *  the Mentor AXI4 Agent and the above listener block, and passes it
 *  the handle to the high level interface called MON which is passed
 *  to us as a parameter at the top of this file from the testbench.
 *  ***************************************************************** */
initial begin
  uvm_connect_phase::get().raise_objection( null , "prevent early termination" );
  axi4_monitor_cfg = new("axi_monitor_cfg");
  axi4_monitor_cfg.m_bfm = AXI4;
  configure_axi4_monitor;
  axi4_env = new($sformatf("%m.axi4_env"), uvm_top);
  axi4_env.axi4_cfg = axi4_monitor_cfg;
  axi4_env.vif = MON; 
end

/** ******************************************************************
 *  Task Configure_AXI4_Monitor.
 *  Configures the Mentor AXI4 VIP
 *  This is a monitor block, it watches activity on the bus but does not
 *  contribute to the protocol either as a master or as a slave, therefore
 *  both master and slave VIP abstration_level are OFF (1,0) as are the
 *  built in clock generator and the reset source capabilities.
 *  The built in transaction checker keeps a log of all writes we make
 *  to the bus throws an error if subsequent reads fail to match, this
 *  is obviously not applicable in the case where we are watching the
 *  bus and not contributing, so the trans_ap checker is turned off.
 *  ***************************************************************** */
function void configure_axi4_monitor (bit coverage = 1);
  axi4_monitor_cfg.m_bfm.axi4_set_master_abstraction_level(1,0);
  axi4_monitor_cfg.m_bfm.axi4_set_slave_abstraction_level(1,0);
  axi4_monitor_cfg.m_bfm.axi4_set_clock_source_abstraction_level(1,0);
  axi4_monitor_cfg.m_bfm.axi4_set_reset_source_abstraction_level(1,0);
  axi4_monitor_cfg.m_bfm.set_config_enable_region_support(1'b0);
  axi4_monitor_cfg.m_bfm.set_config_enable_errors(1'b1);
  axi4_monitor_cfg.m_warn_on_uninitialized_read = 1'b0;

  axi4_monitor_cfg.delete_analysis_component("trans_ap","checker");
  if (coverage) begin
    axi4_monitor_cfg.set_analysis_component("", cg_name,
     axi4_coverage#(ADDR_WIDTH,
                    RDATA_WIDTH,
                    WDATA_WIDTH,
                    ID_WIDTH,
                    USER_WIDTH,
                    REGION_MAP_SIZE)::type_id::get());
    end
endfunction: configure_axi4_monitor

/** ******************************************************************
 *  Function remove_dots.
 *  Reformats the unique path to replace dots in CG name with underscores
 *  ***************************************************************** */
function string remove_dots(string s);
  int i;
  string rtn;
  rtn = s;
  for (i=0; i<s.len(); i++) begin
    if ((s.getc(i) == ".")||(s.getc(i) == ":")) begin
      rtn.putc(i,"_");
      end
    end
  return rtn;
endfunction: remove_dots

endmodule: mentor_qvip_api_axi4_monitor
