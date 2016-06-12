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

// TITLE: UVM Register Sequences
// A register sequence base class and a register sequence. 

// CLASS: uvm_register_sequence_base
//
// A useful base class for register sequences
// Especially when used in automated register testing.
//
class uvm_register_sequence_base
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends uvm_sequence #(REQ, RSP);

  `uvm_sequence_utils(uvm_register_sequence_base#(REQ, RSP), 
    uvm_register_sequencer#(REQ, RSP))

  int counter = 0;

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "uvm_register_sequence_base");
    super.new(name);
  endfunction

  // FUNCTION: do_write()
  // Helper function which does a write given
  // a register name and data to write. 
  virtual task do_write(string register_name, 
      dataWidth_t data_to_write);

    REQ req;
    RSP rsp;

    req = REQ::type_id::create(); 
	start_item(req);
    assert(req.randomize());
    req.name = register_name; 
    req.op = WRITE;
    req.data = data_to_write;
	finish_item(req);
    get_response(rsp);
	rsp.status = PASS;
  endtask

  // FUNCTION: do_read()
  // Helper function which does a read given
  // a register name. It returns the
  // data read as an argument.
  virtual task do_read(string register_name, 
          output dataWidth_t data_read);
    REQ req;
    RSP rsp;

    req = REQ::type_id::create(); 
	start_item(req);
    assert(req.randomize());
    req.name = register_name; 
    req.op = READ;
    // Clear the data.
    req.data = '0;
	finish_item(req);
    get_response(rsp);
	rsp.status = PASS;
    data_read = rsp.data;
  endtask

  // FUNCTION: do_write_read()
  // Helper function which does a write and a read given
  // a register name and data to write. It returns the
  // data read as an argument.
  virtual task do_write_read(string register_name, 
      dataWidth_t data_to_write, 
          output dataWidth_t data_read);

	do_write(register_name, data_to_write);
	do_read(register_name, data_read);

	// TODO: Should do something fancier - like use
	// the register compare.
    if (data_read != data_to_write)
      uvm_report_warning("MISMATCH", 
        $psprintf("(%s) Expected %0x, read back %0x",
          register_name, data_to_write, data_read));
  endtask

  // TASK: body()
  // Base class functionality; find what sequencer we
  // are connected to, and lookup a "counter" parameter.
  virtual task body();
    uvm_sequencer_base my_sequencer;

    // Can't call get_config_*() from a sequence.
    // Bounce off the sequencer.
    $cast(my_sequencer, get_sequencer());
    if (!my_sequencer.get_config_int("counter", counter)) 
      counter = 10; // Default: 10 times.

    uvm_report_info(get_type_name(),
      $psprintf("Starting Sequence %s..., counter=%0d", 
        get_type_name(), counter));
  endtask
endclass

class built_in_sequences 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends uvm_register_sequence_base #(REQ, RSP);

  `uvm_sequence_utils(
    built_in_sequences#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  register_list_t register_list;
  int verbose = 0;

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "built_in_sequences");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();

    super.body();

    begin
      uvm_register_sequencer#(REQ, RSP) my_sequencer;

	  // Fetch the sequencer we are running on.
	  // Assume it has the register map we are going to use.
      $cast(my_sequencer, get_sequencer());

      // Get a list of all the registers in the register map.
      my_sequencer.register_map.get_register_array(register_list);
    end

    // Create a little summary of the registers we'll test.
	if (verbose) begin
      uvm_report_info("BuiltInTest", 
        $psprintf(" Register Name(s) to Test (%0d total)",
          register_list.size()));
      foreach (register_list[i]) begin
        uvm_report_info("BuiltInTest", 
          $psprintf("  #%4d - %s", 
		    i, register_list[i].get_full_name()));
	  end
    end
  endtask
endclass

