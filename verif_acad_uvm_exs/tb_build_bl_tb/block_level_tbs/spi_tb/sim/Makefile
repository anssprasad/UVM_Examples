
UVM_REGISTER ?= ../../../../ovm_register-2.0
RTL          ?= ../../../rtl
AGENTS       ?= ../../../agents
TAR_PATH     ?= ../../../../
TEST         ?= spi_interrupt_test

all: work build run

tarball: clean tar

work:
	vlib work

build: work
	vlog -incr +incdir+$(RTL)/spi/rtl/verilog $(RTL)/spi/rtl/verilog/*.v
	vlog -incr +incdir+$(UVM_REGISTER)/src $(UVM_REGISTER)/src/uvm_register_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/register_layering $(AGENTS)/register_layering/register_layering_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/apb_agent $(AGENTS)/apb_agent/apb_agent_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/spi_agent $(AGENTS)/spi_agent/spi_agent_pkg.sv -suppress 2263
	vlog -incr +incdir+../register_model ../register_model/spi_register_pkg.sv -suppress 2263
	vlog -incr $(AGENTS)/apb_agent/apb_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr $(AGENTS)/spi_agent/spi_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr ../tb/intr_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr +incdir+../env ../env/spi_env_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/spi_bus_sequence_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/spi_sequence_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/spi_virtual_seq_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../test ../test/spi_test_lib_pkg.sv -suppress 2263
	vlog -incr -timescale 1ns/10ps +incdir+$(RTL)/spi/rtl/verilog ../tb/top_tb.sv

run:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME="$(TEST)"

clean:
	@rm -rf work transcript *~ vsim.wlf *.log *.tgz
	@find ../../../ -name "*~" -delete

tar:
	@(cd $(TAR_PATH);\
	tar -zcf tb_build/block_level_tbs/spi_tb/sim/uvm_tb_build_bl_tb.tgz\
	tb_build/agents/apb_agent\
	tb_build/agents/spi_agent\
	tb_build/agents/register_layering\
	tb_build/rtl/spi\
	tb_build/block_level_tbs/spi_tb/env\
	tb_build/block_level_tbs/spi_tb/test\
	tb_build/block_level_tbs/spi_tb/sequences\
	tb_build/block_level_tbs/spi_tb/register_model\
	tb_build/block_level_tbs/spi_tb/tb\
	tb_build/block_level_tbs/spi_tb/sim/Makefile\
	tb_build/block_level_tbs/spi_tb/sim/README.txt)
