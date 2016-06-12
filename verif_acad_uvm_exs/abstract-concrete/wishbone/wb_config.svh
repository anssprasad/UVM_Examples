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

`ifndef WB_CONFIG
`define WB_CONFIG

// configuration container class
class wb_config extends uvm_object;
  `uvm_object_utils( wb_config );

  virtual wishbone_bus_syscon_if v_wb_bus_if; // virtual wb_bus_if
  
  int m_wb_id;                       // Wishbone bus ID                                  
  int m_wb_master_id;                // Wishbone bus master id for wishone agent         
  int m_mac_id;                      // id of MAC WB master                              
  int unsigned m_mac_wb_base_addr;   // Wishbone base address of MAC                     
  bit [47:0]   m_mac_eth_addr;       // Ethernet address of MAC                          
  bit [47:0]   m_tb_eth_addr;        // Ethernet address of testbench for sends/receives 
  int m_mem_slave_size;              // Size of slave memory in bytes                    
  int unsigned m_s_mem_wb_base_addr; // base address of wb memory for MAC frame buffers  
  int m_mem_slave_wb_id;             // Wishbone ID of slave memory                      
  int m_wb_verbosity;                // verbosity level for wishbone messages            
  
  wb_bus_abs_c m_wb_bus_abs_c;      // abstract class handle


  function new( string name = "" );
    super.new( name );
  endfunction

  // Convenience function that first gets the object out of the UVM database
  // and reports an error if the object is not present in the database, then
  // casts it to the correct config object type, again checking for errors
  static function wb_config get_config( uvm_component c );
    wb_config t;
     
    if (!uvm_config_db#(wb_config)::get(c, "", "wb_config", t) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration wb_config from uvm_config_db. Have you set() it?")
     
    return t;
  endfunction
endclass

`endif
