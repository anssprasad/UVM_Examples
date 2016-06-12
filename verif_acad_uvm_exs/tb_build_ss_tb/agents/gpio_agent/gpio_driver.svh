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
class gpio_driver extends uvm_driver #(gpio_seq_item, gpio_seq_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(gpio_driver)

// Virtual Interface
virtual gpio_if GPIO;

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "gpio_driver", uvm_component parent = null);
extern task run_phase(uvm_phase phase);

endclass: gpio_driver

function gpio_driver::new(string name = "gpio_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

task gpio_driver::run_phase(uvm_phase phase);
  gpio_seq_item req;
  gpio_seq_item rsp;

  GPIO.ext_clk <= 0;
  forever begin
    seq_item_port.get_next_item(req);
    @(posedge GPIO.clk);
    #1ns;
    foreach(req.use_ext_clk[i]) begin
      if(req.use_ext_clk[i] == 0) begin
        GPIO.gpio[i] <= req.gpio[i];
      end
    end
    repeat(2)
      @(negedge GPIO.clk);
    foreach(req.use_ext_clk[i]) begin
      if(req.use_ext_clk[i] == 1) begin
        if(req.ext_clk_edge[i] == 1) begin
          GPIO.gpio[i] <= req.gpio[i];
        end
      end
    end
    repeat(2)
      @(negedge GPIO.clk);
    GPIO.ext_clk <= 1;
    repeat(5)
      @(negedge GPIO.clk);
    foreach(req.use_ext_clk[i]) begin
      if(req.use_ext_clk[i] == 1) begin
        if(req.ext_clk_edge[i] == 0) begin
          GPIO.gpio[i] <= req.gpio[i];
        end
      end
    end
    repeat(5)
      @(negedge GPIO.clk);
    GPIO.ext_clk <= 0;
    repeat(5)
      @(negedge GPIO.clk);
    seq_item_port.item_done();
  end

endtask: run_phase
