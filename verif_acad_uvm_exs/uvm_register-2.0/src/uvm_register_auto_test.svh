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

// TITLE: UVM Register Auto Test
// This class is provided for quick layering. It will
// be replaced in a future release.

// CLASS: uvm_register_auto_test
//
// Utility class to plug into the register_env.
//
virtual class uvm_register_auto_test
  #(type REQ = uvm_sequence_item, 
    type RSP = uvm_sequence_item)
  extends uvm_component; 

  //XXX_RICH `uvm_component_param_utils(uvm_register_auto_test#(REQ, RSP))

  // VARIABLE: channel
  // The communication channel contained in this class.
  uvm_tlm_transport_channel #(REQ, RSP) channel;

  // PORT: transport_export
  // Connects the channel to the outside world.
  uvm_transport_export  #(REQ, RSP) transport_export;

  // PORT: ap
  // The analysis port for the response. Usually
  // connected to the sequencer.
  uvm_analysis_port #(RSP) ap;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    channel = new("channel", this);
    transport_export = new("transport_export", this);
    ap = new("ap", this);
    transport_export.connect(channel.transport_export);
  endfunction

  // TASK: do_operation()
  // A task which MUST be defined in an extension of this 
  // class. This task gets called when a new REQ (request) 
  // is received.
  // Usually a user of this class implements do_operation() to
  // map a REQ (request) into pin wiggles, and cause a 
  // transaction on a bus. Then the implementation waits 
  // for a transaction on the bus which is the response. 
  // It then creates an RSP (response) and returns it as 
  // an argument to the function.
  pure virtual task do_operation(REQ req, output RSP rsp);

  // Task: run()
  // Simple process. Call get() on the channel to get 
  // the request. Call the user implemented 'do_operation()' 
  // with the request.
  // When do_operation() returns, a response is ready for 
  // putting into the channel using put().
  task run_phase(uvm_phase phase);
    REQ req;
    RSP rsp;
    forever begin
      // Fetch the next request
      channel.get_request_export.get(req);

      // Do the operation
      do_operation(req, rsp);
      rsp.set_id_info(req);

      // Publish the response
      ap.write(rsp);

      // Supply the next response
      channel.put_response_export.put(rsp);
    end
  endtask
endclass

