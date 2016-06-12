// $Id: //dvt/vtech/dev/main/uvm/src/base/uvm_registry.svh#17 $
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS: uvm_named_object_registry #(T,Tname)
//
// The uvm_named_object_registry serves as a lightweight proxy for a
// named_object of
// type ~T~ and type name ~Tname~, a string. The proxy enables efficient
// registration with the <uvm_factory>. Without it, registration would
// require an instance of the named_object itself.
//
// See Usage section below for information on using uvm_named_object_registry.
//
//------------------------------------------------------------------------------


class uvm_named_object_registry #(type T=uvm_named_object, string Tname="<unknown>")
                                           extends uvm_object_wrapper;
  typedef uvm_named_object_registry #(T,Tname) this_type;


  // Function: create_named_object
  //
  // Creates a named_object of type T having the provided ~name~ and ~parent~.
  // This is an override of the method in <uvm_object_wrapper>. It is
  // called by the factory after determining the type of object to create.
  // You should not call this method directly. Call <create> instead.

  virtual function uvm_named_object 
    create_named_object (string name, uvm_named_object parent = null);
    T obj = new(name, parent);
    return obj;
  endfunction

  // Function: create_object
  //
  // Creates an object of type ~T~ and returns it as a handle to an
  // <uvm_object>. This is an override of the method in <uvm_object_wrapper>.
  // It is called by the factory after determining the type of object to create.
  // You should not call this method directly. Call <create> instead.

  // Need this for the factory interface.
  virtual function uvm_object create_object(string name="");
    return create_named_object(name);
  endfunction

  const static string type_name = Tname;

  // Function: get_type_name
  //
  // Returns the value given by the string parameter, ~Tname~. This method
  // overrides the method in <uvm_object_wrapper>.

  virtual function string get_type_name();
    return type_name;
  endfunction

  local static this_type me = get();


  // Function: get
  //
  // Returns the singleton instance of this type. Type-based factory operation
  // depends on there being a single proxy instance for each registered type. 

  static function this_type get();
    if (me == null) begin
      uvm_factory f = uvm_factory::get();
      me = new;
      f.register(me);
    end
    return me;
  endfunction


  // Function: create
  //
  // Returns an instance of the named_object type, ~T~, represented by this proxy,
  // subject to any factory overrides based on the context provided by the
  // ~parent~'s full name. The ~contxt~ argument, if supplied, supercedes the
  // ~parent~'s context. The new instance will have the given leaf ~name~
  // and ~parent~.

  static function T create(string name, uvm_named_object parent, string contxt="");
    uvm_object obj;
    T item;
    uvm_factory f = uvm_factory::get();
    if (contxt == "" && parent != null)
      contxt = parent.get_full_name();

    // Should really be something like:
    //   obj = f.create_named_object_by_type(get(),contxt,name,parent);
    // but the factory doens't know about named_objects.
    obj = f.create_object_by_type(get(),contxt,name);
    if (!$cast(item, obj)) begin
      string msg;
      msg = {"Factory did not return a named_object of type '",type_name,
        "'. A named_object of type '",obj == null ? "null" : obj.get_type_name(),
        "' was returned instead. Name=",name," Parent=",
        parent==null?"null":parent.get_type_name()," contxt=",contxt};
      uvm_report_fatal("FCTTYP", msg);
    end

	if (parent != null) begin
      // The parent/child relationship was necessarily set already.
      // We know right now that that relationship was an expeditious
      // setting (read: wrong). Now we can correct it by calling
      // 'move_child'. This is like 'add_child', but assumes you really
      // want to move, and so ignores certain checks.
      void'(parent.m_move_child(item));
	end

    return item;
  endfunction


  // Function: set_type_override
  //
  // Configures the factory to create an object of the type represented by
  // ~override_type~ whenever a request is made to create an object of the type,
  // ~T~, represented by this proxy, provided no instance override applies. The
  // original type, ~T~, is typically a super class of the override type. 

  static function void set_type_override (uvm_object_wrapper override_type,
                                          bit replace=1);
    factory.set_type_override_by_type(get(),override_type,replace);
  endfunction


  // Function: set_inst_override
  //
  // Configures the factory to create a named_object of the type represented by
  // ~override_type~ whenever a request is made to create an object of the type,
  // ~T~, represented by this proxy,  with matching instance paths. The original
  // type, ~T~, is typically a super class of the override type.
  //
  // If ~parent~ is not specified, ~inst_path~ is interpreted as an absolute
  // instance path, which enables instance overrides to be set from outside
  // named_object classes. If ~parent~ is specified, ~inst_path~ is interpreted
  // as being relative to the ~parent~'s hierarchical instance path, i.e.
  // ~{parent.get_full_name(),".",inst_path}~ is the instance path that is
  // registered with the override. The ~inst_path~ may contain wildcards for
  // matching against multiple contexts.

  static function void set_inst_override(uvm_object_wrapper override_type,
                                         string inst_path,
                                         uvm_named_object parent=null);
    string full_inst_path;
    if (parent != null) begin
      if (inst_path == "")
        inst_path = parent.get_full_name();
      else
        inst_path = {parent.get_full_name(),".",inst_path};
    end
    factory.set_inst_override_by_type(get(),override_type,inst_path);
  endfunction

endclass
