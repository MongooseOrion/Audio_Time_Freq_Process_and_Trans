//******************************************************************

//******************************************************************
`timescale 1ns/1ns
module ehco_Cancelling
#(  
    parameter DATA_WIDTH = 8
)
(
    input                       sck,
    input                       clk,
    input                       rst_n/*synthesis PAP_MARK_DEBUG="1"*/,
    input [8:0]                 rs232_data,
    input                       rs232_flag,
    output reg [DATA_WIDTH - 1:0]  data_out/*synthesis PAP_MARK_DEBUG="1"*/,
    input   signed[DATA_WIDTH - 1:0]  data_in/*synthesis PAP_MARK_DEBUG="1"*/
);
parameter signed threshold_hign = 16'b0111111111111111;  //+32767
parameter signed threshold_low  = 16'b1000000000000000; // -32768
wire                almost_full/*synthesis PAP_MARK_DEBUG="1"*/;
reg                 rd_en/*synthesis PAP_MARK_DEBUG="1"*/;
wire  signed[15:0]  rd_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire  signed[15:0]  p_1/*synthesis PAP_MARK_DEBUG="1"*/;
wire [14:0]         wr_water_level;
wire [31:0]         p;
reg                 rs232_flag_clk_to_sck;
reg                 rs232_flag_sck_reg1;
reg                 rs232_flag_sck_reg2;
reg  [14:0]         set_delay;
reg  [15:0]         set_echo_Attenuation_factor;
reg  [14:0]         set_delay_sck;
reg  [15:0]         set_echo_Attenuation_factor_sck;
reg [12:0]          cnt;
assign p_1 = p[31:16];
//通过rs232 设置延时系数，和衰减因子
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        set_delay <= 'd7998;
        set_echo_Attenuation_factor <= 'd32767;
    end
    else if(rs232_flag==1'b1 && rs232_data[7:0] == 8'b00011111) begin
        set_delay <= 'd7998;
        set_echo_Attenuation_factor <= 'd32767;
    end
    else if(rs232_flag==1'b1 && rs232_data[7:0] == 8'b00010001) begin
        set_delay <=set_delay + 'd1000;
    end
    else if (rs232_flag==1'b1 && rs232_data[7:0] == 8'b00010010) begin
        set_delay <=set_delay - 'd1000;
    end
    else if(rs232_flag==1'b1 && rs232_data[7:0] == 8'b00011001) begin
        set_echo_Attenuation_factor <=set_echo_Attenuation_factor + 'd20;
    end
    else if (rs232_flag==1'b1 && rs232_data[7:0] == 8'b00011010) begin
        set_echo_Attenuation_factor <=set_echo_Attenuation_factor - 'd20;
    end
end


//跨时钟处理rs232_data，和rs232_flag信号
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        rs232_flag_clk_to_sck <= 'd0;
    end
    else if (cnt == 'd4095) begin
        rs232_flag_clk_to_sck <= 'd0;
    end
    else if(rs232_flag==1'b1) begin
        rs232_flag_clk_to_sck <= 1'b1;
    end
end
//计数rs232_flag_clk_to_sck 拉高时钟周期，拉高4000个后拉低,以便于在sck时钟下处理时能够被sck时钟捕获

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        cnt <= 'd0;
    end
    else if(rs232_flag_clk_to_sck==1'b1) begin
        cnt <= cnt + 1;
    end
end
//在sck时钟下将rs232_flag_clk_to_sck打两个周期的脉冲,跨时钟处理
always @(posedge sck or negedge rst_n)
begin
    if (~rst_n) begin
        rs232_flag_sck_reg1 <= 'd0;
        rs232_flag_sck_reg2 <= 'd0;
        set_delay_sck <= 'd0;
        set_echo_Attenuation_factor_sck <= 'd0;
    end
    else begin
        rs232_flag_sck_reg1 <= rs232_flag_clk_to_sck;
        rs232_flag_sck_reg2 <= rs232_flag_sck_reg1;
        set_delay_sck <= set_delay;
        set_echo_Attenuation_factor_sck <= set_echo_Attenuation_factor;

    end
end

always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        rd_en <= 'd0;
    end
    else if (rs232_flag_sck_reg2 == 1'b1) begin
        rd_en <= 1'b0;
    end
    else if(wr_water_level == set_delay_sck) begin
        rd_en <= 1'b1;
    end
    else begin
        rd_en <= rd_en;
    end
end

always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        data_out <= 'd0;
    end
    else if ((data_in - p_1)>=threshold_hign) begin
        data_out <= 16'b0111111111111111;
    end
    else if ((data_in - p_1)<=threshold_low) begin
        data_out <= 16'b1000000000000000;
    end
    else begin
        data_out <= data_in - p_1;
    end
end

echo_fifo echo_fifo_inst (
  .clk(sck),                      // input
  .rst(~rst_n | rs232_flag_sck_reg2),                      // input
  .wr_en(rst_n),                  // input
  .wr_data(data_out),              // input [15:0]
  .wr_full(wr_full),              // output
  .almost_full(almost_full),      // output
  .wr_water_level(wr_water_level),    // output [14:0]
  .rd_en(rd_en),                  // input
  .rd_data(rd_data),              // output [15:0]
  .rd_empty(rd_empty),            // output
  .almost_empty(almost_empty)     // output
);

simple_multi_16x16 simple_multi_16x16 (
  .a(rd_data),                         // input [15:0]
  .b(set_echo_Attenuation_factor_sck), // input [15:0]
  .clk(sck),                           // input
  .rst(~rst_n),                       /// input
  .ce(rd_en),                          // input
  .p(p)                                // output [31:0]
);

endmodule
