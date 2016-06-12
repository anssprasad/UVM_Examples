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

class spi_scoreboard extends uvm_component;

`uvm_component_utils(spi_scoreboard)

uvm_tlm_analysis_fifo #(apb_seq_item) apb;
uvm_tlm_analysis_fifo #(spi_seq_item) spi; // Both mosi & miso come in together

// Handle - where the env passes a reference
uvm_register_map spi_rm;

// Data buffers:
logic[31:0] mosi[3:0];
logic[31:0] miso[3:0];
logic[127:0] mosi_regs = 0;
// Bit count:
logic[6:0] bit_cnt;
//
// Statistics:
//
int no_transfers;
int no_tx_errors;
int no_cs_errors;

function new(string name = "", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  apb = new("apb", this);
  spi = new("miso", this);
endfunction: build_phase

// What this scoreboard does:
//
// Tracks APB accesses and updates the registers model when it sees
// a write to one of the registers - this allows the SPI monitor to keep
// in step with the current programming state - via a linked config object
//
// Tracks reads from non-volatile SPI registers to make sure that they
// return the right values
//
// When it sees the control GO bit written it copies the current state
// of the data registers into a buffer for comparison against the character
// transmitted by the SPI interface on the MOSI pin
//
// When it receives a MISO transaction it stores the value in a buffer to
// to check that the correct value is read back

task run_phase(uvm_phase phase);
  no_transfers = 0;
  no_tx_errors = 0;
  no_cs_errors = 0;

  fork
    track_apb;
    track_spi;
  join
endtask: run_phase

task track_apb;
  apb_seq_item apb_txn;
  bytearray_t data;
  uvm_register_base register;

  forever begin
    apb.get(apb_txn);
    data = '{apb_txn.data[7:0], apb_txn.data[15:8], apb_txn.data[23:16], apb_txn.data[31:24]};
    if(apb_txn.we == 1) begin
      register = spi_rm.lookup_register_by_address(apb_txn.addr);
      register.bus_write(data);
      case(apb_txn.addr[4:0])
       5'h0: mosi_regs[31:0] = apb_txn.data;
       5'h4: mosi_regs[63:32] = apb_txn.data;
       5'h8: mosi_regs[95:64] = apb_txn.data;
       5'hc: mosi_regs[127:96] = apb_txn.data;
      endcase
    end
    else begin
      spi_rm.bus_read(data, address_t'(apb_txn.addr)); // Check against register model
    end

  end
endtask: track_apb

task track_spi;
  spi_seq_item item;
  spi_rw spi_data_0;
  spi_rw spi_data_1;
  spi_rw spi_data_2;
  spi_rw spi_data_3;
  spi_ctrl spi_control;
  spi_ss spi_cs;

  logic[127:0] tx_data;
  logic[127:0] mosi_data;
  logic[127:0] miso_data;
  logic[127:0] rev_miso;
  logic[127:0] bit_mask;

  bit error;


  assert($cast(spi_data_0, spi_rm.lookup_register_by_name("spi_reg_file.spi_data_0")));
  assert($cast(spi_data_1, spi_rm.lookup_register_by_name("spi_reg_file.spi_data_1")));
  assert($cast(spi_data_2, spi_rm.lookup_register_by_name("spi_reg_file.spi_data_2")));
  assert($cast(spi_data_3, spi_rm.lookup_register_by_name("spi_reg_file.spi_data_3")));
  assert($cast(spi_control, spi_rm.lookup_register_by_name("spi_reg_file.spi_ctrl")));
  assert($cast(spi_cs, spi_rm.lookup_register_by_name("spi_reg_file.spi_ss")));


  forever begin
    error = 0;
    spi.get(item);
    no_transfers++;
    bit_cnt = spi_control.data.CHAR_LEN;
    // Corner case for bit count equal to zero:
    if(bit_cnt == 0) begin
      bit_cnt = 128;
    end
    // Deal with the mosi data (TX)
    tx_data[31:0] = spi_data_0.data;
    tx_data[63:32] = spi_data_1.data;
    tx_data[95:64] = spi_data_2.data;
    tx_data[127:96] = spi_data_3.data;


    // Fix the data comparison mask for the number of bits
    bit_mask = 0;
    for(int i = 0; i < bit_cnt; i++) begin
      bit_mask[i] = 1;
    end

    spi_data_0.compareMask = bit_mask[31:0];
    spi_data_1.compareMask = bit_mask[63:32];
    spi_data_2.compareMask = bit_mask[95:64];
    spi_data_3.compareMask = bit_mask[127:96];

    if(spi_control.data.TX_NEG == 1) begin
      mosi_data = item.nedge_mosi; // To be compared against write data
    end
    else begin
      mosi_data = item.pedge_mosi;
    end
    if(spi_control.data.LSB == 1) begin
      for(int i = 0; i < bit_cnt; i++) begin
        if(tx_data[i] != mosi_data[i]) begin
          error = 1;
        end
      end
      if(error == 1) begin
        `uvm_error("SPI_SB_MOSI_LSB:", $sformatf("Expected mosi value %0h actual %0h", tx_data, mosi_data))
      end
    end
    else begin
      for(int i = 0; i < bit_cnt; i++) begin
        if(tx_data[i] != mosi_data[(bit_cnt-1) - i]) begin
          error = 1;
        end
      end
      if(error == 1) begin // Need to reverse the mosi_data bits
        rev_miso = 0;
        for(int i = 0; i < bit_cnt; i++) begin
          rev_miso[(bit_cnt-1) - i] = mosi_data[i];
        end
        `uvm_error("SPI_SB_MOSI_MSB:", $sformatf("Expected mosi value %0h actual %0h", tx_data, rev_miso))
      end
    end
    if(error == 1)
      no_tx_errors++;

    // Check the miso data (RX)
    if(spi_control.data.RX_NEG == 1) begin
      miso_data = item.pedge_miso;
    end
    else begin
      miso_data = item.nedge_miso;
    end
    if(spi_control.data.LSB == 0) begin
      // reverse the bits lsb -> msb, and so on
      rev_miso = 0;
      for(int i = 0; i < bit_cnt; i++) begin
        rev_miso[(bit_cnt-1) - i] = miso_data[i];
      end
      miso_data = rev_miso;
    end

    spi_data_0.data = miso_data[31:0];
    spi_data_1.data = miso_data[63:32];
    spi_data_2.data = miso_data[95:64];
    spi_data_3.data = miso_data[127:96];  // These will be checked on read-back

    // Check the chip select lines
    if(spi_cs.data.SS != ~item.cs) begin
      `uvm_error("SPI_SB_CS:", $sformatf("Expected cs value %b actual %b", spi_cs.data.SS, ~item.cs))
      no_cs_errors++;
    end
  end

endtask: track_spi

function void report_phase(uvm_phase phase);

  if((no_cs_errors == 0) && (no_tx_errors == 0)) begin
    `uvm_info("SPI_SB_REPORT:", $sformatf("Test Passed - %0d transfers occured with no errors", no_transfers), UVM_LOW)
    `uvm_info("___PASSED TESTCASE___:", $sformatf("Test Passed - %0d transfers occured with no errors", no_transfers), UVM_LOW)
  end
  if(no_tx_errors > 0) begin
    `uvm_error("SPI_SB_REPORT:", $sformatf("Test Failed - %0d TX errors occured during %0d transfers", no_tx_errors, no_transfers))
  end
  if(no_cs_errors > 0) begin
    `uvm_error("SPI_SB_REPORT:", $sformatf("Test Failed - %0d CS errors occured during %0d transfers", no_cs_errors, no_transfers))
  end

endfunction: report_phase


endclass: spi_scoreboard
