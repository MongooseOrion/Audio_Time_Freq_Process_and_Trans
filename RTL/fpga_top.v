// FILE ENCODER: UTF-8
// 项目顶层文件
//
module fpga_top (
    input               sys_clk         ,//50MHz
    input               sys_rst         ,
    // ES7243E  ADC in
    output              es7243_scl      ,//CCLK
    inout               es7243_sda      ,//CDATA
    output              es0_mclk        ,//MCLK  clk_12M
    input               es0_sdin        ,//SDOUT i2s       i2s_sdin
    input               es0_dsclk       ,//SCLK  i2s      i2s_sck   
    input               es0_alrck       ,//LRCK  i2s     i2s_ws
    // ES8156  DAC out
    output              es8156_scl      ,//CCLK
    inout               es8156_sda      ,//CDATA 
    output              es1_mclk        ,//MCLK  clk
    input               es1_sdin        ,//SDOUT 
    output              es1_sdout       ,//SDIN  DAC       i2s_sdout
    input               es1_dsclk       ,//SCLK  i2s      i2s_sck
    input               es1_dlrc        ,//LRCK  i2s      i2s_ws
    // 插入检测
    input               left_in_detect  ,
    input               left_out_detect ,
    // led
    output              hardware_init   ,
    output              eth_init        ,
    output              voice_flag      ,// 当电平幅值高于阈值时亮起
    // UART
    input               uart_rx         ,
    output              uart_tx         ,
    output              rstn_out        , 
    // hdmi 寄存器相关
    output              iic_tx_scl      ,
    inout               iic_tx_sda      ,

    // hdmi_out 
    output              pix_clk         ,//pixclk                           
    output              vs_out          , 
    output              hs_out          , 
    output              de_out          ,
    output [7:0]        r_out           , 
    output [7:0]        g_out           , 
    output [7:0]        b_out           ,      
    // RJ45
    output              e_mdc                   ,//MDIO的时钟信号，用于读写PHY的寄存器
    inout               e_mdio                  ,//MDIO的数据信号，用于读写PHY的寄存器  
    output  [3:0]       rgmii_txd               ,//RGMII 发送数据
    output              rgmii_txctl             ,//RGMII 发送有效信号
    output              rgmii_txc               ,//125Mhz ethernet rgmii uart_tx clock
    input   [3:0]       rgmii_rxd               ,//RGMII 接收数据
    input               rgmii_rxctl             ,//RGMII 接收数据有效信号
    input               rgmii_rxc               ,//125Mhz ethernet rgmii RX clock
    // DDR
    output              mem_rst_n               ,
    output              mem_ck                  ,
    output              mem_ck_n                ,
    output              mem_cke                 ,
    output              mem_cs_n                ,
    output              mem_ras_n               ,
    output              mem_cas_n               ,
    output              mem_we_n                ,
    output              mem_odt                 ,
    output [14:0]       mem_a                   ,
    output [2:0]        mem_ba                  ,
    inout  [3:0]        mem_dqs                 ,
    inout  [3:0]        mem_dqs_n               ,
    inout  [31:0]       mem_dq                  ,
    output [3:0]        mem_dm

);

parameter X_WIDTH = 4'd12;
parameter Y_WIDTH = 4'd12; 
parameter MEM_ROW_ADDR_WIDTH   = 15         ;
parameter MEM_COL_ADDR_WIDTH   = 10         ;
parameter MEM_BADDR_WIDTH      = 3          ;
parameter MEM_DQ_WIDTH         =  32        ;
parameter CTRL_ADDR_WIDTH = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH;
parameter MEM_DQS_WIDTH        =  32/8  ;

wire                    aclken                      ; 
wire                    xn_axi4s_data_tvalid        ;
wire [16*2-1:0]         xn_axi4s_data_tdata         ;
wire                    xn_axi4s_data_tlast         ;
wire                    xn_axi4s_data_tready        ;
wire                    xn_axi4s_cfg_tvalid         ;
wire                    xn_axi4s_cfg_tdata          ;
wire                    xk_axi4s_data_tvalid        ;
wire [32*2-1:0]         xk_axi4s_data_tdata         ;
wire                    xk_axi4s_data_tlast         ;
wire [16-1:0]           xk_axi4s_data_tuser         ;
wire [2:0]              alm                         ;
wire                    stat                        ;
wire [15:0]             noise_reduction_data_out    ;

