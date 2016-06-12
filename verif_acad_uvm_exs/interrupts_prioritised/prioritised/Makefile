all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog ../bidirect_bus_agent_pkg.sv
	vlog top.sv

sim:
	vsim -c -do "run -all" top

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../.. ;\
	tar -zcf interrupts/prioritised/uvm_interrupts_prioritised.tgz\
	interrupts/bidirect_bus_agent_pkg.sv\
	interrupts/prioritised/top.sv\
	interrupts/prioritised/Makefile\
	interrupts/prioritised/README.txt;\
	cd interrupts/prioritised)
