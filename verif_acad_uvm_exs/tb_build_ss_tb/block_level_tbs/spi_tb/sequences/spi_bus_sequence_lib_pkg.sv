package spi_bus_sequence_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

//import apb_agent_pkg::*;
import spi_env_pkg::*;
import uvm_register_pkg::*;
import register_layering_pkg::*;

// This base class provides read and write methods
class bus_base_sequence extends uvm_sequence #(uvm_sequence_item);

`uvm_object_utils(bus_base_sequence)

rand logic[31:0] address;
rand logic[31:0] seq_data;

string reg_name = "spi_reg_file.spi_ctrl_reg";

spi_env_config m_cfg;
uvm_register_map spi_rm;
register_adapter_base adapter;

function new(string name = "bus_base_sequence");
  super.new(name);
endfunction

// This gets the env config object via the sequencer
task body;
  if (!uvm_config_db #(spi_env_config)::get(m_sequencer, "", "spi_env_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration spi_env_config from uvm_config_db. Have you set() it?")
  spi_rm = m_cfg.spi_rm;
  adapter = register_adapter_base::type_id::create("adapter",,"spi_bus");
  adapter.m_bus_sequencer = m_sequencer;
endtask: body

task read(string read_reg);
  bit addr_valid;
  register_seq_item register_read = register_seq_item::type_id::create("register_read");

  $cast(register_read.address, spi_rm.lookup_register_address_by_name(read_reg, addr_valid));
  adapter.read(register_read);
  seq_data = register_read.data;
endtask: read

task write(string write_reg, logic[31:0] write_data);
  register_seq_item register_write = register_seq_item::type_id::create("register_read");
  bit addr_valid;

  $cast(register_write.address, spi_rm.lookup_register_address_by_name(write_reg, addr_valid));
  register_write.data = write_data;
  adapter.write(register_write);
endtask: write

task random_write(string write_reg);
  register_seq_item register_write = register_seq_item::type_id::create("register_read");
  bit addr_valid;

  assert(register_write.randomize());
  $cast(register_write.address, spi_rm.lookup_register_address_by_name(write_reg, addr_valid));
  adapter.write(register_write);
endtask: random_write

endclass: bus_base_sequence

class spi_write_seq extends bus_base_sequence;

`uvm_object_utils(spi_write_seq);

function new(string name = "spi_write_seq");
  super.new(name);
endfunction

task body;
  super.body;
  write(reg_name, seq_data);
endtask: body

endclass: spi_write_seq

class spi_read_seq extends bus_base_sequence;

`uvm_object_utils(spi_read_seq);

function new(string name = "spi_read_seq");
  super.new(name);
endfunction

task body;
  super.body;
  read(reg_name );
endtask: body

endclass: spi_read_seq

//
// Data load sequence - any number of locations loaded with
// random data in a random order
//
class data_load_seq extends bus_base_sequence;

`uvm_object_utils(data_load_seq)

function new(string name = "data_load_seq");
  super.new(name);
endfunction

rand int n;

string data_regs[] = '{"spi_reg_file.spi_data_0", "spi_reg_file.spi_data_1", "spi_reg_file.spi_data_2", "spi_reg_file.spi_data_3"};

constraint no_loads {n inside {[1:5]};}

task body;
  super.body;
  data_regs.shuffle();
  foreach(data_regs[i]) begin
    random_write(data_regs[i]);
  end
endtask: body

endclass: data_load_seq

//
// Data load sequence - any number of locations unloaded with
// random data in a random order
//
class data_unload_seq extends bus_base_sequence;

`uvm_object_utils(data_unload_seq)

function new(string name = "data_unload_seq");
  super.new(name);
endfunction

rand int n;
//string data_regs[] = '{"reg_map.spi_reg_file.spi_data_0", "reg_map.spi_reg_file.spi_data_1", "reg_map.spi_reg_file.spi_data_2", "reg_map.spi_reg_file.spi_data_3"};
string data_regs[] = '{"spi_reg_file.spi_data_0", "spi_reg_file.spi_data_1", "spi_reg_file.spi_data_2", "spi_reg_file.spi_data_3"};

task body;
  super.body;
  data_regs.shuffle();
  foreach(data_regs[i]) begin
    read(data_regs[i]);
  end
endtask: body


endclass: data_unload_seq

//
// Div load sequence - loads one of the target
//                     divisor values
//
class div_load_seq extends bus_base_sequence;

`uvm_object_utils(div_load_seq)

function new(string name = "div_load_seq");
  super.new(name);
endfunction

