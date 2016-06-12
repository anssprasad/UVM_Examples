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
`ifndef SPI_MONITOR_BFM
`define SPI_MONITOR_BFM

//
// BFM Description:
//
//
interface spi_monitor_bfm(spi_if SPI);
// pragma attribute spi_monitor_bfm partition_interface_xif

import spi_agent_pkg::spi_monitor;

spi_monitor proxy; // pragma tbx oneway proxy.write

task run(); // pragma tbx xtf
  logic[127:0] nedge_mosi;
  logic[127:0] pedge_mosi;
  logic[127:0] nedge_miso;
  logic[127:0] pedge_miso;
  logic[7:0] cs;
  int n;
  int p;
  bit clk_val;

  @(negedge SPI.PCLK);

  while(SPI.cs != 8'hff) @(negedge SPI.PCLK);

  forever begin
    while(SPI.cs == 8'hff) @(negedge SPI.PCLK);

    n = 0;
    p = 0;
    nedge_mosi <= 0;
    pedge_mosi <= 0;
    nedge_miso <= 0;
    pedge_miso <= 0;
    cs <= SPI.cs;

    clk_val = SPI.clk;                             // \
    @(negedge SPI.PCLK);                           //  |- mimics @(SPI.clk);
    while(SPI.clk == clk_val) @(negedge SPI.PCLK); // /

    while(SPI.cs == cs) begin
      if(SPI.clk == 1) begin
        nedge_mosi[p] <= SPI.mosi;
        nedge_miso[p] <= SPI.miso;
        p++;
      end
      else begin
        pedge_mosi[n] <= SPI.mosi;
        pedge_miso[n] <= SPI.miso;
        //$display("%t sample %0h, pedge_mosi[%0d] = %b", $time, pedge_mosi, n, SPI.mosi);
        n++;
      end
      clk_val = SPI.clk;              // \
      @(negedge SPI.PCLK);            //  \
      while(SPI.clk == clk_val) begin //   |- mimics @(SPI.clk) with premature break on SPI.cs change
        @(negedge SPI.PCLK);          //  /
        if (SPI.cs != cs) break;      // /
      end
    end

/*
    $display("nedge_mosi: %0h", nedge_mosi);
    $display("pedge_mosi: %0h", pedge_mosi);
    $display("nedge_miso: %0h", nedge_miso);
    $display("pedge_miso: %0h", pedge_miso);
*/
    // Publish to the subscribers
    proxy.write(nedge_mosi, pedge_mosi, nedge_miso, pedge_miso, cs);
  end
endtask: run

endinterface: spi_monitor_bfm

`endif // SPI_MONITOR_BFM
