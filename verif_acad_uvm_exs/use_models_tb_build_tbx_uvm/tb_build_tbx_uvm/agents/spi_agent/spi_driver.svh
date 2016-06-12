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
`ifndef SPI_DRIVER
`define SPI_DRIVER

//
// Class Description:
//
//
class spi_driver extends uvm_driver #(spi_seq_item, spi_seq_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(spi_driver)

// Virtual Interface
virtual spi_driver_bfm BFM;

//------------------------------------------
// Data Members
//------------------------------------------

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name = "spi_driver", uvm_component parent = null);
extern task run_phase(uvm_phase phase);

endclass: spi_driver

function spi_driver::new(string name = "spi_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

// This driver is really an SPI slave responder
task spi_driver::run_phase(uvm_phase phase);
  spi_seq_item req;
  spi_seq_item rsp;

  BFM.init();

  forever begin
    seq_item_port.get_next_item(req);
    `uvm_info("SPI_DRV_RUN:", $sformatf("Starting transmission: %0h RX_NEG State %b, no of bits %0d", req.spi_data, req.RX_NEG, req.no_bits), UVM_LOW)
    BFM.do_item(req.spi_data, req.no_bits, req.RX_NEG); 
    seq_item_port.item_done();
  end
endtask: run_phase

`endif // SPI_DRIVER
