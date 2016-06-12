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

`ifndef MAC_RX_FRAME_SEQ
`define MAC_RX_FRAME_SEQ

//sequence for sending a frame to the MAC
// Mike Baird
//----------------------------------------------

// forward declarations
typedef class mac_mii_rx_agent;

class mac_rx_frame_seq extends wb_mem_map_access_base_seq;
 `uvm_object_utils(mac_rx_frame_seq)


 rand bit [15:0] m_payload_size;   // number of byte in payload
 rand logic [7:0]  m_payload [];   // payload data for frame
 mac_mii_rx_agent m_parent_agent;  // handle to parent agent 

 function new(string name = "");
   super.new(name);
 endfunction

 task body();
  super.body();
  $cast(m_parent_agent,m_sequencer.get_parent()); // set handle to parent agent
  initialize_Rxbd();
  set_up_mode_reg();
  send_frame_to_mac();
 endtask

 // this method called by the parent sequence to set up the sequence for
 // generating ethernet packets
 virtual function void init_seq(uvm_sequencer #(wb_txn,wb_txn) seqr_handle,
                                int m_id,
                                int unsigned mem_base_addr,
                                int unsigned mac_b_addr,
                                bit[47:0] dest, bit[47:0] srce,
                                bit[15:0] len,  logic[7:0]  data []
                                );
   m_wb_seqr_handle   = seqr_handle;
   m_mac_id = m_id;
   m_s_mem_wb_base_addr = mem_base_addr;
   m_mac_wb_base_addr = mac_b_addr;
   m_tb_addr   = srce;
   m_MAC_addr  = dest;
   m_payload_size = len;
   m_payload    = data;
   m_payload = new[m_payload_size](m_payload);  //resize to m_payload_size
 endfunction

  virtual task set_up_mode_reg();  //sets up the mode reg in the MAC
    wb_txn wb_rd_results;    // for storing results of a wishbone read
    mode_register_t mode_reg;
    mode_reg.rxen   = 1;    // Rx enable
    mode_reg.txen   = 1;    // Rx enable
    mode_reg.pad    = 1;    // Pad Enable 
    mode_reg.full_d = 1;    // full duplex
    if(m_payload_size > 1500) //Maximum ethernet frame payload size is 1500 bytes
      mode_reg.huge_en = 1; // enable large payload size.  Note this effects the Rx buffers so careful    
    wb_write_register("mode_reg", mode_reg);  //write the mode reg
    //the following read will give time so transfer to MAC doesn't start before it is set up
    wb_read_register("mode_reg", wb_rd_results); 
  endtask
  
  // The Rx buffer descriptors are at address MAC base address + 0x400 - 0x7ff
  // There is up to 128 BD each BD is 64 bits (2 words) long
  // the first word is has the length and status/control bits
  // the second word is the pointer to the data buffer
  // Note: this method assumes only one buffer descriptor is used
  virtual task initialize_Rxbd();  //initialize buffer descriptor(s)
   wb_txn wb_rd_results;    // for storing results of a wishbone read
   int unsigned Rxbd_buff_addr;     //Rx buffer address
   rx_bd_t rx_bd;
   
   // set up buffer descriptor
   rx_bd.rdy  = 1;
   rx_bd.irq  = 1;
   rx_bd.wrap = 1; //indicates this is the last one
   Rxbd_buff_addr = m_s_mem_wb_base_addr + Rx_buf_base_off;   //where frame is stored
   //write to the buffer descriptor pointer the data buffer for the frame
   wb_write_register("rx_bd_0_ptr", Rxbd_buff_addr);
   wb_write_register("rx_bd_0", rx_bd); //write buffer descriptor status
  endtask

  // Sends a frame to the MAC and then waits for an interrupt to signal the frame has been received
  // then checks to make sure the frame was received properly.  Will do retries of the frame if a send error
  // has occurred
  virtual task send_frame_to_mac();
    ethernet_txn  txn;
    wb_txn wb_rd_results;  // for storing results of a wishbone read
    uvm_sequence_item temp;
    irq_source_register_t irq_source;
    rx_bd_t rxbd;
    bit error;  // error bit
    int retry_count;
    bit rx_irq;  // flag for valid Rx irq
    //NOTE:  minimum ethernet packet payload size is 46 bytes.  Otherwise need to pad with bytes of "00"
    if(m_payload_size < 46) begin
      m_payload_size = 46;  //adjust size
      m_payload = new[46](m_payload); //resize and pad with zero's
    end
      //create transaction object
    assert($cast(txn, create_item(ethernet_txn::type_id::get(), m_sequencer, "txn")));     
    do begin
      start_item(txn);  // tell sequencer ready to give a transaction item
      txn.set_transaction_id(this.get_transaction_id()); // set transaction_id to parents transaction_id
      txn.init_txn(m_MAC_addr, m_tb_addr, m_payload_size, m_payload); //initialize transaction item
      finish_item(txn); // send transaction
      get_response(temp);
      temp.set_id_info(txn);  // set transaction and sequence id's
      do begin
        wb_wait_irq();                // wait for interrupt request
        wb_read_register("irq_source_reg", wb_rd_results); //get interrupt source reg
        irq_source = wb_rd_results.data[0][6:0];
        case(1)
          irq_source.busy:  begin  //busy?
            error = 1; 
            retry_count++; //simply retry
            `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id), "BUSY\n",UVM_LOW )   
            if(retry_count <3)
              `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id), "Retrying Rx Frame\n",UVM_LOW )   
            wb_write_register("irq_source_reg",  7'b0010000);  // clear interrupt bit
            initialize_Rxbd();
            set_up_mode_reg();
            rx_irq = 1; // this is a valid irq for a Rx frame
          end
        irq_source.rxe:  begin // Receive error?
            error = 1; 
            retry_count++;
            `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id), "RXE - Receive Error\n",UVM_LOW )   
            wb_write_register("irq_source_reg",  7'b0010000);  // clear interrupt bit
            check_Rxbd_results(0, rxbd);        // check the Rx buffer descriptor status
            initialize_Rxbd();
            set_up_mode_reg();
            rx_irq = 1; // this is a valid irq for a Rx frame
          end
        irq_source.rxb: begin // Good?
            `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id), "RXB - Receive frame",UVM_LOW ) 
            `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id),
               "\n-------Ethernet frame successfully Received by MAC\n",UVM_LOW )
            wb_write_register("irq_source_reg",  7'b0000100);  // clear interrupt bit
            error = 0;  // clear error in case it is good after a retry
            rx_irq = 1; // this is a valid irq for a Rx frame
          end       
        irq_source.txb || irq_source.txe: 
          #1000 rx_irq = 0; // irq was for a Tx frame
          // Note:  The wb_wait_irq does a level check so until the Tx irq bit is cleared
          // wb_wait_irq will return in about 100nS with the same irq vector. The delay of 1000nS here
          // lengthens that loop so it is not hammering the wishbone bus too hard doing reads of the irq reg
        endcase
      end
      while(!rx_irq);  // loop until a valid Rx frame irq
    end
    while (error && retry_count < 3); //retry if error and not too many errors
    if (retry_count >=3)
      `uvm_error ($sformatf("MAC_RX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id),
        $sformatf("Rx Error.  Retry count exceeded.  Interrupt status = %b", irq_source,) ) 
    if( m_parent_sequence.get_use_response_handler() == 1) // custom response handler?
      m_parent_sequence.response_handler(temp);  // Yes call custom handler
    else
      m_parent_sequence.put_response(temp);  //write ethernet frame from MAC to parent sequences response queue
    check_data_in_mac(0, txn);
  endtask
  
  // this task is for checking the frame in the memory of the MAC
  // after sending the frame to the MAC
  virtual task check_data_in_mac(int bd_num, ethernet_txn exp_txn);
    wb_txn wb_rd_results;    // for storing results of a wishbone read
    rx_bd_t rxbd;
    bit[31:0] addr;
    ethernet_txn act_txn;
    int i,j;
    string s1,s2;
    
    check_Rxbd_results(bd_num, rxbd);  //Get buffer descriptor status
    if(!rxbd.rdy) begin // is there data in the buffer?
      wb_read_register("rx_bd_0_ptr", wb_rd_results); //get bd pointer
      addr = wb_rd_results.data[0]; //addr gets pointer to frame in wishbone memory
      wb_read(addr, wb_rd_results,4); //get data up to the payload size
      act_txn = ethernet_txn::type_id::create(); // create object
      // unpack data from wishbone memory into the ethernet txn fields
      act_txn.dest_addr[47:16] = wb_rd_results.data[0]; //upper 32 bits of dest address
      act_txn.dest_addr[15:00] = wb_rd_results.data[1][31:16]; //lower 16 bits of dest address
      act_txn.srce_addr[47:32] = wb_rd_results.data[1][15:0];  //upper 16 bits of srce address
      act_txn.srce_addr[31:00] = wb_rd_results.data[2]; //upper 32 bits of dest address
      act_txn.payload_size     = wb_rd_results.data[3][31:16]; //lower 16 bits of dest address
      act_txn.payload = new[act_txn.payload_size];              //resize payload
      act_txn.payload[0] = wb_rd_results.data[3][15:8];   //byte 0
      act_txn.payload[1] = wb_rd_results.data[3][7:0];    //byte 1
      wb_read(addr+16, wb_rd_results, ((act_txn.payload_size-2)/4)+2); //get rest of data
      for(i=0, j=2; j<act_txn.payload_size-3; i++) begin  
        act_txn.payload[j++] = wb_rd_results.data[i][31:24];
        act_txn.payload[j++] = wb_rd_results.data[i][23:16];
        act_txn.payload[j++] = wb_rd_results.data[i][15:08];
        act_txn.payload[j++] = wb_rd_results.data[i][07:00];
      end
      // check to see if word aligned
      case(act_txn.payload_size -j) 
        0:  //aligned
             act_txn.crc = wb_rd_results.data[i];  //write the crc
        1: begin // one extra byte
             act_txn.payload[j++] = wb_rd_results.data[i][31:24];
             act_txn.crc[31:08]   = wb_rd_results.data[i++][23:00]; // write the crc
             act_txn.crc[07:00]   = wb_rd_results.data[i][31:24];   // last byte of crc
           end
        2: begin // 2 extra bytes      
             act_txn.payload[j++] = wb_rd_results.data[i][31:24];
             act_txn.payload[j++] = wb_rd_results.data[i][23:16];
             act_txn.crc[31:16]   = wb_rd_results.data[i++][15:00]; // write the crc
             act_txn.crc[15:00]   = wb_rd_results.data[i][31:16];   // last 16 bits of crc
          end
        3: begin //3 extra bytes
             act_txn.payload[j++] = wb_rd_results.data[i][31:24];
             act_txn.payload[j++] = wb_rd_results.data[i][23:16];
             act_txn.payload[j++] = wb_rd_results.data[i][15:08];
             act_txn.crc[31:24]   = wb_rd_results.data[i++][07:00]; // write the crc
             act_txn.crc[23:00]   = wb_rd_results.data[i][31:08];   // last 16 bits of crc
           end
      endcase
      m_parent_agent.mii_rx_seq_ap.write(act_txn);  // broadcast the actual transaction
/*      
      if(act_txn.compare(exp_txn))
        `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d",m_mac_id),
          "\n-------------------Frame received by the MAC was with correct data\n",UVM_LOW )
      else begin
        $sformat(s1, "\n-------------------Frame received by the MAC with INCORRECT data\n");
        $sformat(s2, " expected %s  actual %s", exp_txn.sprint(), act_txn.sprint());
        `uvm_error($sformatf("MAC_RX_FRAME_SEQ_%0d",m_mac_id), {s1,s2} )
      end
*/
    end
  endtask

  // this task is called after a transfer to check the status of the transfer
  // Note assumes only using the first RX buffer descriptor for transfers
  task check_Rxbd_results(input bit [7:0] bd_num = 0, output rx_bd_t rxbd);
    wb_txn wb_rd_results;    // for storing results of a wishbone read
    string s1;
    wb_read_register("rx_bd_0", wb_rd_results);  //get BD status
    rxbd = int'(wb_rd_results.data[0]);
    `uvm_info($sformatf("MAC_RX_FRAME_SEQ_%0d",m_mac_id),
                    $sformatf("%0d bytes(decimal) received", rxbd.len-18),UVM_LOW )
    if(rxbd.rdy)          s1 = {s1, " Empty,"};           
    if(rxbd.irq)          s1 = {s1, " IRQ Enable,"};           
    if(rxbd.wrap)         s1 = {s1, " Wrap,"};          
    if(rxbd.c_frame)      s1 = {s1, " Control Frame,"};       
    if(rxbd.miss)         s1 = {s1, " Miss,"};          
    if(rxbd.over_run)     s1 = {s1, " Overrun,"};      
    if(rxbd.inval_symbol) s1 = {s1, " Invalid Symbol,"};  
    if(rxbd.dn)           s1 = {s1, " Dribble Nibble,"};            
    if(rxbd.too_long)     s1 = {s1, " Too Long,"};      
    if(rxbd.s_frame)      s1 = {s1, " Short Frame,"};       
    if(rxbd.crc_error)    s1 = {s1, " Rx CRC Error,"};     
    if(rxbd.l_coll)       s1 = {s1, " Late Collision"};
    `uvm_info("MAC_SIMPLE_RxBD", {"RxBD status bits set:\n",s1,"\n"},UVM_LOW )       
  endtask

endclass
`endif
