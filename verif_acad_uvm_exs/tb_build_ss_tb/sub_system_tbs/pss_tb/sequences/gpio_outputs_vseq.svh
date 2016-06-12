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

class gpio_outputs_vseq extends pss_vseq_base;

`uvm_object_utils(gpio_outputs_vseq)

function new(string name = "gpio_outputs_vseq");
  super.new(name);
endfunction

task body;
  output_test_seq GP_OPs = output_test_seq::type_id::create("GP_OPs");

  // Get the virtual sequencer handles assigned
  super.body();

  begin
    repeat(200) begin
      GP_OPs.start(ahb);
    end
  end

endtask: body

endclass: gpio_outputs_vseq

