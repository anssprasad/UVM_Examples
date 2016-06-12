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

`ifndef TEST_MAC_SIMPLE_DUPLEX
`define TEST_MAC_SIMPLE_DUPLEX

// test class for Ethernet Mac with WISHBONE IF
// Mike Baird
// note on WISHBONE masters:
// each Mac is a WISHBONE master (and slave), MAC_0 is wb master 0, MAC_1 wb master 1 etc.
// There is at least one wb_master_agent for use by the testbench to do r/w on the wb bus
// to access the MACs.
// The configuration for this test has 1 MAC and 1 WISHBONE master and does not scale

// The configuration for this test uses two mac sequencers per MAC and a mii_tx and mii_rx drivers 
// providing full duplex communication with the MAC

// This does simple directed read/write testing of the MAC

class test_mac_simple_duplex extends uvm_test;
  `uvm_component_utils(test_mac_simple_duplex)

  mac_env env_0;
  mac_env env_1;
  mac_simple_duplex_seq #(0) m_seq_0;  //main sequence
  mac_simple_duplex_seq #(1) m_seq_1;  //main sequence
  wb_config wb_config_0;  // config object for WISHBONE BUS 0
  wb_config wb_config_1;  // config object for WISHBONE BUS 1
  mii_config mii_config_0;  // config object for MII bus 0
  mii_config mii_config_1;  // config object for MII bus 1
  
  // handle(s) to sequencer(s) in the testbench
  uvm_sequencer #(wb_txn,wb_txn)   wb_seqr_handle_0;
  uvm_sequencer #(wb_txn,wb_txn)   wb_seqr_handle_1;
    
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void set_wishbone_config_params();
    //set configuration info for WISHBONE 0
    // NOTE   The MAC is WISHBONE slave 0, mem_slave_0 is WISHBONE slave 1
    // MAC is WISHBONE master 0,  wb_master is WISHBONE master 1
    wb_config_0 = new();

    wb_config_0.m_wb_id = 0;  // WISHBONE 0
    // Get the virtual interface handle that was set in the top module or protocol module
     if (!uvm_config_db #(wb_bus_abs_c)::get(this, "",
                       $sformatf("WB_BUS_CONCR_INST_%0h", wb_config_0.m_wb_id),
                                             wb_config_0.m_wb_bus_abs_c) )  // virtual interface
       `uvm_fatal("BAD_CONFIG", $sformatf("Cannot get() interface WB_BUS_CONCR_INST_ from uvm_config_db. Have you set() it?", wb_config_0.m_wb_id));

    wb_config_0.m_mac_id = mac_m_wb_id;   // the WISHBONE bus master id of the MAC master
    wb_config_0.m_mac_eth_addr = 48'h000BC0D0EF00;
    wb_config_0.m_mac_wb_base_addr = mac_slave_wb_id * slave_addr_space_sz; // base address of MAC slave
    wb_config_0.m_wb_master_id = 1; // the ID of the wb master
    wb_config_0.m_tb_eth_addr = 48'h000203040506;
    wb_config_0.m_s_mem_wb_base_addr = mem_slave_wb_id * slave_addr_space_sz; // base address of slave mem
    wb_config_0.m_mem_slave_size = 2**(mem_slave_size+2);  // default is 1 Mbyte
    wb_config_0.m_mem_slave_wb_id = mem_slave_wb_id;  // WISHBONE bus slave id of slave mem
    wb_config_0.m_wb_verbosity = 350;

    // put in config
    uvm_config_db #(wb_config)::set(this, "env_0*", "wb_config", wb_config_0);

    //set configuration info for WISHBONE 1
    // NOTE   The MAC is WISHBONE slave 0, mem_slave_0 is WISHBONE slave 1
    // MAC is WISHBONE master 0,  wb_master is WISHBONE master 1
    wb_config_1 = new();

    wb_config_1.m_wb_id = 1;  // WISHBONE 1
    if (!uvm_config_db #(wb_bus_abs_c)::get(this, "",
                       $sformatf("WB_BUS_CONCR_INST_%0h", wb_config_1.m_wb_id),
                                            wb_config_1.m_wb_bus_abs_c) )  // virtual interface
       `uvm_fatal("BAD_CONFIG", $sformatf("Cannot get() interface WB_BUS_CONCR_INST_ from uvm_config_db. Have you set() it?", wb_config_1.m_wb_id));

    wb_config_1.m_mac_id = mac_m_wb_id;   // the WISHBONE bus master id of the MAC master
    wb_config_1.m_mac_eth_addr = 48'h000BC0D0EF00;
    wb_config_1.m_mac_wb_base_addr = mac_slave_wb_id * slave_addr_space_sz; // base address of MAC slave
    wb_config_1.m_wb_master_id = 1; // the ID of the wb master
    wb_config_1.m_tb_eth_addr = 48'h000203040506;
    wb_config_1.m_s_mem_wb_base_addr = mem_slave_wb_id * slave_addr_space_sz; // base address of slave mem
    wb_config_1.m_mem_slave_size = 2**(mem_slave_size+2);  // default is 1 Mbyte
    wb_config_1.m_mem_slave_wb_id = mem_slave_wb_id;  // WISHBONE bus slave id of slave mem
    wb_config_1.m_wb_verbosity = 350;

    // put in config
    uvm_config_db #(wb_config)::set(this, "env_1*", "wb_config", wb_config_1);
  endfunction

  function void set_mii_config_params();
    mii_config_0 = new();

    if (!uvm_config_db #(virtual mii_if)::get(this, "",
                                              "MIIM_IF_0",
                                              mii_config_0.v_miim_if) )  // virtual interface
       `uvm_fatal("BAD_CONFIG", "Cannot get() interface MIIM_IF_0 from uvm_config_db. Have you set() it?");
    uvm_config_db #(mii_config)::set(this, "env_0*",  // put in config
                                     "mii_config", mii_config_0);

    mii_config_1 = new();

    if (!uvm_config_db #(virtual mii_if)::get(this, "",
                                              "MIIM_IF_1",
                                              mii_config_1.v_miim_if) )  // virtual interface
       `uvm_fatal("BAD_CONFIG", "Cannot get() interface MIIM_IF_1 from uvm_config_db. Have you set() it?");

    uvm_config_db #(mii_config)::set(this, "env_1*",  // put in config
                                     "mii_config", mii_config_1);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    set_wishbone_config_params();
    set_mii_config_params();
    
    env_0 = mac_env::type_id::create("env_0", this);  // create environment class
    env_1 = mac_env::type_id::create("env_1", this);  // create environment class
    m_seq_0 =  mac_simple_duplex_seq #(0)::type_id::create("m_seq_0"); 
    m_seq_1 =  mac_simple_duplex_seq #(1)::type_id::create("m_seq_1"); 
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    int m_id;
    //find the wb sequencer in the testbench
    $cast(wb_seqr_handle_0,uvm_top.find($sformatf("*env_0*wb_m_%0d_seqr",wb_config_0.m_wb_master_id)));
    $cast(wb_seqr_handle_1,uvm_top.find($sformatf("*env_1*wb_m_%0d_seqr",wb_config_1.m_wb_master_id)));
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // start up the main sequence
    #100; //wait for reset to clear on WISHBONE bus
    fork
     m_seq_0.start(wb_seqr_handle_0, null);  //start the main sequence 0
     m_seq_1.start(wb_seqr_handle_1, null);  //start the main sequence 1
    join
    #100000;  //wait until they all are done
    phase.drop_objection(this); //done  
  endtask

endclass
`endif
