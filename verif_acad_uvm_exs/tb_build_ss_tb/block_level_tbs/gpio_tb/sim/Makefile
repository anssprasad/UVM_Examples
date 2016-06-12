
UVM_REGISTER ?= ../../../../uvm_register-2.0
RTL          ?= ../../../rtl
AGENTS       ?= ../../../agents
TAR_PATH     ?= ../..
TEST         ?= gpio_outputs_test

all: work build run

tarball: clean tar

work:
	vlib work

build: work
	vlog -incr +incdir+$(RTL)/gpio/rtl/verilog $(RTL)/gpio/rtl/verilog/*.v
	vlog -incr +incdir+$(UVM_REGISTER)/src $(UVM_REGISTER)/src/uvm_register_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/register_layering $(AGENTS)/register_layering/register_layering_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/apb_agent $(AGENTS)/apb_agent/apb_agent_pkg.sv -suppress 2263
	vlog -incr +incdir+../register_model ../register_model/gpio_register_pkg.sv -suppress 2263
	vlog -incr +incdir+$(AGENTS)/gpio_agent $(AGENTS)/gpio_agent/gpio_agent_pkg.sv -suppress 2263
	vlog -incr $(AGENTS)/apb_agent/apb_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr $(AGENTS)/gpio_agent/gpio_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr ../tb/intr_if.sv -timescale 1ns/10ps -suppress 2263
	vlog -incr +incdir+../env ../env/gpio_env_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/gpio_bus_sequence_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/gpio_sequence_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../sequences ../sequences/gpio_virtual_sequence_lib_pkg.sv -suppress 2263
	vlog -incr +incdir+../test ../test/gpio_test_lib_pkg.sv -suppress 2263
	vlog -incr -timescale 1ns/10ps +incdir+$(RTL)/gpio/rtl/verilog ../tb/top_tb.sv -suppress 2263

run:
	vsim -c -do "run -all" top_tb +UVM_TESTNAME="$(TEST)"

clean:
	@rm -rf work transcript *~ vsim.wlf *.log
	@find ../../../ -name "*~" -delete