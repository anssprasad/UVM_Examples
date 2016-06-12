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

class uvm_broadcast_register #(type T = int) 
    extends uvm_register#(T);

  // List of all the registers which will be 
  // broadcast to - the "targets".
  //TODO: Can this be uvm_register_base once the
  //TODO:  base class contains write() and poke()?
  uvm_register #(T) targets[$];

  function new(string name, uvm_named_object p);
    super.new(name, p);
  endfunction

  // Function: add_target()
  // Add the register 'r' to the list of targets
  // managed by this broadcast register.
  virtual function void add_target(uvm_register #(T) r);
    targets.push_back(r);
  endfunction

  // Function: write()
  // Re-implement write() to forward all writes to
  // the managed targets. The value of this
  // "wrapper" register is NEVER updated.
  function void write(T v, T local_mask = '1);
    foreach (targets[i])
      targets[i].write(v, local_mask);
  endfunction

  // Function: poke()
  // Re-implement poke() to forward all pokes to
  // the managed targets. The value of this
  // "wrapper" register is NEVER updated.
  function void poke(T v);
    foreach (targets[i])
      targets[i].poke(v);
  endfunction
endclass
