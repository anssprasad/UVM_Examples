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


module wb_bus_protocol_module(

  // WISHBONE common signals
  output bit clk;
  output bit rst;
  input  bit [7:0] irq;
  // WISHBONE master outputs
  input  logic [data_width-1:0]  m_wdata[num_masters];
  input  logic [addr_width-1:0]  m_addr [num_masters];
  input  bit m_cyc [num_masters];
  input  bit m_lock[num_masters];
  input  bit m_stb [num_masters];
  input  bit m_we  [num_masters];
  input  bit m_ack [num_masters];
  input  bit [7:0] m_sel[num_masters];
  
  // WISHBONE master inputs
  output bit m_err;
  output bit m_rty;
  output logic [data_width-1:0]  m_rdata;
  
  // WISHBONE slave inputs
  output logic [data_width-1:0]  s_wdata;
  output logic [addr_width-1:0]  s_addr;
  output bit [7:0]  s_sel;
  output bit s_cyc;
  output bit s_stb[num_slaves]; //only input not shared since it is the select
  output bit s_we;
   
  
  // WISHBONE slave outputs
  input  logic [data_width-1:0] s_rdata[num_slaves];
  input  bit s_err[num_slaves];
  input  bit s_rty[num_slaves];
  input  bit s_ack[num_slaves];
  
  // WISHBONE common signals
  assign clk = wb_bfm.clk;
  output bit rst;
  input  bit [7:0] irq;
  // WISHBONE master outputs
  input  logic [data_width-1:0]  m_wdata[num_masters];
  input  logic [addr_width-1:0]  m_addr [num_masters];
  input  bit m_cyc [num_masters];
  input  bit m_lock[num_masters];
  input  bit m_stb [num_masters];
  input  bit m_we  [num_masters];
  input  bit m_ack [num_masters];
  input  bit [7:0] m_sel[num_masters];
  
  // WISHBONE master inputs
  output bit m_err;
  output bit m_rty;
  output logic [data_width-1:0]  m_rdata;
  
  // WISHBONE slave inputs
  output logic [data_width-1:0]  s_wdata;
  output logic [addr_width-1:0]  s_addr;
  output bit [7:0]  s_sel;
  output bit s_cyc;
  output bit s_stb[num_slaves]; //only input not shared since it is the select
  output bit s_we;
   
  
  // WISHBONE slave outputs
  input  logic [data_width-1:0] s_rdata[num_slaves];
  input  bit s_err[num_slaves];
  input  bit s_rty[num_slaves];
  input  bit s_ack[num_slaves];
    

  wishbone_bus_syscon_bfm wb_bfm();

endmodule
