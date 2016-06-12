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

`ifndef MII_TX_DRIVER
`define MII_TX_DRIVER

// wishbone master point to point driver
// Mike Baird
//----------------------------------------------
class mii_tx_driver extends uvm_driver #(ethernet_txn,ethernet_txn);
`uvm_component_utils(mii_tx_driver)

  uvm_analysis_port #(ethernet_txn) mii_tx_drv_ap;

  virtual mii_if m_v_miim_if;
  mii_config m_config;

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mii_tx_drv_ap = new("mii_tx_drv_ap", this);
    if(!uvm_config_db #(mii_config)::get(this, "", "mii_config", m_config)) begin
      `uvm_error("build_phase", "unable to get mii_config from configuration database")
    end
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_v_miim_if   = v_miim_if;  // set to global virtual interface
  endfunction
  
  task run_phase(uvm_phase phase);
    ethernet_txn txn;
    ethernet_txn sb_txn;
    forever begin    
      seq_item_port.get(txn);       // get transaction
      get_frame(txn);               // receive txn from MAC
      $cast(sb_txn, txn.clone());   // make a copy of the txn
      mii_tx_drv_ap.write(sb_txn);  // broadcast received txn 
      seq_item_port.put(txn);    // return transaction
    end
  endtask
   
  //task to receive a frame from the MAC
  task get_frame(ref ethernet_txn txn);
    bit[31:0] crc32 = 32'hffffffff;  //init CRC
    logic[31:0] crc_received =0;  //crc from MAC
    logic[7:0] temp_byte; // for assembling nibbles to bytes
    `uvm_info("MII_TX_DRIVER","get_frame waiting for Tx to start",UVM_LOW )
    wait(m_v_miim_if.MTxEn);    // wait for transmission to start
    #1 m_v_miim_if.MCrs = 1;    // set carrier sense 
    
    `uvm_info("MII_TX_DRIVER", "Tx Preamble",UVM_LOW )
    for(int i=0; i<14; i++) begin  // preamble
      @(posedge m_v_miim_if.mtx_clk)
        if(m_v_miim_if.MTxD != 5) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in Preamble" )
          return;
        end
    end
    
    `uvm_info("MII_TX_DRIVER", "Tx SFD",UVM_LOW )
    @(posedge m_v_miim_if.mtx_clk)  // SFD
      if(m_v_miim_if.MTxD != 5 && m_v_miim_if.MTxEn) begin
        `uvm_error("MII_TX_DRIVER", "MTxEn Error in SFD" )
        return;
      end
    @(posedge m_v_miim_if.mtx_clk && m_v_miim_if.MTxEn)
      if(m_v_miim_if.MTxD != 4'hd && m_v_miim_if.MTxEn) begin
        `uvm_error("MII_TX_DRIVER", "MTxEn Error in SFD" )
        return;
      end
    
    `uvm_info("MII_TX_DRIVER", "Tx Dest MAC addr",UVM_LOW )
    for(int i=47; i>0; i-=8)  begin         // Dest_addr (Dest MAC addr)
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in Dest Addr" )
          return;
        end
        txn.dest_addr[(i-4)-:4] =  m_v_miim_if.MTxD;    //low nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in Dest Addr" )
          return;
        end
        txn.dest_addr[i-:4] =  m_v_miim_if.MTxD;        //high nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
    end

    `uvm_info("MII_TX_DRIVER", "Tx Source MAC addr",UVM_LOW )
    for(int i=47; i>0; i-=8)  begin         // srce_addr (Source MAC addr)
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in Source Addr" )
          return;
        end
        txn.srce_addr[(i-4)-:4] = m_v_miim_if.MTxD;     //low nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in Source Addr" )
          return;
        end
        txn.srce_addr[i-:4] = m_v_miim_if.MTxD;         //high nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
    end

    `uvm_info("MII_TX_DRIVER", "Tx length",UVM_LOW )
    for(int i=15; i>0; i-=8)  begin         // length
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in length" )
          return;
        end
        txn.payload_size[(i-4)-:4] = m_v_miim_if.MTxD;     //low nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in length" )
          return;
        end
        txn.payload_size[i-:4] = m_v_miim_if.MTxD;         //high nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
    end

    `uvm_info("MII_TX_DRIVER", "Tx Payload",UVM_LOW )
    txn.payload = new[txn.payload_size];  // resize payload
    for(int i=0; i<txn.payload_size; i++)  begin  // Payload
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in payload" )
          return;
        end
        txn.payload[i][3:0] = m_v_miim_if.MTxD;                //low nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in payload" )
          return;
        end
        txn.payload[i][7:4] = m_v_miim_if.MTxD;                //high nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
    end

   // Note:  Continue to caculate crc on the received crc
   // this will result in the "magic number" for the crc-32 polynomial
   // the crc was "inverted" on the other end before being appended
   // to the frame.  See how the inversion is done in the send_frame method 
   `uvm_info("MII_TX_DRIVER", "Tx CRC",UVM_LOW )
    for(int i=31; i>0; i-=8)  begin        // CRC
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in CRC" )
          return;
        end
        crc_received[(i-4)-:4] = m_v_miim_if.MTxD;         //low nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
      @(posedge m_v_miim_if.mtx_clk)
        if(!m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn Error in CrC" )
          return;
        end
        crc_received[i-:4] = m_v_miim_if.MTxD;            //high nibble
        crc32 = gen_crc(crc32,m_v_miim_if.MTxD);
    end
      @(posedge m_v_miim_if.mtx_clk)
        if(m_v_miim_if.MTxEn) begin
          `uvm_error("MII_TX_DRIVER", "MTxEn error" )
          return;
        end
        else
          #1 m_v_miim_if.MCrs = 1;    // clear carrier sense 

    //check crc against the "magic number" for the crc-32 polynomial
    txn.crc = crc_received;
    if(crc32 != 32'hc704dd7b)  //crc == magic number?
      `uvm_error("MII_TX_DRIVER","CRC error on received packet from MAC" )
  endtask
  
  function int gen_crc (int unsigned Crc, bit[3:0]nibble);
    int unsigned CrcNext;
    bit [3:0] Data ; //= nibble;
    Data[0] = nibble[3];
    Data[1] = nibble[2];
    Data[2] = nibble[1];
    Data[3] = nibble[0];
    CrcNext[0] = (Data[0] ^ Crc[28]); 
    CrcNext[1] = (Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29]); 
    CrcNext[2] = (Data[2] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^
                  Crc[30]); 
    CrcNext[3] = (Data[3] ^ Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30] ^
                  Crc[31]); 
    CrcNext[4] = ((Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^
                  Crc[31])) ^ Crc[0]; 
    CrcNext[5] = ((Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^
                  Crc[31])) ^ Crc[1]; 
    CrcNext[6] = ((Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30])) ^ Crc[ 2]; 
    CrcNext[7] = ((Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^
                  Crc[31])) ^ Crc[3]; 
    CrcNext[8] = ((Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^
                  Crc[31])) ^ Crc[4]; 
    CrcNext[9] = ((Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30])) ^ Crc[5]; 
    CrcNext[10] = ((Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^
                   Crc[31])) ^ Crc[6]; 
    CrcNext[11] = ((Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^
                   Crc[31])) ^ Crc[7]; 
    CrcNext[12] = ((Data[2] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^
                   Crc[30])) ^ Crc[8]; 
    CrcNext[13] = ((Data[3] ^ Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30] ^
                   Crc[31])) ^ Crc[9]; 
    CrcNext[14] = ((Data[3] ^ Data[2] ^ Crc[30] ^ Crc[31])) ^ Crc[10]; 
    CrcNext[15] = ((Data[3] ^ Crc[31])) ^ Crc[11]; 
    CrcNext[16] = ((Data[0] ^ Crc[28])) ^ Crc[12]; 
    CrcNext[17] = ((Data[1] ^ Crc[29])) ^ Crc[13]; 
    CrcNext[18] = ((Data[2] ^ Crc[30])) ^ Crc[14]; 
    CrcNext[19] = ((Data[3] ^ Crc[31])) ^ Crc[15]; 
    CrcNext[20] = Crc[16]; 
    CrcNext[21] = Crc[17]; 
    CrcNext[22] = ((Data[0] ^ Crc[28])) ^ Crc[18]; 
    CrcNext[23] = ((Data[1] ^ Data[0] ^ Crc[29] ^ Crc[28])) ^ Crc[19]; 
    CrcNext[24] = ((Data[2] ^ Data[1] ^ Crc[30] ^ Crc[29])) ^ Crc[20]; 
    CrcNext[25] = ((Data[3] ^ Data[2] ^ Crc[31] ^ Crc[30])) ^ Crc[21]; 
    CrcNext[26] = ((Data[3] ^ Data[0] ^ Crc[31] ^ Crc[28])) ^ Crc[22]; 
    CrcNext[27] = ((Data[1] ^ Crc[29])) ^ Crc[23]; 
    CrcNext[28] = ((Data[2] ^ Crc[30])) ^ Crc[24]; 
    CrcNext[29] = ((Data[3] ^ Crc[31])) ^ Crc[25]; 
    CrcNext[30] = Crc[26]; 
    CrcNext[31] = Crc[27]; 
    return(CrcNext);  			 
  endfunction
endclass
`endif
