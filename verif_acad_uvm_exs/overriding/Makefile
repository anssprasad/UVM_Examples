
OVM_HOME ?= $(QUESTA_HOME)/verilog_src/ovm-2.1

all: work build run

tarball: clean tar

work:
	vlib work

build:
	vlog +incdir+$(OVM_HOME)/src a_agent_pkg.sv
	vlog +incdir+$(OVM_HOME)/src top.sv

run:
	vsim -c -do "run -all" top_tb

clean:
	rm -rf work transcript *~ vsim.wlf *.log
	
tar:
	@(cd .. ;\
	tar -cf overriding/overriding.tar\
	overriding/a_agent_pkg.sv\
	overriding/top.sv\
	overriding/Makefile\
	overriding/README.txt;\
	cd overriding)
	@gzip overriding.tar

