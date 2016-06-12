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

`ifndef WB_MAC_REG_SCOREBOARD
`define WB_MAC_REG_SCOREBOARD

// wishbone bus monitor
// Monitors slave read and write transactions and "packages" each
// transaction into a wb_txn and broadcasts the wb_txn
// Note only monitors slave 0 and slave 1 (see wishbone_bus_syscon_if)
// Mike Baird

//----------------------------------------------
class wb_mac_reg_scoreboard extends mac_reg_comp_base;
  `uvm_component_utils(wb_mac_reg_scoreboard)
   
  uvm_analysis_export #(wb_txn) wb_txn_axp;

  uvm_tlm_analysis_fifo #(wb_txn) m_txn_buffer;  // buffer for wb_txn's
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
    m_txn_buffer = new("m_txn_buffer", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    wb_txn_axp.connect(m_txn_buffer.analysis_export);
  endfunction

 task run_phase(uvm_phase phase);
  wb_txn txn;
  uvm_register_base mac_reg;
  logic [31:0] data;

  forever begin
    m_txn_buffer.get(txn);  // get WISHBONE transaction
    // check to see if txn is a MAC slave transaction
    if (txn.adr >= m_config.m_mac_wb_base_addr && txn.adr <= m_config.m_mac_wb_base_addr + 'hfff) begin
      mac_reg = m_register_map.lookup_register_by_address(txn.adr);
      if( mac_reg!= null) begin
       if (txn.txn_type == 2) begin
        data = mac_reg.read_data32();
        `uvm_info("REG_MON", $sformatf("\n++++ Did a shadow reg read to %s", 
                                        mac_reg.get_full_name()), UVM_MEDIUM)
//        if(data != txn.data[0])
//          `uvm_error("REG_MON", $sformatf("\n++++ Register read error %s",
//                                        mac_reg.get_full_name()))
       end
       else if(txn.txn_type == WRITE) begin 
        mac_reg.write_data32(txn.data[0]);
        `uvm_info("REG_MON", $sformatf("\n---- Did a shadow reg write to %s",
                                        mac_reg.get_full_name()), UVM_MEDIUM)
       end
      end
    end
  end
 endtask

  
endclass
`endif
