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

class gpio_register_coverage extends uvm_subscriber #(apb_seq_item);


  `uvm_component_utils(gpio_register_coverage)

  bit m_is_covered;
  logic[31:0] address;
  bit cmd;

  covergroup reg_cover;

    option.name = "Register Access Cover Group";
    option.comment = "Automatically generated";
    option.per_instance = 1;

    address_cpt: coverpoint address
      {
        bins gpio_in_reg = {32'h0000_0000};
        bins gpio_out_reg = {32'h0000_0004};
        bins gpio_oe_reg = {32'h0000_0008};
        bins gpio_inte_reg = {32'h0000_000C};
        bins gpio_ptrig_reg = {32'h0000_0010};
        bins gpio_aux_reg = {32'h0000_0014};
        bins gpio_ctrl_reg = {32'h0000_0018};
        bins gpio_ints_reg = {32'h0000_001C};
        bins gpio_eclk_reg = {32'h0000_0020};
        bins gpio_nec_reg = {32'h0000_0024};
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

endclass: gpio_register_coverage