constraint div_values {seq_data[15:0] inside {16'h0, 16'h1, 16'h2, 16'h4, 16'h8, 16'h10, 16'h20, 16'h40, 16'h80};}
/*              16'h100, 16'h200, 16'h400, 16'h800, 16'h1000, 16'h2000, 16'h4000, 16'h8000,
              16'hffff, 16'hfffe, 16'hfffd, 16'hfffb, 16'hfff7,
              16'hffef, 16'hffdf, 16'hffbf, 16'hff7f,
              16'hfeff, 16'hfdff, 16'hfbff, 16'hf7ff,
              16'hefff, 16'hdfff, 16'hbfff, 16'h7fff};}
*/
task body;
  super.body;
  assert(this.randomize());
  write("spi_reg_file.spi_div", seq_data);
endtask: body

endclass: div_load_seq

//
// Ctrl set sequence - loads one control params
//                     but does not set the go bit
//
class ctrl_set_seq extends bus_base_sequence;

`uvm_object_utils(ctrl_set_seq)

function new(string name = "ctrl_set_seq");
  super.new(name);
endfunction

bit int_enable = 0;

constraint length_values {seq_data[6:0] inside {0, 1, [31:33], [63:65], [95:97], 126, 127};}
constraint dont_go {seq_data[8] == 0;}

task body;
  super.body;
  assert(this.randomize());
  if(int_enable == 1) begin
    seq_data[12] = 1;
  end
  write("spi_reg_file.spi_ctrl", seq_data);
endtask: body

endclass: ctrl_set_seq

//
// Ctrl go sequence - sets the transfer in motion
//                    uses previously set control value
//
class ctrl_go_seq extends bus_base_sequence;

`uvm_object_utils(ctrl_go_seq)

function new(string name = "ctrl_go_seq");
  super.new(name);
endfunction

task body;
  super.body;
  seq_data[8] = 1;
  write("spi_reg_file.spi_ctrl", seq_data);
endtask: body

endclass: ctrl_go_seq

// Slave Select setup sequence
//
// Random values set for slave select
//
class slave_select_seq extends bus_base_sequence;

`uvm_object_utils(slave_select_seq)

function new(string name = "slave_select_seq");
  super.new(name);
endfunction

task body;
  super.body;
  assert(this.randomize() with {seq_data[7:0] != 8'h0;});
  write("spi_reg_file.spi_ss", seq_data);
endtask: body

endclass: slave_select_seq

// Slave Unselect setup sequence
//
// Random values set for slave select
//
class slave_unselect_seq extends bus_base_sequence;

`uvm_object_utils(slave_unselect_seq)

function new(string name = "slave_unselect_seq");
  super.new(name);
endfunction

task body;
  super.body;
  write("spi_reg_file.spi_ss", 32'h0);
endtask: body

endclass: slave_unselect_seq

// Transfer complete by polling sequence
//
//
class tfer_over_by_poll_seq extends bus_base_sequence;


`uvm_object_utils(tfer_over_by_poll_seq)

function new(string name = "tfer_over_by_poll_seq");
  super.new(name);
endfunction

task body;
  data_unload_seq empty_buffer;
  slave_unselect_seq ss_deselect;

  super.body;

  // Poll the GO_BSY bit in the control register
  seq_data = '1;
  while(seq_data[8] == 1) begin
    read("spi_reg_file.spi_ctrl");
  end
  ss_deselect = slave_unselect_seq::type_id::create("ss_deselect");
  ss_deselect.start(m_sequencer);
  empty_buffer = data_unload_seq::type_id::create("empty_buffer");
  empty_buffer.start(m_sequencer);
endtask: body

endclass: tfer_over_by_poll_seq

class check_regs_seq extends bus_base_sequence;

`uvm_object_utils(check_regs_seq)

function new(string name = "check_regs_seq");
  super.new(name);
endfunction

rand logic[31:0] data;

string reg_names[] = '{"spi_reg_file.spi_data_0", "spi_reg_file.spi_data_1", "spi_reg_file.spi_data_2", "spi_reg_file.spi_data_3",
                       "spi_reg_file.spi_div", "spi_reg_file.spi_ctrl", "spi_reg_file.spi_ss"};

task body;

  super.body;
  // Read back reset values in random order
  reg_names.shuffle();
  foreach(reg_names[i]) begin
    read(reg_names[i]);
  end
  // Write random data and check read back (10 times)
  repeat(10) begin
    reg_names.shuffle();
    foreach(reg_names[i]) begin
      if(reg_names[i] == "spi_reg_file.spi_ctrl") begin
        assert(this.randomize() with {data[8] == 0;});
        write(reg_names[i], data);
      end
      else begin
        random_write(reg_names[i]);
      end
    end
    reg_names.shuffle();
    foreach(reg_names[i]) begin
      read(reg_names[i]);
    end
  end

endtask: body

endclass: check_regs_seq

endpackage: spi_bus_sequence_lib_pkg