wire                    xn_axi4s_data_tvalid1       ;
wire [16*2-1:0]         xn_axi4s_data_tdata1        ;
wire                    xn_axi4s_data_tlast1        ;
wire                    xn_axi4s_cfg_tvalid1        ;
wire                    xn_axi4s_cfg_tdata1         ;

wire                    xn_axi4s_data_tvalid2       ;
wire [16*2-1:0]         xn_axi4s_data_tdata2        ;
wire                    xn_axi4s_data_tlast2        ;
wire                    xn_axi4s_cfg_tvalid2        ;
wire                    xn_axi4s_cfg_tdata2         ;

wire [15:0]             rx_data                     ;
wire                    rx_l_vld                    ;
wire                    rx_r_vld                    ;
wire [15:0]             ldata_out                   ;
wire [15:0]             rdata_out                   ;
wire [15:0]             voice_change_out            ;
wire [15:0]             ldata                       ;
wire [15:0]             rdata                       ;

wire [2:0]              recognition_result          ;
wire                    recognition_result_flag     ;

wire                    es7243_init                 ;
wire                    es8156_init                 ;
wire                    adc_dac_init                ; 
wire                    clk_12M                     ;
wire                    clk_50M;

wire [7:0]              rs232_rx_data               ;
wire                    rs232_rx_flag               ;

