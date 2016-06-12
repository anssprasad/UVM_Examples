all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog ../mbus_slave/mbus_slave.sv
	vlog +incdir+./mbus_pipelined_agent ./mbus_pipelined_agent/mbus_pipelined_agent_pkg.sv
	vlog top.sv

sim:
	vsim -c -do "run -all" top_tb

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../../ ;\
	tar -zcf use_models/pipelined_item_done/uvm_use_models_pipelined_item_done.tgz\
	use_models/pipelined_item_done/top.sv\
	use_models/pipelined_item_done/Makefile\
	use_models/pipelined_item_done/README.txt\
	use_models/mbus_slave\
	use_models/pipelined_item_done/mbus_pipelined_agent;\
	cd use_models/pipelined_item_done)
