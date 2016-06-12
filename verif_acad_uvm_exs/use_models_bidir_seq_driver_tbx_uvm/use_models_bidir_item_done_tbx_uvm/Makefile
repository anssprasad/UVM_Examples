MODE ?= puresim

UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.1

CPP_PATH = $(GNUHOME)/bin/gcc

all: work build run

tarball: clean tar

work:
	vlib work.$(MODE)
	vmap work work.$(MODE)

build:
	vlog bidirect_bus_shared_pkg.sv
	vlog +incdir+$(UVM_HOME)/src top_tb.sv
ifeq ($(MODE),puresim)
	vlog +incdir+$(UVM_HOME)/src top_hdl.sv
else
	veanalyze bidirect_bus_shared_pkg.sv
	veanalyze -extract_hvl_info +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
	veanalyze -extract_hvl_info +define+QUESTA +incdir+$(UVM_HOME)/src top_tb.sv
	veanalyze top_hdl.sv
	tbxcomp -top top_hdl -$(MODE) 
	tbxsvlink -veloce -cpppath $(CPP_PATH)
endif

run:
	vsim -c -do "run -all" top_tb top_hdl -cpppath $(CPP_PATH)
	cp transcript transcript.$(MODE)

norun:
	vsim -c +tbxrun+norun top_tb top_hdl -cpppath $(CPP_PATH)
	cp transcript transcript.$(MODE)

clean:
	rm -rf work work.$(MODE) transcript *~ vsim.wlf *.log dgs.dbg dmslogdir
	rm -rf dgs.dbg dmslogdir tbx.dir debussy.cfg modelsim.ini tbx.map tbxsim.v tbxbindings* TRACE.txt

tar:
	@(cd ../../ ;\
	tar -cf use_models/bidirectional_item_done_tbx/use_models_bidir_item_done_tbx.tar\
	use_models/bidirectional_item_done_tbx/top_tb.sv\
	use_models/bidirectional_item_done_tbx/top_hdl.sv\
	use_models/bidirectional_item_done_tbx/bidirect_bus_shared_pkg.sv\
	use_models/bidirectional_item_done_tbx/Makefile\
	use_models/bidirectional_item_done_tbx/tbx.config\
	use_models/bidirectional_item_done_tbx/README.txt;\
	cd use_models/bidirectional_item_done_tbx)
	@gzip -f use_models_bidir_item_done_tbx.tar
