//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
package bus_agent_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

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

class bus_agent_config extends uvm_object;

`uvm_object_utils(bus_agent_config)

virtual bus_if BUS;

function new(string name = "bus_agent_config");
  super.new(name);
endfunction

//
// Task: wait_for_clock
//
// This method waits for n clock cycles. This technique can be used for clocks,
// resets and any other signals.
//
task wait_for_clock( int n = 1 );
  repeat( n ) begin
    @( posedge BUS.clk );
  end
endtask

endclass: bus_agent_config

class bus_driver extends uvm_driver #(bus_seq_item);

`uvm_component_utils(bus_driver)

bus_seq_item req;

virtual bus_if BUS;

function new(string name = "bus_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

task run_phase(uvm_phase phase);

  // Default conditions:
  BUS.valid <= 0;
  BUS.rnw <= 1;
  // Wait for reset to end
  @(posedge BUS.resetn);
  forever
    begin
      seq_item_port.get_next_item(req);
      repeat(req.delay) begin
        @(posedge BUS.clk);
      end
      BUS.valid <= 1;
      BUS.addr <= req.addr;
      BUS.rnw <= req.read_not_write;
      if(req.read_not_write == 0) begin
        BUS.write_data <= req.write_data;
      end
      while(BUS.ready != 1) begin
        @(posedge BUS.clk);
      end
      if(req.read_not_write == 1) begin
        req.read_data = BUS.read_data;
      end
      req.error = BUS.error;
      BUS.valid <= 0; // End the bus transaction
      seq_item_port.item_done();
    end
endtask: run_phase

endclass: bus_driver

class bus_sequencer extends uvm_sequencer #(bus_seq_item);

`uvm_component_utils(bus_sequencer)

function new(string name = "bus_sequencer", uvm_component parent = null);
  super.new(name, parent);
endfunction

endclass: bus_sequencer

class bus_agent extends uvm_component;

`uvm_component_utils(bus_agent)

bus_agent_config m_cfg;
bus_driver m_driver;
bus_sequencer m_sequencer;

function new(string name = "bus_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  if(!uvm_config_db #(bus_agent_config)::get(this, "", "config", m_cfg)) begin
    `uvm_error("build_phase", "Unable to find configuration object")
  end
  // No options here always active ...
  m_driver = bus_driver::type_id::create("m_driver", this);
  m_sequencer = bus_sequencer::type_id::create("m_sequencer", this);
endfunction: build_phase

function void connect_phase(uvm_phase phase);
  m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  m_driver.BUS = m_cfg.BUS;
endfunction: connect_phase

endclass: bus_agent


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
  if(!uvm_config_db #(bus_agent_config)::get(null, get_full_name(), "config", m_cfg)) begin
    `uvm_error("body", "unable to access agent configuration object")
  end

  repeat(limit)
    begin
      start_item(req);
      // The address is constrained to be within the address of the GPIO function
      // within the DUT, The result will be a request item for a read or a write
      if(!req.randomize() with {addr inside {[32'h0100_0000:32'h0100_001C]};}) begin
        `uvm_error("body", "Randomization of req failed")
      end
      finish_item(req);
      m_cfg.wait_for_clock(i);
      i++;
      // The req handle points to the object that the driver has updated with response data
      uvm_report_info("seq_body", req.convert2string());
    end
endtask: body

endclass: bus_seq

endpackage: bus_agent_pkg
