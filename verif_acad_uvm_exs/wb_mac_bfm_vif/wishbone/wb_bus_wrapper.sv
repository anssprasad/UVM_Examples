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


// wrapper module for concrete class, BFM and DUT
`include "uvm_macros.svh"

module wb_bus_wrapper #(int WB_ID = 0);
  import uvm_pkg::*;
  import test_params_pkg::*;
  import wishbone_pkg::*;

  // WISHBONE BFM instance
  // Supports up to 8 masters and up to 8 slaves
  wishbone_bus_syscon_bfm wb_bfm();
  
  //-----------------------------------   
  //  WISHBONE 0, slave 0:  000000 - 0fffff
  //  this is 1 Mbytes of memory
  wb_slave_mem  #(mem_slave_size) wb_s_0 (
    // inputs
    .clk ( wb_bfm.clk ),
    .rst ( wb_bfm.rst ),
    .adr ( wb_bfm.s_addr ),
    .din ( wb_bfm.s_wdata ),
    .cyc ( wb_bfm.s_cyc ),
    .stb ( wb_bfm.s_stb[mem_slave_wb_id]   ),
    .sel ( wb_bfm.s_sel[3:0] ),
    .we  ( wb_bfm.s_we  ),
    // outputs
    .dout( wb_bfm.s_rdata[mem_slave_wb_id] ),
    .ack ( wb_bfm.s_ack[mem_slave_wb_id]   ),
    .err ( wb_bfm.s_err[mem_slave_wb_id]   ),
    .rty ( wb_bfm.s_rty[mem_slave_wb_id]   )
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
    .wb_clk_i( wb_bfm.clk ),
    .wb_rst_i( wb_bfm.rst ), 
    // WISHBONE slave
    .wb_adr_i( wb_bfm.s_addr[11:2] ),
    .wb_sel_i( wb_bfm.s_sel[3:0] ),
    .wb_we_i ( wb_bfm.s_we  ), 
    .wb_cyc_i( wb_bfm.s_cyc ),
    .wb_stb_i( wb_bfm.s_stb[mac_slave_wb_id] ),
    .wb_ack_o( wb_bfm.s_ack[mac_slave_wb_id] ), 
    .wb_err_o( wb_bfm.s_err[mac_slave_wb_id] ),
    .wb_dat_i( wb_bfm.s_wdata ),
    .wb_dat_o( wb_bfm.s_rdata[mac_slave_wb_id] ), 
    // WISHBONE master
    .m_wb_adr_o( wb_bfm.m_addr[mac_m_wb_id]     ),
    .m_wb_sel_o( wb_bfm.m_sel[mac_m_wb_id][3:0] ),
    .m_wb_we_o ( wb_bfm.m_we[mac_m_wb_id]), 
    .m_wb_dat_i( wb_bfm.m_rdata),
    .m_wb_dat_o( wb_bfm.m_wdata[mac_m_wb_id] ),
    .m_wb_cyc_o( wb_bfm.m_cyc[mac_m_wb_id]   ), 
    .m_wb_stb_o( wb_bfm.m_stb[mac_m_wb_id]   ),
    .m_wb_ack_i( wb_bfm.m_ack[mac_m_wb_id]   ),
    .m_wb_err_i( wb_bfm.m_err),
    // WISHBONE interrupt
    .int_o(wb_bfm.irq[0]), 

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
    .wb_rst_i(wb_bfm.rst),
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
    
  // Interface
  interface wishbone_bus_bfm_if #(int ID = WB_ID)
    (input bit clk);
      
    // Methods
    //WRITE  1 or more write cycles
    task wb_write_cycle(wb_txn req_txn, bit [2:0] m_id);
      wb_bfm.wb_write_cycle(req_txn, m_id);
    endtask

      //READ 1 or more cycles
    task wb_read_cycle(wb_txn req_txn, bit [2:0] m_id, output wb_txn rsp_txn);
      wb_bfm.wb_read_cycle(req_txn, m_id, rsp_txn);
    endtask

    // wait for an interrupt
    task wb_irq(wb_txn req_txn, output wb_txn rsp_txn);
      wb_bfm.wb_irq(req_txn, rsp_txn);
    endtask
    
    task monitor(output wb_txn txn);    
      wb_bfm.monitor(txn);
    endtask
  endinterface
    
  // Interface instance
  wishbone_bus_bfm_if #(WB_ID) wb_bus_bfm_if(.clk(wb_bfm.clk));
  
  initial  
    //set interface in config space
    uvm_config_db #(virtual wishbone_bus_bfm_if)::set(null, "uvm_test_top",
                                                      $sformatf("WB_BFM_IF_%0d",WB_ID),
                                                      wb_bus_bfm_if);

   
endmodule
