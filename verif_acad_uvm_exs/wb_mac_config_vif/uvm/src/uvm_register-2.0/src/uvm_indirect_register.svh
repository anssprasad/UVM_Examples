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

  //
  // CLASS: uvm_indirect_register 
  //    and uvm_indirect_address_register
  //
  // This pair of registers are used together. An address register
  // is used to define an indirect address which will be used the next
  // time the data register is acccessed.
  //
  // For example, writing value = 42 to the address register causes
  // the next write to the data register to store the written value in
  // an internal (indirect) memory at location 42. Furthermore, after
  // each write or read on the data register, the address is incremented
  // by one.
  //
  // To use the indirect registers, a pair must be constructed. The
  // address register and the data register. Once both are constructed,
  // they are linked using the 'connect_to_data_register()' call.
  //
  // Once they are linked, they are no different than any other
  // register, and can be put into the register files and address maps
  // as desired.
  //
  //
  class uvm_indirect_register #(type T = bit[31:0]) 
      extends uvm_register#(T);

    T values[$];
    local T pointer;

    function new(string name, uvm_named_object p);
      super.new(name, p);
      pointer = 0;
    endfunction

    function void reset();
      super.reset();
      pointer = 0;
    endfunction

    // Function: indirect_address_write()
    // Sets the indirect address to v for the next
    // data read or write.
    virtual function void indirect_address_write(T v);
      pointer = v;
    endfunction

    // Function: indirect_address_read()
    // Returns the current pointer. 
    virtual function T indirect_address_read();
      return pointer;
    endfunction

    // Peek and Poke are the only routines with
    // access to read or write the 'values' array.
    // No other code modifies or reads this array.
    // Function: peek()
    // Re-implement to have the correct behavior.
    function T peek();
      return values[pointer];
    endfunction

    // Function: poke()
    // Re-implement to have the correct behavior.
    function void poke(T v);
      values[pointer] = v;
    endfunction

    // Function: indirect_write()
    // Set the value, and increment the pointer.
    virtual function void indirect_write(T v);
      poke(v);
      pointer++;
    endfunction

    // Function: indirect_read()
    // Get the current value, and increment the pointer.
    virtual function T indirect_read();
      T v = peek();
      pointer++;
      return v; 
    endfunction

    // Function: read_without_notify()
    // Re-implement to have the correct behavior.
    function T read_without_notify(T local_mask = '1);
      // TODO: Masking?
      return indirect_read();
    endfunction

    // Function: write_without_notify()
    // Re-implement to have the correct behavior.
    function void write_without_notify(T v, 
        T local_mask = '1);
      // TODO: Masking?
      indirect_write(v);
    endfunction

    function string convert2string();
      return $psprintf("%p", values);
    endfunction

    virtual function string convert2string_alternate();
      string s = "";
      foreach (values[i])
        s = {s, (i==0?"":" "), 
          $psprintf("%0x", values[i])};
      return s;
    endfunction
  endclass

  // CLASS: uvm_indirect_address_register
  // Used in conjunction with uvm_indirect_register.
  // This class provides the "address register" behavior
  // of an indirect register access.
  class uvm_indirect_address_register 
    #(type T = bit[31:0]) extends uvm_register#(T);

      local uvm_indirect_register #(T) r;

      function new(string name, uvm_named_object p);
        super.new(name, p);
      endfunction

      // Function: connect_to_data_register()
      // This routine is used to provide
      // the data register to the address register.
      function void connect_to_data_register(
        uvm_indirect_register #(T) r);
        uvm_report_info("AddressRegister", 
          $psprintf(
"Connecting Address Register '%s' to Data Register '%s'",
            get_full_name(), r.get_full_name()));
        // TODO: check $cast;
        this.r = r;
      endfunction

      // Function: poke()
      // Poke is re-implemented to set the pointer
      // value in the data register.
      function void poke(T v);
        //uvm_report_info("AddressRegister", 
        //  $psprintf("Writing address '%0x' to '%s'.",
        //    v, r.get_full_name()));
        r.indirect_address_write(v);
      endfunction

      // Function: peek()
      // Peek is re-implemented to get the pointer
      // value in the data register.
      function T peek();
        T v = r.indirect_address_read();
        //uvm_report_info("AddressRegister", 
        //  $psprintf("Reading address '%0x' from '%s'.",
        //    v, r.get_full_name()));
        return v;
      endfunction
  endclass
