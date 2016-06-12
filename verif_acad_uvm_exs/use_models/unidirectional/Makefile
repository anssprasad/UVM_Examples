all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog top.sv

sim:
	vsim -c -do "run -all" top_tb

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../../ ;\
	tar -zcf use_models/unidirectional/uvm_use_models_unidirectional.tgz\
	use_models/unidirectional/top.sv\
	use_models/unidirectional/Makefile\
	use_models/unidirectional/README.txt;\
	cd use_models/unidirectional)
