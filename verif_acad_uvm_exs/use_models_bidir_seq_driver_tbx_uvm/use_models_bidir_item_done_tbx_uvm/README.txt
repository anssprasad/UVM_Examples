This example shows how to implement a driver and a sequencer for a
bidrectional protocol when the driver uses get_next_item to obtain the next
sequence_item and item_done() to indicate that it has completed the transfer.
The response information is available via the sequence_item handle.

In order to run the example you should make sure that the following environment
variables are set up:

QUESTA_HOME - Pointing to your install of Questa
UVM_HOME - Pointing to the top of your copy of the UVM source code tree

To compile and run the simulation, please use the make file -e.g:

make all - Compile and run
make build - Compile only
make run  - Run the simulation in command line mode
