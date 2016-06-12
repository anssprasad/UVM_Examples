SIMPLE_HOME = ./simple_ovc

all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog +incdir+$(SIMPLE_HOME) $(SIMPLE_HOME)/simple_pkg.sv
	vlog top.sv


sim:
	vsim -c  -do "run -all" top

clean:
	rm -rf work transcript *~ vsim.wlf *.log
	
tar:
	@(cd ../.. ;\
	tar -zcf virtual_sequences/standalone_find_all/uvm_virt_seq_find_all.tgz\
	virtual_sequences/standalone_find_all/simple_ovc\
	virtual_sequences/standalone_find_all/top.sv\
	virtual_sequences/standalone_find_all/Makefile\
	virtual_sequences/standalone_find_all/README.txt;\
	cd virtual_sequences/standalone_find_all)
	
	
	
