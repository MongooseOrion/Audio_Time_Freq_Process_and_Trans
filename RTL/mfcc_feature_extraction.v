
module mfcc_feature_extraction 
#(
    parameter DATA_WIDTH = 16,
    parameter FFT_LENGTH = 'd1024,
    parameter MELFB_NUMBER = 'd31,
    parameter FRAME_NUMBER = 'd300   //最大收集300帧
)
(   
    input                       clk,
    input                       sck,
    input                       rst_n/*synthesis PAP_MARK_DEBUG="1"*/,
    input                       rs232_flag,
    input [7:0]                 rs232_data,
    output wire [8:0]           rd_data7,
    input  wire [13:0]          rd_addr7,

    output reg                     voice_flag/*synthesis PAP_MARK_DEBUG="1"*/,
    output reg                     mfcc_extraction_end/*synthesis PAP_MARK_DEBUG="1"*/,
    input  wire signed [DATA_WIDTH - 1:0]     data_in, /*synthesis PAP_MARK_DEBUG="1"*/
    output reg  [8:0]              mfcc_number,

    //fft相关
    output reg                      xn_axi4s_data_tvalid,
    output   [16*2-1:0]             xn_axi4s_data_tdata ,
    output reg                      xn_axi4s_data_tlast ,
    input                           xn_axi4s_data_tready,
    output wire                     xn_axi4s_cfg_tvalid ,
    output reg                      xn_axi4s_cfg_tdata  ,
    input                           xk_axi4s_data_tvalid,
    input    [32*2-1:0]             xk_axi4s_data_tdata ,
    input                           xk_axi4s_data_tlast    ,
    output  reg                     voice_flag_reg  ,
    input      [15:0]               voiceprint_vioce_out,
    input                           fifo_ready ,  
    output  wire                    rd_en_fifo ,    
    input                           rd_start         

);
//求位数
function integer clog2;
    input integer n;
    begin
        n = n - 1;
        for (clog2=0; n>0; clog2=clog2+1)   //取对数，方便宏定义位数,向上取整
            n = n >> 1;
    end
endfunction
parameter signed threshold_hign = 40000;
parameter signed threshold_hign1 = 'd0;
localparam  FFT_WIDTH      = clog2(FFT_LENGTH);    //10
wire signed [DATA_WIDTH + FFT_WIDTH:0]         xk_axi4s_data_tdata_imag/*synthesis PAP_MARK_DEBUG="1"*/;
wire signed [DATA_WIDTH + FFT_WIDTH:0]         xk_axi4s_data_tdata_real/*synthesis PAP_MARK_DEBUG="1"*/;
wire                       almost_full1_1;
wire                       almost_full2_2;

