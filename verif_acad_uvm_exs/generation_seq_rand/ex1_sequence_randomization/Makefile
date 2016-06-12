
all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog ../common/bus_if.sv
	vlog ../common/dut.sv
	vlog ../common/bus_agent_pkg.sv
	vlog ../sequence_library/bus_seq_lib_pkg.sv
	vlog ../tests/test_lib_pkg.sv
	vlog ../common/top_tb.sv

sim:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=seq_rand_test

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../.. ;\
	tar -zcf generation/ex1_sequence_randomization/uvm_generation_seq_rand.tgz\
	generation/common\
	generation/sequence_library\
	generation/tests\
	generation/ex1_sequence_randomization/Makefile\
	generation/ex1_sequence_randomization/README.txt;\
	cd generation/ex1_sequence_randomization)
	
