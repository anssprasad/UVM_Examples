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
class spi_test_base extends uvm_test;

// UVM Factory Registration Macro
//
`uvm_component_utils(spi_test_base)

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Component Members
//------------------------------------------
// The environment class
spi_env m_env;
// Configuration objects
spi_env_config m_env_cfg;
apb_agent_config m_apb_cfg;
spi_agent_config m_spi_cfg;
// Register map
spi_register_map spi_rm;

//------------------------------------------
// Methods
//------------------------------------------
extern virtual function void configure_apb_agent(apb_agent_config cfg);
// Standard UVM Methods:
extern function new(string name = "spi_test_base", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);

endclass: spi_test_base

function spi_test_base::new(string name = "spi_test_base", uvm_component parent = null);
  super.new(name, parent);
endfunction

// Build the env, create the env configuration
// including any sub configurations and assigning virtural interfaces
function void spi_test_base::build_phase(uvm_phase phase);
  // env configuration
  m_env_cfg = spi_env_config::type_id::create("m_env_cfg");
  // Register map - Keep reg_map a generic name for vertical reuse reasons
  spi_rm = new("reg_map", null);
  m_env_cfg.spi_rm = spi_rm;
  // APB configuration
  m_apb_cfg = apb_agent_config::type_id::create("m_apb_cfg");
  configure_apb_agent(m_apb_cfg);
  if (!uvm_config_db #(virtual apb_if)::get(this, "", "APB_vif", m_apb_cfg.APB))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface APB_vif from uvm_config_db. Have you set() it?")
  m_env_cfg.m_apb_agent_cfg = m_apb_cfg;
  // The SPI is not configured as such
  m_spi_cfg = spi_agent_config::type_id::create("m_spi_cfg");
  if (!uvm_config_db #(virtual spi_if)::get(this, "", "SPI_vif", m_spi_cfg.SPI) )
    `uvm_fatal("VIF CONFIG", "Cannot get() interface SPI_vif from uvm_config_db. Have you set() it?")
  m_spi_cfg.has_functional_coverage = 0;
  m_env_cfg.m_spi_agent_cfg = m_spi_cfg;
  // Insert the interrupt virtual interface into the env_config:
  if (!uvm_config_db #(virtual intr_if)::get(this, "", "INTR_vif", m_env_cfg.INTR) )
    `uvm_fatal("VIF CONFIG", "Cannot get() interface INTR_vif from uvm_config_db. Have you set() it?")
  uvm_config_db #(spi_env_config)::set(this, "*", "spi_env_config", m_env_cfg);
  m_env = spi_env::type_id::create("m_env", this);
  // Override for register adapter:
  register_adapter_base::type_id::set_inst_override(apb_register_adapter::get_type(), "spi_bus.adapter");
endfunction: build_phase


//
// Convenience function to configure the apb agent
//
// This can be overloaded by extensions to this base class
function void spi_test_base::configure_apb_agent(apb_agent_config cfg);
  cfg.active = UVM_ACTIVE;
  cfg.has_functional_coverage = 0;
  cfg.has_scoreboard = 0;
  // SPI is on select line 0 for address range 0-18h
  cfg.no_select_lines = 1;
  cfg.start_address[0] = 32'h0;
  cfg.range[0] = 32'h18;
endfunction: configure_apb_agent
