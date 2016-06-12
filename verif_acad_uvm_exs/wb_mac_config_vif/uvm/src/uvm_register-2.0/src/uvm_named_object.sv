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

//------------------------------------------------------------------------------
//
// CLASS: uvm_named_object
//
// The uvm_named_object class is the root base class for UVM components. In
// addition to the features inherited from <uvm_object> and <uvm_report_object>,
// uvm_named_object provides the following interfaces:
//
// Hierarchy - provides methods for searching and traversing the component
//     hierarchy.
//
// Configuration - provides methods for configuring component topology and other
//     parameters ahead of and during component construction.
//
// Phasing - defines a phased test flow that all components follow. Derived
//     components implement one or more of the predefined phase callback methods
//     to perform their function. During simulation, all components' callbacks
//     are executed in precise order. Phasing is controlled by uvm_top, the
//     singleton instance of <uvm_root>.
//
// Reporting - provides a convenience interface to the <uvm_report_handler>. All
//     messages, warnings, and errors are processed through this interface.
//
// Transaction recording - provides methods for recording the transactions
//     produced or consumed by the component to a transaction database (vendor
//     specific). 
//
// Factory - provides a convenience interface to the <uvm_factory>. The factory
//     is used to create new components and other objects based on type-wide and
//     instance-specific configuration.
//
// The uvm_named_object is automatically seeded during construction using UVM
// seeding, if enabled. All other objects must be manually reseeded, if
// appropriate. See <uvm_object::reseed> for more information.
//
//------------------------------------------------------------------------------

