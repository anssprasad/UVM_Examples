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
    
  // Concrete driver class
  class wb_bus_bfm_driver_c #(int ID = WB_ID) extends wb_bus_bfm_driver_base;
  `uvm_component_param_utils(wb_bus_bfm_driver_c #(ID))
  
    function new(string name = "", uvm_component parent = null);
     super.new(name,parent);
    endfunction

    task run_phase(uvm_phase phase);
      wb_txn req_txn;
      forever begin    
        seq_item_port.get(req_txn);  // get transaction
        @ ( posedge wb_bfm.clk) #1;  // sync to clock edge + 1 time step
        case(req_txn.txn_type)  //what type of transaction?
          NONE: `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                                $sformatf("wb_txn %0d the wb_txn_type was type NONE",
                                req_txn.get_transaction_id()),UVM_LOW )
          WRITE: wb_write_cycle(req_txn);
          READ:  wb_read_cycle(req_txn);
          RMW:  wb_rmw_cycle(req_txn);
          WAIT_IRQ: fork wb_irq(req_txn); join_none
          default: `uvm_error($sformatf("WB_M_DRVR_%0d",m_id),
                                    $sformatf("wb_txn %0d the wb_txn_type was type illegal",
                                    req_txn.get_transaction_id()) )
        endcase
      end
    endtask
    
    // Methods
    // calls corresponding BFM methods
    //WRITE  1 or more write cycles
    task wb_write_cycle(wb_txn req_txn);
      wb_txn orig_req_txn;
      $cast(orig_req_txn, req_txn.clone());  //save off copy of original req transaction
      wb_bfm.wb_write_cycle(req_txn, m_id);
      wb_drv_ap.write(orig_req_txn);  //broadcast orignal transaction
    endtask

      //READ 1 or more cycles
    task wb_read_cycle(wb_txn req_txn);
      wb_txn rsp_txn;
      wb_bfm.wb_read_cycle(req_txn, m_id, rsp_txn);
      seq_item_port.put(rsp_txn);  // send rsp object back to sequence
      wb_drv_ap.write(rsp_txn);  //broadcast read transaction with results        
    endtask

    // wait for an interrupt
    task wb_irq(wb_txn req_txn);
      wb_txn rsp_txn;
      wb_bfm.wb_irq(req_txn, rsp_txn);
      seq_item_port.put(rsp_txn);  // send rsp object back to sequence
    endtask
    
    //RMW ( read-modify_write)
    virtual task wb_rmw_cycle(ref wb_txn req_txn);
      `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                      "Wishbone RMW instruction not implemented yet",UVM_LOW )
  endtask
  endclass
    
  // Concrete monitor class
  class wb_bus_bfm_monitor_c #(int ID = WB_ID) extends wb_bus_bfm_mon_base;
  `uvm_component_param_utils(wb_bus_bfm_monitor_c #(ID))

    function new(string name = "", uvm_component parent = null);
     super.new(name,parent);
    endfunction

    task run_phase(uvm_phase phase);
      wb_txn txn;
      forever begin
        wb_bfm.monitor(txn);
        wb_mon_ap.write(txn); // broadcast the wb_txn
      end
    endtask
  
  endclass

  initial begin
    //set inst override of concrete bfm driver for base bfm driver
    wb_bus_bfm_driver_base::type_id::set_inst_override(
        wb_bus_bfm_driver_c #(WB_ID)::get_type(),
        $sformatf("*env_%0d*", WB_ID));
    
    wb_bus_bfm_mon_base::type_id::set_inst_override( 
        wb_bus_bfm_monitor_c #(WB_ID)::get_type(),      
        $sformatf("*env_%0d*", WB_ID));
  end
   
endmodule
