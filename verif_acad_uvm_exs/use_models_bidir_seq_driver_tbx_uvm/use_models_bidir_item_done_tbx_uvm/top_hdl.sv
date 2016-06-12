//
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
//
// This example illustrates how to implement a bidirectional driver-sequence use
// model. It uses get_next_item(), item_done() in the driver.
//
// It includes a bidirectional slave DUT, and the bus transactions are reported to
// the transcript.
//
interface bidirect_bus_driver_bfm (bus_if BUS);
// pragma attribute bidirect_bus_driver_bfm partition_interface_xif

import bidirect_bus_shared_pkg::bus_seq_item_s;
import bidirect_bus_pkg::bidirect_bus_driver;

bidirect_bus_driver proxy; // pragma tbx oneway proxy.item_done

bus_seq_item_s req;

bit go;

function void run(); // pragma tbx xtf
  // Default conditions:
  BUS.valid <= 0;
  BUS.rnw <= 1;
  go = 1;
endfunction

initial begin
  // Wait for reset to end and go signal from run()
  wait(BUS.resetn & go);
  @(posedge BUS.clk);
  forever
    begin
      bit success;
      proxy.try_next_item(req, success); // Start processing req item
      while (!success) begin
        @(posedge BUS.clk);
        proxy.try_next_item(req, success); // Start processing req item
      end
      @(posedge BUS.clk);
      repeat(req.delay-1) begin
        @(posedge BUS.clk);
      end
      BUS.valid <= 1;
      BUS.addr <= req.addr;
      BUS.rnw <= req.read_not_write;
      if(req.read_not_write == 0) begin
        BUS.write_data <= req.write_data;
      end
      while(BUS.ready != 1) begin
        @(posedge BUS.clk);
      end
      // At end of the pin level bus transaction
      // Copy response data into the req fields:
      if(req.read_not_write == 1) begin
        req.read_data = BUS.read_data; // If read - copy returned read data
      end
      req.error = BUS.error; // Copy bus error status
      BUS.valid <= 0; // End the pin level bus transaction
      proxy.item_done(req); // End of req item
    end
end

endinterface

// Interfaces for the bus and the DUT GPIO output

interface bus_if(input bit clk, resetn);

logic[31:0] addr;
logic[31:0] write_data;
logic rnw;
logic valid;
logic ready;
logic[31:0] read_data;
logic error;

modport master_mp (
  input  clk, resetn, rnw, valid, 
  output ready, error, 
  input  addr, write_data, 
  output read_data
);

modport slave_mp (
  input clk, resetn,
  output  rnw, valid, 
  input ready, error, 
  output  addr, write_data, 
  input read_data
);

endinterface: bus_if

interface gpio_if(input bit clk);

logic[255:0] gp_op;
logic[255:0] gp_ip;

modport out_mp(output gp_ip, output gp_op);

endinterface: gpio_if

// DUT - A semi-real GPIO interface with a scratch RAM
//
module bidirect_bus_slave(interface bus, interface gpio);

logic[1:0] delay;

always @(posedge bus.clk)
  begin
    if(bus.resetn == 0) begin
      delay <= 0;
      bus.ready <= 0;
      gpio.gp_op <= 0;
    end
    if(bus.valid == 1) begin // Valid cycle
      if(bus.rnw == 0) begin // Write
        if(delay == 2) begin
          bus.ready <= 1;
          delay <= 0;
          if(bus.addr inside{[32'h0100_0000:32'h0100_001C]}) begin // GPO range - 8 words or 255 bits
            case(bus.addr[7:0])
              8'h00: gpio.gp_op[31:0] <= bus.write_data;
              8'h04: gpio.gp_op[63:32] <= bus.write_data;
              8'h08: gpio.gp_op[95:64] <= bus.write_data;
              8'h0c: gpio.gp_op[127:96] <= bus.write_data;
              8'h10: gpio.gp_op[159:128] <= bus.write_data;
              8'h14: gpio.gp_op[191:160] <= bus.write_data;
              8'h18: gpio.gp_op[223:192] <= bus.write_data;
              8'h1c: gpio.gp_op[255:224] <= bus.write_data;
            endcase
            bus.error <= 0;
          end
          else begin
            bus.error <= 1; // Outside valid write address range
          end
        end
        else begin
          delay <= delay + 1;
          bus.ready <= 0;
        end
      end
      else begin // Read cycle
        if(delay == 3) begin
          bus.ready <= 1;
          delay <= 0;
          if(bus.addr inside{[32'h0100_0000:32'h0100_001C]}) begin // GPO range - 8 words or 255 bits
            case(bus.addr[7:0])
              8'h00: bus.read_data <= gpio.gp_op[31:0];
              8'h04: bus.read_data <= gpio.gp_op[63:32];
              8'h08: bus.read_data <= gpio.gp_op[95:64];
              8'h0c: bus.read_data <= gpio.gp_op[127:96];
              8'h10: bus.read_data <= gpio.gp_op[159:128];
              8'h14: bus.read_data <= gpio.gp_op[191:160];
              8'h18: bus.read_data <= gpio.gp_op[223:192];
              8'h1c: bus.read_data <= gpio.gp_op[255:224];
            endcase
            bus.error <= 0;
          end
          else if(bus.addr inside{[32'h0100_0020:32'h0100_003C]}) begin // GPI range - 8 words or 255 bits - read only
            case(bus.addr[7:0])
              8'h20: bus.read_data <= gpio.gp_ip[31:0];
              8'h24: bus.read_data <= gpio.gp_ip[63:32];
              8'h28: bus.read_data <= gpio.gp_ip[95:64];
              8'h2c: bus.read_data <= gpio.gp_ip[127:96];
              8'h30: bus.read_data <= gpio.gp_ip[159:128];
              8'h34: bus.read_data <= gpio.gp_ip[191:160];
              8'h38: bus.read_data <= gpio.gp_ip[223:192];
              8'h3c: bus.read_data <= gpio.gp_ip[255:224];
            endcase
            bus.error <= 0;
          end
          else begin
            bus.error <= 1;
          end
        end
        else begin
          delay <= delay + 1;
          bus.ready <= 0;
        end
      end
    end
    else begin
      bus.ready <= 0;
      bus.error <= 0;
      delay <= 0;
    end
  end

endmodule: bidirect_bus_slave

// Top level test bench module
module top_hdl;

bit clk, resetn;

bus_if BUS(clk, resetn);
gpio_if GPIO(clk);
bidirect_bus_slave DUT(.bus(BUS.slave_mp), .gpio(GPIO.out_mp));

bidirect_bus_driver_bfm DRIVER(.BUS(BUS.master_mp));

// tbx vif_binding_block
initial
  begin
    import uvm_pkg::uvm_config_db;
    uvm_config_db #(virtual bidirect_bus_driver_bfm) C;
    C.set(null, "uvm_test_top", $psprintf("%m.DRIVER"), DRIVER);
  end

// Free running clock
// tbx clkgen
initial
  begin
    clk = 0;
    forever begin
      #10 clk = ~clk;
    end
  end

// Reset
// tbx clkgen
initial
  begin
    resetn = 0;
    #50 resetn = 1;
  end

endmodule: top_hdl
