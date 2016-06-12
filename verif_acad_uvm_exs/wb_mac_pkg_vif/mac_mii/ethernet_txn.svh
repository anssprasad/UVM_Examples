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

`ifndef ETHERNET_TXN
`define ETHERNET_TXN

//----------------------------------------------

class ethernet_txn  extends uvm_sequence_item;
  // preamble data to be sent - correct is 64'h0055_5555_5555_5555
//CRG  bit [(8*8)-1:0] preamble_data = 64'h0055_5555_5555_5555;  
//CRG  bit [3:0] preamble_len = 7; // length of preamble in bytes - max is 4'h8, correct is 4'h7 
  bit [(16*8)-1:0] preamble_data = 128'h5555_5555_5555_5555_5555_5555_5555_5555;  
  bit [3:0] preamble_len = 14; // length of preamble in bytes - max is 4'h8, correct is 4'h7 
  bit [7:0] sfd_data = 8'hD5 ; // SFD data to be sent - correct is 8'hD5
  rand bit [47:0] dest_addr;
  rand bit [47:0] srce_addr;
  rand bit [15:0] payload_size;
  rand logic [7:0] payload [];
  bit[31:0] crc;

  constraint srce_addr_single_mac { srce_addr[47:40] == 8'h00; };

  function new(string name = "ethernet_txn");
   super.new(name);
   payload = new[1]; //init with default size of 1
  endfunction
 
  `uvm_object_utils_begin(ethernet_txn)
    `uvm_field_int(preamble_data,  UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(preamble_len,  UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(sfd_data,  UVM_ALL_ON)
    `uvm_field_int(dest_addr,  UVM_ALL_ON)
    `uvm_field_int(srce_addr,  UVM_ALL_ON)
    `uvm_field_int(payload_size,  UVM_ALL_ON)
    `uvm_field_array_int(payload, UVM_ALL_ON)
    `uvm_field_int(crc,  UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end
      
  virtual function void init_txn(bit[47:0] dest, bit[47:0] srce,
                bit[15:0] len,    logic [7:0] data []
                );
    dest_addr = dest;
    srce_addr = srce;
    payload_size = len;
    payload = data;
  endfunction
    
endclass

`endif
