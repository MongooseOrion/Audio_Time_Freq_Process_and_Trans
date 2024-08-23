module axi_interconnect_rd #(
    parameter MEM_ROW_WIDTH        = 15     ,
    parameter MEM_COLUMN_WIDTH     = 10     ,
    parameter MEM_BANK_WIDTH       = 3      ,
    parameter CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter DQ_WIDTH             = 'd32   ,
    parameter BURST_LEN            = 'd16         
)(
    input                               clk             /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               rst             ,
    input                               voice_clk       ,
    input [7:0]                         rs232_data      ,
    input                               rs232_flag      , 

    // AXI READ INTERFACE
    output reg                          axi_arvalid     /*synthesis PAP_MARK_DEBUG="1"*/,  
    input                               axi_arready     /*synthesis PAP_MARK_DEBUG="1"*/, 
    output reg [CTRL_ADDR_WIDTH-1:0]    axi_araddr      /*synthesis PAP_MARK_DEBUG="1"*/,  
                                                         
    input  [DQ_WIDTH*8-1:0]             axi_rdata       /*synthesis PAP_MARK_DEBUG="1"*/,  
    input                               axi_rvalid      /*synthesis PAP_MARK_DEBUG="1"*/,  
    input                               axi_rlast     /*synthesis PAP_MARK_DEBUG="1"*/ ,

    input [CTRL_ADDR_WIDTH-1:0]         axi_awaddr ,
    input                               record_valid ,
    output [15:0]                       record_vioce_out,
    input                               rd_start/*synthesis PAP_MARK_DEBUG="1"*/,
    output [15:0]                       voiceprint_vioce_out,
    output                              almost_full1   ,
    input                               rd_en_fifo    ,
    input                               mfcc_valid1,
    input [15:0]                        data_in   ,
    input                               sck                 

);

parameter    INIT            = 3'b001;         
parameter    AXI_ARADDR      = 3'b010;  //写进有效地址
parameter    AXI_RDATA       = 3'b100;  //写进有效数据

