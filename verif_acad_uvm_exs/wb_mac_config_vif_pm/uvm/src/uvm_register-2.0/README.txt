Title: README.txt
-----------------------------------
UVM REGISTER - UVM Register Package
-----------------------------------

 The UVM Register package provides base class
 functionality for use as part of a shadow register 
 verification environment.

 The UVM Register package requires an UVM installation
 in order to run. If you do not already have the UVM,
 you should download and unpack it from <http://www.uvmworld.org>.

-------------------------------------------------
UVM Register Package Contents:

  User Guide (BETA)     - UVM-Register-User-Guide-BETA.pdf
  Reference Guide       - UVM-Register-Reference-Guide.html

  src/                  - The library base classes.
  examples/registers    - Examples for the register library.
  docs/                 - Documentation - HTML for the 
                          Reference Guide.

-------------------------------------------------
The UVM Register library (src/):

   src/uvm_register_pkg.sv  - The UVM Register package 
                              definition

   src/uvm_register.svh     - The register library and address 
                              map library

   src/uvm_register_agent_pkg.svh - Useful parts that make 
                                    up a register OVC

   src/uvm_register_auto_test.svh - Hook for users to get 
                                    automatic testing

   src/uvm_register_env_pkg.svh   - A useful ENV which is 
                                    part of the automatic 
                                    testing

   src/uvm_register_sequences_pkg.svh   - Automatic sequences 

   src/uvm_register_transaction_pkg.svh - Transaction 
                                          definitions

   src/uvm_register_version.svh         - Version string

   src/uvm_id_register.svh              - An ID register implementation
   src/uvm_modal_register.svh           - A modal register implementation
  
-------------------------------------------------
The UVM Register Library Examples:


o examples/registers/00_stopwatch/ 

  A simple example using automatic testing 
  demonstrating a shadow register.

   makefile                       - Compile, Simulate, Print

   auto/stopwatch_register_pkg.sv - The "automatically" 
                                    generated code. Today the 
                                    automation code is not yet
                                    released. This code must 
                                    be created by some means -
                                    typing, custom perl 
                                    script, etc.

   dut/stopwatch_rtl.sv           - The RTL

   dut/stopwatch_rtl_wrapper.sv   - SV interface to the RTL

   t.sv                           - Top level test. 
                                    What the user MUST write.

-------------------------------------------------
o examples/registers/01_bus_transactions/  

  A simple example showing generation of bus transactions.
  Constraints are demonstrated.


   makefile                       - Compile, Simulate, Print

   t.sv                           - Main classes. Top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/02_register_transactions/  

  A simple example showing generation of register transactions.

   makefile                       - Compile, Simulate, Print

   t.sv                           - Main classes. Top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/03_layered_register_sequences/  

  An example showing a bus driver, bus sequencer and
  bus transaction. A layered system is built with a
  specialized sequencer and special sequence (translate_sequence)
  which translates a register sequence into a bus sequence.

   makefile                       - Compile, Simulate, Print

   t.sv                           - Main classes. Top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/04_simple_bus/  

  An example showing an OVC designed for the "simple_bus".
  The OVC is used to drive and monitor the simple bus.
  A register translation sequence (translate_seq) is
  used to translate from generic register bus transactions
  into protocol specific simple_bus bus transactions.

  See RegisterPackageOverSimpleBus.pdf for additional
  documentation.

   makefile                       - Compile, Simulate, Print

   dut.sv                         - The Hardware.
   simple_bus.sv                  - The simple_bus OVC.
   t.sv                           - Main classes. Top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/05_backdoor_simple/  

  An example showing the use of the backdoor api.

   makefile                       - Compile, Simulate, Print
   test.sv                        - A simple test
   
   dut_ABC.sv                     - Code to represent a piece of hardware
   dut_ABC_rf_pkg.sv              - The register and address map definitions
                                    for device "ABC".

   dut_XYZ.sv                     - Code to represent a piece of hardware
   dut_XYZ_rf_pkg.sv              - The register and address map definitions
                                    for device "XYZ".

   system_map_pkg.sv              - Code to build the register map that
                                    represents the system.
   t.sv                           - A tiny top level, instantiating the
                                    three hardware instances, and the bus.


-------------------------------------------------
o examples/registers/06_id_registers/  

  An example showing a "fancy" register who acts as a device ID.
  Successive reads return the next value in a sequence. Once the
  end of the sequence is reached the next value read is the first.
  This sequence of values is the "ID" of the device.

   makefile                       - Compile, Simulate, Print

   t.sv                           - Simple test and top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/08_register_field_modes/  

  An example showing a register who has two modes. The modes
  are captured by two different field definitions. Additionally,
  the modes have different coverage collected.

   makefile                       - Compile, Simulate, Print

   t.sv                           - Simple test and top-level.
   regdef.sv                      - The register definitions.

-------------------------------------------------
o examples/registers/08_register_field_modes_derived_class/  

  An alternate implementation with slightly different capabilities.
  The 08_register_field_modes example implementation is the 
  preferred implementation.

-------------------------------------------------
o examples/registers/09_memory_simple/  

  An example showing a simple memory use model. With
  this new functionality, a memory value can be written
  and read from the shadow represented by a memory map.
  There is also an implementation for "memory allocation",
  but this API, is not yet completely tested. The
  memory allocation functionality will be supported 
  in a future release.

-------------------------------------------------
o examples/registers/10_coherent_registers/  

  An example showing "master" and "slave" registers
  which act together to provide a coherent view of the
  slaves. When the master is read(), the slaves take
  a snapshot of themselves - effectively locking in the
  current values. Later, as time has passed, the snapshot
  values can be read, giving a consistent (coherent) picture
  of the values of the slaves when the snapshot was taken.

-------------------------------------------------
o examples/registers/11_masking_notification/  

  An example demonstrating the access policies and
  "aliasing" that a register can have. A register can
  be  "read-write" from one bus, and "read-only" from another
  bus.

-------------------------------------------------
o examples/registers/12_fifo_registers/  

  An example demonstrating the functionality of a fifo
  register.

-------------------------------------------------
o examples/registers/13_field_by_name/  

  An example demonstrating using a "by-name" access to
  set and get field values. This "field-by-name" access
  is demonstrated with a register definition file, and
  a few tests.

-------------------------------------------------
How to Install UVM:

 Get the UVM distribution. (uvm-xxx.tar.gz)
 Where 'xxx' is the current version number.

   Go to <http://www.uvmworld.org>

 Unpack the UVM distribution.

:   tar zxvf uvm-xxx.tar.gz

-------------------------------------------------
How to Install UVM Register Package:

 Get the UVM Register distribution. (uvm_register-xxx.tar.gz)

 Unpack the UVM Register distribution.

:   tar zxvf uvm_register-xxx.tar.gz

-------------------------------------------------
How to run the UVM Register examples:

 Change to the UVM REgister directory.

:   cd uvm_register-xxx/

 Change to the examples directory.

:   cd examples/registers/00_stopwatch

 Point at your UVM installation. Or edit the
 makefile.

:   setenv UVM <UVM_INSTALL_DIR>/uvm

 Run the example.

:   make

 Note - you can also use the 'run_questa' scripts.
 
---------------------------------------------------