wire                        locked     ;
wire                        rstn       ;
wire                        init_over  ;
wire [X_WIDTH - 1'b1:0]     act_x      ;
wire [Y_WIDTH - 1'b1:0]     act_y      ;    
wire                        hs         ;
wire                        vs         ;
wire                        de         ;

wire [7:0]                  r_out1          ;
wire [7:0]                  g_out1          ;
wire [7:0]                  b_out1          ;
wire [23:0]                 o_data          ;
wire [45:0]                 spectrum_data   ;
wire ['d6-'d1 : 0]          frame_CNT1      ;

// axi bus   
wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr          ;
wire                        axi_awready         ;
wire                        axi_awvalid         ;

wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata           ;
wire                        axi_wready          ;
wire                        axi_wusero_last     ;

wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr          ;
wire                        axi_arready         ;
wire                        axi_arvalid         ;

wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata           ;
wire                        axi_rvalid          ;
wire                        axi_rlast           ;

wire                        core_clk            ;
wire                        ddr_init_done       ;

wire                        record_valid        ;
wire [15:0]                 record_vioce_out    ;
wire                        almost_full         ;
wire [255:0]                rd_data             ;
wire                        rd_en               ;


reg  [3:0]              split_mode                  ;
reg  [15:0]             voice_out                   ;
reg                     CHANGE_MODE                 ; 

reg  [3:0]              reset_delay_cnt;

reg  [15:0]             eth_voice_data;

reg  [19:0]             cnt_12M         ;
reg                     ce              ; 
reg                     rst_1           ;
reg  [19:0]             rstn_1ms        ;
reg                     hardware_led    ;


assign r_out = o_data[23:16];
assign g_out = o_data[15:8];
assign b_out = o_data[7:0];
assign xn_axi4s_data_tvalid = (rs232_rx_data[7:4] == 4'b0101)? xn_axi4s_data_tvalid2:xn_axi4s_data_tvalid1;
assign xn_axi4s_data_tdata  = (rs232_rx_data[7:4] == 4'b0101)? xn_axi4s_data_tdata2 :xn_axi4s_data_tdata1 ;
assign xn_axi4s_data_tlast  = (rs232_rx_data[7:4] == 4'b0101)? xn_axi4s_data_tlast2 :xn_axi4s_data_tlast1 ;
assign xn_axi4s_cfg_tvalid  = (rs232_rx_data[7:4] == 4'b0101)? xn_axi4s_cfg_tvalid2 :xn_axi4s_cfg_tvalid1 ;
assign xn_axi4s_cfg_tdata   = (rs232_rx_data[7:4] == 4'b0101)? xn_axi4s_cfg_tdata2  :xn_axi4s_cfg_tdata1  ;

assign lin_led = left_in_detect ? 1'b0 : 1'b1;
assign lout_led = left_out_detect ? 1'b0 : 1'b1;
assign adc_dac_init = es7243_init && es8156_init;
assign hardware_init = hardware_led;

assign es1_mclk    =    clk_12M;
assign clk_test    =    clk_12M;


// 
// 系统时钟分频
sys_pll u_pll (
    .pll_rst        (!sys_rst   ),      // input
    .clkin1         (sys_clk    ),   // input 50MHz
    .pll_lock       (locked     ),   // output
    .clkout0        (clk_12M    ),  // output 12.288MHz
    .clkout1        (clk_50M    ),  // output 50MHz
    .clkout2        (pix_clk    )    // output 74.25MHz
);
assign es0_mclk = clk_12M;


//
// 硬件准备就绪
always@(posedge clk_50M or negedge sys_rst) begin
    if(!sys_rst) begin
        hardware_led <= 1'b0;
    end
    else if(lin_led && lout_led && adc_dac_init && ddr_init_done && init_over) begin
        hardware_led <= 1'b1;
    end
    else begin
        hardware_led <= hardware_led;
    end
end


//
// 解调双声道
i2s_loop#(
    .DATA_WIDTH(16)
)i2s_loop(
    .rst_n          (adc_dac_init),// input
    .sck            (es0_dsclk  ),// input
    .ldata          (ldata      ),// output[15:0]
    .rdata          (rdata      ),// output[15:0]
    .data           (rx_data    ),// input[15:0]   //
    .r_vld          (rx_r_vld   ),// input
    .l_vld          (rx_l_vld   ) // input
);


//
// 初始化复位信号
always @(posedge clk_12M)begin
    if(!locked|!sys_rst)
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


//
// ADC DAC 初始化
ES7243E_reg_config	ES7243E_reg_config(
    .clk_12M                 (clk_12M           ),//input
    .rstn                    (rstn_out          ),//input	
    .i2c_sclk                (es7243_scl        ),//output
    .i2c_sdat                (es7243_sda        ),//inout
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


// 
// ES7243E 接收音频
pgr_i2s_rx#(
    .DATA_WIDTH(16)
)ES7243_i2s_rx(
    .rst_n          (es7243_init      ),// input

    .sck            (es0_dsclk        ),// input
    .ws             (es0_alrck        ),// input
    .sda            (es0_sdin         ),// input

    .data           (rx_data          ),// output[15:0]  //
    .l_vld          (rx_l_vld         ),// output
    .r_vld          (rx_r_vld         ) // output
);


//
// ES8156 输出音频
pgr_i2s_tx#(
    .DATA_WIDTH(16)
)ES8156_i2s_tx(
    .rst_n          (es8156_init    ),// input

    .sck            (es1_dsclk      ),// input  //SCLK  i2s
    .ws             (es1_dlrc       ),// input  //LRCK  i2s
    .sda            (es1_sdout      ),// output //SDIN  DAC i2s
    .ldata          (voice_out          ),// input[15:0]
    .l_req          (          ),// output
    .rdata          (voice_out          ),// input[15:0]
    .r_req          (          ) // output
);


//
// hdmi 寄存器配置
ms72xx_ctl ms72xx_ctl(
    .clk         (  clk_12M    ), //input       clk,
    .rst_n       (  rstn_out   ), //input       rstn,
                            
    .init_over   (  init_over  ), //output      init_over,
    .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
    .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
    .iic_scl     (  iic_scl    ), //output      iic_scl,
    .iic_sda     (  iic_sda    )  //inout       iic_sda
);


//
// hdmi vesa 时序生成
sync_vg sync_vg(                                                 
    .clk                  (  pix_clk               ),//input                   clk,                                 
    .rstn                 (  adc_dac_init                 ),//input                   rstn,                            
    .vs_out               ( vs_out                  ),//output reg              vs_out,                                                                                                                                      
    .hs_out               ( hs_out                  ),//output reg              hs_out,            
    .de_out               ( de_out                  ),//output reg              de_out,             
    .x_act                (  act_x                ),//output reg [X_BITS-1:0] x_out,             
    .y_act                (  act_y                ) //output reg [Y_BITS:0]   y_out,             
);


//
// 频谱显示
hdmi_spectrum hdmi_spectrum (
    .rst_n                (  adc_dac_init | ddr_init_done                 ),//input                         rstn,                                                     
    .pix_clk              (  pix_clk               ),//input                         clk_in,  
    .clk                  (core_clk               ),
    .act_x                (  act_x                ),//input      [X_BITS-1:0]       x, 
    .act_y                (  act_y                ),
    // input video timing
    .vs_in                (  vs_out                  ),//input                         vn_in                        
    .hs_in                (  hs_out                  ),//input                         hn_in,                           
    .de_in                (  de_out                  ),//input                         dn_in,
    .xn_axi4s_cfg_tvalid  (xn_axi4s_cfg_tvalid) ,
    .xn_axi4s_cfg_tdata   (xn_axi4s_cfg_tdata) ,
    .xk_axi4s_data_tvalid (xk_axi4s_data_tvalid) ,
    .xk_axi4s_data_tdata  (xk_axi4s_data_tdata) ,
    .spectrum_data        (spectrum_data),
    .frame_CNT1           (frame_CNT1),
    .rs232_data           (rs232_rx_data),
    .rs232_flag           (rs232_rx_flag),
    // test pattern image output                                                    
    .r_out                (  r_out1                ),//output reg [COCLOR_DEPP-1:0]  r_out,                      
    .g_out                (  g_out1                ),//output reg [COCLOR_DEPP-1:0]  g_out,                       
    .b_out                (  b_out1                ), //output reg [COCLOR_DEPP-1:0]  b_out ,

    .rst_clear            (recognition_result_flag | train_down)  
);


//
// 字符显示
osd_display osd_display(
    .rst_n(adc_dac_init | ddr_init_done),   
    .pclk(pix_clk),
    .clk (core_clk),
    .i_data({r_out1,g_out1,b_out1}),   
    .o_data(o_data),
    .vs_in(vs_out),
    .rs232_data(rs232_rx_data),
    .rs232_flag(rs232_rx_flag),
    .recognition_result(recognition_result),
    .recognition_result_flag(recognition_result_flag),
    .train_down(train_down),
    .pos_x(act_x),
    .pos_y(act_y)

);


//
// uart 接收和发送
rs232_rx #(
    .UART_BPS('d9600      ) ,
    .CLK_FREQ('d100_000_000) 
)rs232_rx_inst(
    .sys_clk     (core_clk),
    .sys_rst_n   (adc_dac_init | ddr_init_done),
    .rx          (uart_rx),

    .rs232_rx_data (rs232_rx_data)    ,
    .rs232_rx_flag(rs232_rx_flag)
);

rs232_tx #(
    .UART_BPS('d9600      ) ,
    .CLK_FREQ('d100_000_000) 
)rs232_tx_inst(
    .sys_clk     (core_clk),
    .sys_rst_n   (adc_dac_init | ddr_init_done),
    .tx          (uart_tx),

    .rs232_tx_data ({5'd0,recognition_result})    ,
    .rs232_tx_flag(recognition_result_flag)
);


// 
// 串口命令仲裁
always @(posedge core_clk) begin
    if (~adc_dac_init) begin
        split_mode <= 'd1;
        voice_out <= ldata;
        rst_1 <= 'd0;
    end
    else if ( rs232_rx_flag == 1'b1) begin
        rst_1 <= 1'b1;
    end
    else if (rs232_rx_data[7:4] == 4'b0011 ) begin  // 降噪
        split_mode <= rs232_rx_data[3:0] + 'd6;
        voice_out <= noise_reduction_data_out;
        rst_1 <= 'd0;
    end
    else if (rs232_rx_data[7:4] == 4'b0100 ) begin  // 人声分离
        split_mode <= rs232_rx_data[3:0];
        voice_out <= noise_reduction_data_out;
        rst_1 <= 'd0;
    end
    else if (rs232_rx_data[7:4] == 4'b0001 ) begin // 回声消除
        voice_out <= ldata_out;
        rst_1 <= 1'b0;
    end
    else if (rs232_rx_data[7:4] == 4'b0010 ) begin  // 变声选择
        voice_out <= voice_change_out;
        CHANGE_MODE <= rs232_rx_data[0];
        rst_1 <= 1'b0;
    end
    else if (rs232_rx_data[7:4] == 4'b0101 ) begin  // 声纹识别
        voice_out <= ldata;
        rst_1 <= 1'b0;
    end
    else if (rs232_rx_data[7:3] == 5'b10101 ) begin  // ddr 录音播放
        voice_out <= record_vioce_out;
        rst_1 <= 1'b0;
    end
    else begin
        voice_out <= ldata;
        rst_1 <= 1'b0;
    end
end


//
// 人声分离和降噪
noise_reduction#(
    .DATA_WIDTH(16)
)noise_reduction_inst(
    .rst_n          (adc_dac_init | ddr_init_done),// input
    .sck            (es1_dlrc   ),// input
    .clk            (core_clk),
    .data_in        (ldata      ),// input[15:0]
    .data_out(noise_reduction_data_out),
    .xn_axi4s_data_tready(xn_axi4s_data_tready),
    .xn_axi4s_data_tvalid(xn_axi4s_data_tvalid1),
    .xn_axi4s_data_tdata(xn_axi4s_data_tdata1),
    .xn_axi4s_data_tlast(xn_axi4s_data_tlast1),
    .xn_axi4s_cfg_tvalid(xn_axi4s_cfg_tvalid1),
    .xn_axi4s_cfg_tdata(xn_axi4s_cfg_tdata1),
    .xk_axi4s_data_tvalid(xk_axi4s_data_tvalid),
    .xk_axi4s_data_tdata(xk_axi4s_data_tdata),
    .xk_axi4s_data_tlast(xk_axi4s_data_tlast),
    .SPLIT_MODE(split_mode),
    .spectrum_data (spectrum_data),
    .frame_CNT1 (frame_CNT1),
    .rst_rs232 (rst_1)
);


//
// 声纹识别
voiceprint_recognition#(
    .DATA_WIDTH(16)
)voiceprint_recognition_inst(
    .rst_n          (adc_dac_init | ddr_init_done),// input
    .sck            (es1_dlrc   ),// input
    .clk            (core_clk   ),
    .data_in        (ldata      ),// input[15:0]
    .voice_flag     (voice_flag ),
    .rs232_rx_data  (rs232_rx_data),
    .rs232_flag  (rs232_rx_flag),
    .xn_axi4s_data_tready(xn_axi4s_data_tready),
    .xn_axi4s_data_tvalid(xn_axi4s_data_tvalid2),
    .xn_axi4s_data_tdata(xn_axi4s_data_tdata2),
    .xn_axi4s_data_tlast(xn_axi4s_data_tlast2),
    .xn_axi4s_cfg_tvalid(xn_axi4s_cfg_tvalid2),
    .xn_axi4s_cfg_tdata(xn_axi4s_cfg_tdata2),
    .xk_axi4s_data_tvalid(xk_axi4s_data_tvalid),
    .xk_axi4s_data_tdata(xk_axi4s_data_tdata),
    .xk_axi4s_data_tlast(xk_axi4s_data_tlast),
    .recognition_result (recognition_result) ,
    .recognition_result_flag (recognition_result_flag) ,
    .train_down(train_down)
);


//
// 快速傅里叶变换 IP 核
ipsxb_fft_demo_pp_1024  u_fft_wrapper ( 
    .i_aclk                 (core_clk               ),
    .i_axi4s_data_tvalid    (xn_axi4s_data_tvalid),
    .i_axi4s_data_tdata     (xn_axi4s_data_tdata ),
    .i_axi4s_data_tlast     (xn_axi4s_data_tlast ),
    .o_axi4s_data_tready    (xn_axi4s_data_tready),
    .i_axi4s_cfg_tvalid     (xn_axi4s_cfg_tvalid ),
    .i_axi4s_cfg_tdata      (xn_axi4s_cfg_tdata  ),
    .o_axi4s_data_tvalid    (xk_axi4s_data_tvalid),
    .o_axi4s_data_tdata     (xk_axi4s_data_tdata ),
    .o_axi4s_data_tlast     (xk_axi4s_data_tlast ),
    .o_axi4s_data_tuser     (xk_axi4s_data_tuser ),
    .o_alm                  (alm                 ),
    .o_stat                 (stat                )
);


//
// 回声消除
ehco_Cancelling#(
    .DATA_WIDTH(16)
)ehco_Cancelling_inst(
    .rst_n          (adc_dac_init),// input
    .clk            (core_clk),
    .rs232_data     (rs232_rx_data),
    .rs232_flag     (rs232_rx_flag),
    .sck            (es1_dlrc   ),// input
    .data_out       (ldata_out    ),// output[15:0]
    .data_in        (ldata      )// input[15:0]

);


// 
// 人声变声
voice_change#(
    .DATA_WIDTH(16)
)voice_change_inst(
    .rst_n          (adc_dac_init),// input
    .clk            (clk_50M    ),
    .sck            (es1_dlrc   ),// input
    .CHANGE_MODE    (CHANGE_MODE),
    .ldata_out      (voice_change_out ),// output[15:0]
    .ldata_in       (ldata      )// input[15:0]

);


//
// ddr 输入缓存
cache_wr_fifo cache_wr_fifo_inst (
  .wr_clk(es1_dlrc),                // input
  .wr_rst(~adc_dac_init),                // input
  .wr_en(adc_dac_init),                  // input
  .wr_data(ldata),              // input [15:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_clk(core_clk),                // input
  .rd_rst(~record_valid),                // input
  .rd_en(rd_en),                  // input
  .rd_data(rd_data),              // output [255:0]
  .rd_empty(),            // output
  .almost_empty(almost_empty)     // output
);


//
// axi 总线写
axi_interconnect_wr axi_interconnect_wr_inst (
    .clk            (core_clk),                // ddr core clk
    .rst            (adc_dac_init | ddr_init_done),
    .rs232_data     (rs232_rx_data),
    .rs232_flag     (rs232_rx_flag), 
    .channel1_rready(~almost_empty) ,
    .channel1_data  (rd_data) ,
    .channel1_rd_en (rd_en) ,
    .axi_awaddr     (axi_awaddr) ,
    .axi_awready    (axi_awready) ,
    .axi_awvalid    (axi_awvalid) ,
    .axi_wdata      (axi_wdata) ,
    .axi_wlast      (axi_wusero_last) ,
    .axi_wready     (axi_wready),      
    .record_valid   (record_valid)
);


//
// axi 总线读
axi_interconnect_rd axi_interconnect_rd_inst (
    .clk            (core_clk),
    .rst            (adc_dac_init | ddr_init_done),
    .voice_clk      (es1_dlrc),
    .rs232_data     (rs232_rx_data),
    .rs232_flag     (rs232_rx_flag), 
    .axi_arvalid    (axi_arvalid),  
    .axi_arready    (axi_arready), 
    .axi_araddr     (axi_araddr),                   
    .axi_rdata      (axi_rdata),  
    .axi_rvalid     (axi_rvalid),  
    .axi_rlast      (axi_rlast)  ,
    .axi_awaddr     (axi_awaddr) ,
    .record_valid   (record_valid) ,
    .record_vioce_out(record_vioce_out)
);


//
// ddr3 控制器
ddr3 ddr3_record_cache_inst (
  .resetn(rstn_out),                                      // input
  .ref_clk(clk_50M),
  .ddr_init_done(ddr_init_done),                        // output
  .ddrphy_clkin(core_clk),                          // output
  .pll_lock(pll_lock),                                  // output

  .axi_awaddr(axi_awaddr),                              // input [27:0]
  .axi_awuser_ap(1'b0),                        // input
  .axi_awuser_id(4'b0),                        // input [3:0]
  .axi_awlen(4'd15),                                // input [3:0]
  .axi_awready(axi_awready),                            // output
  .axi_awvalid(axi_awvalid),                            // input
  
  .axi_wdata(axi_wdata),
  .axi_wstrb(32'hffffffff),                                // input [31:0]
  .axi_wready(axi_wready),                              // output
  .axi_wusero_id(),                        // output [3:0]
  .axi_wusero_last(axi_wusero_last),                    // output

  .axi_araddr(axi_araddr),                              // input [27:0]
  .axi_aruser_ap(1'b0),                        // input
  .axi_aruser_id(4'b0),                        // input [3:0]
  .axi_arlen(4'd15),                                // input [3:0]
  .axi_arready(axi_arready),                            // output
  .axi_arvalid(axi_arvalid),                            // input

  .axi_rdata(axi_rdata),                                // output [255:0]
  .axi_rid(),                                    // output [3:0]
  .axi_rlast(axi_rlast),                                // output
  .axi_rvalid(axi_rvalid),                              // output

  .apb_clk(1'b0),                                    // input
  .apb_rst_n(1'b1),                                // input
  .apb_sel(1'b0),                                    // input
  .apb_enable(1'b0),                              // input
  .apb_addr(1'b0),                                  // input [7:0]
  .apb_write(1'b0),                                // input
  .apb_ready(),                                // output
  .apb_wdata(16'b0),                                // input [15:0]
  .apb_rdata(),                                // output [15:0]
  .apb_int(),                                    // output

  .debug_data(),                              // output [135:0]
  .debug_slice_state(),                // output [51:0]
  .debug_calib_ctrl(),                  // output [21:0]
  .ck_dly_set_bin(),                      // output [7:0]
  .force_ck_dly_en(1'b0),                    // input
  .force_ck_dly_set_bin(8'h05),          // input [7:0]
  .dll_step(),                                  // output [7:0]
  .dll_lock(),                                  // output
  .init_read_clk_ctrl(2'b0),              // input [1:0]
  .init_slip_step(4'b0),                      // input [3:0]
  .force_read_clk_ctrl(1'b0),            // input
  .ddrphy_gate_update_en(1'b0),        // input
  .update_com_val_err_flag(),    // output [3:0]
  .rd_fake_stop(1'b0),                          // input

  .mem_rst_n(mem_rst_n),                                // output
  .mem_ck(mem_ck),                                      // output
  .mem_ck_n(mem_ck_n),                                  // output
  .mem_cke(mem_cke),                                    // output
  .mem_cs_n(mem_cs_n),                                  // output
  .mem_ras_n(mem_ras_n),                                // output
  .mem_cas_n(mem_cas_n),                                // output
  .mem_we_n(mem_we_n),                                  // output
  .mem_odt(mem_odt),                                    // output
  .mem_a(mem_a),                                        // output [14:0]
  .mem_ba(mem_ba),                                      // output [2:0]
  .mem_dqs(mem_dqs),                                    // inout [3:0]
  .mem_dqs_n(mem_dqs_n),                                // inout [3:0]
  .mem_dq(mem_dq),                                      // inout [31:0]
  .mem_dm(mem_dm)                                       // output [3:0]
);


// 
// 音频元数据 UDP 发送
always @(posedge es1_dlrc ) begin
    if (rs232_rx_data[7:4] == 4'b0010) begin
        eth_voice_data <= voice_change_out;
    end
    else begin
        eth_voice_data <= ldata;
    end
end

eth_trans u_eth_trans(
    .sys_clk        (clk_50M    ),
    .rst_n          (rstn_out   ),
    .led            (eth_init   ),

    .vin_clk        (es1_dlrc   ),
    .vin_sck        (es1_dsclk  ),
    .vin_ldata      (eth_voice_data      ),

    .e_mdc          (e_mdc),
    .e_mdio         (e_mdio),
    .rgmii_txd      (rgmii_txd),
    .rgmii_txctl    (rgmii_txctl),
    .rgmii_txc      (rgmii_txc),
    .rgmii_rxd      (rgmii_rxd),
    .rgmii_rxctl    (rgmii_rxctl),
    .rgmii_rxc      (rgmii_rxc)
);



endmodule
