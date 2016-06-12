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

class spi_interrupt_vseq extends pss_vseq_base;

`uvm_object_utils(spi_interrupt_vseq)

logic[31:0] control;

function new(string name = "spi_interrupt_vseq");
  super.new(name);
endfunction

task body;
  // Sequences to be used
  data_load_seq load = data_load_seq::type_id::create("load");
  div_load_seq div = div_load_seq::type_id::create("div");
  ctrl_set_seq setup = ctrl_set_seq::type_id::create("setup");
  ctrl_go_seq go = ctrl_go_seq::type_id::create("go");
  slave_select_seq ss = slave_select_seq::type_id::create("ss");
  tfer_over_by_poll_seq wait_unload = tfer_over_by_poll_seq::type_id::create("wait_unload");
  spi_tfer_seq spi_transfer = spi_tfer_seq::type_id::create("spi_transfer");
  ahb_write_seq ahb_write = ahb_write_seq::type_id::create("ahb_write");
  ahb_read_seq ahb_read = ahb_read_seq::type_id::create("ahb_read");

  super.body();

  control = 0;

  // Set up the interrupt controller for the SPI interrupts
  ahb_write.addr = 32'h200;
  ahb_write.data = 32'h1;
  ahb_write.start(ahb);

  repeat(10) begin
    randsequence(START)
      START: SETUP GO WAIT;
      SETUP: rand join LOAD DIV SS SET_CTRL;
      LOAD: {load.start(ahb);};
      DIV: {div.start(ahb);};
      SS: {ss.start(ahb);};
      SET_CTRL: {begin
                   setup.int_enable = 1;
                   setup.start(ahb);
                   control = setup.seq_data;
                 end};
      GO: {begin
             go.seq_data = control;
             go.start(ahb);
           end};
      WAIT:{fork
              begin
                m_cfg.wait_for_interrupt;
                // Read and clear the interrupt
                ahb_read.addr = 32'h204;
                ahb_read.start(ahb);
                wait_unload.start(ahb);
                if(!m_cfg.is_interrupt_cleared()) begin
                  `uvm_error("INT_ERROR", "Interrupt not cleared by register read/write");
                end
              end
              begin
                spi_transfer.BITS = control[6:0];
                spi_transfer.rx_edge = control[9];
                spi_transfer.start(spi);
              end
            join};
    endsequence
  end
endtask:body

endclass: spi_interrupt_vseq