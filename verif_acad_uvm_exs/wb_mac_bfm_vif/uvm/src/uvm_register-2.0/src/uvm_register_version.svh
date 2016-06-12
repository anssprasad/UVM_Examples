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

// Revision number.

`ifndef UVM_REGISTER_VERSION_SVH
`define UVM_REGISTER_VERSION_SVH

string uvm_register_name = "UVM Register Package";
int    uvm_register_major_rev = 2;
int    uvm_register_minor_rev = 0;
int    uvm_register_fix_rev = 0;
string uvm_register_mgc_copyright = "(C) 2007-2010 Mentor Graphics Corporation";

function string uvm_register_revision_string();
  string s;
  if(uvm_register_fix_rev <= 0)
    $sformat(s, "%s Version %1d.%1d", 
      uvm_register_name, 
      uvm_register_major_rev, 
      uvm_register_minor_rev);
  else
    $sformat(s, "%s Version %1d.%1d.%0d", 
      uvm_register_name, 
      uvm_register_major_rev, 
      uvm_register_minor_rev, 
      uvm_register_fix_rev);
`ifdef NCV
  // If either 
  //  1. running on INCA, or
  //  2. running on Questa in INCA "compat" mode.
  s = $psprintf("%s NCV", s);
`endif
  return s;
endfunction

static bit uvm_register_initialized = initialize();

function bit initialize();
  if (!uvm_register_initialized) begin
    $display("----------------------------------------------------------------");
    $display("%s", uvm_register_revision_string());
    $display("%s", uvm_register_mgc_copyright);
    $display("----------------------------------------------------------------");
  end
  return 1;
endfunction

`endif // UVM_REGISTER_VERSION_SVH
