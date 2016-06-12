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

class uart_driver extends uvm_driver #(uart_seq_item, uart_seq_item);

`uvm_component_utils(uart_driver)

function new(string name = "uart_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

virtual serial_if sline;

uart_seq_item pkt;

bit clk;
logic[15:0] divisor;

task clk_gen;
  clk = 0;
  divisor = 4;
  forever
    begin
      repeat(divisor)
        @(posedge sline.clk);
      clk = ~clk;
    end
endtask: clk_gen


task send_pkts;
// Receives a character according to the appropriate word format
  integer bitPtr = 0;
  begin
    sline.sdata = 1;
    forever
      begin
        seq_item_port.get_next_item(pkt);
        divisor = pkt.baud_divisor;
        // Variable delay
        repeat(pkt.delay)
          @(posedge clk);
        if (pkt.sbe)
          begin
            sline.sdata <= 0;
            repeat(pkt.sbe_clks)
              @(posedge clk);
            sline.sdata <= 1;
            repeat(pkt.sbe_clks)
              @(posedge clk);
          end
        // Start bit
        sline.sdata <= 0;
        bitPtr = 0;
        bitPeriod;
        // Data bits 0 to 4
        while(bitPtr < 5)
          begin
            sline.sdata <= pkt.data[bitPtr];
            bitPeriod;
            bitPtr++;
          end
        // Data bits 5 to 7
        if (pkt.lcr[1:0] > 2'b00)
          begin
            sline.sdata <= pkt.data[5];
            bitPeriod;
          end
        if (pkt.lcr[1:0] > 2'b01)
          begin
            sline.sdata <= pkt.data[6];
            bitPeriod;
          end
        if (pkt.lcr[1:0] > 2'b10)
          begin
            sline.sdata <= pkt.data[7];
            bitPeriod;
          end
        // Parity
        if (pkt.lcr[3])
          begin
            sline.sdata <= logic'(calParity(pkt.lcr, pkt.data));
            if (pkt.pe)
              sline.sdata <= ~sline.sdata;
            bitPeriod;
          end
        // Stop bit
        if (!pkt.fe)
          sline.sdata <= 1;
        else
          sline.sdata <= 0;
        bitPeriod;
        if (!pkt.fe)
          begin
            if (pkt.lcr[2])
              begin
                if (pkt.lcr[1:0] == 2'b00)
                  begin
                    repeat(8)
                      @(posedge clk);
                  end
                else
                  bitPeriod;
              end
          end
        else
          begin
            sline.sdata <= 1;
            bitPeriod;
          end
      end
      seq_item_port.item_done();
  end
endtask: send_pkts

task bitPeriod;
  begin
    repeat(16)
      @(posedge clk);
  end
endtask: bitPeriod


task run_phase(uvm_phase phase);
  fork
    send_pkts;
    clk_gen;
  join
endtask: run_phase


endclass: uart_driver
