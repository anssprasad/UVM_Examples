MVC_HOME     ?= $(QUESTA_MVC_HOME)/questa_mvc_src
MVC_BASE     ?= $(MVC_HOME)/sv

all: work mvc uvm_tb sim


mvc:
	vlog -32 +incdir+$(QUESTA_MVC_HOME)/include $(QUESTA_MVC_HOME)/include/questa_mvc_svapi.svh -timescale 1ns/10ps
	vlog -32 +incdir+$(UVM_HOME)/src+incdir+$(MVC_BASE) $(MVC_BASE)/mvc_pkg.sv -timescale 1ns/10ps
	vlog -32 +incdir+$(UVM_HOME)/src+incdir+$(MVC_BASE)/axi4+incdir+$(MVC_BASE) $(MVC_BASE)/axi4/mgc_axi4_v1_0_pkg.sv -timescale 1ns/10ps -suppress 2720

uvm_tb:
	vlog -32 dut_params_pkg.sv
	vlog -32 +cover=sb axi4_slave_synth.sv
	vlog -32 mentor_qvip_api_axi4_master.sv
	vlog -32 mentor_qvip_api_axi4_slave.sv
	vlog -32 mentor_qvip_api_axi4_monitor.sv
	vlog -32 scoreboard.sv
	vlog -32 top.sv

work:
	vlib work

sim:
	vsim -c top -novopt -coverage -mvchome $(QUESTA_MVC_HOME)

clean:
	rm -r work questa_mvc.ucdb transcript vsim.wlf
