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

class modem_agent extends uvm_agent;
  `uvm_component_utils(modem_agent)

  modem_monitor    m_monitor;
  modem_driver     m_driver;
  modem_sequencer  m_sequencer;
  modem_coverage_monitor m_cov;
  modem_config     cfg;
  uvm_analysis_port #(modem_seq_item) ap;

  function new(string name = "modem_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction



  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  ap = new("modem_agent_ap", this);
  m_cov = modem_coverage_monitor::type_id::create("m_cov", this);
  m_monitor = modem_monitor::type_id::create("monitor", this);

  if (!uvm_config_db #(modem_config)::get(this, "", "modem_config", cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration modem_config from uvm_config_db. Have you set() it?")
  if (cfg.active) begin
       m_driver = modem_driver::type_id::create("drv", this);
       m_sequencer = modem_sequencer::type_id::create("sequencer", this);
    end
  endfunction: build


  function void connect_phase(uvm_phase phase);
    ap = m_monitor.ap;
    ap.connect(m_cov.analysis_export);
    if(cfg.active) begin
        m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
      end
  endfunction: connect

endclass: modem_agent
