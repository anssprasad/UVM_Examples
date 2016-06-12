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
`ifndef SPI_AGENT_BFM
`define SPI_AGENT_BFM

//
// Class Description:
//
//
module spi_agent_bfm(spi_if SPI);

spi_monitor_bfm monitor(SPI.monitor_mp);
spi_driver_bfm  driver(SPI.driver_mp);

//if(SPI_IS_ACTIVE) begin: has_driver
//  spi_driver_bfm driver(SPI.driver_mp);
//end

endmodule: spi_agent_bfm

`endif // SPI_AGENT_BFM
