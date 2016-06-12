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

`ifndef WB_TXN
`define WB_TXN

//----------------------------------------------
  // Wishbone transaction types enumeration
  //typedef enum  {NONE, WRITE, READ, RMW, WAIT_IRQ } wb_txn_t;

class wb_txn extends uvm_sequence_item;
 typedef uvm_object_registry #(wb_txn,"wb_txn") type_id;
 
  wb_txn_t          txn_type;
  rand logic [31:0] adr;
  rand logic [31:0] data [];
  rand int          count;  // number of writes or reads per transaction
  bit [7:0]         byte_sel;
  //wishbone is byte addressable up to 64 bits wide
  // the bits of byte sel are mapped to the 8 possible byte of data
  // and tell which are valid for the transaction


  function new(string name = "wb_txn");
   super.new(name);
   set_byte_sel(); // set byte_sel for the wishbone transaction
   data = new[1]; //init with default size of 1
  endfunction

  function void init_txn(wb_txn_t l_txn_type = NONE,
                        logic [31:0] l_adr = 'x,
                        logic [31:0] l_data[],
                        int cnt = 1
                       );
    txn_type = l_txn_type;
    count = cnt;
    adr  = l_adr;
    data = l_data;
  endfunction
  
  function void set_byte_sel();
  //function sets the byte select bits
    for (int i = 0; i<4; i++)begin
        byte_sel = byte_sel << 1;
        byte_sel++;
    end
  endfunction
  
  function string convert2string();
    string str1;
    
    str1 = {    "-------------------- Start WISHBONE txn --------------------\n",
                "WISHBONE txn \n",
      $sformatf("  txn_type : %s\n", txn_type.name()),
      $sformatf("  adr      : 'h%h\n", adr),
      $sformatf("  count    : 'h%h\n", count),
      $sformatf("  byte_sel : 'h%h\n", byte_sel)};
      if(data.size() < 10)
        foreach(data[i])
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
      else begin
        for(int i = 0; i<5; i++)
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
         str1 = {str1, "    ...\n"};
        for(int i = data.size()-5; i<data.size(); i++)
         str1 = {str1, $sformatf("  data[%0d]: 'h%h\n", i, data[i])};
      end   
    str1 = {str1, "--------------------- End WISHBONE txn ---------------------\n"};
    return(str1);
  endfunction
  
  
  // shallow copy clone for performance
  function uvm_object clone(); 
    wb_txn tmp = new this;
    return(tmp);
  endfunction

  function void do_copy(uvm_object rhs);
   wb_txn rhs_;
   $cast(rhs_, rhs); // cast so can access the fields
   super.do_copy(rhs_);
   adr      = rhs_.adr     ;
   data     = rhs_.data    ;
   count    = rhs_.count   ;
   txn_type = rhs_.txn_type; 
   byte_sel = rhs_.byte_sel; 
  endfunction

  function void do_print(uvm_printer printer);
   if (printer.knobs.sprint)  //is this a sprint() call?
     printer.m_string = convert2string();
   else  // nope a print() call
     $display(convert2string());
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    wb_txn rhs_;
    do_compare = (
      $cast(rhs_, rhs) &&
      super.do_compare(rhs, comparer) &&
      adr      == rhs_.adr    &&
      data     == rhs_.data   &&
      count    == rhs_.count  &&
      data     == rhs_.data   &&
      count    == rhs_.count  
    );
  endfunction

  virtual function void do_pack(uvm_packer packer);
    super.do_pack(packer);
    packer.m_bits[packer.count +: 32] = txn_type;
    packer.count += 32;
    packer.m_bits[packer.count +: 32] = adr;
    packer.count += 8;
    // for array add meta data - size of array
    packer.m_bits[packer.count +: 32] = data.size();
    packer.count += 32;
    foreach (data [index]) begin
      packer.m_bits[packer.count+:32] = data[index];
      packer.count += 32;
    end
    packer.m_bits[packer.count +: 32] = count;
    packer.count += 32;
    packer.m_bits[packer.count +: 8]  = byte_sel;
    packer.count += 8;
  endfunction

  virtual function void do_unpack (uvm_packer packer);
    int sz;
    super.do_unpack(packer);
    txn_type = wb_txn_t'(packer.m_bits[packer.count +: 32]);
    packer.count += 32;
    adr = packer.m_bits[packer.count +: 32];
    packer.count += 32;
    // get size of array
    sz = packer.m_bits[packer.count +: 32];
    packer.count += 32;
    data = new[sz];  // size payload array
    foreach (data [index]) begin
      data[index] = packer.m_bits[packer.count +: 32];
      packer.count += 32;
    end
    count = packer.m_bits[packer.count +: 32];
    packer.count += 32;
    byte_sel = packer.m_bits[packer.count +: 8];
    packer.count += 8;
  endfunction
        
endclass

`endif
