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
`ifndef APB_AGENT_BFM
`define APB_AGENT_BFM

//
// BFM Description:
//
//
module apb_agent_bfm(apb_if APB);

apb_monitor_bfm monitor(APB.monitor_mp);
apb_driver_bfm  driver(APB.driver_mp);

//if(APB_IS_ACTIVE) begin: has_driver
//  apb_driver_bfm driver(APB.driver_mp);
//end

endmodule: apb_agent_bfm

`endif // APB_AGENT_BFM
