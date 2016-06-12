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

`ifndef __WB_IRQ_MIX_COVERAGE_COLLECTOR_H
`define __WB_IRQ_MIX_COVERAGE_COLLECTOR_H

virtual class coverpoint_wrapper;
  wb_txn txn;
  pure virtual function void sample();
endclass

class rx_coverpoint extends coverpoint_wrapper;
  covergroup cg;
    int_srce_addr: coverpoint txn.adr[11:2]
     // Interrupt Source reg word address is 'h1
      { bins addr_bin = {1}; }
    rxb:  coverpoint txn.data[0][2] // Receive buffer
      { bins rxb_1 = {1}; }
    rxb_c  : cross int_srce_addr, rxb;
  endgroup

  function new();
    super.new();
    cg = new();
  endfunction

  function void sample();
    cg.sample();
  endfunction
endclass


class tx_coverpoint extends coverpoint_wrapper;
  covergroup cg;
    int_srce_addr: coverpoint txn.adr[11:2]
     // Interrupt Source reg word address is 'h1
      { bins addr_bin = {1}; }
    txb:  coverpoint txn.data[0][0] // Transmit buffer
      { bins txb_1 = {1}; }
    txb_c  : cross int_srce_addr, txb;
  endgroup

  function new();
    super.new();
    cg = new();
  endfunction

  function void sample();
    cg.sample();
  endfunction
endclass


class busy_coverpoint extends coverpoint_wrapper;
  covergroup cg;
    int_srce_addr: coverpoint txn.adr[11:2]
     // Interrupt Source reg word address is 'h1
      { bins addr_bin = {1}; }
    busy: coverpoint txn.data[0][4] // Busy
      { bins busy_1 = {1}; }
    busy_c : cross int_srce_addr, busy;
  endgroup

  function new();
    super.new();
    cg = new();
  endfunction

  function void sample();
    cg.sample();
  endfunction
endclass


class error_coverpoint extends coverpoint_wrapper;
  covergroup cg;
    int_srce_addr: coverpoint txn.adr[11:2]
     // Interrupt Source reg word address is 'h1
      { bins addr_bin = {1}; }
    rxe:  coverpoint txn.data[0][3] // Receive error
      { bins rxe_1 = {1}; }
    txe:  coverpoint txn.data[0][1] // Transmit error
      { bins txe_1 = {1}; }
    rxe_c  : cross int_srce_addr, rxe;
    txe_c  : cross int_srce_addr, txe;
  endgroup

  function new();
    super.new();
    cg = new();
  endfunction

  function void sample();
    cg.sample();
  endfunction
endclass


class wb_irq_mix_coverage_collector extends uvm_subscriber #(wb_txn);
  `uvm_component_utils(wb_irq_mix_coverage_collector)

  rx_coverpoint rx_cp;
  tx_coverpoint tx_cp;
  busy_coverpoint busy_cp;
  error_coverpoint error_cp;

  coverpoint_wrapper cp_q[$];

// Hard-coded for example. Would normally get these from config
  bit rx_mode = 1;
  bit tx_mode = 1;
  bit busy_mode = 0;
  bit error_mode = 0;
//-------------------------------------------------------------

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
// Depending on configuration params, add coverpoint wrapper objects to queue
    if (rx_mode) begin
      rx_cp = new();
      cp_q.push_back(rx_cp);
    end
    if (tx_mode) begin
      tx_cp = new();
      cp_q.push_back(tx_cp);
    end
    if (busy_mode) begin
      busy_cp = new();
      cp_q.push_back(busy_cp);
    end
    if (error_mode) begin
      error_cp = new();
      cp_q.push_back(error_cp);
    end
  endfunction
 
  function void write(wb_txn t);

// Sample only when reading the MAC irq register
    if (t.txn_type == READ && t.adr == 32'h00100004) begin
      foreach (cp_q[i]) begin
        cp_q[i].txn = t;
        cp_q[i].sample();
      end
    end
  endfunction
 
endclass

`endif
