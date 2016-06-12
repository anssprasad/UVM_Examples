
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.0p1

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
	tar -cf use_models/bidirectional_item_done/use_models_bidir_item_done.tar\
	use_models/bidirectional_item_done/top.sv\
	use_models/bidirectional_item_done/Makefile\
	use_models/bidirectional_item_done/README.txt;\
	cd use_models/bidirectional_item_done)
	@gzip -f use_models_bidir_item_done.tar
