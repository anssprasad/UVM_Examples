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

virtual class register_adapter_base extends uvm_sequence #(register_seq_item);

`uvm_object_utils(register_adapter_base)

uvm_sequencer_base m_bus_sequencer;

function new(string name = "register_adapter_base");
  super.new(name);
endfunction

pure virtual task read(inout register_seq_item req);
pure virtual task write(register_seq_item req);

endclass: register_adapter_base
