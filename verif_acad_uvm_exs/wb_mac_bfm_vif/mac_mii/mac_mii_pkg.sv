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


package mac_mii_pkg;
import uvm_pkg::*;
import mac_info_pkg::*;
import uvm_register_pkg::*;
import wb_register_pkg::*;
import wishbone_pkg::*;

  // "global" virtual interface
  virtual mii_if v_miim_if;

 `include "uvm_macros.svh"
 `include "ethernet_txn.svh"
 `include "ethernet_txn_ext.svh"
 `include "mii_config.svh"
 `include "mii_tx_driver.svh"
 `include "mii_rx_driver.svh"
 `include "mac_mii_base_frame_seq.svh"
 `include "mac_rx_frame_seq.svh"
 `include "mac_tx_frame_seq.svh"
 `include "mac_mii_tx_agent.svh"
 `include "mac_mii_rx_agent.svh"
 `include "mac_mii_duplex_agent.svh"
 `include "mii_scoreboard.svh"

endpackage
