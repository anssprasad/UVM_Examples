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

package gpio_virtual_sequence_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_agent_pkg::*;
import gpio_agent_pkg::*;
import gpio_env_pkg::*;
import gpio_bus_sequence_lib_pkg::*;
import gpio_sequence_lib_pkg::*;

`define INTS 32'h1c

// Interrupt service routine - at the APB level
class gpio_isr extends uvm_sequence #(apb_seq_item);

`uvm_object_utils(gpio_isr)

function new(string name = "isr");
  super.new(name);
endfunction

task body;

  apb_seq_item cmd = apb_seq_item::type_id::create("cmd");

  // This ISR is getting called because an int has occurred
  // Read from the ISR, then clear any set bits
  //
  m_sequencer.grab(this); // Exclusive access
  cmd.addr = `INTS;
  cmd.we = 0;
  cmd.delay = 0;
  start_item(cmd);
  finish_item(cmd);
  cmd.we = 1;
  cmd.data = 0;
  start_item(cmd);
  finish_item(cmd);

  m_sequencer.ungrab(this); // Release hold on sequencer
endtask: body

endclass: gpio_isr

// This base class contains a body method implementation that assigns the
// sequencer handles to the actual sequences:
class gpio_virtual_sequence_base extends uvm_sequence #(uvm_sequence_item);

`uvm_object_utils(gpio_virtual_sequence_base)

function new(string name = "gpio_virtual_sequence_base");
  super.new(name);
endfunction

// Virtual sequencer
gpio_virtual_sequencer m_v_sqr;

// env config object - needed to get to the wait_for_interrupt function
gpio_env_config m_cfg;

// Local handles for the sequencers
gpio_sequencer gpi;
gpio_sequencer aux;
apb_sequencer apb;


task body;
  // Setting up the sequencers
  if(!$cast(m_v_sqr, m_sequencer)) begin
    `uvm_fatal("GPIO_VIRTUAL_SEQUENCER", "Cast of m_sequencer to the virtual sequencer failed - this simulation will fail");
  end
  gpi = m_v_sqr.gpi;
  aux = m_v_sqr.aux;
  apb = m_v_sqr.apb;
  // Getting access to the interrupt line
  if (!uvm_config_db #(gpio_env_config)::get(m_sequencer, "", "gpio_env_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration gpio_env_config from uvm_config_db. Have you set() it?")
endtask: body

endclass: gpio_virtual_sequence_base

// Register test - checks reset and then R/W path
class reg_test_vseq extends gpio_virtual_sequence_base;

`uvm_object_utils(reg_test_vseq)

function new(string name = "reg_test_vseq");
  super.new(name);
endfunction

task body;
  check_reset_seq do_reset = check_reset_seq::type_id::create("do_reset");
  gpio_reg_rand reg_check = gpio_reg_rand::type_id::create("reg_check");
  gpio_sync_seq init_gpio = gpio_sync_seq::type_id::create("init_gpio");

  // Get the virtual sequencer handles assigned
  super.body();

  // Initialise the GPI and AUX inputs to 0
  init_gpio.data = 0;
  init_gpio.start(aux);
  init_gpio.start(gpi);
  // Check the reset conditions
  do_reset.start(apb);
  reg_check.iterations = 200;
  reg_check.start(apb);
endtask: body

endclass: reg_test_vseq

// GPIO Output path test
class GPO_test_vseq extends gpio_virtual_sequence_base;

`uvm_object_utils(GPO_test_vseq)

function new(string name = "GPO_test_vseq");
  super.new(name);
endfunction

task body;
  output_test_seq GP_OPs = output_test_seq::type_id::create("GP_OPs");
  gpio_aux_seq AUX_IPs = gpio_aux_seq::type_id::create("AUX_IPs");
  diag_outputs diag = diag_outputs::type_id::create("diag");
  aux_reg_seq AUX_reg = aux_reg_seq::type_id::create("AUX_reg");

  // Get the virtual sequencer handles assigned
  super.body();

  fork
    begin
      diag.start(apb);
      repeat(200) begin
        fork
          GP_OPs.start(apb);
          AUX_reg.start(apb);
        join
      end
    end
    AUX_IPs.start(aux);
  join_any

endtask: body

endclass: GPO_test_vseq

// GPIO Input path test - including interrupts
class GPI_test_vseq extends gpio_virtual_sequence_base;

`uvm_object_utils(GPI_test_vseq)

function new(string name = "GPI_test_vseq");
  super.new(name);
endfunction

task body;
  gpio_isr ISR = gpio_isr::type_id::create("ISR");
  gpio_input_test_seq gpi_input_regs = gpio_input_test_seq::type_id::create("gpi_input_regs");
  gpio_rand_seq gpi_inputs = gpio_rand_seq::type_id::create("gpio_rand_seq");

  super.body();

  fork
    gpi_inputs.start(gpi); // Forever
    begin // Setting up the GPI associated registers
      gpi_input_regs.iterations = 20000; // Repeat 100 times (Not enough)
      gpi_input_regs.start(apb);
    end
    begin // ISR
      forever begin
        m_cfg.wait_for_interrupt;
        ISR.start(apb);
      end
    end
  join_any

endtask: body


endclass: GPI_test_vseq

endpackage: gpio_virtual_sequence_lib_pkg
