module mentor_qvip_api_axi4_slave #(int ADDR_WIDTH = 32,
                                    int RDATA_WIDTH = 32,
                                    int WDATA_WIDTH = 32,
                                    int ID_WIDTH = 4,
                                    int USER_WIDTH = 4,
                                    int REGION_MAP_SIZE = 16)
                                   (interface AXI4);

import uvm_pkg::*;
import mvc_pkg::*;
import mgc_axi4_v1_0_pkg::*;

/** ******************************************************************
 *  Default values.
 *  In the case of the slave model just the names
 *  ***************************************************************** */
string m_name = $sformatf("%m:");
string cg_name = remove_dots($sformatf("%m_cg"));

/** ******************************************************************
 *  uvm Elements.
 *  A single axi4 pre-written slave sequence which responds to AXI4
 *  transactions on the bus by storing Writes in a memory and providing
 *  the appropriate response when asked for a read.
 *  Also the Questa VIP AXI 4 Agent, and the configuration object.
 *  ***************************************************************** */
typedef axi4_slave_sequence #(ADDR_WIDTH,
                            RDATA_WIDTH,
                            WDATA_WIDTH,
                            ID_WIDTH,
                            USER_WIDTH,
                            REGION_MAP_SIZE) slave_sequence_t;

mvc_agent axi4_agent;
axi4_vip_config #(ADDR_WIDTH,
                  RDATA_WIDTH,
                  WDATA_WIDTH,
                  ID_WIDTH,
                  USER_WIDTH,
                  REGION_MAP_SIZE) axi4_slave_cfg;

slave_sequence_t slave_seq;
  
/** ******************************************************************
 *  Expected result memory used instead of a scoreboard.
 *  mem_exp is a byte memory containing the expected result as loaded by the test writer
 *  mem_exp_load function allow the test writer to load an expected image
 *  mem_exp_move function allows test writer to move blocks of data in the expected memory
 *  mem_exp_diff function checks actual mem against expected to see if they are identical
 *  Normal use model by test writer :
 *    Load a starting image into the source memory using mem_load function
 *    Load the same image into the expected destination memory using mem_exp_load
 *    Perform a series of manipulation operations
 *     In the case of ICE, load_command_list, apply some interrupt IDs
 *    Calculate the expected memory move operation and apply to exp mem using mem_exp_move
 *    Call mem_exp_diff to see if DUT produced the same answer as expected
 *  ***************************************************************** */
bit[7:0] mem_act [int];  //  local memory - NOTE only updated during a check operation
bit[7:0] mem_exp [int];

/** ******************************************************************
 *  Initial Block - Gets run once at the start of simulation.
 *  Constructs a configuration object, puts a handle to the AXI bus
 *  into the configuration object and calls the task to set configs.
 *  Constructs the agent and associates it with the config object.
 *  Waits for Reset then Constructs and starts the AXI4 sequence.
 *  ***************************************************************** */
initial begin
  axi4_slave_cfg = new("axi_slave_cfg");
  axi4_slave_cfg.m_bfm = AXI4;
  configure_axi4_slave ();
  axi4_agent = new($sformatf("%m.axi4_agent"), uvm_top);
  axi4_agent.set_mvc_config(axi4_slave_cfg);
  @(posedge AXI4.ARESETn);
  slave_seq = new();
  run_forever();
end

/** ******************************************************************
 *  Slave sequence sits waiting for activity from the master, stores
 *  incoming writes in a memory, and responds accordingly to reads.
 *  ***************************************************************** */
task run_forever();
  slave_seq.start(axi4_agent.m_sequencer);
endtask: run_forever

/** ******************************************************************
 *  Memory access functions.
 *  mem_load - Preload the slave memory without executing any AXI cycles.
 *  mem_exp_load - Load a memory with expected result image
 *  mem_exp_move - Allows test designers to move blocks of memory in the expected result
 *  mem_exp_diff - Compares actual memory with expected image - returns 1 if identical
 *  ***************************************************************** */
function void mem_load(bit [ADDR_WIDTH - 1 : 0] addr,
                       bit [7:0] data_bytes []);
  slave_seq.backdoor_write(addr, data_bytes);
endfunction: mem_load

function void mem_exp_load(bit [ADDR_WIDTH - 1 : 0] addr,
                           bit [7:0] data_bytes []);
  //mem_exp = new[data_bytes.size()];
  foreach (data_bytes[i]) begin
    mem_exp[addr+i] = data_bytes[i];
    end
endfunction: mem_exp_load

function void mem_exp_move( bit [ADDR_WIDTH - 1 : 0] source_addr,
                            bit [ADDR_WIDTH - 1 : 0] dest_addr,
                            int number_of_bytes);
  bit [7:0] tempmem [];
  tempmem = new [number_of_bytes];
  for (int i = 0; i < number_of_bytes; i++ ) begin
    tempmem[i] = slave_seq.axi4_memory_read(source_addr+i);
    end
  slave_seq.backdoor_write(dest_addr,tempmem);
endfunction: mem_exp_move

