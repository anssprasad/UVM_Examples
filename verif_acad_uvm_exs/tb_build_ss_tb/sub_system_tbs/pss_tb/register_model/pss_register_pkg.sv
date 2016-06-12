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

package pss_register_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import uvm_register_pkg::*;

import spi_register_pkg::*;
import gpio_register_pkg::*;

typedef uvm_register_file reg_file_array[];

class pss_register_map extends uvm_register_map;

  spi_register_file spi_reg_file;
  gpio_register_file gpio_reg_file;

  function new(string name, uvm_named_object parent);
    super.new(name, parent);
    spi_reg_file = new("spi_reg_file", this);
    this.add_register_file(spi_reg_file, 0);
    gpio_reg_file = new("gpio_reg_file", this);
    this.add_register_file(gpio_reg_file, 32'h100);
  endfunction

  function reg_file_array get_register_files;
    return '{spi_reg_file, gpio_reg_file};
  endfunction: get_register_files;

endclass: pss_register_map

endpackage: pss_register_pkg