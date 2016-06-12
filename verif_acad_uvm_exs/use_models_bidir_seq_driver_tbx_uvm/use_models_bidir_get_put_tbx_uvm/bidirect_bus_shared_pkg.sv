//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
//

package bidirect_bus_shared_pkg;

// Bus sequence item struct
typedef struct packed {
  // Request fields
  logic[31:0] addr;
  logic[31:0] write_data;
  bit read_not_write;
  int delay;

  // Response fields
  bit error;
  logic[31:0] read_data;
} bus_seq_item_s;

parameter int BUS_SEQ_ITEM_NUM_BITS  = $bits(bus_seq_item_s);
parameter int BUS_SEQ_ITEM_NUM_BYTES = (BUS_SEQ_ITEM_NUM_BITS+7)/8;

typedef bit [BUS_SEQ_ITEM_NUM_BITS-1:0] bus_seq_item_vector_t;

endpackage: bidirect_bus_shared_pkg
