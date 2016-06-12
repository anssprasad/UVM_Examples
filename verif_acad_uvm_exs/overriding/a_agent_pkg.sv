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
// This pkgs contains the "a_agent" which is agent that converts
// sequence_items into messages
//
package a_agent_pkg;

import ovm_pkg::*;
`include "ovm_macros.svh"

class a_seq_item extends ovm_sequence_item;

`ovm_object_utils(a_seq_item)

function new(string name = "a_seq_item");
  super.new(name);
endfunction

rand int a; // No need for the various methods?
string s;

endclass: a_seq_item

class a_sequencer extends ovm_sequencer #(a_seq_item);

`ovm_component_utils(a_sequencer)

function new(string name = "a_sequencer", ovm_component parent = null);
  super.new(name, parent);
endfunction

endclass: a_sequencer

class a_driver extends ovm_driver #(a_seq_item);

`ovm_component_utils(a_driver)

function new(string name = "a_driver", ovm_component parent = null);
  super.new(name, parent);
endfunction

task run;

a_seq_item req;

forever begin
  seq_item_port.get_next_item(req);
  #10;
  req.a = req.a + 1;
  `ovm_info("RUN:", $psprintf("Heartbeat:%s", req.s), OVM_LOW);
  seq_item_port.item_done();
end

endtask: run

endclass: a_driver

class a_agent extends ovm_component;

`ovm_component_utils(a_agent)

a_sequencer m_sequencer;
a_driver m_driver;

function new(string name = "a_agent", ovm_component parent = null);
  super.new(name, parent);
endfunction

function void build();
  m_driver = a_driver::type_id::create("m_driver", this);
  m_sequencer = a_sequencer::type_id::create("m_sequencer", this);
endfunction: build

function void connect();
  m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
endfunction: connect

endclass: a_agent

class a_seq extends ovm_sequence #(a_seq_item);
`ovm_object_utils(a_seq)

rand int no_as=1;
string s = "A_SEQ";

function new(string name = "a_seq");
  super.new(name);
endfunction

task body;
  a_seq_item item;

  item = a_seq_item::type_id::create("item");
  item.s = s;
  repeat(no_as) begin
    start_item(item);
    assert(item.randomize());
    finish_item(item);
  end
endtask: body

endclass: a_seq

class b_seq extends a_seq;
`ovm_object_utils(b_seq)

function new(string name = "b_seq");
  super.new(name);
  s="B_SEQ";
endfunction

task body;
  super.body();
endtask: body

endclass: b_seq

class c_seq extends b_seq;
`ovm_object_utils(c_seq)

function new(string name = "c_seq");
  super.new(name);
  s="C_SEQ";
endfunction

task body;
  super.body();
endtask: body

endclass: c_seq

endpackage: a_agent_pkg