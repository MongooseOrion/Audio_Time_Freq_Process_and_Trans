`timescale  1ns/1ns
module mfcc_feature_extraction_tb (
    
);

reg           rst;
reg           sck;
reg           clk;
reg    [15:0] data_in;
reg           xn_axi4s_data_tready;
reg                          xk_axi4s_data_tvalid;
reg   [32*2-1:0]             xk_axi4s_data_tdata ;
reg                          xk_axi4s_data_tlast ;
integer    i;
integer    j;
reg grs_n;



initial begin
    xk_axi4s_data_tvalid <=1'b0;
    xk_axi4s_data_tlast <= 1'b0;
    xk_axi4s_data_tdata <= 'd0;
    xn_axi4s_data_tready <= 'd0;
    data_in <= 'd0;
    sck = 1'b1;
    clk = 1'b1;
    rst <= 1'b0;
    #1000
    rst <= 1'b1;

    for(i = 1; i < 4000; i = i + 1)
    begin
        data_in <= i;
        #(1000);
    end
end

initial begin
    #1000;
    #(1000*1100);
    xn_axi4s_data_tready <= 1'b1;
    #(1000*10);
    xn_axi4s_data_tready <= 1'b0;

    #10000;
    xk_axi4s_data_tvalid <=1'b1;
    for(j = 1; j < 1025; j = j + 1)
    begin
        xk_axi4s_data_tdata <= j;
        #(10);
        if (j == 1023) begin
            xk_axi4s_data_tlast <= 1'b1;  //模拟fft数据计算输出
        end
    end
    xk_axi4s_data_tvalid <=1'b0;
    xk_axi4s_data_tlast <= 1'b0;


 

    #(1000*1000);
    xn_axi4s_data_tready <= 1'b1;
    #(1000*10);
    xn_axi4s_data_tready <= 1'b0;


    xk_axi4s_data_tvalid <=1'b1;
    for(j = 1; j < 257; j = j + 1)
    begin
        xk_axi4s_data_tdata <= j;
        #(10);
        if (j == 255) begin
            xk_axi4s_data_tlast <= 1'b1;  //模拟fft数据计算输出
        end
    end
    xk_axi4s_data_tvalid <=1'b0;
    xk_axi4s_data_tlast <= 1'b0;


 

end

always #500 sck = ~sck;
always #5 clk = ~clk;


mfcc_feature_extraction #(
    .DATA_WIDTH(16)
)mfcc_feature_extraction_inst(
    .rst_n          (rst),// input
    .sck            (sck   ),// input
    .clk            (clk),
    .data_in        (data_in      ),// input[15:0]
    .xn_axi4s_data_tready(xn_axi4s_data_tready),
    .xk_axi4s_data_tvalid(xk_axi4s_data_tvalid),
    .xk_axi4s_data_tdata(xk_axi4s_data_tdata),
    .xk_axi4s_data_tlast(xk_axi4s_data_tlast)



);
GTP_GRS GRS_INST(
.GRS_N (grs_n)
);

endmodule