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

class spi_register_coverage extends uvm_subscriber #(apb_seq_item);


  `uvm_component_utils(spi_register_coverage)

  bit m_is_covered;
  logic[31:0] address;
  bit cmd;

  covergroup reg_cover;

    option.name = "Register Access Cover Group";
    option.comment = "Automatically generated";

    address_cpt: coverpoint address
      {
        bins spi_data_0_reg = {32'h0000_0000};
        bins spi_data_1_reg = {32'h0000_0004};
        bins spi_data_2_reg = {32'h0000_0008};
        bins spi_data_3_reg = {32'h0000_000C};
        bins spi_ctrl_reg = {32'h0000_0010};
        bins spi_div_reg = {32'h0000_0014};
        bins spi_ss_reg = {32'h0000_0018};
     }

  bus_command_cpt: coverpoint cmd
    {bins read = {0};
     bins write = {1};
    }

  reg_command_cross: cross address_cpt, bus_command_cpt;

endgroup: reg_cover

function new(string name, uvm_component parent);
  super.new(name, parent);
  reg_cover = new;
  m_is_covered = 0;
endfunction

function void write (apb_seq_item t);
  address = t.addr;
  cmd = t.we;
  reg_cover.sample();
  if (reg_cover.get_inst_coverage > 95)
    m_is_covered = 1;
endfunction: write

endclass: spi_register_coverage

