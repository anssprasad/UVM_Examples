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

typedef class uvm_register_transaction;

// TITLE: UVM Register Agent
// This collection of classes provides drivers, monitors
// and sqeuencers for the UVM Register Package.

// CLASS: uvm_register_driver
// 
// A driver which expects to be connected to
// a sequencer. The requests are sent out
// the transport_port to a downstream
// TLM based cloud. The cloud returns a 
// response sometime later.
// This class acts as a forwarding object. It communicates
// with an uvm_sequencer to get requests and send responses,
// and it communicates with a request/response port to
// send requests and recieve responses.
//
class uvm_register_driver 
    #(type REQ = uvm_register_transaction,
      type RSP = uvm_register_transaction)
  extends uvm_driver #(REQ, RSP);

  `uvm_component_param_utils(uvm_register_driver#(REQ, RSP))

  // PORT: transport_port
  // This is the "downstream" connection for this register
  // driver. A REQ is sent down the transport_port,
  // and a RSP is returned. By default, both REQ and RSP
  // are 'uvm_register_transactions'.
  uvm_transport_port #(REQ, RSP) transport_port;

  // FUNCTION: new()
  // Construct the register driver and the transport_port.
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    transport_port = new("transport_port", this);
  endfunction

  // TASK: run()
  // This is a standard uvm_driver, and uses get()
  // and rsp_port.write() to communicate with the sequencer.
  task run();
    uvm_report_info("Register Driver", 
      $psprintf("Starting Register Driver (%s)...", 
        get_full_name()));

    forever begin
      // Collect the request
      seq_item_port.get(req);
      uvm_report_info("Register Driver", 
        $psprintf("  request (%s)...", 
          req.convert2string()));

      // Send the request, and wait for the response
      transport_port.transport(req, rsp);
      uvm_report_info("Register Driver", 
        $psprintf(" response (%s)...", 
          rsp.convert2string()));

      // Transfer the response back
      rsp_port.write(rsp);
    end
  endtask
endclass

// CLASS: uvm_register_sequencer
//
// A sequencer to use with an uvm_register_driver.
// It contains a register_map (since the sequences
// are going to need a register_map, but it is more
// convenient to host the register map in an uvm_component
// based system, than an uvm_transaction based system).
//
class uvm_register_sequencer
    #(type REQ = uvm_register_transaction,
      type RSP = uvm_register_transaction)
  extends uvm_sequencer #(REQ, RSP);

  `uvm_sequencer_param_utils(
    uvm_register_sequencer#(REQ, RSP))

  // VARIABLE: register_map
  // Can be used by sequences to find out what registers 
  // are available.
  uvm_register_map register_map;

  // FUNCTION: new()
  // Construct this register sequencer.
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    `uvm_update_sequence_lib_and_item(
      uvm_register_transaction)
  endfunction

  // FUNCTION: build()
  // Lookup the register map that may have been 
  // previously registered. This lookup is a convenience
  // function for the user of this class.
  function void build();
    super.build();
    // Fetch the register map for sequences to use
    // if they wish.
    register_map = 
      uvm_register_map::uvm_register_get_register_map(,this);
  endfunction
endclass

// CLASS: uvm_register_bus_monitor
//
// A monitor which expects to monitor bus transactions
//
// It uses a register_map to re-convert the bus
// transaction into a register transaction.
// Then it publishes the register transaction to
// any connected subscribers.
//
class uvm_register_bus_monitor #(type T = bus_transaction)
  extends uvm_subscriber#(T);

  `uvm_component_param_utils(uvm_register_bus_monitor#(T))

  // PORT: ap
  // Output port which publishes register transactions.
  uvm_analysis_port #(uvm_register_transaction) ap;

  // VARIABLE: register_map
  // The register map that lookups will occur in.
  uvm_register_map register_map;

  // FUNCTION: new()
  // Construct this register bus monitor and 
  // the analysis port.
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  // FUNCTION: build()
  // Lookup the register map that may have been 
  // previously registered. This lookup is a convenience
  // function for the user of this class.
  function void build();
    super.build();
    register_map = 
      uvm_register_map::uvm_register_get_register_map(,this);
  endfunction

  // FUNCTION: write()
  // This routine is called when something is published.
  // This function is called from a bus monitor - so a
  // bus transaction has been seen, and will be passed in
  // as argument 't'. This write() function then
  // converts the bus transaction into a register transaction
  // using the register map available.
  function void write(T t);

    // The output register transaction published on the 
    // analysis port, 'ap'.
    uvm_register_transaction register_transaction = new();

    // The base class handle. We have no idea exactly which
    // register type we will get - and we don't care. The
    // register base class handles all the information.
    uvm_register_base r;

    uvm_report_info("Register Bus Monitor", 
      $psprintf("     bus_transaction: %s", 
        t.convert2string()));

    register_transaction.op = t.op;

    // Get the register handle that represents this register.
    r = register_map.lookup_register_by_address(t.address);

    // Fill in the name.
    register_transaction.name = r.get_full_name();

    // Copy the data and status over.
    register_transaction.data = t.data;
    register_transaction.status = t.status;

    uvm_report_info("Register Bus Monitor", 
      $psprintf("register_transaction: %s", 
        register_transaction.convert2string()));

    // Finally, publish the register transaction
    ap.write(register_transaction);
  endfunction
endclass

// CLASS: uvm_register_bus_driver
//
// This is not a real bus_driver; it is not
//  meant to be used as part of a 
//  sequencer/sequence/driver triumvirate.
// It is simply a convenience class to generate
//  bus transactions instead of register transactions.
//
// This driver does a get() on a register
// request channel (fifo). It converts the register
// transaction into a bus transaction and sends it
// downstream to a bus transaction based cloud.
//
class uvm_register_bus_driver 
    #(type REQ = uvm_register_transaction,
      type RSP = uvm_register_transaction)
  extends uvm_component;

  `uvm_component_param_utils(
    uvm_register_bus_driver#(REQ, RSP))

  // VARIABLE: channel
  // The channel is used to 
  uvm_tlm_transport_channel #(REQ, RSP) channel;

  // PORT: transport_export
  // This export is connected to the channel,
  // and is available for others outside to connect to.
  uvm_transport_export  #(REQ, RSP) transport_export;

  // PORT: transport_port
  // Bus request transactions are generated and sent
  // down this transport_port. Bus response transactions
  // are received back on this transport_port.
  // This is the "downstream" connection.
  uvm_transport_port  #(bus_request, bus_response) 
    transport_port;

  // VARIABLE: register_map
  // The register map that will be used for address lookup.
  uvm_register_map register_map;

  // FUNCTION: new()
  // Construct this register bus driver, the
  // internal channel, and the port connections.
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    channel          = new("channel",          this);
    transport_export = new("transport_export", this);
    transport_port   = new("transport_port",   this);
  endfunction

  // FUNCTION: connect()
  // Connect the channel transport_export connection
  // (an internal connection).
  function void connect();
    transport_export.connect(channel.transport_export);
  endfunction

  // FUNCTION: build()
  // Lookup the register map that may have been 
  // previously registered. This lookup is a convenience
  // function for the user of this class.
  function void build();
    super.build();
    register_map = 
      uvm_register_map::uvm_register_get_register_map(,this);
  endfunction

  // TASK: run()
  // Do a "get()" to get a register request transaction
  // from the channel. Create a bus transaction and send
  // it down the transport_port. Receive a response on the
  // transport_port, create the register response transaction
  // and send it back to the channel using put(). 
  task run();
    bit valid_address;
    uvm_register_base r;

    REQ req;
    RSP rsp;

    bus_request bus_req;
    bus_response bus_rsp;

    uvm_report_info("Register Bus Driver", 
      $psprintf("Starting Bus Driver (%s)...", 
        get_full_name()));

    // Loop forever, getting register requests,
    // mapping to bus requests and sending them on.
    // Using the transport() functionality, a
    // bus_response is received, and translated
    // back into a register response, and returned.
    forever begin
      channel.get_request_export.get(req);

      uvm_report_info("Register Bus Driver", 
        $psprintf("Register request (%s)...", 
          req.convert2string()));

      // Create a bus request.
      bus_req = new();

      // Figure out what address this register is at.
      bus_req.address = 
        register_map.lookup_register_address_by_name(
          req.name, valid_address);
      if (!valid_address) begin
        uvm_report_error("Register Bus Driver", 
          $psprintf("Register %s not found", req.name));
        bus_req.address = '1; 
      end
      bus_req.op = req.op;
      bus_req.data = req.data; 

      uvm_report_info("Register Bus Driver", 
        $psprintf("  bus request (%s)...", 
          bus_req.convert2string()));

      // Send the bus request downstream,
      // wait for the response.
      transport_port.transport(bus_req, bus_rsp);

      uvm_report_info("Register Bus Driver", 
        $psprintf(" bus response (%s)...", 
          bus_rsp.convert2string()));

      // Create a register response.
      rsp = new();

      // Figure out what register this address
      //  represents.
      r = register_map.lookup_register_by_address(
        bus_rsp.address);
      rsp.name = r.get_full_name(); 
      rsp.data = bus_rsp.data;
      rsp.op = bus_rsp.op;
      rsp.status = bus_rsp.status;
      rsp.set_id_info(req);

      uvm_report_info("Register Bus Driver", 
        $psprintf("Register response (%s)...", 
          rsp.convert2string()));

      // Return the register response.
      channel.put_response_export.put(rsp);
    end
 endtask
endclass


// CLASS: uvm_register_monitor
//
// A component which expects to be sent relevant
// register transactions.
//
class uvm_register_monitor #(type T = int)
  extends uvm_subscriber#(T);

  `uvm_component_param_utils(uvm_register_monitor#(T))

  // VARIABLE: register_map
  // The register map that will be used for name lookup.
  uvm_register_map register_map;

  // FUNCTION: new()
  // Construct the register scoreboard. 
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // FUNCTION: build()
  // Lookup the register map that may have been 
  // previously registered. This lookup is a convenience
  // function for the user of this class.
  function void build();
    register_map = 
      uvm_register_map::uvm_register_get_register_map(,this);
  endfunction

  // FUNCTION: write()
  // Receive a register transaction, and use the 
  // current register map to do shadow checking. 
  // (bus_read32() and bus_write32()).
  // Note - Usually T is uvm_register_transaction.
  function void write(T t);
    uvm_register_base r;

    uvm_report_info("Register Scoreboard", 
      t.convert2string());

    r = register_map.lookup_register_by_name(t.name);

    case (t.op)
      READ:  begin
             r.bus_read32(t.data);
             uvm_report_info("Register Scoreboard",
       $psprintf("Checking (%s) received=%x vs shadow=%x", 
                 t.name, t.data, r.get_data32()));
             end
      WRITE: begin
             uvm_report_info("Register Scoreboard",
       $psprintf("Writing (%s) received=%x replaces shadow=%x", 
                 t.name, t.data, r.get_data32()));
             r.bus_write32(t.data);
             end
      default: 
        uvm_report_error("register_monitor", 
          $psprintf(
"Op code %0d not recognized. Legal values are %0d(%s) and %0d(%s)",
            t.op, READ, READ, WRITE, WRITE));
    endcase
  endfunction
endclass
