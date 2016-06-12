
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.1

all: work build run

tarball: clean tar

work:
	vlib work

build:
	vlog +incdir+$(UVM_HOME)/src top.sv

run:
	vsim -c -do "run -all" top_tb

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../../ ;\
	tar -cf use_models/bidirectional_get_put/use_models_bidir_get_put.tar\
	use_models/bidirectional_get_put/top.sv\
	use_models/bidirectional_get_put/Makefile\
	use_models/bidirectional_get_put/README.txt;\
	cd use_models/bidirectional_get_put)
	@gzip -f use_models_bidir_get_put.tar
