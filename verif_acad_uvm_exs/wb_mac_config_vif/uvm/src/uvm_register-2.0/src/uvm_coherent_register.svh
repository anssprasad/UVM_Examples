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

// CLASS: uvm_coherent_register_slave
//
// A base class which implements the "slave" which will be
// kept "coherent". A "master" triggers, and then each 
// of the slaves that are managed by that master are 
// "snapshotted". The slave keeps a copy of the snapshot 
// for later retrieval.
//
class uvm_coherent_register_slave #(type T = int) 
    extends uvm_register #(T);
  T m_snapshot;

  function new(string name, uvm_named_object p);
    super.new(name, p);
  endfunction

  // Function: snapshot()
  // Calling this function causes a snapshot to be taken.
  virtual function void snapshot();
    poke_snapshot(super.peek());
  endfunction

  // Function: peek_snapshot()
  // This function returns the current snapshot value.
  virtual function T peek_snapshot();
    return m_snapshot; 
  endfunction

  // Function: poke_snapshot()
  // This function saves the value 'v' into the snapshot.
  virtual function void poke_snapshot(T v);
    m_snapshot = v; 
  endfunction

  // Function: peek()
  // Returns the snapshot value.
  // TODO: Why does peek return the snapshot? How will we
  //       get the regular value?
  function T peek();
    return peek_snapshot();
  endfunction
endclass

// CLASS: uvm_coherent_register_master
//
// A base class which acts as a "master", managing
// "slaves". The managed slaves are treated as a group
// of registers which are "snapshotted" together when
// this master class is "triggered".
//
class uvm_coherent_register_master #(type T = int) 
    extends uvm_register#(T);

  // Variable: slaves[$]
  // The list of all the slaves "managed".
  uvm_coherent_register_slave #(T) slaves[$];

  function new(string name, uvm_named_object p);
    super.new(name, p);
  endfunction

  // Function: add_slave()
  // Adds the slave 'r' to the managed list.
  virtual function void 
      add_slave(uvm_coherent_register_slave#(T) r);
    slaves.push_back(r);
  endfunction

  // Function: snapshot()
  // Causes the managed slaves to be snapshotted.
  virtual function void snapshot();
    foreach (slaves[i])
      slaves[i].snapshot();
  endfunction

  // Function: read_without_notify()
  // This is the "normal" read function that is called
  // in the register package. Calling this function
  // in the master is the trigger which will cause
  // the slaves to be snapshotted - doing a read()
  // on the master causes all the slaves to be snapshotted.
  function T read_without_notify(T local_mask = '1);
    snapshot();
    return super.read_without_notify(local_mask);
  endfunction
endclass
