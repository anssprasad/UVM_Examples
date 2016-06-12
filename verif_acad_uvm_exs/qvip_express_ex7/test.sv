// This is an example of a test, it creates stimulus in the testbench
// and can check results (checking can also be in a scoreboard).
// A normal environment will have one testbench and multiple tests.
`define PARAM #( AXI4_ADDRESS_WIDTH, AXI4_RDATA_WIDTH,AXI4_WDATA_WIDTH,AXI4_ID_WIDTH,AXI4_USER_WIDTH,AXI4_REGION_MAP_SIZE )
module test(mentor_qvip_api_axi4_master axi4_master_qvip);

import uvm_pkg::*;
import dut_params_pkg::*;
import mgc_axi4_v1_0_pkg::*;

bit[31:0] rd_data;
bit[(AXI4_WDATA_WIDTH -1):0] burst_data [];
bit[((AXI4_WDATA_WIDTH / 8) -1):0] burst_write_strobe [];
bit[(AXI4_WDATA_WIDTH -1):0] random_data [bit[31:0]];

// Instantiate the testbench
// -------------------------

// Example test structure
// ----------------------
  initial begin
    simple_rd_wr_test();
    rand_burst_rd_wr_test();
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
// This task does random, consrained random and burst rd/wr
// --------------------------------------
  task rand_burst_rd_wr_test();
    bit[31:0] data_written[];
    //axi4_master_qvip.wait_for_reset;

    $display("Single Write test");
    axi4_master_qvip.single_write(32'h0, 32'haa55aa55);
    axi4_master_qvip.single_write(32'h4, 32'h55aa55aa);

    $display("Randomized Write test");
    for (int i = 0; i < 5 ; i++) begin
      // five randomized writes
      axi4_master_qvip.write(.address(32'h100 + (i * 8)),
                              .data_written(data_written)
                             );
      random_data[32'h100+(i*8)] = data_written[0];
      end 
    $display("Readback Randomized Write data test");
    for (int i = 0; i < 5 ; i++) begin
      axi4_master_qvip.single_read(.address(32'h100 + (i * 8)),
                                    .data(rd_data)
                                   );
      if ( rd_data == random_data[32'h100+(i*8)] ) begin
        $display("Match");
        end
      else begin
        $display("Mismatch Expected %32h Actual %32h", random_data[32'h100+(i*8)], rd_data);
        end
      end 

    $display("Repeat Randomized Write test this time with Constraints");
    axi4_master_qvip.set_default (.data_min(32'h00010000),
                                   .data_max(32'h0001FFFF)
                                  );
    for (int i = 0; i < 5 ; i++) begin
      // five randomized writes
      axi4_master_qvip.write(.address(32'h200 + (i * 8)),
                              .data_written(data_written)
                             );
      random_data[32'h200+(i*8)] = data_written[0];
      end 
    $display("Readback Randomized Write data test");
    for (int i = 0; i < 5 ; i++) begin
      axi4_master_qvip.single_read(.address(32'h200 + (i * 8)),
                                    .data(rd_data)
                                   );
      if ( rd_data == random_data[32'h200+(i*8)] ) begin
        $display("Match");
        end
      else begin
        $display("Mismatch Expected %32h Actual %32h", random_data[32'h200+(i*8)], rd_data);
        end
      end 

    $display("Single Read test");
    axi4_master_qvip.single_read(32'h0, rd_data);
    axi4_master_qvip.single_read(32'h4, rd_data);

    $display("Burst Write test");
    burst_data = new[8];
    burst_write_strobe = new[8];
    burst_data = {32'h00000000, 32'h11111111, 32'h22222222, 32'h33333333,
                  32'h44444444, 32'h55555555, 32'h66666666, 32'h77777777 }; 
    burst_write_strobe = {4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf, 4'hf };
    axi4_master_qvip.write(7, 32'h200, burst_data, burst_write_strobe);
    // Do it again with PROT set to AXI4_PRIV_SEC_INST
    axi4_master_qvip.write(7, 32'h200, burst_data, burst_write_strobe, AXI4_PRIV_SEC_INST);
  endtask: rand_burst_rd_wr_test

endmodule: test

