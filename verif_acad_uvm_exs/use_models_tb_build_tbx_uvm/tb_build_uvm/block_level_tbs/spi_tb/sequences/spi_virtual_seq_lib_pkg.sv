package spi_virtual_seq_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_agent_pkg::*;
import spi_agent_pkg::*;
import spi_env_pkg::*;
import spi_bus_sequence_lib_pkg::*;
import spi_sequence_lib_pkg::*;

// Base class to get sub-sequencer handles
class spi_vseq_base extends uvm_sequence #(uvm_sequence_item);

`uvm_object_utils(spi_vseq_base)

function new(string name = "spi_vseq_base");
  super.new(name);
endfunction

// Virtual sequencer handles
apb_sequencer apb;
spi_sequencer spi;
spi_virtual_sequencer vsqr;

// Handle for env config to get to interrupt line
spi_env_config m_cfg;

// This set up is required for child sequences to run
task body;
  assert($cast(vsqr, m_sequencer)) else begin
    `uvm_error("BODY", "Error in $cast of virtual sequencer")
  end
  apb = vsqr.apb;
  spi = vsqr.spi;
  m_cfg = spi_env_config::get_config(m_sequencer);
endtask: body

endclass: spi_vseq_base

class interrupt_test extends spi_vseq_base;

`uvm_object_utils(interrupt_test)

logic[31:0] control;

function new(string name = "interrupt_test");
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

  super.body;

  control = 0;

  repeat(10) begin
    randsequence(START)
      START: SETUP GO WAIT;
      SETUP: rand join LOAD DIV SS SET_CTRL;
      LOAD: {load.start(apb);};
      DIV: {div.start(apb);};
      SS: {ss.start(apb);};
      SET_CTRL: {begin
                   setup.int_enable = 1;
                   setup.start(apb);
                   control = setup.seq_data;
                 end};
      GO: {begin
             go.seq_data = control;
             go.start(apb);
           end};
      WAIT:{fork
              begin
                m_cfg.wait_for_interrupt;
                wait_unload.start(apb);
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
endtask

endclass: interrupt_test

class polling_test extends spi_vseq_base;

`uvm_object_utils(polling_test)

logic[31:0] control;

function new(string name = "polling_test");
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

  super.body;

  control = 0;

  repeat(10) begin
    randsequence(START)
      START: SETUP GO WAIT;
      SETUP: rand join LOAD DIV SS SET_CTRL;
      LOAD: {load.start(apb);};
      DIV: {div.start(apb);};
      SS: {ss.start(apb);};
      SET_CTRL: {begin
                   setup.start(apb);
                   control = setup.seq_data;
                 end};
      GO: {begin
             go.seq_data = control;
             go.start(apb);
           end};
      WAIT:{fork
              wait_unload.start(apb);
              begin
                spi_transfer.BITS = control[6:0];
                spi_transfer.rx_edge = control[9];
                spi_transfer.start(spi);
              end
            join};
    endsequence
  end
endtask

endclass: polling_test

class register_test_vseq extends spi_vseq_base;

`uvm_object_utils(register_test_vseq)

function new(string name = "register_test_vseq");
  super.new(name);
endfunction

task body;
  check_regs_seq reg_seq = check_regs_seq::type_id::create("reg_seq");

  super.body;
  reg_seq.start(apb);
endtask: body


endclass: register_test_vseq

class debug_test extends spi_vseq_base;

`uvm_object_utils(debug_test)

logic[31:0] control;

function new(string name = "debug_test");
  super.new(name);
endfunction

task body;
  // Sequences to be used
  spi_write_seq write = spi_write_seq::type_id::create("write");
  spi_read_seq read = spi_read_seq::type_id::create("read");
  spi_tfer_seq spi_transfer = spi_tfer_seq::type_id::create("spi_transfer");

  super.body;

  control = 0;
  // Divider
  write.reg_name = "spi_reg_file.spi_div";
  write.seq_data = 32'h04;
  write.start(apb);
  // Data
  write.reg_name = "spi_reg_file.spi_data_0";
  write.seq_data = 32'haa55_aa55;
  write.start(apb);
  // Control
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2808;
  write.start(apb);
  // SS
  write.reg_name = "spi_reg_file.spi_ss";
  write.seq_data = 32'h7e;
  write.start(apb);
  // Control - GO
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2908;
  write.start(apb);
  // SPI TFR Seq
  spi_transfer.BITS = 8;
  spi_transfer.rx_edge = 0;
  spi_transfer.start(spi);
  control = 32'h100;
  while(control[8] == 1) begin
    read.reg_name = "spi_reg_file.spi_ctrl";
    read.start(apb);
    control = read.seq_data;
  end

  read.reg_name = "spi_reg_file.spi_data_0";
  read.start(apb);

  // Data
  write.reg_name = "spi_reg_file.spi_data_0";
  write.seq_data = 32'haa55_aa55;
  write.start(apb);
  // Control - GO
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2908;
  write.start(apb);
  // SPI TFR Seq
  spi_transfer.BITS = 8;
  spi_transfer.rx_edge = 0;
  spi_transfer.start(spi);
  control = 32'h100;
  while(control[8] == 1) begin
    read.reg_name = "spi_reg_file.spi_ctrl";
    read.start(apb);
    control = read.seq_data;
  end
  read.reg_name = "spi_reg_file.spi_data_0";
  read.start(apb);

// Now run with MSB first
  // Control
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2008;
  write.start(apb);
  // Data
  write.reg_name = "spi_reg_file.spi_data_0";
  write.seq_data = 32'haa55_aa59;
  write.start(apb);
  // Control - GO
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2108;
  write.start(apb);
  // SPI TFR Seq
  spi_transfer.BITS = 8;
  spi_transfer.rx_edge = 0;
  spi_transfer.start(spi);
  control = 32'h100;
  while(control[8] == 1) begin
    read.reg_name = "spi_reg_file.spi_ctrl";
    read.start(apb);
    control = read.seq_data;
  end
  read.reg_name = "spi_reg_file.spi_data_0";
  read.start(apb);

// Now run with MSB first, TX_NEG
  // Control
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2E08;
  write.start(apb);
  // Data
  write.reg_name = "spi_reg_file.spi_data_0";
  write.seq_data = 32'haa55_aaaa;
  write.start(apb);
  // Control - GO
  write.reg_name = "spi_reg_file.spi_ctrl";
  write.seq_data = 32'h0000_2F08;
  write.start(apb);
  // SPI TFR Seq
  spi_transfer.BITS = 8;
  spi_transfer.rx_edge = 1;
  spi_transfer.start(spi);
  control = 32'h100;
  while(control[8] == 1) begin
    read.reg_name = "spi_reg_file.spi_ctrl";
    read.start(apb);
    control = read.seq_data;
  end
  read.reg_name = "spi_reg_file.spi_data_0";
  read.start(apb);


endtask

endclass: debug_test


endpackage:spi_virtual_seq_lib_pkg
