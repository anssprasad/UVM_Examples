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

// Container class for wishbone bus master
// Mike Baird
//----------------------------------------

class wb_master_agent extends uvm_agent;
  `uvm_component_utils(wb_master_agent)

   //ports
  uvm_analysis_port #(wb_txn) wb_agent_drv_ap;
  uvm_analysis_port #(wb_txn) wb_agent_mon_ap;

   // components
  wb_m_bus_driver wb_drv;
  wb_bus_monitor  wb_mon;
  uvm_sequencer #(wb_txn,wb_txn) wb_seqr;

  wb_config m_config;

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // get ID
    if(!uvm_config_db #(wb_config)::get(this, "", "wb_config", m_config)) begin
      `uvm_error("build_phase", "Unable to find wb_config in configuration database")
    end
     //ports
    wb_agent_drv_ap = new("wb_agent_drv_ap", this);
    wb_agent_mon_ap = new("wb_agent_mon_ap", this);

     //components
    wb_drv = wb_m_bus_driver::type_id::create("wb_drv", this);  // driver
    wb_mon = wb_bus_monitor::type_id::create( "wb_mon", this);  // monitor
    wb_seqr = new($sformatf("wb_m_%0d_seqr",m_config.m_wb_master_id), this);  // sequencer
  endfunction

  function void connect_phase(uvm_phase phase);
     //analysis ports
    wb_drv.wb_drv_ap.connect(wb_agent_drv_ap);
    wb_mon.wb_mon_ap.connect(wb_agent_mon_ap);
     // child ports
    wb_drv.seq_item_port.connect(wb_seqr.seq_item_export);
  endfunction

endclass
