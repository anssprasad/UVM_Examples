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

`ifndef MAC_SIMPLE_DUPLEX_SEQ
`define MAC_SIMPLE_DUPLEX_SEQ
//sequence for sending and receiving frames to/from the MAC
// uses separate drivers for sending and receiving
// Mike Baird

//NOTE:  it is required that this inherits from the default specialization of uvm_sequence
// so that the response queue type is of uvm_sequence_item class because of multiple
// response types - ethernet_txn and wb_txn

class mac_simple_duplex_seq #(int WB_ID = 0) extends wb_mem_map_access_base_seq;
  `uvm_object_param_utils(mac_simple_duplex_seq #(WB_ID))
  
  // handle for sequencer in wishbone agent
  uvm_sequencer #(wb_txn,wb_txn)   wb_seqr;
  // handles for the mac Rx and Tx sequencers in MAC agent
  uvm_sequencer #(ethernet_txn,ethernet_txn) mii_rx_seqr;
  uvm_sequencer #(ethernet_txn,ethernet_txn) mii_tx_seqr;
  
  // variables
  logic [7:0]    stim_data[];     // data to send/receive from MAC
  ethernet_txn eth_rsp_txn;       // for storing ethernet frame received from the MAC
  int txn_id = 1;                 // for setting transaction id's on transactions
  // response queues for ethernet & wishbone transactions
  uvm_queue #(uvm_sequence_item) eth_rsp_q; // response q for ethernet_txn
  uvm_queue #(uvm_sequence_item) wb_rsp_q;  // response q for wb_txn 

  uvm_register_map m_register_map;
  wb_config m_config;

  function new(string name = "");
    super.new(name);
    // create response queues
    eth_rsp_q = new("eth_rsp_q");
    wb_rsp_q  = new("wb_rsp_q" );
  endfunction
      
  task body;
    super.body();
    // get config object
    if (!uvm_config_db#(wb_config)::get(m_sequencer,"","wb_config", m_config) )
       `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration wb_config from uvm_config_db. Have you set() it?")
    use_response_handler(1); // set to use custom rsp handler
    init_sequence();  // set up this sequence's  properties
    init_mac();       // init the MAC's registers

