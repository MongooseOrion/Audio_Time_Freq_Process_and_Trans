module voiceprint_recognition 
#(
    parameter DATA_WIDTH = 16,
    parameter FFT_LENGTH = 'd1024,
    parameter MELFB_NUMBER = 'd20,
    parameter FRAME_NUMBER = 'd300
)
(   
    input                       clk,
    input                       sck,
    input                       rst_n/*synthesis PAP_MARK_DEBUG="1"*/,
    input                       rs232_flag/*synthesis PAP_MARK_DEBUG="1"*/,
    input [7:0]                 rs232_rx_data/*synthesis PAP_MARK_DEBUG="1"*/,

    output wire                  voice_flag/*synthesis PAP_MARK_DEBUG="1"*/,
    input  wire signed [DATA_WIDTH - 1:0]     data_in, /*synthesis PAP_MARK_DEBUG="1"*/

    //fft相关
    output                          xn_axi4s_data_tvalid,
    output   [16*2-1:0]             xn_axi4s_data_tdata ,
    output                          xn_axi4s_data_tlast ,
    input                           xn_axi4s_data_tready,
    output                          xn_axi4s_cfg_tvalid ,
    output                          xn_axi4s_cfg_tdata  ,
    input                           xk_axi4s_data_tvalid,
    input    [32*2-1:0]             xk_axi4s_data_tdata ,
    input                           xk_axi4s_data_tlast ,
    output  [2:0]                   recognition_result  /*synthesis PAP_MARK_DEBUG="1"*/,
    output                          recognition_result_flag/*synthesis PAP_MARK_DEBUG="1"*/  ,
    output                          train_down      

);
wire [8:0]           mfcc_data;   // 
reg  [12:0]          mfcc_addr;
wire  [12:0]          mfcc_addr1;
wire  [12:0]          mfcc_addr2;
wire [8:0]           vqlbg_data;
wire [10:0]          vplbg_addr;

always @(*) begin
    if (rs232_rx_data[7:3] == 5'b01011  ) begin  //识别阶段
        mfcc_addr <= mfcc_addr2;
    end
    else begin
        mfcc_addr <= mfcc_addr1;
    end
end

mfcc_feature_extraction#(            //提取mfcc特征
    .DATA_WIDTH(16)
)mfcc_feature_extraction(
    .rst_n          (rst_n),// input
    .sck            (sck   ),// input
    .clk            (clk),
    .data_in        (data_in      ),// input[15:0]
    .xn_axi4s_data_tready(xn_axi4s_data_tready),
    .xn_axi4s_data_tvalid(xn_axi4s_data_tvalid),
    .xn_axi4s_data_tdata(xn_axi4s_data_tdata),
    .xn_axi4s_data_tlast(xn_axi4s_data_tlast),
    .xn_axi4s_cfg_tvalid(xn_axi4s_cfg_tvalid),
    .xn_axi4s_cfg_tdata(xn_axi4s_cfg_tdata),
    .xk_axi4s_data_tvalid(xk_axi4s_data_tvalid),
    .xk_axi4s_data_tdata(xk_axi4s_data_tdata),
    .xk_axi4s_data_tlast(xk_axi4s_data_tlast),
    .voice_flag         (voice_flag        ),
    .rs232_flag         (rs232_flag),
    .rs232_data         (rs232_rx_data),
    .rd_data7           (mfcc_data  ),
    .rd_addr7           (mfcc_addr  ),
    .mfcc_extraction_end(mfcc_extraction_end)


);

vqlbg_train vqlbg_train_inst
(
.clk(clk),
.rst_n(rst_n),
.rs232_rx_data(rs232_rx_data),
.mfcc_extraction_end(mfcc_extraction_end),
.mfcc_addr(mfcc_addr1),
.mfcc_data(mfcc_data),
.vqlbg_addr(vplbg_addr),
.vqlbg_rd_data(vqlbg_data),
.train_down(train_down)
);

recognition_test recognition_test_inst 
(
    .clk(clk),
    .rst_n(rst_n),
    .mfcc_data(mfcc_data),
    .mfcc_addr(mfcc_addr2),
    .vqlbg_data(vqlbg_data),
    .vplbg_addr(vplbg_addr),
    .mfcc_extraction_end(mfcc_extraction_end),
    .recognition_result(recognition_result),
    .recognition_result_flag(recognition_result_flag),
    .rs232_rx_data (rs232_rx_data)

);

endmodule