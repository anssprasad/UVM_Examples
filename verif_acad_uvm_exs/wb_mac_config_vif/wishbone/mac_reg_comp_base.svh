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

`ifndef MAC_REG_COMP_BASE
`define MAC_REG_COMP_BASE

// Base class with access methods for the WISHBONE register map
//
// Mike Baird

//----------------------------------------------
virtual class mac_reg_comp_base extends uvm_component;
  `uvm_component_utils(mac_reg_comp_base)

 uvm_register_map m_register_map;

    // constructor
  function new( string name, uvm_component parent = null);
   super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    m_register_map = get_register_map(); // set property
  endfunction

 //--------------------------------------------------------------------
 // get_register_map()
 // Returns a handle to the register map (wb_mem_map) object
 virtual  function uvm_register_map get_register_map();
  uvm_object t;

  if( m_register_map == null ) begin // get it from config space
   if(! uvm_config_db #(uvm_register_map)::get(this, "", "register_map" , m_register_map ) ) begin

     uvm_report_fatal(get_name(),"no config object for register_map");
   end
     return(m_register_map);

  end
 endfunction

  //--------------------------------------------------------------------
  // get_address() - returns address based on register name
  virtual function address_t get_address( string name );
    bit valid;
    address_t address;

    uvm_register_map map = get_register_map();
    address = map.lookup_register_address_by_name( {map.get_name(), ".mac_0_regs.", name}, valid );
    if( !valid )
      uvm_report_error( get_name() , $psprintf("%s has no address in the register map", name ) );
    return(address);
  endfunction

endclass
`endif
