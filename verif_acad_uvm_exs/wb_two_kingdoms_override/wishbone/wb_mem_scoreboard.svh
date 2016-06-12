//------------------------------------------------------------
//   Copyright 2010 Mentor Graphics Corporation
//   All Rights Reserved Worldwide
//   
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//   
//       http://www.apache.org/licenses/LICENSE-2.0
//   
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------

`ifndef WB_MEM_SCOREBOARD
`define WB_MEM_SCOREBOARD

// Scoreboard for wishbone with slave memories
// for with wishbone bus with 1 Mbyte memory mapped slaves
// Mike Baird
//----------------------------------------------
class wb_mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(wb_mem_scoreboard)
  
  logic [31:0] shadow_mem [ bit[31:0] ];  //associative array for shadow memory
 
  uvm_analysis_export #(wb_txn) wb_txn_axp;
 
  uvm_tlm_analysis_fifo #(wb_txn) wb_txn_fifo;
  int mem_read_error_cnt;
  int wb_wt_txn_cnt, wb_rd_txn_cnt;
  int wb_wt_non_mem_cnt, wb_rd_non_mem_cnt;

  wb_config m_config;
 
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get config object
    if (!uvm_config_db#(wb_config)::get(this,"","wb_config", m_config) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration wb_config from uvm_config_db. Have you set() it?")
    wb_txn_axp  = new("wb_txn_axp", this);
    wb_txn_fifo = new("wb_txn_fifo",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    wb_txn_axp.connect(wb_txn_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    wb_txn txn;

    forever begin
      wb_txn_fifo.get(txn);  // get a transaction
      case(txn.txn_type)
        NONE: `uvm_info($sformatf("MEM_SB_%0d",m_config.m_mem_slave_wb_id),
                              $sformatf("wb_txn %0d the wb_txn_type was type NONE",
                              txn.get_transaction_id()),UVM_LOW )
        WRITE: wb_write_cycle(txn);
        READ:  wb_read_cycle(txn);
        RMW:  wb_rmw_cycle(txn);
      endcase
    end

  endtask

  //WRITE  1 or more write cycles
  virtual task wb_write_cycle(ref wb_txn req_txn);
    if(!check_for_slave_mem(req_txn)) // check to make sure it is for the wishbone slave memory
      return;
    wb_wt_txn_cnt++;
    for(int i = 0; i<req_txn.count; i++)
      shadow_mem[req_txn.adr] = req_txn.data[i];  // write shadow memory
  endtask
  
  //READ 1 or more cycles
  virtual task wb_read_cycle(ref wb_txn rsp_txn);
    string s1,s2;
    if(!check_for_slave_mem(rsp_txn)) // check to make sure it is for the wishbone slave memory
      return;
    wb_rd_txn_cnt++;
    for(int i = 0; i<rsp_txn.count; i++)
      if (shadow_mem[rsp_txn.adr + i] != rsp_txn.data[i]) begin
        mem_read_error_cnt++;
        $sformat(s1,"WB Bus Read error, Sequence ID: %0d, Transaction ID: %0d \n",
                rsp_txn.get_sequence_id(), rsp_txn.get_transaction_id());
        $sformat(s2, "Address: %0h, Expected: %0d, Actual: %0d",
                  rsp_txn.adr, shadow_mem[rsp_txn.adr + i], rsp_txn.data[i]);
        `uvm_error($sformatf("MEM_SB_%0d",m_config.m_mem_slave_wb_id),{s1,s2} )
      end        
  endtask

    //RMW ( read-modify_write)
  virtual task wb_rmw_cycle(ref wb_txn req_txn);
    `uvm_info($sformatf("MEM_SB_%0d",m_config.m_mem_slave_wb_id), "Wishbone RMW instruction not implemented yet",UVM_LOW )
  endtask
  
  virtual function bit check_for_slave_mem(ref wb_txn txn);
    if ((txn.adr >= m_config.m_s_mem_wb_base_addr) && (txn.adr <= m_config.m_s_mem_wb_base_addr + m_config.m_mem_slave_size - 1))
      return(1);  // valid slave mem address
    if (txn.txn_type == READ)
      wb_rd_non_mem_cnt++;
    else
      wb_wt_non_mem_cnt++;
    return(0);  // not a valid slave mem address - could be to another device
  endfunction
  
  function void report_phase(uvm_phase phase);
    string s1,s2,s3,s4,s5;
    $sformat(s1,"\n  Number of Wishbone %0d Slave Memory write transactions: %0d \n",m_config.m_mem_slave_wb_id, wb_wt_txn_cnt);
    $sformat(s2,  "  Number of Wishbone %0d Non-Slave Memory write cycles: %0d \n",m_config.m_mem_slave_wb_id, wb_wt_non_mem_cnt);
    $sformat(s3,  "  Number of Wishbone %0d Slave Memory read  transactions: %0d \n",m_config.m_mem_slave_wb_id, wb_rd_txn_cnt);
    $sformat(s4,  "  Number of Wishbone %0d Non-Slave Memory read cycles: %0d \n",m_config.m_mem_slave_wb_id, wb_rd_non_mem_cnt);
    $sformat(s5,  "  Wishbone %0d Slave Memory read error count: %0d\n", m_config.m_mem_slave_wb_id, mem_read_error_cnt);
    `uvm_info($sformatf("MEM_SB_%0d",m_config.m_mem_slave_wb_id),{s1,s3,s2,s4,s5},UVM_LOW ) 
  endfunction

endclass
`endif