// CLASS: register_alias
class register_alias 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends built_in_sequences #(REQ, RSP);

  `uvm_sequence_utils(
    register_alias#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "register_alias");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
    BV data, r_data;
    register_list_t second_register_list;

	super.body();

    uvm_report_info("Alias", "----------");
    uvm_report_info("Alias", 
      $psprintf("(%s) Starting...", get_type_name()));

    foreach (register_list[i]) begin
      if (verbose)
	    uvm_report_info("Alias", 
          $psprintf("(%s) Reseting Shadow Register %s", 
            get_type_name(), register_list[i].get_full_name()));
	  register_list[i].reset();
    end

	// Get a list of the registers to READ back.
	second_register_list = register_list;

    // Go through the list of registers.
    foreach (register_list[i]) begin
      if (verbose)
	    uvm_report_info("Alias", 
          $psprintf("(%s) Writing Register %s", 
            get_type_name(), register_list[i].get_full_name()));

      register_list[i].write_data32(data);

      // Issue the bus cycle.
      do_write(register_list[i].get_full_name(), data);

      foreach (second_register_list[j]) begin
        if (verbose)
		  uvm_report_info("Alias", 
            $psprintf("(%s) Reading-back Register %s", 
              get_type_name(), second_register_list[j].get_full_name()));
        do_read(second_register_list[j].get_full_name(), r_data);
	    second_register_list[j].bus_read32(r_data);
	  end
	  register_list[i].reset();
    end
    uvm_report_info("Alias", 
      $psprintf("(%s) Done.", get_type_name()));
  endtask
endclass


// CLASS: power_on_reset
class power_on_reset 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends built_in_sequences #(REQ, RSP);

  `uvm_sequence_utils(
    power_on_reset#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "power_on_reset");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
    int r_data;

	super.body();

    uvm_report_info("PowerOnReset", "----------");
    uvm_report_info("PowerOnReset", 
      $psprintf("(%s) Starting...", get_type_name()));

    foreach (register_list[i]) begin
      if (verbose)
	    uvm_report_info("PowerOnReset", 
          $psprintf("(%s) Reseting Shadow Register %s", 
            get_type_name(), register_list[i].get_full_name()));
	  register_list[i].reset();
    end

    // Go through the list of registers.
    foreach (register_list[i]) begin
      if(verbose)
	    uvm_report_info("PowerOnReset", 
          $psprintf("(%s) Reading Register %s", 
            get_type_name(), register_list[i].get_full_name()));

      // Issue the bus cycle.
      do_read(register_list[i].get_full_name(), r_data);
	  register_list[i].bus_read32(r_data);
    end
    uvm_report_info("PowerOnReset", 
      $psprintf("(%s) Done.", get_type_name()));
  endtask
endclass

// CLASS: walking
class walking
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends built_in_sequences #(REQ, RSP);

  //`uvm_sequence_utils(
    //walking#(REQ, RSP), 
      //uvm_register_sequencer#(REQ, RSP))

  string test_name = "Walking";
  BV starting_value;
  bit right_fill = 'b0;
  BV value;

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "walking");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
    BV r_data, data;
	int max_shifts;

	super.body();

    uvm_report_info(test_name, "----------");
    uvm_report_info(test_name, 
      $psprintf("(%s) Starting...", get_type_name()));

    // Go through the list of registers.
    foreach (register_list[i]) begin
	  data = starting_value;
	  max_shifts = register_list[i].get_num_bits();
      if (verbose)
	    uvm_report_info(test_name, 
          $psprintf("(%s) Starting Register %s, width=%0d bits", 
            get_type_name(), 
            register_list[i].get_full_name(),
            max_shifts));

	  for (int j = 0; j < max_shifts; j++) begin
        if (verbose)
		  uvm_report_info(test_name, 
            $psprintf("(%s) %3d Assigning Register %s the value '%x'", 
              get_type_name(), 
			  j,
			  register_list[i].get_full_name(),
			  data));
  
		// Update the shadow.
		register_list[i].write_data32(data);

        // Issue the bus cycle.
		// Write to the hardware.
		do_write(register_list[i].get_full_name(), data);
		// Read back
        do_read(register_list[i].get_full_name(), r_data);

		// Compare.
	    register_list[i].bus_read32(r_data);

	    data = data << 1;
		data = data | right_fill;
      end
	end
    uvm_report_info(test_name, 
      $psprintf("(%s) Done.", get_type_name()));
  endtask
