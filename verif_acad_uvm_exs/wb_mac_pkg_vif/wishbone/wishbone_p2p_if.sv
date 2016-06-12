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

// Wishbone point to point interface
// Mike Baird 
// Note:  wishbone is a byte addressable bus of up to 64 bits of data

interface wishbone_p2p_if #(int data_width = 32, int addr_width = 32) ();

 bit clk;
 bit rst;
 logic [data_width-1:0] wdata, rdata;
 logic [addr_width-1:0] adr;
 bit [7:0] sel;
 bit ack;
 bit cyc;
 bit err;
 bit rty;
 bit we;
 bit stb;
 bit lock;  // note unused in point to point connections
 
 modport master (output wdata, adr, sel, cyc, we, stb, lock,
                  input rst, rdata, ack, err, rty);
                
 modport slave  ( input rst, wdata, adr, sel, cyc, we, stb, lock,
                 output rdata, ack, err, rty);
 
   //clk generation
 always  #5 clk = ~ clk;
 
 // reset generation
 initial begin
   rst = 1;
   repeat(5) @ (posedge clk) ;
   rst = 0;
 end

endinterface
