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

package gpio_sequence_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import gpio_agent_pkg::*;

class gpio_aux_seq extends uvm_sequence #(gpio_seq_item);

`uvm_object_utils(gpio_aux_seq)

function new(string name = "gpio_aux_seq");
  super.new(name);
endfunction

task body;
  gpio_seq_item aux_pkt = gpio_seq_item::type_id::create("aux_pkt");

  forever begin
    start_item(aux_pkt);
    assert(aux_pkt.randomize() with {use_ext_clk == 0;});
    finish_item(aux_pkt);
  end

endtask: body

endclass: gpio_aux_seq

// Generates totally random traffic for the GPI input
class gpio_rand_seq extends uvm_sequence #(gpio_seq_item);

`uvm_object_utils(gpio_rand_seq)

function new(string name = "gpio_rand_seq");
  super.new(name);
endfunction

task body;
  gpio_seq_item rand_pkt = gpio_seq_item::type_id::create("rand_pkt");

  forever begin
    start_item(rand_pkt);
    assert(rand_pkt.randomize());
    finish_item(rand_pkt);
  end

endtask: body

endclass: gpio_rand_seq

// Generates a GPIO input of a known value, synchronised to the internal
// clock
// Generates totally random traffic for the GPI input
class gpio_sync_seq extends uvm_sequence #(gpio_seq_item);

`uvm_object_utils(gpio_sync_seq)

rand logic[31:0] data;

function new(string name = "gpio_sync_seq");
  super.new(name);
endfunction

task body;
  gpio_seq_item item = gpio_seq_item::type_id::create("item");

  start_item(item);
  item.gpio = data;
  item.use_ext_clk = 0;
  finish_item(item);

endtask: body

endclass: gpio_sync_seq

endpackage: gpio_sequence_lib_pkg