/*****************************************************************************
 *
 * Copyright 2010 Mentor Graphics Corporation 
 * All Rights Reserved.
 *
 * THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE PROPERTY OF 
 * MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.
 *
 *****************************************************************************/

import uvm_pkg::*;
`define PARAM #( AXI4_ADDRESS_WIDTH, AXI4_RDATA_WIDTH,AXI4_WDATA_WIDTH,AXI4_ID_WIDTH,AXI4_USER_WIDTH,AXI4_REGION_MAP_SIZE )
`define DUT_PARAM #(1024, AXI4_ADDRESS_WIDTH, AXI4_RDATA_WIDTH, AXI4_WDATA_WIDTH, AXI4_ID_WIDTH, AXI4_USER_WIDTH) 

module clock_reset( output bit ACLK , output bit ARESETn );

  initial begin
    ACLK = 0;
    forever #7 ACLK = ~ACLK;
  end

  initial begin
    ARESETn = 0;
    #40 ARESETn = 1;
  end
endmodule


// Module: top
// This instantiates a <mgc_axi4> interface 
module top;
  import dut_params_pkg::*;
  import mgc_axi4_v1_0_pkg::*;

    // system signals
    wire ACLK    ;
    wire ARESETn ;

    // write address channel signals
    wire                              AWVALID ;
    wire [AXI4_ADDRESS_WIDTH-1:0]    AWADDR ;
    wire [3:0]                        AWLEN ;
    wire [2:0]                        AWSIZE ;
    wire [1:0]                        AWBURST ;
    wire [1:0]                        AWLOCK ;
    wire [3:0]                        AWCACHE ;
    wire [2:0]                        AWPROT ;
    wire [AXI4_ID_WIDTH-1:0]         AWID ;
    wire                              AWREADY ;

    // read address channel signals
    wire                              ARVALID ;
    wire [AXI4_ADDRESS_WIDTH-1:0]    ARADDR ;
    wire [3:0]                        ARLEN ;
    wire [2:0]                        ARSIZE ;
    wire [1:0]                        ARBURST ;
    wire [1:0]                        ARLOCK ;
    wire [3:0]                        ARCACHE ;
    wire [2:0]                        ARPROT ;
    wire [AXI4_ID_WIDTH-1:0]         ARID ;
    wire                              ARREADY ;

    // read channel (data) signals
    wire                              RVALID ;
    wire                              RLAST ;
    wire[AXI4_RDATA_WIDTH-1:0]       RDATA ;
    wire[1:0]                         RRESP ;
    wire[AXI4_ID_WIDTH-1:0]          RID ;
    wire                              RREADY ;

    // write channel signals
    wire                              WVALID ;
    wire                              WLAST ;
    wire [AXI4_WDATA_WIDTH-1:0]      WDATA ;
    wire [(((AXI4_WDATA_WIDTH / 8)) - 1):0]  WSTRB;
    wire [AXI4_ID_WIDTH-1:0]         WID ;
    wire                              WREADY ;

    // write response channel signals
    wire                              BVALID ;
    wire[1:0]                         BRESP ;
    wire[AXI4_ID_WIDTH-1:0]          BID ;
    wire                              BREADY ;

    //user signals
    wire [AXI4_USER_WIDTH-1:0] AWUSER;
    wire [AXI4_USER_WIDTH-1:0] ARUSER;
    wire[AXI4_USER_WIDTH-1:0] RUSER;
    wire [AXI4_USER_WIDTH-1:0] WUSER;
    wire[AXI4_USER_WIDTH-1:0] BUSER;

//test data
bit[31:0] rd_data;
bit[(AXI4_WDATA_WIDTH -1):0] burst_data [];
bit[((AXI4_WDATA_WIDTH / 8) -1):0] burst_write_strobe [];

