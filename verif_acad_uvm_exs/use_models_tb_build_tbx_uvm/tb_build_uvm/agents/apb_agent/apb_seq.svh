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
`ifndef APB_SEQ
`define APB_SEQ


//
// Class Description:
//
//
class apb_seq extends uvm_sequence #(apb_seq_item);

// UVM Factory Registration Macro
//
`uvm_object_utils(apb_seq)

//------------------------------------------
// Data Members (Outputs rand, inputs non-rand)
//------------------------------------------


//------------------------------------------
// Constraints
//------------------------------------------



//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "apb_seq");
extern task body;

endclass:apb_seq

function apb_seq::new(string name = "apb_seq");
  super.new(name);
endfunction

task apb_seq::body;
  apb_seq_item req;

  begin
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize());
    finish_item(req);
  end

endtask:body

`endif // APB_SEQ