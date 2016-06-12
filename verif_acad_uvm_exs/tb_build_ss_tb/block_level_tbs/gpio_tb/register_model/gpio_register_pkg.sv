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

package gpio_register_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import uvm_register_pkg::*;
import apb_agent_pkg::*;

typedef struct packed {logic[31:0] bits;} word_t;

typedef struct packed {bit[29:0] reserved; bit INTS; bit INTE;} RGPIO_CTRL_t;

// This is for the GPIO input register which is read only
class rgpio_ro extends uvm_register #(word_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "R0";
  data = 32'h0;
endfunction

endclass: rgpio_ro

// This is for most of the registers in the GPIO which are 32 bit r/w
class rgpio_rw extends uvm_register #(word_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "RW";
  data = 32'h0;
endfunction

endclass: rgpio_rw

// This is for the control register
class rgpio_ctrl extends uvm_register #(RGPIO_CTRL_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "RW";
  data = 32'h0;
endfunction

endclass: rgpio_ctrl

typedef uvm_register_base regs_array[];

class gpio_register_file extends uvm_register_file;

rand rgpio_ro gpio_in_reg;
rand rgpio_rw gpio_out_reg;
rand rgpio_rw gpio_oe_reg;
rand rgpio_rw gpio_inte_reg;
rand rgpio_rw gpio_ptrig_reg;
rand rgpio_rw gpio_aux_reg;
rand rgpio_ctrl gpio_ctrl_reg;
rand rgpio_rw gpio_ints_reg;
rand rgpio_rw gpio_eclk_reg;
rand rgpio_rw gpio_nec_reg;

  function new(string name = "gpio_register_file",
               uvm_named_object register_container = null );

    super.new(name, register_container);

    gpio_in_reg = new("gpio_in", this);
    gpio_in_reg.WMASK = 32'b00000000000000000000000000000000;
    gpio_out_reg = new("gpio_out", this);
    gpio_oe_reg = new("gpio_oe", this);
    gpio_inte_reg = new("gpio_inte", this);
    gpio_ptrig_reg = new("gpio_ptrig", this);
    gpio_aux_reg = new("gpio_aux", this);
    gpio_ctrl_reg = new("gpio_ctrl", this);
    gpio_ints_reg = new("gpio_ints", this);
    gpio_eclk_reg = new("gpio_eclk", this);
    gpio_nec_reg = new("gpio_nec", this);

    this.add_register(gpio_in_reg.get_fullname(), 32'h0000_0000, gpio_in_reg, "GPI");
    this.add_register(gpio_out_reg.get_fullname(), 32'h0000_0004, gpio_out_reg, "GPO");
    this.add_register(gpio_oe_reg.get_fullname(), 32'h0000_0008, gpio_oe_reg, "GPOE");
    this.add_register(gpio_inte_reg.get_fullname(), 32'h0000_000c, gpio_inte_reg, "INTE");
    this.add_register(gpio_ptrig_reg.get_fullname(), 32'h0000_0010, gpio_ptrig_reg, "PTRIG");
    this.add_register(gpio_aux_reg.get_fullname(), 32'h0000_0014, gpio_aux_reg, "AUX");
    this.add_register(gpio_ctrl_reg.get_fullname(), 32'h0000_0018, gpio_ctrl_reg, "CTRL");
    this.add_register(gpio_ints_reg.get_fullname(), 32'h0000_001c, gpio_ints_reg, "INTS");
    this.add_register(gpio_eclk_reg.get_fullname(), 32'h0000_0020, gpio_eclk_reg, "ECLK");
    this.add_register(gpio_nec_reg.get_fullname(), 32'h0000_0024, gpio_nec_reg, "NEC");
   endfunction

   function bit check_valid_address(address_t address);
     bit result;

     result = addrSpace.exists(address);
     return result;
   endfunction: check_valid_address

   function regs_array get_regs();
     return '{gpio_in_reg,
              gpio_out_reg,
              gpio_oe_reg,
              gpio_inte_reg,
              gpio_ptrig_reg,
              gpio_aux_reg,
              gpio_ctrl_reg,
              gpio_ints_reg,
              gpio_eclk_reg,
              gpio_nec_reg};
   endfunction: get_regs

endclass: gpio_register_file

typedef uvm_register_file reg_file_array[];

class gpio_register_map extends uvm_register_map;

  gpio_register_file gpio_reg_file;

  function new(string name, uvm_named_object parent);
    super.new(name, parent);
    gpio_reg_file = new("gpio_reg_file", this);
    this.add_register_file(gpio_reg_file, 0);
  endfunction

  function reg_file_array get_register_files;
    return '{gpio_reg_file};
  endfunction: get_register_files;

endclass: gpio_register_map

`include "gpio_register_coverage.svh"

endpackage: gpio_register_pkg