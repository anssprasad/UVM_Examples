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

`ifndef MII_SCOREBOARD
`define MII_SCOREBOARD

// Scoreboard for MAC Media Independent Interface (MII)
// checks and counts ethernet transactions to/from the MAC
// Across its MII
// Mike Baird
//----------------------------------------------

class mii_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mii_scoreboard)

    // analsysis exports
  uvm_analysis_export #(ethernet_txn) mii_rx_drv_axp;
  uvm_analysis_export #(ethernet_txn) mii_tx_drv_axp;
  uvm_analysis_export #(ethernet_txn) mii_rx_seq_axp;
  uvm_analysis_export #(ethernet_txn) mii_tx_seq_axp;

  // components
  logic [31:0] shadow_mem [ bit[31:0] ];  //associative array for shadow memory

    // analysis fifos
  uvm_tlm_analysis_fifo   #(ethernet_txn) mii_rx_drv_fifo;
  uvm_tlm_analysis_fifo   #(ethernet_txn) mii_tx_drv_fifo;
  uvm_tlm_analysis_fifo   #(ethernet_txn) mii_rx_seq_fifo;
  uvm_tlm_analysis_fifo   #(ethernet_txn) mii_tx_seq_fifo;

  // variables
  int unsigned mem_base_addr;
  int unsigned mem_size;  // size in bytes of memory
  int wb_id;  // wishbone id of slave memory
  int rx_error_cnt, tx_error_cnt;
  int rx_txn_cnt, tx_txn_cnt;
  int wb_wt_non_mem_cnt, wb_rd_non_mem_cnt;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);

    // analsysis exports
    mii_rx_drv_axp  = new("mii_rx_drv_axp", this);
    mii_tx_drv_axp  = new("mii_tx_drv_axp", this);
    mii_rx_seq_axp  = new("mii_rx_seq_axp", this);
    mii_tx_seq_axp  = new("mii_tx_seq_axp", this);

    // analysis fifos
    mii_rx_drv_fifo = new("mii_rx_drv_fifo",this);
    mii_tx_drv_fifo = new("mii_tx_drv_fifo",this);
    mii_rx_seq_fifo = new("mii_rx_seq_fifo",this);
    mii_tx_seq_fifo = new("mii_tx_seq_fifo",this);
  endfunction

  function void connect_phase(uvm_phase phase);

    // analsysis exports & analysis fifos
    mii_rx_drv_axp.connect(mii_rx_drv_fifo.analysis_export);
    mii_tx_drv_axp.connect(mii_tx_drv_fifo.analysis_export);
    mii_rx_seq_axp.connect(mii_rx_seq_fifo.analysis_export);
    mii_tx_seq_axp.connect(mii_tx_seq_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    wb_txn txn;

    fork
      rx_proc();
      tx_proc();
    join
  endtask

  virtual task tx_proc(); // Compare and counts Tx transactions
    ethernet_txn exp_txn, act_txn;
    string s1,s2;

    forever begin
      mii_tx_drv_fifo.get(act_txn);  // get actual txn from driver
      mii_tx_seq_fifo.get(exp_txn);  // get expected txn
      tx_txn_cnt++; // increment number of received tx transactions
      if(!act_txn.compare(exp_txn)) begin  // are they the same?
        tx_error_cnt++;  // no increment error count
        $sformat(s1, "\n-------------------Frame received by the Testbench with INCORRECT data\n");
        $sformat(s2, " expected %s  actual %s",
               exp_txn.convert2string(), act_txn.sprint(uvm_default_tree_printer));
        `uvm_error("MMI_SB", {s1,s2})
      end
      else begin
        $sformat(s1, "\n-------------------Testbench receieved ethernet frame from MAC\n");
        $sformat(s2, "-------------------Frame received by the Testbench was with correct data \n");
        `uvm_info("MMI_SB", {s1,s2},UVM_MEDIUM);
      end
    end
  endtask

  virtual task rx_proc();
    ethernet_txn exp_txn, act_txn;
    string s1,s2;

    forever begin
      mii_rx_drv_fifo.get(exp_txn);  // get actual txn from driver
      mii_rx_seq_fifo.get(act_txn);  // get expected txn
      rx_txn_cnt++; // increment number of received tx transactions
      if(act_txn.compare(exp_txn))
        `uvm_info("MMI_SB",
          "\n-------------------Frame received by the MAC was with correct data\n",
          UVM_MEDIUM)
      else begin
        $sformat(s1, "\n-------------------Frame received by the MAC with INCORRECT data\n");
        $sformat(s2, " expected %s  actual %s", exp_txn.sprint(), act_txn.sprint());
        `uvm_error("MMI_SB", {s1,s2})
      end
    end
  endtask


  function void report();
    string s1,s2,s3,s4,s5;
    $sformat(s1,"\n  Number of Ethernet transactions sent (Tx) by the MAC: %0d \n",tx_txn_cnt);
    $sformat(s2,  "  Number of Tx Errors: %0d \n",tx_error_cnt);
    $sformat(s3,  "  Number of Ethernet transactions received (Rx) by the MAC: %0d \n",rx_txn_cnt);
    $sformat(s4,  "  Number of Rx Errors: %0d \n",rx_error_cnt);
    `uvm_info($sformatf("MEM_SB_%0d",wb_id),{s1,s3,s2,s4},UVM_LOW )
  endfunction

endclass
`endif