endclass

// CLASS: walking_zeros
class walking_zeros 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends walking #(REQ, RSP);

  `uvm_sequence_utils(
    walking_zeros#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "walking_zeros");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
	test_name = "Walking 0's";
	starting_value = '0;
	right_fill = 'b1;
	starting_value |= 'b1;
	starting_value = ~starting_value; 
	super.body();
  endtask
endclass

// CLASS: walking_ones
class walking_ones 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends walking #(REQ, RSP);

  `uvm_sequence_utils(
    walking_ones#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "walking_ones");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
	test_name = "Walking 1's";
	starting_value = '0;
	starting_value |= 'b1;
	super.body();
  endtask
endclass

// CLASS: write_read
class write_read 
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends built_in_sequences #(REQ, RSP);

  `uvm_sequence_utils(
    write_read#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  // FUNCTION: new()
  // Construct the object.
  function new(string name = "write_read");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
	string test_name = "Write/Read";
	BV data, r_data;
	super.body();

    uvm_report_info(test_name, "----------");
    uvm_report_info(test_name, 
      $psprintf("(%s) Starting...", get_type_name()));

	data = 42;

    // Go through the list of registers.
    foreach (register_list[i]) begin
	  if (verbose)
        uvm_report_info(test_name, 
          $psprintf("(%s) Writing Register %s with '%x'", 
            get_type_name(), 
			register_list[i].get_full_name(),
			data));

		// Update the shadow.
		register_list[i].write_data32(data);

        // Issue the bus cycle.
		// Write to the hardware.
		do_write(register_list[i].get_full_name(), data);
	end
  
    foreach (register_list[i]) begin
	  // Read back
      do_read(register_list[i].get_full_name(), r_data);

      if (verbose)
	    uvm_report_info(test_name, 
          $psprintf("(%s) Read Register %s as '%x'", 
            get_type_name(), 
			register_list[i].get_full_name(),
			r_data));

	  // Compare.
	  register_list[i].bus_read32(r_data);
	end
  endtask
endclass

// CLASS: register_sequence_all_registers
//
// Gets a list of all registers.
// Reads and writes them.
//
class register_sequence_all_registers
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends built_in_sequences #(REQ, RSP);

  `uvm_sequence_utils(
    register_sequence_all_registers#(REQ, RSP), 
      uvm_register_sequencer#(REQ, RSP))

  walking_ones #(REQ, RSP) walking_1s_h;
  walking_zeros#(REQ, RSP) walking_0s_h;
  register_alias#(REQ, RSP) register_alias_h;
  power_on_reset#(REQ, RSP) power_on_reset_h;
  write_read#(REQ, RSP) write_read_h;

  // FUNCTION: new()
  // Construct the object.
  function new(string name = 
    "register_sequence_all_registers");
    super.new(name);
  endfunction

  // TASK: body()
  // A sequence which calls the base class, then retrieves
  // a list of all registers. It then iterates through these
  // registers calling the helper function 'do_write_read()'
  // on each register in turn.
  task body();
    int r_data;

    super.body();

    uvm_report_info("AutoTest", "----------");
    uvm_report_info("AutoTest", 
      $psprintf("(%s) Starting...", get_type_name()));

    // Go through the list of registers.
    foreach (register_list[i]) begin
      uvm_report_info("AutoTest", 
        $psprintf("(%s) Testing Register %s", 
          get_type_name(), register_list[i].get_full_name()));
      // Issue the bus cycles.
      do_write_read(register_list[i].get_full_name(), i, r_data);
    end
    uvm_report_info("AutoTest", 
      $psprintf("(%s) Done.", get_type_name()));
  endtask
endclass