//    fork  // duplex operation
//      mac_tx_frame(50, eth_rsp_txn);  // get a frame from the MAC
//      mac_rx_frame(50, eth_rsp_txn);  // send a frame to the MAC
//    join
//    mac_rx_frame(53, eth_rsp_txn);  // send a frame to the MAC 
//    mac_tx_frame(51,  eth_rsp_txn);  // get a frame from the MAC
//    mac_rx_frame(51, eth_rsp_txn);  // send a frame to the MAC
//    mac_tx_frame(52,  eth_rsp_txn);  // get a frame from the MAC
//    mac_rx_frame(103, eth_rsp_txn);  // send a frame to the MAC
    
  endtask
  
  virtual function void init_payload(int size = 50); 
    stim_data = new[size];  //46 is minimum size, 1500 max
    //set up data to send    
    for(int i = 0; i < size; i++)
      stim_data[i] = i+1;    
  endfunction
  
  virtual function void init_sequence();
    // assumption here is that this sequence is started with m_sequencer
    // pointing to the wb_sequencer
    $cast(wb_seqr,m_sequencer);
    // find mac_rx_sequencer and mac_tx_sequencer    
    $cast(mii_rx_seqr,uvm_top.find($sformatf("*env_%0d*mii_rx_seqr", WB_ID)));
    $cast(mii_tx_seqr,uvm_top.find($sformatf("*env_%0d*mii_tx_seqr", WB_ID)));
  endfunction
  
  virtual task init_mac();  // init the MAC
    wb_txn wb_rd_results;
    uvm_sequence_item temp;
    int_mask_register_t int_mask_reg;
    mode_register_t mode_reg;

     //clear mode register in MAC
    wb_write_register("mode_reg", 0);
     //write MAC_ADDR0 register
    wb_write_register("mac_addr0_reg", m_config.m_mac_eth_addr[31:00]);
     //write MAC_ADDR1 register
    wb_write_register("mac_addr1_reg", m_config.m_mac_eth_addr[47:32]);

    // set up interrupt masks
    int_mask_reg.txb_m = 1; //unmask transmit buffer irq
    int_mask_reg.txe_m = 1; //unmask transmit error irq
    int_mask_reg.rxb_m = 1; //unmask receive frame irq
    int_mask_reg.rxe_m = 1; //unmask receive error irq
    int_mask_reg.busy_m= 1; //unmask busy irq
    wb_write_register("int_mask_reg", int_mask_reg);

    // set up the mode register for sending and receiving
    mode_reg.txen   = 1;    // Tx enable
    mode_reg.rxen   = 1;    // Rx enable
    mode_reg.pad    = 1;    // Pad Enable 
    mode_reg.full_d = 1;    // full duplex
    mode_reg.crc_en = 1;    // crc enable
    wb_write_register("mode_reg", mode_reg);
  endtask
 
 // Custom response handler
 function void response_handler(uvm_sequence_item response);
  ethernet_txn e_txn;
  wb_txn w_txn;
  if ($cast(w_txn, response)) begin // WISHBONE txn?
    wb_rsp_q.push_back(w_txn);  // add to wb_txn response queue
    return;
  end
  else if ($cast(e_txn, response)) begin // Ethernet txn?
    eth_rsp_q.push_back(e_txn); // add to ethernet_txn response queue
    return;
  end
  else 
   `uvm_error("mac_s_cust_rsp_seq",
     $sformatf("Response handler received an unexpected type - %s, response was dropped",
               response.get_type_name()))  
 endfunction
 
 // Custom get_response method for ethernet or wb transactions
 task get_txn_response(output uvm_sequence_item response,
                       ref uvm_queue #(uvm_sequence_item) q,
                       input int transaction_id = -1);
  int queue_size;
  if(q.size() ==0)
    wait(q.size() !=0); // wait for something in queue
  if(transaction_id == -1) begin
    response =  q.pop_front();
    return;
  end
  forever begin
   queue_size = q.size();
   for (int i=0; i< queue_size; i++) begin //look for item with transaction_id
   response = q.get(i);  // get item from q
   if(response.get_transaction_id() == transaction_id) begin
     q.delete(i); // delete from queue
     return;
   end
   end
   wait(q.size() != queue_size); // wait for another response item
  end
 endtask
  
//--------------------------------------------
// MII sequence call methods
//
  virtual task mac_rx_frame(int count, output ethernet_txn eth_txn);
    mac_rx_frame_seq m_rx_f_seq;
    uvm_sequence_item temp;
    int m_txn_id; // for storing the transaction_id of generated sequence
    `uvm_info("MAC_SIMPLE_DUPLEX_SEQ", "\n-------Sending a frame from the testbench to the MAC\n",UVM_LOW )
    init_payload(count); //set up payload
    assert ($cast(m_rx_f_seq, create_item(mac_rx_frame_seq::type_id::get(), mii_rx_seqr, "m_rx_f_seq")));
    start_item (m_rx_f_seq);
    m_txn_id = txn_id++;  // save off transaction_id
    m_rx_f_seq.set_transaction_id(m_txn_id);  //set the transaction_id of sequence
    m_rx_f_seq.init_seq(wb_seqr, m_mac_id, m_config.m_s_mem_wb_base_addr, m_config.m_mac_wb_base_addr,
                        m_config.m_mac_eth_addr, m_config.m_tb_eth_addr, count, stim_data);
    finish_item(m_rx_f_seq);
    get_txn_response(temp, eth_rsp_q);   // get return response from ethernet response queue
    $cast(eth_txn, temp);
  endtask

  virtual task mac_tx_frame(int count, output ethernet_txn eth_txn);
    uvm_sequence_item temp;
    mac_tx_frame_seq m_tx_f_seq;
    int m_txn_id; // for storing the transaction_id of generated sequence
    `uvm_info("MAC_SIMPLE_DUPLEX_SEQ", "\n-------Sending a frame from the MAC to the testbench\n",UVM_LOW )
    init_payload(count); //set up payload
    assert ($cast(m_tx_f_seq, create_item(mac_tx_frame_seq::type_id::get(), mii_tx_seqr, "m_tx_f_seq")));
    start_item(m_tx_f_seq);
    m_txn_id = txn_id++;  // save off transaction_id
    m_tx_f_seq.set_transaction_id(m_txn_id);  //set the transaction_id of sequence
    m_tx_f_seq.init_seq(wb_seqr, m_mac_id, m_config.m_s_mem_wb_base_addr, m_config.m_mac_wb_base_addr,
                        m_config.m_tb_eth_addr, m_config.m_mac_eth_addr, count, stim_data);
    finish_item(m_tx_f_seq);    
    get_txn_response(temp, eth_rsp_q, m_txn_id);   // get return response from ethernet response queue
    $cast(eth_txn, temp);
  endtask

endclass
`endif
