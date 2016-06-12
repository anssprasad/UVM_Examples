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
`ifndef SPI_TEST
`define SPI_TEST

//
// Class Description:
//
//
class spi_test extends spi_test_base;

// UVM Factory Registration Macro
//
`uvm_component_utils(spi_test)

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "spi_test", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern task reset_phase(uvm_phase phase);
extern task main_phase(uvm_phase phase);

endclass: spi_test

function spi_test::new(string name = "spi_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

// Build the env, create the env configuration
// including any sub configurations and assigning virtural interfaces
function void spi_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction: build_phase

task spi_test::reset_phase(uvm_phase phase);
  check_regs_seq reset_test_seq = check_regs_seq::type_id::create("rest_test_seq");

  phase.raise_objection(this, "Starting reset_test_seq");
  reset_test_seq.start(m_env.m_v_sqr.apb);
  phase.drop_objection(this, "Finished reset_test_seq");
endtask: reset_phase

task spi_test::main_phase(uvm_phase phase);
  send_spi_char_seq spi_char_seq = send_spi_char_seq::type_id::create("spi_char_seq");

  phase.raise_objection(this, "Starting spi_char_seq");
  spi_char_seq.start(m_env.m_v_sqr.apb);
  m_env_cfg.pound_delay(100); 
  phase.drop_objection(this, "Finished spi_char_seq");
endtask: main_phase

`endif // SPI_TEST
