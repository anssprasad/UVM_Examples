//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------


class dsp_con_agent extends uvm_component;

`uvm_component_utils(dsp_con_agent)

dsp_con_driver m_driver;
dsp_con_sequencer m_sequencer;
dsp_con_config m_cfg;

function new(string name = "dsp_con_agent", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  if(!uvm_config_db #(dsp_con_config)::get(this, "", "dsp_con_agent_config", m_cfg)) begin
    `uvm_error("build_phase", "dsp_con_agent_config not found")
  end
  m_driver = dsp_con_driver::type_id::create("m_driver", this);
  m_sequencer = dsp_con_sequencer::type_id::create("m_sequencer", this);
endfunction: build_phase

function void connect_phase(uvm_phase phase);
  m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  m_driver.CONTROL = m_cfg.CONTROL;
endfunction: connect_phase


endclass: dsp_con_agent
