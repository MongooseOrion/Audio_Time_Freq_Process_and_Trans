`timescale  1ns/1ns
module vqlbg_train_tb (
    
);

reg           rst;
reg           clk;


reg grs_n;



initial begin
    clk = 1'b1;
    rst <= 1'b0;
    #10
    rst <= 1'b1;


end

always #5 clk = ~clk;
GTP_GRS GRS_INST(
.GRS_N (grs_n)
);

vqlbg_train vqlbg_train_inst (
.clk(clk),
.rst_n(rst)
);

endmodule