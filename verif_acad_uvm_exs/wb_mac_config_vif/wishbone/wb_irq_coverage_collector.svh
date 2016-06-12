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

`ifndef __WB_IRQ_COVERAGE_COLLECTOR_H
`define __WB_IRQ_COVERAGE_COLLECTOR_H

class wb_irq_coverage_collector extends uvm_subscriber #(wb_txn);
  `uvm_component_utils(wb_irq_coverage_collector)

  wb_txn txn;
 
// Control which coverpoints are active by using weights
  covergroup cg_irq_srce(bit rx_mode, bit tx_mode, bit busy_mode, bit error_mode);
    int_srce_addr: coverpoint txn.adr[11:2]
     // Interrupt Source reg word address is 'h1
      { bins addr_bin = {1}; }
    busy: coverpoint txn.data[0][4] // Busy
      { option.weight = busy_mode; bins busy_1 = {1}; }
    rxe:  coverpoint txn.data[0][3] // Receive error
      { option.weight = error_mode; bins rxe_1 = {1}; }
    rxb:  coverpoint txn.data[0][2] // Receive buffer
      { option.weight = rx_mode; bins rxb_1 = {1}; }
    txe:  coverpoint txn.data[0][1] // Transmit error
      { option.weight = error_mode; bins txe_1 = {1}; }
    txb:  coverpoint txn.data[0][0] // Transmit buffer
      { option.weight = tx_mode; bins txb_1 = {1}; }
    busy_c : cross int_srce_addr, busy { option.weight = busy_mode; }
    rxe_c  : cross int_srce_addr, rxe  { option.weight = error_mode; }
    rxb_c  : cross int_srce_addr, rxb  { option.weight = rx_mode; }
    txe_c  : cross int_srce_addr, txe  { option.weight = error_mode; }
    txb_c  : cross int_srce_addr, txb  { option.weight = tx_mode; }
  endgroup
 
  function new(string name, uvm_component parent);
    super.new(name, parent);

// Set only RX and TX active, values can come from config
// instead of hard-coded as shown here
    cg_irq_srce = new(1, 1, 0, 0); // Create covergroup
  endfunction
 
  function int get_cg_coverage();
    return cg_irq_srce.get_coverage();
  endfunction
 
  function void write(wb_txn t);
    txn = t;

// Sample only when reading the MAC irq register
    if (t.txn_type == READ && t.adr == 32'h00100004) begin
      cg_irq_srce.sample();  // Sample the observed transaction
    end
  endfunction
 
endclass

`endif