virtual class uvm_named_object extends uvm_object;

  // Function: new
  //
  // Creates a new component with the given leaf instance ~name~ and handle to
  // to its ~parent~.  If the component is a top-level component (i.e. it is
  // created in a static module or interface), ~parent~ should be null.
  //
  // The component will be inserted as a child of the ~parent~ object, if any.
  // If ~parent~ already has a child by the given ~name~, an error is produced.
  //
  // If ~parent~ is null, then the component will become a child of the
  // implicit top-level component, ~uvm_top~.
  //
  // All classes derived from uvm_named_object must call super.new(name,parent).

  extern function     new (string name="", uvm_named_object parent=null);

  //----------------------------------------------------------------------------
  // Group: Debug Section
  //----------------------------------------------------------------------------
  int enable_stop_interrupt;

  extern virtual function string convert2string();
  extern virtual function void print_tree(int depth = 0);


  //----------------------------------------------------------------------------
  // Group: Hierarchy Interface
  //----------------------------------------------------------------------------
  //
  // These methods provide user access to information about the component
  // hierarchy, i.e., topology.
  // 
  //----------------------------------------------------------------------------

  // Function: get_parent
  //
  // Returns a handle to this component's parent, or null if it has no parent.

  extern virtual function uvm_named_object get_parent ();


  // Function: get_full_name
  //
  // Returns the full hierarchical name of this object. The default
  // implementation concatenates the hierarchical name of the parent, if any,
  // with the leaf name of this object, as given by <uvm_object::get_name>. 

  extern virtual function string get_full_name ();


  // Function: get_child
  extern function uvm_named_object get_child (string name);

  // Function: get_next_child
  extern function int get_next_child (ref string name);

  // Function: get_first_child
  //
  // These methods are used to iterate through this component's children, if
  // any. For example, given a component with an object handle, ~comp~, the
  // following code calls <uvm_object::print> for each child:
  //
  //|    string name;
  //|    uvm_named_object child;
  //|    if (comp.get_first_child(name))
  //|      do begin
  //|        child = comp.get_child(name);
  //|        child.print();
  //|      end while (comp.get_next_child(name));

  extern function int get_first_child (ref string name);



  // Function: get_num_children
  //
  // Returns the number of this component's children. 

  extern function int get_num_children ();


  // Function: has_child
  //
  // Returns 1 if this component has a child with the given ~name~, 0 otherwise.

  extern function int has_child (string name);


  // Function: set_name
  //
  // Renames this component to ~name~ and recalculates all descendants'
  // full names.

  extern virtual function void set_name (string name);
  extern virtual function void remove_child(
    string name, uvm_named_object old_child);

  
  // Function: lookup
  //
  // Looks for a component with the given hierarchical ~name~ relative to this
  // component. If the given ~name~ is preceded with a '.' (dot), then the search
  // begins relative to the top level (absolute lookup). The handle of the
  // matching component is returned, else null. The name must not contain
  // wildcards.

  extern function uvm_named_object lookup (string name);


  //----------------------------------------------------------------------------
  // Group: Factory Interface
  //----------------------------------------------------------------------------
  //
  // The factory interface provides convenient access to a portion of UVM's
  // <uvm_factory> interface. For creating new objects and components, the
  // preferred method of accessing the factory is via the object or component
  // wrapper (see <uvm_named_object_registry #(T,Tname)> and
  // <uvm_object_registry #(T,Tname)>). The wrapper also provides functions
  // for setting type and instance overrides.
  //
  //----------------------------------------------------------------------------


  // Function: create_object
  //
  // A convenience function for <uvm_factory::create_object_by_name>,
  // this method calls upon the factory to create a new object
  // whose type corresponds to the preregistered type name,
  // ~requested_type_name~, and instance name, ~name~. This method is
  // equivalent to:
  //
  //|  factory.create_object_by_name(requested_type_name,
  //|                                get_full_name(), name);
  //
  // If the factory determines that a type or instance override exists, the
  // type of the object created may be different than the requested type.  See
  // <uvm_factory> for details on factory operation.

  extern function uvm_object create_object (string requested_type_name,
                                            string name="");


  // Function: set_type_override_by_type
  //
  // A convenience function for <uvm_factory::set_type_override_by_type>, this
  // method registers a factory override for components and objects created at
  // this level of hierarchy or below. This method is equivalent to:
  //
  //|  factory.set_type_override_by_type(original_type, override_type,replace);
  //
  // The ~relative_inst_path~ is relative to this component and may include
  // wildcards. The ~original_type~ represents the type that is being overridden.
  // In subsequent calls to <uvm_factory::create_object_by_type> or
  // <uvm_factory::create_named_object_by_type>, if the requested_type matches the
  // ~original_type~ and the instance paths match, the factory will produce
  // the ~override_type~. 
  //
  // The original and override type arguments are lightweight proxies to the
  // types they represent. See <set_inst_override_by_type> for information
  // on usage.

  extern static function void set_type_override_by_type
                                             (uvm_object_wrapper original_type, 
                                              uvm_object_wrapper override_type,
                                              bit replace=1);


  // Function: set_inst_override_by_type
  //
  // A convenience function for <uvm_factory::set_inst_override_by_type>, this
  // method registers a factory override for components and objects created at
  // this level of hierarchy or below. In typical usage, this method is
  // equivalent to:
  //
  //|  factory.set_inst_override_by_type({get_full_name(),".",
  //|                                     relative_inst_path},
  //|                                     original_type,
  //|                                     override_type);
  //
  // The ~relative_inst_path~ is relative to this component and may include
  // wildcards. The ~original_type~ represents the type that is being overridden.
  // In subsequent calls to <uvm_factory::ereate_object_by_type> or
  
  // <uvm_factory::create_named_object_by_type>, if the requested_type matches the
  // ~original_type~ and the instance paths match, the factory will produce the
  // ~override_type~. 
  //
  // The original and override types are lightweight proxies to the types they
  // represent. They can be obtained by calling type::get_type(), if
  // implemented, or by directly calling type::type_id::get(), where type is the
  // user type and type_id is the name of the typedef to
  // <uvm_object_registry #(T,Tname)> or <uvm_named_object_registry #(T,Tname)>.
  //
  // If you are employing the `uvm_*_utils macros, the typedef and the get_type
  // method will be implemented for you.
  //
  // The following example shows `uvm_*_utils usage:
  //
  //|  class comp extends uvm_named_object;
  //|    `uvm_named_object_utils(comp)
  //|    ...
  //|  endclass
  //|
  //|  class mycomp extends uvm_named_object;
  //|    `uvm_named_object_utils(mycomp)
  //|    ...
  //|  endclass
  //|
  //|  class block extends uvm_named_object;
  //|    `uvm_named_object_utils(block)
  //|    comp c_inst;
  //|    virtual function void build();
  //|      set_inst_override_by_type("c_inst",comp::get_type(),
  //|                                         mycomp::get_type());
  //|    endfunction
  //|    ...
  //|  endclass

  extern function void set_inst_override_by_type(string relative_inst_path,  
                                                 uvm_object_wrapper original_type,
                                                 uvm_object_wrapper override_type);


  // Function: set_type_override
  //
  // A convenience function for <uvm_factory::set_type_override_by_name>,
  // this method configures the factory to create an object of type
  // ~override_type_name~ whenever the factory is asked to produce a type
  // represented by ~original_type_name~.  This method is equivalent to:
  //
  //|  factory.set_type_override_by_name(original_type_name,
  //|                                    override_type_name, replace);
  //
  // The ~original_type_name~ typically refers to a preregistered type in the
  // factory. It may, however, be any arbitrary string. Subsequent calls to
  // create_named_object or create_object with the same string and matching
  // instance path will produce the type represented by override_type_name.
  // The ~override_type_name~ must refer to a preregistered type in the factory. 

  extern static function void set_type_override(string original_type_name, 
                                                string override_type_name,
                                                bit    replace=1);


  // Function: set_inst_override
  //
  // A convenience function for <uvm_factory::set_inst_override_by_type>, this
  // method registers a factory override for components created at this level
  // of hierarchy or below. In typical usage, this method is equivalent to:
  //
  //|  factory.set_inst_override_by_name({get_full_name(),".",
  //|                                     relative_inst_path},
  //|                                      original_type_name,
  //|                                     override_type_name);
  //
  // The ~relative_inst_path~ is relative to this component and may include
  // wildcards. The ~original_type_name~ typically refers to a preregistered type
  // in the factory. It may, however, be any arbitrary string. Subsequent calls
  // to create_named_object or create_object with the same string and matching
  // instance path will produce the type represented by ~override_type_name~.
  // The ~override_type_name~ must refer to a preregistered type in the factory. 

  extern function void set_inst_override(string relative_inst_path,  
                                         string original_type_name,
                                         string override_type_name);


  // Function: print_override_info
  //
  // This factory debug method performs the same lookup process as create_object
  // and create_named_object, but instead of creating an object, it prints
  // information about what type of object would be created given the
  // provided arguments.

  extern function void print_override_info(string requested_type_name,
                                           string name="");


  //----------------------------------------------------------------------------
  //                     PRIVATE or PSUEDO-PRIVATE members
  //                      *** Do not call directly ***
  //         Implementation and even existence are subject to change. 
  //----------------------------------------------------------------------------
  // Most local methods are prefixed with m_, indicating they are not
  // user-level methods. SystemVerilog does not support friend classes,
  // which forces some otherwise internal methods to be exposed (i.e. not
  // be protected via 'local' keyword). These methods are also prefixed
  // with m_ to indicate they are not intended for public use.
  //
  // Internal methods will not be documented, although their implementa-
  // tions are freely available via the open-source license.
  //----------------------------------------------------------------------------

  static int g_named_object_id = 1; // Start from 1, so
                                    // that 0 is not a legal
									// id.
  int        named_object_id;   // Unique ID 
                                //  for each call to new()

  string m_name;

  /*protected*/ uvm_named_object m_parent;
  bit print_enabled = 1; // Used in uvm_named_object_top. Normally always 1.
 uvm_named_object m_children[string]; // TODO: RICH was protected
  protected uvm_named_object m_children_by_handle[uvm_named_object];

  extern function bit m_add_child (uvm_named_object child, 
    bit move_child = 0);
  extern function bit m_move_child (uvm_named_object child);
  extern virtual function void m_set_full_name (); // TODO: RICH was local.

  extern local function void m_extract_name(string name ,
                                            output string leaf ,
                                            output string remainder );
  // overridden to disable
  extern virtual function uvm_object create (string name=""); 
  extern virtual function uvm_object clone  ();

  //----------------------------------------------------------------------------
  //                          DEPRECATED MEMBERS
  //                      *** Do not use in new code ***
  //                  Convert existing code when appropriate.
  //----------------------------------------------------------------------------

  extern virtual function  void  post_new ();

  extern static  function uvm_named_object find_component   (string comp_match);
  extern static  function void          find_components  (string comp_match, 
                                                    ref uvm_named_object comps[$]);
  extern static  function uvm_named_object get_component    (int ele);
  extern static  function int           get_num_components ();

