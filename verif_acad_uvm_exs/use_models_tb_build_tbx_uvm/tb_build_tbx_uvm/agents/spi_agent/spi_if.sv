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
// Interface: spi_if
//
// Note signal bundle only
interface spi_if(input PCLK,
                 input PRESETn);

  logic clk;
  logic[7:0] cs;
  logic miso;
  logic mosi;

  modport driver_mp (
    output miso,
    input cs,
    input clk,
    input PCLK, PRESETn
  );

  modport monitor_mp (
    input cs, miso, mosi,
    input clk,
    input PCLK, PRESETn
  );

endinterface: spi_if
