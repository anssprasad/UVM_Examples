//------------------------------------------------------------
//   Copyright 2010 Mentor Graphics Corporation
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

`ifndef MII_CONFIG
`define MII_CONFIG

// configuration container class
class mii_config extends uvm_object;
  `uvm_object_utils( mii_config );

  virtual mii_if v_miim_if; // virtual mii_if


  function new( string name = "" );
    super.new( name );
  endfunction

  static function mii_config get_config( uvm_component c );
    mii_config t;
     
     if (!uvm_config_db#(mii_config)::get(c, "", "mii_config", t) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration mii_config from uvm_config_db. Have you set() it?")
     
    return t;
  endfunction
endclass

`endif
