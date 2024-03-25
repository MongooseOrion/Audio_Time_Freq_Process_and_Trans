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
// 声音处理的顶层文件
//
module fpga_top(    
    input               sys_clk             ,//50MHz
    input               sys_rst             ,
    
    // ES7243E ADC_in
    output              es7243_scl          ,//CCLK
    inout               es7243_sda          ,//CDATA
    output              es0_mclk            ,//MCLK  clk_12M
    input               es0_sdin            ,//SDOUT i2s数据输入             i2s_sdin
    input               es0_dsclk           ,//SCLK  i2s数据时钟             i2s_sck   
    input               es0_alrck           ,//LRCK  i2s数据左右信道帧时钟     i2s_ws
    
    // ES8156 DAC_out
    output              es8156_scl          ,//CCLK
    inout               es8156_sda          ,//CDATA 
    output              es1_mclk            ,//MCLK  clk_12M
    input               es1_sdin            ,//SDOUT 回放信号反馈
    output              es1_sdout           ,//SDIN  DAC i2s数据输出          i2s_sdout
    input               es1_dsclk           ,//SCLK  i2s数据位时钟            i2s_sck
    input               es1_dlrc            ,//LRCK  i2s数据左右信道帧时钟      i2s_ws
    
    // 检测相关
    input               lin_test            ,//麦克风插入检测
    input               lout_test           ,//扬声器检测
    output              lin_led,
    output              lout_led,   
    output              codec_init,

    // UART
    input               uart_rx,
    output              uart_tx
);


reg  [19:0]     rstn_1ms    ;
reg             tone_aujusted_enable;
reg             echo_reduced_enable;
reg             backgm_reduced_enable;
reg             voice_recog_enable;
reg             ethernet_trans_enable;

wire            locked      ;
wire [3:0]      ctrl_command;
wire [3:0]      value_command;
wire            rstn_out    ;
wire            es7243_init ;
wire            es8156_init ;
wire            clk_12M     ;
wire [15:0]     rx_data     ;
wire            rx_l_vld    ;
wire            rx_r_vld    ;
wire [15:0]     ldata_out1  ;
wire [15:0]     rdata_out1  ;
wire [15:0]     ldata_out   ;
wire [15:0]     rdata_out   ;
wire [15:0]     ldata       ;
wire [15:0]     rdata       ;

assign lin_led = lin_test ? 1'b0 : 1'b1;
assign lout_led = lout_test ? 1'b0 : 1'b1;
assign codec_init = es7243_init && es8156_init;


//
// 全局时钟信号
sys_pll u_sys_pll (
    .clkin1       (sys_clk   ),   // input//50MHz
    .pll_rst      (sys_rst   ),
    .pll_lock     (locked    ),   // output
    .clkout0      (clk_12M   ),   // output//12.288MHz
    .clkout1      (clk_50M   )
);


//
// uart 信号输入
uart_trans ctrl_command_trans(
    .clk                    (clk_50M    ),
    .rst                    (sys_rst    ),
    .uart_rx                (uart_rx    ),
    .uart_tx                (uart_tx    ),
    .command_in             (),  // 用于板上回传信号
    .command_in_flag        (),
    .ctrl_command_out       (ctrl_command ),
    .value_command_out      (value_command),
    .command_out_flag       ()
);


