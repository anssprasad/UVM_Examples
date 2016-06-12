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

// Typedef : Internal use - sets the "kind" for the range.
typedef enum bit [1:0] { MEMORY_SET_BY_HAND, 
                         MEMORY_RAND_BY_HAND, 
                         MEMORY_RAND} 
                         MEMORY_R_TYPE;
//
// CLASS: uvm_memory_range
// A uvm_memory_range defines one block of memory with a range_start
// address and an end address.
//
// A range class (uvm_memory_range) has a range_start address and
// an end address (or a range_start and a length)
// It has a "type", (MEMORY_RAND, 
// MEMORY_RAND_BY_HAND, MEMORY_SET_BY_HAND).
//
// Where:
//   MEMORY_SET_BY_HAND - this range was created by hand, and should
//                        not be deleted or changed.
//   MEMORY_RAND_BY_HAND - this is a range that is random, but we
//                        did add it - we told the system - "create
//                        a random range".
//   MEMORY_RAND         - this is a range that is random, and
//                        the system decided to create it on its
//                        own. we didn't ask for it - it's just
//                        filling space, per the 
//                        randomization/constraints in place.

class uvm_memory_range;
  string tag_name = "ranges";

  MEMORY_R_TYPE t = MEMORY_RAND; // How it was entered. 
                   // By hand, As a random item or 
                   //   just by list expansion.

  rand address_t range_start, range_end;

  // Constraint: make sure end is larger than or equal 
  // to range_start.
  constraint legal {
    range_end >= range_start;
  }

  // Constraint: Limit the legal value - mostly for speed
  // during the debug time. Something for the user to override.
  constraint value_range {
    //range_start >= 0; range_start < 3000;
    //range_end   >= 0; range_end   < 3000;
  }
endclass