endclass : uvm_named_object

////////////////////////////////////////////////////////////

class uvm_named_object_root extends uvm_named_object;
  static local uvm_named_object_root m_inst;

  function new();
    super.new("__top__", null);
`ifdef NOTDEF
    begin
      uvm_root_report_handler rh = new();
      set_report_hander(rh);
    end
`endif
  endfunction

  static function uvm_named_object_root get();
    if (m_inst == null)
      m_inst = new();
    return m_inst;
  endfunction

//------------------------------------------------------------------------------
// Component Search & Printing
//------------------------------------------------------------------------------


  // Function: find_all
  //
  // Returns the component handle (find) or list of components handles
  // (find_all) matching a given string. The string may contain the wildcards,
  // * and ?. Strings beginning with '.' are absolute path names. If optional
  // comp arg is provided, then search begins from that component down
  // (default=all components).

  function void find_all(string comp_match, ref uvm_named_object comps[$],
                                   input uvm_named_object comp=null); 
    string name;
`ifdef INCA
  static uvm_named_object tmp[$]; //static list to work around ius 6.2 limitation
  static bit s_is_child;  //starts at 0 for the root call
         bit is_child;    //automatic variable gets updated immediately on entry
  is_child = s_is_child;
`endif

  if (comp==null)
    comp = this;

  if (comp.get_first_child(name))
    do begin
      `ifdef INCA
        //Indicate that a recursive call is being made. Using a static variable
        //since this is a temp workaround and we don't want to effect the
        //function prototype.
        s_is_child = 1;
        this.find_all(comp_match,tmp,comp.get_child(name));
        s_is_child = 0;  //reset for a future call.
        //Only copy to the component list if this is the top of the stack,
        //otherwise an infinite loop will result copying tmp to itself.
        if(is_child==0)
          while(tmp.size()) comps.push_back(tmp.pop_front());
      `else
        this.find_all(comp_match,comps,comp.get_child(name));
      `endif
    end
    while (comp.get_next_child(name));

  if (uvm_is_match(comp_match, comp.get_full_name()) &&
       comp.get_name() != "") /* uvm_top */
    comps.push_back(comp);

endfunction


// find
// ----

function uvm_named_object find (string comp_match);
  `ifdef INCA
    static uvm_named_object comp_list[$];
    comp_list.delete();
  `else
    uvm_named_object comp_list[$];
  `endif

  find_all(comp_match,comp_list);

  if (comp_list.size() > 1)
    uvm_top.uvm_report_warning("MMATCH",
    $psprintf("Found %0d components matching '%s'. Returning first match, %0s.",
              comp_list.size(),comp_match,comp_list[0].get_full_name()));

  if (comp_list.size() == 0) begin
    uvm_top.uvm_report_warning("CMPNFD",
      {"Component matching '",comp_match,
       "' was not found in the list of uvm_named_objects"});
    return null;
  end

  return comp_list[0];