//
// 功能控制
always @(posedge sys_clk or negedge sys_rst) begin
    if(!sys_rst) begin
        tone_aujusted_enable <= 1'b0;
        echo_reduced_enable <= 1'b0;
        backgm_reduced_enable <= 1'b0;
        voice_recog_enable <= 1'b0;
        ethernet_trans_enable <= 1'b0;
    end
    else begin
        if(ctrl_command == 4'b0010) begin
            if(value_command == 4'b0001) begin
                echo_reduced_enable <= 1'b0;
                backgm_reduced_enable <= 1'b0;
                voice_recog_enable <= 1'b0;
                tone_aujusted_enable <= 1'b1;
            end
            else if(value_command == 4'b0010) begin
                backgm_reduced_enable <= 1'b0;
                tone_aujusted_enable <= 1'b0;
                voice_recog_enable <= 1'b0;
                echo_reduced_enable <= 1'b1;
            end
            else if(value_command == 4'b0010) begin
                tone_aujusted_enable <= 1'b0;
                echo_reduced_enable <= 1'b0;
                voice_recog_enable <= 1'b0;
                backgm_reduced_enable <= 1'b1;
            end
            else begin
                tone_aujusted_enable <= 1'b0;
                echo_reduced_enable <= 1'b0;
                voice_recog_enable <= 1'b0;
                backgm_reduced_enable <= 1'b0;
            end
        end
        else if((ctrl_command == 4'b0100) || (ctrl_command == 4'b1000)) begin
            tone_aujusted_enable <= 1'b0;
            echo_reduced_enable <= 1'b0;
            voice_recog_enable <= 1'b0;
            ethernet_trans_enable <= 1'b1;
        end
        else if(ctrl_command == 4'b1001) begin
            voice_recog_enable <= 1'b1;
        end
        else begin
            tone_aujusted_enable <= 1'b0;
            echo_reduced_enable <= 1'b0;
            backgm_reduced_enable <= 1'b0;
            voice_recog_enable <= 1'b0;
        end
    end
end


// 
// 音频输入输出芯片 i2s 寄存器配置
always @(posedge clk_12M)
begin
	if((!locked) || (!sys_rst))
	    rstn_1ms <= 20'h0;
	else
	begin
		if(rstn_1ms == 20'h50000)
		    rstn_1ms <= rstn_1ms;
		else
		    rstn_1ms <= rstn_1ms + 1'b1;
	end
end
assign rstn_out = (rstn_1ms == 20'h50000);

ES7243E_reg_config ES7243E_reg_config(
	.clk_12M                 (clk_12M           ),//input
	.rstn                    (rstn_out          ),//input	
	.i2c_sclk                (es7243_scl        ),//output，配置的引脚
	.i2c_sdat                (es7243_sda        ),//inout，配置的引脚
	.reg_conf_done           (es7243_init       ),//output config_finished
    .clock_i2c               (clock_i2c)
);
ES8156_reg_config ES8156_reg_config(
	.clk_12M                 (clk_12M           ),//input
	.rstn                    (rstn_out            ),//input	
	.i2c_sclk                (es8156_scl        ),//output
	.i2c_sdat                (es8156_sda        ),//inout
	.reg_conf_done           (es8156_init       )//output config_finished
);


//
// ES7243E
pgr_i2s_rx #(
    .DATA_WIDTH     (16)
)ES7243_i2s_rx (
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input
    .ws             (es0_alrck        ),// input
    .sda            (es0_sdin         ),// input

    .data           (rx_data          ),// output[15:0]
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);


// 
// ES8156
pgr_i2s_tx #(
    .DATA_WIDTH     (16)
)ES8156_i2s_tx (
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s数据位时钟  
    .ws             (es1_dlrc       ),// input  //LRCK  i2s数据左右信道帧时钟 
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s数据输出

    .ldata          (ldata_out          ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (ldata_out          ),// input[15:0]
    .r_req          (          ) // output
);


//
// 将从 ADC 接收的数据按 i2s 时序分离为左右声道数据
i2s_loop #(
    .DATA_WIDTH     (16)
)u_i2s_loop (
    .rst_n          (codec_init ),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);


//
// 回声消除
voice_echo_reduced #(
    .DATA_WIDTH     (16)
)u_voice_echo_reduced (
    .rst_n          (codec_init ),// input
    .sck            (es1_dlrc   ),// input
    .data_out       (ldata_out  ),// output[15:0]
    .data_in        (ldata      )// input[15:0]
);


//
// 音色调整
tone_aujusted #(
    .DATA_WIDTH     (16)
)u_tone_adjusted (
    .rst_n          (codec_init),// input
    .process_clk    (clk_50M    ),
    .sck            (es1_dlrc   ),// input
    .ldata_out      (ldata_out1      ),// output[15:0]
    .rdata_out      (rdata_out1      ),// output[15:0]
    .rdata_in       (rdata      ),// input[15:0]      //音色改变处理
    .ldata_in       (ldata      )// input[15:0]
);


// 
// 背景声和人声分离，并去除噪声



//
// 音频元数据 UDP 发送
eth_trans u_eth_trans(
    
);

endmodule