parameter    addr_step = BURST_LEN * 8 ;
parameter    MFCC_ADDR_MAX   = 6*48000*16/32;
reg   [2:0]    state/*synthesis PAP_MARK_DEBUG="1"*/;
reg  channel1_rready_reg1;
reg  channel1_rready_reg2;
reg      record_sound_valid_reg;
reg      record_sound_valid_reg1;
reg          record_sound_valid;
reg  [2:0]   record_cnt; 
reg  [2:0]   record_end_cnt; 
reg  [CTRL_ADDR_WIDTH-1:0]  record_addr_save [0:7];
initial begin
    record_addr_save[0] = MFCC_ADDR_MAX;
    record_addr_save[1] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[2] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[3] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[4] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[5] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[6] = {CTRL_ADDR_WIDTH{1'b0}};
    record_addr_save[7] = {CTRL_ADDR_WIDTH{1'b0}};
end
reg   record_valid_reg;
reg   record_valid_posedge;
reg   record_valid_negedge;

always @(posedge clk ) begin  //边沿检测
    record_valid_reg <= record_valid;
    record_valid_posedge <= (~record_valid_reg) & record_valid;
    record_valid_negedge <= (~record_valid    ) & record_valid_reg;
end

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        record_cnt <= 'd0;
    end
    else if (rs232_data == 8'b10100000 && rs232_flag == 1'b1) begin   //重新开始录制音频
        record_cnt <= 'd0;
    end
    else if (record_valid_negedge) begin
        record_cnt <= record_cnt + 1'b1;
        record_addr_save[record_cnt + 1'b1] <= axi_awaddr;
    end
end

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        record_sound_valid <= 'd0;
        record_end_cnt    <= 'd0;
    end
    else if (rs232_data[7:3] == 5'b10101 && rs232_flag == 1'b1) begin  //开始播放
        record_sound_valid <= 1'b1;
        record_end_cnt <= rs232_data[2:0] + 1'b1;
    end
    else if (axi_araddr == record_addr_save[record_end_cnt]) begin // 一段地址播放了停止播放停止播放
        record_sound_valid <= 1'b0;
    end
end

always @(posedge voice_clk) begin   //跨时钟域打排
    record_sound_valid_reg <= record_sound_valid;
    record_sound_valid_reg1 <= record_sound_valid_reg;
end

always @(posedge clk or negedge rst) begin   
    if (~rst) begin
        axi_araddr <= 'd0;
    end
    else if (rs232_data[7:3] == 5'b10101 && rs232_flag == 1'b1) begin
        axi_araddr <= record_addr_save[rs232_data[2:0]];    //该段音频的起始地址初始化
    end 
    else if (rs232_data[7:4] == 4'b0101 && rs232_flag == 1'b1) begin
        axi_araddr <= 'd0;
    end
    else if (axi_arready & axi_arvalid) begin
        axi_araddr <= axi_araddr + addr_step;
    end
end

//状态机跳转
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        state <= INIT;
    end
    else begin
        case (state)
            INIT:begin
                if ((record_sound_valid & ~almost_full) | (~almost_full2 & rd_start)) begin
                    state <= AXI_ARADDR;
                end
            end
            AXI_ARADDR:begin
                if (axi_arready & axi_arvalid) begin
                    state <= AXI_RDATA;
                end
            end 
            AXI_RDATA:begin
                if (axi_rlast == 1'b1) begin
                    state <= INIT;
                end
            end 
        endcase
    end
end
 
//相关信号变化
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        axi_arvalid <= 'd0;
    end
    else begin
        case (state)
            AXI_ARADDR:begin
                if ((axi_arready & axi_arvalid)) begin
                    axi_arvalid <= 1'b0;
                end
                else begin
                    axi_arvalid <= 1'b1;
                end
            end 
        endcase
    end
end

reg [15:0] data_in_max/*synthesis PAP_MARK_DEBUG="1"*/;
reg [15:0] data_in_ture;
//data_in 变成正数
always @(*) begin
    if (data_in[15] == 1'b1) begin
        data_in_ture = ~data_in + 1'b1;
    end
    else begin
        data_in_ture = data_in;
    end
end
//mfcc_valid1 在sck域打三拍
reg   mfcc_valid1_reg;
reg   mfcc_valid1_reg1;
reg   mfcc_valid1_reg2;
always @(posedge sck) begin
    mfcc_valid1_reg <= mfcc_valid1;
    mfcc_valid1_reg1 <= mfcc_valid1_reg;
    mfcc_valid1_reg2 <= mfcc_valid1_reg1;
end

//在mfcc_valid1的上升沿data_in_max清零，其他时候比较大小找出最大值
always @(posedge sck or negedge rst) begin
    if (~rst) begin
        data_in_max <= 'd0;
    end
    else if (mfcc_valid1_reg2 == 1'b0 && mfcc_valid1_reg1 == 1'b1) begin
        data_in_max <= 'd0;
    end
    else if (data_in_ture > data_in_max && mfcc_valid1_reg == 1'b1) begin
        data_in_max <= data_in_ture;
    end
    else begin
        data_in_max <= data_in_max;
    end
end


cache_ddr_rd_fifo cache_ddr_rd_fifo (
  .wr_clk(clk),                // input
  .wr_rst(~record_sound_valid),                // input
  .wr_en(axi_rvalid),                  // input
  .wr_data(axi_rdata),              // input [255:0]
  .wr_full(),              // output
  .almost_full(almost_full),      // output
  .rd_clk(voice_clk),                // input
  .rd_rst(1'b0),                // input
  .rd_en(record_sound_valid_reg1),                  // input
  .rd_data(record_vioce_out),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);
wire [15:0]   rd_data2/*synthesis PAP_MARK_DEBUG="1"*/;
wire [31:0]   q/*synthesis PAP_MARK_DEBUG="1"*/;
wire          done/*synthesis PAP_MARK_DEBUG="1"*/;
wire          busy/*synthesis PAP_MARK_DEBUG="1"*/;
parameter        INIT2          = 3'b001;
parameter        DIV_CFG        = 3'b010;
parameter        WAIT_RESULT    = 3'b100; 
reg  [3:0]   state2/*synthesis PAP_MARK_DEBUG="1"*/;
wire rd_en1/*synthesis PAP_MARK_DEBUG="1"*/;
assign rd_en1 = (state2 == DIV_CFG) ? 1'b1 : 1'b0;  
//状态机跳转
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        state2 <= INIT2;
    end
    else begin
        case (state2)
            INIT2 : begin
                if (rd_start == 1'b1 && almost_full2 == 1'b1 && busy == 1'b0 && almost_full1 == 1'b0) begin
                    state2 <= DIV_CFG;
                end
            end
            DIV_CFG : begin
                state2 <= WAIT_RESULT;
            end
            WAIT_RESULT : begin
                if (done == 1'b1) begin
                    state2 <= INIT2;
                end
            end
            default: state2 <= INIT2;
        endcase
    end
end



i_5_256_o_9_16_fifo i_5_256_o_9_16_fifo_inst (
  .clk(clk),                      // input
  .rst(~rd_start),                      // input
  .wr_en(axi_rvalid),                  // input
  .wr_data(axi_rdata),              // input [255:0]
  .wr_full(),              // output
  .almost_full(almost_full2),      // output
  .rd_en(rd_en1),                  // input
  .rd_data(rd_data2),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

i_10_16_a_768_fifo i_10_16_a_768_fifo_inst (
  .clk(clk),                      // input
  .rst(~rd_start),                      // input
  .wr_en(done),                  // input
  .wr_data(q[15:0]),              // input [15:0]
  .wr_full(),              // output
  .almost_full(almost_full1),      // output
  .rd_en(rd_en_fifo),                  // input
  .rd_data(voiceprint_vioce_out),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);


divider_signed divider_signed_inst (
	.dividend({rd_data2[15],rd_data2,15'd0}), 
	.divisor({16'd0,data_in_max}), 
	.start(rd_en1), 
	.clock(clk), 
	.reset(rst), 
	.q(q), 
	.r(), 
	.busy(busy),
    .done(done)
);

endmodule