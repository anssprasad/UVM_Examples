//------------------------------------------------------------------------------
//   Copyright 2010 Mentor Graphics Corporation
//
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

package uvm_container_pkg;

import uvm_pkg::*;

localparam string s_no_container_config_id = "no container";
localparam string s_container_config_type_error_id = "container config type error";

//
// Class: uvm_container
//
// This is a general purpose container. Its primary purpose is to wrap virtual
// interfaces in an uvm_object so that they can be stored and extracted from the 
// uvm configuration mechanism. It can also be used for built in types such as 
// ints, bits, etc. Doing so will avoid using up 4048 bytes in set and get_config_int
// methods.
//

class uvm_container #( type T = int ) extends uvm_object;
  typedef uvm_container #( T ) this_t;

  //
  // Variable: t
  // 
  // The data being wrapped
  //

  T t;

  //
  // Function:  set_value_in_global_config
  //
  // This static method creates a container, stores t in the container, and
  // then stores the container in the global config space using the string
  // config_id.
  //
  // Although the config_id is, well, a config id, in the case of virtual
  // interfaces it is best interpreted as an elaboration or user defined
  // scope name which makes the virtual interface t unique within the 
  // system.
  //
  // Typical usage is :
  //
  // string scope = "%m";
  // uvm_container #( axi_if )::set_value_in_global_config( scope , m_if );
  // 
  // or simply:
  //  uvm_container #( axi_if )::set_value_in_global_config( "AXI_PORT_1" , m_if );
  //
  static function void set_value_in_global_config( string config_id , T t );
    this_t container = new();

    uvm_report_info( config_id , "Setting Container" );
    
    container.t = t;
    set_config_object("*" , config_id , container , 0 );
  endfunction

  //
  // Function: get_value_from_config
  //
  // This static method gets the uvm_container associated with the config_id using
  // the local config in component c. If set_value_in_global_config has been used
  // then the component c is in fact irrelevant since the value will be the same
  // anywhere in the UVM component hierarchy. But passing a value for the component
  // allows the theoretical possibiliy that different values are present at different
  // places in the UVM hierarchy for the same config_id.
  //
  static function T get_value_from_config( uvm_component c , string config_id );
    uvm_object o;
	uvm_container #(T) tmp;
	
	assert (c.get_config_object (config_id, o, 0)) 
	  else c.uvm_report_error ( s_no_container_config_id ,
                                    $psprintf( "component has no uvm_container associated with %s" , config_id ) );

	assert ($cast (tmp, o))
	  else c.uvm_report_error ( s_container_config_type_error_id ,
                                    $psprintf( "object associated with %s is not of the correct type" , config_id) );

	
	return tmp.t;
  endfunction 

endclass

endpackage
