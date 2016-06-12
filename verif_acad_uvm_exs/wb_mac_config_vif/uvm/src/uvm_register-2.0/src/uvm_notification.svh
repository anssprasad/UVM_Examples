// $Id: //dvt/vtech/dev/main/uvm/src/base/uvm_named_object.sv#80 $
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
//-----------------------------------------------------------

// Notification with ap.write() needs a lightweight
// imp. It can be hung on another register, on a register
// file or register map. Or anywhere.
//
// You can just do:
//
// 1. Create the class with a special "suffix" (_x in this
//    example).
//
//    `UVM_REGISTER_NOTIFY(_x)
//
// 2. Connect the register ap to the notification place:
//
//      regA.write_ap.connect(
//        regB.analysis_export_x);
//      regA.generic_write_ap.connect(
//        regB.analysis_export_generic_x);
//
// 3. Now call ap.write()
//
//    When ap.write() is called, it will in turn call
//       regB.write_x() and regB.write_generic_x().
//

// The DECOMPONENTITIZED VERSION _nc -> no component
class uvm_analysis_imp_nc #(type T=int, type IMP=int)
  extends uvm_port_base #(uvm_tlm_if_base #(T,T));
    protected IMP m_imp;

    function new (string name, IMP imp);
`ifdef NOTDEF
      string long_name;
      if (imp == null)
        uvm_report_fatal("IMP_NC", "IMP is null");

      long_name = {imp.get_full_name(), ".", name};
      super.new (long_name, null, UVM_IMPLEMENTATION, 1, 1);
`endif
	  // Call to super.new() must be first.
      //super.new (name, imp, UVM_IMPLEMENTATION, 1, 1);
                    /* null! de-componentification! */
      super.new (name, null, UVM_IMPLEMENTATION, 1, 1);

      m_imp = imp;
      m_if_mask = `UVM_TLM_ANALYSIS_MASK;
    endfunction

    virtual function string get_type_name();
      return "uvm_analysis_imp";
    endfunction

  //function void write (input T t);
    // m_imp.write (t);
  //endfunction
endclass


`ifdef NOTDEF
class uvm_analysis_imp #(type T=int, type IMP=int)
  extends uvm_port_base #(uvm_tlm_if_base #(T,T));
    local IMP m_imp;

    function new (string name, IMP imp);
      super.new (name, imp, UVM_IMPLEMENTATION, 1, 1);
      m_imp = imp;
      m_if_mask = `UVM_TLM_ANALYSIS_MASK;
    endfunction       

    virtual function string get_type_name();
      return "uvm_analysis_imp";
    endfunction

  function void write (input T t);
    m_imp.write (t);
  endfunction
endclass
`endif

