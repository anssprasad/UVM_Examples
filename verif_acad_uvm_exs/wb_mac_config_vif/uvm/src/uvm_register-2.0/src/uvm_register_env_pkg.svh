//------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
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

// TITLE: UVM Register Environment
// This environment is a template for other register test
// enviornments or may be used as-is.

// CLASS: uvm_register_env
//
// An environment that can be used for automated
// register testing.
//
// It contains a driver, sequencer, bus_driver, monitor and
// scoreboard.
//
// Once things are built and connected, this env
// uses the factory to find sequences to run.
//
class uvm_register_env 
  extends uvm_env;

  `uvm_component_utils(uvm_register_env)

  bit m_auto_run;

  // PORT: bus_transport_port
  // The "downstream" side of the env. The register driver
  // transport_port is connected here.
  uvm_transport_port  
    #(bus_request, bus_response) bus_transport_port;

  // PORT: bus_rsp_analysis_export
  // Publishes the register monitor analysis export. This is
  // an "input". Register transaction responses should come
  // back here to be processed by the uvm_register_monitor
  // (built-in scoreboard).
  uvm_analysis_export   
    #(uvm_register_transaction) bus_rsp_analysis_export;

  // VARIABLE: m_sequencer
  // The sequencer contained in the env.
  uvm_register_sequencer 
    #(uvm_register_transaction, 
      uvm_register_transaction) m_sequencer;

  // VARIABLE: m_driver
  // The driver contained in the env.
  uvm_register_driver    
    #(uvm_register_transaction, 
      uvm_register_transaction) m_driver;

  // VARIABLE: m_bus_driver
  // The bus_driver contained in the env.
  uvm_register_bus_driver    
    #(uvm_register_transaction, 
      uvm_register_transaction) m_bus_driver;

  // VARIABLE: m_register_monitor
  // The register monitor contained in the env.
  // Used to scoreboard register transactions.
  uvm_register_monitor 
    #(uvm_register_transaction) m_register_monitor;

  // VARIABLE: m_register_map
  // Convenient place to house the register map
  //  for users of this env to reference.
  // This is the register map being exercised.
  uvm_register_map               m_register_map;

  // FUNCTION: new()
  // Construct this object.
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // FUNCTION: build()
  // Build the components and ports. Setup
  // the default configurations.
  function void build();
    super.build();

    m_sequencer         = new("sequencer",         this);
    m_driver            = new("reg_driver",        this);
    m_bus_driver        = new("bus_driver",        this);
    m_register_monitor  = new("register_monitor",  this);

    bus_rsp_analysis_export 
                  = new("bus_rsp_analysis_export", this);
    bus_transport_port      
                  = new("bus_transport_port",      this);

    set_config_string("sequencer", 
      "default_sequence", 
        "uvm_exhaustive_sequence");

    // Doesn't really work here. Need to go l level higher.
    set_config_string("*", 
      "default_auto_register_test", 
        "register_sequence_all_registers#(REQ, RSP)");

    m_register_map = 
      uvm_register_map::uvm_register_get_register_map();

    begin
      int x;
      // Are we to start ourselves automatically?
      // The default is to NOT start ourselves automatically.
      // To change the setting do:
      //   set_config_int("*", auto_run, 1)
      m_auto_run = 0;
      if (get_config_int("auto_run", x)) begin
        // Use the setting.
        uvm_report_info("Register Env", 
          "Checking 'auto_run'");
        m_auto_run = x;
      end
      uvm_report_info("Register Env", 
        $psprintf("auto_run set to %0d", m_auto_run));
    end
  endfunction

  // FUNCTION: connect()
  // Connect the upstream side of the driver to the
  // sequencer.
  // Connect the bus_driver "downstream" side to the 
  // bus_transport_port.
  // Connect the bus monitor analysis port (the output
  // side) to the register monitor (scoreboard).
  function void connect();
    m_driver.seq_item_port.connect(
      m_sequencer.seq_item_export);

    m_driver.rsp_port.connect(
      m_sequencer.rsp_export);

    m_driver.transport_port.connect(
      m_bus_driver.transport_export);

    m_bus_driver.transport_port.connect(
      bus_transport_port);

    bus_rsp_analysis_export.connect(
      m_register_monitor.analysis_export);
  endfunction

  // TASK: run()
  // 1) Find a sequence to run.
  //    Either by name or by type.
  // 2) Run it.
  //      ie. m_sequence.start(m_sequencer);
  task run();

    string default_auto_register_test = 
      "register_sequence_all_registers#(REQ, RSP)";
    
    uvm_register_sequence_base
      #(uvm_register_transaction, 
        uvm_register_transaction) m_sequence;

    if ( !m_auto_run )
      return;

    uvm_report_info("Register Env", "Starting...");

    // Useful for debug, but prints different things
	// depending on which UVM, so don't use under
	// normal regression runs
	//  factory.print(1);

    // Get the "default_auto_register_test"
    // sequence from the factory and run it.

`ifdef TYPE_BASED
    // Works, but hard-coded type.
    m_sequence = register_sequence_all_registers
      #(uvm_register_transaction, uvm_register_transaction)::
          type_id::create(default_auto_register_test, this);
`else
    begin
      // Just doing an "import" on the sequence does NOT 
      //  cause the static construction to take place. This 
      //  dummy declaration will cause the static 
      //  initialization to happen.
      // NOTE: This dummy declarion should be in each 
      //  test/sequence.
      //
      // register_sequence_all_registers
      //     #(uvm_register_transaction, 
      //       uvm_register_transaction) dummy;
  
      if (!get_config_string( "default_auto_register_test", 
          default_auto_register_test)) begin
        uvm_report_error("Register Env", 
"Cannot find 'default_auto_register_test' in the configuration table");

        default_auto_register_test = 
          "register_sequence_all_registers#(REQ, RSP)";
        uvm_report_info("Register Env",
          $psprintf("Using default value of %s", 
            default_auto_register_test));
      end

      uvm_report_info("Register Env", 
        {"Creating sequence ... ", 
          default_auto_register_test, " from the factory"});

      // $cast(m_sequence, uvm_factory::create_object( 
      //    m_sequence.get_type_name(),
      //     get_full_name(), m_sequence.get_name())))

      // m_sequence = uvm_factory::create_object(
      //   default_auto_register_test, get_full_name(), 
      //     "auto_test");

      $cast(m_sequence, factory.create_object_by_name(
        default_auto_register_test, get_full_name(), 
          "auto_test"));
    end
`endif

    if ( m_sequence == null ) begin
      uvm_report_fatal("Register Env", 
        $psprintf("Cannot find sequence (%s) in factory", 
          default_auto_register_test));
    end
    else begin
      uvm_report_info("Register Env", 
        $psprintf("Automatically starting sequence (%s)", 
          m_sequence.get_type_name()));

      m_sequence.start(m_sequencer);
    end

    global_stop_request();
  endtask
endclass

