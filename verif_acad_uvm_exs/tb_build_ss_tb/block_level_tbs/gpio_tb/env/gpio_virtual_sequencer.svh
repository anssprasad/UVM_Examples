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
//
// Class Description:
//
//
class gpio_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(gpio_virtual_sequencer)

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Sub Components
//------------------------------------------
// Handles assigned during env connect phase
gpio_sequencer gpi;
gpio_sequencer aux;
apb_sequencer apb;
//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "gpio_virtual_sequencer", uvm_component parent = null);

endclass: gpio_virtual_sequencer

function gpio_virtual_sequencer::new(string name = "gpio_virtual_sequencer", uvm_component parent = null);
  super.new(name, parent);
endfunction
