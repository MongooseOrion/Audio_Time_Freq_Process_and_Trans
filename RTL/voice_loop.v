`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module voice_loop_test(
    input wire        sys_clk         ,//50MHz
    input             key             /*synthesis PAP_MARK_DEBUG="1"*/,
//ES7243E  ADC  in
    output            es7243_scl      /*synthesis PAP_MARK_DEBUG="1"*/,//CCLK
    inout             es7243_sda      /*synthesis PAP_MARK_DEBUG="1"*/,//CDATA
    output            es0_mclk        /*synthesis PAP_MARK_DEBUG="1"*/,//MCLK  clk_12M
    input             es0_sdin        /*synthesis PAP_MARK_DEBUG="1"*/,//SDOUT i2s数据输入             i2s_sdin
    input             es0_dsclk       /*synthesis PAP_MARK_DEBUG="1"*/,//SCLK  i2s数据时钟             i2s_sck   
    input             es0_alrck       /*synthesis PAP_MARK_DEBUG="1"*/,//LRCK  i2s数据左右信道帧时钟     i2s_ws
//ES8156  DAC   out
    output            es8156_scl      /*synthesis PAP_MARK_DEBUG="1"*/,//CCLK
    inout             es8156_sda      /*synthesis PAP_MARK_DEBUG="1"*/,//CDATA 
    output            es1_mclk        /*synthesis PAP_MARK_DEBUG="1"*/,//MCLK  clk_12M
    input             es1_sdin        /*synthesis PAP_MARK_DEBUG="1"*/,//SDOUT 回放信号反馈？
    output            es1_sdout       /*synthesis PAP_MARK_DEBUG="1"*/,//SDIN  DAC i2s数据输出          i2s_sdout
    input             es1_dsclk       /*synthesis PAP_MARK_DEBUG="1"*/,//SCLK  i2s数据位时钟            i2s_sck
    input             es1_dlrc        /*synthesis PAP_MARK_DEBUG="1"*/,//LRCK  i2s数据左右信道帧时钟      i2s_ws
//  
    input             lin_test,//麦克风插入检测
    input             lout_test,//扬声器检测
    output            lin_led,
    output            lout_led,   
    
    output            adc_dac_int
);

assign lin_led=lin_test?1'b0:1'b1;
assign lout_led=lout_test?1'b0:1'b1;



    wire        locked         ;
    wire        rstn_out       /*synthesis PAP_MARK_DEBUG="1"*/;
    wire        es7243_init       /*synthesis PAP_MARK_DEBUG="1"*/;
    wire        es8156_init       /*synthesis PAP_MARK_DEBUG="1"*/;
    wire        clk_12M        /*synthesis PAP_MARK_DEBUG="1"*/;

    PLL u_pll (
      .clkin1       (sys_clk   ),   // input//50MHz
      .pll_lock     (locked    ),   // output
      .clkout0      (clk_12M   )    // output//12.288MHz
    );
assign es0_mclk    =    clk_12M;

reg  [19:0]                 cnt_12M   ;
reg                         ce        /*synthesis PAP_MARK_DEBUG="1"*/; 
    always @(posedge clk_12M)
    begin
    	if(!locked|!key)
    	    cnt_12M <= 20'h0;
    	else
    	begin
    		if(cnt_12M == 20'h10000)
    		    cnt_12M <= cnt_12M;
    		else
    		    cnt_12M <= cnt_12M + 1'b1;
    	end
    end

    always @(posedge clk_12M)
    begin
    	if(!locked|!key)
    	    ce <= 1'h0;
    	else
    	begin
    		if((cnt_12M <= 20'h1)|(cnt_12M == 20'h10000))
    		    ce <= 1'h1;
    		else
    		    ce <= 1'h0;
    	end
    end



assign es1_mclk    =    clk_12M;
assign clk_test    =    clk_12M;
reg  [19:0]                 rstn_1ms            /*synthesis PAP_MARK_DEBUG="1"*/;
    always @(posedge clk_12M)
    begin
    	if(!locked|!key)
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

ES7243E_reg_config	ES7243E_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out          ),//input	
    	.i2c_sclk                (es7243_scl        ),//output，配置的引脚
    	.i2c_sdat                (es7243_sda        ),//inout，配置的引脚
    	.reg_conf_done           (es7243_init       ),//output config_finished
        .clock_i2c               (clock_i2c)
    );
ES8156_reg_config	ES8156_reg_config(
    	.clk_12M                 (clk_12M           ),//input
    	.rstn                    (rstn_out            ),//input	
    	.i2c_sclk                (es8156_scl        ),//output
    	.i2c_sdat                (es8156_sda        ),//inout
    	.reg_conf_done           (es8156_init       )//output config_finished
    );
assign adc_dac_int = es7243_init&&es8156_init;
//ES7243E demo板////////////////////////////////////////////////////////////////////////////////////////////

assign es0_mclk_demo=es0_mclk;
//////////////////////////////////////////////////////////////////////////////////////////////
wire [15:0]rx_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire       rx_l_vld/*synthesis PAP_MARK_DEBUG="1"*/;
wire       rx_r_vld/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]ldata_out/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]rdata_out/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]ldata_out1/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]rdata_out1/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]ldata/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0]rdata/*synthesis PAP_MARK_DEBUG="1"*/;
//ES7243E
pgr_i2s_rx#(
    .DATA_WIDTH(16)
)ES7243_i2s_rx(
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input
    .ws             (es0_alrck        ),// input
    .sda            (es0_sdin         ),// input

    .data           (rx_data          ),// output[15:0]  //接收到的左右声道的数据，是混在一起的
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);
//ES8156
pgr_i2s_tx#(
    .DATA_WIDTH(16)
)ES8156_i2s_tx(
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s数据位时钟  
    .ws             (es1_dlrc       ),// input  //LRCK  i2s数据左右信道帧时钟 
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s数据输出

    .ldata          (ldata_out          ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (ldata_out          ),// input[15:0]
    .r_req          (          ) // output
);
////////////////////////////////////////////LOOP//////////////////////////////////////////////////将数据接收成左右通道输出
ehco_Cancelling#(
    .DATA_WIDTH(16)
)ehco_Cancelling_inst(
    .rst_n          (adc_dac_int),// input
    .sck            (es1_dlrc   ),// input
    .data_out       (ldata_out    ),// output[15:0]
    .data_in        (ldata      )// input[15:0]

);

voice_change#(
    .DATA_WIDTH(16)
)voice_change_inst(
    .rst_n          (adc_dac_int),// input
    .clk            (sys_clk    ),
    .sck            (es1_dlrc   ),// input
    .ldata_out      (ldata_out1      ),// output[15:0]
    .rdata_out      (rdata_out1      ),// output[15:0]
    .rdata_in       (rdata      ),// input[15:0]      //音色改变处理
    .ldata_in       (ldata      )// input[15:0]

);

i2s_loop#(
    .DATA_WIDTH(16)
)i2s_loop(
    .rst_n          (adc_dac_int),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]   //根据左右声道的时序将左右声道的数据分离成ldata，rdata
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
endmodule
