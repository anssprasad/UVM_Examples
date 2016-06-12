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

`ifndef WB_M_BUS_DRIVER
`define WB_M_BUS_DRIVER

// WISHBONE master driver
// Mike Baird
//----------------------------------------------
class wb_m_bus_driver extends uvm_driver  #(wb_txn, wb_txn);
`uvm_component_utils(wb_m_bus_driver)

  uvm_analysis_port #(wb_txn) wb_drv_ap;
  virtual wishbone_bus_syscon_if m_v_wb_bus_if;  // Virtual Interface
  bit [2:0] m_id;  // Wishbone bus master ID
  wb_config m_config;
  

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get config object
    if (!uvm_config_db#(wb_config)::get(this,"","wb_config", m_config) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration wb_config from uvm_config_db. Have you set() it?")
    m_id = m_config.m_wb_master_id;
    wb_drv_ap = new("wb_drv_ap", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_v_wb_bus_if = m_config.v_wb_bus_if; // set local virtual if property
  endfunction 
  
  function void end_of_elaboration_phase(uvm_phase phase);
    int wb_verbosity;
    set_report_verbosity_level(m_config.m_wb_verbosity);
    _global_reporter.set_report_verbosity_level(wb_verbosity);
  endfunction  
  
  task run_phase(uvm_phase phase);
    wb_txn req_txn;
    forever begin    
      seq_item_port.get(req_txn);  // get transaction
      @ (posedge m_v_wb_bus_if.clk) #1;  // sync to clock edge + 1 time step
      case(req_txn.txn_type)  //what type of transaction?
        NONE: `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                              $sformatf("wb_txn %0d the wb_txn_type was type NONE",
                              req_txn.get_transaction_id()),UVM_LOW )
        WRITE: wb_write_cycle(req_txn);
        READ:  wb_read_cycle(req_txn);
        RMW:  wb_rmw_cycle(req_txn);
        WAIT_IRQ: fork wb_irq(req_txn); join_none
        default: `uvm_error($sformatf("WB_M_DRVR_%0d",m_id),
                                  $sformatf("wb_txn %0d the wb_txn_type was type illegal",
                                  req_txn.get_transaction_id()) )
      endcase
    end
  endtask
  
  //READ 1 or more cycles
  virtual task wb_read_cycle(ref wb_txn req_txn);
    logic [31:0] temp_addr = req_txn.adr;
    for(int i = 0; i<req_txn.count; i++) begin
      if(m_v_wb_bus_if.rst) begin
        reset();  // clear everything
        return; //exit if reset is asserted
      end
      m_v_wb_bus_if.m_addr[m_id] = temp_addr;
      m_v_wb_bus_if.m_we[m_id]  = 0;  // read
      m_v_wb_bus_if.m_sel[m_id] = req_txn.byte_sel;
      m_v_wb_bus_if.m_cyc[m_id] = 1;
      m_v_wb_bus_if.m_stb[m_id] = 1;
      @ (posedge m_v_wb_bus_if.clk)
      while (!(m_v_wb_bus_if.m_ack[m_id] & m_v_wb_bus_if.gnt[m_id])) @ (posedge m_v_wb_bus_if.clk);
      req_txn.data[i] = m_v_wb_bus_if.m_rdata;  // get data
      temp_addr =  temp_addr + 4;  // byte address so increment by 4 for word addr
    end
    seq_item_port.put(req_txn);  // send rsp object back to sequence
    wb_drv_ap.write(req_txn);  //broadcast read transaction with results        
    m_v_wb_bus_if.m_cyc[m_id] = 0;
    m_v_wb_bus_if.m_stb[m_id] = 0;     
  endtask

  //WRITE  1 or more write cycles
  virtual task wb_write_cycle(ref wb_txn req_txn);
    wb_txn orig_req_txn;
    $cast(orig_req_txn, req_txn.clone());  //save off copy of original req transaction
    for(int i = 0; i<req_txn.count; i++) begin
      if(m_v_wb_bus_if.rst) begin
        reset();  // clear everything
        return; //exit if reset is asserted
      end
      m_v_wb_bus_if.m_wdata[m_id] = req_txn.data[i];
      m_v_wb_bus_if.m_addr[m_id] = req_txn.adr;
      m_v_wb_bus_if.m_we[m_id]  = 1;  //write
      m_v_wb_bus_if.m_sel[m_id] = req_txn.byte_sel;
      m_v_wb_bus_if.m_cyc[m_id] = 1;
      m_v_wb_bus_if.m_stb[m_id] = 1;
      @ (posedge m_v_wb_bus_if.clk)
      while (!(m_v_wb_bus_if.m_ack[m_id] & m_v_wb_bus_if.gnt[m_id])) @ (posedge m_v_wb_bus_if.clk);
      req_txn.adr =  req_txn.adr + 4;  // byte address so increment by 4 for word addr
    end
    `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                    $sformatf("req_txn: %s",orig_req_txn.convert2string()),
                    351 )
    wb_drv_ap.write(orig_req_txn);  //broadcast orignal transaction
    m_v_wb_bus_if.m_cyc[m_id] = 0;
    m_v_wb_bus_if.m_stb[m_id] = 0;     
  endtask

  //RMW ( read-modify_write)
  virtual task wb_rmw_cycle(ref wb_txn req_txn);
    `uvm_info($sformatf("WB_M_DRVR_%0d",m_id),
                    "Wishbone RMW instruction not implemented yet",UVM_LOW )
  endtask
  
  virtual task wb_irq(wb_txn req_txn);
    wait(m_v_wb_bus_if.irq);
    req_txn.data[0] = m_v_wb_bus_if.irq;
    seq_item_port.put(req_txn);  // send rsp object back to sequence
  endtask
  
  function void reset();
    m_v_wb_bus_if.m_cyc[m_id] = 0;
    m_v_wb_bus_if.m_stb[m_id] = 0;   
  endfunction

endclass
`endif
