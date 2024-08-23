module axi_interconnect_wr #(
    parameter MEM_ROW_WIDTH        = 15     ,
    parameter MEM_COLUMN_WIDTH     = 10     ,
    parameter MEM_BANK_WIDTH       = 3      ,
    parameter CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter DQ_WIDTH             = 'd32   ,
    parameter BURST_LEN            = 'd16                         
)(
    input                               clk,                // ddr core clk
    input                               rst,
    input [7:0]                         rs232_data,
    input                               rs232_flag, 
    input                               audio_data_valid,
    // 通道 1  
    input                               channel1_rready /*synthesis PAP_MARK_DEBUG="1"*/,
    input       [DQ_WIDTH*8-1'b1:0]     channel1_data   /*synthesis PAP_MARK_DEBUG="1"*/,
    output                              channel1_rd_en  /*synthesis PAP_MARK_DEBUG="1"*/,
    input       [CTRL_ADDR_WIDTH-1:0]   axi_araddr      /*synthesis PAP_MARK_DEBUG="1"*/,

    // AXI WRITE INTERFACE 
    output reg [CTRL_ADDR_WIDTH-1:0]    axi_awaddr      /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_awready     /*synthesis PAP_MARK_DEBUG="1"*/,
    output reg                          axi_awvalid     /*synthesis PAP_MARK_DEBUG="1"*/,

    output [DQ_WIDTH*8-1'b1:0]          axi_wdata       /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_wlast       /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_wready,      /*synthesis PAP_MARK_DEBUG="1"*/
    output reg                          record_valid,
    output reg                          rd_start,/*synthesis PAP_MARK_DEBUG="1"*/
    output reg                          mfcc_valid1
);

parameter    INIT            = 3'b001;         
parameter    AXI_AWADDR      = 3'b010;  //写进有效地址
parameter    AXI_WDATA       = 3'b100;  //写进有效数据
parameter    IDLE_ADDR       = 6*48000*16/320;
parameter    MFCC_ADDR_MAX   = 5*48000*16/32 +IDLE_ADDR;

parameter    addr_step = BURST_LEN * 8 ;

reg   [CTRL_ADDR_WIDTH-1:0]  record_addr_save;
reg   [2:0]    state/*synthesis PAP_MARK_DEBUG="1"*/;
reg  channel1_rready_reg1;
reg  channel1_rready_reg2;


assign channel1_rd_en = axi_wready/*synthesis PAP_MARK_DEBUG="1"*/;
assign axi_wdata =channel1_data;

reg          mfcc_valid;
reg          mfcc_valid_reg;

reg  [2:0]   record_cnt; 
reg  [27:0]   cnt1s;

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        cnt1s <= 'd0;
    end
    else if (audio_data_valid) begin
        cnt1s <= 0;
    end
    else begin
        cnt1s <= cnt1s + 1;
    end
end
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        record_valid <= 'd0;
        mfcc_valid <= 'd0;
    end
    else if (rs232_data == 8'b10100001 && rs232_flag == 1'b1) begin  //开始录音
        record_valid <= 1'b1;
    end
    else if (rs232_data == 8'b10100010 && rs232_flag == 1'b1) begin //停止录音
        record_valid <= 1'b0;
    end
    else if (rs232_data[7:4] == 4'b0101 && rs232_flag == 1'b1 ) begin //开始收集
        mfcc_valid <= 1'b1;  
    end
    else if (rs232_data[7:4] == 4'b0101 && (cnt1s == 'd60000000 || axi_awaddr > MFCC_ADDR_MAX ) && mfcc_valid1 == 1'b1 && axi_awaddr > IDLE_ADDR * 3) begin //连续0.4s无有效数据或者达到mfcc最大值停止
        mfcc_valid <= 1'b0;
    end
end

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        mfcc_valid1 <= 'd0;
    end
    else if (mfcc_valid == 1'b0) begin //开始收集
        mfcc_valid1 <= 1'b0;  
    end
    else if (audio_data_valid == 1'b1) begin //连续0.4s无有效数据或者达到mfcc最大值停止
        mfcc_valid1 <= 1'b1;
    end
end

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        rd_start <= 'd0;
    end
    else if ((~mfcc_valid) & mfcc_valid_reg) begin //检测到下降沿
        rd_start <= 1'b1;  
    end
    else if (axi_araddr > (axi_awaddr - IDLE_ADDR)) begin // 读ddr完成
        rd_start <= 1'b0;
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
                if (channel1_rready_reg2 & (record_valid | mfcc_valid1)) begin
                    state <= AXI_AWADDR;
                end
            end
            AXI_AWADDR:begin
                if (axi_awready & axi_awvalid) begin
                    state <= AXI_WDATA;
                end
            end 
            AXI_WDATA:begin
                if (axi_wlast == 1'b1) begin
                    state <= INIT;
                end
            end 
        endcase
    end
end
 
//相关信号变化
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        axi_awvalid <= 'd0;
    end
    else begin
        case (state)
            AXI_AWADDR:begin
                if ((axi_awready & axi_awvalid)) begin
                    axi_awvalid <= 1'b0;
                end
                else begin
                    axi_awvalid <= 1'b1;
                end
            end 
        endcase
    end
end


always @(posedge clk or negedge rst) begin   //通道1偏移地址
    if (~rst) begin
        axi_awaddr <= 'd0;
        record_addr_save <= MFCC_ADDR_MAX;    
    end
    else if (rs232_data == 8'b10100000 && rs232_flag == 1'b1) begin
        record_addr_save <= MFCC_ADDR_MAX;
    end
    else if (rs232_data == 8'b10100001 && rs232_flag == 1'b1) begin
        axi_awaddr <= record_addr_save;
    end
    else if (rs232_data == 8'b10100010 && rs232_flag == 1'b1) begin
        record_addr_save <= axi_awaddr;
    end
    else if (rs232_data[7:4] == 4'b0101 && rs232_flag == 1'b1) begin
        axi_awaddr <= 'd0;
    end
    else if (axi_awready & axi_awvalid) begin
        axi_awaddr <= axi_awaddr + addr_step;
    end
end



always @(posedge clk) begin  //跨时钟打拍及边缘检测
    channel1_rready_reg1 <= channel1_rready;
    channel1_rready_reg2 <= channel1_rready_reg1;
    mfcc_valid_reg <= mfcc_valid;
end


endmodule