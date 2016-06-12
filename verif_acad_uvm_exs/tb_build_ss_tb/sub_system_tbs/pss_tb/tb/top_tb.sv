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
import pss_test_lib_pkg::*;

// PCLK and PRESETn
//
logic HCLK;
logic HRESETn;

//
// Instantiate the interfaces:
//
apb_if APB(HCLK, HRESETn); // APB interface - shared between passive agents
ahb_if AHB(HCLK, HRESETn);   // AHB interface
spi_if SPI();  // SPI Interface
intr_if INTR();   // Interrupt
gpio_if GPO();
gpio_if GPI();
gpio_if GPOE();
icpit_if ICPIT();
serial_if UART_RX();
serial_if UART_TX();
modem_if MODEM();

// Binder
binder probe();

// DUT Wrapper:
pss_wrapper wrapper(.ahb(AHB),
                   .spi(SPI),
                   .gpi(GPI),
                   .gpo(GPO),
                   .gpoe(GPOE),
                   .icpit(ICPIT),
                   .uart_rx(UART_RX),
                   .uart_tx(UART_TX),
                   .modem(MODEM));


// UVM initial block:
// Virtual interface wrapping & run_test()
initial begin
  uvm_config_db #(virtual apb_if)::set(null,"uvm_test_top","APB_vif" , APB);
  uvm_config_db #(virtual ahb_if)::set(null,"uvm_test_top","AHB_vif" , AHB);
  uvm_config_db #(virtual spi_if)::set(null,"uvm_test_top","SPI_vif" , SPI);
  uvm_config_db #(virtual intr_if)::set(null,"uvm_test_top","INTR_vif", INTR);
  uvm_config_db #(virtual gpio_if)::set(null,"uvm_test_top","GPO_vif" , GPO);
  uvm_config_db #(virtual gpio_if)::set(null,"uvm_test_top","GPOE_vif" , GPOE);
  uvm_config_db #(virtual gpio_if)::set(null,"uvm_test_top","GPI_vif" , GPI);
  uvm_config_db #(virtual icpit_if)::set(null,"uvm_test_top","ICPIT_vif" , ICPIT);
  uvm_config_db #(virtual serial_if)::set(null,"uvm_test_top","UART_RX_vif" , UART_RX);
  uvm_config_db #(virtual serial_if)::set(null,"uvm_test_top","UART_TX_vif" , UART_TX);
  uvm_config_db #(virtual modem_if)::set(null,"uvm_test_top","MODEM_vif" , MODEM);
  run_test();
end

//
// Clock and reset initial block:
//
initial begin
  HCLK = 0;
  HRESETn = 0;
  repeat(8) begin
    #10ns HCLK = ~HCLK;
  end
  HRESETn = 1;
  forever begin
    #10ns HCLK = ~HCLK;
  end
end

// Clock assignments:
assign GPO.clk = HCLK;
assign GPOE.clk = HCLK;
assign GPI.clk = HCLK;
assign ICPIT.PCLK = HCLK;

endmodule: top_tb
