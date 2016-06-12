
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
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=rand_transfer_test

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../.. ;\
	tar -zcf generation/ex3_sequence_polymorphism/uvm_generation_seq_poly.tgz\
	generation/common\
	generation/sequence_library\
	generation/tests\
	generation/ex3_sequence_polymorphism/Makefile\
	generation/ex3_sequence_polymorphism/README.txt;\
	cd generation/ex3_sequence_polymorphism)
