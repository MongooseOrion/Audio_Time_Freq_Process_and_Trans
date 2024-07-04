`timescale 1ns / 1ps
`define UD #1
module hdmi_spectrum # (
    parameter                            COCLOR_DEPP=8, // number of bits per channel
    parameter                            X_BITS=12,
    parameter                            Y_BITS=12,
    parameter                            H_ACT = 12'd1280,
    parameter                            V_ACT = 12'd720
)(                                       
    input                                rst_n, 
    input                                pix_clk,
    input                                clk,
    input [X_BITS-1:0]                   act_x/*synthesis PAP_MARK_DEBUG="1"*/,
    input [Y_BITS-1:0]                   act_y/*synthesis PAP_MARK_DEBUG="1"*/,
    input                                vs_in, 
    input                                hs_in, 
    input                                de_in/*synthesis PAP_MARK_DEBUG="1"*/,

    input                         xn_axi4s_cfg_tvalid,
    input                         xn_axi4s_cfg_tdata ,
    input                        xk_axi4s_data_tvalid,
    input [32*2-1:0]             xk_axi4s_data_tdata , 


    output wire [COCLOR_DEPP-1:0]         r_out, 
    output wire [COCLOR_DEPP-1:0]         g_out, 
    output wire [COCLOR_DEPP-1:0]         b_out,
    input wire [45:0]                    spectrum_data,
    input wire ['d6 - 'd1:0]             frame_CNT1 ,
    input [7:0]                          rs232_data,
    input [7:0]                          rs232_flag,
    input                                rst_clear
);
wire [24:0]  xk_axi4s_data_tdata_real;
wire [24:0]  xk_axi4s_data_tdata_imag;

parameter FFT_WIDTH = 'd10;
parameter DATA_WIDTH = 'd16;
parameter spectrum_inteval = 'd6;  //两个频谱的间距
parameter spectrum_high = (V_ACT - 3*spectrum_inteval)/2;  //每个频谱的显示高度
parameter spectrum_width = 'd512;  //每个频谱的显示的宽度
parameter spectrum_left_width = 'd20;  // 频谱左边间距
parameter PIXEL_SIZE = ((1 << 17) - 1)/spectrum_high;  //每个像素点表示的幅度大小
//取绝对值
reg         wr_en_gloab;
reg [9:0]   fft_out_cnt;
reg [25:0]  p3;  //写进ram1的值
reg [25:0]  p3_reg1;
reg [25:0]  p3_reg2; // 
wire [25:0] wr_data_ram2; //写进ram2的值
wire [17:0] p;
reg [17:0] p1;

