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



module mac_mii_protocol_module #(string INTERFACE_NAME = "") (
  input   logic       wb_rst_i,
// Tx
  output  logic       mtx_clk_pad_o, // Transmit clock (from PHY)
  input   logic[3:0]  mtxd_pad_o,    // Transmit nibble (to PHY)
  input   logic       mtxen_pad_o,   // Transmit enable (to PHY)
  input   logic       mtxerr_pad_o,  // Transmit error (to PHY)

// Rx
  output  logic       mrx_clk_pad_o, // Receive clock (from PHY)
  output  logic[3:0]  mrxd_pad_i,    // Receive nibble (from PHY)
  output  logic       mrxdv_pad_i,   // Receive data valid (from PHY)
  output  logic       mrxerr_pad_i,  // Receive data error (from PHY)

// Common Tx and Rx
  output  logic       mcoll_pad_i,   // Collision (from PHY)
  output  logic       mcrs_pad_i,    // Carrier sense (from PHY)

// MII Management interface
  output  logic       md_pad_i,      // MII data input (from I/O cell)
  input   logic       mdc_pad_o,     // MII Management data clock (to PHY)
  input   logic       md_pad_o,      // MII data output (to I/O cell)
  input   logic       md_padoe_o    // MII data output enable (to I/O cell)
);
  import uvm_pkg::*;

// Instantiate interface
  mii_if miim_if();

// Connect interface to protocol signals through module ports
  assign mtx_clk_pad_o = miim_if.mtx_clk;
  assign miim_if.MTxD = mtxd_pad_o;
  assign miim_if.MTxEn = mtxen_pad_o;
  assign miim_if.MTxErr = mtxerr_pad_o ;

  assign mrx_clk_pad_o = miim_if.mrx_clk;
  assign mrxd_pad_i = miim_if.MRxD;
  assign mrxdv_pad_i = miim_if.MRxDV ;
  assign mrxerr_pad_i = miim_if.MRxErr ;

  assign mcoll_pad_i = miim_if.MColl  ;
  assign mcrs_pad_i = miim_if.MCrs    ;

  assign md_pad_i = miim_if.Mdi_I     ;
  assign miim_if.Mdc_O = mdc_pad_o    ;
  assign miim_if.Mdo_O = md_pad_o     ;
  assign miim_if.Mdo_OE = md_padoe_o  ;
  
/*
// Not included in example because QVL is a Questa licensed product

// Instantiate QVL Checker
    qvl_gigabit_ethernet_mii_monitor mii_monitor(
    .areset(1'b0),
    .reset(wb_rst_i),
    .tx_clk(miim_if.mtx_clk),
    .txd(miim_if.MTxD),
    .tx_en(miim_if.MTxEn),
    .tx_er(miim_if.MTxErr),
    .rx_clk(miim_if.mrx_clk),
    .rxd(miim_if.MRxD),
    .rx_dv(miim_if.MRxDV),
    .rx_er(miim_if.MRxErr),
    .col(miim_if.MColl),
    .crs(miim_if.MCrs)    ,
    .half_duplex(1'b0)
    );  
*/

// Connect interface to testbench virtual interface
  string interface_name = (INTERFACE_NAME == "") ? $sformatf("%m") : INTERFACE_NAME;

  initial begin
    uvm_config_db #(virtual mii_if)::set(null, "uvm_test_top",interface_name, miim_if);
  end

endmodule
