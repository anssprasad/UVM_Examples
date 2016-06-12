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
`ifndef APB_MONITOR
`define APB_MONITOR

//
// Class Description:
//
//
class apb_monitor extends uvm_component;

// UVM Factory Registration Macro
//
`uvm_component_utils(apb_monitor);

// Virtual Interface
virtual apb_monitor_bfm BFM;

//------------------------------------------
// Data Members
//------------------------------------------
int apb_index = 0; // Which PSEL line is this monitor connected to
protected apb_seq_item item;

//------------------------------------------
// Component Members
//------------------------------------------
uvm_analysis_port #(apb_seq_item) ap;

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:

extern function new(string name = "apb_monitor", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern function void end_of_elaboration_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern function void report_phase(uvm_phase phase);

extern function void write(apb_seq_item_s item_s);

endclass: apb_monitor

function apb_monitor::new(string name = "apb_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void apb_monitor::build_phase(uvm_phase phase);
  ap = new("ap", this);
  item = apb_seq_item::type_id::create("item");
endfunction: build_phase

function void apb_monitor::end_of_elaboration_phase(uvm_phase phase);
  BFM.proxy = this;
endfunction: end_of_elaboration_phase

task apb_monitor::run_phase(uvm_phase phase);
  BFM.run(apb_index);
endtask: run_phase

function void apb_monitor::write(apb_seq_item_s item_s);
  apb_seq_item item;

  apb_seq_item_converter::to_class(item, item_s);
  this.item.copy(item);
  ap.write(this.item);
endfunction: write

function void apb_monitor::report_phase(uvm_phase phase);
// Might be a good place to do some reporting on no of analysis transactions sent etc

endfunction: report_phase

`endif // APB_MONITOR
