// 用于存储和读取字符数据的模块
//
module osd_display #(
parameter x_start1   =  12'd850,           //更改显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start1  =   12'd350,
parameter interval=     8'd80,                 //修改此处改变行间隔
parameter color_char  = 24'hffffff       //更改字符颜色
)
(
	input                       rst_n,  
    input                       clk, 
	input                       pclk,
	input    [23:0]             i_data,
    input                       vs_in,   
	output [23:0]               o_data,
    input [7:0]                 rs232_data,
    input                       rs232_flag,
    input [12-1:0]              pos_x/*synthesis PAP_MARK_DEBUG="1"*/,
    input [12-1:0]              pos_y/*synthesis PAP_MARK_DEBUG="1"*/,
    input                       train_down,
    input [2:0]                 recognition_result,
    input                       recognition_result_flag
);



// 当前模式:
parameter OSD_WIDTH   =  12'd160;  // 更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT  =  12'd45;
parameter x_start = x_start1;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start = y_start1+interval-4'd6;

//音频回传，音频降噪，回声消除，人声变换，人声分离 ，声纹识别 共用此位置
parameter OSD_WIDTH2   =  12'd128;  //更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT2  =  12'd45;
parameter x_start2     =  x_start + OSD_WIDTH;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start2     =  y_start;

//识别结果： 正在训练：  训练完成： 
parameter OSD_WIDTH3   =  12'd160;  //更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT3  =  12'd45;
parameter x_start3     =  x_start;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start3     =  y_start2+interval + OSD_HEGIHT2;

//说话人
parameter OSD_WIDTH4   =  12'd96;  //更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT4  =  12'd45;
parameter x_start4     = x_start2 ;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start4     = y_start3;

// 模式数字
parameter OSD_WIDTH5   =  12'd16;  //更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT5  =  12'd33;
parameter x_start5     = x_start2 + OSD_WIDTH2 + 'd5 ;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start5     = y_start2 + 4'd4;

//说话人数字
parameter OSD_WIDTH6   =  12'd16;  //更改rom显示区域的大小，要和取的字模的大小一样
parameter OSD_HEGIHT6  =  12'd33;
parameter x_start6   = x_start4+OSD_WIDTH4 + 'd5 ;  //更改rom显示区域起始位置，要注意剩余的区域不能比显示区域小
parameter y_start6  =  y_start4+4'd4;



reg [9:0]  addr_char_bias [0:9];  //数字寻址起始地址
initial begin
    addr_char_bias[0] <= 'd0 * 'd66;
    addr_char_bias[1] <= 'd1 * 'd66;
    addr_char_bias[2] <= 'd2 * 'd66;
    addr_char_bias[3] <= 'd3 * 'd66;
    addr_char_bias[4] <= 'd4 * 'd66;
    addr_char_bias[5] <= 'd5 * 'd66;
    addr_char_bias[6] <= 'd6 * 'd66;
    addr_char_bias[7] <= 'd7 * 'd66;
    addr_char_bias[8] <= 'd8 * 'd66;
    addr_char_bias[9] <= 'd9 * 'd66;
end

reg[23:0]  v_data;
reg[11:0]  osd_x;
reg[15:0]  osd_ram_addr;
wire[7:0]  q1;
wire[7:0]  data;
wire[7:0]  data1;
wire[7:0]  data2;
wire[7:0]  data3;
wire[7:0]  data4;
wire[7:0]  data5;
wire[7:0]  data6;
wire[7:0]  data7;
wire[7:0]  data8;
wire[7:0]  data9;
wire[7:0]  data10;
wire[7:0]  data11;
wire[7:0]  data12;
wire[7:0]  data13;
wire[7:0]  data14;
wire[7:0]  data15;
reg        region_active;
reg        region_active_d0;
reg[9:0] osd_ram_addr3_reg;
reg        pos_vs_d0;
reg        pos_vs_d1;


reg[11:0]  osd_x2;
reg[15:0]  osd_ram_addr2;
reg        region_active2;
reg        region_active2_d0;

reg[11:0]  osd_x3;
reg[15:0]  osd_ram_addr3;
reg        region_active3;
reg        region_active3_d0;

reg[11:0]  osd_x4;
reg[11:0]  osd_y4;
reg[15:0]  osd_ram_addr4;
reg        region_active4;
reg        region_active4_d0;

