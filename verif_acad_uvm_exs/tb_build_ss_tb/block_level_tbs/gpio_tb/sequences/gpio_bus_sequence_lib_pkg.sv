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

package gpio_bus_sequence_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_agent_pkg::*;
import uvm_register_pkg::*;
//import gpio_register_pkg::*;
import gpio_env_pkg::*;
import register_layering_pkg::*;


// This base class provides read and write methods
class bus_base_sequence extends uvm_sequence #(uvm_sequence_item);

`uvm_object_utils(bus_base_sequence)

rand logic[31:0] address;
rand logic[31:0] seq_data;

string reg_name = "gpio_reg_file.GPO_reg";

gpio_env_config m_cfg;
uvm_register_map gpio_rm;
register_adapter_base adapter;

function new(string name = "bus_base_sequence");
  super.new(name);
endfunction

// This gets the env config object via the sequencer
task body();
  if (!uvm_config_db #(gpio_env_config)::get(m_sequencer, "", "gpio_env_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration gpio_env_config from uvm_config_db. Have you set() it?")
  gpio_rm = m_cfg.gpio_rm;
  adapter = register_adapter_base::type_id::create("adapter",,"gpio_bus");
  adapter.m_bus_sequencer = m_sequencer;
endtask: body

task read(string read_reg);
  bit addr_valid;
  register_seq_item register_read = register_seq_item::type_id::create("register_read");

  $cast(register_read.address, gpio_rm.lookup_register_address_by_name(read_reg, addr_valid));
  adapter.read(register_read);
  seq_data = register_read.data;
endtask: read

task write(string write_reg, logic[31:0] write_data);
  register_seq_item register_write = register_seq_item::type_id::create("register_write");
  bit addr_valid;

  $cast(register_write.address, gpio_rm.lookup_register_address_by_name(write_reg, addr_valid));
  register_write.data = write_data;
  adapter.write(register_write);
endtask: write

task random_write(string write_reg);
  register_seq_item register_write = register_seq_item::type_id::create("register_write");
  bit addr_valid;

  assert(register_write.randomize());
  $cast(register_write.address, gpio_rm.lookup_register_address_by_name(write_reg, addr_valid));
  adapter.write(register_write);
endtask: random_write

endclass: bus_base_sequence

class check_reset_seq extends bus_base_sequence;

`uvm_object_utils(check_reset_seq)

string regs[] = '{"gpio_reg_file.GPI", "gpio_reg_file.GPO", "gpio_reg_file.GPOE", "gpio_reg_file.AUX",
                  "gpio_reg_file.CTRL", "gpio_reg_file.INTE", "gpio_reg_file.PTRIG", "gpio_reg_file.INTS",
                  "gpio_reg_file.ECLK", "gpio_reg_file.NEC"};

function new(string name = "check_reset_seq");
  super.new(name);
endfunction

task body;
  super.body;

  foreach(regs[i]) begin
    read(regs[i]);
    if(seq_data != 0) begin
      `uvm_error("RESET_CHECK", $sformatf("Unexpected reset value @%s Read back %0h", i, seq_data))
    end
  end
endtask: body

endclass: check_reset_seq

class gpio_reg_rand extends bus_base_sequence;

`uvm_object_utils(gpio_reg_rand)

rand int iterations;

string regs[] = '{"gpio_reg_file.GPI", "gpio_reg_file.GPO", "gpio_reg_file.GPOE", "gpio_reg_file.AUX",
                  "gpio_reg_file.CTRL", "gpio_reg_file.INTE", "gpio_reg_file.PTRIG", "gpio_reg_file.INTS",
                  "gpio_reg_file.ECLK", "gpio_reg_file.NEC"};

function new(string name = "gpio_reg_rand");
  super.new(name);
endfunction

task body;
  super.body();

  repeat(iterations) begin
    regs.shuffle();
    randcase
      1:read(regs[0]);
      1:random_write(regs[0]);
    endcase
  end
endtask: body

endclass: gpio_reg_rand

// Hammers the GPO and GPOE registers
class output_test_seq extends bus_base_sequence;

