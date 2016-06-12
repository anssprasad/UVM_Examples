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

//  Top level module for a wishbone system with bus connection
// multiple masters and slaves
// Mike Baird
//----------------------------------------------
`timescale 1ns / 1ns

module top_mac;
  import uvm_pkg::*;
  import tests_pkg::*;

  // WISHBONE interface instance
  // Supports up to 8 masters and up to 8 slaves
  wishbone_bus_syscon_if wb_bus_if();
  
  // MII interface instance
  mii_if miim_if();
  
  //-----------------------------------   
  //  WISHBONE 0, slave 0:  000000 - 0fffff
  //  this is 1 Mbytes of memory
  wb_slave_mem  #(18) wb_s_0 (
    // inputs
    .clk ( wb_bus_if.clk ),
    .rst ( wb_bus_if.rst ),
    .adr ( wb_bus_if.s_addr ),
    .din ( wb_bus_if.s_wdata ),
    .cyc ( wb_bus_if.s_cyc ),
    .stb ( wb_bus_if.s_stb[0] ),
    .sel ( wb_bus_if.s_sel[3:0] ),
    .we  ( wb_bus_if.s_we  ),
    // outputs
    .dout( wb_bus_if.s_rdata[0] ),
    .ack ( wb_bus_if.s_ack[0] ),
    .err ( wb_bus_if.s_err[0] ),
    .rty ( wb_bus_if.s_rty[0] )
  );

  //-----------------------------------   
  // MAC 0 
  // It is WISHBONE slave 1: address range 100000 - 100fff
  // It is WISHBONE Master 0
  eth_top mac_0
  (
    // WISHBONE common
    .wb_clk_i( wb_bus_if.clk ),
    .wb_rst_i( wb_bus_if.rst ), 
    // WISHBONE slave
    .wb_adr_i( wb_bus_if.s_addr[11:2] ),
    .wb_sel_i( wb_bus_if.s_sel[3:0] ),
    .wb_we_i ( wb_bus_if.s_we  ), 
    .wb_cyc_i( wb_bus_if.s_cyc ),
    .wb_stb_i( wb_bus_if.s_stb[1] ),
    .wb_ack_o( wb_bus_if.s_ack[1] ), 
    .wb_err_o( wb_bus_if.s_err[1] ),
    .wb_dat_i( wb_bus_if.s_wdata ),
    .wb_dat_o( wb_bus_if.s_rdata[1] ), 
    // WISHBONE master
    .m_wb_adr_o( wb_bus_if.m_addr[0]),
    .m_wb_sel_o( wb_bus_if.m_sel[0][3:0]),
    .m_wb_we_o ( wb_bus_if.m_we[0]), 
    .m_wb_dat_i( wb_bus_if.m_rdata),
    .m_wb_dat_o( wb_bus_if.m_wdata[0]),
    .m_wb_cyc_o( wb_bus_if.m_cyc[0]), 
    .m_wb_stb_o( wb_bus_if.m_stb[0]),
    .m_wb_ack_i( wb_bus_if.m_ack[0]),
    .m_wb_err_i( wb_bus_if.m_err),
    // WISHBONE interrupt
    .int_o(wb_bus_if.irq[0]), 

    //MII TX
    .mtx_clk_pad_i(miim_if.mtx_clk),
    .mtxd_pad_o(miim_if.MTxD),
    .mtxen_pad_o(miim_if.MTxEn),
    .mtxerr_pad_o(miim_if.MTxErr),
    //MII RX
    .mrx_clk_pad_i(miim_if.mrx_clk),
    .mrxd_pad_i(miim_if.MRxD), 
    .mrxdv_pad_i(miim_if.MRxDV), 
    .mrxerr_pad_i(miim_if.MRxErr), 
    .mcoll_pad_i(miim_if.MColl),    
    .mcrs_pad_i(miim_if.MCrs), 
    // MII Management Data
    .mdc_pad_o(miim_if.Mdc_O), 
    .md_pad_i(miim_if.Mdi_I), 
    .md_pad_o(miim_if.Mdo_O), 
    .md_padoe_o(miim_if.Mdo_OE)

  );
  
/*
// Not included in build since it is a Questa licensed product:

  qvl_gigabit_ethernet_mii_monitor mii_monitor(
    .areset(1'b0),
    .reset(wb_bus_if.rst),
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
   
  initial begin 
    //set interfaces in config space
    uvm_config_db #(virtual mii_if)::set(null, "uvm_test_top", "MIIM_IF",
                                         miim_if);
    uvm_config_db #(virtual wishbone_bus_syscon_if)::set(null, "uvm_test_top",
                                                         "WB_BUS_IF",
                                                         wb_bus_if);

    run_test("test_mac_simple_duplex");  // create env and start running test
  end
  
endmodule
