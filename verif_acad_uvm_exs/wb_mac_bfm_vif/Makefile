
UVM_HOME ?= $(dir $(shell which vsim))../verilog_src/uvm-1.1
UVM_SRC = $(UVM_HOME)/src
UVM_REG_HOME = ./uvm/src/uvm_register-2.0/src
QUESTA_HOME ?= $(dir $(shell which vsim))/..
WB_SRCS = ./wishbone
SEQUENCES_SRCS = ./sequences
MII_SRCS = ./mac_mii
TEST_SRCS = ./tests
ETH_SRCS = ./eth
ENV_SRCS = ./env
TOP_SRCS = ./top_modules

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
        $(WB_SRCS)/wb_bus_wrapper.sv \
        $(TOP_SRCS)/top.sv \
        $(TOP_SRCS)/top_mac.sv

MAC_SRC_DIR = ./mac_core
MAC_SRCS = $(MAC_SRC_DIR)/eth_top.v

normal: clean cmp sim


gui: clean cmp
	vsim +nowarnTSCALE -voptargs="+acc" top top_mac -suppress 3829

sim: 
	vsim +nowarnTSCALE -c top top_mac -suppress 3829 -do "run -all" 
	@echo " " 
	@echo "---- To verify your output is correct scroll up the output to above"
	@echo "---- the report summary and look for the following lines:"
	@echo " " 
	@echo " Number of Ethernet transactions sent (Tx) by the MAC: 3      " 
	@echo " Number of Ethernet transactions received (Rx) by the MAC: 4  "
	@echo " Number of Tx Errors: 0                                       "
	@echo " Number of Rx Errors: 0                                       "
	@echo " "
	@echo " Number of Wishbone 0 Slave Memory write transactions: 134    "
	@echo " Number of Wishbone 0 Slave Memory read  transactions: 135    "
	@echo " Number of Wishbone 0 Non-Slave Memory write cycles: 33       "
	@echo " Number of Wishbone 0 Non-Slave Memory read cycles: 22        "
	@echo " Wishbone 0 Slave Memory read error count: 0                  "
	@echo " "

bus: clean cmp
	vsim +nowarnTSCALE -c top_mac -suppress 3829 -do "run -all"

debug: clean cmp
	vsim +nowarnTSCALE -gui -voptargs="+acc" top_mac -suppress 3829 -UVMdebug

uvm_cmp: 
	test -e work || vlib work
	vlog +incdir+$(UVM_SRC) +incdir+$(UVM_REG_HOME) $(UVM_REG_HOME)/uvm_register_pkg.sv

qvl_cmp:
	vlog -novopt -sv -mfcu +define+QVL_ASSERT_ON+QVL_COVER_ON $(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet/qvl_gigabit_ethernet_mii_monitor.sv \
           -y $(QUESTA_HOME)/verilog_src/std_ovl -y $(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet +incdir+$(QUESTA_HOME)/verilog_src/std_ovl \
           +incdir+$(QUESTA_HOME)/qvl_src/qvl_monitors/gigabit_ethernet +incdir+$(QUESTA_HOME)/qvl_src/qvl_checkers +libext+.sv


cmp: clean uvm_cmp sv_bus_cmp

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
	@rm -f wb_mac_bfm_vif.tar; \
	rm -f wb_mac_bfm_vif.tar.gz ; \
	cd .. ; \
	tar -zcf wb_mac_bfm_vif/wb_mac_bfm_vif.tgz \
	wb_mac_bfm_vif/env \
	wb_mac_bfm_vif/eth \
	wb_mac_bfm_vif/mac_core \
	wb_mac_bfm_vif/mac_mii \
	wb_mac_bfm_vif/Makefile \
	wb_mac_bfm_vif/uvm \
	wb_mac_bfm_vif/README.txt \
	wb_mac_bfm_vif/sequences \
	wb_mac_bfm_vif/tests \
	wb_mac_bfm_vif/top_modules \
	wb_mac_bfm_vif/WB_TWO_KINDOMS_CC_INST_v28 \
	wb_mac_bfm_vif/wishbone ;\
	cd wb_mac_bfm_vif; 

clean: .FRC
	rm -rf  *.tmp  *.log  log transcript work *.wlf vsim.fcdb *.vstf
	find . -name "*~" 
        
.FRC:
