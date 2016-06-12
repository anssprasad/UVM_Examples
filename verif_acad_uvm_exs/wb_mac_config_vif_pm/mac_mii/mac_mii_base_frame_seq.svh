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

`ifndef WB_MEM_MAP_ACCESS_BASE_SEQ
`define WB_MEM_MAP_ACCESS_BASE_SEQ

// Base class for sequences that will communicate with 
// the WISHBONE bus throught the wishbone agent
// Contains common methods and properties
// Mike Baird
//----------------------------------------------

virtual class wb_mem_map_access_base_seq extends uvm_sequence;
 `uvm_object_utils (wb_mem_map_access_base_seq)

 bit [47:0] m_MAC_addr;              // Ethernet address of MAC
 int m_mac_id;                       // id of MAC this sequence will interact with
 rand bit [15:0] m_payload_size;     // number of byte in payload
 rand logic [7:0]  m_payload [];     // payload data for frame
 int unsigned m_s_mem_wb_base_addr;  // wishbone base address of wb memory for MAC frame buffers
 int m_txn_id = 1;
 uvm_sequencer #(wb_txn, wb_txn) m_wb_seqr_handle; //handle to wb sequencer for wb master agent

 uvm_register_map m_register_map;

 function new(string name = "");
   super.new(name);
   m_register_map = get_register_map();
 endfunction

 // Write a single word to the WISHBONE bus
 virtual task wb_write(int address, logic [31:0] dat);
  int txn_id; // for storing the transaction_id of generated sequence
  wb_write_seq wr_seq = wb_write_seq::type_id::create("wr_seq");
  logic [31:0] data[1];
  data[0] = dat;
  txn_id = m_txn_id++;  // save off transaction_id
  wr_seq.set_transaction_id(txn_id);  //set the transaction_id of sequence
  wr_seq.init_seq(address, data);
  wr_seq.set_parent_sequence(this);
  wr_seq.start(m_wb_seqr_handle);  
 endtask

 // Write a single word to the WISHBONE bus based on the register name
 virtual task wb_write_register(input string name, logic [31:0] dat);
  wb_write(get_address(name), dat);
 endtask

 // Method to do either a single or block WISHBONE bus read
 virtual task wb_read(input int address = 0, output wb_txn results,
                      input int count = 1);
   int txn_id; // for storing the transaction_id of generated sequence
   wb_read_seq rd_seq = wb_read_seq::type_id::create("rd_seq");
   uvm_sequence_item temp_seq_item;

   txn_id = m_txn_id++;  // save off transaction_id
   rd_seq.set_transaction_id(txn_id);  //set the transaction_id of sequence
   rd_seq.init_seq(address, count);
   rd_seq.set_parent_sequence(this);
   rd_seq.start(m_wb_seqr_handle);
   get_response(temp_seq_item, txn_id); // get the return response
   $cast(results,temp_seq_item);
 endtask

 // Method to do either a single or block WISHBONE bus read
 virtual task wb_read_register(input string name, output wb_txn results);
   wb_read(get_address(name), results);
 endtask

 // Method to wait for a WISHBONE interrupt request
 virtual task wb_wait_irq();
   int txn_id; // for storing the transaction_id of generated sequence
   wb_wait_irq_seq wait_irq_seq = wb_wait_irq_seq::type_id::create("wait_irq_seq");
   uvm_sequence_item temp_seq_item;
   txn_id = m_txn_id++;  // save off transaction_id
   wait_irq_seq.set_transaction_id(txn_id);  //set the transaction_id of sequence
   wait_irq_seq.set_parent_sequence(this);
   wait_irq_seq.start(m_wb_seqr_handle);
   get_response(temp_seq_item, txn_id); // get the return response
 endtask

 //--------------------------------------------------------------------
 // get_register_map
 //--------------------------------------------------------------------   
 function uvm_register_map get_register_map();
   uvm_object t;

   if( m_register_map == null ) begin // get it from the sequencer
     if( !m_sequencer.get_config_object( "register_map" , t , 0  ) ) begin
       m_sequencer.uvm_report_fatal(get_name(),"no config object for register_map");
     end
     if(!$cast( m_register_map , t ) ) begin
        m_sequencer.uvm_report_fatal("type mismatch" , $psprintf("%s is not of type register map" , t.sprint() ) );    
     end
   end

   return m_register_map;
 endfunction

  //--------------------------------------------------------------------
  // get_address - Gets address based on register name
  //--------------------------------------------------------------------   
  function address_t get_address( string name );
    bit valid;
    address_t address;
    uvm_register_map map = get_register_map();
  
//    address = map.lookup_register_address_by_name( name , valid );
    address = map.lookup_register_address_by_name( {map.get_name(), ".mac_0_regs.", name}, valid );

    if( !valid ) begin
      uvm_report_error( get_name() , $psprintf("%s has no address in the register map", name ) );
    end
  
    return address;
  endfunction

endclass
`endif //MAC_MII_BASE_FRAME_SEQ
