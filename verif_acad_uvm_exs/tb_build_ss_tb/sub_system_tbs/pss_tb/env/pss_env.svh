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
class pss_env extends uvm_env;

// UVM Factory Registration Macro
//
`uvm_component_utils(pss_env)

//------------------------------------------
// Data Members
//------------------------------------------
pss_env_config m_cfg;
//------------------------------------------
// Sub Components
//------------------------------------------
spi_env m_spi_env;
gpio_env m_gpio_env;
ahb_agent m_ahb_agent;
pss_virtual_sequencer m_vsqr;
//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "pss_env", uvm_component parent = null);
// Only required if you have sub-components
extern function void build_phase(uvm_phase phase);
// Only required if you have sub-components which are connected
extern function void connect_phase(uvm_phase phase);

endclass: pss_env

function pss_env::new(string name = "pss_env", uvm_component parent = null);
  super.new(name, parent);
endfunction

// Only required if you have sub-components
function void pss_env::build_phase(uvm_phase phase);
  if (!uvm_config_db #(pss_env_config)::get(this, "", "pss_env_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration pss_env_config from uvm_config_db. Have you set() it?")
  if(m_cfg.has_spi_env) begin
    uvm_config_db #(spi_env_config)::set(this, "m_spi_env*", "spi_env_config", m_cfg.m_spi_env_cfg);
    m_spi_env = spi_env::type_id::create("m_spi_env", this);
  end
  if(m_cfg.has_gpio_env) begin
    uvm_config_db #(gpio_env_config)::set(this, "m_gpio_env*", "gpio_env_config", m_cfg.m_gpio_env_cfg);
    m_gpio_env = gpio_env::type_id::create("m_gpio_env", this);
  end
  if(m_cfg.has_ahb_agent) begin
    uvm_config_db #(ahb_agent_config)::set(this, "m_ahb_agent*", "ahb_agent_config", m_cfg.m_ahb_agent_cfg);
    m_ahb_agent = ahb_agent::type_id::create("m_ahb_agent", this);
  end
  if(m_cfg.has_virtual_sequencer) begin
    m_vsqr = pss_virtual_sequencer::type_id::create("m_vsqr", this);
  end
endfunction: build_phase

// Only required if you have sub-components which are connected
function void pss_env::connect_phase(uvm_phase phase);
  if(m_cfg.has_virtual_sequencer) begin
    if(m_cfg.has_spi_env) begin
      m_vsqr.spi = m_spi_env.m_spi_agent.m_sequencer;
    end
    if(m_cfg.has_gpio_env) begin
      m_vsqr.gpi = m_gpio_env.m_GPI_agent.m_sequencer;
    end
    if(m_cfg.has_ahb_agent) begin
      m_vsqr.ahb = m_ahb_agent.m_sequencer;
    end
  end
endfunction: connect_phase