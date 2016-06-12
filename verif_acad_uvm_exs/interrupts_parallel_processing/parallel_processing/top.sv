//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------

interface control_if;

  logic clk;
  logic rst;
  logic go_0;
  logic go_1;
  logic go_2;
  logic go_3;

endinterface: control_if

interface intr_if;

  logic irq0;
  logic irq1;
  logic irq2;
  logic irq3;

endinterface: intr_if


module top_tb;

import uvm_pkg::*;
import dsp_con_pkg::*;

intr_if IRQ();
control_if CONTROL();

dsp_chain DUT(.intr(IRQ), .control(CONTROL));


// Clock-Reset
initial begin
  CONTROL.clk = 0;
  CONTROL.rst = 1;
  repeat(6) begin
    #10ns CONTROL.clk = ~CONTROL.clk;
  end
  CONTROL.rst = 0;
  forever begin
    #10ns CONTROL.clk = ~CONTROL.clk;
  end
end

initial begin
  uvm_config_db #(virtual intr_if)::set(null, "uvm_test_top", "IRQ_vif", IRQ);
  uvm_config_db #(virtual control_if)::set(null, "uvm_test_top", "CONTROL_vif", CONTROL);
  run_test("dsp_con_test");
end

endmodule: top_tb
