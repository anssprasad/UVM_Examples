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

package apb_responder_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_agent_pkg::*;

//
// Class Description:
//
// APB Responder - acts as a slave - returns a response
// saves writes in one of 8 associative arrays
// gets reads from one of the 8 arrays
//
class apb_responder extends uvm_component;

// UVM Factory Registration Macro
//
`uvm_component_utils(apb_responder);

// Virtual Interface
virtual apb_if APB;

//------------------------------------------
// Data Members
//------------------------------------------
// Slave memories
bit[31:0] apb_0[bit[31:0]];
bit[31:0] apb_1[bit[31:0]];
bit[31:0] apb_2[bit[31:0]];
bit[31:0] apb_3[bit[31:0]];
bit[31:0] apb_4[bit[31:0]];
bit[31:0] apb_5[bit[31:0]];
bit[31:0] apb_6[bit[31:0]];
bit[31:0] apb_7[bit[31:0]];

//------------------------------------------
// Component Members
//------------------------------------------
uvm_analysis_port #(apb_seq_item) ap;

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:

extern function new(string name = "apb_responder", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern function void report_phase(uvm_phase phase);

endclass: apb_responder

function apb_responder::new(string name = "apb_responder", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_responder::build_phase(uvm_phase phase);
  ap = new("ap", this);
endfunction: build_phase

task apb_responder::run_phase(uvm_phase phase);
  apb_seq_item item;
  apb_seq_item cloned_item;

  item = apb_seq_item::type_id::create("item");

  forever begin
    // Detect the protocol event on the TBAI virtual interface
    @(posedge APB.PCLK iff((APB.PENABLE == 1) && (APB.PSEL != 0)));
    item.addr = APB.PADDR;
    item.we = APB.PWRITE;
    if(APB.PWRITE == 1) begin
      item.data = APB.PWDATA;
      case(APB.PSEL[7:0])
        8'b0000_0001: apb_0[APB.PADDR] = APB.PWDATA;
        8'b0000_0010: apb_1[APB.PADDR] = APB.PWDATA;
        8'b0000_0100: apb_2[APB.PADDR] = APB.PWDATA;
        8'b0000_1000: apb_3[APB.PADDR] = APB.PWDATA;
        8'b0001_0000: apb_4[APB.PADDR] = APB.PWDATA;
        8'b0010_0000: apb_5[APB.PADDR] = APB.PWDATA;
        8'b0100_0000: apb_6[APB.PADDR] = APB.PWDATA;
        8'b1000_0000: apb_7[APB.PADDR] = APB.PWDATA;
        default: begin
                   `uvm_error("PSEL_ERROR", $sformatf("PSEL is not valid %b", APB.PSEL))
                 end
      endcase
    end
    else begin
      case(APB.PSEL[7:0])
        8'b0000_0001: APB.PRDATA <= apb_0[APB.PADDR];
        8'b0000_0010: APB.PRDATA <= apb_1[APB.PADDR];
        8'b0000_0100: APB.PRDATA <= apb_2[APB.PADDR];
        8'b0000_1000: APB.PRDATA <= apb_3[APB.PADDR];
        8'b0001_0000: APB.PRDATA <= apb_4[APB.PADDR];
        8'b0010_0000: APB.PRDATA <= apb_5[APB.PADDR];
        8'b0100_0000: APB.PRDATA <= apb_6[APB.PADDR];
        8'b1000_0000: APB.PRDATA <= apb_7[APB.PADDR];
        default: begin
                   `uvm_error("PSEL_ERROR", $sformatf("PSEL is not valid %b", APB.PSEL))
                 end
      endcase
      item.data = APB.PRDATA;
    end
    @(negedge APB.PCLK);
    APB.PREADY <= 1;
    @(posedge APB.PCLK);
    #1 APB.PREADY <= 0;
    // Clone and publish the cloned item to the subscribers
    $cast(cloned_item, item.clone());
    ap.write(cloned_item);
  end
endtask: run_phase

function void apb_responder::report_phase(uvm_phase phase);
// Might be a good place to do some reporting on no of analysis transactions sent etc

endfunction: report_phase


endpackage: apb_responder_pkg
