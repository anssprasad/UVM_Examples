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

// TITLE: UVM Register Macros 
//
// These macros (uvm_register_begin_fields, 
// uvm_register_field, uvm_register_end_fields) 
// form a collection and are used as
//
//|  `uvm_register_begin_fields(TYPE)
//|    `uvm_register_field(field_name1)
//|    `uvm_register_field(field_name2)
//|    `uvm_register_field(field_name3)
//|  `uvm_register_end_fields
// 
//
// MACRO: `uvm_register_begin_fields
//
// `uvm_register_begin_fields is used to start the
// definition of the field access engine.
//
// MACRO: `uvm_register_end_fields
//
// `uvm_register_end_fields is used to end the 
// definition of the field access engine.
//
// MACRO: `uvm_register_field(FIELD_NAME)
// This macro takes one argument, the field name - not
// as a string, just the field name:
//
// | `uvm_register_field(f1)
// | `uvm_register_field(f2)
// | `uvm_register_field(f3)
//

// Preserve this indentation to make the generated
// code as readable as possible.

`define uvm_register_begin_fields \
\
function BV m_register_field_by_name( \
UVM_REGISTER_FIELD_ACCESS_T cmd, \
  string name, BV x, BV v = 0); \
       T m_x = x; \
       case (name) \

`define uvm_register_field(FIELD_NAME) \
\
  `"FIELD_NAME`": case (cmd) \
  UVM_REGISTER_FIELD_SET_BY_NAME: begin \
            m_x.FIELD_NAME = v; \
            return m_x; \
          end \
          UVM_REGISTER_FIELD_GET_BY_NAME: begin \
            return m_x.FIELD_NAME; \
          end \
          default: begin \
            uvm_report_error("m_register_field_by_name", \
$psprintf("Command '%s' not implemented.", cmd)); \
          end \
         endcase \

`define uvm_register_no_field(FIELD_NAME) \
\
  `"FIELD_NAME`": case (cmd) \
  UVM_REGISTER_FIELD_SET_BY_NAME: begin \
            m_x = v; \
            return m_x; \
          end \
          UVM_REGISTER_FIELD_GET_BY_NAME: begin \
            return m_x; \
          end \
          default: begin \
            uvm_report_error("m_register_field_by_name", \
$psprintf("Command '%s' not implemented.", cmd)); \
          end \
         endcase \

`define uvm_register_enum_field(FIELD_NAME, TYPE_NAME) \
\
  `"FIELD_NAME`": case (cmd) \
  UVM_REGISTER_FIELD_SET_BY_NAME: begin \
            m_x.FIELD_NAME = TYPE_NAME'(v); \
            return m_x; \
          end \
          UVM_REGISTER_FIELD_GET_BY_NAME: begin \
            return m_x.FIELD_NAME; \
          end \
          default: begin \
            uvm_report_error("m_register_field_by_name", \
$psprintf("Command '%s' not implemented.", cmd)); \
          end \
         endcase \

`define uvm_register_end_fields \
\
  default: begin \
    uvm_report_error("m_register_field_by_name",  \
$psprintf("Field '%s' not known in register %s", \
name, get_full_name())); \
  end \
endcase \
endfunction \

//
// These macros really belong in their own file, but
// there are only two, so they're in here.
//
`define xxxx_UVM_REGISTER_NOTIFY(SFX) \
  class uvm_register_notify``SFX \
     #(type T=int, type IMP=int) \
      extends uvm_port_base #(uvm_tlm_if_base#(T,T)); \
    IMP m_imp; \
    function new(string name, IMP imp); \
                   /* null! de-componentification! */ \
      super.new(name, null, UVM_IMPLEMENTATION, 1, 1); \
      m_if_mask = `UVM_TLM_ANALYSIS_MASK; \
      m_imp = imp; \
    endfunction \
    function void write(input T t); \
      m_imp.write``SFX(t); \
    endfunction \
  endclass

`define UVM_REGISTER_NOTIFY(SFX) \
  class uvm_register_notify``SFX \
     #(type T=int, type IMP=int) \
      extends uvm_analysis_imp_nc #(T, IMP); \
    function new(string name, IMP imp); \
      super.new(name, imp); \
    endfunction \
    function void write(input T t); \
      m_imp.write``SFX(t); \
    endfunction \
  endclass

`define USE_NOTIFY(SFX, IMP) \
    uvm_register_notify``SFX \
      #(this_type, IMP) analysis_export``SFX;

`define USE_GENERIC_NOTIFY(SFX, IMP) \
    uvm_register_notify``SFX \
      #(uvm_register_base, IMP) analysis_export``SFX;

`define uvm_named_object_registry(T,S) \
   typedef uvm_named_object_registry #(T,S) type_id; \
   static function type_id get_type(); \
     return type_id::get(); \
   endfunction

`define uvm_named_object_registry_internal(T,S) \
   typedef uvm_named_object_registry #(T,`"S`") type_id; \
   static function type_id get_type(); \
     return type_id::get(); \
   endfunction

`define uvm_named_object_utils(T) \
  `uvm_named_object_utils_begin(T) \
  `uvm_named_object_utils_end

`define uvm_named_object_param_utils(T) \
  `uvm_named_object_param_utils_begin(T) \
  `uvm_named_object_utils_end

`define uvm_named_object_utils_begin(T) \
   `uvm_named_object_registry_internal(T,T) \
   `uvm_get_type_name_func(T) \

`define uvm_named_object_param_utils_begin(T) \
   `uvm_named_object_registry_param(T) \

`define uvm_named_object_utils_end \

`define add_field_rw( field, rv) \
  RMASK.field = '1; \
  WMASK.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "RW");

`define add_enum_field_rw( field, rv, T) \
  RMASK.field = T'('1); \
  WMASK.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "RW");

`define add_field_ro( field, rv) \
  RMASK.field = '1; \
  WMASK.field = '0; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "RO");

`define add_enum_field_ro( field, rv, T) \
  RMASK.field = T'('1); \
  WMASK.field = T'('0); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "RO");

`define add_field_wo( field, rv) \
  RMASK.field = '0; \
  WMASK.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "WO");

`define add_enum_field_wo( field, rv, T) \
  RMASK.field = T'('0); \
  WMASK.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "WO");

`define add_field_w1clr( field, rv) \
  W1CLRMASK.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "W1C");

`define add_enum_field_w1clr( field, rv, T) \
  W1CLRMASK.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "W1C");

`define add_field_w0set( field, rv) \
  W0SETMASK.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "W0S");

`define add_enum_field_w0set( field, rv, T) \
  W0SETMASK.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "W0S");

`define add_field_clronread( field, rv) \
  CLRONREAD.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "R2C");

`define add_enum_field_clronread( field, rv, T) \
  CLRONREAD.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "R2C");

`define add_field_setonread( field, rv) \
  SETONREADMASK.field = '1; \
  resetValue.field = rv; \
  add_field(`"field`", rv, "R2S");

`define add_enum_field_setonread( field, rv, T) \
  SETONREADMASK.field = T'('1); \
  resetValue.field = T'(rv); \
  add_field(`"field`", rv, "R2S");

