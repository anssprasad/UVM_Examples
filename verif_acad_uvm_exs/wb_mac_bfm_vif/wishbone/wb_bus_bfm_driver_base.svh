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

`ifndef WB_BUS_BFM_DRIVER_BASE
`define WB_BUS_BFM_DRIVER_BASE

// WISHBONE master driver base class
// Mike Baird
// Base class driver for Two Kingdoms
//----------------------------------------------
class wb_bus_bfm_driver_base extends uvm_driver #(wb_txn, wb_txn);
`uvm_component_utils(wb_bus_bfm_driver_base)
  
  uvm_analysis_port #(wb_txn) wb_drv_ap;
  bit [2:0] m_id;  // Wishbone bus master ID

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wb_drv_ap = new("wb_drv_ap", this);
  endfunction
  
endclass
`endif
