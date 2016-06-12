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

`ifndef MAC_ENV
`define MAC_ENV

//environment class for wishbone system
// Mike Baird
//----------------------------------------------
class mac_env extends uvm_component;
`uvm_component_utils(mac_env)

  mac_mii_tx_agent mac_tx_agent;  
  mac_mii_rx_agent mac_rx_agent;  
  wb_master_agent  wb_m_agent;
  wb_mem_scoreboard wb_mem_sb;
  mii_scoreboard mii_sb;
  wb_mac_reg_scoreboard mac_regs;
  
  // constructor
  function new( string name, uvm_component parent = null);
   super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string s_name;
    super.build_phase(phase);
    // create MAC stuff
    mac_tx_agent = mac_mii_tx_agent::type_id::create("mac_tx_agent", this);
    mac_rx_agent = mac_mii_rx_agent::type_id::create("mac_rx_agent", this);
    mii_sb    = mii_scoreboard::type_id::create("mii_sb", this);
    // create wishbone stuff
    wb_m_agent = wb_master_agent::type_id::create(  "wb_m_agent", this);
    wb_mem_sb  = wb_mem_scoreboard::type_id::create("wb_mem_sb",  this);
    mac_regs = wb_mac_reg_scoreboard::type_id::create("mac_regs", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mac_rx_agent.mii_rx_drv_ap.connect(mii_sb.mii_rx_drv_axp);
    mac_rx_agent.mii_rx_seq_ap.connect(mii_sb.mii_rx_seq_axp);
    mac_tx_agent.mii_tx_drv_ap.connect(mii_sb.mii_tx_drv_axp);
    mac_tx_agent.mii_tx_seq_ap.connect(mii_sb.mii_tx_seq_axp);
    wb_m_agent.wb_agent_mon_ap.connect(wb_mem_sb.wb_txn_axp);
    wb_m_agent.wb_agent_mon_ap.connect(mac_regs.wb_txn_axp);
    
  endfunction

endclass
`endif