wire [23:0]                p/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [15:0]                a/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [7:0]                 b/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        xk_axi4s_data_tlast_reg;
reg                        xk_axi4s_data_tlast_reg1;
reg                        delay_128_wr_en;
reg                        wr_en4_reg1;
reg  [FFT_WIDTH - 'd2:0]   cnt_512;
reg                        fifo_rst;
reg  [7:0]                 state/*synthesis PAP_MARK_DEBUG="1"*/;
wire                       almost_full1;
wire                       almost_full2;
wire                       almost_full3;
reg                        almost_full1_reg1;
reg                        almost_full2_reg1;
reg                        almost_full1_reg2;
reg                        almost_full2_reg2;
wire                        rd_en1;
wire [15:0]                rd_data1;
reg                        rd_en2;
wire [15:0]                rd_data2;
reg                        rd_en3;
wire signed [15:0]         rd_data3/*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]                wr_data3;
reg                        wr_en3;
reg                        wr_en3_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        start_rd;
reg  [FFT_WIDTH:0]         start_rd_cnt;

reg  [FFT_WIDTH - 'd1:0]   sin_data_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        xn_axi4s_data_tvalid1;
reg  [2:0]                 cnt4;
reg  [FFT_WIDTH - 'd1:0]   fft_in_cnt;
reg  [FFT_WIDTH - 'd1:0]   fft_out_cnt;  

reg  [31:0]                wr_data4/*synthesis PAP_MARK_DEBUG="1"*/;
wire [53:0]                p1;
wire [53:0]                p2;

reg  [52:0]                p3;  //能量，赋值的平方

reg                        wr_en4_reg/*synthesis PAP_MARK_DEBUG="1"*/;
wire [31:0]                rd_data4/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [FFT_WIDTH - 'd1:0]   sin_addr/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        wr_en4;
reg                        rd_en4;

reg [8:0]                  wr_addr5;
reg                        wr_en5;
reg [8:0]                  rd_addr5;
wire  [52:0]                rd_data5;

reg  [13:0] melfb_addr;
wire [8:0]  melfb_rd_data;
wire [61:0] p4;


wire [7:0]                 sin_rd_data/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [3:0]                 cnt5;
reg [8:0]  cnt_1024/*synthesis PAP_MARK_DEBUG="1"*/;
reg signed [30:0] short_time_energy/*synthesis PAP_MARK_DEBUG="1"*/;
reg [8:0]   zeroCrossing_cnt2;
reg [15:0]  data_in_reg;

wire [56:0]        rd_data6;
reg [65:0]        wr_data6;
wire [56:0]       wr_data6_1/*synthesis PAP_MARK_DEBUG="1"*/;
reg [4:0]         wr_addr6/*synthesis PAP_MARK_DEBUG="1"*/;
reg [4:0]         rd_addr6/*synthesis PAP_MARK_DEBUG="1"*/;
reg               wr_en6/*synthesis PAP_MARK_DEBUG="1"*/;
wire [56:0]        log_rd_data;
reg  [56:0]        log_rd_data_reg;
reg  [5:0]         log_addr;
reg [9:0] dct_addr;
wire [8:0] dct_rd_data;
wire signed [14:0] p5;
wire signed [6:0] p5_1;
reg  signed [16:0] wr_data7;
wire signed [8:0] wr_data7_1/*synthesis PAP_MARK_DEBUG="1"*/;  //这个才是实际要写进去的
reg [13:0] wr_addr7/*synthesis PAP_MARK_DEBUG="1"*/;
reg        wr_en7/*synthesis PAP_MARK_DEBUG="1"*/;
reg               flag1;
reg  [2:0]        cnt1;
reg  [4:0]        cnt2;
reg         fifo_rst2;
wire signed [24:0] pre_p;
wire signed [15:0] pre_p1;
reg  signed [15:0] pre_data;
assign pre_p1 = pre_p[24:9];
//定义变量，voice_flag跨时钟打拍
// reg              voice_flag_reg;
reg [26:0]       cnt_1s;
reg   wr_en_256;
reg [7:0]    cnt_256;
reg [2:0]    delay_8;
reg [9:0]    cnt_768;

parameter        INIT2       = 4'b0001;
parameter        RD_FIFO1    = 4'b0010;
parameter        RD_FIFO2    = 4'b0100;
parameter        DELAY       = 4'b1000;  //等待数据 
reg  [3:0]   state2;

parameter        START         = 8'b00000101;
parameter        INIT         = 8'b00000000;
parameter        FIFO_INIT    = 8'b00000011;
parameter        WAIT_DATA    = 8'b00000001;  //等待数据
parameter        FFT_MODE_CFG = 8'b00000010;  //FFT模式配置成fft or ifft
parameter        SIN_WINDOW   = 8'B00100000;  //加窗
parameter        FFT_DATA_IN  = 8'b00000100;  //将加sin窗后的数据传给fft_demo
parameter        FFT_DATA_OUT = 8'b00001000;  //等待数据变换完成，接收传出的数据并求出能量谱
parameter        MEL_FILTER   = 8'b00010000;  //梅谱滤波
parameter        LOG_E_COMPUTE= 8'b01000000;  //log e 计算
parameter        DCT_COMPUTE  = 8'b10000000;  //离散余弦变换

assign wr_data6_1 = (state == MEL_FILTER) ? wr_data6[65:9] : wr_data6[56:0];
assign wr_data7_1 = (wr_data7[7:0] < 'd128) ? wr_data7[16:8]:wr_data7[16:8]+1'b1;
assign xn_axi4s_data_tdata = rd_data4 ;

assign xk_axi4s_data_tdata_imag = xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH + 'd32:32];
assign xk_axi4s_data_tdata_real = xk_axi4s_data_tdata[DATA_WIDTH + FFT_WIDTH:0];
assign xn_axi4s_cfg_tvalid = (state == FFT_MODE_CFG) ? 1'b1:1'b0; //状态机处于fft配置模式就拉高

assign almost_full1_1 = ~almost_full1;
assign almost_full2_2 = ~almost_full2;
assign p_1 = p[23:8];

assign rd_en1 = (state2 == RD_FIFO1) ? 1'b1 : 1'b0;
assign rd_en_fifo = (state2 == RD_FIFO2) ? 1'b1 : 1'b0;
assign wr_data3 = (state2 == RD_FIFO1 && state2 == DELAY) ? rd_data1 : voiceprint_vioce_out;

always @(posedge sck or negedge rst_n) begin
    if (~rst_n) begin
        pre_data <= 'd0;
    end
    else begin
        pre_data <= data_in - pre_p1;
    end
end

//状态机跳转,提取mfcc特征
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= START;
        mfcc_extraction_end <= 'd0;
        mfcc_number <= 'd0;
    end
    else begin
        case (state)
            START : begin
                if (rd_start == 1'b1) begin   
                    state <= INIT;
                end
                mfcc_extraction_end <= 'd0;
                mfcc_number <= 'd0;
            end
            INIT: begin
                if (rd_start == 1'b0) begin  //这一条优先级最高，收集完成了也退出收集
                    state <= START;
                    mfcc_extraction_end <= 1'b1;
                end
                else if (almost_full3 == 1'b1) begin
                    state <= WAIT_DATA;
                end
                // else begin
                //     state <= WAIT_DATA;
                // end
            end
            // FIFO_INIT : begin
            //     if (voice_flag_reg == 1'b1 ) begin
            //         state <= WAIT_DATA;
            //     end
            //     else if (cnt_1s == 'd40000000 && wr_addr7 > 'd1000) begin  //连续0.4s没有有效信号，mfcc收集完成，
            //         state <= START;
            //         mfcc_extraction_end <= 1'b1;
            //     end
            // end
            WAIT_DATA: begin
                state <= FFT_MODE_CFG;
            end
            FFT_MODE_CFG:begin
                state <= SIN_WINDOW ;
                mfcc_number <= mfcc_number + 1'b1;
            end
            SIN_WINDOW:begin
                if (sin_data_cnt == (FFT_LENGTH - 1'b1)) begin
                    state <= FFT_DATA_IN;
                end
            end
            FFT_DATA_IN:begin
                if (rd_start == 1'b0) begin  //这一条优先级最高，收集完成了也退出收集
                    state <= START;
                    mfcc_extraction_end <= 1'b1;
                end
                else if (fft_in_cnt == (FFT_LENGTH - 1'b1) ) begin
                    state <= FFT_DATA_OUT;
                end
            end
            FFT_DATA_OUT:begin
                if (rd_start == 1'b0) begin  //这一条优先级最高，收集完成了也退出收集
                    state <= START;
                    mfcc_extraction_end <= 1'b1;
                end
                else if (xk_axi4s_data_tlast == 1'b1) begin
                    state <= MEL_FILTER;
               end
            end
            MEL_FILTER:begin
                if (wr_addr6 == MELFB_NUMBER) begin  //表示已经全部计算完
                    state <= LOG_E_COMPUTE;
                end
            end
            LOG_E_COMPUTE : begin
                if (rd_addr6 == MELFB_NUMBER ) begin
                    state <= DCT_COMPUTE;
                end
            end
            DCT_COMPUTE :begin
                if (cnt2 == MELFB_NUMBER ) begin
                    state <= INIT;
                end
            end
            
            default: state <= START;
        endcase
    end
end

//状态机内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a <= 'd0;
        b <= 'd0;
        sin_addr <= {FFT_WIDTH{1'b1}};  //和fifo取出的值同步才行，加1后的地址为0，这是才是第一个值
        rd_en3 <= 'd0;
        wr_en4 <= 'd0;
        cnt4   <= 'd0;
        rd_en4 <= 'd0;
        fft_in_cnt <= 'd0;
        xn_axi4s_data_tlast <= 'd0;
        xn_axi4s_data_tvalid <= 'd0;
        xn_axi4s_data_tvalid1 <= 'd0;
        xn_axi4s_cfg_tdata <= 1'b1;
        sin_data_cnt <= 'd0;
        xk_axi4s_data_tlast_reg <= 'd0;
        fifo_rst <= 1'b1;  //fifo清空
        xk_axi4s_data_tlast_reg1 <= 'd0;
        fft_out_cnt <= 'd0;
        wr_en5 <= 1'b0;
        wr_addr5 <= 'd0;
        melfb_addr <= 'd0;
        wr_en6 <= 'd0;
        wr_data6 <= 'd0;
        wr_addr6 <= 'd0;
        rd_addr6 <= 'd0;
        rd_addr5 <= 'd0;
        cnt1 <= 'd0;
        flag1 <= 'd0;
        log_addr <= 'd0;
        wr_data7 <= 'd0;
        wr_addr7 <= 'd0;
        wr_en7   <= 'd0;
        dct_addr <= 'd0;
        cnt2     <= 'd0;
        fifo_rst2 <= 1'b0;
        cnt_1s <= 'd0;
    end
    else begin
        case (state)
            START :begin
                wr_addr7 <= 'd0;
            end
            INIT :begin
                a <= 'd0;
                b <= 'd0;
                sin_addr <= {FFT_WIDTH{1'b1}};  //和fifo取出的值同步才行，加1后的地址为0，这是才是第一个值
                rd_en3 <= 'd0;
                wr_en4 <= 'd0;
                cnt4   <= 'd0;
                rd_en4 <= 'd0;
                fft_in_cnt <= 'd0;
                xn_axi4s_data_tlast <= 'd0;
                xn_axi4s_data_tvalid <= 'd0;
                xn_axi4s_data_tvalid1 <= 'd0;
                xn_axi4s_cfg_tdata <= 1'b1;
                sin_data_cnt <= 'd0;
                xk_axi4s_data_tlast_reg <= 'd0;
                fifo_rst <= 1'b1;  //fifo清空
                xk_axi4s_data_tlast_reg1 <= 'd0;
                wr_en5 <= 1'b0;
                fft_out_cnt <= 'd0;
                wr_addr5 <= 'd0;
                melfb_addr <= 'd0;
                wr_en6 <= 'd0;
                wr_data6 <= 'd0;
                wr_addr6 <= 'd0;
                rd_addr6 <= 'd0;
                rd_addr5 <= 'd0;
                cnt1 <= 'd0;
                flag1 <= 'd0;
                log_addr <= 'd0;
                wr_data7 <= 'd0;
                wr_en7   <= 'd0;
                dct_addr <= 'd0;
                cnt2 <= 'd0;
                wr_addr7 <= wr_addr7 ;
                cnt_1s <= 'd0;

            end
            // FIFO_INIT : begin
            //     fifo_rst2 <= 1'b1; 
            //     cnt_1s <= cnt_1s + 1'b1;  //无有效信号计数
            // end
            WAIT_DATA:begin
                fifo_rst <= 1'b0; 
                cnt_1s <= 'd0;
            end
            SIN_WINDOW :begin
                a <= rd_data3;
                b <= sin_rd_data;
                sin_addr <= sin_addr + 1'b1;
                rd_en3 <= 1'b1;
                if (sin_data_cnt == (FFT_LENGTH - 1'b1)) begin
                    wr_en4 <= 1'b0; 
                end
                else if (cnt4 == 'd3) begin  //相当于延迟3个时钟周期在写进去
                    wr_en4 <= 1'b1;
                end
                if (wr_en4 == 1'b0) begin
                    cnt4   <= cnt4 + 1'b1;
                end
                else if (wr_en4 == 1'b1) begin
                    sin_data_cnt <=  sin_data_cnt + 1'b1;  //sin_data_cnt 自动清零了，后续不用置零
                end
            end
            FFT_DATA_IN:begin
                rd_en3 <= 'd0;
                if (xn_axi4s_data_tready == 1'b1 && fft_in_cnt != (FFT_LENGTH - 1'b1)) begin
                    rd_en4 <= 1'b1;
                    xn_axi4s_data_tvalid1 <= 1'b1;
                end
                else begin
                    rd_en4 <= 'd0;
                end
    
                if (fft_in_cnt == (FFT_LENGTH - 1'b1)) begin
                    xn_axi4s_data_tvalid <= 1'b0;  
                    xn_axi4s_data_tlast <= 1'b0;  //拉低
                    xn_axi4s_data_tvalid1 <= 1'b0;
                    fifo_rst <= 1'b1;
                end
                else if (fft_in_cnt == (FFT_LENGTH - 'd2)) begin
                    xn_axi4s_data_tlast <= 1'b1;    //最后一个数据传输的时候拉高
                    xn_axi4s_data_tvalid <= xn_axi4s_data_tvalid1;
                end
                else begin
                    xn_axi4s_data_tvalid <= xn_axi4s_data_tvalid1;  //xn_axi4s_data_tvalid延时一拍，等rd_en4取出来一个数据在写进去
                end
    
                if (xn_axi4s_data_tvalid == 1'b1) begin
                    fft_in_cnt <= fft_in_cnt + 1'b1;
                end 
            end
            FFT_DATA_OUT : begin
                cnt4 <= 'd0;
                p3 = p1[51:0] + p2[51:0]; //计算能量
                if (xk_axi4s_data_tvalid == 1'b1) begin
                    fft_out_cnt <= fft_out_cnt + 1'b1;
                end
                else begin
                    fft_out_cnt <= 'd0;
                end

                if (fft_out_cnt >= 'd1 && fft_out_cnt <= FFT_LENGTH/2 ) begin  //只要前面一半就行
                    wr_en5 <= 1'b1;
                end
                else begin
                    wr_en5 <= 1'b0;
                end

                if (wr_en5 == 1'b1) begin
                    wr_addr5 <= wr_addr5 + 1'b1;
                end
                else begin
                    wr_addr5 <= 'd0;
                end
            end
            MEL_FILTER : begin
                if (melfb_addr >= 'd2 ) begin
                    if (rd_addr5 == 'd1) begin
                        wr_en6 <= 1'b1;    //拉高一个时钟，开始写
                        wr_data6 <= wr_data6 + p4;
                    end
                    else if (wr_addr6 == MELFB_NUMBER) begin
                        wr_addr6 <= 'd0;   //下一个状态机开始要用到
                    end
                    else if (rd_addr5 == 'd2 && melfb_addr == 'd2) begin   //要到第二轮循环才加地址
                        wr_en6 <= 1'b0;
                        wr_data6 <= 'd0 + p4;
                    end
                    else if (rd_addr5 == 'd2) begin
                        wr_en6 <= 1'b0;
                        wr_addr6 <= wr_addr6 + 1'b1;
                        wr_data6 <= 'd0 + p4;
                    end
                    else begin
                        wr_en6 <= 1'b0;
                        wr_addr6 <= wr_addr6;
                        wr_data6 <= wr_data6 + p4; 
                    end
                end
                rd_addr5 <= rd_addr5 + 1'b1;
                melfb_addr <= melfb_addr + 1'b1;
            end
            LOG_E_COMPUTE:begin
               
                wr_addr6 <= rd_addr6;     //将计算结果存储在同一个ram，取出来计算，然后再把计算结果写进去

                if (flag1 == 1'b1) begin
                    cnt1 <= cnt1 + 1'b1;
                end
                else  begin
                    cnt1 <= 'd0;
                end

                if (rd_addr6 == MELFB_NUMBER) begin
                    rd_addr6 <= 'd0;                 //代表最后一个计算完了，要清零，下一个状态机要用到        
                    wr_en6 <= 1'b0;
                end
                else if (rd_data6 < log_rd_data && log_addr == 'd0 && flag1 == 1'b0) begin //表示在log e 查找表中查找到了结果
                    wr_data6 <= 'd0;
                    wr_en6 <= 1'b1;
                    flag1 <= 1'b1;
                    rd_addr6 <= rd_addr6 + 1'b1;
                    log_addr <= 'd0;             //清零，等待下一个计算
                end
                else if (rd_data6 >= log_rd_data_reg && rd_data6 < log_rd_data && flag1 == 1'b0 ) begin  //表示在log e 查找表中查找到了结果
                    wr_data6 <= log_addr - 1'b1;
                    wr_en6 <= 1'b1;
                    flag1 <= 1'b1;
                    rd_addr6 <= rd_addr6 + 1'b1;
                    log_addr <= 'd0;             //清零，等待下一个计算
                end
                else if (cnt1 == 'd2) begin   //要等待两个时钟周期才开始计算下一个log数组
                    flag1 <= 1'b0;
                    wr_en6 <= 1'b0;
                end
                else if (flag1 == 1'b0) begin
                    wr_en6 <= 1'b0;
                    log_addr <= log_addr + 1'b1;
                end
                else begin
                    wr_en6 <= 1'b0;
                end
            end
            DCT_COMPUTE : begin
                dct_addr <= dct_addr + 1'b1;
                if (rd_addr6 == (MELFB_NUMBER - 1'b1)) begin  //清零
                    rd_addr6 <= 'd0;
                end
                else begin
                    rd_addr6 <= rd_addr6 + 1'b1;
                end
                if (dct_addr >= 'd2 ) begin
                    if (rd_addr6 == 'd1) begin
                        wr_en7 <= 1'b1;    //拉高一个时钟，开始写
                        wr_data7 <= wr_data7 + p5;  //有符号数相加
                    end
                    else if (rd_addr6 == 'd2 && dct_addr == 'd2) begin
                        wr_en7 <= 1'b0;
                        wr_data7 <=  p5;    //地址先不用加
                    end
                    else if (rd_addr6 == 'd2) begin
                        wr_en7 <= 1'b0;
                        wr_addr7 <= wr_addr7 + 1'b1;
                        cnt2 <= cnt2 + 1'b1;         //
                        wr_data7 <=  p5;  //相当于重新开始累加
                    end
                    else begin
                        wr_en7 <= 1'b0;
                        wr_addr7 <= wr_addr7;
                        wr_data7 <= wr_data7 + p5; 
                    end
                end
            end
        endcase
    end
end

//短时能量计算 和过零率
always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        cnt_1024 <= 'd0;
        data_in_reg <= 'd0;
    end
    else begin
        cnt_1024 <= cnt_1024 + 1'b1;
        data_in_reg <= data_in;
    end
end

always @(posedge sck or negedge rst_n) //未经阈值判断的过零个数
begin
    if (~rst_n) begin
        zeroCrossing_cnt2 <= 'd0;
    end
    else if (cnt_1024 == 'd511) begin
        zeroCrossing_cnt2 <= 'd0;
    end
    else if (data_in_reg[15] ^ data_in[15]) begin
        zeroCrossing_cnt2 <= zeroCrossing_cnt2+1'b1;
    end
end

always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        short_time_energy <= 'd0;
    end
    else if (cnt_1024 == 'd511) begin
        short_time_energy <= 'd0;
    end
    else if (short_time_energy >= threshold_hign) begin
        short_time_energy <= short_time_energy;
    end
    else begin
        if (data_in > threshold_hign1) begin
            short_time_energy <= short_time_energy + data_in;
        end
        else begin
            short_time_energy <= short_time_energy - data_in;
        end
    end
end

always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        voice_flag <= 'd0;
    end
    else if (cnt_1024 == 'd511) begin
        if (short_time_energy >= threshold_hign ) begin
            voice_flag <= 'd1;
        end
        else begin
            voice_flag <= 'd0;
        end
    end
end



always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        voice_flag_reg <= 'd0;
    end
    else begin
        voice_flag_reg <= voice_flag;
    end
end


//sin_window_result这个fifo，用来存储加窗后的结果fft的输入
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        wr_en4_reg <= 1'b0;
        wr_data4 <= 'd0;
        wr_en4_reg1 <= 'd0;
    end
    else if (state == SIN_WINDOW) begin
        wr_en4_reg <= wr_en4;
        wr_data4 <= {16'd0,p[23:8]};  //加窗计算结果，取高16位,只用填实部进去
    end
    else begin
        wr_en4_reg <= 1'b0;
        wr_data4 <= 'd0; 
        wr_en4_reg1 <= 'd0;
    end
end



//状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state2 <= INIT2;
    end
    else begin
        case (state2)
            INIT2 : begin
                if (rd_start == 1'b1 && almost_full3 == 1'b0 && fifo_ready == 1'b1) begin
                    state2 <= RD_FIFO1;
                end
            end
            RD_FIFO1 : begin
                if (cnt_256 == 'd255) begin
                    state2 <= DELAY;
                end
            end
            RD_FIFO2 : begin
                if (cnt_768 == 'd767) begin
                    state2 <= INIT2;
                end
            end
            DELAY : begin
                if (delay_8 == 'd7) begin
                    state2 <= RD_FIFO2;
                end
            end
            default: state2 <= INIT2;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cnt_256 <= 'd0;
        delay_8 <= 'd0;
        cnt_768 <= 'd0;
    end
    else begin
        case (state2)
            INIT2 : begin
                cnt_256 <= 'd0;
                delay_8 <= 'd0;
                cnt_768 <= 'd0;
            end
            RD_FIFO1 : begin
                cnt_256 <= cnt_256 + 1'b1;
            end
            RD_FIFO2 : begin
                cnt_768 <= cnt_768 + 1'b1;
            end
            DELAY : begin
                delay_8 <= delay_8 + 1'b1;
            end
        endcase
    end
end



always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en3_reg <= 1'b0;
    end
    else begin
        wr_en3_reg <= rd_en1 | rd_en_fifo;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en_256 <= 1'b0;
    end
    else if(cnt_768 >= ('d768-'d256) && cnt_768 <= 'd767) begin
        wr_en_256 <= 1'b1;
    end
    else begin
        wr_en_256 <= 1'b0;
    end
end

//存储重叠部分的fifo
i_9_16_a_256_fifo i_9_16_a_256_fifo_inst (
  .clk(clk),                      // input
  .rst(~rd_start),                      // input
  .wr_en(wr_en_256),                  // input
  .wr_data(voiceprint_vioce_out),              // input [15:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en1),                  // input
  .rd_data(rd_data1),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

Single_length_2048_almost_1024_fifo data_merge_fifo (  //这个FIFO是模拟移动步长为128，256个数据，一帧的暂存
  .clk(clk),                      // input
  .rst(~rd_start),                      // input
  .wr_en(wr_en3_reg),                  // input
  .wr_data(wr_data3),              // input [15:0]
  .wr_full(),              // output
  .almost_full(almost_full3),      // output
  .rd_en(rd_en3),                  // input
  .rd_data(rd_data3),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

Single_length_1024_width_32 sin_window_result (  //这个fifo用来存储加窗后的结果
  .clk(clk),                      // input
  .rst((~rst_n) | fifo_rst),                      // input
  .wr_en(wr_en4_reg),                  // input
  .wr_data(wr_data4),              // input [31:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en4),                  // input
  .rd_data(rd_data4),              // output [31:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

hanming_data_rom sin_window_inst (   //这里是汉明窗
  .addr(sin_addr),          // input [9:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(sin_rd_data)     // output [7:0]
);

melfb_data_rom melfb_data_rom_inst (  //这里是梅尔滤波器的查找表，31组滤波器
  .addr(melfb_addr),          // input [13:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(melfb_rd_data)     // output [8:0]
);

log_e_data_rom log_e_data_rom_inst ( //这里是log e的查找表
  .addr(log_addr),          // input [5:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(log_rd_data)     // output [56:0]
);

dct_data_rom dct_data_rom_inst (    //dct离散余弦变换,这里是查找表,已更改成31个点的dct
  .addr(dct_addr),          // input [9:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(dct_rd_data)     // output [8:0]
);

single_length_512_width_53_ram single_length_512_width_53_ram_inst (  //存储一整fft后的能量幅值
  .wr_data(p3),    // input [52:0]
  .wr_addr(wr_addr5),    // input [8:0]
  .wr_en(wr_en5),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(rd_addr5),    // input [8:0]
  .rd_data(rd_data5),    // output [52:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);


length_32_width_57_ram length_32_width_57_ram_inst (  //存储梅谱滤波后的结果
  .wr_data(wr_data6_1),    // input [56:0]
  .wr_addr(wr_addr6),    // input [4:0]
  .wr_en(wr_en6),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(rd_addr6),    // input [4:0]
  .rd_data(rd_data6),    // output [56:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);

mfcc_result_14_9_ram mfcc_result_14_9_ram_inst (  //存储多帧mfcc的结果
  .wr_data(wr_data7_1),    // input [8:0]
  .wr_addr(wr_addr7),    // input [13:0]
  .wr_en(wr_en7),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(rd_addr7),    // input [13:0]
  .rd_data(rd_data7),    // output [8:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);

simmpe_mult simmpe_mult_inst (  //加窗计算乘法器
  .a(a),        // input [15:0]
  .b(b),        // input [7:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [23:0]
);

sim_multi_27x27_signed sim_multi_27x27_signed_inst1 (  //能量计算乘法器
  .a(xk_axi4s_data_tdata_real),        // input [26:0]
  .b(xk_axi4s_data_tdata_real),        // input [26:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p1)         // output [53:0]
);

sim_multi_27x27_signed sim_multi_27x27_signed_inst2 ( // 能量计算乘法器
  .a(xk_axi4s_data_tdata_imag),        // input [26:0]
  .b(xk_axi4s_data_tdata_imag),        // input [26:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p2)         // output [53:0]
);

simple_multi_16x9 simple_multi_16x9_inst (
  .a(data_in),        // input [15:0]
  .b(9'd16),        // input [8:0]
  .clk(sck),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(pre_p)         // output [24:0]
);

simple_multi_53x9 simple_multi_53x9_inst (  //melfb 梅谱滤波计算乘法器
  .a(rd_data5),        // input [52:0]
  .b(melfb_rd_data),        // input [8:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p4)         // output [61:0]
);

simple_multi_6x9 simple_multi_6x9_inst (   //dct离散余弦计算
  .a(rd_data6[5:0]),        // input [5:0]
  .b(dct_rd_data),        // input [8:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p5)         // output [14:0]  //要取高7位，因为最高位是符号位
);

endmodule 