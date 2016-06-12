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

package sequences_pkg;
import uvm_pkg::*;
import mac_info_pkg::*;
import uvm_register_pkg::*;
import wb_register_pkg::*;
import mac_mii_pkg::ethernet_txn;
import wishbone_pkg::*;
import mac_mii_pkg::mac_rx_frame_seq;
import mac_mii_pkg::mac_tx_frame_seq;


  `include "uvm_macros.svh"

  `include "mac_simple_duplex_seq.svh"

endpackage
