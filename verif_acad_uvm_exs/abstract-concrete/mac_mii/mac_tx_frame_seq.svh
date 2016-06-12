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

`ifndef MAC_TX_FRAME_SEQ
`define MAC_TX_FRAME_SEQ

//sequence for receiving a frame to the MAC
// Mike Baird
//----------------------------------------------

// forward declarations
typedef class mac_mii_tx_agent;

class mac_tx_frame_seq extends wb_mem_map_access_base_seq;
 `uvm_object_utils (mac_tx_frame_seq)

 rand bit [15:0] m_payload_size;     // number of byte in payload
 rand logic [7:0]  m_payload [];     // payload data for frame
 rand bit [15:0] m_frame_length;     
 mac_mii_tx_agent m_parent_agent;  // handle to parent agent 
 ethernet_txn rsp_txn;             // Ethernet frame received from MAC
 // Ethernet frame with expected values to receive from MAC
 ethernet_txn exp_txn;             

 function new(string name = "");
   super.new(name);
 endfunction
 
 task body();
  super.body();
  // set handle to parent agent
  $cast(m_parent_agent,m_sequencer.get_parent()); 
  setup_frame();
  set_up_mode_reg();
  initialize_Txbd();
  receive_frame(rsp_txn);
  if( m_parent_sequence.get_use_response_handler() == 1) // custom  handler?
   m_parent_sequence.response_handler(rsp_txn);  // Yes call custom handler
  else
   //write ethernet frame from MAC to parent sequences response queue
   m_parent_sequence.put_response(rsp_txn);  
 endtask

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
  m_MAC_addr  = srce;
  m_tb_addr  = dest;
  m_payload_size = len;
  m_frame_length = m_payload_size + 14; //payload + dest, srce, payload_size
  m_payload    = data;
  exp_txn = ethernet_txn::type_id::create(); // create object
  exp_txn.init_txn(dest, srce, len, data); //initialize it with expected info
 endfunction

 // Method writes an ethernet frame in the MAC's memory buffer
 virtual task setup_frame();
  int unsigned Txbd_buff_addr;     //Tx buffer address
  // location where frame is stored
  Txbd_buff_addr = m_s_mem_wb_base_addr + Tx_buf_base_off;   
    //Note: above line assumes using only one Txbd, ie the first one only    
  wb_write(Txbd_buff_addr,  m_tb_addr[47:16]); //write upper 32 bits dest addr
  Txbd_buff_addr +=4; //increment buffer address (byte address so incr by 4)
    //write lower bits of dest addr, upper 16 of source addr
  wb_write(Txbd_buff_addr, {m_tb_addr[15:00], m_MAC_addr[47:32]}); 
  Txbd_buff_addr +=4; //increment buffer address (byte address so incr by 4)
  wb_write(Txbd_buff_addr,  m_MAC_addr[31:00]); //write lower 32 bits srce addr
  Txbd_buff_addr +=4; //increment buffer address (byte address so incr by 4)
    // write payload size + first 2 bytes of payload
  wb_write(Txbd_buff_addr, {m_payload_size,m_payload[0],m_payload[1]});   
  Txbd_buff_addr +=4; //increment buffer address (byte address so incr by 4)
  wb_write_payload(Txbd_buff_addr, m_payload);  //write the rest of the payload
 endtask

 // Method sets up the mode reg in the MAC
 virtual task set_up_mode_reg();
  wb_txn wb_rd_results;    // for storing results of a wishbone read
  mode_register_t mode_reg;
  mode_reg.rxen   = 1;    // Rx enable
  mode_reg.txen   = 1;    // Rx enable
  mode_reg.pad    = 1;    // Pad Enable 
  mode_reg.full_d = 1;    // full duplex
  mode_reg.crc_en = 1;    // crc enable
  wb_write_register("mode_reg", mode_reg);  //write the mode reg
  //the following read will give time so transfer to MAC doesn't start before it is set up
  wb_read_register("mode_reg", wb_rd_results);
 endtask

 // this task assumes that only the first buffer descriptor will be used
 virtual task initialize_Txbd();  
   int unsigned Txbd_buff_addr;     //Tx buffer address
   tx_bd_t tx_bd;
   wb_txn wb_rd_results;    // for storing results of a wishbone read

   // set up single (last) buffer descriptor
   tx_bd.len  = m_frame_length;  //length of frame less crc, preamble & sfd
   tx_bd.rdy  = 1;
   tx_bd.irq  = 1;
   tx_bd.crc_en = 1;
   tx_bd.wrap = 1; //indicates this is the last one
   Txbd_buff_addr = m_s_mem_wb_base_addr + Tx_buf_base_off;   //where frame is stored
   //write to the buffer descriptor pointer the data buffer for the frame
   wb_write_register("tx_bd_0_ptr", Txbd_buff_addr);  //write the TX buffer descriptor ptr
   wb_write_register("tx_bd_0", tx_bd);  //write the TX Buffer descriptor
 endtask

 // Method to receive an Ethernet frame from the MAC 
 virtual task receive_frame(ref ethernet_txn txn);
   string s1,s2, s3;
   uvm_sequence_item temp;
   irq_source_register_t irq_source;
   int_mask_register irq_mask;
   tx_bd_t txbd;
   bit error;  // error bit
   int retry_count;
   bit tx_irq;  // flag for valid Tx irq
   wb_txn wb_rd_results;    // for storing results of a wishbone read
     //create transaction object\
   assert($cast(txn, create_item(ethernet_txn::type_id::get(), m_sequencer, "txn")));     
   do begin
     start_item(txn);      // tell sequencer ready to give a transaction item
     m_payload_size = 0; //indicate that it is empty so driver knows to receive this txn not send
     m_payload = new[0]; //resize the m_payload to empty
     txn.set_transaction_id(this.get_transaction_id()); // set transaction_id to parents transaction_id
     txn.init_txn(m_tb_addr, m_MAC_addr, m_payload_size, m_payload);   //initialize transaction item
     finish_item(txn);     // send transaction to mii driver
     get_response(temp);   // get ethernet frame
     temp.set_id_info(txn);  // set transaction and sequence id's
     do begin
       wb_wait_irq();                // wait for interrupt request
       wb_read_register("irq_source_reg", wb_rd_results); //get interrupt source reg
       irq_source = wb_rd_results.data[0][6:0];
       case(1)
       irq_source.txe:  begin // Transmit error?
           error = 1; 
           retry_count++;
           `uvm_info($sformatf("MAC_TX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id),
                           "TXE - Transmit Transmit error\n",UVM_LOW )   
           wb_write_register("irq_source_reg",  7'b0000010);  // clear interrupt bit
           check_Txbd_results();        // check the Tx buffer descriptor status
           initialize_Txbd();
           set_up_mode_reg();
           tx_irq = 1; // this is a valid irq for a Tx frame
         end
       irq_source.txb: begin // Good?
           `uvm_info($sformatf("MAC_TX_FRAME_SEQ_%0d_INTERRUPT",m_mac_id),
                           "TXB - Transmit buffer",UVM_LOW )   
           `uvm_info($sformatf("MAC_TX_FRAME_SEQ_%0d",m_mac_id),
                           "\n-------Ethernet frame successfully Sent by MAC\n",UVM_LOW )
           wb_write_register("irq_source_reg",  7'b0000001);  // clear interrupt bit   
           error = 0;  // clear error in case it is good after a retry
           tx_irq = 1; // this is a valid irq for a Tx frame
         end
       irq_source.rxb || irq_source.rxe || irq_source.busy: 
         #1000 tx_irq = 0; // irq was for a Rx frame
         // Note:  The wb_wait_irq does a level check so until the Rx irq bit is cleared
         // wb_wait_irq will return in about 100nS with the same irq vector. The delay of 1000nS here
         // lengthens that loop so it is not hammering the wishbone bus too hard doing reads of the irq reg
       endcase
     end
     while(!tx_irq);  // loop until a valid Tx frame irq
   end
   while (error && retry_count < 3); //retry if error and not too many errors
   if (retry_count >=3)
     `uvm_error ($sformatf("MAC_TX_FRAME_SEQ_%0d",m_mac_id),
       $sformatf("Rx Error.  Retry count exceeded.  Interrupt status = %b", irq_source,) ) 
   m_parent_agent.mii_tx_seq_ap.write(exp_txn);  // broadcast the expected transaction
   m_parent_sequence.put_response(temp);  //write ethernet frame from MAC to parent sequences response queue
 endtask

 // Method to write payload into WISHBONE slave memory
 virtual task wb_write_payload(int address, logic [7:0] dat[ ]);
   int txn_id; // for storing the transaction_id of generated sequence
   wb_write_seq wr_seq;
   logic[31:0] data[];
   int i,j,sz;
   sz = (dat.size()-2)/4; //get size to transfer in words
   if ((dat.size()-2) % 4) // is there remaining bytes?
     sz++; //if so increase size by one word
   data = new[sz]; //resize data array
   //pack data array starting with dat[2], dat[1:0] sent with the size bytes
   for(i=0, j=2; j<dat.size()-3;i++) begin  
     data[i][31:24] = dat[j++];
     data[i][23:16] = dat[j++];
     data[i][15:08] = dat[j++];
     data[i][07:00] = dat[j++];
    end
   // check to see if word aligned
   case(dat.size() -j) 
     1: // one extra byte
       data[i] = {dat[j], 24'h0};
     2: begin // 2 extra bytes      
          data[i][31:24] = dat[j++];
          data[i][23:00] = {dat[j], 16'h0};
       end
     3: begin //3 extra bytes
          data[i][31:24] = dat[j++];
          data[i][23:16] = dat[j++];
          data[i][15:00] = {dat[j], 8'h0};
        end
   endcase
   assert ($cast(wr_seq, create_item(wb_write_seq::type_id::get(),
                                     m_wb_seqr_handle, "wr_seq")));
   start_item (wr_seq);
   txn_id = m_txn_id++;  // save off transaction_id
   wr_seq.set_transaction_id(txn_id);  //set the transaction_id of sequence
   wr_seq.init_seq(address, data, data.size());  //block write to wishbone
   finish_item(wr_seq);  
 endtask


 // Method to check the transaction status in the MAC
 // Assumes only one buffer descriptor is used for transfers
 task check_Txbd_results();
   string s1;
   tx_bd_t txbd;
   wb_txn wb_rd_results;    // for storing results of a wishbone read

   wb_read_register("tx_bd_0", wb_rd_results);
   txbd = int'(wb_rd_results.data[0]);
   `uvm_info($sformatf("MAC_TX_FRAME_SEQ_%0d",m_mac_id),
       $sformatf("%0d bytes(decimal) received", txbd.len-14),UVM_LOW )
   if(txbd.rdy)          s1 = {s1, " TxBD Ready,"};           
   if(txbd.irq)          s1 = {s1, " IRQ Enable,"};           
   if(txbd.wrap)         s1 = {s1, " Wrap,"};          
   if(txbd.pad_en)       s1 = {s1, " Pad Enable,"};       
   if(txbd.crc_en)       s1 = {s1, " CRC Enable,"};          
   if(txbd.under_run)    s1 = {s1, " Underrun,"};      
   if(txbd.retry)        s1 = {s1, " Retry count nonzero,"};  
   if(txbd.ret_lim)      s1 = {s1, " Retransmission Limit,"};            
   if(txbd.late_col)     s1 = {s1, " Late Collision,"};      
   if(txbd.defer)        s1 = {s1, " Defer,"};     
   if(txbd.c_sense)      s1 = {s1, " Carrier Sense Lost"};
   `uvm_info("MAC_SIMPLE_TxBD", {"TxBD status bits set:\n",s1,"\n"},UVM_LOW )       
 endtask

endclass
`endif
