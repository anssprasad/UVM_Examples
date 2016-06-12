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

`ifndef WB_TXN
`define WB_TXN

//----------------------------------------------
  // Wishbone transaction types enumeration
  //typedef enum  {NONE, WRITE, READ, RMW, WAIT_IRQ } wb_txn_t;

class wb_txn extends uvm_sequence_item;
  rand logic [31:0] adr;
  rand logic [31:0] data [];
  wb_txn_t txn_type;
  //wishbone is byte addressable up to 64 bits wide
  // the bits of byte sel are mapped to the 8 possible byte of data
  // and tell which are valid for the transaction
  bit [7:0] byte_sel;
  rand int count;  // number of writes or reads per transaction


  function new(string name = "wb_txn");
   super.new(name);
   set_byte_sel(); // set byte_sel for the wishbone transaction
   data = new[1]; //init with default size of 1
  endfunction
 
  `uvm_object_utils_begin(wb_txn)
    `uvm_field_enum(wb_txn_t, txn_type, UVM_ALL_ON)
    `uvm_field_int(adr,  UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_int(count, UVM_ALL_ON)
    `uvm_field_int(byte_sel, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function void init_txn(wb_txn_t l_txn_type = NONE,
                        logic [31:0] l_adr = 'x,
                        logic [31:0] l_data[],
                        int cnt = 1
                       );
    txn_type = l_txn_type;
    count = cnt;
    adr  = l_adr;
    data = l_data;
  endfunction
  
  function void set_byte_sel();
  //function sets the byte select bits
    for (int i = 0; i<4; i++)begin
        byte_sel = byte_sel << 1;
        byte_sel++;
    end
  endfunction
  
  function string convert2string();
    string str1;
    
    str1 = {    "-------------------- Start WISHBONE txn --------------------\n",
                "WISHBONE txn \n",
      $sformatf("  txn_type : %s\n", txn_type.name()),
      $sformatf("  adr      : 'h%h\n", adr),
      $sformatf("  count    : 'h%h\n", count),
      $sformatf("  byte_sel : 'h%h\n", byte_sel)};
      if(data.size() < 10)
        foreach(data[i])
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
      else begin
        for(int i = 0; i<5; i++)
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
         str1 = {str1, "    ...\n"};
        for(int i = data.size()-5; i<data.size(); i++)
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
      end   
    str1 = {str1, "--------------------- End WISHBONE txn ---------------------\n"};
    return(str1);
  endfunction
    
      
endclass

`endif
