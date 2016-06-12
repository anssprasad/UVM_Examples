
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.1
UVM_REGISTER ?= ../../../../uvm_register-2.0
RTL ?= ../../../rtl
AGENTS ?= ../../../agents
TAR_PATH ?= ../../../../

all: work build run

tarball: clean tar

work:
	vlib work

build:
	vlog +incdir+$(RTL)/spi/rtl/verilog $(RTL)/spi/rtl/verilog/*.v
	vlog +incdir+$(UVM_HOME)/src+$(UVM_REGISTER)/src $(UVM_REGISTER)/src/uvm_register_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+$(AGENTS)/register_layering $(AGENTS)/register_layering/register_layering_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+$(AGENTS)/apb_agent $(AGENTS)/apb_agent/apb_agent_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+$(AGENTS)/spi_agent $(AGENTS)/spi_agent/spi_agent_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+incdir+../register_model ../register_model/spi_register_pkg.sv
	vlog $(AGENTS)/apb_agent/apb_if.sv -timescale 1ns/10ps
	vlog $(AGENTS)/spi_agent/spi_if.sv -timescale 1ns/10ps
	vlog ../tb/intr_if.sv -timescale 1ns/10ps
	vlog +incdir+$(UVM_HOME)/src+incdir+../env ../env/spi_env_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+incdir+../sequences ../sequences/spi_bus_sequence_lib_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+incdir+../sequences ../sequences/spi_sequence_lib_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+incdir+../sequences ../sequences/spi_virtual_seq_lib_pkg.sv
	vlog +incdir+$(UVM_HOME)/src+incdir+../test ../test/spi_test_lib_pkg.sv
	vlog -timescale 1ns/10ps +incdir+$(RTL)/spi/rtl/verilog ../tb/top_tb.sv

run:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_interrupt_test

run_spi_interrupt_test:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_interrupt_test

run_spi_debug_test:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_debug_test

run_spi_poll_test:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_poll_test

run_spi_reg_test:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_reg_test

run_spi_test:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME=spi_test

clean:
	@rm -rf work transcript *~ vsim.wlf *.log *.tgz

tar:
	@(cd $(TAR_PATH);\
	tar -zcf tb_build/block_level_tbs/spi_tb/sim/tb_build_bl_tb.tgz\
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
