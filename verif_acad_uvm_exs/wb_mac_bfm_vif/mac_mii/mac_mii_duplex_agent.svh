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

`ifndef MAC_MII_DUPLEX_AGENT
`define MAC_MII_DUPLEX_AGENT

// Container class for MAC agent
// Mike Baird
//----------------------------------------------

class mac_mii_duplex_agent extends uvm_agent;
 `uvm_component_utils(mac_mii_duplex_agent)

  // Analysis ports
 uvm_analysis_port #(ethernet_txn) mii_rx_drv_ap;
 uvm_analysis_port #(ethernet_txn) mii_tx_drv_ap;
 uvm_analysis_port #(ethernet_txn) mii_rx_seq_ap;
 uvm_analysis_port #(ethernet_txn) mii_tx_seq_ap;

 // Components
 mii_rx_driver mii_rx_drv;
 mii_tx_driver mii_tx_drv;
 uvm_sequencer #(ethernet_txn) mii_rx_seqr;
 uvm_sequencer #(ethernet_txn) mii_tx_seqr;

 function new(string name, uvm_component parent);
  super.new(name,parent);
 endfunction

 function void build_phase(uvm_phase phase);
  string seqr_name;
  super.build_phase(phase);

   //ports
  mii_rx_drv_ap = new("mii_rx_drv_ap", this);
  mii_tx_drv_ap = new("mii_tx_drv_ap", this);
  mii_rx_seq_ap = new("mii_rx_seq_ap", this);
  mii_tx_seq_ap = new("mii_tx_seq_ap", this);

   //components
  mii_rx_drv = mii_rx_driver::type_id::create("mii_rx_drv", this);
  mii_tx_drv = mii_tx_driver::type_id::create("mii_tx_drv", this);

  mii_rx_seqr = new("mii_rx_seqr", this); //create sequencer
  mii_tx_seqr = new("mii_tx_seqr", this); //create sequencer
 endfunction

 function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);

   //analysis ports
  mii_rx_drv.mii_rx_drv_ap.connect(mii_rx_drv_ap); 
  mii_tx_drv.mii_tx_drv_ap.connect(mii_tx_drv_ap); 

   // child ports
  mii_rx_drv.seq_item_port.connect(mii_rx_seqr.seq_item_export);
  mii_tx_drv.seq_item_port.connect(mii_tx_seqr.seq_item_export);
  
 endfunction

endclass
`endif
