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
`ifndef SPI_DRIVER_BFM
`define SPI_DRIVER_BFM

//
// BFM Description:
//
//
interface spi_driver_bfm (spi_if SPI);
// pragma attribute spi_driver_bfm partition_interface_xif

initial begin
  SPI.miso = 1;
end

task init(); // pragma tbx xtf
  @(negedge SPI.PCLK);
  while(SPI.cs != 8'hff) @(negedge SPI.PCLK);
endtask: init

// This driver is really an SPI slave responder
task do_item(logic[127:0] spi_data, bit[6:0] no_bits, bit RX_NEG); // pragma tbx xtf
  bit[7:0] num_bits;

  @(negedge SPI.PCLK);

  while(SPI.cs == 8'hff) @(negedge SPI.PCLK);

  //$display("@ %0t: (spi_driver_bfm::do_item) Starting transmission: %0h RX_NEG State %b, no_bits %0d", $time, spi_data, RX_NEG, no_bits);
  num_bits = no_bits;
  if(num_bits == 0) begin
    num_bits = 128;
  end
  SPI.miso <= spi_data[0];
  for(int i = 1; i < num_bits-1; i++) begin
	 @(negedge SPI.PCLK);                          // \
    while(SPI.clk == RX_NEG) @(negedge SPI.PCLK); //  |- mimics if (RX_NEG == 1) @(posedge SPI.clk) else @(negedge SPI.clk)
    while(SPI.clk != RX_NEG) @(negedge SPI.PCLK); // /
    SPI.miso <= spi_data[i];
    if(SPI.cs == 8'hff) begin
      break;
    end
  end
endtask: do_item

endinterface: spi_driver_bfm

`endif // SPI_DRIVER_BFM
