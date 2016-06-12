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


// wrapper module for WISHBONE bus BFM & concrete class
//  instances
`include "uvm_macros.svh"

module wb_bus_protocol_module #(int WB_ID = 0, int num_masters = 8, int num_slaves = 8,
                                   int data_width = 32, int addr_width = 32)
  (
  // Port declarations
  // WISHBONE common signals
  output logic clk,
  output logic rst,
  input  logic [7:0] irq,
  // WISHBONE master outputs
  input  logic [data_width-1:0]  m_wdata[num_masters],
  input  logic [addr_width-1:0]  m_addr [num_masters],
  input  logic m_cyc [num_masters],
  input  logic m_lock[num_masters],
  input  logic m_stb [num_masters],
  input  logic m_we  [num_masters],
  input  logic [7:0] m_sel[num_masters],
  
  // WISHBONE master inputs
  output logic m_ack [num_masters],
  output logic m_err,
  output logic m_rty,
  output logic [data_width-1:0]  m_rdata,
  
  // WISHBONE slave inputs
  output logic [data_width-1:0]  s_wdata,
  output logic [addr_width-1:0]  s_addr,
  output logic [7:0]  s_sel,
  output logic s_cyc,
  output logic s_stb[num_slaves], //only input not shared since it is the select
  output logic s_we,
   
  
  // WISHBONE slave outputs
  input  logic [data_width-1:0] s_rdata[num_slaves],
  input  logic s_err[num_slaves],
  input  logic s_rty[num_slaves],
  input  logic s_ack[num_slaves]
  );
  import uvm_pkg::*;
  import test_params_pkg::*;
  import wishbone_pkg::*;
    
  // Concrete class declaration
  class wb_bus_concr_c #(int ID = WB_ID) extends wb_bus_abs_c;
//  `uvm_component_param_utils(wb_bus_concr_c #(ID))
  
    function new(string name = "", uvm_component parent = null);
     super.new(name,parent);
    endfunction

    // API methods
    // simply call corresponding BFM methods
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
    
    task run_phase(uvm_phase phase);
      forever @ (posedge clk)
       -> pos_edge_clk;
    endtask
    
  endclass
    
  // instance of concrete class
  wb_bus_concr_c wb_bus_concr_c_inst;
  
  // lazy allocation of concrete class
  function wb_bus_abs_c get_wb_bus_concr_c_inst();
   if(wb_bus_concr_c_inst == null)
    wb_bus_concr_c_inst = new();
   return (wb_bus_concr_c_inst);   
  endfunction 

  initial 
    //set concrete class object in config space
    uvm_config_db #(wb_bus_abs_c)::set(null, "*",
                                      $sformatf("WB_BUS_CONCR_INST_%0d",WB_ID),
                                       get_wb_bus_concr_c_inst());
    //uvm_container #(wb_bus_abs_c)::set_value_in_global_config(
    //   $sformatf("WB_BUS_CONCR_INST_%0d",WB_ID) , get_wb_bus_concr_c_inst());

  // WISHBONE BFM instance
  wishbone_bus_syscon_bfm wb_bfm(
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

endmodule
