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

// Wishbone bus system interconnect (syscon)
// for multiple master, multiple slave bus
// max 8 masters and 8 slaves
// Mike Baird

  `include "uvm_macros.svh"

import uvm_pkg::*;  // need reporter
import wishbone_pkg::*;
module wishbone_bus_syscon_bfm #(int num_masters = 8, int num_slaves = 8,
                                   int data_width = 32, int addr_width = 32)
  (
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
  output  logic m_ack [num_masters],
  output logic m_err,
  output logic m_rty,
  output logic [data_width-1:0]  m_rdata,
  
  // WISHBONE slave inputs
  output logic [data_width-1:0]  s_wdata,
  output logic [addr_width-1:0]  s_addr,
  output logic [7:0]  s_sel,
  output logic s_cyc,
  output logic s_stb[num_slaves], 
  output logic s_we,   
  
  // WISHBONE slave outputs
  input  logic [data_width-1:0] s_rdata[num_slaves],
  input  logic s_err[num_slaves],
  input  logic s_rty[num_slaves],
  input  logic s_ack[num_slaves]
  );
  
  //Wishbone Revision B.3.  Typically not used
  bit [2:0]  m_cti[num_masters];   // Cycle Type Identifier
  bit [1:0]  m_bte[num_masters];   // Burst Type Extension
  bit [2:0]  s_cti;   // Cycle Type Identifier
  bit [1:0]  s_bte;   // Burst Type Extension


//clk generation
//--------------------------------
  initial begin
    clk = 0;
    forever #12.5 clk = ~ clk;   // 2*12.5 ns -> 40 MHz
  end
  
// reset generation
//--------------------------------
 initial begin
   rst = 1;
   repeat(5) @ (posedge clk) ;
   rst = 0;
 end
 
   // code to combine the inputs via methods and wire inputs from WISHBONE bus masters
  logic [data_width-1:0]  bfm_m_wdata[num_masters];
  logic [addr_width-1:0]  bfm_m_addr [num_masters];
  logic bfm_m_cyc [num_masters];
  logic bfm_m_lock[num_masters];
  logic bfm_m_stb [num_masters];
  logic bfm_m_we  [num_masters];
  logic [7:0] bfm_m_sel[num_masters];
  
  wire [data_width-1:0]  m_wdata_combined[num_masters];
  wire [addr_width-1:0]  m_addr_combined [num_masters];
  wire m_cyc_combined [num_masters];
  wire m_lock_combined[num_masters];
  wire m_stb_combined [num_masters];
  wire m_we_combined  [num_masters];
  wire [7:0] m_sel_combined [num_masters];

  assign m_wdata_combined = bfm_m_wdata;
  assign m_addr_combined  = bfm_m_addr;
  assign m_cyc_combined   = bfm_m_cyc;
  assign m_lock_combined  = bfm_m_lock;
  assign m_stb_combined   = bfm_m_stb;
  assign m_we_combined    = bfm_m_we;
  assign m_sel_combined   = bfm_m_sel;
  
  assign m_wdata_combined = m_wdata;
  assign m_addr_combined  = m_addr;
  assign m_cyc_combined   = m_cyc;
  assign m_lock_combined  = m_lock;
  assign m_stb_combined   = m_stb;
  assign m_we_combined    = m_we;
  assign m_sel_combined   = m_sel;


// WISHBONE bus arbitration logic
//--------------------------------
// A master requests the bus by raising his cyc signal
  enum {GRANT0,GRANT1,GRANT2,GRANT3,GRANT4,GRANT5,GRANT6,GRANT7} state, next_state;
// note that the states match the master's value. ie GRANT1 has a value of 1 and
// indicates that master 1 is granted the bus.
  bit gnt[num_masters];

  always @ (posedge clk)
    if(rst) begin 
      state <= #1 GRANT0;
      foreach(gnt[i]) gnt[i] <= #1 0;  // clear any grant
      gnt[0] <= #1 1;  // set inital grant
    end else
      state <= #1 next_state;
  
  always @ (state) begin
    foreach(gnt[i]) gnt[i] = 0;
    gnt[state] = 1;
  end
  
  always @ (state or m_cyc_combined[0] or m_cyc_combined[1] or m_cyc_combined[2]
            or m_cyc_combined[3] or m_cyc_combined[4] or m_cyc_combined[5]
            or m_cyc_combined[6] or m_cyc_combined[7] ) begin
    next_state = state; // Default - keep state
    case (state)
      GRANT0:
        if(!m_cyc_combined[0]) // if request is dropped arbitrate
            arbitrate(0);  // go to next state with a request
      GRANT1:
        if(!m_cyc_combined[1]) // if request is dropped arbitrate
            arbitrate(1);  // go to next state with a request
      GRANT2:
        if(!m_cyc_combined[2]) // if request is dropped arbitrate
            arbitrate(2);  // go to next state with a request
      GRANT3:
        if(!m_cyc_combined[3]) // if request is dropped arbitrate
            arbitrate(3);  // go to next state with a request
      GRANT4:
        if(!m_cyc_combined[4]) // if request is dropped arbitrate
            arbitrate(4);  // go to next state with a request
      GRANT5:
        if(!m_cyc_combined[5]) // if request is dropped arbitrate
            arbitrate(5);  // go to next state with a request
      GRANT6:
        if(!m_cyc_combined[6]) // if request is dropped arbitrate
            arbitrate(6);  // go to next state with a request
      GRANT7:
        if(!m_cyc_combined[7]) // if request is dropped arbitrate
            arbitrate(7);  // go to next state with a request
      default: begin
        `uvm_error("WB_SYSCON_ARB", "Illegal state in Wishbone Arbiter reached" )
        next_state = GRANT0;
        foreach(gnt[i]) gnt[i] <= #1 0;  // clear any grant
        gnt[0] <= #1 1;  // set inital grant
      end
    endcase
  end

  function void arbitrate(int last_grant);
    for (int i=0; i<num_masters; i++) begin
      //increment last_grant so start check with next master
      last_grant++;
      if(last_grant == num_masters) //check for need to wrap  
        last_grant = 0; //wrap if necessary
      if(m_cyc_combined[last_grant] == 1) begin  //request?
        $cast(next_state, last_grant);  // go to granted master's equivalent state
        return;
      end
    end
  endfunction

