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

class dsp_con_config extends uvm_object;

`uvm_object_utils(dsp_con_config)

virtual control_if CONTROL;
virtual intr_if    IRQ;

function new(string name = "dsp_con_config");
  super.new(name);
endfunction

//
// Convenience methods:
//
task wait_for_reset;
  @(negedge CONTROL.rst);
endtask: wait_for_reset

task wait_for_clock;
  @(posedge CONTROL.clk);
endtask: wait_for_clock

task wait_for_irq0;
  @(posedge IRQ.irq0);
endtask: wait_for_irq0

task wait_for_irq1;
  @(posedge IRQ.irq1);
endtask: wait_for_irq1

task wait_for_irq2;
  @(posedge IRQ.irq2);
endtask: wait_for_irq2

task wait_for_irq3;
  @(posedge IRQ.irq3);
endtask: wait_for_irq3


endclass: dsp_con_config
