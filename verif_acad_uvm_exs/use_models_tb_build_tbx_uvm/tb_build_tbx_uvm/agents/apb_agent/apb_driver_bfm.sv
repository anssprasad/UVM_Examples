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
`ifndef APB_DRIVER_BFM
`define APB_DRIVER_BFM

//
// BFM Description:
//
//
interface apb_driver_bfm (apb_if APB);
// pragma attribute apb_driver_bfm partition_interface_xif

import apb_shared_pkg::apb_seq_item_s;

initial begin
  APB.PSEL <= 0;
  APB.PENABLE <= 0;
  APB.PADDR <= 0;
end

task do_item(apb_seq_item_s req, int psel_index, output apb_seq_item_s rsp); // pragma tbx xtf
  @(posedge APB.PCLK);
  repeat(req.delay-1) // ok since delay is constrained to be between 1 and 20
    @(posedge APB.PCLK);

  rsp = req;
  rsp.error = (psel_index < 0);

  if(rsp.error) return;

  APB.PSEL[psel_index] <= 1;
  APB.PADDR <= req.addr;
  APB.PWDATA <= req.data;
  APB.PWRITE <= req.we;
  @(posedge APB.PCLK);
  APB.PENABLE <= 1;
  while (!APB.PREADY)
    @(posedge APB.PCLK);
  if(APB.PWRITE == 0)
  begin
    rsp.data = APB.PRDATA;
  end
  APB.PSEL <= 0;
  APB.PENABLE <= 0;
  APB.PADDR <= 0;
endtask: do_item

endinterface: apb_driver_bfm

`endif // APB_DRIVER_BFM
