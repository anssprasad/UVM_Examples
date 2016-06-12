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


package mac_info_pkg;

// MAC address offsets from 
// Wishbone base address of MAC
// Used in the testbench
// See eth_speci.pdf for details

//Buffer Descripter address offsets
const int unsigned Tx_buf_base_off = 32'h00000000;
const int unsigned Rx_buf_base_off = 32'h00008000;
const int unsigned Tx_bd_base_off  = 32'h00000400;
const int unsigned Rx_bd_base_off  = 32'h00000600;

// Buffer Descriptor fields

/*
typedef struct packed{
  bit [15:0] len;     // Tx BD length 
  bit rdy;            // Tx BD Ready 
  bit irq;            // Tx BD IRQ Enable
  bit wrap;           // Tx BD Wrap (last BD) 
  bit pad_en;         // Tx BD Pad Enable 
  bit crc_en;         // Tx BD CRC Enable
  bit [1:0] reserved; //reserved bit field
  bit under_run;      // Tx BD Underrun Status 
  bit [3:0] retry;    // Tx BD Retry Status 
  bit ret_lim;        // Tx BD Retransmission Limit Status 
  bit late_col;       // Tx BD Late Collision Status 
  bit defer;          // Tx BD Defer Status 
  bit c_sense;        // Tx BD Carrier Sense Lost Status 
} Tx_buffer_descriptor_t;
*/

/*
typedef struct packed {
  bit [15:0] len;     // Rx BD length 
  bit rdy;            // Rx BD Ready 
  bit irq;            // Rx BD IRQ Enable
  bit wrap;           // Rx BD Wrap (last BD) 
  bit [3:0] reserved; // reserved bit field
  bit c_frame;        // Rx BD Control frame 
  bit miss;           // Rx BD Miss Status 
  bit over_run;       // Rx BD Overrun Status 
  bit inval_symbol;   // Rx BD Invalid Symbol Status 
  bit dn;             // Rx BD Dribble Nibble Status  
  bit too_long;       // Rx BD Too Long Status 
  bit s_frame;        // Rx BD Too Short Frame Status
  bit crc_error;      // Rx BD CRC Error Status 
  bit l_coll;         // Rx BD Late Collision Status 
} Rx_buffer_descriptor;
*/

// Register address offsets
const int unsigned mode_reg_offset       = 32'h00; // Mode Register 
const int unsigned int_source_offset     = 32'h04; // Interrupt Source Register 
const int unsigned int_mask_offset       = 32'h08; // Interrupt Mask Register 
const int unsigned ipgt_offset           = 32'h0C; // Back to Bak Inter Packet Gap Register 
const int unsigned ipgr1_offset          = 32'h10; // Non Back to Back Inter Packet Gap Register 1
const int unsigned ipgr2_offset          = 32'h14; // Non Back to Back Inter Packet Gap Register 2
const int unsigned packetlen_offset      = 32'h18; // Packet Length Register (min. and max.) 
const int unsigned collconf_offset       = 32'h1C; // Collision and Retry Configuration Register 
const int unsigned tx_bd_num_offset      = 32'h20; // Transmit Buffer Descriptor Number Register 
const int unsigned ctrlmoder_offset      = 32'h24; // Control Module Mode Register 
const int unsigned miimoder_offset       = 32'h28; // MII Mode Register 
const int unsigned miicommand_offset     = 32'h2C; // MII Command Register 
const int unsigned miiaddress_offset     = 32'h30; // MII Address Register 
const int unsigned miiTx_data_offset     = 32'h34; // MII Transmit Data Register 
const int unsigned miiRx_data_offset     = 32'h38; // MII Receive Data Register 
const int unsigned miistatus_offset      = 32'h3C; // MII Status Register 
const int unsigned mac_addr0_offset      = 32'h40; // MAC Individual Address Register 0 
const int unsigned mac_addr1_offset      = 32'h44; // MAC Individual Address Register 1 
const int unsigned eth_hash0_adr_offset  = 32'h48; // Hash Register 0 
const int unsigned eth_hash1_adr_offset  = 32'h4C; // Hash Register 1 
const int unsigned eth_Txctrl_offset     = 32'h50; // Tx Control Register 
                                            
                               
//Register fields   

/*
typedef struct packed{
  bit[14:0] reserved; // reserved bit field   
  bit rec_small;      // Receive Small 
  bit pad;            // Pad Enable 
  bit huge_en;        // Huge Enable 
  bit crc_en;         // CRC Enable 
  bit dly_crc_en;     // Delayed CRC Enable 
  bit rst     ;       // Reset MAC 
  bit full_d  ;       // Full Duplex 
  bit ex_defer;       // Excess Defer 
  bit no_back_off;    // No Backoff 
  bit loop_back;      // Loop Back 
  bit ifg     ;       // Min. IFG not required 
  bit pro     ;       // Promiscuous (receive all)
  bit iam     ;       // Use Individual Hash 
  bit bro     ;       // Reject Broadcast
  bit nopre   ;       // No Preamble 
  bit txen    ;       // Transmit Enable 
  bit rxen    ;       // Receive Enable  
} mode_register; 

typedef struct packed{  
// if bit is "0" the event is masked
// if bit is "1" the interrupt is enabled
// reset value is 0 on all bits
  bit[24:0] reserved; //reserved bit field   
  bit rxc_m   ;       // Receive control frame mask 
  bit txc_m   ;       // Transmit Control Frame mask
  bit busy_m  ;       // Busy mask 
  bit rxe_m   ;       // Receive error mask
  bit rxb_m   ;       // receive frame mask
  bit txe_m   ;       // transmit error mask
  bit txb_m   ;       // Transmit buffer mask  
} int_mask_register;

typedef struct packed{
  bit rxc   ;       //   
  bit txc   ;       //   
  bit busy  ;       // 
  bit rxe   ;       // 
  bit rxb   ;       // 
  bit txe   ;       // 
  bit txb   ;       //
} irq_source_register;
*/

endpackage
