vlib work

# Compile the RTL
vlog +incdir+../rtl/verilog ../rtl/verilog/*.v +cover

# Test bench

# Standard packages
set OVM_HOME $env(OVM_HOME)

vlog +incdir+$OVM_HOME/src+incdir+../ovm/ovm_container ../ovm/ovm_container/ovm_container.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/ovm_register-2.0/src ../ovm/ovm_register-2.0/src/ovm_register_pkg.sv

# GPIO test bench packages

vlog ../ovm/agents/apb/apb_if.sv -timescale 1ns/10ps
vlog ../ovm/agents/spi/spi_if.sv -timescale 1ns/10ps
vlog ../ovm/tb/intr_if.sv -timescale 1ns/10ps

vlog +incdir+$OVM_HOME/src+incdir+../ovm/agents/register_layering ../ovm/agents/register_layering/register_layering_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/agents/apb ../ovm/agents/apb/apb_agent_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/register_model ../ovm/register_model/spi_register_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/agents/spi ../ovm/agents/spi/spi_agent_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/env ../ovm/env/spi_env_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/sequences ../ovm/sequences/spi_bus_sequence_lib_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/sequences ../ovm/sequences/spi_sequence_lib_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/sequences ../ovm/sequences/spi_virtual_seq_lib_pkg.sv
vlog +incdir+$OVM_HOME/src+incdir+../ovm/test ../ovm/test/spi_test_lib_pkg.sv
vlog -timescale 1ns/10ps +incdir+../rtl/verilog ../ovm/tb/top_tb.sv

