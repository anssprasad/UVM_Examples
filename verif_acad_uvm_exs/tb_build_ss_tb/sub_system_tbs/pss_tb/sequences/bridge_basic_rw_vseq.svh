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

class bridge_basic_rw_vseq extends uvm_sequence #(ahb_seq_item);

`uvm_object_utils(bridge_basic_rw_vseq)

function new(string name = "bridge_basic_rw_vseq");
  super.new(name);
endfunction

task body;
  ahb_seq_item req = ahb_seq_item::type_id::create("req");

  repeat(10) begin
    start_item(req);
    assert(req.randomize() with {HADDR inside {[0:32'h18], [32'h100:32'h124], [32'h200:32'h210], [32'h300:32'h318]};
                                 HWRITE == AHB_READ;});
    finish_item(req);
    $display("%t: Read %0h from %0h", $time, req.DATA, req.HADDR);
  end
endtask: body

endclass:bridge_basic_rw_vseq