//------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
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

/* ************************************ */
/* THIS IS AUTOMATICALLY GENERATED CODE */
/* ************************************ */

package mac_register_pkg;

  import uvm_pkg::*;
  import uvm_register_pkg::*;
  
  typedef bit[31:0] bit32_t;

  // Buffer Descriptor fields
  typedef struct packed {
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
  } tx_buffer_descriptor_t;

  typedef struct packed {
    bit [15:0] len;     // Rx BD length 
    bit rdy;            // Rx BD Ready 
    bit irq;            // Rx BD IRQ Enable
    bit wrap;           // Rx BD Wrap (last BD) 
    bit [3:0] reserved; //reserved bit field
    bit c_frame;        // Rx BD Control frame 
    bit miss;           // Rx BD Miss Status 
    bit over_run;       // Rx BD Overrun Status 
    bit inval_symbol;   // Rx BD Invalid Symbol Status 
    bit dn;             // Rx BD Dribble Nibble Status  
    bit too_long;       // Rx BD Too Long Status 
    bit s_frame;        // Rx BD Too Short Frame Status
    bit crc_error;      // Rx BD CRC Error Status 
    bit l_coll;         // Rx BD Late Collision Status 
  } rx_buffer_descriptor_t;

  typedef struct packed {
    bit[14:0] reserved; //reserved bit field   
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
  } moder_register_t; 

  class moder_register extends uvm_register #(moder_register_t);

    covergroup c;
               rec_small: coverpoint data.rec_small; 
                     pad: coverpoint data.pad; 
                 huge_en: coverpoint data.huge_en;
                  crc_en: coverpoint data.crc_en;
         dly_crc_en: coverpoint data.dly_crc_en; 
         rst   : coverpoint data.rst;   
         full_d    : coverpoint data.full_d;   
         ex_defer  : coverpoint data.ex_defer;   
        no_back_off: coverpoint data.no_back_off;
         loop_back : coverpoint data.loop_back;  
         ifg   : coverpoint data.ifg;   
         pro   : coverpoint data.pro;   
         iam   : coverpoint data.iam;   
         bro   : coverpoint data.bro;   
         nopre     : coverpoint data.nopre;   
         txen  : coverpoint data.txen;   
         rxen  : coverpoint data.rxen;
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p);
      super.new(name, p);
      c = new();
      // All bits writable, except the reserved bits.
      WMASK = 32'h01ff;
    endfunction
  endclass

  typedef struct packed {
    bit[24:0] reserved; //reserved bit field   
    bit rxc   ;       // Receive control frame  
    bit txc   ;       // Transmit Control Frame 
    bit busy  ;       // Busy mask 
    bit rxe   ;       // Receive error 
    bit rxb   ;       // receive frame 
    bit txe   ;       // transmit error 
    bit txb   ;       // Transmit buffer   
  } int_source_register_t;

  class int_source_register extends uvm_register #(int_source_register_t);

    covergroup c;
      rxc : coverpoint data.rxc; 
      txc : coverpoint data.txc; 
      busy: coverpoint data.busy;
      rxe : coverpoint data.rxe;
      rxb : coverpoint data.rxb; 
      txe : coverpoint data.txe;   
      txb : coverpoint data.txb;   
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p);
      super.new(name, p);
      c = new(); // instantiate covergroup
      // All bits writable, except the reserved bits.
      WMASK = 32'h007f;
    endfunction
  endclass

  typedef struct packed {  
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
  } int_mask_register_t;

  class int_mask_register extends uvm_register #(int_mask_register_t);

    covergroup c;
              rxc_m : coverpoint data.rxc_m; 
              txc_m : coverpoint data.txc_m; 
              busy_m: coverpoint data.busy_m;
              rxe_m : coverpoint data.rxe_m;
         rxb_m : coverpoint data.rxb_m; 
         txe_m : coverpoint data.txe_m;   
         txb_m : coverpoint data.txb_m;   
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p, bit32_t resetVal = 0);
      super.new(name, p, resetVal);
      c = new();
      // All bits writable, except the reserved bits.
      WMASK = 32'h007f;
    endfunction
  endclass

  typedef struct packed {  
  // if bit is "0" the event is masked
  // if bit is "1" the interrupt is enabled
  // reset value is 0 on all bits
    bit[24:0] reserved; //reserved bit field   
    bit [6:0] ipgt;     // Back to Back Inter Packet Gap 
  } ipgt_register_t;

  class ipgt_register extends uvm_register #(ipgt_register_t);

    covergroup c;
              ipgt : coverpoint data.ipgt; 
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p, bit32_t resetVal = 0);
      super.new(name, p, resetVal);
      c = new();
      // All bits writable, except the reserved bits.
      WMASK = 32'h007f;
    endfunction
  endclass

  typedef struct packed {  
  // if bit is "0" the event is masked
  // if bit is "1" the interrupt is enabled
  // reset value is 0 on all bits
    bit[24:0] reserved; //reserved bit field   
    bit [6:0] ipgr1;     // Non Back to Back Inter Packet Gap 1 
  } ipgr1_register_t;

  class ipgr1_register extends uvm_register #(ipgr1_register_t);

    covergroup c;
              ipgr1 : coverpoint data.ipgr1; 
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p, bit32_t resetVal = 0);
      super.new(name, p, resetVal);
      c = new();
      // All bits writable, except the reserved bits.
      WMASK = 32'h007f;
    endfunction
  endclass

  typedef struct packed {  
  // if bit is "0" the event is masked
  // if bit is "1" the interrupt is enabled
  // reset value is 0 on all bits
    bit[24:0] reserved; //reserved bit field   
    bit [6:0] ipgr2;     // Non Back to Back Inter Packet Gap 2
  } ipgr2_register_t;

  class ipgr2_register extends uvm_register #(ipgr2_register_t);

    covergroup c;
              ipgr2 : coverpoint data.ipgr2; 
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p);
      super.new(name, p);
      c = new();
      // All bits writable, except the reserved bits.
      WMASK = 32'h007f;
    endfunction
  endclass

  typedef struct packed {  
  // if bit is "0" the event is masked
  // if bit is "1" the interrupt is enabled
  // reset value is 0 on all bits
    bit [15:0] minfl; //Minimum Frame Length  
    bit [15:0] maxfl; // Maximum Frame Length
  } packetlen_register_t;

  class packetlen_register extends uvm_register #(packetlen_register_t);

    covergroup c;
              minfl : coverpoint data.minfl; 
              maxfl : coverpoint data.maxfl; 
    endgroup

    function void sample();
      c.sample();
    endfunction

    function new(string name, uvm_named_object p, bit32_t resetVal = 0);
      super.new(name, p, resetVal);
      c = new();
      // All bits writable
      WMASK = 32'hffff;
    endfunction
  endclass

  class mac_register_file extends uvm_register_file;
    // declare registers
    rand moder_register      moder_reg;
    rand int_source_register int_source_reg;
    rand int_mask_register   int_mask_reg;
    rand ipgt_register       ipgt_reg;
    rand ipgr1_register      ipgr1_reg;
    rand ipgr2_register      ipgr2_reg;
    rand packetlen_register  packetlen_reg;

    function new(string name, uvm_named_object p);
      super.new(name, p);
    endfunction

    function void build_phase(uvm_phase phase);
      uvm_report_info("eth_register_file", "build()");
      super.build_phase(phase);

      // -----------------------
      // Construct the registers
      // -----------------------
      moder_reg       = new("MODER",      this, 'h0000a000);
      int_source_reg  = new("INT_SOURCE", this, 'h00000000);
      int_mask_reg    = new("INT_MASK",   this, 'h00000000);
      ipgt_reg        = new("IPGT",       this, 'h00000012);
      ipgr1_reg       = new("IPGR1",      this, 'h0000000c);
      ipgr2_reg       = new("IPGR2",      this, 'h00000012);
      packetlen_reg   = new("PACKETLEN",  this, 'h00400600);

      // --------------------------------------
      // Add the registers to the register file
      // --------------------------------------
      add_register(moder_reg.get_name(),     'h00, moder_reg);
      add_register(int_source_reg.get_name(),'h04, int_source_reg);
      add_register(int_mask_reg.get_name(),  'h08, int_mask_reg);
      add_register(ipgt_reg.get_name(),      'h0C, ipgt_reg);
      add_register(ipgr1_reg.get_name(),     'h10, ipgr1_reg);
      add_register(ipgr2_reg.get_name(),     'h14, ipgr2_reg);
      add_register(packetlen_reg.get_name(), 'h18, packetlen_reg);
    endfunction
  endclass

  //
  // The actual register map for this system.
  //
  class wb_register_map extends uvm_register_map;
    rand mac_register_file mac_0;

    function new(string name, uvm_named_object p);
      super.new(name, p);
    endfunction

    function void build_phase(uvm_phase phase);
      uvm_report_info("wb_register_map", "build()");
      super.build_phase(phase);

      mac_0 = new("mac_0", this);

      mac_0.build(); 

      add_register_file(mac_0, 'h00100000);
    endfunction
  endclass

  //
  // A class to automatically load a register map.
  //
  class register_map_auto_load;

    // Triggers factory registration of this default
    //  sequence. Can be overriden by the user using
    //  "default_auto_register_test".
//    register_sequence_all_registers
//      #(uvm_register_transaction, 
//        uvm_register_transaction) dummy;

    static bit loaded = build_register_map();

    static function bit build_register_map();

      wb_register_map register_map;

      register_map = new("register_map", null);

      register_map.build();
      register_map.reset();

      uvm_config_db #(uvm_register_map)::set(null, "*",
                                             "register_map", register_map);
      return 1;
    endfunction

  endclass
endpackage
