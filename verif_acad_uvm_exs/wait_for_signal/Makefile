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
	@(cd .. ;\
	tar -zcf wait_for_signal/uvm_wait_for_signal.tgz\
	wait_for_signal/top.sv\
	wait_for_signal/Makefile\
	wait_for_signal/README.txt;\
	cd wait_for_signal)
	
