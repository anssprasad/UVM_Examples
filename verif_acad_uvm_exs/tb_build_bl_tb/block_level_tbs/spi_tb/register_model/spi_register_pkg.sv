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

package spi_register_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import uvm_register_pkg::*;
import apb_agent_pkg::*;

typedef struct packed {logic[31:0] bits;} word_t;

typedef struct packed {bit[31:14] reserved; bit ASS; bit IE; bit LSB; bit TX_NEG; bit RX_NEG; bit GO_BSY; bit reserved_1; bit[6:0] CHAR_LEN;} ctrl_t;
typedef struct packed {bit[31:16] reserved; bit [15:0] DIVIDER;} divider_t;
typedef struct packed {bit[31:8] reserved; bit[7:0] SS;} ss_t;

// This is for the SPIO TX/RX register which overlap
class spi_rw extends uvm_register #(word_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "RW";
  data = 32'h0;
endfunction

endclass: spi_rw

// This is for the control register
class spi_ctrl extends uvm_register #(ctrl_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "RW";
  data = 32'h0;
endfunction

endclass: spi_ctrl

// This is for the divider register
class spi_div extends uvm_register #(divider_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0000_ffff;
  register_type = "RW";
  data = 32'h0000_ffff;
endfunction

endclass: spi_div

// This is for the slave select register
class spi_ss extends uvm_register #(ss_t);

function new(string l_name = "registerName",
             uvm_named_object p = null);
  super.new(l_name, p);
  resetValue = 32'h0;
  register_type = "RW";
  data = 32'h0;
endfunction

endclass: spi_ss

typedef uvm_register_base regs_array[];

class spi_register_file extends uvm_register_file;

rand spi_rw spi_data_0_reg;
rand spi_rw spi_data_1_reg;
rand spi_rw spi_data_2_reg;
rand spi_rw spi_data_3_reg;
rand spi_ctrl spi_ctrl_reg;
rand spi_div spi_div_reg;
rand spi_ss spi_ss_reg;

  function new(string name = "spi_register_file",
               uvm_named_object register_container = null );

    super.new(name, register_container);

    spi_data_0_reg = new("spi_data_0", this);
    spi_data_1_reg = new("spi_data_1", this);
    spi_data_2_reg = new("spi_data_2", this);
    spi_data_3_reg = new("spi_data_3", this);
    spi_ctrl_reg = new("spi_ctrl", this);
    spi_ctrl_reg.WMASK = 32'b0000_0000_0000_0000_0011_1111_1111_1111;
    spi_ctrl_reg.UNPREDICTABLEMASK = 32'b0000_0000_0000_0000_0000_0001_0000_0000;
    spi_div_reg = new("spi_div", this);
    spi_div_reg.WMASK = 32'b0000_0000_0000_0000_1111_1111_1111_1111;
    spi_ss_reg = new("spi_ss", this);
    spi_ss_reg.WMASK = 32'b0000_0000_0000_0000_0000_0000_1111_1111;
    this.add_register(spi_data_0_reg.get_fullname(), 32'h0000_0000, spi_data_0_reg, "spi_data_0");
    this.add_register(spi_data_1_reg.get_fullname(), 32'h0000_0004, spi_data_1_reg, "spi_data_1");
    this.add_register(spi_data_2_reg.get_fullname(), 32'h0000_0008, spi_data_2_reg, "spi_data_2");
    this.add_register(spi_data_3_reg.get_fullname(), 32'h0000_000c, spi_data_3_reg, "spi_data_3");
    this.add_register(spi_ctrl_reg.get_fullname(), 32'h0000_0010, spi_ctrl_reg, "spi_ctrl");
    this.add_register(spi_div_reg.get_fullname(), 32'h0000_0014, spi_div_reg, "spi_div");
    this.add_register(spi_ss_reg.get_fullname(), 32'h0000_0018, spi_ss_reg, "spi_ss");
   endfunction

   function bit check_valid_address(address_t address);
     bit result;

     result = addrSpace.exists(address);
     return result;
   endfunction: check_valid_address

   function regs_array get_regs();
     return '{spi_data_0_reg,
              spi_data_1_reg,
              spi_data_2_reg,
              spi_data_3_reg,
              spi_ctrl_reg,
              spi_div_reg,
              spi_ss_reg};
   endfunction: get_regs

endclass: spi_register_file

typedef uvm_register_file reg_file_array[];

class spi_register_map extends uvm_register_map;

  spi_register_file spi_reg_file;

  function new(string name, uvm_named_object parent);
    super.new(name, parent);
    spi_reg_file = new("spi_reg_file", this);
    this.add_register_file(spi_reg_file, 0);
  endfunction

  function reg_file_array get_register_files;
    return '{spi_reg_file};
  endfunction: get_register_files;

endclass: spi_register_map

`include "spi_register_coverage.svh"

endpackage: spi_register_pkg
