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
  // CLASS: uvm_id_register
  //
  // A base class which implements an "ID register" 
  // functionality. Each successive read() call retrieves
  // the next value in a list. Upon reaching the end of
  // the list, the first one is retrieved, repeating.
  // The sequence of values read from this register is
  // used as an ID.
  //
  class uvm_id_register #(type T = bit[31:0]) 
      extends uvm_register#(T);

    T values[$];
    local T pointer;
    local int max_n;

`ifndef NCV
    covergroup id_reads(int n);
      option.name = get_full_name();
      option.comment = "ID register location read";
      option.per_instance = 1;
      cp_id_reads: coverpoint pointer {
        bins pointer_bins[] = { [0:n-1] };
      }
    endgroup: id_reads

    covergroup id_writes(int n);
      option.name = get_full_name();
      option.comment = "ID register location write";
      option.per_instance = 1;
      cp_id_writes: coverpoint pointer {
        bins pointer_bins[] = { [0:n-1] };
      }
    endgroup: id_writes
`endif // NOTDEF NCV

    function new(string name, uvm_named_object p, T new_values[]);
      int n;
      super.new(name, p);
      pointer = 0;
      n = new_values.size();
`ifndef NCV
      id_reads  = new(n);
      id_writes = new(n);
`endif // NOTDEF NCV
      max_n = n;
      values = new_values;
    endfunction

    // By definition, my id_register goes back to the 
    // beginning on reset.
    function void reset();
      super.reset();
      pointer = 0;
    endfunction

    // Function: get_length()
    // Return the number of reads() that it will take
    // to get all the data items read.
    virtual function int get_length();
      return values.size();
    endfunction

    // Function: id_write()
    // Call this function to append a new value to the
    // id register. id_write() is normally only called
    // at system initialization time, since the ID
    // values normally don't change once set.
    virtual function void id_write(T v);
      // Update the pointer. This IS the write
      // to the id register.
      pointer = v;
      if (pointer > get_length()-1)
        pointer = 0;
      // Since we just updated the pointer, we should
      // make sure the 'data' value is correct.
      // This makes 'data' available for raw access.
      poke(values[pointer]);
`ifndef NCV
      id_writes.sample();
`endif // NOTDEF NCV
    endfunction

    // Function: id_read()
    // Call this function to fetch or read the next value 
    // from the ID register. Successive calls to id_read() 
    // return the successive elements in the 'values' array. 
    // When the end of the array is reached, we start over 
    // from the beginning.
    virtual function T id_read();
      if (pointer > get_length()-1)
        pointer = 0;
`ifndef NCV
      id_reads.sample();
`endif // NOTDEF NCV

      // Set the value of the "data" field of the register.
      // This makes 'data' available for raw access.
      poke(values[pointer++]);
      return peek(); 
    endfunction

    // Function: read_without_notify()
    // Re-implemented to affect our new ID 
    // register functionality.
    function T read_without_notify(T local_mask = '1);
      return id_read();
    endfunction

    // Function: write_without_notify()
    // Re-implemented to affect our new ID 
    // register functionality.
    // Note: "writing" this register does NOT write a
    // new value into the register. Instead, writing
    // to this register actually updates (writes to)
    // the pointer.
    function void write_without_notify(T v, T local_mask = '1);
      id_write(v);
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

