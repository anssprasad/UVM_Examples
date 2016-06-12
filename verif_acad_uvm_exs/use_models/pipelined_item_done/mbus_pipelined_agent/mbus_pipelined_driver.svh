//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
//
// This class implements a pipelined driver
//
class mbus_pipelined_driver extends uvm_driver #(mbus_seq_item);

`uvm_component_utils(mbus_pipelined_driver)

virtual mbus_if MBUS;

function new(string name = "mbus_pipelined_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

// the two pipeline processes use a semaphore to ensure orderly execution
semaphore pipeline_lock = new(1);
//
// The run_phase(uvm_phase phase);
//
// This spawns two parallel transfer threads, only one of
// which can be active during the cmd phase, so implementing
// the pipeline
//
task run_phase(uvm_phase phase);

  @(posedge MBUS.MRESETN);
  @(posedge MBUS.MCLK);

  fork
    do_pipelined_transfer;
    do_pipelined_transfer;
  join

endtask

//
// This task has to be automatic because it is spawned
// in separate threads
//
task automatic do_pipelined_transfer;
  mbus_seq_item req;

  forever begin
    pipeline_lock.get();
    seq_item_port.get(req);
    accept_tr(req, $time);
    void'(begin_tr(req, "pipelined_driver"));
    MBUS.MADDR <= req.MADDR;
    MBUS.MREAD <= req.MREAD;
    MBUS.MOPCODE <= req.MOPCODE;
    @(posedge MBUS.MCLK);
    while(!MBUS.MRDY == 1) begin
      @(posedge MBUS.MCLK);
    end
    // End of command phase:
    // - unlock pipeline semaphore
    // - signal CMD_DONE
    pipeline_lock.put();
    req.trigger("CMD_DONE");
    // Complete the data phase
    if(req.MREAD == 1) begin
      @(posedge MBUS.MCLK);
      while(MBUS.MRDY != 1) begin
        @(posedge MBUS.MCLK);
      end
      req.MRESP = MBUS.MRESP;
      req.MRDATA = MBUS.MRDATA;
    end
    else begin
      MBUS.MWDATA <= req.MWDATA;
      @(posedge MBUS.MCLK);
      while(MBUS.MRDY != 1) begin
        @(posedge MBUS.MCLK);
      end
      req.MRESP = MBUS.MRESP;
    end
    req.trigger("DATA_DONE");
    end_tr(req);
  end
endtask: do_pipelined_transfer

endclass: mbus_pipelined_driver