endfunction


// print_topology
// --------------

function void print_topology(uvm_printer printer=null);

  string s;

  uvm_top.uvm_report_info("UVMTOP", "UVM testbench topology:");

  if (m_children.num()==0) begin
    uvm_top.uvm_report_warning("EMTCOMP", "print_topology - No UVM components to print.");
    return;
  end

  if (printer==null)
    printer = uvm_default_printer;

  if (printer.knobs.sprint)
    s = printer.m_string;

  foreach (m_children[c]) begin
    if(m_children[c].print_enabled) begin
      printer.print_object("", m_children[c]);  
      if(printer.knobs.sprint)
        s = {s, printer.m_string};
    end
  end

  printer.m_string = s;

endfunction

endclass

static uvm_named_object_root 
      uvm_named_object_top = uvm_named_object_root::get();

//-----------------------------------------------------------
//
// CLASS- uvm_named_object
//
//-----------------------------------------------------------

function string uvm_named_object::convert2string();
  return $psprintf("<%0d,'%s'>", named_object_id, get_full_name());
endfunction

// Prints lines like:
// #   - id=8 sw_register_map_0 
//         <8,'sw_register_map_0'>, 
//             parent=<null>
// #    - id=9 sw_register_map_0.sw1 
//         <9,'sw_register_map_0.sw1'>, 
//             parent=<8,'sw_register_map_0'>
// #      - id=11 sw_register_map_0.sw1.CSR '{value}, 
//             parent=<9,'sw_register_map_0.sw1'>
// #      - id=10 sw_register_map_0.sw1.VALUE 3, 
//             parent=<9,'sw_register_map_0.sw1'>
// #    - id=12 sw_register_map_0.sw2 
//         <12,'sw_register_map_0.sw2'>, 
//             parent=<8,'sw_register_map_0'>
// #      - id=14 sw_register_map_0.sw2.CSR '{value}, 
//             parent=<12,'sw_register_map_0.sw2'>
// #      - id=13 sw_register_map_0.sw2.VALUE 3, 
//             parent=<12,'sw_register_map_0.sw2'>
//
function void uvm_named_object::print_tree(int depth = 0);
  string s;
