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

`ifndef ETHERNET_TXN_EXT
`define ETHERNET_TXN_EXT

//----------------------------------------------

class ethernet_txn_ext  extends ethernet_txn;
  int retry_error;

  function new(string name = "ethernet_txn_ext");
   super.new(name);
  endfunction
 
  `uvm_object_utils_begin(ethernet_txn_ext)
    `uvm_field_int(retry_error,  UVM_ALL_ON )
  `uvm_object_utils_end    

endclass

`endif
