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

`ifndef WB_BUS_ABS_C
`define WB_BUS_ABS_C

// Abstract class for two kingdoms wishbone bus communication
// Mike Baird
//----------------------------------------------
virtual class wb_bus_abs_c extends uvm_component;
`uvm_component_utils(wb_bus_abs_c)

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction

  // API methods
  //WRITE  1 or more write cycles
  pure virtual task wb_write_cycle(wb_txn req_txn, bit [2:0] m_id);

  //READ 1 or more cycles
  pure virtual task wb_read_cycle(wb_txn req_txn, bit [2:0] m_id, output wb_txn rsp_txn);

  // wait for an interrupt
  pure virtual task wb_irq(wb_txn req_txn, output wb_txn rsp_txn);

  //Get a wb transaction from the bus
  pure virtual task monitor(output wb_txn txn); 
  
  event pos_edge_clk;   

endclass
`endif
