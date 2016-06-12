module mentor_qvip_api_axi4_master #(int ADDRESS_WIDTH = 32,
                                     int RDATA_WIDTH = 32,
                                     int WDATA_WIDTH = 32,
                                     int ID_WIDTH = 4,
                                     int USER_WIDTH = 4,
                                     int REGION_MAP_SIZE = 16)
                        (ACLK, ARESETn,
                         AWVALID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWID, AWREADY,
                         ARVALID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARID, ARREADY,
                         RVALID, RLAST, RDATA, RRESP, RID, RREADY,
                         WVALID, WLAST, WDATA, WSTRB, WID, WREADY,
                         BVALID, BRESP, BID, BREADY,
                         AWUSER, ARUSER, RUSER, WUSER, BUSER
                        );

import uvm_pkg::*;
import mvc_pkg::*;
import mgc_axi4_v1_0_pkg::*;

    // system signals
    input ACLK    ;
    input ARESETn ;

    // write address channel signals
    output                              AWVALID ;
    output [ADDRESS_WIDTH-1:0]    AWADDR ;
    output [3:0]                        AWLEN ;
    output [2:0]                        AWSIZE ;
    output [1:0]                        AWBURST ;
    output [1:0]                        AWLOCK ;
    output [3:0]                        AWCACHE ;
    output [2:0]                        AWPROT ;
    output [ID_WIDTH-1:0]         AWID ;
    input                               AWREADY ;

    // read address channel signals
    output                              ARVALID ;
    output [ADDRESS_WIDTH-1:0]    ARADDR ;
    output [3:0]                        ARLEN ;
    output [2:0]                        ARSIZE ;
    output [1:0]                        ARBURST ;
    output [1:0]                        ARLOCK ;
    output [3:0]                        ARCACHE ;
    output [2:0]                        ARPROT ;
    output [ID_WIDTH-1:0]         ARID ;
    input                               ARREADY ;

    // read channel (data) signals
    input                               RVALID ;
    input                               RLAST ;
    input [RDATA_WIDTH-1:0]       RDATA ;
    input [1:0]                         RRESP ;
    input [ID_WIDTH-1:0]          RID ;
    output                              RREADY ;

    // write channel signals
    output                              WVALID ;
    output                              WLAST ;
    output [WDATA_WIDTH-1:0]      WDATA ;
    output [(((WDATA_WIDTH / 8)) - 1):0]  WSTRB;
    output [ID_WIDTH-1:0]         WID ;
    input                               WREADY ;

    // write response channel signals
    input                               BVALID ;
    input [1:0]                         BRESP ;
    input [ID_WIDTH-1:0]          BID ;
    output                              BREADY ;

    output [USER_WIDTH-1:0] AWUSER;
    output [USER_WIDTH-1:0] ARUSER;
    input [USER_WIDTH-1:0] RUSER;
    output [USER_WIDTH-1:0] WUSER;
    input [USER_WIDTH-1:0] BUSER;

/** ******************************************************************
 *  Default values.
 *  Values stored here are used as the default if the test writter does
 *  not explicitly specify another value. These defaults can be overridden
 *  by the test writer using the set_defaults() method.
 *  ***************************************************************** */
// Instantiating the axi4 interface
`define PARAM #( ADDRESS_WIDTH, RDATA_WIDTH,WDATA_WIDTH,ID_WIDTH,USER_WIDTH,REGION_MAP_SIZE )
mgc_axi4 `PARAM axi4_if(1'bz, 1'bz);
string        m_name         = $sformatf("%m:");
axi4_prot_e   default_prot   = AXI4_NORM_NONSEC_DATA;
axi4_size_e   default_size   = AXI4_BYTES_4;
axi4_burst_e  default_burst  = AXI4_INCR;
axi4_lock_e   default_lock   = AXI4_NORMAL;
axi4_cache_e  default_cache  = AXI4_NONMODIFIABLE_NONBUF;
axi4_response_e default_wr_resp = AXI4_SLVERR;
axi4_response_e default_rd_resp[] = '{AXI4_SLVERR};
bit[(ID_WIDTH-1):0] default_id  = 0;
bit[(WDATA_WIDTH-1):0]  default_data_min = 0;
bit[(WDATA_WIDTH-1):0]  default_data_max = '1;
bit[(WDATA_WIDTH -1):0] default_data [] = {4,4,1,6,3,5,8,1,1,4,7,1};
bit[(WDATA_WIDTH -1):0] default_data_o [] = '{'1};
bit[((WDATA_WIDTH / 8) -1):0] default_strobe []  = '{'1};
string        cg_name = remove_dots($sformatf("%m_cg"));

