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


// The three files uvm_memory.svh, uvm_memory_range.svh
// and uvm_memory_ranges.svh are meant to be used together,
// and included inside a package.
`include "uvm_memory_range.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
`include "uvm_memory_ranges.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

// CLASS: uvm_memory
// uvm_memory is used to model memory, and have that
// modeled memory participate with the register
// models in order to support certain address map
// verification techniques (like "shadow" memory
// and randomized configurations of memory and registers).
//
// The choice of how to model memory needs to be made
// carefully. The model of memory supported by uvm_memory
// is as follows. uvm_memory "contains" a regular verilog
// memory - modeled something like 
//   bit[7:0]mem[address];
// or
//   bit[31:0]mem[address];
// or
//   T mem[address];
//
//   where T is some typedef (packed struct, union, etc).
//
// The 'mem' field is a sparse array, which means
// it consumes little or no actual space until a value is
// written to an address.
//
// Within a management memory space, there can be ranges. 
// The ranges can either be unmanaged (holes) or managed.
// The holes are treated like "illegal" memory access. The
// managed ranges are treated like memory which "could be
// used".
//
class uvm_memory #(type T = int) 
  extends uvm_register#(T);

  // Variable: mem[int]
  // A "regular" verilog memory implemented as an
  // associative array (sparse array). Each memory
  // location is of type 'T'. Normal access to this memory
  // is to use mem_peek() and mem_poke().
  T mem[int];

  // Variable: ranges
  // This is the list of managed (and unmanaged) addresses.
  // In a future release 'ranges' will be 'rand'.
  uvm_memory_ranges ranges;

  // Variable: start_address
  // The first legal address to use in this memory.
  address_t start_address;

  // Variable: end_address
  // The last legal address to use in this memory.
  address_t end_address;

  function new(string name, 
      uvm_named_object p, 
      T l_resetValue = 0);
    super.new(name, p, l_resetValue);
    m_isMemory = 1;
    ranges = new();
  endfunction

  function void post_randomize();
    // After randomization, the memory blocks may have shrunk.
    // A shrink means that certain addresses are no longer
    // within the "managed" block - which means they are
    // no longer legal addresses to use. Those locations
    // should have their values set to 'x.

    // TODO: Visit all the "shrunk" addresses, and set the
    // values to 'x.

    // Check for the ranges we are going to throw away.
    // Those memory locations no longer read a value - 
    // they're "unallocated". Set them to X.
`ifdef NOTDEF
    for(int i = new_size; i < old_size; i++)
      if (ranges.old_ranges[i].t != MEMORY_SET_BY_HAND)
        // The range was NOT MEMORY_SET_BY_HAND, but it 
        // is a range that we are going to throw away.
        for (int j  = ranges.old_ranges[i].range_start; 
                 j <= ranges.old_ranges[i].range_end; j++)
          mem_poke(j, 'x);
`endif
  endfunction

  // Function: mem_poke()
  // "Write" to the actual memory using address (addr)
  // and data (d).
  function void mem_poke(address_t addr, T d);
    // TODO: calc_write()
    // TODO: check_ranges()
    mem[addr] = d;
    poke(mem[addr]);  // Side-effect. Update the "data"
  endfunction

  // Function: mem_peek()
  // "Read" from the actual memory using address (addr).
  // Return the value read.
  function T mem_peek(address_t addr);
    // TODO: calc_read()
    // TODO: check_ranges()

    // DEBUG $display("%m: reading mem[%0x(%0d)] as %x (%0d)",
    // DEBUG   addr, addr, mem[addr], mem[addr]);
    if (mem.exists(addr)) begin
      poke(mem[addr]);  // Side-effect. Update the "data"
      return mem[addr];
    end
    else begin
      uvm_report_info("MEMORY",
        $psprintf("Address 0x%x (%d) does not exist in %s",
          addr, addr, get_full_name()));
    end
  endfunction

`ifdef NOTDEF
  function T peek();
    // If the memory address doesn't exist, return x.
  endfunction
`endif

  virtual function uvm_memory_range add_range(
    address_t range_start, 
    address_t range_end, 
    string tag_name = "ranges");

    return ranges.add_range(range_start, range_end, tag_name);
  endfunction

  virtual function uvm_memory_range add_range_random_by_hand(
    string tag_name = "ranges");

    if (1)
      uvm_report_fatal("MEMORY", $psprintf(
"add_range_random_by_hand() not supported in this release"));

    return ranges.add_range_random_by_hand(tag_name);
  endfunction

  virtual function void print();
    ranges.print();
  endfunction

  function void set_start_range(address_t offset);
    start_address = offset;
  endfunction

  function void set_end_range(address_t offset);
    end_address = offset;
  endfunction

  virtual function address_t get_start_range();
    return start_address;
  endfunction

  virtual function address_t get_end_range();
    return end_address;
  endfunction

  virtual function bit range_ok(address_t address);
    if ( address < get_start_range() )
      return 0;
    if ( address > get_end_range() )
      return 0;
    return 1;
  endfunction

  function string convert2string();
    string s = "";
    foreach (mem[i])
      s = {s, $psprintf("[%0x:%0x] ", i, mem[i])};
    if ( s == "" )
      s = "<empty>";
    return s; 
  endfunction

  typedef enum bit { MEM_VAL_2_BYTES, MEM_BYTES_2_VAL } mem_pack_t;

  // m_pack_bytes()
  // Inputs:
  //   pack_unpack, which way we're packing...
  //   byte_pos, the position at which to start in the array
  //     of bytes.
  //
  // Inouts:
  //   value 'val', representing a data value we're
  //     going to pack and return with values from 'ba'.
  //     
  //   ba, the array of bytes that we will loop through.
  //
  // Return value:
  //   byte_pos, the NEXT position in the byte array to process.
  //
  virtual function int m_pack_bytes( 
      mem_pack_t pack_unpack,
      inout T val, 
      ref bytearray_t ba, 
      int byte_pos);

    int nbits, nbytes;
    int start_bit;

    nbits = $bits(T);
    start_bit = 0;
    nbytes = ba.size();
    // Each time through the loop, byte_pos gets incremented
    // by 1, and start_bit gets incremented by 8.
    while (byte_pos < nbytes) begin
      case (pack_unpack)
      MEM_BYTES_2_VAL: begin
        // Stuff the byte from the array into the value.
