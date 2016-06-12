README.txt

**************
DUT

Base circuit is a WISHBONE bus environment with an Ethernet MAC and a slave memory.


**************
Testbench

The Testbench has a single WISHBONE bus environment.
The WISHBONE bus environment connects to the WISHBONE bus via a WISHBONE agent.
The WISHBONE bus environment connects to the MII interface of the MAC via a MII agent.
A virtual sequence controls both of the agents.  It has a directed test that
generates ethernet traffic to and from the MAC.

***************
Running

A Makefile is provided with some targets:

make  or  make normal
  - compile and run

make gui
  - compile and run with the GUI

make cmp
  - compile only

make sim
  - run only

make clean
  - clean up directory
  
***************
Verifying output

This testbench is not self checking. You will need to verify the output visually.
The test outputs the following guide when run:

   ---- To verify your output is correct scroll up the output to above
   ---- the report summary and look for the following lines:

    Number of Ethernet transactions sent (Tx) by the MAC: 3     
    Number of Ethernet transactions received (Rx) by the MAC: 4 
    Number of Tx Errors: 0                                      
    Number of Rx Errors: 0                                      

    Number of Wishbone 0 Slave Memory write transactions: 147   
    Number of Wishbone 0 Slave Memory read  transactions: 147   
    Number of Wishbone 0 Non-Slave Memory write cycles: 26      
    Number of Wishbone 0 Non-Slave Memory read cycles: 16       
    Wishbone 0 Slave Memory read error count: 0                 