`uvm_object_utils(output_test_seq)

function new(string name = "output_test_seq");
  super.new(name);
endfunction

string output_regs[] = '{"gpio_reg_file.GPO", "gpio_reg_file.GPOE"};

task body;
  super.body();
  output_regs.shuffle();
  random_write(output_regs[0]);
endtask: body

endclass: output_test_seq

// Hammers the GPO and GPOE registers
class aux_reg_seq extends bus_base_sequence;

`uvm_object_utils(aux_reg_seq)

function new(string name = "aux_reg_seq");
  super.new(name);
endfunction

task body;
  super.body();
  random_write("gpio_reg_file.AUX");
endtask: body

endclass: aux_reg_seq
/*
// Interrupt service routine - fairly directed
class gpio_isr extends bus_base_sequence;

`uvm_object_utils(gpio_isr)

function new(string name = "isr");
  super.new(name);
endfunction

task body;

//  logic[31:0] ints;
  super.body();
//  apb_seq_item cmd = apb_seq_item::type_id::create("cmd");

  // This ISR is getting called because an int has occurred
  // Read from the ISR, then clear any set bits
  //
  m_sequencer.grab(this); // Exclusive access
  read("gpio_reg_file.INTS");
//  cmd.addr = `INTS;
//  cmd.we = 0;
//  cmd.delay = 0;
//  start_item(cmd);
//  finish_item(cmd);
//  ints = seq_data;
  write("gpio_reg_file.INTS", 0);
//  cmd.we = 1;
//  cmd.data = 0;
//  start_item(cmd);
//  finish_item(cmd);

  m_sequencer.ungrab(this); // Release hold on sequencer
endtask: body

endclass: gpio_isr
*/
// Random toggling of all the registers associated with the
// input stream
class gpio_input_test_seq extends bus_base_sequence;

`uvm_object_utils(gpio_input_test_seq)

rand int iterations;

string regs[] = '{"gpio_reg_file.GPI", "gpio_reg_file.CTRL", "gpio_reg_file.INTE", "gpio_reg_file.PTRIG",
                  "gpio_reg_file.INTS", "gpio_reg_file.ECLK", "gpio_reg_file.NEC"};


function new(string name = "gpio_input_test_seq");
  super.new("");
endfunction

task body;
  super.body();

  repeat(20) begin
    random_write("gpio_reg_file.GPI");
  end
  write("gpio_reg_file.ECLK", 32'hFFFF_FFFF);
  repeat(20) begin
    random_write("gpio_reg_file.GPI");
  end
  write("gpio_reg_file.NEC", 32'hFFFF_FFFF);
  repeat(20) begin
    random_write("gpio_reg_file.GPI");
  end
  write("gpio_reg_file.INTE", 32'hFFFF_FFFF);
  repeat(20) begin
      read("gpio_reg_file.INTS");
  end
  write("gpio_reg_file.CTRL", 32'h1);
  repeat(20) begin
    random_write("gpio_reg_file.INTS");
  end
  write("gpio_reg_file.PTRIG", 32'hFFFF_FFFF);
  repeat(20) begin
    read("gpio_reg_file.INTS");
  end

  repeat(iterations) begin
    regs.shuffle();
    randcase
      10:random_write(regs[0]);
      1:read(regs[0]);
    endcase
  end
endtask: body

endclass: gpio_input_test_seq

class gpio_toggle_test_seq extends bus_base_sequence;

`uvm_object_utils(gpio_toggle_test_seq)

function new(string name = "gpio_toggle_test_seq");
  super.new(name);
endfunction

task body;
  super.body();
  write("gpio_reg_file.GPO", 32'haa55_aa55);
  write("gpio_reg_file.GPOE", 32'h55aa_55aa);
  write("gpio_reg_file.GPO", 32'h55aa_55aa);
  write("gpio_reg_file.GPOE", 32'haa55_aa55);
endtask: body

endclass: gpio_toggle_test_seq

class diag_outputs extends bus_base_sequence;

`uvm_object_utils(diag_outputs)

function new(string name = "diag_outputs");
  super.new(name);
endfunction

task body;

  super.body();
  write("gpio_reg_file.GPO", 32'haaaa_aaaa);
  write("gpio_reg_file.GPO", 32'h5555_5555);
  #100ns;
  write("gpio_reg_file.AUX", 32'hffff_ffff);
endtask: body

endclass: diag_outputs

endpackage: gpio_bus_sequence_lib_pkg
