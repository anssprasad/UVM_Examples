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
//
// Package Description:
//
package gpio_env_pkg;

// Standard UVM import & include:
import uvm_pkg::*;
`include "uvm_macros.svh"

// Any further package imports:
import apb_agent_pkg::*;
import gpio_agent_pkg::*;
import uvm_register_pkg::*;
import gpio_register_pkg::*;

localparam string s_my_config_id = "gpio_env_config";
localparam string s_no_config_id = "no config";
localparam string s_my_config_type_error_id = "config type error";

// Register address defines
`define RGPIO_IN 5'h0
`define RGPIO_OUT 5'h4
`define RGPIO_OE 5'h8
`define RGPIO_INTE 5'hc
`define RGPIO_PTRIG 5'h10
`define RGPIO_AUX 5'h14
`define RGPIO_CTRL 5'h18
`define RGPIO_INTS 5'h1c
`define RGPIO_ECLK 5'h20
`define RGPIO_NEC 5'h24


// Includes
`include "gpio_env_config.svh"
`include "gpio_virtual_sequencer.svh"
`include "gpio_out_scoreboard.svh"
`include "gpio_in_scoreboard.svh"
`include "gpio_reg_scoreboard.svh"
`include "gpio_env.svh"

endpackage: gpio_env_pkg
