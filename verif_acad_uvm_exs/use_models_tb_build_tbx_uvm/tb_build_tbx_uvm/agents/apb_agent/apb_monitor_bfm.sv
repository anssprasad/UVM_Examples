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
`ifndef APB_MONITOR_BFM
`define APB_MONITOR_BFM

//
// BFM Description:
//
//
interface apb_monitor_bfm(apb_if APB);
// pragma attribute apb_monitor_bfm partition_interface_xif

import apb_shared_pkg::apb_seq_item_s;
import apb_agent_pkg::apb_monitor;

apb_monitor proxy; // pragma tbx oneway proxy.write

task run(int index); // pragma tbx xtf
  apb_seq_item_s item;

  @(posedge APB.PCLK);

  forever begin
    // Detect the protocol event on the TBAI virtual interface
    @(posedge APB.PCLK);
    if(APB.PREADY && APB.PSEL[index]) // index identifies PSEL line this monitor is connected to

    // Assign the relevant values to the analysis item fields
      begin
        item.addr = APB.PADDR;
        item.we = APB.PWRITE;
        if(APB.PWRITE)
          begin
            item.data = APB.PWDATA;
          end
        else
          begin
            item.data = APB.PRDATA;
          end
        // Publish the item to the subscribers
        proxy.write(item);
      end
  end
endtask: run

endinterface: apb_monitor_bfm

`endif // APB_MONITOR_BFM
