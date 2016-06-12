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

module top_tb;

import uvm_pkg::*;
import icpit_test_pkg::*;

logic PCLK;
logic PRESETN;

// Instantiate DUT and interfaces:
apb_if APB(.PCLK(PCLK), .PRESETn(PRESETN));
icpit_if ICPIT();

icpit DUT(// APB Interface signals:
          .PCLK(APB.PCLK),
          .PRESETN(APB.PRESETn),
          .PADDR(APB.PADDR[4:2]),
          .PSEL(APB.PSEL[0]),
          .PENABLE(APB.PENABLE),
          .PWRITE(APB.PWRITE),
          .PWDATA(APB.PWDATA),
          .PRDATA(APB.PRDATA),
          .PREADY(APB.PREADY),
              // Interrupt signals:
          .IRQ(ICPIT.IRQ),
          .IREQ(ICPIT.IREQ),
              // PIT Terminal Count
          .PIT_OUT(ICPIT.PIT_OUT),
              // Watchdog Terminal Count
          .WATCHDOG(ICPIT.WDOG));

initial begin
  uvm_config_db #(virtual apb_if)::set(null,"uvm_test_top","APB_vif" , APB);
  uvm_config_db #(virtual icpit_if)::set(null,"uvm_test_top","ICPIT_vif" , ICPIT);
  run_test();
end

// Clock and reset
initial begin
  PRESETN = 0;
  PCLK = 0;
  repeat(10) begin
    PCLK = #1ns ~PCLK;
  end
    PRESETN = 1;
  forever begin
    PCLK = #1ns ~PCLK;
  end
end

assign ICPIT.PCLK = PCLK;
assign ICPIT.PRESETN = PRESETN;

// Interrupts:
initial begin
  ICPIT.IREQ = 0;

  forever begin
    #6ns ICPIT.IREQ = 0;
    #100ns;
    randcase
      1: ICPIT.IREQ[0] = 1;
      1: ICPIT.IREQ[1] = 1;
      1: ICPIT.IREQ[2] = 1;
      1: ICPIT.IREQ[3] = 1;
      1: ICPIT.IREQ[4] = 1;
      1: ICPIT.IREQ[5] = 1;
      1: ICPIT.IREQ[6] = 1;
      1: ICPIT.IREQ[7] = 1;
    endcase
  end
end

endmodule: top_tb
