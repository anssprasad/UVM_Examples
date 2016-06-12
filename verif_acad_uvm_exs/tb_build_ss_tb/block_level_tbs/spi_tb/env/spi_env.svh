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
class spi_env extends uvm_env;

// UVM Factory Registration Macro
//
`uvm_component_utils(spi_env)
//------------------------------------------
// Data Members
//------------------------------------------
apb_agent m_apb_agent;
spi_agent m_spi_agent;
spi_env_config m_cfg;
spi_register_coverage m_reg_cov_monitor;
spi_reg_functional_coverage m_func_cov_monitor;
spi_virtual_sequencer m_v_sqr;
spi_scoreboard m_scoreboard;
//------------------------------------------
// Constraints
//------------------------------------------

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "spi_env", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern function void connect_phase(uvm_phase phase);

endclass:spi_env

function spi_env::new(string name = "spi_env", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void spi_env::build_phase(uvm_phase phase);
  if (!uvm_config_db #(spi_env_config)::get(this, "", "spi_env_config", m_cfg))
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration spi_env_config from uvm_config_db. Have you set() it?")
  if(m_cfg.has_apb_agent) begin
    uvm_config_db #(apb_agent_config)::set(this, "m_apb_agent*",
                                           "apb_agent_config",
                                           m_cfg.m_apb_agent_cfg);
    m_apb_agent = apb_agent::type_id::create("m_apb_agent", this);
  end
  if(m_cfg.has_spi_agent) begin
    uvm_config_db #(spi_agent_config)::set(this, "m_spi_agent*",
                                           "spi_agent_config",
                                           m_cfg.m_spi_agent_cfg);
    m_spi_agent = spi_agent::type_id::create("m_spi_agent", this);
  end
  if(m_cfg.has_virtual_sequencer) begin
    m_v_sqr = spi_virtual_sequencer::type_id::create("m_v_sqr", this);
  end
  if(m_cfg.has_functional_coverage) begin
    m_reg_cov_monitor = spi_register_coverage::type_id::create("m_reg_cov_monitor", this);
  end
  if(m_cfg.has_spi_functional_coverage) begin
    m_func_cov_monitor = spi_reg_functional_coverage::type_id::create("m_func_cov_monitor", this);
  end
  if(m_cfg.has_spi_scoreboard) begin
    m_scoreboard = spi_scoreboard::type_id::create("m_scoreboard", this);
  end
endfunction:build_phase

function void spi_env::connect_phase(uvm_phase phase);
  if(m_cfg.has_virtual_sequencer) begin
    if(m_cfg.has_spi_agent) begin
      m_v_sqr.spi = m_spi_agent.m_sequencer;
    end
    if(m_cfg.has_apb_agent) begin
      m_v_sqr.apb = m_apb_agent.m_sequencer;
    end
  end
  if(m_cfg.has_functional_coverage) begin
    m_apb_agent.ap.connect(m_reg_cov_monitor.analysis_export);
  end
  if(m_cfg.has_spi_functional_coverage) begin
    m_apb_agent.ap.connect(m_func_cov_monitor.analysis_export);
  end
  if(m_cfg.has_spi_scoreboard) begin
    m_apb_agent.ap.connect(m_scoreboard.apb.analysis_export);
    m_spi_agent.ap.connect(m_scoreboard.spi.analysis_export);
    m_scoreboard.spi_rm = m_cfg.spi_rm;
  end

endfunction: connect_phase