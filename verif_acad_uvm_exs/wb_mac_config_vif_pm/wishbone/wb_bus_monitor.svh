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


// WISHBONE bus monitor
// Monitors slave read and write transactions and "packages" each
// transaction into a wb_txn and broadcasts the wb_txn
// Note only monitors slave 0 and slave 1 (see wishbone_bus_syscon_if)
// Mike Baird
//----------------------------------------------
class wb_bus_monitor extends uvm_monitor;
`uvm_component_utils(wb_bus_monitor)

  uvm_analysis_port #(wb_txn) wb_mon_ap;
  virtual wishbone_bus_syscon_if m_v_wb_bus_if;
  wb_config m_config;

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    wb_mon_ap = new("wb_mon_ap", this);
    if(!uvm_config_db #(wb_config)::get(this, "", "wb_config", m_config)) begin
      `uvm_error("build_phase", "Unable to find wb_config in the configuration database")
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    m_v_wb_bus_if = m_config.v_wb_bus_if; // set local virtual if property
  endfunction

  task run_phase(uvm_phase phase);
    wb_txn txn;

    forever @ (posedge m_v_wb_bus_if.clk)
      if(m_v_wb_bus_if.s_cyc) begin // Is there a valid wb cycle?
        txn = wb_txn::type_id::create("txn"); // create a new wb_txn
        txn.adr = m_v_wb_bus_if.s_addr; // get address
        txn.count = 1;  // set count to one read or write
        if(m_v_wb_bus_if.s_we)  begin // is it a write?
          txn.data[0] = m_v_wb_bus_if.s_wdata;  // get data
          txn.txn_type = WRITE; // set op type
          while (!(m_v_wb_bus_if.s_ack[0] | m_v_wb_bus_if.s_ack[1]|m_v_wb_bus_if.s_ack[2]))
            @ (posedge m_v_wb_bus_if.clk); // wait for cycle to end
        end
        else begin
          txn.txn_type = READ; // set op type
          case (1) //Nope its a read, get data from correct slave
            m_v_wb_bus_if.s_stb[0]:  begin
                while (!(m_v_wb_bus_if.s_ack[0])) @ (posedge m_v_wb_bus_if.clk); // wait for ack
                txn.data[0] = m_v_wb_bus_if.s_rdata[0];  // get data
              end
            m_v_wb_bus_if.s_stb[1]:  begin
                while (!(m_v_wb_bus_if.s_ack[1])) @ (posedge m_v_wb_bus_if.clk); // wait for ack
                txn.data[0] = m_v_wb_bus_if.s_rdata[1];  // get data
              end
          endcase
        end
        wb_mon_ap.write(txn); // broadcast the wb_txn
      end
  endtask
endclass

