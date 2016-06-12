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
class pss_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(pss_virtual_sequencer)

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Sub Components
//------------------------------------------
// Handles assigned during env connect phase
gpio_sequencer gpi;
spi_sequencer spi;
ahb_sequencer ahb;
//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "pss_virtual_sequencer", uvm_component parent = null);

endclass: pss_virtual_sequencer

function pss_virtual_sequencer::new(string name = "pss_virtual_sequencer", uvm_component parent = null);
  super.new(name, parent);
endfunction