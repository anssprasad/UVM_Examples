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
  // CLASS: uvm_fifo_register
  //
  // A base class which implements a "FIFO register" 
  // functionality. This register holds mulitple
  // elements - limited in quantity by the amount of
  // memory on the system. The first item put into the
  // fifo is the first item retrieved.
  //
  class uvm_fifo_register #(type T = bit[31:0]) 
      extends uvm_register#(T);

    T values[$];

    function new(string name, uvm_named_object p);
      super.new(name, p);
    endfunction

    function void reset();
	  // What should reset do? Clear the fifo?
	  while(values.size() > 0)
	    void'(values.pop_front());
      super.reset();
    endfunction

    // Function: size()
    // Return the number of reads() that it will take
    // to get all the data items read.
    virtual function int size();
      return values.size();
    endfunction

    // Function: fifo_write()
    // Call this function to append a new value to the
    // fifo register. 
    virtual function void fifo_write(T v);
	  // Items go in the back.
	  values.push_back(v);
    endfunction

    // Function: fifo_read()
    // Call this function to fetch or read the last item written
	// from the FIFO register.
    virtual function T fifo_read();
	  if (values.size() <= 0) begin
	    uvm_report_error("FIFO Register", 
		  $psprintf("Illegal read() from an empty fifo (%s)",
		    get_full_name()));
	    return 0;
	  end
	  else
	    // Items come out the front.
        return values.pop_front();
    endfunction

    // Function: read_without_notify()
    function T read_without_notify(T local_mask = '1);
	  // TODO: calc_read()
      T v = fifo_read();
	  if (values.size() > 0)
	    poke(values[0]); // Update the "data" field. 
		                 // The last item written. 
	  return v;
    endfunction

    // Function: write_without_notify()
    function void write_without_notify(T v, T local_mask = '1);
	  // TODO: calc_write()
      fifo_write(v);
	  poke(v); // Update 'data' as the last item written. 
    endfunction

	function T peek();
	  // TODO: Should peek()'ing an empty fifo produce an error?
	  if (values.size() > 0)
	    return values[0];
	  return 0;
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

