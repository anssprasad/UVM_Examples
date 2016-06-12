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

// UVM Register Package


//
// Simulator Compatibility and SystemVerilog Language Support.
//
// Every simulator supports a slightly different subset of
// the SystemVerilog language. Certain compromises need to
// be made in order to have a common code base running on
// all simulators. Sometimes those compromises are
// permanent - meaning the coding style doesn't matter or
// the trade-offs on architecture are unimportant. These 
// permanent compromises become part of the code base.
// Other compromises are temporary. Compromises are temporary 
// because a new feature will soon be supported which
// enhances the architecture or the compromise would affect
// long term support or performance issues.
//
// An example of a temporary compromise is when a search
// is performed on a linked list instead of a "search tree".
// As long as the list is short it won't matter. When the list
// gets long it will matter. A linked list would only be
// used as a temporary compromise.
//

// INCA is defined on the IUS simulator. When running IUS
// always define "NCV", that way the compatibility layer is 
// turned on.
// When running on Questa, you can choose to either run in
// IUS compatibility mode or not. In general running in IUS
// compatibility mode is not recommended, since certain data
// are sub-optimal, and the overall memory footprint and 
// simulation performance will be less.
// When running on Questa to use IUS compatability mode do:
//
//    vlog ... +define+NCV ....
//
`ifdef INCA
`define NCV
`endif

package uvm_register_pkg;

`ifndef UVM_REGISTER_MAX_WIDTH
`define UVM_REGISTER_MAX_WIDTH 1024
`endif

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "uvm_register_dpi.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

  `include "uvm_named_object.sv"
  `include "uvm_named_object_registry.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

  `include "uvm_notification.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

  `include "uvm_register_version.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_misc.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology


`ifndef USING_UVM_1
  `include "uvm_register_transaction_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_agent_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_sequences_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_env_pkg.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_register_auto_test.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
`endif

  `include "uvm_id_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_modal_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_coherent_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_fifo_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_broadcast_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology
  `include "uvm_indirect_register.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

  `include "uvm_memory.svh" // -*- FIXME include of uvm file other than uvm_macros.svh detected, you should move to an import based methodology

endpackage : uvm_register_pkg