reg[11:0]  osd_x5;
reg[11:0]  osd_y5;
reg[15:0]  osd_ram_addr5;
reg        region_active5;
reg        region_active5_d0;

reg[11:0]  osd_x6;
reg[11:0]  osd_y6;
reg[15:0]  osd_ram_addr6;
reg        region_active6;
reg        region_active6_d0;

reg [7:0] rs232_data_reg1;
reg [7:0] rs232_data_reg2;

wire [9:0] osd_ram_addr5_reg;

reg        flag;
reg        flag_reg1;
reg        flag_reg2;
reg        flag2;
reg        flag2_reg1;
reg        flag2_reg2;
wire [2:0] data_reg;
reg [2:0] recognition_result_reg;
reg [2:0] recognition_result_reg1;
reg [2:0] recognition_result_reg2;

assign data_reg = (rs232_data_reg2[3] == 1'b1) ? recognition_result_reg2 : rs232_data_reg2[2:0];
assign o_data = v_data;
assign osd_ram_addr5_reg= (region_active5 == 1'b1) ? (osd_ram_addr5[12:3] + addr_char_bias[rs232_data_reg2[2:0]]) : (osd_ram_addr6[12:3] + addr_char_bias[data_reg]);

always @(posedge pclk ) begin
    rs232_data_reg1 <= rs232_data;
    rs232_data_reg2 <= rs232_data_reg1;    //跨时钟域打拍
    recognition_result_reg1 <= recognition_result_reg;
    recognition_result_reg2  <=recognition_result_reg1;
    flag_reg1 <= flag;
    flag_reg2 <= flag_reg1;
    flag2_reg1 <= flag2;
    flag2_reg2 <= flag2_reg1;

end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        flag <= 'd0;
    end
    else if (rs232_data[7:3] == 5'b01010) begin
        if (rs232_flag == 1'b1) begin
            flag <= 'd0;
        end
        else if (train_down == 1'b1) begin
            flag <= 'd1;
        end
        else begin
            flag <= flag;
        end
    end 
    else begin
        flag <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        flag2 <= 'd0;
        recognition_result_reg <= 'd0;
    end
    else if (rs232_data[7:3] == 5'b01011) begin
        if (rs232_flag == 1'b1) begin
            flag2 <= 'd0;
        end
        else if (recognition_result_flag == 1'b1) begin
            flag2 <= 'd1;
            recognition_result_reg <= recognition_result;  //保存数据
        end
        else begin
            flag2 <= flag2;
        end
    end 
    else begin
        flag2 <= 'd0;
    end
end

//两区域不能有交叉，否则交叉部分，rom区域会覆盖ram区域，ram区域显示不完整



//当前模式 
always@(posedge pclk)
begin
	if(pos_y >= y_start && pos_y <= y_start + OSD_HEGIHT - 12'd1 && pos_x >= x_start && pos_x  <= x_start + OSD_WIDTH - 12'd1)
		region_active <= 1'b1;
	else
		region_active <= 1'b0;
end


always@(posedge pclk)
begin
	region_active_d0 <= region_active;
end


always@(posedge pclk)
begin
	if(region_active_d0 == 1'b1)
		osd_x <= osd_x + 12'd1;
	else
		osd_x <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr <= 16'd0;
	else if(region_active == 1'b1)
		osd_ram_addr <= osd_ram_addr + 16'd1;
end

//音频回传，音频降噪，回声消除，人声变换，人声分离 ，声纹识别 共用此位置
always@(posedge pclk)
begin
	if(pos_y >= y_start2 && pos_y <= y_start2 + OSD_HEGIHT2 - 12'd1 && pos_x >= x_start2 && pos_x  <= x_start2 + OSD_WIDTH2 - 12'd1)
		region_active2 <= 1'b1;
	else
		region_active2 <= 1'b0;
end


always@(posedge pclk)
begin
	region_active2_d0 <= region_active2;
end


always@(posedge pclk)
begin
	if(region_active2_d0 == 1'b1)
		osd_x2 <= osd_x2 + 12'd1;
	else
		osd_x2 <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr2 <= 16'd0;
	else if(region_active2 == 1'b1)
		osd_ram_addr2 <= osd_ram_addr2 + 16'd1;
end
//

//识别结果： 正在训练：  训练完成：
always@(posedge pclk)
begin
	if(pos_y >= y_start3 && pos_y <= y_start3 + OSD_HEGIHT3 - 12'd1 && pos_x >= x_start3 && pos_x  <= x_start3 + OSD_WIDTH3 - 12'd1)
		region_active3 <= 1'b1;
	else
		region_active3 <= 1'b0;
end


always@(posedge pclk)
begin
	region_active3_d0 <= region_active3;
end


always@(posedge pclk)
begin
	if(region_active3_d0 == 1'b1)
		osd_x3 <= osd_x3 + 12'd1;
	else
		osd_x3 <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr3 <= 16'd0;
	else if(region_active3 == 1'b1)
		osd_ram_addr3 <= osd_ram_addr3 + 16'd1;
end

//说话人
always@(posedge pclk)
begin
	if(pos_y >= y_start4 && pos_y <= y_start4 + OSD_HEGIHT4 - 12'd1 && pos_x >= x_start4 && pos_x  <= x_start4 + OSD_WIDTH4 - 12'd1)
		region_active4 <= 1'b1;
	else
		region_active4 <= 1'b0;
end


always@(posedge pclk)
begin
	region_active4_d0 <= region_active4;
end


always@(posedge pclk)
begin
	if(region_active4_d0 == 1'b1)
		osd_x4 <= osd_x4 + 12'd1;
	else
		osd_x4 <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr4 <= 16'd0;
	else if(region_active4 == 1'b1)
		osd_ram_addr4 <= osd_ram_addr4 + 16'd1;
end

//模式数字
always@(posedge pclk)
begin
	if(pos_y >= y_start5 && pos_y <= y_start5 + OSD_HEGIHT5 - 12'd1 && pos_x >= x_start5 && pos_x  <= x_start5 + OSD_WIDTH5 - 12'd1)
		region_active5 <= 1'b1;
	else
		region_active5 <= 1'b0;
end


always@(posedge pclk)
begin
	region_active5_d0 <= region_active5;
end


always@(posedge pclk)
begin
	if(region_active5_d0 == 1'b1)
		osd_x5 <= osd_x5 + 12'd1;
	else
		osd_x5 <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr5 <= 16'd0;
	else if(region_active5 == 1'b1)
		osd_ram_addr5 <= osd_ram_addr5 + 16'd1;
end


//结果数字
always@(posedge pclk)
begin
	if(pos_y >= y_start6 && pos_y <= y_start6 + OSD_HEGIHT6 - 12'd1 && pos_x >= x_start6 && pos_x  <= x_start6 + OSD_WIDTH6 - 12'd1)
		region_active6 <= 1'b1;
	else
		region_active6 <= 1'b0;
end


always@(posedge pclk)
begin
	region_active6_d0 <= region_active6;
end


always@(posedge pclk)
begin
	if(region_active6_d0 == 1'b1)
		osd_x6 <= osd_x6 + 12'd1;
	else
		osd_x6 <= 12'd0;
end


always@(posedge pclk)
begin
	if(vs_in == 1'b1)
		osd_ram_addr6 <= 16'd0;
	else if(region_active6 == 1'b1)
		osd_ram_addr6 <= osd_ram_addr6 + 16'd1;
end

//字符显示
always@(posedge pclk)
begin
	if(region_active_d0 == 1'b1) begin
		if(q1[osd_x[2:0]] == 1'b1) begin
			v_data <= color_char; //  当前输入
        end
		else begin
			v_data <= i_data;
        end
    end
    else if(region_active2_d0 == 1'b1) begin  //音频回传，音频降噪，回声消除，人声变换，人声分离 ，声纹识别 共用此位置
        if (rs232_data_reg2[7:4] == 4'b0011) begin
		    if(data3[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  音频降噪
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:4] == 4'b0001) begin
		    if(data4[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  回声消除
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:4] == 4'b0010) begin
		    if(data5[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  人声变换
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:4] == 4'b0100) begin
		    if(data6[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  人声分离
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:4] == 4'b0101) begin
		    if(data7[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  声纹识别
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:3] == 5'b10100) begin
		    if(data13[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  声纹识别
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:3] == 5'b10101) begin
		    if(data14[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; //  声纹识别
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else  begin
		    if(data2[osd_x2[2:0]] == 1'b1) begin
		    	v_data <= color_char; // 音频回传
            end
		    else begin
		    	v_data <= i_data;
            end
        end
    end
    else if (region_active3_d0 == 1'b1) begin
        if (rs232_data_reg2[7:3] == 5'b01011) begin
		    if(data8[osd_x3[2:0]] == 1'b1) begin
		    	v_data <= color_char; // 识别结果：
            end
		    else begin
		    	v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:3] == 5'b01010) begin
            if (flag_reg2 == 1'b0) begin
		        if(data9[osd_x3[2:0]] == 1'b1 ) begin
		        	v_data <= color_char; // 正在训练
                end
		        else begin
		        	v_data <= i_data;
                end
            end
            else begin
		        if(data10[osd_x3[2:0]] == 1'b1 ) begin
		        	v_data <= color_char; // 训练完成
                end
		        else begin
		        	v_data <= i_data;
                end
            end
        end
        else begin
            v_data <= i_data;
        end
    end
	else if(region_active4_d0 == 1'b1) begin
        if (rs232_data_reg2[7:3] == 5'b01011 && recognition_result_reg2 == 'd7 && flag2_reg2 == 1'b1) begin   
            if(data15[osd_x4[2:0]] == 1'b1) begin
                v_data <= color_char; // 无结果
            end
            else begin
                v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:4] == 4'b0101) begin
            if(data11[osd_x4[2:0]] == 1'b1) begin
                v_data <= color_char; // 说话人
            end
            else begin
                v_data <= i_data;
            end
        end
        else begin
            v_data <= i_data;
        end
    end
	else if(region_active5_d0 == 1'b1) begin
        if (rs232_data_reg2[7:4] == 4'b0010 || rs232_data_reg2[7:4] == 4'b0011 || rs232_data_reg2[7:4] == 4'b0100) begin  //人声调整，音频去噪，人声分离都有模式x
            if(data12[osd_x5[2:0]] == 1'b1) begin
                v_data <= color_char; // 说话人
            end
            else begin
                v_data <= i_data;
            end
        end
        else begin
            v_data <= i_data;
        end
    end
	else if(region_active6_d0 == 1'b1) begin
        if (rs232_data_reg2[7:3] == 5'b01010) begin  //识别结果和训练人
            if(data12[osd_x6[2:0]] == 1'b1) begin
                v_data <= color_char; // 说话人
            end
            else begin
                v_data <= i_data;
            end
        end
        else if (rs232_data_reg2[7:3] == 5'b01011 && flag2_reg2 == 1'b1 && recognition_result_reg2 != 'd7) begin  //识别结果的数字显示
            if(data12[osd_x6[2:0]] == 1'b1) begin
                v_data <= color_char; // 说话人
            end
            else begin
                v_data <= i_data;
            end
        end
        else begin
            v_data <= i_data;
        end
    end
	else begin
		v_data <= i_data;
    end
end


osd_rom1 disp_current_mode (
  .addr(osd_ram_addr[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(q1)     // output [7:0]
);

osd_rom2 disp_voice_loop (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data2)     // output [7:0]
);

osd_rom3 disp_noise (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data3)     // output [7:0]
);

osd_rom4 disp_echo (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data4)     // output [7:0]
);

osd_rom5 disp_voice_change (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data5)     // output [7:0]
);

osd_rom6 disp_voice_split (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data6)     // output [7:0]
);

osd_rom7 disp_voice_recongnition (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data7)     // output [7:0]
);
//识别结果： 正在训练：  训练完成：
osd_rom8 disp_result (
  .addr(osd_ram_addr3[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data8)     // output [7:0]
);
osd_rom9 disp_trainning (
  .addr(osd_ram_addr3[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data9)     // output [7:0]
);
osd_rom10 disp_train_done (
  .addr(osd_ram_addr3[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data10)     // output [7:0]
);

//说话人

osd_rom11 disp_speaker (
  .addr(osd_ram_addr4[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data11)     // output [7:0]
);

//数字
osd_rom12 disp_num (
  .addr(osd_ram_addr5_reg),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data12)     // output [7:0]
);

//音频录音
osd_rom13 disp_record (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data13)     // output [7:0]
);

//录音播放
osd_rom14 disp_record_sound (
  .addr(osd_ram_addr2[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data14)     // output [7:0]
);

//说话人

osd_rom15 disp_no_result (
  .addr(osd_ram_addr4[12:3]),          // input [9:0]
  .clk(pclk),            // input
  .rst(1'b0),            // input
  .rd_data(data15)     // output [7:0]
);

endmodule