`ifdef NCV
        val[start_bit+:8] = ba[byte_pos];
		byte_pos++;
`else
        val[start_bit+:8] = ba[byte_pos++];
`endif
	  end
      MEM_VAL_2_BYTES: begin
        // Grab the byte from the value, and put it
        // in the array.
`ifdef NCV
        ba[byte_pos] = val[start_bit+:8];
		byte_pos++;
`else
        ba[byte_pos++] = val[start_bit+:8];
`endif
	  end
      default:
        uvm_report_fatal("MEMORY", 
          $psprintf("Illegal operation - %0d", pack_unpack));
      endcase

      start_bit+=8;
      if ( start_bit >= nbits )
        break;
    end
    return byte_pos;
  endfunction

  // Function: mem_poke_bytes()
  // Given an address (addr) and an array of bytes,
  // write those bytes into the memory, starting at the
  // address supplied.
  virtual function void mem_poke_bytes(
      address_t addr, bytearray_t d);
    T val;
    int nbytes, byte_pos;

    nbytes = d.size(); 
    byte_pos = 0;
    while (byte_pos < nbytes) begin
      // This is the FIRST time we're
      // considering this addr. If there
      // is an existing value, pre-fill 'val'.
      val = 0;
      if (mem.exists(addr))
        val = mem_peek(addr); // Old mem value.

      // Input 'val', 'd'. Output 'val'.
      byte_pos = m_pack_bytes(
        MEM_BYTES_2_VAL, val, d, byte_pos);

      // There is sometimes a partial 'val'.
      // This means the array of bytes is not
      // a multiple of the sizeof(T). This means
      // we're going to fill in some number of T values
      // and a final T which is partial.
      // Since 'val' is pre-filled with the 
      // existing value, we'll end up changing the
      // changed bytes, and not changing the unchanged
      // bytes.
      // Updating will just re-write the unchanged bytes.
      mem_poke(addr, val);
      addr++;
    end
  endfunction

  // Function: mem_peek_bytes()
  // Given an address (addr) and a number of bytes to
  // read, return a list of bytes (nbytes long) starting
  // from the address supplied. 
  virtual function void mem_peek_bytes(
	  output bytearray_t d,
      input address_t addr, int nbytes);
    T val;
    int nbits, byte_pos;

    byte_pos = 0;
    d = new[nbytes];
    while (byte_pos < nbytes) begin
      val = mem_peek(addr);
      // Input 'val', output 'd'.
      byte_pos = m_pack_bytes(
        MEM_VAL_2_BYTES, val, d, byte_pos);
      addr++;
    end
    // Return the array of bytes. (via argument 'd')
  endfunction


  // Function: bus_read()
  virtual function void bus_read(
    bytearray_t read_data, address_t address = 0);

    T val;
    int nbytes, byte_pos;

    nbytes = read_data.size(); 
    byte_pos = 0;
    while (byte_pos < nbytes) begin
      val = 'x;
      if (mem.exists(address))
        val = mem_peek(address); // Old mem value.

      byte_pos = m_pack_bytes(
        MEM_BYTES_2_VAL, val, read_data, byte_pos);

      // Side-effect - we want the "data" value to be
      // the value read.
      if (mem.exists(address))
        void'(mem_peek(address));

      bus_read_bv(val);
      address++;
    end
  endfunction

//TODO: RICH - bus_write() -> Request 

/* TODO: check_range()
   TODO: Put these (and other) error checks back in.
      uvm_report_error("MEM", 
        $psprintf(
          "Illegal peek memory access to address %0x", 
            address));
      uvm_report_error("MEM", 
        $psprintf(
          "Address %0x out-of-range [%0x:%0x]", 
          address, get_start_range(), get_end_range()));
*/


    virtual function void peek_bytes(
	    output bytearray_t ba, 
        input address_t address, int nbytes = 0);
      mem_peek_bytes(ba, address, nbytes);
    endfunction

    virtual function void poke_bytes(
        address_t address, bytearray_t new_data);
      mem_poke_bytes(address, new_data);
    endfunction
endclass
