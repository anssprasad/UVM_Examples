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

class register_seq_item extends uvm_sequence_item;

`uvm_object_utils(register_seq_item)

function new(string name = "register_seq_item");
  super.new(name);
endfunction

rand logic[31:0] address;
rand logic[31:0] data;
rand logic we;

// To do: implement do_xxx methods

endclass: register_seq_item
