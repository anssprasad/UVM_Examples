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
//
// This example illustrates how to implement a bidirectional driver-sequence use
// model. It uses get_next_item(), item_done() in the driver.
//
// It includes a bidirectional slave DUT, and the bus transactions are reported to
// the transcript.
//
`define uvm_record_field(NAME,VALUE) \
   $add_attribute(recorder.tr_handle,VALUE,NAME);

package bidirect_bus_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"
import bidirect_bus_shared_pkg::*;

// Bus sequence item
class bus_seq_item extends uvm_sequence_item;

// Request fields
rand logic[31:0] addr;
rand logic[31:0] write_data;
rand bit read_not_write;
rand int delay;

// Response fields
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
    `uvm_error("do_copy", "cast failed, check types");
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
                    super.convert2string(), addr, write_data, read_not_write, delay, error, read_data);
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

class bus_seq_item_converter;

  static function void from_class(input bus_seq_item t, output bus_seq_item_vector_t v);
    bus_seq_item_s s;
    s.addr = t.addr;
    s.write_data = t.write_data;
    s.read_not_write = t.read_not_write;
    s.delay = t.delay;
    s.error = t.error;
    s.read_data = t.read_data;
    v = s;
  endfunction

  static function void to_class(output bus_seq_item t, input bus_seq_item_vector_t v);
    bus_seq_item_s s;
    s = v;
    t = new();
    t.addr = s.addr;
    t.write_data = s.write_data;
    t.read_not_write = s.read_not_write;
    t.delay = s.delay;
    t.error = s.error;
    t.read_data = s.read_data;
  endfunction

endclass: bus_seq_item_converter

// Bidirectional driver - uses:
//
// get_next_item() to get the next instruction item
// item_done() to indicate that the dirver has finished with the item
//
class bidirect_bus_driver extends uvm_driver #(bus_seq_item);

`uvm_component_utils(bidirect_bus_driver)

bus_seq_item req;

virtual bidirect_bus_driver_bfm BFM;

function new(string name = "bidirect_bus_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void end_of_elaboration_phase(uvm_phase phase);
  BFM.proxy = this;
endfunction: end_of_elaboration_phase

task run_phase(uvm_phase phase);
  BFM.run();
endtask: run_phase

task try_next_item(output bus_seq_item_s req_s, output bit success);
  seq_item_port.try_next_item(req); // Start processing req item
  success = (req != null);
  if (success)
    bus_seq_item_converter::from_class(req, req_s);
endtask: try_next_item

function void item_done(input bus_seq_item_s req_s);
  bus_seq_item req;
  bus_seq_item_converter::to_class(req, req_s);
  this.req.copy(req);
  seq_item_port.item_done(); // End of req item
endfunction: item_done

endclass: bidirect_bus_driver

// Bus sequencer:
class bidirect_bus_sequencer extends uvm_sequencer #(bus_seq_item);

`uvm_component_utils(bidirect_bus_sequencer)

function new(string name = "bidirect_bus_sequencer", uvm_component parent = null);
  super.new(name, parent);
endfunction

endclass: bidirect_bus_sequencer

// Bus sequence, which shows how the req object contains the result at the end
// of the control handshake with the driver via the sequencer
//
class bus_seq extends uvm_sequence #(bus_seq_item);

`uvm_object_utils(bus_seq)

bus_seq_item req;

rand int limit = 40; // Controls the number of iterations

function new(string name = "bus_seq");
  super.new(name);
endfunction

task body;
  req = bus_seq_item::type_id::create("req");

  repeat(limit)
    begin
      start_item(req);
      // The address is constrained to be within the address of the GPIO function
      // within the DUT, The result will be a request item for a read or a write
      assert(req.randomize() with {addr inside {[32'h0100_0000:32'h0100_001C]};});
      finish_item(req);
      // The req handle points to the object that the driver has updated with response data
      `uvm_info("seq_body", req.convert2string(), UVM_LOW);
    end
endtask: body

endclass: bus_seq

// Test class which instantiates, builds and connects the sequencer and the driver
//
class bidirect_bus_test extends uvm_test;

`uvm_component_utils(bidirect_bus_test)

bus_seq test_seq;
bidirect_bus_driver m_driver;
bidirect_bus_sequencer m_sequencer;

function new(string name = "bidirect_bus_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  m_driver = bidirect_bus_driver::type_id::create("m_driver", this);
  m_sequencer = bidirect_bus_sequencer::type_id::create("m_sequencer", this);
endfunction: build_phase

function void connect_phase(uvm_phase phase);
  m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  if (!uvm_config_db #(virtual bidirect_bus_driver_bfm)::get(this, "", "top_hdl.DRIVER", m_driver.BFM))
    `uvm_error("connect_phase", "uvm_config_db #(virtual bidirect_bus_driver_bfm)::get(...) failed");

endfunction: connect_phase

task run_phase(uvm_phase phase);
  test_seq = bus_seq::type_id::create("test_seq");

  phase.raise_objection(this, "Starting test_seq");
  test_seq.start(m_sequencer);
  phase.drop_objection(this, "Finished test_seq");
endtask: run_phase

endclass: bidirect_bus_test

endpackage: bidirect_bus_pkg

// Top level test bench module
module top_tb;

import uvm_pkg::*;
import bidirect_bus_pkg::*;

// UVM start up:
initial
  begin
    run_test("bidirect_bus_test");
  end

endmodule: top_tb
