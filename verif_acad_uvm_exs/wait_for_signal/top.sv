//
//------------------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
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
//------------------------------------------------------------------------------
//
// This example illustrates how a sequence can wait for interface clocks using
// a method implemented in a configuration object.
//
// The configuration object class (bus_agent_config) contains a virtual interface
// handle and two methods which can be called from a sequence:
//
// wait_for_clock(int n) - Waits for n positive clock edges
//
// The sequence bus_seq shows how to call these two methods. It uses the wait_for_clock
// method to increase the interval between bus accesses as the simulation progresses.
//

package bidirect_bus_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

// Bus agent sequence item
class bus_seq_item extends uvm_sequence_item;

rand logic[31:0] addr;
rand logic[31:0] write_data;
rand bit read_not_write;
rand int delay;

bit error;
logic[31:0] read_data;

`uvm_object_utils(bus_seq_item)

function new(string name = "bus_seq_item");
  super.new(name);
endfunction

constraint at_least_1 { delay inside {[1:20]};}

constraint align_32 {addr[1:0] == 0;}

function void do_copy(uvm_object rhs);
  bus_seq_item rhs_;

  if(!$cast(rhs_, rhs)) begin
    uvm_report_error("do_copy", "cast failed, check types");
  end
  addr = rhs_.addr;
  write_data = rhs_.write_data;
  read_not_write = rhs_.read_not_write;
  delay = rhs_.delay;
  error = rhs_.error;
  read_data = rhs_.read_data;
endfunction: do_copy

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  bus_seq_item rhs_;

  do_compare = $cast(rhs_, rhs) &&
               super.do_compare(rhs, comparer) &&
               addr == rhs_.addr &&
               write_data == rhs_.write_data &&
               read_not_write == rhs_.read_not_write &&
               delay == rhs_.delay &&
               error == rhs_.error &&
               read_data == rhs_.read_data;
endfunction: do_compare

function string convert2string();
  return $sformatf("%s\n addr:\t%0h\n write_data:\t%0h\n read_not_write:\t%0b\n delay:\t%0d\n error:\t%0b\n read_data:\t%0h",
                   super.convert2string(),  addr, write_data, read_not_write, delay, error, read_data);
endfunction: convert2string

function void do_print(uvm_printer printer);

  if(printer.knobs.sprint == 0) begin
    $display(convert2string());
  end
  else begin
    printer.m_string = convert2string();
  end

endfunction: do_print

function void do_record(uvm_recorder recorder);
  super.do_record(recorder);

  `uvm_record_field("addr", addr);
  `uvm_record_field("write_data", write_data);
  `uvm_record_field("read_not_write", read_not_write);
  `uvm_record_field("delay", delay);
  `uvm_record_field("error", error);
  `uvm_record_field("read_data", read_data);

endfunction: do_record

endclass: bus_seq_item

// Configuration object containing:
//
// wait_for_clock()
//
class bus_agent_config extends uvm_object;

`uvm_object_utils(bus_agent_config)

virtual bus_if BUS;

localparam string s_my_config_id = "config";
localparam string s_no_config_id = "no config";
localparam string s_my_config_type_error_id = "config type error";


function new(string name = "bus_agent_config");
  super.new(name);
endfunction

//
// Task: wait_for_clock
//
// This method waits for n clock cycles. This technique can be used for clocks,
// resets and any other signal.
//
task wait_for_clock( int n = 1 );
  repeat( n ) begin
    @( posedge BUS.clk );
  end
endtask

endclass: bus_agent_config

// Bus agent driver:
class bidirect_bus_driver extends uvm_driver #(bus_seq_item);

