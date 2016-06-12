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
//
// Interface: intr_if
//
interface intr_if(input PCLK,
                  input PRESETn);
// pragma attribute intr_if partition_interface_xif

  logic IRQ;

  task wait_for_interrupt(); // pragma tbx xtf
    @(posedge IRQ);
/*
    @(posedge PCLK);
    wait(IRQ == 1);
    @(posedge PCLK);
*/
  endtask: wait_for_interrupt

  function bit is_interrupt_cleared(); // pragma tbx xtf
    if(IRQ == 0)
      return 1;
    else
      return 0;
  endfunction: is_interrupt_cleared

  task wait_n_cycles(int n); // pragma tbx xtf
    @(posedge PCLK);
    assert(n>0);
    repeat (n-1) @(posedge PCLK);
  endtask: wait_n_cycles

endinterface: intr_if
