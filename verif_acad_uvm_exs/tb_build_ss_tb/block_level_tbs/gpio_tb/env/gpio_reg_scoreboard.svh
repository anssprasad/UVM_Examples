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
//
// Class Description:
//
//
class gpio_reg_scoreboard extends uvm_subscriber #(apb_seq_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(gpio_reg_scoreboard)

//------------------------------------------
// Data Members
//------------------------------------------
logic[31:0] RGPIO_IN;
logic[31:0] RGPIO_OUT;
logic[31:0] RGPIO_OE;
logic[31:0] RGPIO_INTE;
logic[31:0] RGPIO_PTRIG;
logic[31:0] RGPIO_AUX;
logic[31:0] RGPIO_CTRL;
logic[31:0] RGPIO_INTS;
logic[31:0] RGPIO_ECLK;
logic[31:0] RGPIO_NEC;
int read_error_count;

//------------------------------------------
// Sub Components
//------------------------------------------

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "gpio_reg_scoreboard", uvm_component parent = null);
// Only required if you have sub-components
extern function void build_phase(uvm_phase phase);
// Only required if you need to report:
extern function void report_phase(uvm_phase phase);
// Write method for the analysis port
extern function void write(T t);
// Report a read error
extern function void read_error(T t, logic[31:0] register);

endclass: gpio_reg_scoreboard

function gpio_reg_scoreboard::new(string name = "gpio_reg_scoreboard", uvm_component parent = null);
  super.new(name, parent);
  // Initialise the shadow registers:
  RGPIO_IN = 0;
  RGPIO_OUT = 0;
  RGPIO_OE = 0;
  RGPIO_INTE = 0;
  RGPIO_PTRIG = 0;
  RGPIO_AUX = 0;
  RGPIO_CTRL = 0;
  RGPIO_INTS = 0;
  RGPIO_ECLK = 0;
  RGPIO_NEC = 0;
  read_error_count = 0;
endfunction

// Only required if you have sub-components
function void gpio_reg_scoreboard::build_phase(uvm_phase phase);


endfunction: build_phase

// Only required if you need to report:
function void gpio_reg_scoreboard::report_phase(uvm_phase phase);
  if(read_error_count == 0) begin
    `uvm_info("GPIO_REG_SB", "Test Passed: No register read errors", UVM_LOW)
  end
  else begin
    `uvm_error("GPIO_REG_SB", $sformatf("%0d register read errors detected", read_error_count))
  end
endfunction: report_phase

// Write method - where it all happens
function void gpio_reg_scoreboard::write(T t);
  if(t.we == 0) begin
    case(t.addr)
      `RGPIO_OUT: if(RGPIO_OUT != t.data) begin
                    read_error(t, RGPIO_OUT);
                  end
      `RGPIO_OE : if(RGPIO_OE != t.data) begin
                    read_error(t, RGPIO_OE);
                  end
      `RGPIO_INTE: if(RGPIO_INTE != t.data) begin
                     read_error(t, RGPIO_INTE);
                   end
      `RGPIO_PTRIG: if(RGPIO_PTRIG != t.data) begin
                      read_error(t, RGPIO_PTRIG);
                    end
      `RGPIO_AUX: if(RGPIO_AUX != t.data) begin
                    read_error(t, RGPIO_AUX);
                  end
      `RGPIO_CTRL: if(RGPIO_CTRL[0] != t.data[0]) begin
                     read_error(t, RGPIO_CTRL);
                   end
      `RGPIO_INTS: if(RGPIO_INTS != t.data) begin
                     read_error(t, RGPIO_INTS);
                   end
      `RGPIO_ECLK: if(RGPIO_ECLK != t.data) begin
                     read_error(t, RGPIO_ECLK);
                   end
      `RGPIO_NEC: if(RGPIO_NEC != t.data) begin
                    read_error(t, RGPIO_NEC);
                  end
    endcase
  end
  else begin
    case(t.addr)
      `RGPIO_OUT: RGPIO_OUT = t.data;
      `RGPIO_OE : RGPIO_OE = t.data;
      `RGPIO_INTE: RGPIO_INTE = t.data;
      `RGPIO_PTRIG: RGPIO_PTRIG = t.data;
      `RGPIO_AUX: RGPIO_AUX = t.data;
      `RGPIO_INTS: RGPIO_INTS = t.data;
      `RGPIO_CTRL: RGPIO_CTRL = {30'h0, t.data[1:0]};
      `RGPIO_ECLK: RGPIO_ECLK = t.data;
      `RGPIO_NEC: RGPIO_NEC = t.data;
    endcase
  end
endfunction: write

function void gpio_reg_scoreboard::read_error(T t, logic[31:0] register);
  `uvm_error("READ_ERROR", $sformatf("@%0h Expected %0h, Actual %0h", t.addr, register, t.data))
  read_error_count++;
endfunction: read_error
