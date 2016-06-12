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

// Top level module for a wishbone system with bus connection
// multiple masters and slaves
// Mike Baird
//----------------------------------------------
`timescale 1ns / 1ns

module top_mac;
  import uvm_pkg::*;
  import tests_pkg::*;
  import test_params_pkg::*;

  // WISHBONE interface instance
  // Supports up to 8 masters and up to 8 slaves
  wishbone_bus_syscon_if wb_bus_if();
  
  
  //-----------------------------------   
  //  WISHBONE 0, slave 0:  000000 - 0fffff
  //  this is 1 Mbytes of memory
  wb_slave_mem  #(mem_slave_size) wb_s_0 (
    // inputs
    .clk ( wb_bus_if.clk ),
    .rst ( wb_bus_if.rst ),
    .adr ( wb_bus_if.s_addr ),
    .din ( wb_bus_if.s_wdata ),
    .cyc ( wb_bus_if.s_cyc ),
    .stb ( wb_bus_if.s_stb[mem_slave_wb_id]   ),
    .sel ( wb_bus_if.s_sel[3:0] ),
    .we  ( wb_bus_if.s_we  ),
    // outputs
    .dout( wb_bus_if.s_rdata[mem_slave_wb_id] ),
    .ack ( wb_bus_if.s_ack[mem_slave_wb_id]   ),
    .err ( wb_bus_if.s_err[mem_slave_wb_id]   ),
    .rty ( wb_bus_if.s_rty[mem_slave_wb_id]   )
  );

  // wires for MAC MII connection
  wire [3:0] MTxD;
  wire [3:0] MRxD;

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
    .wb_stb_i( wb_bus_if.s_stb[mac_slave_wb_id] ),
    .wb_ack_o( wb_bus_if.s_ack[mac_slave_wb_id] ), 
    .wb_err_o( wb_bus_if.s_err[mac_slave_wb_id] ),
    .wb_dat_i( wb_bus_if.s_wdata ),
    .wb_dat_o( wb_bus_if.s_rdata[mac_slave_wb_id] ), 
    // WISHBONE master
    .m_wb_adr_o( wb_bus_if.m_addr[mac_m_wb_id]     ),
    .m_wb_sel_o( wb_bus_if.m_sel[mac_m_wb_id][3:0] ),
    .m_wb_we_o ( wb_bus_if.m_we[mac_m_wb_id]), 
    .m_wb_dat_i( wb_bus_if.m_rdata),
    .m_wb_dat_o( wb_bus_if.m_wdata[mac_m_wb_id] ),
    .m_wb_cyc_o( wb_bus_if.m_cyc[mac_m_wb_id]   ), 
    .m_wb_stb_o( wb_bus_if.m_stb[mac_m_wb_id]   ),
    .m_wb_ack_i( wb_bus_if.m_ack[mac_m_wb_id]   ),
    .m_wb_err_i( wb_bus_if.m_err),
    // WISHBONE interrupt
    .int_o(wb_bus_if.irq[0]), 

    //MII TX
    .mtx_clk_pad_i(mtx_clk),
    .mtxd_pad_o(MTxD),
    .mtxen_pad_o(MTxEn),
    .mtxerr_pad_o(MTxErr),
    //MII RX
    .mrx_clk_pad_i(mrx_clk),
    .mrxd_pad_i(MRxD), 
    .mrxdv_pad_i(MRxDV), 
    .mrxerr_pad_i(MRxErr), 
    .mcoll_pad_i(MColl),    
    .mcrs_pad_i(MCrs), 
    // MII Management Data
    .mdc_pad_o(Mdc_O), 
    .md_pad_i(Mdi_I), 
    .md_pad_o(Mdo_O), 
    .md_padoe_o(Mdo_OE)

  );

  // protocol module for MAC MII interface
  mac_mii_protocol_module #(.INTERFACE_NAME("MIIM_IF")) mii_pm(
    .wb_rst_i(wb_bus_if.rst),
    //MII TX
    .mtx_clk_pad_o(mtx_clk),
    .mtxd_pad_o(MTxD),
    .mtxen_pad_o(MTxEn),
    .mtxerr_pad_o(MTxErr),
    //MII RX
    .mrx_clk_pad_o(mrx_clk),
    .mrxd_pad_i(MRxD), 
    .mrxdv_pad_i(MRxDV), 
    .mrxerr_pad_i(MRxErr), 
    .mcoll_pad_i(MColl),    
    .mcrs_pad_i(MCrs), 
    // MII Management Data
    .mdc_pad_o(Mdc_O), 
    .md_pad_i(Mdi_I), 
    .md_pad_o(Mdo_O), 
    .md_padoe_o(Mdo_OE)
);
  
  initial begin 
    //set interfaces in config space
    uvm_config_db #(virtual wishbone_bus_syscon_if)::set(null, "uvm_test_top",
                                                         "WB_BUS_IF",
                                                         wb_bus_if);

    run_test("test_mac_simple_duplex");  // create and start running test
  end
  
endmodule
