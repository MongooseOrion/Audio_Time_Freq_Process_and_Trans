// 计算欧氏几何距离
module disteu
#(
    parameter DATA_WIDTH         = 'd9,
    parameter ADDR_WIDTH         = 'd14,
    parameter DISTEU_RESULT_NUBMER = 'd31,
    parameter MEAN_FRAME_WIDTH   = 'd9 
)
(
    input                                 clk,
    input                                 rst_n,
    input  signed[DATA_WIDTH - 1'b1 : 0]  rd_data_d,
    output reg[ADDR_WIDTH - 1'b1 : 0]     rd_addr_d,    //待计算的ram,如z = disteu(d, r);   表示d的数据
    input  signed[DATA_WIDTH - 1'b1 : 0]  rd_data_r,
    output reg[8:0]                       rd_addr_r,    //待计算的ram,如z = disteu(d, r);   表示r的数据
    input                                 cfg_valid,
    input  [MEAN_FRAME_WIDTH -1'b1: 0]    cfg_data,
    input                                 cfg_last,
    input  [5: 0]                         cfg_mode_data,   //分高2位和低4位，如果高2位等于00，那么表示指定列与第（低4位列进行）列进行计算，结果输出是欧式距离和。 如果高2位是01，表示多列与多列进行计算，结果输出为数据流形式的比较大小的结果。高两位10，多对多，结果输出为每行的最小值，再求和
    output reg                            o_ready,
    output reg                            o_valid,
    output reg [29:0]                     o_data
);



reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        rd_addr;
wire [MEAN_FRAME_WIDTH - 1'b1 : 0]        rd_data;
reg [MEAN_FRAME_WIDTH - 1'b1 : 0]        wr_addr;

reg                                      ram_rst;
reg                                      cfg_valid_reg;
reg                                      cfg_valid_nedge_flag;
reg [7:0]                                state/*synthesis PAP_MARK_DEBUG="1"*/;
wire [13:0]                               p;
reg [7:0]                                addr_bias;
reg [3:0]                                wr_data_fifo;
wire [3:0]                                rd_data_fifo;
reg                                      wr_en_fifo;
reg                                      rd_en_fifo;
reg [5:0]                                cnt1;
reg [3:0]                                cnt2;
reg [3:0]                                cnt4;
reg [8:0]                                cnt3;

reg  [5: 0]                              cfg_mode_data_reg;
reg signed [9:0]                         result1;
wire [19:0]                              p1;
reg  [20:0]                              sum_data;
reg  [29:0]                              sum_data_end;
reg  [29:0]                              sum_data_end1;
reg                                      o_valid_mode01;
reg [2:0]                                cnt5;
parameter  INIT          = 8'b00000001;   //FIFO初始化
parameter  CFG_RAM       = 8'b00000010;   //配置ram
parameter  TIME_DELAY    = 8'b00000100;   //延迟4个时钟周期，以便能正确的赋值到初值
parameter  COMPUTE_INIT  = 8'b00001000;   //计算初始化
parameter  COMPUTE       = 8'b00010000;   //计算一次
parameter  RESULT_SAVE   = 8'b00100000;   //结果存储
parameter  RESULT_OUTPUT = 8'b01000000;   //最终输出

reg [8:0] addr_start [15:0];

  // 在初始化块中对数组进行初始化
initial begin
  addr_start[0]  = DISTEU_RESULT_NUBMER * 0;
  addr_start[1]  = DISTEU_RESULT_NUBMER * 1;
  addr_start[2]  = DISTEU_RESULT_NUBMER * 2;
  addr_start[3]  = DISTEU_RESULT_NUBMER * 3;
  addr_start[4]  = DISTEU_RESULT_NUBMER * 4;
  addr_start[5]  = DISTEU_RESULT_NUBMER * 5;
  addr_start[6]  = DISTEU_RESULT_NUBMER * 6;
  addr_start[7]  = DISTEU_RESULT_NUBMER * 7;
  addr_start[8]  = DISTEU_RESULT_NUBMER * 8;
  addr_start[9]  = DISTEU_RESULT_NUBMER * 9;
  addr_start[10] = DISTEU_RESULT_NUBMER * 10;
  addr_start[11] = DISTEU_RESULT_NUBMER * 11;
  addr_start[12] = DISTEU_RESULT_NUBMER * 12;
  addr_start[13] = DISTEU_RESULT_NUBMER * 13;
  addr_start[14] = DISTEU_RESULT_NUBMER * 14;
  addr_start[15] = DISTEU_RESULT_NUBMER * 15;
end


always @(*) begin          //最终输出的值
    if (~rst_n) begin
        o_valid <= 'd0;
        o_data <= 'd0;
    end
    else if (cfg_mode_data_reg[5:4] == 2'b01 ) begin
        o_valid <= o_valid_mode01;
        o_data <= {26'd0,rd_data_fifo[3:0]};
    end
    else if (cfg_mode_data_reg[5:4] == 2'b00) begin
        o_data <= sum_data_end;
        if (state == RESULT_OUTPUT) begin
            o_valid <= 1'b1;
        end
        else  begin
            o_valid <= 1'b0;
        end
    end
    else if (cfg_mode_data_reg[5:4] == 2'b10) begin
        o_data <= sum_data_end1;
        if (state == RESULT_OUTPUT) begin
            o_valid <= 1'b1;
        end
        else  begin
            o_valid <= 1'b0;
        end
    end
end

//
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cfg_valid_nedge_flag <= 'd0;
        cfg_valid_reg        <= 'd0;
    end
    else begin
        cfg_valid_nedge_flag <= (~cfg_valid) & cfg_valid_reg;  //下降沿检测
        cfg_valid_reg <= cfg_valid;
        o_valid_mode01 <= rd_en_fifo;
    end
end
// 状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= INIT;
    end
    else begin
        case (state)
            INIT:begin
                state <= CFG_RAM;
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
            end
            COMPUTE:begin
                if ( cnt1 == (DISTEU_RESULT_NUBMER + 'd4)) begin
                        state <= RESULT_SAVE;
                end
            end
            RESULT_SAVE:begin
                if (rd_addr == wr_addr) begin
                    state <= RESULT_OUTPUT;
                end
                else begin
                    state <= COMPUTE_INIT;
                end
                
            end
            RESULT_OUTPUT:begin
                if (cfg_mode_data_reg[5:4] == 2'b01) begin
                    if ( cnt3 == wr_addr - 1'b1 ) begin
                        state <= INIT;
                    end
                end
                else begin    //其他两种模式只停留一个时钟周期
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
        sum_data<= 'd0;
        addr_bias  <= 'd0;
        wr_en_fifo <= 1'b0;
        cnt1       <= 'd0;
        rd_en_fifo <= 1'b0;
        sum_data_end <= 'd0;
        cnt2  <='d0;
        sum_data_end1 <= 'd0;
        cnt3 <= 'd0;
        cfg_mode_data_reg <= 'd0;
        rd_addr_r <= 'd0;
        rd_addr_d <= 'd0;
        wr_data_fifo <= 'd0;
        rd_addr_d <= 'd0;
        result1 <= 'd0;
        cnt4 <= 'd0;
        cnt5 <= 'd0;
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
                wr_en_fifo <= 1'b0;
                cnt1 <= 'd0;
                rd_en_fifo <= 1'b0;
                sum_data_end <= 'd0;
                cnt2 <= 'd0;
                sum_data_end1 <= 'd0;
                cnt3 <= 'd0;
                cfg_mode_data_reg <= cfg_mode_data_reg;
                rd_addr_r <= 'd0;
                rd_addr_d <= 'd0;
                wr_data_fifo <= 'd0;
                rd_addr_d <= 'd0;
                result1 <= 'd0;
                cnt4 <= 'd0;
                cnt5 <= 'd0;
            end 
            CFG_RAM:begin
                ram_rst <= 'd0;
                cfg_mode_data_reg <= cfg_mode_data;    //保存模式配置
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
            end
            COMPUTE_INIT:begin

                if (cfg_mode_data_reg[5:4] == 2'b00 ) begin
                    rd_addr_d <= p[ADDR_WIDTH-1'b1:0] ;
                    rd_addr   <= rd_addr + 1'b1;
                    rd_addr_r <= addr_start[cfg_mode_data_reg[3:0]] ;
                    cnt1 <= 'd0;
                    sum_data <= 'd0;
                end
                else if (cfg_mode_data_reg[5:4] == 2'b01 || cfg_mode_data_reg[5:4] == 2'b10) begin
                    rd_addr_d <= p[ADDR_WIDTH-1'b1:0] ;
                    rd_addr_r <= addr_start[cnt2] ;
                    cnt1 <= 'd0;
                    sum_data <= 'd0;
                    wr_en_fifo <= 1'b0;
                    if (cnt2 == cfg_mode_data_reg[3:0]) begin
                        cnt2 <= 'd0;
                        rd_addr   <= rd_addr + 1'b1;
                    end
                    else begin
                        cnt2 <= cnt2 + 1'b1;
                    end

                end

            end
            COMPUTE:begin                  //无论哪种模式，都是求两列的欧式几何距离  
                rd_addr_d <= rd_addr_d + 1'b1;
                rd_addr_r <= rd_addr_r + 1'b1;
                cnt1 <= cnt1 + 1'b1;
                result1 <= rd_data_d - rd_data_r;
                if ((cnt1 >= 'd3) && (cnt1 <= (DISTEU_RESULT_NUBMER + 'd2))) begin
                    sum_data <= sum_data + p1[16:0];
                end
            end
            RESULT_SAVE:begin
                
                if (cfg_mode_data_reg[5:4] == 2'b00) begin
                    sum_data_end <= sum_data_end + sum_data;   //模式1的各列的欧式距离和 再输出
                end
                else if (cfg_mode_data_reg[5:4] == 2'b01) begin
                    cnt4 <= cnt4 + 1'b1;
                    if (cnt2 == 'd1) begin    //第一个值不比较，直接赋值
                        wr_data_fifo <= cnt2 - 1'b1;
                        sum_data_end <= {9'd0,sum_data[20:0]};   //存一下值，好比较大小
                    end
                    else if (sum_data_end[20:0] > sum_data) begin
                        wr_data_fifo <= cnt4;
                        sum_data_end <= {9'd0,sum_data[20:0]};   //大于，赋值
                    end
                    else begin
                        wr_data_fifo <= wr_data_fifo;
                    end
                    
                    if (cnt2 == 'd0) begin
                        wr_en_fifo <= 1'b1;
                        cnt4 <= 'd0;
                    end
                end
                else if (cfg_mode_data_reg[5:4] == 2'b10) begin
                    if (cnt2 == 'd1) begin    //第一个值不比较，直接赋值
                        sum_data_end <= {9'd0,sum_data[20:0]};   
                    end
                    else if (sum_data_end[20:0] > sum_data) begin
                        sum_data_end <= {9'd0,sum_data[20:0]};    //找到更小的值，替换
                    end
                    else begin
                        sum_data_end <= sum_data_end;
                    end

                    if (cnt2 == 'd0 && (sum_data_end[20:0] > sum_data) ) begin
                        sum_data_end1 <= sum_data_end1 + sum_data;    //因为状态机只到这里停留1个时钟周期，如果没有这个判断条件直接加sum_data_end，可能sum_data_end不是这一行的最小值
                    end
                    else if (cnt2 == 'd0) begin
                        sum_data_end1 <= sum_data_end1 + sum_data_end;
                    end

                end
            end
            RESULT_OUTPUT:begin
                wr_en_fifo <= 1'b0;
                if (cfg_mode_data_reg[5:4] == 2'b01) begin
                    if (cnt3 == wr_addr - 1'b1) begin
                        rd_en_fifo <= 1'b0;
                    end
                    else begin
                        rd_en_fifo <= 1'b1;
                    end  
                end

                if (rd_en_fifo == 1'b1) begin
                    cnt3 <= cnt3 + 1'b1;
                end
            end
        endcase
    end
end



length_512_width_9_ram  disteu_cfg_ram(   //存储计算列的ram
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
  .a(DISTEU_RESULT_NUBMER),        // input [4:0]
  .b(rd_data),        // input [8:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [13:0]
);

simple_multi_10x10 simple_multi_10x10_inst (    //
  .a(result1),        // input [9:0]
  .b(result1),        // input [9:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p1)         // output [19:0]
);

single_length_512_width_4_fifo single_length_512_width_4_fifo_inst (   
  .clk(clk),                      // input
  .rst((~rst_n) | ram_rst),                      // input
  .wr_en(wr_en_fifo),                  // input
  .wr_data(wr_data_fifo),              // input [3:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en_fifo),                  // input
  .rd_data(rd_data_fifo),              // output [3:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);



endmodule