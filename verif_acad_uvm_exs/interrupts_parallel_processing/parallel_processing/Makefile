all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog dsp_chain.sv
	vlog dsp_con_pkg.sv
	vlog top.sv

sim:
	vsim -c -do "run -all" top_tb

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../.. ;\
	tar -zcf interrupts/parallel_processing/uvm_interrupts_parallel_processing.tgz\
	interrupts/bidirect_bus_agent_pkg.sv\
	interrupts/parallel_processing/dsp_*.*\
	interrupts/parallel_processing/top.sv\
	interrupts/parallel_processing/Makefile\
	interrupts/parallel_processing/README.txt;\
	cd interrupts/parallel_processing)
