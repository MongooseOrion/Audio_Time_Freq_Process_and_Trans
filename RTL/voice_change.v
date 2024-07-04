//******************************************************************

//******************************************************************

module voice_change
#(
    parameter DATA_WIDTH = 16
    
)
(   
    input                       clk,
    input                       sck,
    input                       rst_n/*synthesis PAP_MARK_DEBUG="1"*/,
    input                       CHANGE_MODE,// 0为男变女，1为女变男
    output     [DATA_WIDTH - 1:0]  ldata_out/*synthesis PAP_MARK_DEBUG="1"*/,

    input   [DATA_WIDTH - 1:0]  ldata_in/*synthesis PAP_MARK_DEBUG="1"*/

);

wire        almost_full/*synthesis PAP_MARK_DEBUG="1"*/;
reg         rd_en/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] rd_data_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] rd_data_ram2/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] wr_data_fifo /*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0] rd_data_fifo;
reg   [9:0] cnt1/*synthesis PAP_MARK_DEBUG="1"*/;
reg   [9:0] cnt2/*synthesis PAP_MARK_DEBUG="1"*/;
reg   [9:0] rd_addr_ram1/*synthesis PAP_MARK_DEBUG="1"*/;

reg         wr_en_ram1/*synthesis PAP_MARK_DEBUG="1"*/;
reg         flag1/*synthesis PAP_MARK_DEBUG="1"*/;     //重复抽样flag
wire        wr_en_ram2/*synthesis PAP_MARK_DEBUG="1"*/;
reg         pose_flag/*synthesis PAP_MARK_DEBUG="1"*/;
reg         nege_flag/*synthesis PAP_MARK_DEBUG="1"*/;
reg         wr_en_fifo/*synthesis PAP_MARK_DEBUG="1"*/;
reg         wr_en_ram1_reg1;
reg         wr_en_ram1_reg2;
reg         pose_flag_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg         nege_flag_reg/*synthesis PAP_MARK_DEBUG="1"*/;
assign wr_en_ram2 = rst_n ? ~wr_en_ram1:1'b0;
assign wr_data_fifo = wr_en_ram1 ? rd_data_ram2:rd_data_ram1;
assign ldata_out = rd_data_fifo;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        pose_flag <= 'd0;
        nege_flag <= 'd0;
    end
    else begin
        pose_flag <= wr_en_ram1_reg1 & (~wr_en_ram1_reg2);
        nege_flag <= (~wr_en_ram1_reg1) & (wr_en_ram1_reg2);
    end
end


//计数cnt1，960个数据为一帧,cnt1也当作为两个ram写地址信号 
always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        cnt1 <= 'd0;
    end
    else if(cnt1 == 'd1023) begin
        cnt1 <= 'd0;
    end
    else begin
        cnt1 <= cnt1 + 1'b1;
    end
end

 
//乒乓操作，一个ram存一帧数据
always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        wr_en_ram1 <= 'd0;
    end
    else if(cnt1=='d1023) begin
        wr_en_ram1 <= ~wr_en_ram1;  
    end
    else begin
        wr_en_ram1 <= wr_en_ram1;
    end
end


//在clk下延迟两拍，做边沿检测
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        wr_en_ram1_reg1 <= 'd0;
        wr_en_ram1_reg2 <= 'd0;
    end
    else begin
        wr_en_ram1_reg1 <= wr_en_ram1;
        wr_en_ram1_reg2 <= wr_en_ram1_reg1;
    end
end
// 读ram数据写进fifo，采用系统时钟作为读ram数据写进fifo的时钟,当前模式女声变男声，即增大基频时钟周期
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        rd_addr_ram1 <= 'd0;
        flag1        <= 1'b0;
    end
    else if (pose_flag | nege_flag )  begin//清零 
        rd_addr_ram1 <= 'd0;
        flag1        <= 1'b0;  
    end
    else if (CHANGE_MODE == 'd0) begin
        if(((rd_addr_ram1 % 'd4) =='d0) && (flag1 == 1'b0)) begin
            rd_addr_ram1 <= rd_addr_ram1;  
            flag1        <= 1'b1;
        end
        else begin
            rd_addr_ram1 <= rd_addr_ram1 + 1'b1;
            flag1      <= 1'b0;
        end 
    end
    else if (CHANGE_MODE == 1'b1) begin
        if ((rd_addr_ram1 + 1'b1 ) % 'd2 == 'd0) begin
            rd_addr_ram1 <= rd_addr_ram1 + 2'b10;
        end
        else begin
            rd_addr_ram1 <= rd_addr_ram1 + 1'b1; 
        end
    end
end 


//计数cnt2，写进fifo里面的数据计数，在clk时钟下
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        cnt2 <= 'd0;
    end
    else if(wr_en_fifo == 1'b0) begin
        cnt2 <= 'd0;
    end
    else begin
        cnt2 <= cnt2 + 1'b1;
    end
end

//fifo写使能信号,clk时钟下
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        wr_en_fifo <= 'd0;
    end
    else if(cnt2=='d1023) begin
        wr_en_fifo <= 1'b0;  
    end
    else if (pose_flag | nege_flag) begin
        wr_en_fifo <= 1'b1;
    end
    else begin
        wr_en_fifo <= wr_en_fifo;
    end
end

voice_change_ram voice_change_ram_inst1 (
  .wr_data(ldata_in),    // input [15:0]
  .wr_addr(cnt1),    // input [9:0]
  .wr_en(wr_en_ram1),        // input
  .wr_clk(sck),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(rd_addr_ram1),    // input [9:0]
  .rd_data(rd_data_ram1),    // output [15:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);

voice_change_ram voice_change_ram_inst2 (
  .wr_data(ldata_in),    // input [15:0]
  .wr_addr(cnt1),    // input [9:0]
  .wr_en(wr_en_ram2),        // input
  .wr_clk(sck),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(rd_addr_ram1),    // input [9:0] 
  .rd_data(rd_data_ram2),    // output [15:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);

voice_change_fifo the_instance_name (
  .wr_clk(clk),                // input
  .wr_rst(~rst_n),                // input
  .wr_en(wr_en_fifo),                  // input
  .wr_data(wr_data_fifo),              // input [15:0]  
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_clk(sck),                // input
  .rd_rst(~rst_n),                // input
  .rd_en(rst_n),                  // input
  .rd_data(rd_data_fifo),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

endmodule 
