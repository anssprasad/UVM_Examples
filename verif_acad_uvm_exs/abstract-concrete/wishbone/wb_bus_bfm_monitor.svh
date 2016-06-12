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

`ifndef WB_BUS_BFM_MONITOR
`define WB_BUS_BFM_MONITOR




class wb_bus_bfm_monitor extends uvm_monitor;
`uvm_component_utils(wb_bus_bfm_monitor)

  wb_bus_abs_c m_wb_bus_abs_c;
  uvm_analysis_port #(wb_txn) wb_mon_ap;
  wb_config m_config;

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wb_mon_ap = new("wb_mon_ap", this);
    // get config object
    if (!uvm_config_db#(wb_config)::get(this,"","wb_config", m_config) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration wb_config from uvm_config_db. Have you set() it?")
    // Assign abstract class handle to concrete object
    m_wb_bus_abs_c = m_config.m_wb_bus_abs_c;
  endfunction
  
  task run_phase(uvm_phase phase);
    wb_txn txn;
    forever begin
      m_wb_bus_abs_c.monitor(txn);
      wb_mon_ap.write(txn); // broadcast the wb_txn
    end
  endtask
  
endclass
`endif
