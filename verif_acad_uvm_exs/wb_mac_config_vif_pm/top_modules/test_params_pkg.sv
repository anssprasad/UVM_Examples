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

package test_params_pkg;
import uvm_pkg::*;

  // WISHBONE general slave parameters
  parameter slave_addr_space_sz = 32'h00100000;
  
  // WISHBONE slave memory parameters
  parameter mem_slave_size = 18;  // 2**slave_mem_size = size in words(32 bits) of wb slave memory
  parameter mem_slave_wb_id = 0;  // WISHBONE bus slave id of wb slave memory 
  
  // MAC WISHBONE parameters
  parameter mac_m_wb_id = 0;      // WISHBONE bus master id of MAC
  parameter mac_slave_wb_id = 1;  // WISHBONE bus slave  id of MAC 
  
endpackage
