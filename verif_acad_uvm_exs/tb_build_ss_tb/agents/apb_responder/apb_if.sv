interface apb_if(input PCLK,
                 input PRESETn);

  logic[31:0] PADDR;
  logic[31:0] PRDATA;
  logic[31:0] PWDATA;
  logic PSEL;
  logic PENABLE;
  logic PWRITE;
  logic PREADY;

endinterface: apb_if