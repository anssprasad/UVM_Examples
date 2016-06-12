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
class pss_test_base extends uvm_test;

// UVM Factory Registration Macro
//
`uvm_component_utils(pss_test_base)

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Component Members
//------------------------------------------
// The environment class
pss_env m_env;
// Configuration objects
pss_env_config m_env_cfg;
spi_env_config m_spi_env_cfg;
gpio_env_config m_gpio_env_cfg;
//uart_env_config m_uart_env_cfg;
apb_agent_config m_spi_apb_agent_cfg;
apb_agent_config m_gpio_apb_agent_cfg;
ahb_agent_config m_ahb_agent_cfg;
spi_agent_config m_spi_agent_cfg;
gpio_agent_config m_GPO_agent_cfg;
gpio_agent_config m_GPI_agent_cfg;
gpio_agent_config m_GPOE_agent_cfg;
// Register map
pss_register_map pss_rm;


//------------------------------------------
// Methods
//------------------------------------------
//extern function void configure_apb_agent(apb_agent_config cfg);
// Standard UVM Methods:
extern function new(string name = "spi_test_base", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern virtual function void configure_apb_agent(apb_agent_config cfg, int index, logic[31:0] start_address, logic[31:0] range);

extern task run_phase(uvm_phase phase);

endclass: pss_test_base

function pss_test_base::new(string name = "spi_test_base", uvm_component parent = null);
  super.new(name, parent);
endfunction

// Build the env, create the env configuration
// including any sub configurations and assigning virtural interfaces
function void pss_test_base::build_phase(uvm_phase phase);
  m_env_cfg = pss_env_config::type_id::create("m_env_cfg");
  // Register map - Keep reg_map a generic name for vertical reuse reasons
  pss_rm = new("reg_map", null);
  m_env_cfg.pss_rm = pss_rm;
  // SPI Sub-env configuration:
  m_spi_env_cfg = spi_env_config::type_id::create("m_spi_env_cfg");
  m_spi_env_cfg.spi_rm = pss_rm;
  // apb agent in the SPI env:
  m_spi_env_cfg.has_apb_agent = 1;
  m_spi_apb_agent_cfg = apb_agent_config::type_id::create("m_spi_apb_agent_cfg");
  configure_apb_agent(m_spi_apb_agent_cfg, 0, 32'h0, 32'h18);
  if (!uvm_config_db #(virtual apb_if)::get(this, "", "APB_vif", m_spi_apb_agent_cfg.APB))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface APB_vif from uvm_config_db. Have you set() it?")
  m_spi_env_cfg.m_apb_agent_cfg = m_spi_apb_agent_cfg;
  // SPI agent:
  m_spi_agent_cfg = spi_agent_config::type_id::create("m_spi_agent_cfg");
  if (!uvm_config_db #(virtual spi_if)::get(this, "", "SPI_vif", m_spi_agent_cfg.SPI))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface APB_vif from uvm_config_db. Have you set() it?")
  m_spi_env_cfg.m_spi_agent_cfg = m_spi_agent_cfg;
  m_env_cfg.m_spi_env_cfg = m_spi_env_cfg;
  uvm_config_db #(spi_env_config)::set(this, "*", "spi_env_config", m_spi_env_cfg);
  // GPIO env configuration:
  m_gpio_env_cfg = gpio_env_config::type_id::create("m_gpio_env_cfg");
  m_gpio_env_cfg.gpio_rm = pss_rm;
  m_gpio_env_cfg.has_apb_agent = 1; // APB agent used
  m_gpio_apb_agent_cfg = apb_agent_config::type_id::create("m_gpio_apb_agent_cfg");
  configure_apb_agent(m_gpio_apb_agent_cfg, 1, 32'h100, 32'h124);
  if (!uvm_config_db #(virtual apb_if)::get(this, "", "APB_vif", m_gpio_apb_agent_cfg.APB))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface APB_vif from uvm_config_db. Have you set() it?")
  m_gpio_env_cfg.m_apb_agent_cfg = m_gpio_apb_agent_cfg;
  m_gpio_env_cfg.has_functional_coverage = 1; // Register coverage no longer valid
  // GPO agent
  m_GPO_agent_cfg = gpio_agent_config::type_id::create("m_GPO_agent_cfg");
  if (!uvm_config_db #(virtual gpio_if)::get(this, "", "GPO_vif", m_GPO_agent_cfg.GPIO))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface APB_vif from uvm_config_db. Have you set() it?")
  m_GPO_agent_cfg.active = UVM_PASSIVE; // Only monitors
  m_gpio_env_cfg.m_GPO_agent_cfg = m_GPO_agent_cfg;
  // GPOE agent
  m_GPOE_agent_cfg = gpio_agent_config::type_id::create("m_GPOE_agent_cfg");
  if (!uvm_config_db #(virtual gpio_if)::get(this, "", "GPOE_vif", m_GPOE_agent_cfg.GPIO))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface GPOE_vif from uvm_config_db. Have you set() it?")
  m_GPOE_agent_cfg.active = UVM_PASSIVE; // Only monitors
  m_gpio_env_cfg.m_GPOE_agent_cfg = m_GPOE_agent_cfg;
  // GPI agent - active (default)
  m_GPI_agent_cfg = gpio_agent_config::type_id::create("m_GPI_agent_cfg");
  if (!uvm_config_db #(virtual gpio_if)::get(this, "", "GPI_vif", m_GPI_agent_cfg.GPIO))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface GPI_vif from uvm_config_db. Have you set() it?")
  m_gpio_env_cfg.m_GPI_agent_cfg = m_GPI_agent_cfg;
  // GPIO Aux agent not present
  m_gpio_env_cfg.has_AUX_agent = 0;
  m_gpio_env_cfg.has_functional_coverage = 1;
  m_gpio_env_cfg.has_virtual_sequencer = 0;
  m_gpio_env_cfg.has_reg_scoreboard = 0;
  m_gpio_env_cfg.has_out_scoreboard = 1;
  m_gpio_env_cfg.has_in_scoreboard = 1;
  m_env_cfg.m_gpio_env_cfg = m_gpio_env_cfg;
  uvm_config_db #(gpio_env_config)::set(this, "*", "gpio_env_config", m_gpio_env_cfg);
  // AHB Agent
  m_ahb_agent_cfg = ahb_agent_config::type_id::create("m_ahb_agent_cfg");
  if (!uvm_config_db #(virtual ahb_if)::get(this, "", "AHB_vif", m_ahb_agent_cfg.AHB))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface AHB_vif from uvm_config_db. Have you set() it?")
  m_env_cfg.m_ahb_agent_cfg = m_ahb_agent_cfg;
  // Add in interrupt line
  if (!uvm_config_db #(virtual icpit_if)::get(this, "", "ICPIT_vif", m_env_cfg.ICPIT))
    `uvm_fatal("VIF CONFIG", "Cannot get() interface ICPIT_vif from uvm_config_db. Have you set() it?")
  uvm_config_db #(pss_env_config)::set(this, "*", "pss_env_config", m_env_cfg);
  m_env = pss_env::type_id::create("m_env", this);
  // Override for register adapters:
  register_adapter_base::type_id::set_inst_override(ahb_register_adapter::get_type(), "spi_bus.adapter");
  register_adapter_base::type_id::set_inst_override(ahb_register_adapter::get_type(), "gpio_bus.adapter");
endfunction: build_phase

//
// Convenience function to configure the apb agent
//
// This can be overloaded by extensions to this base class
function void pss_test_base::configure_apb_agent(apb_agent_config cfg, int index, logic[31:0] start_address, logic[31:0] range);
  cfg.active = UVM_PASSIVE;
  cfg.has_functional_coverage = 0;
  cfg.has_scoreboard = 0;
  cfg.no_select_lines = 1;
  cfg.apb_index = index;
  cfg.start_address[0] = start_address;
  cfg.range[0] = range;
endfunction: configure_apb_agent


task pss_test_base::run_phase(uvm_phase phase);

endtask: run_phase
