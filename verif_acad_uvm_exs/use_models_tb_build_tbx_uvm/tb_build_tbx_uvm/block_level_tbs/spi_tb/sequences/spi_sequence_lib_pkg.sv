package spi_sequence_lib_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import spi_agent_pkg::*;

class spi_tfer_seq extends uvm_sequence #(spi_seq_item);

`uvm_object_utils(spi_tfer_seq)

function new(string name = "spi_tfer_seq");
  super.new(name);
endfunction

rand logic[6:0] BITS;
rand logic rx_edge;

task body;
  spi_seq_item req = spi_seq_item::type_id::create("req");

  start_item(req);
  assert(req.randomize() with {no_bits == BITS; RX_NEG == rx_edge;});
  finish_item(req);

endtask:body

endclass: spi_tfer_seq

endpackage: spi_sequence_lib_pkg
