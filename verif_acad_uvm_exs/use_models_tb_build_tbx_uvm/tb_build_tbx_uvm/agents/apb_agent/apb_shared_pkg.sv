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

package apb_shared_pkg;

  typedef struct packed {
    logic[31:0] addr;
    logic[31:0] data;
    logic we;
    int delay;
    bit error;
  } apb_seq_item_s;

  parameter int APB_SEQ_ITEM_NUM_BITS  = $bits(apb_seq_item_s);
  parameter int APB_SEQ_ITEM_NUM_BYTES = (APB_SEQ_ITEM_NUM_BITS+7)/8;

  typedef bit [APB_SEQ_ITEM_NUM_BITS-1:0] apb_seq_item_vector_t;

endpackage
