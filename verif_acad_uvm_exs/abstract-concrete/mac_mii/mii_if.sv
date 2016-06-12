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

// Media Independent Interface (MII) for the Media Access Controller (MAC)
// Michael Baird

interface mii_if();

  // PHY interface
  // Connect the Ethernet IP Core (MAC) with the PHY interface
  // Active high is default
  // direction is relative to the Ethernet IP core

  logic mtx_clk;       // Transmit nibble clock
  logic  [3:0] MTxD; // Transmit Data Nibble
  logic MTxEn;         // Transmit Enable
  logic MTxErr;        // Transmit Coding Error

  logic mrx_clk;      // Receive nibble clock
  logic [3:0] MRxD; // Receive Data Nibble
  logic MRxDV;        // Receive Data Valid
  logic MRxErr;       // Receive Error
  logic MColl;        // Collision Detected
  logic MCrs;         // Carrier Sense

  logic Mdi_I;  // Management Data Input
  logic Mdo_O;  // Management Data Output
  logic Mdo_OE; // Management Data Output Enable
  logic Mdc_O;  // Management Data Clock

  // Generate mtx_clk clock
  initial begin
    mtx_clk = 0;
    #3 forever #20 mtx_clk = ~mtx_clk;   // 2*20 ns -> 25 MHz (100Mbps)
  end
  // Generate mrx_clk clock
  initial begin
    mrx_clk = 0;
    #16 forever #20 mrx_clk = ~mrx_clk;   // 2*20 ns -> 25 MHz (100Mbps)
  end
endinterface