// Monitor interface
// Shows high level traffic detected on interface
//
mon_if `PARAM mon_if_i();

// Instantiate the QVIP Express AXI4 Master, Slave, Monitor  modules
// ----------------------------------------------------
//mentor_qvip_api_axi4_slave `PARAM dma_slave1(.AXI4());
//mentor_qvip_api_axi4_monitor `PARAM dma_internal_monitor(.AXI4(),.MON(mon_if_i));
// Instantiate a Verilog slave dut
mentor_qvip_api_axi4_master `PARAM axi4_master_qvip
                             (
                             .ACLK    (ACLK),
                             .ARESETn (ARESETn),
                             .AWVALID (AWVALID),
                             .AWADDR  (AWADDR),
                             .AWLEN   (AWLEN),
                             .AWSIZE  (AWSIZE),
                             .AWBURST (AWBURST),
                             .AWLOCK  (AWLOCK),
                             .AWCACHE (AWCACHE),
                             .AWPROT  (AWPROT),
                             .AWID    (AWID),
                             .AWREADY (AWREADY),
                             .AWUSER  (AWUSER),
                             .ARVALID (ARVALID),
                             .ARADDR  (ARADDR),
                             .ARLEN   (ARLEN),
                             .ARSIZE  (ARSIZE),
                             .ARBURST (ARBURST),
                             .ARLOCK  (ARLOCK),
                             .ARCACHE (ARCACHE),
                             .ARPROT  (ARPROT),
                             .ARID    (ARID),
                             .ARREADY (ARREADY),
                             .ARUSER  (ARUSER),
                             .RVALID  (RVALID),
                             .RLAST   (RLAST),
                             .RDATA   (RDATA),
                             .RRESP   (RRESP),
                             .RID     (RID),
                             .RREADY  (RREADY),
                             .RUSER   (RUSER),
                             .WVALID  (WVALID),
                             .WLAST   (WLAST),
                             .WDATA   (WDATA),
                             .WSTRB   (WSTRB),
                             .WID     (WID),
                             .WREADY  (WREADY),
                             .WUSER   (WUSER),
                             .BVALID  (BVALID),
                             .BRESP   (BRESP),
                             .BID     (BID),
                             .BREADY  (BREADY),
                             .BUSER   (BUSER)
                             );

  clock_reset iclock_reset( .ACLK( ACLK ), .ARESETn( ARESETn ) );

// Instantiate a scoreboard
scoreboard scbd (.SB1(mon_if_i));

// Instantiate a Verilog slave dut
  AXI4_slave_v `DUT_PARAM dut_slave_i (
                             .ACLK    (ACLK),
                             .ARESETn (ARESETn),
                             .AWVALID (AWVALID),
                             .AWADDR  (AWADDR),
                             .AWLEN   (AWLEN),
                             .AWSIZE  (AWSIZE),
                             .AWBURST (AWBURST),
                             .AWLOCK  (AWLOCK),
                             .AWCACHE (AWCACHE),
                             .AWPROT  (AWPROT),
                             .AWID    (AWID),
                             .AWREADY (AWREADY),
                             .AWUSER   (AWUSER),
                             .ARVALID (ARVALID),
                             .ARADDR  (ARADDR),
                             .ARLEN   (ARLEN),
                             .ARSIZE  (ARSIZE),
                             .ARBURST (ARBURST),
                             .ARLOCK  (ARLOCK),
                             .ARCACHE (ARCACHE),
                             .ARPROT  (ARPROT),
                             .ARID    (ARID),
                             .ARREADY (ARREADY),
                             .ARUSER   (ARUSER),
                             .RVALID  (RVALID),
                             .RLAST   (RLAST),
                             .RDATA   (RDATA),
                             .RRESP   (RRESP),
                             .RID     (RID),
                             .RREADY  (RREADY),
                             .RUSER   (RUSER),
                             .WVALID  (WVALID),
                             .WLAST   (WLAST),
                             .WDATA   (WDATA),
                             .WSTRB   (WSTRB),
                             .WREADY  (WREADY),
                             .WUSER   (WUSER),
                             .BVALID  (BVALID),
                             .BRESP   (BRESP),
                             .BID     (BID),
                             .BREADY  (BREADY),
                             .BUSER   (BUSER)
                             );

  initial begin
  //Start the UVM test
  uvm_run_phase::get().raise_objection( null , "prevent early termination" );
  run_test();
  end

// Example test 
// ----------------------
  initial begin
    simple_rd_wr_test();
    burst_rd_wr_test();
    $finish;
  end
      
// -----------------------------
  task simple_rd_wr_test();
    #500; 
    $display("Single Write test");
    axi4_master_qvip.single_write(32'h0, 32'haa55aa55);
    axi4_master_qvip.single_write(32'h4, 32'h55aa55aa);
    #500; 
    $display("Single Read test");
    axi4_master_qvip.single_read(32'h0, rd_data);
    axi4_master_qvip.single_read(32'h4, rd_data);
    #100;
  endtask: simple_rd_wr_test


// --------------------------------------
// This task does burst rd/wr
// --------------------------------------
  task burst_rd_wr_test();
    //axi4_master_qvip.wait_for_reset;

    $display("Burst Write test");
    burst_data = new[8];
    burst_write_strobe = new[8];
    burst_data = {32'h00000000, 32'h11111111, 32'h22222222, 32'h33333333,
                  32'h44444444, 32'h55555555, 32'h66666666, 32'h77777777 }; 
    burst_write_strobe = {4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf };
    axi4_master_qvip.write(7, 32'h200, burst_data, burst_write_strobe);
    // Do it again with PROT set to AXI4_PRIV_SEC_INST
    axi4_master_qvip.write(7, 32'h200, burst_data, burst_write_strobe, AXI4_PRIV_SEC_INST);
  endtask: burst_rd_wr_test
endmodule