`uvm_component_utils(bidirect_bus_driver)

bus_seq_item req;

virtual bus_if BUS;

function new(string name = "bidirect_bus_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

task run_phase(uvm_phase phase);

  // Default conditions:
  BUS.valid = 0;
  BUS.rnw = 1;
  // Wait for reset to end
  @(posedge BUS.resetn);
  forever
    begin
      seq_item_port.get_next_item(req);
      repeat(req.delay) begin
        @(posedge BUS.clk);
      end
      BUS.valid = 1;
      BUS.addr = req.addr;
      BUS.rnw = req.read_not_write;
      if(req.read_not_write == 0) begin
        BUS.write_data = req.write_data;
      end
      while(BUS.ready != 1) begin
        @(posedge BUS.clk);
      end
      if(req.read_not_write == 1) begin
        req.read_data = BUS.read_data;
      end
      req.error = BUS.error;
      BUS.valid = 0; // End the bus transaction
      seq_item_port.item_done();
    end
endtask: run_phase

endclass: bidirect_bus_driver

// Bus agent - basic utility sequence:
//
class bus_seq extends uvm_sequence #(bus_seq_item);

`uvm_object_utils(bus_seq)

bus_seq_item req;
bus_agent_config m_cfg;

rand int limit = 40; // Controls the number of iterations

function new(string name = "bus_seq");
  super.new(name);
endfunction

