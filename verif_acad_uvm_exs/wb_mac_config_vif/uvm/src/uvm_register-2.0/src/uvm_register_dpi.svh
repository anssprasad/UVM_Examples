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

// TITLE: UVM Register Backdoor SystemVerilog support routines.
// These routines provide an interface to the DPI/PLI
// implementation of backdoor access used by registers.
//
// Default is backward compatible -- NO DPI Backdoor.
// If you are not using backdoor access, there is nothing
// you need to do.
//
// If you want to use the DPI Backdoor API, then compile your
// SystemVerilog code with the vlog switch
//:   vlog ... +define+BACKDOOR_DPI ...
//
// If you DON'T want BACKDOOR_DPI, you don't have
//   to define anything.
//
// If you always want BACKDOOR_DPI, then in this file,
//  you can add a line like to avoid having to supply
//  the vlog compile-time switch. Uncomment the following
//  line to have BACKDOOR_DPI on by default.
//:    `define BACKDOOR_DPI
//

// The define BACKDOOR_DPI_OFF, allows you to turn OFF
//  the BACKDOOR_DPI define.
//  Use *+define+BACKDOOR_DPI_OFF* on the compile line
//  to make sure the C API is not called. This should
//  normally *not* be used.

`ifdef BACKDOOR_DPI_OFF
`undef BACKDOOR_DPI
`endif

/* 
 * VARIABLE: UVM_REGISTER_MAX_WIDTH
 * This parameter will be looked up by the 
 * DPI-C code using:
 *   vpi_handle_by_name(
 *     "uvm_register_pkg::UVM_REGISTER_MAX_WIDTH", 0);
 */
parameter int UVM_REGISTER_MAX_WIDTH = `UVM_REGISTER_MAX_WIDTH;

`ifdef BACKDOOR_DPI
  // Defining BACKDOOR_DPI means that a C implmentation will
  // be called. You MUST have a compiled DPI-C callable routine.

  // For one of the examples, you might compile the provided DPI-C
  // code on Windows as:
  //
  // c:/QuestaSim_6.5/gcc-4.2.1-mingw32/bin/gcc.exe \
  //   -shared -o backdoor.dll \
  //   -m32 \
  //   -Ic:/QuestaSim_6.5/include \
  //   ../../../src/uvm_register_dpi.c \
  //   -Lc:/QuestaSim_6.5/win32 -lmtipli
  //

  //
  // Function: uvm_register_check_hdl()
  // The path argument is looked up using vpi_get_handle().
  // If the path is found, return 1, otherwise return 0.
  //
  import "DPI-C" function int uvm_register_check_hdl(string path);

  //
  // Function: uvm_register_set_hdl()
  // This routine sets the value of a named path, using the PLI.
  // Lookup 'path', and assign value.
  //
  import "DPI-C" function void uvm_register_set_hdl(
    string path, logic[`UVM_REGISTER_MAX_WIDTH-1:0] value);

  //
  // Function: uvm_register_get_hdl()
  // This routine gets the value of a named path, using the PLI.
  // Lookup 'path' and return the value.
  //
  import "DPI-C" function void uvm_register_get_hdl(
    string path, output logic[`UVM_REGISTER_MAX_WIDTH-1:0] value);

`else
  function int uvm_register_check_hdl( string path);

    uvm_report_fatal("UVM_REGISTER_SET_HDL", 
      $psprintf("%m: Backdoor routines are compiled off. Recompile with +define+BACKDOOR_DPI"));
    return 0;
  endfunction

  function void uvm_register_set_hdl( 
    string path, logic[`UVM_REGISTER_MAX_WIDTH-1:0] value);

    uvm_report_fatal("UVM_REGISTER_SET_HDL", 
      $psprintf("%m: Backdoor routines are compiled off. Recompile with +define+BACKDOOR_DPI"));
  endfunction

  function void uvm_register_get_hdl( 
    string path, output logic[`UVM_REGISTER_MAX_WIDTH-1:0] value);

    uvm_report_error("UVM_REGISTER_GET_HDL", 
      $psprintf("%m: Backdoor routines are compiled off. Recompile with +define+BACKDOOR_DPI"));
  endfunction
`endif
