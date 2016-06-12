This example shows how you can use the OVM factory to override sequences
either by type (i.e. globally) or by an instance. The instance approach relies
on you thinking about overriding wherever you create the sequence via the
factory.

In order to run the example you should make sure that the following environment
variables are set up:

QUESTA_HOME - Pointing to your install of Questa
OVM_HOME - Pointing to the top of your copy of the OVM source code tree

To compile and run the simulation, please use the make file:

make all - Compile and run
make build - Compile only
make run  - Run the simulation in command line mode
