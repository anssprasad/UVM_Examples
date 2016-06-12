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
`ifndef APB_DRIVER
`define APB_DRIVER

//
// Class Description:
//
//
class apb_driver extends uvm_driver #(apb_seq_item, apb_seq_item);

// UVM Factory Registration Macro
//
`uvm_component_utils(apb_driver)

// Virtual Interface
virtual apb_driver_bfm BFM;

//------------------------------------------
// Data Members
//------------------------------------------
apb_agent_config m_cfg;
//------------------------------------------
// Methods
//------------------------------------------
extern function int sel_lookup(logic[31:0] address);
// Standard UVM Methods:
extern function new(string name = "apb_driver", uvm_component parent = null);
extern task run_phase(uvm_phase phase);
extern function void build_phase(uvm_phase phase);


endclass: apb_driver

function apb_driver::new(string name = "apb_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

task apb_driver::run_phase(uvm_phase phase);
  apb_seq_item req;
  apb_seq_item rsp;
  int psel_index;

  forever
   begin
     apb_seq_item_s req_s, rsp_s;

     seq_item_port.get_next_item(req);
     psel_index = sel_lookup(req.addr);
     if(psel_index < 0) begin
       `uvm_error("RUN", $sformatf("Access to addr %0h out of APB address range", req.addr))
     end
     apb_seq_item_converter::from_class(req, req_s);
     BFM.do_item(req_s, psel_index, rsp_s); 
     apb_seq_item_converter::to_class(rsp, rsp_s);
     req.copy(rsp);
     seq_item_port.item_done();
     //#0;
     //#1; // Needed to hold the bus fields long enough for the monitor to get the info
   end

endtask: run_phase

function void apb_driver::build_phase(uvm_phase phase);
  m_cfg = apb_agent_config::get_config(this);
endfunction: build_phase

// Looks up the address and returns PSEL line that should be activated
// If the address is invalid, a non positive integer is returned to indicate an error
function int apb_driver::sel_lookup(logic[31:0] address);
  for(int i = 0; i < m_cfg.no_select_lines; i++) begin
    if((address >= m_cfg.start_address[i]) && (address <= (m_cfg.start_address[i] + m_cfg.range[i]))) begin
      return i;
    end
  end
  return -1; // Error: Address not found
endfunction: sel_lookup

`endif // APB_DRIVER
