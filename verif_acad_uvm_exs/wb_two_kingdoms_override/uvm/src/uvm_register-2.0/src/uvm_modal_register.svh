//------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
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

  typedef string uvm_register_modes_t[string];

  //
  // CLASS: uvm_modal_register
  // This class is an uvm_register, which also has "modes".
  // The modes are just a list of strings, and the mode can
  // the changed by calling 'set_mode()'. The user implements
  // set_mode() with any kind of mode switching implementation
  // necessary.
  //
  class uvm_modal_register #(type T = int ) extends uvm_register #(T); 
    function new(string name, uvm_named_object p);
      super.new(name, p);
    endfunction

    uvm_register_modes_t modes;
    string current_mode;

    // Function: add_mode()
    // Add 'mode' to be a legal mode list.
    virtual function void add_mode(string mode);
      if (get_mode() == "")
        current_mode = mode; // Default mode.
      modes[mode] = mode;
    endfunction

    // Function: get_modes()
    // Return the list of legal modes.
    virtual function void get_modes(
	  output uvm_register_modes_t modes);
      modes = this.modes;
    endfunction

    // Function: get_mode()
    // Return the current mode.
    virtual function string get_mode();
      return current_mode;
    endfunction

    // Function: set_mode()
    // Set the current mode.
    virtual function void set_mode(string mode);
      current_mode = mode;
    endfunction
  endclass


  // CLASS: uvm_modal_register_derived
  // This is an uvm_register, which has modes and contains
  // a list of registers which act on behalf of the current mode.
  class uvm_modal_register_derived #(type T = int ) extends uvm_modal_register #(T); 
    uvm_register_base mode_registers[string];

    function new(string name, uvm_named_object p);
      super.new(name, p);
    endfunction

    // Function: set_mode()
    // Set the mode, but also copy the current value into the new mode
    // register.
    function void set_mode(string mode);
      // Get the current data value from the current register
      T d = read_data32();
      // Switch modes
      super.set_mode(mode);
      // Write the previous current register data in the
      // the current register data.
      write_data32(d);
    endfunction

    // Function: add_mode_instance()
    // Calls add_mode() and adds 'inst' to the list of register proxies.
    virtual function void add_mode_instance(string mode, uvm_register_base inst);
      add_mode(mode);
      mode_registers[mode] = inst;
    endfunction
  
`ifdef NCV
`else
    function void pre_randomize();
      super.pre_randomize();
      assert(mode_registers[get_mode()].randomize());
    endfunction
`endif
  
    function logic[31:0] read_data32();
      return mode_registers[get_mode()].read_data32();
    endfunction
  
    function void write_data32(logic[31:0] bv);
      mode_registers[get_mode()].write_data32(bv);
    endfunction
  
    function logic[31:0] peek_data32();
      return mode_registers[get_mode()].peek_data32();
    endfunction
  
    function void poke_data32(logic[31:0] bv);
      mode_registers[get_mode()].poke_data32(bv);
    endfunction
  
    function string convert2string();
      return mode_registers[get_mode()].convert2string();
    endfunction
  endclass

