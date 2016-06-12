/*****************************************************************************
 *
 * Copyright 2008 Mentor Graphics Corporation 
 * All Rights Reserved.
 *
 * THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE PROPERTY OF 
 * MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.
 *
 *****************************************************************************/
          
module AXI4_slave_v #( parameter G_SLAVE_ADDR_SIZE=1024, G_AXI_ADDRESS_WIDTH = 32, G_AXI_RDATA_WIDTH = 1024, G_AXI_WDATA_WIDTH = 1024, G_AXI_ID_WIDTH = 4, G_USER_WIDTH = 4 )
(
    input  bit ACLK,
    input  bit ARESETn,
    input  bit AWVALID,
    input  bit [((G_AXI_ADDRESS_WIDTH) - 1):0]  AWADDR,
    input  bit [7:0] AWLEN,
    input  bit [2:0] AWSIZE,
    input  bit [1:0] AWBURST,
    input  bit AWLOCK,
    input  bit [3:0] AWCACHE,
    input  bit [2:0] AWPROT,
    input  bit [((G_AXI_ID_WIDTH) - 1):0]  AWID,
    output bit AWREADY,
    input  bit [(G_USER_WIDTH-1):0] AWUSER,
    input  bit ARVALID,
    input  bit [((G_AXI_ADDRESS_WIDTH) - 1):0]  ARADDR,
    input  bit [7:0] ARLEN,
    input  bit [2:0] ARSIZE,
    input  bit [1:0] ARBURST,
    input  bit ARLOCK,
    input  bit [3:0] ARCACHE,
    input  bit [2:0] ARPROT,
    input  bit [((G_AXI_ID_WIDTH) - 1):0]  ARID,
    output bit ARREADY,
    input  bit [(G_USER_WIDTH-1):0] ARUSER,
    output bit RVALID,
    output bit RLAST,
    output bit [(G_AXI_RDATA_WIDTH - 1):0]  RDATA,
    output bit [1:0] RRESP,
    output bit [(G_AXI_ID_WIDTH - 1):0]  RID,
    input  bit RREADY,
    output bit [(G_USER_WIDTH-1):0] RUSER,
    input  bit WVALID,
    input  bit WLAST,
    input  bit [(G_AXI_WDATA_WIDTH - 1):0]  WDATA,
    input  bit [(((G_AXI_WDATA_WIDTH / 8)) - 1):0]  WSTRB,
    output bit WREADY,
    input  bit [(G_USER_WIDTH-1):0] WUSER,
    output bit BVALID,
    output bit [1:0] BRESP,
    output bit [((G_AXI_ID_WIDTH) - 1):0]  BID,
    input  bit BREADY,
    output bit [(G_USER_WIDTH - 1):0] BUSER
);

    // declare the memory array
    bit [((G_AXI_RDATA_WIDTH>G_AXI_WDATA_WIDTH)?G_AXI_RDATA_WIDTH:G_AXI_WDATA_WIDTH)-1:0] ram[G_SLAVE_ADDR_SIZE];

    // State variables for state machine
    bit [1:0] write_states[1<<G_AXI_ID_WIDTH];
    bit read_states[1<<G_AXI_ID_WIDTH];
    bit [G_AXI_ADDRESS_WIDTH-1:0] write_addr[1<<G_AXI_ID_WIDTH];
    bit [3:0] write_count[1<<G_AXI_ID_WIDTH];
    bit [G_AXI_ADDRESS_WIDTH-1:0] read_addr[1<<G_AXI_ID_WIDTH];
    bit [3:0] read_count[1<<G_AXI_ID_WIDTH];
    bit [3:0] read_length[1<<G_AXI_ID_WIDTH];

    bit [31:0] AWREADY_vector = 32'b0001_0011_0100_1010_0110_0010_1010_1011;
    bit [31:0] ARREADY_vector = 32'b0010_1000_1101_0010_1100_0110_1100_1001;
    bit [40:0] WREADY_vector  = 41'b1_1001_0111_1010_1000_1111_0110_0010_0011_0110_1000;

    genvar i;

    always @(posedge ACLK ) AWREADY_vector <= ( AWVALID == 1'b1 ) ? { AWREADY_vector[0], AWREADY_vector[31:1] } : AWREADY_vector;
    always @(posedge ACLK ) ARREADY_vector <= ( ARVALID == 1'b1 ) ? { ARREADY_vector[0], ARREADY_vector[31:1] } : ARREADY_vector;
    always @(posedge ACLK )  WREADY_vector <= {  WREADY_vector[0],  WREADY_vector[40:1] };

    // Only accept input when in the correct state for the current *ID
    assign  AWREADY = ( write_states[AWID] == 2'b00 ) ? AWREADY_vector[0] : 1'b0;
    assign  ARREADY = ( read_states[ARID] == 1'b0   ) ? ARREADY_vector[0] : 1'b0;
    assign  WREADY  = ( write_states[AWID] == 2'b01 ) ?  WREADY_vector[0] : 1'b0;

    // Always OK resp and user data
    assign RRESP = '{2{1'b0}};
    assign RUSER = '{G_USER_WIDTH{1'b0}};
    assign BRESP = '{2{1'b0}};
    assign BUSER = '{G_USER_WIDTH{1'b0}};

    for ( i = 0; i < ( 1 << G_AXI_ID_WIDTH ) ; i++ )
    begin: state_machine
        always @(posedge ACLK or negedge ARESETn)
        begin
            if (!ARESETn)
            begin
                write_states[i] <= 2'b00;
                read_states[i]  <= 1'b0;
                write_addr[i] <= '{G_AXI_ADDRESS_WIDTH{1'b0}};
                write_count[i] <= 4'b0000;
                read_addr[i] <= '{G_AXI_ADDRESS_WIDTH{1'b0}};
                read_count[i] <= 4'b0000;
                read_length[i] <= 4'b0000;
            end
            else
            begin : state_machine
                case ( write_states[i] )
                2'b00:
                    begin    // Wait for write address
                        if ( ( AWVALID == 1'b1 ) && ( AWREADY == 1'b1 ) && ( AWID == i ) )
                        begin
                            write_addr[i]   <= AWADDR;
                            write_count[i]  <= 0;
                            write_states[i] <= 1;
                        end
                    end
                2'b01:
                    begin    // Wait for write data
                        if ( ( WVALID == 1'b1 ) && ( WREADY == 1'b1 ) && ( AWID == i ) )
                        begin
                            // Set the data in the RAM
                            ram[ ( write_addr[i] >> 2 ) + write_count[i] ] <= WDATA;
                            if ( WLAST == 1'b1 )
                            begin
                                write_states[i] <= 2;
                            end
                            else
                            begin
                                write_count[i] <= write_count[i] + 1;
                            end
                        end
                    end
                2'b10:
                    begin    // Write response state
                        if ( ( BVALID == 1'b1 ) && ( BREADY == 1'b1 ) && ( BID == i ) )
                        begin
                            write_states[i] <= 2'b00;
                        end
                    end
                default:
                    begin
                    end
                endcase // write

                case (read_states[i])
                1'b0:
                    begin    // Wait for read address
                        if ( ( ARVALID == 1'b1 ) && ( ARREADY == 1'b1 ) && ( ARID == i ) )
                        begin
                            read_addr[i]    <= ARADDR;
                            read_length[i]  <= ARLEN; 
                            read_count[i]   <= 0;
                            read_states[i]  <= 1;
                        end
                    end
                1'b1:
                    begin    // Read data state
                        if ( ( RVALID == 1 ) && ( RREADY == 1 ) && ( RID == i ) )
                        begin
                            if ( read_count[i] == read_length[i] )
                            begin
                                read_states[i] <= 1'b0;
                            end
                            else
                            begin
                                read_count[i] <= read_count[i] + 1;
                            end
                        end
                    end
                endcase // read
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn)
    begin
        if (!ARESETn)
        begin
            BID <= '{G_AXI_ID_WIDTH{1'b0}};
            RID <= '{G_AXI_ID_WIDTH{1'b0}};
        end
        else
        begin
            if ( ( BVALID == 1'b1 ) && ( BREADY == 1'b0 ) )
            begin
                BID <= BID;
            end
            else
            begin
                BID <= BID + 1;
            end
            if ( ( RVALID == 1'b1 ) && ( RREADY == 1'b0 ) )
            begin
                RID <= RID;
            end
            else
            begin
                RID <= RID + 1;
            end
        end
    end

    assign BVALID = ( write_states[ BID ] == 2'b10 );
    assign RVALID = ( read_states[ RID ] == 1'b1 );
    assign RDATA = ram[ ( read_addr[ RID ] >> 2 ) + read_count[ RID ] ];
    assign RLAST = ( read_count[ RID ] == read_length[ RID ] ) ? 1'b1 : 1'b0;

endmodule
 
