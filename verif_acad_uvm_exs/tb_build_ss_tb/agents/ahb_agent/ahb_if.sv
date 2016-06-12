interface ahb_if(
                 input HCLK,
                 input HRESETn
                );

    logic [31:0]  HADDR;
    logic [1:0] HTRANS;
    logic HWRITE;
    logic [2:0] HSIZE;
    logic [2:0] HBURST;
    logic [3:0] HPROT;
    logic [31:0]  HWDATA;
    logic [31:0]  HRDATA;
    logic [1:0] HRESP;
    logic HREADY;
    logic HSEL;

endinterface: ahb_if