reg        wr_en_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg        wr_en_ram1_reg;
reg        wr_en_ram2;
reg [8:0]   wr_addr_ram1;
reg [8:0]   wr_addr_ram2;
reg  [8:0] spectrum_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg [8:0]  rd_addr_ram/*synthesis PAP_MARK_DEBUG="1"*/;
reg [23:0] rgb_out/*synthesis PAP_MARK_DEBUG="1"*/;
wire [25:0] rd_data_ram1;
wire [25:0] rd_data_ram2;
reg    cnt1;
reg [7:0]  rs232_data_reg;
reg [23:0]  color_char = 24'hffffff;
// always @(posedge clk) begin
//     if (rs232_flag == 1'b1) begin
//         color_char <= 24'hffffff;
//     end
//     else if (rst_clear) begin
//         color_char <= 'd0;
//     end
// end
//频谱数据处理部分
assign   xk_axi4s_data_tdata_real = (xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH] == 1'b1) ? ~(xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH:0] - 1'b1) : xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH:0];
assign   xk_axi4s_data_tdata_imag = (xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH + 'd32] == 1'b1) ? ~(xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH + 'd32:32] - 1'b1) : xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH + 'd32:32];
assign   wr_data_ram2 = (spectrum_data['d44 - frame_CNT1] == 1'b1) ? 'd0 : p3_reg2;
assign r_out = rgb_out[23:16];
assign g_out = rgb_out[15:8];
assign b_out = rgb_out[7:0];
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en_gloab <= 1'b0;
    end
    else if (xn_axi4s_cfg_tvalid == 1'b1) begin
        wr_en_gloab <= xn_axi4s_cfg_tdata;      //我只要写入fft的结果，而非ifft
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        fft_out_cnt <= 'd0;
    end
    else if (xk_axi4s_data_tvalid == 1'b1) begin
        fft_out_cnt <= fft_out_cnt + 1'b1;
    end
    else begin
        fft_out_cnt <= 'd0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        p3 <= 'd0;
        wr_en_ram1_reg <= 'd0;
        wr_en_ram2 <= 'd0;
        p3_reg1 <= 'd0;
        p3_reg2 <= 'd0;

    end
    else begin
        p3 <= xk_axi4s_data_tdata_real +xk_axi4s_data_tdata_imag; //计算能量 
        wr_en_ram1_reg <= wr_en_ram1;
        wr_en_ram2 <= wr_en_ram1_reg;   //wr_en_ram2 要延时两排
        p3_reg1 <= p3;
        p3_reg2 <= p3_reg1;

    end
end

always @(posedge pix_clk) begin
    p1 <= {17{1'b1}} - p;
    rs232_data_reg <= rs232_data;
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en_ram1 <= 'd0;
    end
    else if(fft_out_cnt >= 'd1 && fft_out_cnt <= 'd512 && wr_en_gloab == 1'b1) begin  //fft模式的计算结果才写进去
        wr_en_ram1 <= 1'b1; //
    end
    else begin
        wr_en_ram1 <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_addr_ram1 <= 'd0;
    end
    else if(wr_en_ram1 == 1'b1) begin
        wr_addr_ram1 <= wr_addr_ram1 + 1'b1; 
    end
    else begin
        wr_addr_ram1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_addr_ram2 <= 'd0;
    end
    else if(wr_en_ram2 == 1'b1 ) begin
        wr_addr_ram2 <= wr_addr_ram2 + 1'b1; 
    end
    else begin
        wr_addr_ram2 <= 'd0;
    end
end


//在vga时序下读取频谱数据
always @(posedge pix_clk or negedge rst_n) begin
    if (~rst_n) begin
        spectrum_cnt <= 'd0;
    end
    else if(act_y <= spectrum_inteval + spectrum_high + 'd2) begin
        spectrum_cnt <= act_y - spectrum_inteval;   
    end
    else begin
        spectrum_cnt <= act_y - spectrum_inteval - spectrum_high - spectrum_inteval;
    end
end

//在visa时序下生成读ram的地址
always @(posedge pix_clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_addr_ram <= 'd0;
        cnt1 <= 'd0;
    end
    else if(act_x >= spectrum_left_width && de_in == 1'b1 && cnt1 == 1'b1) begin
        rd_addr_ram <= rd_addr_ram + 1'b1;   
        cnt1 <= ~cnt1;
    end
    else if ( de_in == 1'b1)begin
        rd_addr_ram <= rd_addr_ram;
        cnt1 <= ~cnt1;
    end
    else begin
        rd_addr_ram <= 'd0;
    end
end
//生成rgb输出数据
always @(posedge pix_clk or negedge rst_n) begin
    if (~rst_n) begin
        rgb_out <= 'd0;
    end
    else if((act_x >= (spectrum_left_width + 1'b1))&& (act_x <= (spectrum_left_width + spectrum_width + spectrum_width))&& (act_y >= spectrum_inteval + 1'b1) && (act_y <= spectrum_inteval + spectrum_high) && (rd_data_ram1 >= p1)) begin  //上半部分
        rgb_out <= color_char;   
    end
    else if((act_x >= (spectrum_left_width + 1'b1))&& (act_x <= (spectrum_left_width + spectrum_width + spectrum_width))&& (act_y >= spectrum_inteval + 1'b1 + spectrum_inteval + spectrum_high) && (act_y <= spectrum_inteval  + spectrum_inteval + spectrum_high +spectrum_high ) && (rd_data_ram2 >= p1) && (rs232_data_reg[7:4] == 4'd4  || rs232_data_reg[7:4] == 4'd3)) begin  //下半部分
        rgb_out <= color_char;   
    end
    else begin
        rgb_out <= 'd0;
    end
end

simple_length_512_width_26_ram spectrum_ram1 (
  .wr_data(p3),    // input [25:0]
  .wr_addr(wr_addr_ram1),    // input [8:0]
  .wr_en(wr_en_ram1),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n ),      // input
  .rd_addr(rd_addr_ram),    // input [8:0]
  .rd_data(rd_data_ram1),    // output [25:0]
  .rd_clk(pix_clk),      // input
  .rd_rst(~rst_n )       // input
);

simple_length_512_width_26_ram spectrum_ram2 (
  .wr_data(wr_data_ram2),    // input [25:0]
  .wr_addr(wr_addr_ram2),    // input [8:0]
  .wr_en(wr_en_ram2),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n ),      // input
  .rd_addr(rd_addr_ram),    // input [8:0]
  .rd_data(rd_data_ram2),    // output [25:0]
  .rd_clk(pix_clk),      // input
  .rd_rst(~rst_n )       // input
);

simple_multi_9x26 the_instance_name (
  .a('d373),        // input [8:0]
  .b(spectrum_cnt),        // input [8:0]
  .clk(pix_clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [17:0]
);

endmodule
