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


// wrapper module for protocol module and DUTs
`include "uvm_macros.svh"

module wb_bus_wrapper #(int WB_ID = 0, int num_masters = 8, int num_slaves = 8,
                        int data_width = 32, int addr_width = 32);
  import uvm_pkg::*;
  import test_params_pkg::*;
  import wishbone_pkg::*;

  // wires for WISHBONE bus connection
  wire [7:0] irq;
  wire [data_width-1:0]  m_wdata[num_masters];
  wire [addr_width-1:0]  m_addr [num_masters];
  wire m_cyc [num_masters];
  wire m_lock[num_masters];
  wire m_stb [num_masters];
  wire m_we  [num_masters];
  wire m_ack [num_masters];
  wire [7:0] m_sel[num_masters];
  wire [data_width-1:0]  m_rdata;
  wire [data_width-1:0]  s_wdata;
  wire [addr_width-1:0]  s_addr;
  wire [7:0]  s_sel;
  wire s_stb[num_slaves];
  wire [data_width-1:0] s_rdata[num_slaves];
  wire s_err[num_slaves];
  wire s_rty[num_slaves];
  wire s_ack[num_slaves];

  // WISHBONE Protocol Module instance
  // Supports up to 8 masters and up to 8 slaves
  wb_bus_protocol_module #(.WB_ID(WB_ID)) wb_bus_pm 
  (
  .clk( clk ),
  .rst( rst ),
  .irq( irq ),
  // WISHBONE master outputs
  .m_wdata  ( m_wdata ),
  .m_addr   ( m_addr  ),  
  .m_cyc    ( m_cyc   ),
  .m_lock   ( m_lock  ),
  .m_stb    ( m_stb   ),
  .m_we     ( m_we    ),
  .m_ack    ( m_ack   ),
  .m_sel    ( m_sel   ),
  
  // WISHBONE master inputs
  .m_err    (m_err    ),
  .m_rty    (m_rty    ),
  .m_rdata  (m_rdata  ),
  
  // WISHBONE slave inputs
  .s_wdata  ( s_wdata ),
  .s_addr   ( s_addr  ),
  .s_sel    ( s_sel   ),
  .s_cyc    ( s_cyc   ),
  .s_stb    ( s_stb   ),
  .s_we     ( s_we    ),
   
  
  // WISHBONE slave outputs
  .s_rdata  ( s_rdata ),
  .s_err    ( s_err   ),
  .s_rty    ( s_rty   ),
  .s_ack    ( s_ack   )  
  );
  
  //-----------------------------------   
  //  WISHBONE 0, slave 0:  000000 - 0fffff
  //  this is 1 Mbytes of memory
  wb_slave_mem  #(mem_slave_size) wb_s_0 (
    // inputs
    .clk ( clk ),
    .rst ( rst ),
    .adr ( s_addr ),
    .din ( s_wdata ),
    .cyc ( s_cyc ),
    .stb ( s_stb[mem_slave_wb_id]   ),
    .sel ( s_sel[3:0] ),
    .we  ( s_we  ),
    // outputs
    .dout( s_rdata[mem_slave_wb_id] ),
    .ack ( s_ack[mem_slave_wb_id]   ),
    .err ( s_err[mem_slave_wb_id]   ),
    .rty ( s_rty[mem_slave_wb_id]   )
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
    .wb_clk_i( clk ),
    .wb_rst_i( rst ), 
    // WISHBONE slave
    .wb_adr_i( s_addr[11:2] ),
    .wb_sel_i( s_sel[3:0] ),
    .wb_we_i ( s_we  ), 
    .wb_cyc_i( s_cyc ),
    .wb_stb_i( s_stb[mac_slave_wb_id] ),
    .wb_ack_o( s_ack[mac_slave_wb_id] ), 
    .wb_err_o( s_err[mac_slave_wb_id] ),
    .wb_dat_i( s_wdata ),
    .wb_dat_o( s_rdata[mac_slave_wb_id] ), 
    // WISHBONE master
    .m_wb_adr_o( m_addr[mac_m_wb_id]     ),
    .m_wb_sel_o( m_sel[mac_m_wb_id][3:0] ),
    .m_wb_we_o ( m_we[mac_m_wb_id]), 
    .m_wb_dat_i( m_rdata),
    .m_wb_dat_o( m_wdata[mac_m_wb_id] ),
    .m_wb_cyc_o( m_cyc[mac_m_wb_id]   ), 
    .m_wb_stb_o( m_stb[mac_m_wb_id]   ),
    .m_wb_ack_i( m_ack[mac_m_wb_id]   ),
    .m_wb_err_i( m_err),
    // WISHBONE interrupt
    .int_o(irq[0]), 

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
  mac_mii_protocol_module #(.INTERFACE_NAME("MIIM_IF"), .ID(WB_ID)) mii_pm(
    .wb_rst_i(rst),
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
    
endmodule
