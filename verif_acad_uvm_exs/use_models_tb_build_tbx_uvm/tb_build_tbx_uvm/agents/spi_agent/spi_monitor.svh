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
`ifndef SPI_MONITOR
`define SPI_MONITOR

//
// Class Description:
//
//
class spi_monitor extends uvm_component;

// UVM Factory Registration Macro
//
`uvm_component_utils(spi_monitor);

// Virtual Interface
virtual spi_monitor_bfm BFM;

//------------------------------------------
// Data Members
//------------------------------------------
protected spi_seq_item item;

//------------------------------------------
// Component Members
//------------------------------------------
uvm_analysis_port #(spi_seq_item) ap;

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:

extern function new(string name = "spi_monitor", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern function void end_of_elaboration_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern function void report_phase(uvm_phase phase);

extern function void write(logic[127:0] nedge_mosi, pedge_mosi, nedge_miso, pedge_miso, logic[7:0] cs);

endclass: spi_monitor

function spi_monitor::new(string name = "spi_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void spi_monitor::build_phase(uvm_phase phase);
  ap = new("ap", this);
endfunction: build_phase

function void spi_monitor::end_of_elaboration_phase(uvm_phase phase);
  BFM.proxy = this;
endfunction: end_of_elaboration_phase

task spi_monitor::run_phase(uvm_phase phase);
  BFM.proxy = this;
  item = spi_seq_item::type_id::create("item");
  BFM.run();
endtask: run_phase

function void spi_monitor::write(logic[127:0] nedge_mosi, pedge_mosi, nedge_miso, pedge_miso, logic[7:0] cs);
  spi_seq_item cloned_item;

  item.nedge_mosi = nedge_mosi;
  item.pedge_mosi = pedge_mosi;
  item.nedge_miso = nedge_miso;
  item.pedge_miso = pedge_miso;
  item.cs = cs;
  // Clone and publish the cloned item to the subscribers
  $cast(cloned_item, item.clone());
  ap.write(cloned_item);
endfunction: write

function void spi_monitor::report_phase(uvm_phase phase);
// Might be a good place to do some reporting on no of analysis transactions sent etc

endfunction: report_phase

`endif // SPI_MONITOR
