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

`ifndef WB_READ_SEQ
`define WB_READ_SEQ

class wb_read_seq  extends uvm_sequence #(wb_txn,wb_txn);
  `uvm_object_utils(wb_read_seq)
  
  rand logic [31:0] address;
  rand logic [31:0] data [ ];
  rand int count;
  wb_txn req_txn, rsp_txn;
  
  function new(string name = "");
   super.new(name);
  endfunction
  
 task body();
   //create transaction
  assert($cast(req_txn,
               create_item(wb_txn::type_id::get(),m_sequencer, "req_txn")));     
  start_item(req_txn);  // tell sequencer ready to give an transaction
  // set transaction_id to parents transaction_id
  req_txn.set_transaction_id(this.get_transaction_id()); 
  req_txn.init_txn(READ, address, data, count); //initialize transaction
  finish_item(req_txn); // send transaction
  get_response(rsp_txn, req_txn.get_transaction_id()); //get driver rsp
  if( m_parent_sequence.get_use_response_handler() == 1) // custom handler?
   m_parent_sequence.response_handler(rsp_txn);  // Yes call custom handler
  else
   //write read result to parent sequences response queue
   m_parent_sequence.put_response(rsp_txn);  
  `uvm_info("READ_SEQ", $sformatf("rsp_txn: %s",rsp_txn.sprint(uvm_default_tree_printer)),
                  351   )
 endtask


  virtual function void init_seq(logic [31:0] addr = 'x,
                         int cnt = 1);
    address = addr;
    count = cnt;
    data= new[count];
  endfunction

  virtual function wb_txn get_response_result();
    return (rsp_txn);
  endfunction

endclass
`endif
