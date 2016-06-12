// This is an example scoreboard component, it connects to one or many interfaces
// as provided by the axi_monitor block and can check traffic against expected.
// For Example:
// This can be used to check the descriptor packets flowing between the 
// controller block and the DMA in the ICE. 

// In this example it simply collects data from the interface and prints it

module scoreboard  #(int ADDR_WIDTH = 32,
                     int RDATA_WIDTH = 32,
                     int WDATA_WIDTH = 32,
                     int ID_WIDTH = 4,
                     int USER_WIDTH = 4,
                     int REGION_MAP_SIZE = 16) (interface SB1);

always begin
  @(SB1.newSample);
  if (SB1.readNotWrite == 1'b1) begin
    if (SB1.burst_length == 0) begin
       $display("Scoreboard: Saw a Single Read of address %8h data value %8h",SB1.addr, SB1.rdata[0]);
       end
    else begin
       $display("Scoreboard: Saw a Burst Read starting at address %8h with the following data",SB1.addr);
       for (int i=0; i < SB1.burst_length+1; i++) begin
         $display ("Scoreboard: Data value %8h",SB1.rdata[i]);
         end
       end
    end
  else begin // Write
    if (SB1.burst_length == 0) begin
       $display("Scoreboard: Saw a Single Write of address %8h data value %8h with write_strobe %1h",
                 SB1.addr, SB1.wdata[0], SB1.write_strobes[0]);
       end
    else begin
       $display("Scoreboard: Saw a Burst Write starting at address %8h with the following data",SB1.addr);
       for (int i=0; i < SB1.burst_length+1; i++) begin
         $display ("Scoreboard: Data value %8h with write_strobe %1h",SB1.wdata[i], SB1.write_strobes[i]);
         end
       end
    end 
end

endmodule: scoreboard
