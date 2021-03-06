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
// Class Description:
//
//
class pss_spi_polling_test extends pss_test_base;

// UVM Factory Registration Macro
//
`uvm_component_utils(pss_spi_polling_test)

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "pss_spi_polling_test", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);

endclass: pss_spi_polling_test

function pss_spi_polling_test::new(string name = "pss_spi_polling_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

// Build the env, create the env configuration
// including any sub configurations and assigning virtural interfaces
function void pss_spi_polling_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction: build_phase

task pss_spi_polling_test::run_phase(uvm_phase phase);
  spi_polling_vseq t_seq = spi_polling_vseq::type_id::create("t_seq");
  phase.raise_objection(this, "Starting PSS SPI polling test");

  repeat(10) begin
    t_seq.start(m_env.m_vsqr);
  end

  phase.drop_objection(this, "Finishing PSS SPI polling test");
endtask: run_phase
