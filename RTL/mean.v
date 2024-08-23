module mean 
#(
    parameter DATA_WIDTH         = 'd9,
    parameter ADDR_WIDTH         = 'd14,
    parameter MEAN_RESULT_NUBMER = 'd31,
    parameter MEAN_FRAME_WIDTH   = 'd9 
)
(
    input                                 clk,
    input                                 rst_n,
    input  signed[DATA_WIDTH - 1'b1 : 0]  data_in,
    output reg[ADDR_WIDTH - 1'b1 : 0]     addr,    //待计算的ram
    input                                 cfg_valid,
    input  [MEAN_FRAME_WIDTH -1'b1: 0]    cfg_data,
    input                                 cfg_last,
    output reg                            o_ready,
    output reg                            o_valid,
    output     [DATA_WIDTH - 1'b1:0]      o_data
);

reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        rd_addr;
wire [MEAN_FRAME_WIDTH - 1'b1 : 0]        rd_data;
reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        wr_addr;
reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        divide;
reg  signed [17:0]                       sum_data;
reg  [17:0]                             sum_data1;
reg                                      ram_rst;
reg                                      cfg_valid_reg;
reg                                      cfg_valid_nedge_flag;
reg [7:0]                                state;
wire [13:0]                               p;
reg [7:0]                                addr_bias;
reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        mean_data;
reg                                      rd_en_fifo;
reg [MEAN_FRAME_WIDTH - 1'b1 : 0]       mean_data_end;
reg [5:0]                                cnt1;
reg [2:0]                                cnt5;

wire done;
wire [31:0]   q/*synthesis PAP_MARK_DEBUG="1"*/;
reg start;

parameter  INIT          = 8'b00000001;   //FIFO初始化
parameter  CFG_RAM       = 8'b00000010;   //配置ram
parameter  COMPUTE_INIT  = 8'b00000100;   //计算初始化
parameter  COMPUTE       = 8'b00001000;   //计算一次
parameter  RESULT_SAVE   = 8'b00010000;   //结果存储
parameter  RESULT_OUTPUT = 8'b00100000;   //最终输出
parameter  TIME_DELAY    = 8'b01000000;   //延迟4个时钟周期，以便能正确的赋值到初值



always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cfg_valid_nedge_flag <= 'd0;
        cfg_valid_reg        <= 'd0;
        o_valid <= 'd0;
    end
    else begin
        cfg_valid_nedge_flag <= (~cfg_valid) & cfg_valid_reg;  //下降沿检测
        cfg_valid_reg <= cfg_valid;
        o_valid <= rd_en_fifo;
    end
end
// 状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= INIT;
        start <= 1'b0;
    end
    else begin
        case (state)
            INIT:begin
                state <= CFG_RAM;
                start <= 1'b0;
            end 
            CFG_RAM:begin
                if (cfg_last == 1'b1) begin
                    state <= TIME_DELAY;
                end
            end
            TIME_DELAY :begin
                if (cnt5 == 'd3) begin
                    state <= COMPUTE_INIT;
                end
            end
            COMPUTE_INIT:begin
                state <= COMPUTE;
                start <= 1'b0;
            end
            COMPUTE:begin
                if (rd_addr == (wr_addr + 'd6)) begin   //多两个时钟周期，确保已计算完
                    state <= RESULT_SAVE;
                    start <= 1'b1;
                end
            end
            RESULT_SAVE:begin
                start <= 1'b0;
                if (addr_bias == (MEAN_RESULT_NUBMER - 1'b1) && done == 1'b1) begin
                    state <= RESULT_OUTPUT;
                end
                else if(done == 1'b1) begin
                    state <= COMPUTE_INIT;
                end
                
            end
            RESULT_OUTPUT:begin
                if (cnt1 == MEAN_RESULT_NUBMER ) begin
                    state <= INIT;
                end
            end

        endcase
    end
end

// 内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ram_rst <= 'd0;
        o_ready <= 'd0;
        wr_addr <= 'd0;
        rd_addr <= 'd0;
        addr    <= 'd0;
        sum_data<= 'd0;
        addr_bias<= 'd0;
        cnt1 <= 'd0;
        rd_en_fifo <= 1'b0;
        // mean_data <= 'd0;
        cnt5 <= 'd0;
        divide <= 'd0;
    end
    else begin
        case (state)
            INIT:begin
                ram_rst <= 'd1;    //清空配置的ram 
                o_ready <= 'd0;    //ready 信号拉低
                wr_addr <= 'd0;
                rd_addr <= 'd0;
                sum_data<= 'd0;
                addr_bias <= 'd0;

                cnt1 <= 'd0;
                rd_en_fifo <= 1'b0;
                // mean_data <= 'd0;
                cnt5 <= 'd0;
                divide <= 'd0;
            end 
            CFG_RAM:begin
                ram_rst <= 'd0;
                if (cfg_last == 1'b1) begin
                    o_ready <= 'd0;
                end
                else begin
                    o_ready <= 'd1;
                end
                if (cfg_valid == 1'b1) begin
                    wr_addr <= wr_addr + 1'b1;  // wr_addr 可以看作计数信号 
                end
                else begin
                    wr_addr <= wr_addr;
                end
            end
            TIME_DELAY :begin
                cnt5 <= cnt5 + 1'b1;
                divide <= wr_addr;
            end
            COMPUTE_INIT:begin
                rd_addr <= 'd0;
                addr <= 'd0;

                sum_data <= 'd0;
            end
            COMPUTE:begin
                addr <= p + addr_bias;
                rd_addr <= rd_addr + 1'b1;
                if (rd_addr >= 'd4 && (rd_addr <= (wr_addr + 'd3))) begin
                    sum_data <= sum_data + data_in;
                end
                // mean_data <= sum_data1/wr_addr;
            end
            RESULT_SAVE:begin
                if (done == 1'b1) begin
                    addr_bias <= addr_bias + 1'b1;
                end
            end
            RESULT_OUTPUT:begin

                if (cnt1 == MEAN_RESULT_NUBMER ) begin
                    rd_en_fifo <= 1'b0;
                end
                else begin
                    rd_en_fifo <= 1'b1;
                end
                cnt1 <= cnt1 + 1'b1;
            end
        endcase
    end
end



length_512_width_9_ram  mean_cfg_ram(
  .wr_data(cfg_data),    // input [8:0]
  .wr_addr(wr_addr),    // input [8:0]
  .wr_en  (cfg_valid & o_ready),        // input
  .wr_clk (clk),      // input
  .wr_rst ((~rst_n) | ram_rst),      // input
  .rd_addr(rd_addr),    // input [8:0]
  .rd_data(rd_data),    // output [8:0]
  .rd_clk (clk),      // input
  .rd_rst ((~rst_n) | ram_rst)       // input
);

simple_multi_5x9_unsigned simple_multi_5x9_unsigned_inst (
  .a(MEAN_RESULT_NUBMER),        // input [4:0]
  .b(rd_data),        // input [8:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [13:0]
);

length_32_width_9_fifo length_32_width_9_fifo_inst (
  .clk(clk),                      // input
  .rst((~rst_n) | ram_rst),                      // input
  .wr_en(done),                  // input
  .wr_data(q[8:0]),              // input [8:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en_fifo),                  // input
  .rd_data(o_data),              // output [8:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);


divider_signed divider_signed_inst (
	.dividend({ {14{sum_data[17]}},sum_data}), 
	.divisor({23'd0,divide}), 
	.start(start), 
	.clock(clk), 
	.reset(rst_n), 
	.q(q), 
	.r(), 
	.busy(),
    .done(done)
);

endmodule