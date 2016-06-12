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

// test class for Ethernet Mac with wishbone IF
// Mike Baird
// note on wishbone masters:
// each Mac is a wishbone master (and slave), MAC_0 is wb master 0, MAC_1 wb master 1 etc.
// There is at least one wb_master_agent for use by the testbench to do r/w on the wb bus
// to access the MACs.
// The configuration for this test has 1 MAC and 1 wishbone master and does not scale

// The configuration for this test uses two mac sequencers per MAC and a mii_tx and mii_rx drivers
// providing full duplex communication with the MAC

// This does simple directed read/write testing of the MAC

class test_mac_simple_duplex extends uvm_test;
  `uvm_component_utils(test_mac_simple_duplex)

  mac_env env;
  mac_simple_duplex_seq m_seq;  //main sequence
  wb_config wb_config_0;  // config object for WISHBONE BUS
  mii_config mii_config_0; // config object for MAC_MII

  // handle(s) to sequencer(s) in the testbench
  uvm_sequencer #(wb_txn,wb_txn)   wb_seqr_handle;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //set configuration info
    // NOTE   The MAC is wishbone slave 0, mem_slave_0 is wishbone slave 1
    // MAC is wishbone master 0,  wb_master is wishbone master 1
    wb_config_0 = new();
    wb_config_0.m_wb_id = 0;  // wishbone 0
    wb_config_0.m_mac_id = 0;   // the ID of the MAC master
    wb_config_0.m_mac_eth_addr = 48'h000BC0D0EF00;
    wb_config_0.m_mac_wb_base_addr = 32'h00100000;
    wb_config_0.m_wb_master_id = 1; // the ID of the wb master
    wb_config_0.m_tb_eth_addr = 48'h000203040506;
    wb_config_0.m_s_mem_wb_base_addr = 32'h00000000;
    wb_config_0.m_mem_slave_size = 32'h00100000; // 1 Mbyte
    wb_config_0.m_mem_slave_wb_id = 0;  // the ID of slave mem
    wb_config_0.m_wb_verbosity = 350;
    wb_config_0.v_wb_bus_if = v_wb_bus_if; // From the wishbone_pkg
    uvm_config_db #(wb_config)::set(this, "*","wb_config",wb_config_0);

    mii_config_0 = new();
    mii_config_0.v_miim_if = v_miim_if; // From the mac_mii_pkg
    uvm_config_db #(mii_config)::set(this, "*", "mii_config", mii_config_0);

    env = mac_env::type_id::create("env", this);  // create environment class
    m_seq =  mac_simple_duplex_seq::type_id::create("m_seq");
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    int m_id;
    //find the wb sequencer in the testbench
    $cast(wb_seqr_handle,uvm_top.find($sformatf("*wb_m_%0d_seqr",wb_config_0.m_wb_master_id)));
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // start up the main sequence
    #100; //wait for reset to clear on wishbone bus
    m_seq.start(wb_seqr_handle, null);  //start the main sequence
    #100000;  //wait until they all are done
    phase.drop_objection(this); //done
  endtask

  function void report_phase(uvm_phase phase);
    if((env.mii_sb.tx_txn_cnt > 0) &&
       (env.mii_sb.rx_txn_cnt > 0) &&
       (env.mii_sb.tx_error_cnt == 0) &&
       (env.mii_sb.rx_error_cnt == 0) &&
       (env.wb_mem_sb.mem_read_error_cnt == 0)) begin
       `uvm_info("** UVM TEST PASSED **", "No errors found", UVM_NONE)
    end
    else begin
      `uvm_error("** UVM TEST FAILED **", "Errors occurred or no data was generated")
    end
  endfunction

endclass