/** ******************************************************************
 *  uvm Elements.
 *  A write and a read sequence item, and mvc (questaVIP) sequence
 *  the Questa VIP AXI 4 Agent, and the configuration object.
 *  ***************************************************************** */
typedef axi4_master_write `PARAM write_seq_item_t;
typedef axi4_master_read `PARAM read_seq_item_t;

mvc_sequence axi4_seq;
mvc_agent axi4_agent;
axi4_vip_config `PARAM axi4_master_cfg;


/** ******************************************************************
 *  Initial Block - Gets run once at the start of simulation.
 *  Constructs a configuration object, puts a handle to the AXI bus
 *  into the configuration object and calls the task to set configs.
 *  Constructs the agent and associates it with the config object.
 *  Creates an AXI4 sequence.
 *  ***************************************************************** */
initial begin
  axi4_master_cfg = new("axi_master_cfg");
  axi4_master_cfg.m_bfm = axi4_if;
  configure_axi4_master;
  axi4_agent = new($sformatf("%m.axi4_agent"), uvm_top);
  axi4_agent.set_mvc_config(axi4_master_cfg);
  axi4_seq = new("axi4_seq");
end
assign axi4_if.ACLK    = ACLK;
assign axi4_if.ARESETn = ARESETn;

assign AWVALID = axi4_if.AWVALID;
assign AWADDR  = axi4_if.AWADDR;
assign AWLEN   = axi4_if.AWLEN;
assign AWSIZE  = axi4_if.AWSIZE;
assign AWBURST = axi4_if.AWBURST;
assign AWLOCK  = axi4_if.AWLOCK;
assign AWCACHE = axi4_if.AWCACHE;
assign AWPROT  = axi4_if.AWPROT;
assign AWID    = axi4_if.AWID;
assign AWUSER  = axi4_if.AWUSER;

assign axi4_if.AWREADY = AWREADY;

assign ARVALID = axi4_if.ARVALID;
assign ARADDR  = axi4_if.ARADDR;
assign ARLEN   = axi4_if.ARLEN;
assign ARSIZE  = axi4_if.ARSIZE;
assign ARBURST = axi4_if.ARBURST;
assign ARLOCK  = axi4_if.ARLOCK;
assign ARCACHE = axi4_if.ARCACHE;
assign ARPROT  = axi4_if.ARPROT;
assign ARID    = axi4_if.ARID;
assign ARUSER  = axi4_if.ARUSER;

assign axi4_if.ARREADY = ARREADY;

assign axi4_if.RVALID  = RVALID;
assign axi4_if.RLAST   = RLAST;
assign axi4_if.RDATA   = RDATA;
assign axi4_if.RRESP   = RRESP;
assign axi4_if.RID     = RID;
assign axi4_if.RUSER   = RUSER;

assign RREADY  = axi4_if.RREADY;

assign WVALID  = axi4_if.WVALID;
assign WLAST   = axi4_if.WLAST;
assign WDATA   = axi4_if.WDATA;
assign WSTRB   = axi4_if.WSTRB;
assign WUSER   = axi4_if.WUSER;

assign axi4_if.WREADY  = WREADY;

assign axi4_if.BVALID  = BVALID;
assign axi4_if.BRESP   = BRESP;
assign axi4_if.BID     = BID;
assign axi4_if.BUSER   = BUSER;

assign BREADY  = axi4_if.BREADY;

/** ******************************************************************
 *  function set_name 
 *  Used to override the default name used in all printouts
 *  By default the full path is used eg. top.tb.master 
 *  ***************************************************************** */
function set_name(string name = $sformatf("%m:"));
  m_name = name;
endfunction: set_name

/** ******************************************************************
 *  function set_default 
 *  Used to override the default AXI parameters such as prot
 *  The test writer can explicitly state values like prot in every cmd
 *  Or they can use this method to set the default for all commands 
 *  the parameters data_min and data_max are used to constrain the
 *  random value of data generated when doing write() with no data specified.
 *  ***************************************************************** */
function set_default(bit[(WDATA_WIDTH-1):0]  data_min = 0,
                 bit[(WDATA_WIDTH-1):0]  data_max = '1,
                 bit[((WDATA_WIDTH/8)-1):0] write_strobe = '1,
                 axi4_prot_e  prot   = AXI4_NORM_NONSEC_DATA,
                 axi4_size_e  size   = AXI4_BYTES_4,
                 axi4_burst_e burst  = AXI4_INCR,
                 axi4_lock_e  lock   = AXI4_NORMAL,
                 axi4_cache_e cache  = AXI4_NONMODIFIABLE_NONBUF,
                 bit[(ID_WIDTH-1):0] id  = 0
                );
  default_data_min = data_min;
  default_data_max = data_max;
  default_strobe = '{write_strobe};
  default_prot = prot;
  default_size = size;
  default_burst = burst;
  default_lock = lock;
  default_cache = cache;
  default_id = id;
endfunction: set_default

/** ******************************************************************
 *  Task wait_for_reset 
 *  ***************************************************************** */
task wait_for_reset();
  $display("%0t %s Waiting for Reset", $time, m_name);
  @(posedge axi4_if.ARESETn);
  $display("%0t %s Reset Detected", $time, m_name);
endtask: wait_for_reset

/** ******************************************************************
 *  Task single_write
 *  Convenience method hiding the complexity of arrays of data by
 *  performing just a single transfer, all AXI parameters take their
 *  default value (which is set by set_default), no response is
 *  provided, but the method throws an error if not AXI_OKAY. 
 *  ***************************************************************** */
task single_write(bit[(ADDRESS_WIDTH-1):0] address,
                  bit[(WDATA_WIDTH -1):0] data,
                  bit[((WDATA_WIDTH / 8) -1):0] write_strobe = 'hf
                 );
  bit[(WDATA_WIDTH -1):0] l_data[0:0];
  bit[((WDATA_WIDTH / 8) -1):0] l_write_strobe[0:0];
  axi4_response_e         l_wr_resp;
  l_data[0] = data;
  l_write_strobe[0] = write_strobe;
  write( .address(address),
         .data(l_data),
         .write_strobe(l_write_strobe),
         .wr_resp(l_wr_resp)
       );
  if (l_wr_resp != AXI4_OKAY) begin
    $display("%s ERROR during Write to address %0h response was not axi4_ok", m_name, address);
    end
endtask: single_write

/** ******************************************************************
 *  Task write
 *  Main write method gives control over bursts and all parameters.
 *  Any unspecified parameters take the default set by set_default.
 *  Unspecified data is randomised between data_max and data_min.
 *  ***************************************************************** */
task write(int                           burst_length     = 0,
           bit[(ADDRESS_WIDTH-1):0]         address,         // no default
           bit[(WDATA_WIDTH -1):0]       data []          = default_data, // random default
           bit[((WDATA_WIDTH / 8) -1):0] write_strobe []  = default_strobe, // default FF
           axi4_prot_e                   prot             = default_prot,
           axi4_size_e                   size             = default_size,
           axi4_burst_e                  burst            = default_burst,
           axi4_lock_e                   lock             = default_lock,
           axi4_cache_e                  cache            = default_cache,
           bit[(ID_WIDTH-1):0]           id               = default_id,
           output axi4_response_e        wr_resp          = default_wr_resp
           );
  // Define any local variables
  bit[1:0] l_wr_user_data[]; 
  // Create a new seq_item to hold the data on the sequencer
  automatic write_seq_item_t write_item = new();
  axi4_seq.set_sequencer(axi4_agent.m_sequencer);
  axi4_seq.start_item(write_item);
  // Fill in all the fields, any unspecified are randomised
  assert(write_item.randomize() with {foreach (write_item.data_words[i])
                                       write_item.data_words[i] >= default_data_min &&
                                       write_item.data_words[i] <= default_data_max;});
  l_wr_user_data[0] = 'b1;
  write_item.addr = address;
  write_item.prot = prot;
  write_item.region = 4'b0;
  write_item.size = size;
  write_item.burst = burst;
  write_item.lock = lock;
  write_item.cache = cache;
  write_item.qos = 4'b0;
  write_item.id = id;
  write_item.burst_length = burst_length;
// write_item.addr_user_data =
  write_item.data_words = data;
  write_item.write_strobes = write_strobe;
  l_wr_user_data = new[burst_length+1];
  write_item.wdata_user_data = l_wr_user_data;
  // Print out what will be sent to the transcript
  if (burst_length == 0) begin
    $display("%s Write %0h to address %0h", m_name, write_item.data_words[0], address);
    end
  else begin
    $display("%s Burst Write of length %0d to address %0h", m_name, burst_length+1, address);
    for (int i = 0; i< burst_length+1; i++) begin
      $display("%s Data %0d = %0h", m_name, i, write_item.data_words[i]);
      end 
    end
  // Finish item causes the item to be sent to the DUT
  axi4_seq.finish_item(write_item);
  wr_resp = write_item.resp;
endtask: write

/** ******************************************************************
 *  Task single_read
 *  Convenience method hiding the complexity of arrays of data by
 *  performing just a single transfer, all AXI parameters take their
 *  default value (which is set by set_default), no response is
 *  provided, but the method throws an error if not AXI_OKAY. 
 *  ***************************************************************** */
task single_read(bit[(ADDRESS_WIDTH-1):0] address,
                 output bit[(RDATA_WIDTH -1):0] data);
  bit[(RDATA_WIDTH -1):0] l_data[];
  axi4_response_e         l_rd_resp[];
  read(.address(address),
       .data(l_data),
       .rd_resp(l_rd_resp)
      );
  data = l_data[0];
  if (l_rd_resp[0] != AXI4_OKAY) begin
    $display("%s ERROR during Read from address %0h response was not axi4_ok", m_name, address);
    end
endtask: single_read

/** ******************************************************************
 *  Task read
 *  Main read method gives control over bursts and all parameters.
 *  Any unspecified parameters take the default set by set_default.
 *  ***************************************************************** */
task read (int                           burst_length     = 0,
           bit[(ADDRESS_WIDTH-1):0]         address,         // no default
           axi4_prot_e                   prot             = default_prot,
           axi4_size_e                   size             = default_size,
           axi4_burst_e                  burst            = default_burst,
           axi4_lock_e                   lock             = default_lock,
           axi4_cache_e                  cache            = default_cache,
           bit[(ID_WIDTH-1):0]           id               = default_id,
           output bit[(RDATA_WIDTH-1):0] data[]           = default_data_o,
           output axi4_response_e        rd_resp[]        = default_rd_resp
           );
  automatic read_seq_item_t read_item = new();
  axi4_seq.set_sequencer(axi4_agent.m_sequencer);
  axi4_seq.start_item(read_item);
// Fill in all the fields any unspecified are randomised
  assert(read_item.randomize());
  read_item.addr = address;
  read_item.prot = prot;
  read_item.region = 0;
  read_item.size = size;
  read_item.burst = burst;
  read_item.lock = lock;
  read_item.cache = cache;
  read_item.qos = 0;
  read_item.id = id;
  read_item.burst_length = burst_length;
// read_item.addr_user_data =
  axi4_seq.finish_item(read_item);
  data = read_item.data_words;
  rd_resp = read_item.resp;
  if (burst_length == 0) begin
    $display("%s Read %0h from address %0h", m_name, data[0], address);
    end
  else begin
    $display("%s Burst Read of length %0d from address %0h", m_name, burst_length+1, address);
    for (int i = 0; i< burst_length+1; i++) begin
      $display("%s Data %0d = %0h", m_name, i, data[i]);
      end 
    end
endtask: read

/** ******************************************************************
 *  Task Configure_AXI4_Master
 *  Configures the Mentor AXI4 VIP 
 *  This is the master VIP so set_master_abstration_level is ON (0,1)
 *  Slave abtraction the built in clock and reset sources are all OFF
 *  The built in checker is turned off because it assumes that all
 *  reads match what we have written, which is not always true.
 *  The coverage collector is turned on.
 *  ***************************************************************** */
function void configure_axi4_master (bit coverage = 1);
  axi4_master_cfg.m_bfm.axi4_set_master_abstraction_level(0,1);
  axi4_master_cfg.m_bfm.axi4_set_slave_abstraction_level(1,0);
  axi4_master_cfg.m_bfm.axi4_set_clock_source_abstraction_level(1,0);
  axi4_master_cfg.m_bfm.axi4_set_reset_source_abstraction_level(1,0);
  axi4_master_cfg.m_bfm.set_config_enable_region_support(1'b0);
  axi4_master_cfg.m_bfm.set_config_enable_errors(1'b1);
  axi4_master_cfg.m_warn_on_uninitialized_read = 1'b0;
  axi4_master_cfg.delete_analysis_component("trans_ap","checker");
  if (coverage) begin
    axi4_master_cfg.set_analysis_component("",cg_name,
     axi4_coverage`PARAM::type_id::get());
    end
endfunction: configure_axi4_master

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

endmodule: mentor_qvip_api_axi4_master
