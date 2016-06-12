all: work build sim

tarball: clean tar

work:
	vlib work

build:
	vlog top.sv


sim:
	vsim -c +ARB_TYPE=SEQ_ARB_FIFO -do "run -all" top -l SEQ_ARB_FIFO.log
	vsim -c +ARB_TYPE=SEQ_ARB_WEIGHTED -do "run -all" top -l SEQ_ARB_WEIGHTED.log
	vsim -c +ARB_TYPE=SEQ_ARB_RANDOM -do "run -all" top -l SEQ_ARB_RANDOM.log
	vsim -c +ARB_TYPE=SEQ_ARB_STRICT_FIFO -do "run -all" top -l SEQ_ARB_STRICT_FIFO.log
	vsim -c +ARB_TYPE=SEQ_ARB_STRICT_RANDOM -do "run -all" top -l SEQ_ARB_STRICT_RANDOM.log
	vsim -c +ARB_TYPE=SEQ_ARB_USER -do "run -all" top -l SEQ_ARB_USER.log

clean:
	rm -rf work transcript *~ vsim.wlf *.log

tar:
	@(cd ../.. ;\
	tar -zcf priority/arbitration/uvm_priority_arbitration.tgz\
	priority/arbitration/top.sv\
	priority/arbitration/Makefile\
	priority/arbitration/README.txt;\
	cd priority/arbitration)
