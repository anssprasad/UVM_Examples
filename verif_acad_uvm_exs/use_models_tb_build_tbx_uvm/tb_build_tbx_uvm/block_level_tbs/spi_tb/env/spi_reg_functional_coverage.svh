class spi_reg_functional_coverage extends uvm_subscriber #(apb_seq_item);

`uvm_component_utils(spi_reg_functional_coverage)

logic [4:0] address;
bit wnr;

bit[32:0] cntrl_data;
bit[15:0] div_ratio;

covergroup reg_rw_cov;
  ADDR: coverpoint address {
    bins DATA0 = {0};
    bins DATA1 = {4};
    bins DATA2 = {8};
    bins DATA3 = {5'hC};
    bins CTRL  = {5'h10};
    bins DIVIDER = {5'h14};
    bins SS = {5'h18};
  }
  CMD: coverpoint wnr {
    bins RD = {0};
    bins WR = {1};
  }
  RW_CROSS: cross CMD, ADDR;
endgroup: reg_rw_cov

covergroup combination_cov;
  ASS: coverpoint cntrl_data[13];
  IE: coverpoint cntrl_data[12];
  LSB: coverpoint cntrl_data[11];
  TX_NEG: coverpoint cntrl_data[10];
  RX_NEG: coverpoint cntrl_data[9];
  // Suspect character lengths - there may be more
  CHAR_LEN: coverpoint cntrl_data[6:0] {
    bins LENGTH[] = {0, 1, [31:33], [63:65], [95:97], 126, 127};
  }
  CLK_DIV: coverpoint div_ratio {
    bins RATIO[] = {16'h0, 16'h1, 16'h2, 16'h4, 16'h8, 16'h10, 16'h20, 16'h40, 16'h80};
/*              16'h100, 16'h200, 16'h400, 16'h800, 16'h1000, 16'h2000, 16'h4000, 16'h8000,
              16'hffff, 16'hfffe, 16'hfffd, 16'hfffb, 16'hfff7,
              16'hffef, 16'hffdf, 16'hffbf, 16'hff7f,
              16'hfeff, 16'hfdff, 16'hfbff, 16'hf7ff,
              16'hefff, 16'hdfff, 16'hbfff, 16'h7fff};*/
  }
  COMB_CROSS: cross ASS, IE, LSB, TX_NEG, RX_NEG, CHAR_LEN, CLK_DIV;
endgroup: combination_cov

extern function new(string name = "spi_reg_functional_coverage", uvm_component parent = null);
extern function void write(T t);

endclass: spi_reg_functional_coverage

function spi_reg_functional_coverage::new(string name = "spi_reg_functional_coverage", uvm_component parent = null);
  super.new(name, parent);
  reg_rw_cov = new();
  combination_cov = new();
endfunction

function void spi_reg_functional_coverage::write(T t);
  // Register coverage first
  address = t.addr[4:0];
  wnr = t.we;
  reg_rw_cov.sample();
  // Now keep the cntrl_data & div_ratio up to date
  // sampling when GO_BSY is written with a 1
  case(address)
    5'h10: begin
             if(wnr) begin
               if(t.data[8] == 0) begin
                 cntrl_data = t.data;
               end
               else begin
                 combination_cov.sample(); // TX started
               end
             end
           end
    5'h14: begin
             if(wnr) begin
               div_ratio = t.data[15:0];
             end
           end
  endcase
endfunction: write
