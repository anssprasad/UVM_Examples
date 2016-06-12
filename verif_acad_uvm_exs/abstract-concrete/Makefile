
UVM_HOME      ?= $(dir $(shell which vsim))../verilog_src/uvm-1.0
UVM_SRC        = $(UVM_HOME)/src
UVM_LIB        = $(UVM_TOP)/lib/uvm_dpi
UVM_REG_HOME   = ./uvm_register-2.0/src
QUESTA_HOME   ?= $(dir $(shell which vsim))/..
WB_SRCS        = ./wishbone
SEQUENCES_SRCS = ./sequences
MII_SRCS       = ./mac_mii
TEST_SRCS      = ./tests
ETH_SRCS       = ./eth
ENV_SRCS       = ./env
TOP_SRCS       = ./top_modules

WB_BUS_SOURCES =  \
        $(WB_SRCS)/wb_slave_mem.sv  \
        $(TOP_SRCS)/test_params_pkg.sv \
        $(MII_SRCS)/mii_if.sv $(MII_SRCS)/mac_mii_protocol_module.sv $(ETH_SRCS)/wb_register_pkg.sv $(ETH_SRCS)/mac_info_pkg.sv  \
        $(WB_SRCS)/wishbone_pkg.sv \
        $(MII_SRCS)/mac_mii_pkg.sv \
        $(SEQUENCES_SRCS)/sequences_pkg.sv \
        $(ENV_SRCS)/env_pkg.sv \
        $(TEST_SRCS)/tests_pkg.sv \
        $(WB_SRCS)/wishbone_bus_syscon_bfm.sv \
        $(WB_SRCS)/wb_bus_protocol_module.sv \
        $(WB_SRCS)/wb_bus_wrapper.sv \
        $(TOP_SRCS)/top.sv \
        $(TOP_SRCS)/top_mac.sv

MAC_SRC_DIR = ./mac_core
MAC_SRCS = $(MAC_SRC_DIR)/eth_top.v

normal: clean cmp sim

gui: clean cmp
	vsim +nowarnTSCALE -voptargs="+acc" top top_mac -suppress 3829 \
        -sv_lib $(UVM_HOME)/lib/uvm_dpi

sim: 
	vsim +nowarnTSCALE -c top top_mac -suppress 3829 -do "run -all" \
        -sv_lib $(UVM_HOME)/lib/uvm_dpi

debug: clean cmp
	vsim +nowarnTSCALE -gui -voptargs="+acc" top_mac -suppress 3829 \
        -sv_lib $(UVM_HOME)/lib/uvm_dpi

uvm_cmp: 
	test -e work || vlib work
	vlog $(UVM_SRC)/uvm_pkg.sv +incdir+$(UVM_SRC)
	mkdir -p $(UVM_HOME)/lib
	g++ -m32 -fPIC -DQUESTA -g -W -shared \
         -I$(QUESTA_HOME)/include \
         $(UVM_HOME)/src/dpi/uvm_dpi.cc \
         -o $(UVM_HOME)/lib/uvm_dpi.so
	vlog +incdir+$(UVM_SRC) +incdir+$(UVM_REG_HOME) $(UVM_REG_HOME)/uvm_register_pkg.sv
        

qvl_cmp:
	vlog -novopt -sv -mfcu +define+QVL_ASSERT_ON+QVL_COVER_ON $(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet/qvl_gigabit_ethernet_mii_monitor.sv \
           -y $(QUESTA_HOME)/verilog_src/std_ovl -y $(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet +incdir+$(QUESTA_HOME)/verilog_src/std_ovl \
           +incdir+$(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet +incdir+$(QUESTA_HOME)/qvl_src/qvl_checkers +libext+.sv


cmp: clean uvm_cmp qvl_cmp sv_bus_cmp

sv_bus_cmp: 
	test -e work || vlib work
	vlog +incdir+$(MAC_SRC_DIR) -y $(MAC_SRC_DIR) +libext+.v $(MAC_SRCS)
	vlog -suppress 2223 -suppress 2181  $(WB_BUS_SOURCES) \
	+incdir+$(WB_SRCS) \
	+incdir+$(ETH_SRCS) \
	+incdir+$(ANALYSIS_SRCS) \
	+incdir+$(WB_MII_SRCS) \
	+incdir+$(SEQUENCES_SRCS) \
	+incdir+$(MII_SRCS) \
	+incdir+$(TEST_SRCS) \
	+incdir+$(ENV_SRCS) \
	+incdir+$(UVM_REG_HOME) \
	+incdir+$(UVM_SRC)


tarball: clean tar

tar:
	@rm -f abstract-concrete.tgz; \
	cd .. ; \
	tar -czf abstract-concrete/abstract-concrete.tgz \
	abstract-concrete/env \
	abstract-concrete/eth \
	abstract-concrete/HISTORY \
	abstract-concrete/mac_core \
	abstract-concrete/mac_mii \
	abstract-concrete/Makefile \
	abstract-concrete/uvm \
	abstract-concrete/README.txt \
	abstract-concrete/sequences \
	abstract-concrete/tests \
	abstract-concrete/top_modules \
	abstract-concrete/ABSTRACT-CONCRETE_v28 \
	abstract-concrete/wishbone ;\
	cd abstract-concrete

clean: .FRC
	rm -rf  *.tmp  *.log  log transcript work *.wlf vsim.fcdb *.vstf
	find . -name "*~" -delete
        
.FRC:
       