function bit mem_exp_diff(bit [ADDR_WIDTH - 1 : 0] start_addr,
                          int number_of_bytes);
  automatic bit all_match = 1;
  $display("%s Compare slave memory contents with expected image at address %x for %d number of bytes.",
           m_name, start_addr, number_of_bytes);
  for (int i = 0; i < number_of_bytes; i++ ) begin
    mem_act[start_addr+i] = slave_seq.axi4_memory_read(start_addr+i);
    if (mem_exp[start_addr+i] != mem_act[start_addr+i]) begin
        all_match = 0;
        end
     end
   return all_match;
endfunction: mem_exp_diff

/** ******************************************************************
 *  Task Configure_AXI4_Slave.
 *  Configures the Mentor AXI4 VIP
 *  This is the slave VIP so set_slave_abstration_level is ON (0,1)
 *  Master abtraction the built in clock and reset sources are all OFF
 *  The other parameters define how the slave model responses to AXI.
 *  ***************************************************************** */
function void configure_axi4_slave (
  int write_addr_reorder_depth  = 16,
  int read_addr_reorder_depth   = 16,
  int read_data_reorder_depth   = 16,
  int AWREADY_delay_min         = 0,
  int AWREADY_delay_max         = 4,
  int WREADY_delay_min          = 0,
  int WREADY_delay_max          = 4,
  int ARREADY_delay_min         = 0,
  int ARREADY_delay_max         = 4,
  int write_response_delay_min  = 0,
  int write_response_delay_max  = 10,
  int read_response_delay_min   = 0,
  int read_response_delay_max   = 10,
  int slave_error_rate          = 0,  //Expressed as a %
  int decode_error_rate         = 0,
  logic[RDATA_WIDTH-1:0] uninitalized_read_value = 'x ,
  bit coverage                  = 1
  );
  axi4_slave_cfg.m_bfm.axi4_set_master_abstraction_level(1,0);
  axi4_slave_cfg.m_bfm.axi4_set_slave_abstraction_level(0,1);
  axi4_slave_cfg.m_bfm.axi4_set_clock_source_abstraction_level(1,0);
  axi4_slave_cfg.m_bfm.axi4_set_reset_source_abstraction_level(1,0);
  axi4_slave_cfg.m_bfm.set_config_enable_region_support(1'b0);
  axi4_slave_cfg.m_bfm.set_config_enable_errors(1'b1);
  if (coverage) begin
    axi4_slave_cfg.set_analysis_component("",cg_name,
     axi4_coverage#(ADDR_WIDTH,
                    RDATA_WIDTH,
                    WDATA_WIDTH,
                    ID_WIDTH,
                    USER_WIDTH,
                    REGION_MAP_SIZE)::type_id::get());
    end
  axi4_slave_cfg.m_max_outstanding_write_addrs = write_addr_reorder_depth;
  axi4_slave_cfg.m_max_outstanding_read_addrs  = read_addr_reorder_depth;
  axi4_slave_cfg.m_min_wr_addr_ready          = AWREADY_delay_min;
  axi4_slave_cfg.m_max_wr_addr_ready          = AWREADY_delay_max;
  axi4_slave_cfg.m_min_wr_addr_not_ready      = AWREADY_delay_min;
  axi4_slave_cfg.m_max_wr_addr_not_ready      = AWREADY_delay_max;
  axi4_slave_cfg.m_min_rd_addr_ready          = ARREADY_delay_min;
  axi4_slave_cfg.m_max_rd_addr_ready          = ARREADY_delay_max;
  axi4_slave_cfg.m_min_rd_addr_not_ready      = ARREADY_delay_min;
  axi4_slave_cfg.m_max_rd_addr_not_ready      = ARREADY_delay_max;
  axi4_slave_cfg.m_min_wr_data_not_ready      = WREADY_delay_min;
  axi4_slave_cfg.m_max_wr_data_not_ready      = WREADY_delay_max;
  axi4_slave_cfg.m_min_wr_data_ready          = WREADY_delay_min;
  axi4_slave_cfg.m_max_wr_data_ready          = WREADY_delay_max;
  axi4_slave_cfg.m_max_wr_resp_delay          = write_response_delay_max;
  axi4_slave_cfg.m_min_wr_resp_delay          = write_response_delay_min;
  axi4_slave_cfg.m_max_rd_resp_delay          = read_response_delay_max;
  axi4_slave_cfg.m_min_rd_resp_delay          = read_response_delay_min;
  axi4_slave_cfg.m_slv_err_rate               = slave_error_rate;
  axi4_slave_cfg.m_dec_err_rate               = decode_error_rate;
  axi4_slave_cfg.m_ok_for_exclusive_rate      = 0;
  axi4_slave_cfg.m_bfm.set_config_enable_slave_exclusive(0);
  axi4_slave_cfg.m_warn_on_uninitialized_read = 1'b0;
  axi4_slave_cfg.m_default_value_for_uninitialized_read = uninitalized_read_value;
endfunction: configure_axi4_slave

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

endmodule: mentor_qvip_api_axi4_slave