`ifdef NCV
  s = "";
  for(int i = 0; i < depth; i++)
    s = {s, " "};
`else
  s = {(depth>0?depth:1){" "}};
`endif
  $display("%s - id=%0d %s %s, parent=%s", 
    s, named_object_id, get_full_name(), 
    convert2string(),
    (m_parent!=null)?m_parent.convert2string():"<null>");
  foreach (m_children[i])
    m_children[i].print_tree(depth+2);
endfunction

// new
// ---

function uvm_named_object::new (
    string name="", uvm_named_object parent = null);
  string error_str;

  super.new(name);
  named_object_id = g_named_object_id++;

  // If uvm_named_object_top, reset name to "" so 
  // it doesn't show in full paths then return
  // This object IS the top.
  if (parent==null && name == "__top__") begin
    set_name("");
    return;
  end

  // Generate a name.
  if (name == "") begin
    name.itoa(m_inst_count);
    name = {"NOBJ_", name};
  end

  if (parent == null)
    m_parent = uvm_named_object_top;
  else 
    m_parent = parent;

  // Debug message.
  uvm_top.uvm_report_info("NEWCOMP",
    $psprintf("this=%0s, parent=%0s, name=%s",
      this.get_full_name(),
      m_parent.get_full_name(),name),UVM_MEDIUM+1);

  set_name(name);
  if (m_parent != null)
    void'(m_parent.m_add_child(this));

  // Now that inst name is established, reseed 
  //   (if use_uvm_seeding is set)
  reseed();
endfunction

function bit uvm_named_object::m_move_child(
    uvm_named_object child);
    return m_add_child(child, 1);
endfunction

// m_add_child
// -----------

function bit uvm_named_object::m_add_child(
    uvm_named_object child,
    bit move_child = 0);

  // Can't add an empty child.
  if(child == null) begin
    uvm_top.uvm_report_fatal("EMPTYCHILD", 
      "cannot add a child which is empty.");
  end

  /* DEBUG
    $display("DEBUG: <%s>.m_add_child(<%s>, move=%0d)", 
      this.convert2string(), 
      child.convert2string(), 
      move_child);
  */

  // Can't be the parent of yourself.
  if(child == this) begin
    uvm_top.uvm_report_fatal("THISPARENT", 
      "cannot set the parent of a component to itself");
  end

  // Set or reset the parent pointer.
  if (this == uvm_named_object_top) begin
    // OK. We are adding something to the top.
  end 
  else if (child.m_parent == this) begin
    // The parent of this child is already this object.
    // Asking twice.
  end
  else if (child.m_parent != null) begin
    // This is the normal case. This is the case where the child
    // already has a parent.
  end
  else if (child.m_parent == uvm_named_object_top) begin
  end
  else if (child.m_parent == null) begin
  end
  else begin
    // Well, parent is NOT null.  That means it has a value. 
    // And the value is NOT the top, so
    // we're trying to "move" a child... error out.
    uvm_report_fatal("ADDCHILD", 
      $psprintf("Trying to move '%s' from '%s' to '%s' not allowed.",
        child.convert2string(),
        ((child.m_parent==null)?"__TOP__":child.m_parent.convert2string()),  // Old Parent
        this.convert2string()));          // New Parent
  end

  if ((child.m_parent!=null) && move_child) begin
    // Remove this 'child' object from ITS parent.
    child.m_parent.remove_child(child.get_name(), child);
  end

  if (!move_child) begin
    if (m_children.exists(child.get_name()) &&
      m_children[child.get_name()] != child) begin

     // When cloning, this check seems to get triggered.
     // Why didn't the previous item get removed?

      uvm_top.uvm_report_warning("BDCLD",
$psprintf(
"In '%s', a child with the name '%0s' (type=%0s) already exists in '%s'.",
         get_full_name(),
         child.get_name(), 
           m_children[child.get_name()].get_type_name(),
           this.get_full_name())
           );
      return 0;
    end

    if (m_children_by_handle.exists(child)) begin
      uvm_top.uvm_report_warning("BDCHLD", $psprintf(
"In parent '%s', a child with the name '%0s' %0s '%0s'",
                  get_full_name(),
                  child.get_name(),
                  "already exists in parent under name",
                  m_children_by_handle[child].get_name()));
      return 0;
    end
  end

  // The business end of this function.
  child.m_parent = this;

  // Do this after all other adjustments are made. This call
  // recursively rejiggers all the full names. Why are full names
  // not just dynamically created?
  // set_name() may change the name.
  child.set_name(child.get_name());

  m_children[child.get_name()] = child;
  m_children_by_handle[child] = child;
  return 1;
endfunction

//-----------------------------------------------------------
//
// Hierarchy Methods
// 
//-----------------------------------------------------------


// get_first_child
// ---------------

function int uvm_named_object::get_first_child(
    ref string name);
  return m_children.first(name);
endfunction


// get_next_child
// --------------

function int uvm_named_object::get_next_child(
    ref string name);
  return m_children.next(name);
endfunction


// get_child
// ---------

function uvm_named_object uvm_named_object::get_child(
    string name);
  return m_children[name];
endfunction


// has_child
// ---------

function int uvm_named_object::has_child(string name);
  return m_children.exists(name);
endfunction


// get_num_children
// ----------------

function int uvm_named_object::get_num_children();
  return m_children.num();
endfunction


// get_full_name
// -------------

function string uvm_named_object::get_full_name ();
  // Note- Implementation choice to construct full 
  //  name once since the full name may be used often 
  //  for lookups.
  if(m_name == "")
    return get_name();
  else
    return m_name;
endfunction


// get_parent
// ----------

function uvm_named_object uvm_named_object::get_parent ();
  return  m_parent;
endfunction


// set_name
// --------

function void uvm_named_object::set_name (string name);
  bit name_changing;
  string old_name;

  if ( name != get_name()) 
    name_changing = 1;
  else
    name_changing = 0;
  old_name = get_name();

  super.set_name(name);
  // Gee. I'm changing my name, I better tell my
  // parent to get rid of the old me.
  if (name_changing) begin
    if (m_parent!=null)
      m_parent.remove_child(old_name, this);
  end
  m_set_full_name();
endfunction

// Function: remove_child()
// Remove the child named 'name' from 'this'.
// This function cleans up the child management
// arrays in THIS object.
//
function void uvm_named_object::remove_child(
  string name, uvm_named_object old_child); // {

  /* DEBUG
    $display("DEBUG: <%s>.m_remove_child(<%s>, <%s>)", 
      this.convert2string(),
      name,
      old_child.convert2string()
      );
   */

  // Delete the child from the by_handle.
  // Get the child from the function argument.
  if (old_child != null) begin // {
    if (m_children_by_handle.exists(old_child)) begin // {
      m_children_by_handle.delete(old_child);
    end // }
  end // }

  if (old_child != null) begin // {
    old_child.m_parent = null;
  end // }

  // Delete the child from the by_handle.
  // Get the child object by name.
  if (m_children.exists(name)) begin // {
    uvm_named_object child = m_children[name];
    if (child != null) begin // {
      child.m_parent = null;
      if (m_children_by_handle.exists(child)) begin // {
        m_children_by_handle.delete(child);
      end // }
    end // }
  end // }

  // Delete the name from the by name list.
  // Do this last, since we use the m_children[name] above.
  if (m_children.exists(name)) begin // {
    m_children.delete(name);
  end // }

  // ---------------------------------------------------
  // Note: We don't care if we don't find it.
  //       If we don't find the name, then that means:
  //         1. Sloppy bookkeeping, or
  //         2. We just changed the name, and things 
  //            aren't quite right yet.
  // We called this function as a way to try to get 
  // things straightened out. Not to cause more problems.
  // ---------------------------------------------------
endfunction // }


// m_set_full_name
// ---------------

function void uvm_named_object::m_set_full_name();
  if (m_parent == uvm_named_object_top || m_parent==null)
    m_name = get_name();
  else 
    m_name = {m_parent.get_full_name(), ".", get_name()};

  foreach (m_children[c]) begin
    uvm_named_object tmp;
    tmp = m_children[c];
    tmp.m_set_full_name(); 
  end

endfunction


// lookup
// ------

function uvm_named_object uvm_named_object::lookup( 
    string name );

  string leaf , remainder;
  uvm_named_object comp;

  comp = this;
  
  m_extract_name(name, leaf, remainder);

  if (leaf == "") begin
    comp = uvm_named_object_top; // absolute lookup
    m_extract_name(remainder, leaf, remainder);
  end
  
  if (!comp.has_child(leaf)) begin
    uvm_top.uvm_report_warning("Lookup Error", 
       $psprintf("Cannot find child %0s",leaf));
    return null;
  end

  if( remainder != "" )
    return comp.m_children[leaf].lookup(remainder);

  return comp.m_children[leaf];

endfunction


// m_extract_name
// --------------

function void uvm_named_object::m_extract_name(
    input string name ,
   output string leaf ,
   output string remainder );
  int i , len;
  string extract_str;
  len = name.len();
  
  for( i = 0; i < name.len(); i++ ) begin  
    if( name[i] == "." ) begin
      break;
    end
  end

  if( i == len ) begin
    leaf = name;
    remainder = "";
    return;
  end

  leaf = name.substr( 0 , i - 1 );
  remainder = name.substr( i + 1 , len - 1 );

  return;
endfunction
  
//-----------------------------------------------------------
//
// Factory Methods
// 
//-----------------------------------------------------------

// create
// ------

function uvm_object  uvm_named_object::create (
    string name =""); 
  uvm_top.uvm_report_error("ILLCRT",
"create cannot be called on a uvm_named_object. Use create_named_object instead.");
  return null;
endfunction


// clone
// ------

function uvm_object  uvm_named_object::clone ();
  uvm_top.uvm_report_error("ILLCLN",
    "clone cannot be called on a uvm_named_object. ");
  return null;
endfunction


// print_override_info
// -------------------

function void  uvm_named_object::print_override_info (
  string requested_type_name, 
  string name="");
  factory.debug_create_by_name(
    requested_type_name, get_full_name(), name);
endfunction


// create_object
// -------------

function uvm_object uvm_named_object::create_object (
    string requested_type_name,
    string name="");
  return factory.create_object_by_name(requested_type_name,
                                       get_full_name(), name);
endfunction


// set_type_override (static)
// -----------------

function void uvm_named_object::set_type_override (
    string original_type_name,
    string override_type_name,
    bit    replace=1);
   factory.set_type_override_by_name(original_type_name,
                                     override_type_name, 
                                     replace);
endfunction 


// set_type_override_by_type (static)
// -------------------------

function void uvm_named_object::set_type_override_by_type (
  uvm_object_wrapper original_type,
  uvm_object_wrapper override_type,
  bit    replace=1);
   factory.set_type_override_by_type(
     original_type, override_type, replace);
endfunction 


// set_inst_override
// -----------------

function void  uvm_named_object::set_inst_override (
    string relative_inst_path,  
    string original_type_name,
    string override_type_name);
  string full_inst_path;

  if (relative_inst_path == "")
    full_inst_path = get_full_name();
  else
    full_inst_path = 
      {get_full_name(), ".", relative_inst_path};

  factory.set_inst_override_by_name(
                            original_type_name,
                            override_type_name,
                            full_inst_path);
endfunction 


// set_inst_override_by_type
// -------------------------

function void uvm_named_object::set_inst_override_by_type (
    string relative_inst_path,  
    uvm_object_wrapper original_type,
    uvm_object_wrapper override_type);
  string full_inst_path;

  if (relative_inst_path == "")
    full_inst_path = get_full_name();
  else
    full_inst_path = 
      {get_full_name(), ".", relative_inst_path};

  factory.set_inst_override_by_type(
    original_type, override_type, full_inst_path);

endfunction

//-----------------------------------------------------------
//
// DEPRECATED - DO NOT USE
//
//-----------------------------------------------------------


// post_new (deprecated)
// --------

function void uvm_named_object::post_new();
  return;
endfunction


// find_component (deprecated)
// --------------

function uvm_named_object uvm_named_object::find_component (
    string comp_match);
  static bit issued=0;
  if (!issued) begin
    issued=1;
    uvm_top.uvm_report_warning("deprecated",
{"uvm_named_object::find_component() is deprecated and replaced by ",
      "uvm_named_object_top.find()"});
  end
  return uvm_named_object_top.find(comp_match);
  return null;
endfunction


// find_components (deprecated)
// ---------------

function void uvm_named_object::find_components (
    string comp_match,
    ref uvm_named_object comps[$]);
  static bit issued=0;
  if (!issued) begin
    issued=1;
    uvm_top.uvm_report_warning("deprecated",
{"uvm_named_object::find_components() is deprecated and replaced by ",
      "uvm_named_object_top.find_all()"});
  end
  uvm_named_object_top.find_all(comp_match,comps);
endfunction


// get_component (deprecated)
// -------------

function uvm_named_object uvm_named_object::get_component (
    int ele);
  uvm_named_object m__comps[$];
  static bit issued=0;
  if (!issued) begin
    issued=1;
    uvm_top.uvm_report_warning("deprecated",
{"uvm_named_object::get_component() is an internal method that has been ",
"deprecated. uvm_named_object_top's find, find_all, and uvm_named_object's lookup ",
"method provide similar functionality."});
  end
  //RICH if (m__comps.size()==0)
    //RICH uvm_named_object_top.find_all("*",m__comps);
  if (ele < m__comps.size())
    return m__comps[ele];
  return null;
endfunction


// get_num_components (deprecated)
// ------------------

function int uvm_named_object::get_num_components ();
  uvm_named_object m__comps[$]; 
  static bit issued=0;
  if (!issued) begin
    issued=1;
    uvm_top.uvm_report_warning("deprecated",
{"uvm_named_object::get_num_components() is an internal method that has ",
"been deprecated. The number of components in the testbench can be ",
"obtained using the uvm_named_object_top.find_all() method."});
  end
  while (m__comps.size()!=0)
    m__comps.delete(0);
  uvm_named_object_top.find_all("*",m__comps);
  get_num_components = m__comps.size();
endfunction
