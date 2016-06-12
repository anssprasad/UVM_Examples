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

// UVM Utilities Package

// DEPRECATED. 12/22/2008
// This package name is deprecated.
// Please use 'uvm_register_pkg' instead.
package uvm_utils_pkg;

  import uvm_pkg::*;

  `include "uvm_register_version.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

`ifndef USING_UVM_1
  `include "uvm_macros.svh"

  `include "uvm_register_transaction_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_agent_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_sequences_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_env_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_auto_test.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
`endif

endpackage : uvm_utils_pkg;
