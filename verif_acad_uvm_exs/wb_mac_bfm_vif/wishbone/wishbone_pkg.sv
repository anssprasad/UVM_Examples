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

package wishbone_pkg;
import uvm_pkg::*;
import uvm_register_pkg::*;
import wb_register_pkg::*;

//----------------------------------------------

  // Wishbone transaction types enumeration
  typedef enum  {NONE, WRITE, READ, RMW, WAIT_IRQ } wb_txn_t;


//----------------------------------------------
// global virtual interfaces
  virtual wishbone_bus_syscon_if v_wb_bus_if;  // global virtual wishbone interface

  int next_pkt_id = 0;

  `include "uvm_macros.svh"

  `include "wb_txn.svh"
  `include "wb_bus_abs_c.svh"
  `include "wb_config.svh"
  `include "mac_reg_comp_base.svh"
  `include "wb_read_seq.svh"
  `include "wb_write_seq.svh"
  `include "wb_wait_irq_seq.svh"
//  `include "wb_m_bus_driver.svh"
  `include "wb_bus_bfm_driver.svh"
//  `include "wb_bus_monitor.svh"
  `include "wb_bus_bfm_monitor.svh"
  `include "wb_master_agent.svh"
  `include "wb_mem_scoreboard.svh"
  `include "wb_mac_reg_scoreboard.svh"
  `include "wb_mem_map_access_base_seq.svh"

endpackage
