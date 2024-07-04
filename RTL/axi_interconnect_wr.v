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
    // 通道 1  
    input                               channel1_rready /*synthesis PAP_MARK_DEBUG="1"*/,
    input       [DQ_WIDTH*8-1'b1:0]     channel1_data   /*synthesis PAP_MARK_DEBUG="1"*/,
    output                              channel1_rd_en  /*synthesis PAP_MARK_DEBUG="1"*/,

    // AXI WRITE INTERFACE 
    output reg [CTRL_ADDR_WIDTH-1:0]    axi_awaddr      /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_awready     /*synthesis PAP_MARK_DEBUG="1"*/,
    output reg                          axi_awvalid     /*synthesis PAP_MARK_DEBUG="1"*/,

    output [DQ_WIDTH*8-1'b1:0]          axi_wdata       /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_wlast       /*synthesis PAP_MARK_DEBUG="1"*/,
    input                               axi_wready,      /*synthesis PAP_MARK_DEBUG="1"*/
    output reg                          record_valid
);

parameter    INIT            = 3'b001;         
parameter    AXI_AWADDR      = 3'b010;  //写进有效地址
parameter    AXI_WDATA       = 3'b100;  //写进有效数据

parameter    addr_step = BURST_LEN * 8 ;

reg   [2:0]    state/*synthesis PAP_MARK_DEBUG="1"*/;
reg  channel1_rready_reg1;
reg  channel1_rready_reg2;


assign channel1_rd_en = axi_wready/*synthesis PAP_MARK_DEBUG="1"*/;
assign axi_wdata =channel1_data;


reg  [2:0]   record_cnt; 
always @(posedge clk or negedge rst) begin
    if (~rst) begin
        record_valid <= 'd0;
    end
    else if (rs232_data == 8'b10100001 && rs232_flag == 1'b1) begin  //开始录音
        record_valid <= 1'b1;
    end
    else if (rs232_data == 8'b10100010 && rs232_flag == 1'b1) begin //停止录音
        record_valid <= 1'b0;
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
                if (channel1_rready_reg2 & record_valid) begin
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
    end
    else if (rs232_data == 8'b10100000 && rs232_flag == 1'b1) begin
        axi_awaddr <= 'd0;
    end
    else if (axi_awready & axi_awvalid) begin
        axi_awaddr <= axi_awaddr + addr_step;
    end
end



always @(posedge clk) begin  //跨时钟打拍及边缘检测
    channel1_rready_reg1 <= channel1_rready;
    channel1_rready_reg2 <= channel1_rready_reg1;
end


endmodule