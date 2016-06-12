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
//
// Class Description:
//
//
class gpio_monitor extends uvm_component;

// UVM Factory Registration Macro
//
`uvm_component_utils(gpio_monitor);

// Virtual Interface
virtual gpio_if GPIO;

//------------------------------------------
// Data Members
//------------------------------------------
gpio_agent_config m_cfg;
//------------------------------------------
// Component Members
//------------------------------------------
uvm_analysis_port #(gpio_seq_item) ap;
uvm_analysis_port #(gpio_seq_item) ext_ap;

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:

extern function new(string name = "gpio_monitor", uvm_component parent = null);
extern function void build_phase(uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern task internal_monitor_loop;
extern task external_monitor_loop;
extern function void report_phase(uvm_phase phase);

endclass: gpio_monitor

function gpio_monitor::new(string name = "gpio_monitor", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void gpio_monitor::build_phase(uvm_phase phase);
  if (!uvm_config_db #(gpio_agent_config)::get(this, "", "gpio_agent_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration gpio_agent_config from uvm_config_db. Have you set() it?")
  ap = new("ap", this);
  if(m_cfg.monitor_external_clock == 1) begin
    ext_ap = new("ext_ap", this);
  end
endfunction: build_phase

task gpio_monitor::run_phase(uvm_phase phase);
  fork
    internal_monitor_loop();
    begin // Only needed if running external clock monitoring
      if(m_cfg.monitor_external_clock == 1) begin
        external_monitor_loop();
      end
    end
  join
endtask: run_phase

task gpio_monitor::internal_monitor_loop;
  gpio_seq_item item;
  gpio_seq_item cloned_item;
  logic[31:0] last_gpio_sample;

  item = gpio_seq_item::type_id::create("item");

  // Initialisation:
  @(posedge GPIO.clk);
  last_gpio_sample = GPIO.gpio;

  forever begin
    @(posedge GPIO.clk);
//    if(GPIO.gpio !== last_gpio_sample) begin
      item.gpio = GPIO.gpio;
      last_gpio_sample = GPIO.gpio;
      // Clone and publish the cloned item to the subscribers
      $cast(cloned_item, item.clone());
      ap.write(cloned_item);
//      `uvm_info("GPIO_MONITOR", cloned_item.convert2string(), UVM_LOW)
//    end
  end
/*
//    $display("GPIO.gpio %0h, last_gpio_sample %0h", GPIO.gpio, last_gpio_sample);
    // Detect the protocol event on the virtual interface
    while(GPIO.gpio === last_gpio_sample) begin
      @(posedge GPIO.clk);
    end
    item.gpio = GPIO.gpio;
    last_gpio_sample = GPIO.gpio;
    // Clone and publish the cloned item to the subscribers
    $cast(cloned_item, item.clone());
//    `uvm_info("monitor", item.convert2string(), UVM_LOW);
    ap.write(cloned_item);
//    `uvm_info("monitor", "Got past write", UVM_LOW);
    @(posedge GPIO.clk);
  end
*/
endtask: internal_monitor_loop

task gpio_monitor::external_monitor_loop;
  gpio_seq_item item;
  gpio_seq_item cloned_item;
  logic[31:0] last_gpio_sample;

  item = gpio_seq_item::type_id::create("item");

  // Initialisation:
  @(posedge GPIO.clk);
  last_gpio_sample = GPIO.gpio;

  forever begin
    // Detect the protocol event on the virtual interface
    @(posedge GPIO.ext_clk);
      @(posedge GPIO.clk);
//    if(GPIO.gpio != last_gpio_sample) begin
      item.gpio = GPIO.gpio;
      last_gpio_sample = GPIO.gpio;
      item.ext_clk = 1;
    repeat(4)
      @(posedge GPIO.clk);
    @(negedge GPIO.clk);
//    end
    // Clone and publish the cloned item to the subscribers
    $cast(cloned_item, item.clone());
    ext_ap.write(cloned_item);
    @(negedge GPIO.ext_clk);
    repeat(1)
      @(posedge GPIO.clk);
//    if(GPIO.gpio != last_gpio_sample) begin
      item.gpio = GPIO.gpio;
      last_gpio_sample = GPIO.gpio;
      item.ext_clk = 0;
    repeat(4)
      @(posedge GPIO.clk);
    @(negedge GPIO.clk);
//    end
    // Clone and publish the cloned item to the subscribers
    $cast(cloned_item, item.clone());
    ext_ap.write(cloned_item);
  end
endtask: external_monitor_loop

function void gpio_monitor::report_phase(uvm_phase phase);
// Might be a good place to do some reporting on no of analysis transactions sent etc

endfunction: report_phase
