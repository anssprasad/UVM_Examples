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

`ifndef WB_WRITE_SEQ
`define WB_WRITE_SEQ

class wb_write_seq extends uvm_sequence #(wb_txn,wb_txn);
 `uvm_object_utils(wb_write_seq)

 rand logic [31:0] address;
 rand logic [31:0] data [ ];
 rand int count;

 function new(string name = "");
  super.new(name);
 endfunction

 task body();
   wb_txn txn;
    //create transaction object
   assert($cast(txn,create_item(wb_txn::type_id::get(),m_sequencer, "txn")));     
   start_item(txn);  // tell sequencer ready to give a transaction item
   txn.init_txn(WRITE, address, data, count); //initialize transaction item
   finish_item(txn); // send transaction  
 endtask

 virtual function void init_seq(logic [31:0] addr = 'x,
                        logic [31:0] dat [],
                        int cnt = 1);
   address = addr;
   data = dat;
   count = cnt;
 endfunction
endclass
`endif