//Slave address decode
//--------------------------------
// slave memory map
// Note:  Wishbone is byte addressable. The stb signal is what indicates to a
// slave device it has been selected
// each slave mapped to 1 Mbytes (1,048,576 bytes) of address space
// Each slave uses addr[19:00] internally, addr[22:20] is used for slave select
// slave 0:  000000 - 0fffff
// slave 1:  100000 - 1fffff
// slave 2:  200000 - 2fffff
// slave 3:  300000 - 3fffff
// and so forth


  
  initial
    for (int i=0; i<num_masters; i++) begin
      bfm_m_wdata [i] = 'z;
      bfm_m_addr  [i] = 'z; 
      bfm_m_cyc   [i] = 'z; 
      bfm_m_lock  [i] = 'z;
      bfm_m_stb   [i] = 'z;
      bfm_m_we    [i] = 'z;
      bfm_m_sel   [i] = 'z;
    end

// bus muxing logic
//--------------------------------

  always @ (m_addr[state][22:20] or m_stb_combined[state] )
   s_stb[m_addr[state][22:20]] = m_stb_combined[state];

  // Master to slave connections
  always @ (state or m_wdata_combined[state])
   s_wdata = m_wdata_combined[state];

  always @ (state or m_addr_combined[state])
   s_addr = m_addr_combined[state];

  always @ (state or m_sel_combined[state])
   s_sel = m_sel_combined[state];

  always @ (state or m_cyc_combined[state])
   s_cyc = m_cyc_combined[state];

  always @ (state or m_stb_combined[state])
   s_stb[m_addr[state][22:20]] = m_stb_combined[state];

  always @ (state or m_we_combined[state])
   s_we = m_we_combined[state];

  always @ (state or m_cti[state])
   s_cti = m_cti[state];

  always @ (state or m_bte[state])
   s_bte = m_bte[state];

  //slave to master connections
  always @ (s_rdata[m_addr[state][22:20]])
   m_rdata = s_rdata[m_addr[state][22:20]];

  always @ (s_ack[m_addr[state][22:20]])
   m_ack[state] = s_ack[m_addr[state][22:20]];
   

  always @ (s_err[m_addr[state][22:20]])
   m_err = s_err[m_addr[state][22:20]];

  always @ (s_rty[m_addr[state][22:20]])
   m_rty = s_rty[m_addr[state][22:20]];

  // BFM tasks
    //WRITE  1 or more write cycles
  task wb_write_cycle(wb_txn req_txn, bit [2:0] m_id = 1);
    for(int i = 0; i<req_txn.count; i++) begin
      if(rst) begin
        reset(m_id);  // clear everything
        return; //exit if reset is asserted
      end
      bfm_m_wdata[m_id] = req_txn.data[i];
      bfm_m_addr[m_id] = req_txn.adr;
      bfm_m_we[m_id]  = 1;  //write
      bfm_m_sel[m_id] = req_txn.byte_sel;
      bfm_m_cyc[m_id] = 1;
      bfm_m_stb[m_id] = 1;
      @ (posedge clk)
      while (!(m_ack[1] & gnt[1])) @ (posedge clk);
      req_txn.adr =  req_txn.adr + 4;  // byte address so increment by 4 for word addr
    end
    `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                    $sformatf("req_txn: %s",req_txn.convert2string()),
                    351 )
    bfm_m_cyc[m_id] = 0;
    bfm_m_stb[m_id] = 0;     
  endtask
  
    //READ 1 or more cycles
  task wb_read_cycle(wb_txn req_txn, bit [2:0] m_id = 1, output wb_txn rsp_txn);
    logic [31:0] temp_addr;
    temp_addr = req_txn.adr;
    for(int i = 0; i<req_txn.count; i++) begin
      if(rst) begin
        reset(m_id);  // clear everything
        return; //exit if reset is asserted
      end
      bfm_m_addr[m_id] = temp_addr;
      bfm_m_we[m_id]  = 0;  // read
      bfm_m_sel[m_id] = req_txn.byte_sel;
      bfm_m_cyc[m_id] = 1;
      bfm_m_stb[m_id] = 1;
      @ (posedge clk)
      while (!(m_ack[m_id] & gnt[m_id])) @ (posedge clk);
      req_txn.data[i] = m_rdata;  // get data
      temp_addr =  temp_addr + 4;  // byte address so increment by 4 for word addr
    end
    rsp_txn = req_txn;  // send rsp object back
    bfm_m_cyc[m_id] = 0;
    bfm_m_stb[m_id] = 0;     
  endtask

  task wb_irq(wb_txn req_txn, output wb_txn rsp_txn);
    wait(irq);
    req_txn.data[0] = irq;
    rsp_txn = req_txn;  // send rsp object back
  endtask

  function void reset(bit [2:0] m_id = 1);
    bfm_m_cyc[1] = 0;
    bfm_m_stb[1] = 0;   
  endfunction
  
      
  task monitor(output wb_txn txn);    
    forever @ (posedge clk)
      if(s_cyc) begin // Is there a valid wb cycle?
        txn = wb_txn::type_id::create("txn"); // create a new wb_txn
        txn.adr = s_addr; // get address
        txn.count = 1;  // set count to one read or write
        if(s_we)  begin // is it a write?
          txn.data[0] = s_wdata;  // get data
          txn.txn_type = WRITE; // set op type
          while (!(s_ack[0] | s_ack[1]|s_ack[2]))
            @ (posedge clk); // wait for cycle to end
        end
        else begin
          txn.txn_type = READ; // set op type
          case (1) //Nope its a read, get data from correct slave
            s_stb[0]:  begin
                while (!(s_ack[0])) @ (posedge clk); // wait for ack
                txn.data[0] = s_rdata[0];  // get data
              end
            s_stb[1]:  begin
                while (!(s_ack[1])) @ (posedge clk); // wait for ack
                txn.data[0] = s_rdata[1];  // get data
              end
            s_stb[2]:  begin
                while (!(s_ack[2])) @ (posedge clk); // wait for ack
                txn.data[0] = s_rdata[2];  // get data
              end
          endcase
        end
        return; // exit the task with a transaction
      end
  endtask               


 
endmodule
