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

package pss_vseq_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import ahb_agent_pkg::*;
import spi_agent_pkg::*;
import gpio_agent_pkg::*;
import gpio_bus_sequence_lib_pkg::*;
import gpio_sequence_lib_pkg::*;
import spi_bus_sequence_lib_pkg::*;
import spi_sequence_lib_pkg::*;
import pss_env_pkg::*;

`include "bridge_basic_rw_vseq.svh"
`include "pss_vseq_base.svh"
`include "gpio_outputs_vseq.svh"
`include "spi_interrupt_vseq.svh"
`include "spi_polling_vseq.svh"


endpackage: pss_vseq_lib_pkg