task body;
  int i = 5;
  req = bus_seq_item::type_id::create("req");
  // Get the configuration object
  if(!uvm_config_db #(bus_agent_config)::get(null, get_full_name(), "config", m_cfg)) begin
    `uvm_error("BODY", "bus_agent_config not found")
  end


  repeat(limit)
    begin
      start_item(req);
      // The address is constrained to be within the address of the GPIO function
      // within the DUT, The result will be a request item for a read or a write
      if(!req.randomize() with {addr inside {[32'h0100_0000:32'h0100_001C]};}) begin
        `uvm_error("body", "req randomization failure")
      end
      finish_item(req);
      // Wait for interface clocks:
      m_cfg.wait_for_clock(i);
      i++;
      // The req handle points to the object that the driver has updated with response data
      uvm_report_info("seq_body", req.convert2string());
    end
endtask: body

endclass: bus_seq

// Test class which instantiates the driver, sequencer and sets up
// the configuration object to contain a handle to the virtual
// interface
//
class bidirect_bus_test extends uvm_test;

`uvm_component_utils(bidirect_bus_test)

bus_seq test_seq;
bidirect_bus_driver m_driver;
uvm_sequencer #(bus_seq_item) m_sequencer;
bus_agent_config m_cfg;

function new(string name = "bidirect_bus_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  m_driver = bidirect_bus_driver::type_id::create("m_driver", this);
  m_sequencer = new("m_sequencer", this); // Not registered with the factory ...
  m_cfg = bus_agent_config::type_id::create("m_cfg");
  if (!uvm_config_db #(virtual bus_if)::get(this,"", "BUS_vif", m_cfg.BUS )) begin
    `uvm_error("build", "Failed to find BUS_vif")
  end
  uvm_config_db #(bus_agent_config)::set(this, "*", "config", m_cfg);
endfunction: build_phase

function void connect_phase(uvm_phase phase);
  m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  if(!uvm_config_db #(virtual bus_if)::get(null, "uvm_test_top", "BUS_vif", m_driver.BUS)) begin
    `uvm_error("connect_phase", "Failed to find BUS_vif")
  end
endfunction: connect_phase

task run_phase(uvm_phase phase);
  phase.raise_objection(this, "Started test_seq");
  test_seq = bus_seq::type_id::create("test_seq");

  test_seq.start(m_sequencer);
  phase.drop_objection(this, "Finished test_seq");
endtask: run_phase

endclass: bidirect_bus_test

endpackage: bidirect_bus_pkg

// Bus interface:
interface bus_if;

logic clk;
logic resetn;
logic[31:0] addr;
logic[31:0] write_data;
logic rnw;
logic valid;
logic ready;
logic[31:0] read_data;
logic error;

endinterface: bus_if

// DUT is a GPIO
interface gpio_if;

logic[255:0] gp_op;
logic[255:0] gp_ip;
logic clk;

endinterface: gpio_if

// The DUT - A GPIO with a bidrectional bus interface
module bidirect_bus_slave(interface bus, interface gpio);

logic[1:0] delay;

always @(posedge bus.clk)
  begin
    if(bus.resetn == 0) begin
      delay <= 0;
      bus.ready <= 0;
      gpio.gp_op <= 0;
    end
    if(bus.valid == 1) begin // Valid cycle
      if(bus.rnw == 0) begin // Write
        if(delay == 2) begin
          bus.ready <= 1;
          delay <= 0;
          if(bus.addr inside{[32'h0100_0000:32'h0100_001C]}) begin // GPO range - 8 words or 255 bits
            case(bus.addr[7:0])
              8'h00: gpio.gp_op[31:0] <= bus.write_data;
              8'h04: gpio.gp_op[63:32] <= bus.write_data;
              8'h08: gpio.gp_op[95:64] <= bus.write_data;
              8'h0c: gpio.gp_op[127:96] <= bus.write_data;
              8'h10: gpio.gp_op[159:128] <= bus.write_data;
              8'h14: gpio.gp_op[191:160] <= bus.write_data;
              8'h18: gpio.gp_op[223:192] <= bus.write_data;
              8'h1c: gpio.gp_op[255:224] <= bus.write_data;
            endcase
            bus.error <= 0;
          end
          else begin
            bus.error <= 1; // Outside valid write address range
          end
        end
        else begin
          delay <= delay + 1;
          bus.ready <= 0;
        end
      end
      else begin // Read cycle
        if(delay == 3) begin
          bus.ready <= 1;
          delay <= 0;
          if(bus.addr inside{[32'h0100_0000:32'h0100_001C]}) begin // GPO range - 8 words or 255 bits
            case(bus.addr[7:0])
              8'h00: bus.read_data <= gpio.gp_op[31:0];
              8'h04: bus.read_data <= gpio.gp_op[63:32];
              8'h08: bus.read_data <= gpio.gp_op[95:64];
              8'h0c: bus.read_data <= gpio.gp_op[127:96];
              8'h10: bus.read_data <= gpio.gp_op[159:128];
              8'h14: bus.read_data <= gpio.gp_op[191:160];
              8'h18: bus.read_data <= gpio.gp_op[223:192];
              8'h1c: bus.read_data <= gpio.gp_op[255:224];
            endcase
            bus.error <= 0;
          end
          else if(bus.addr inside{[32'h0100_0020:32'h0100_003C]}) begin // GPI range - 8 words or 255 bits - read only
            case(bus.addr[7:0])
              8'h20: bus.read_data <= gpio.gp_ip[31:0];
              8'h24: bus.read_data <= gpio.gp_ip[63:32];
              8'h28: bus.read_data <= gpio.gp_ip[95:64];
              8'h2c: bus.read_data <= gpio.gp_ip[127:96];
              8'h30: bus.read_data <= gpio.gp_ip[159:128];
              8'h34: bus.read_data <= gpio.gp_ip[191:160];
              8'h38: bus.read_data <= gpio.gp_ip[223:192];
              8'h3c: bus.read_data <= gpio.gp_ip[255:224];
            endcase
            bus.error <= 0;
          end
          else begin
            bus.error <= 1;
          end
        end
        else begin
          delay <= delay + 1;
          bus.ready <= 0;
        end
      end
    end
    else begin
      bus.ready <= 0;
      bus.error <= 0;
      delay <= 0;
    end
  end

endmodule: bidirect_bus_slave

// Top level test bench module
module top_tb;

import uvm_pkg::*;
import bidirect_bus_pkg::*;

// Declare the interfaces
bus_if BUS();
gpio_if GPIO();

// Instantiate and hook up the DUT:
bidirect_bus_slave DUT(.bus(BUS), .gpio(GPIO));

// Free running clock
initial
  begin
    BUS.clk = 0;
    forever begin
      #10 BUS.clk = ~BUS.clk;
    end
  end

// Reset
initial
  begin
    BUS.resetn = 0;
    repeat(3) begin
      @(posedge BUS.clk);
    end
    BUS.resetn = 1;
  end

// UVM start up:
initial
  begin
    uvm_config_db #(virtual bus_if)::set(null, "uvm_test_top", "BUS_vif" , BUS);
    run_test("bidirect_bus_test");
  end

endmodule: top_tb
