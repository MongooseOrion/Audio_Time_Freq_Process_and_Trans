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
// 人声音色调整
// *有跨时钟域处理*
module tone_aujusted#(
    parameter DATA_WIDTH = 16,
    parameter CHANGE_MODE = 1   // 0 为男变女，1 为女变男
)(   
    input                           process_clk,        // 工作时钟
    input                           sck,
    input                           rst_n/*synthesis PAP_MARK_DEBUG="1"*/,

    output      [DATA_WIDTH - 1:0]  ldata_out/*synthesis PAP_MARK_DEBUG="1"*/,
    output reg  [DATA_WIDTH - 1:0]  rdata_out/*synthesis PAP_MARK_DEBUG="1"*/,

    input       [DATA_WIDTH - 1:0]  ldata_in/*synthesis PAP_MARK_DEBUG="1"*/,
    input       [DATA_WIDTH - 1:0]  rdata_in/*synthesis PAP_MARK_DEBUG="1"*/

);

wire            almost_full/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]    rd_data_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]    rd_data_ram2/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]    wr_data_fifo /*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]    rd_data_fifo;
wire            wr_en_ram2/*synthesis PAP_MARK_DEBUG="1"*/; 
wire  [9:0]     wr_addr_ram1;
wire  [9:0]     wr_addr_ram2;

reg   [9:0]     cnt_1/*synthesis PAP_MARK_DEBUG="1"*/;
reg   [9:0]     cnt_2/*synthesis PAP_MARK_DEBUG="1"*/;
reg   [9:0]     rd_addr_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg             wr_en_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg             flag_1/*synthesis PAP_MARK_DEBUG="1"*/;     //重复抽样flag
reg             pose_wr_en_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg             nege_wr_en_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg             wr_en_fifo/*synthesis PAP_MARK_DEBUG="1"*/;
reg             wr_en_ram1_d1;
reg             wr_en_ram1_d2;
reg             pose_flag_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg             nege_flag_reg/*synthesis PAP_MARK_DEBUG="1"*/;

assign wr_data_fifo = wr_en_ram1 ? rd_data_ram2 : rd_data_ram1;
assign ldata_out = rd_data_fifo;


// 做边沿检测，工作时钟域
always @(posedge process_clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_en_ram1_d1 <= 'd0;
        wr_en_ram1_d2 <= 'd0;
    end
    else begin
        wr_en_ram1_d1 <= wr_en_ram1;
        wr_en_ram1_d2 <= wr_en_ram1_d1;
    end
end

always @(posedge process_clk or negedge rst_n) begin
    if(!rst_n) begin
        pose_wr_en_ram1 <= 'd0;
        nege_wr_en_ram1 <= 'd0;
    end
    else begin
        pose_wr_en_ram1 <= wr_en_ram1_d1 && (~wr_en_ram1_d2);
        nege_wr_en_ram1 <= (~wr_en_ram1_d1) && (wr_en_ram1_d2);
    end
end


// 计数 1024 个数据为一帧
always @(posedge sck or negedge rst_n) begin
    if(!rst_n) begin
        cnt_1 <= 'd0;
    end
    else if(cnt_1 == 'd1023) begin
        cnt_1 <= 'd0;
    end
    else begin
        cnt_1 <= cnt_1 + 1'b1;
    end
end
assign wr_addr_ram1 = cnt_1;
assign wr_addr_ram2 = cnt_1;


// 一个 ram 存一帧数据，同时只有一个 ram 使能，以便抽样后复制一份补齐采样序列数
always @(posedge sck or negedge rst_n) begin
    if(!rst_n) begin
        wr_en_ram1 <= 'd0;
    end
    else if(cnt_1 == 'd1023) begin
        wr_en_ram1 <= ~wr_en_ram1;  
    end
    else begin
        wr_en_ram1 <= wr_en_ram1;
    end
end
assign wr_en_ram2 = rst_n ? ~wr_en_ram1 : 1'b0;


// 人声变声逻辑
always @(posedge process_clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_addr_ram1 <= 'd0;
        flag_1 <= 1'b0;
    end
    else if((pose_wr_en_ram1) || (nege_wr_en_ram1)) begin
        rd_addr_ram1 <= 'd0;
        flag_1 <= 1'b0;  
    end
    else if(CHANGE_MODE == 'd0) begin
        if(((rd_addr_ram1 % 'd4) =='d0) && (flag_1 == 1'b0)) begin
            rd_addr_ram1 <= rd_addr_ram1;  
            flag_1 <= 1'b1;
        end
        else begin
            rd_addr_ram1 <= rd_addr_ram1 + 1'b1;
            flag_1 <= 1'b0;
        end 
    end
    else if(CHANGE_MODE == 1'b1) begin
        if((rd_addr_ram1 + 1'b1) % 'd2 == 'd0) begin
            rd_addr_ram1 <= rd_addr_ram1 + 2'b10;
        end
        else begin
            rd_addr_ram1 <= rd_addr_ram1 + 1'b1; 
        end
    end
end 


// fifo 写使能信号
always @(posedge process_clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_2 <= 'd0;
    end
    else if(wr_en_fifo == 1'b0) begin
        cnt_2 <= 'd0;
    end
    else begin
        cnt_2 <= cnt_2 + 1'b1;
    end
end

always @(posedge process_clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_en_fifo <= 'd0;
    end
    else if(cnt_2 == 'd1023) begin
        wr_en_fifo <= 1'b0;
    end
    else if ((pose_wr_en_ram1) || (nege_wr_en_ram1)) begin
        wr_en_fifo <= 1'b1;
    end
    else begin
        wr_en_fifo <= wr_en_fifo;
    end
end


tone_ram tone_ram_1 (
  .wr_data      (ldata_in),    // input [15:0]
  .wr_addr      (wr_addr_ram1),    // input [9:0]
  .wr_en        (wr_en_ram1),        // input
  .wr_clk       (sck),      // input
  .wr_rst       (!rst_n),      // input
  .rd_addr      (rd_addr_ram1),    // input [9:0]
  .rd_data      (rd_data_ram1),    // output [15:0]
  .rd_clk       (process_clk),      // input
  .rd_rst       (!rst_n)       // input
);

tone_ram tone_ram_2 (
  .wr_data      (ldata_in),    // input [15:0]
  .wr_addr      (wr_addr_ram2),    // input [9:0]
  .wr_en        (wr_en_ram2),        // input
  .wr_clk       (sck),      // input
  .wr_rst       (!rst_n),      // input
  .rd_addr      (rd_addr_ram1),    // input [9:0]
  .rd_data      (rd_data_ram2),    // output [15:0]
  .rd_clk       (process_clk),      // input
  .rd_rst       (!rst_n)       // input
);

// 输出缓冲
tone_fifo u_tone_fifo (
  .wr_clk               (process_clk),                // input
  .wr_rst               (!rst_n),                // input
  .wr_en                (wr_en_fifo),                  // input
  .wr_data              (wr_data_fifo),              // input [15:0]
  .wr_full              (),              // output
  .almost_full          (),      // output
  .rd_clk               (sck),                // input
  .rd_rst               (!rst_n),                // input
  .rd_en                (rst_n),                  // input
  .rd_data              (rd_data_fifo),              // output [15:0]
  .rd_empty             (),            // output
  .almost_empty         ()     // output
);

endmodule