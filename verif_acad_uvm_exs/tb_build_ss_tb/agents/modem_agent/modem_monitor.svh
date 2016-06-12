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
 //
class modem_monitor extends uvm_component;

  `uvm_component_utils(modem_monitor)
   
  uvm_analysis_port #(modem_seq_item) ap;

  virtual modem_if MODEM;
  modem_config mcfg;

  function new(string name = "modem_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void connect_phase(uvm_phase phase);
     if (!uvm_config_db #(modem_config)::get(this, "", "modem_config", mcfg) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration modem_config from uvm_config_db. Have you set() it?")
   MODEM = mcfg.mif;
 endfunction: connect_phase


  function void build_phase(uvm_phase phase);
    ap = new("analysis_port", this);
  endfunction : build_phase


  task run_phase(uvm_phase phase);
  modem_seq_item t;

  t = new("Modem analysis transaction");
  forever
    begin
      @ (MODEM.rts_pad_o, MODEM.cts_pad_i, MODEM.dtr_pad_o, MODEM.dsr_pad_i, MODEM.ri_pad_i, MODEM.dcd_pad_i)
      t.modem_bits[5] = MODEM.rts_pad_o;
      t.modem_bits[4] = MODEM.cts_pad_i;
      t.modem_bits[3] = MODEM.dtr_pad_o;
      t.modem_bits[2] = MODEM.dsr_pad_i;
      t.modem_bits[1] = MODEM.ri_pad_i;
      t.modem_bits[0] = MODEM.dcd_pad_i;
      ap.write(t);
    end
  endtask : run_phase

 endclass: modem_monitor



