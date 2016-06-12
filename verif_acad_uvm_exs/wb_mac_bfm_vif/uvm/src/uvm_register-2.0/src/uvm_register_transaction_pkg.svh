//------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
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

// TITLE: UVM Register Transactions
// Transaction definitions for register based transactions
// and bus independent transactions.

// Useful op codes, status and widths for use
//  with the automated register testing code.

  typedef enum bit{READ, WRITE}             op_code_t;
  typedef enum bit{FAIL = 0, PASS = 1}       status_t;
  typedef int unsigned                    dataWidth_t;
  typedef int unsigned                 addressWidth_t;
  
  parameter int MAX_ADDR = 1 << $bits(addressWidth_t); 

  // CLASS: uvm_register_transaction
  //
  // A utility register transaction.
  // It has an op_code, name and data, and might
  // be generated from function calls such as
  //
  //:   READ("register1", r_data)
  //:   WRITE("a.b.c.register2, 14)
  //
  //
  class uvm_register_transaction 
    extends uvm_sequence_item;
  
    // Variable: op
    // Operation on the bus - READ/WRITE
    rand op_code_t   op;

    // Variable: name
    // Name for the register 
    string           name;

    // Variable: data
    // Data for the transaction
    rand dataWidth_t data;

    status_t status;
  
    `uvm_object_utils_begin(uvm_register_transaction)
      `uvm_field_enum  (op_code_t, op,     UVM_ALL_ON)
      `uvm_field_string(           name,   UVM_ALL_ON)
      `uvm_field_int   (           data,   UVM_ALL_ON)
      `uvm_field_enum  (status_t,  status, UVM_ALL_ON)
    `uvm_object_utils_end

    function new();
      super.new();
    endfunction
    
    function void copy(uvm_register_transaction t);
      op = t.op;
      name = t.name;
      data = t.data;
      status = t.status;
    endfunction

    function void copy_req(uvm_register_transaction t);
      super.copy(t);
      copy(t);
    endfunction

    function uvm_object clone();
      uvm_register_transaction t;
      t = new();
      t.copy(this);
      return t;
    endfunction
   
    function string convert2string();
      string s;
      $sformat(s, 
`ifdef NCV
        "REGISTER_OPERATION( %s: %s = %x (status=%s))", 
`else
        "REGISTER_OPERATION(%6s: %s = %x (status=%s))", 
`endif
        op.name, name, data, status.name);
      return s;
    endfunction
  endclass

  // CLASS: bus_transaction
  //
  // Base-class used with the bus request and response.
  //
  class bus_transaction 
    extends uvm_sequence_item;
  
    // Variable: op
    // Operation on the bus - READ/WRITE
    rand op_code_t      op;

    // Variable: address
    // Address of this transaction
    rand addressWidth_t address;

    // Variable: data
    // Data for the transaction
    rand dataWidth_t    data;
  
    `uvm_object_utils_begin(bus_transaction)
      `uvm_field_enum(op_code_t, op,      UVM_ALL_ON)
      `uvm_field_int (           address, UVM_ALL_ON)
      `uvm_field_int (           data,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new();
      super.new();
    endfunction
  
    function void copy(bus_transaction t);
      op = t.op;
      address = t.address;
      data = t.data;
    endfunction
  
    function string convert2string();
      string s;
`ifdef NCV
      $sformat(s, "%s: address = %x, data = %x", 
`else
      $sformat(s, "%6s: address = %x, data = %x", 
`endif
        op.name, address, data);
      return s;
    endfunction
  endclass
  
  // CLASS: bus_request
  // 
  // Useful in the automated register testing.
  class bus_request 
    extends bus_transaction;
  
    `uvm_object_utils_begin(bus_request)
      `uvm_field_enum(op_code_t, op,      UVM_ALL_ON)
      `uvm_field_int (           address, UVM_ALL_ON)
      `uvm_field_int (           data,    UVM_ALL_ON)
    `uvm_object_utils_end

    function uvm_object clone();
      bus_request t = new();
      t.copy(this);
      return t;
    endfunction
  
    function void copy(bus_request t);
      super.copy(t);
    endfunction
  endclass
  
  // CLASS: bus_response
  // 
  // Useful in the automated register testing.
  class bus_response 
    extends bus_transaction;
  
    // Variable: status
    // Response status. Optional use.
    status_t status;
  
    `uvm_object_utils_begin(bus_response)
      `uvm_field_enum(op_code_t, op,      UVM_ALL_ON)
      `uvm_field_int (           address, UVM_ALL_ON)
      `uvm_field_int (           data,    UVM_ALL_ON)
      `uvm_field_enum(status_t,  status,  UVM_ALL_ON)
    `uvm_object_utils_end

    function uvm_object clone();
      bus_response t = new();
      t.copy(this);
      return t;
    endfunction
  
    function void copy(bus_response t);
      super.copy(t);
      status = t.status;
    endfunction
  
    function void copy_req(bus_request t);
      super.copy(t);
    endfunction
  
    function string convert2string();
      string s;
      $sformat(s, "%s, status = %s", 
        super.convert2string(), status.name);
      return s;
    endfunction
  endclass

