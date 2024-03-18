/* =======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: GBK
* ========================================================================
*/
// 回声消除
//
`timescale 1ns/1ns
module voice_echo_reduced #(  
    parameter signed    threshold_high = 17'b01000000000000000, 
    parameter signed    threshold_low  = 17'b10000000000000000, 
    parameter           DATA_WIDTH = 8
)
(
    input                                   sck,
    input                                   rst_n,
    input       signed  [DATA_WIDTH - 1:0]  data_in,

    output  reg         [DATA_WIDTH - 1:0]  data_out
);

wire                almost_full/*synthesis PAP_MARK_DEBUG="1"*/;
wire                wr_en;
wire signed [15:0]  rd_data/*synthesis PAP_MARK_DEBUG="1"*/;

reg                 rd_en/*synthesis PAP_MARK_DEBUG="1"*/;

assign wr_en = rst_n;


// almost_full 值设置为窗口宽度，采样序列达到值则开始处理
always @(posedge sck or negedge rst_n) begin
    if(!rst_n) begin
        rd_en <= 'd0;
    end
    else if(almost_full == 1'b1) begin
        rd_en <= 1'b1;
    end
    else begin
        rd_en <= rd_en;
    end
end


// 有符号数的阈值判断
always @(posedge sck or negedge rst_n)
begin
    if(!rst_n) begin
        data_out <= 'd0;
    end
    else begin
        if ((data_in-(rd_data/2)) >= threshold_high) begin      // 限幅
            data_out <= 16'b0111111111111111;
        end
        else if ((data_in-(rd_data/2)) <= threshold_low) begin  // 限幅
            data_out <= 16'b1000000000000000;
        end
        else begin
            data_out <= data_in - (rd_data/2);          // 线性数字滤波权重系数 0.5
        end
    end
end


echo_fifo u_echo_fifo(
  .clk              (sck),                      // input
  .rst              (!rst_n),                      // input
  .wr_en            (wr_en),                  // input
  .wr_data          (data_out),              // input [15:0]
  .wr_full          (wr_full),              // output
  .almost_full      (almost_full),      // output
  .rd_en            (rd_en),                  // input
  .rd_data          (rd_data),              // output [15:0]
  .rd_empty         (),            // output
  .almost_empty     ()     // output
);

endmodule
