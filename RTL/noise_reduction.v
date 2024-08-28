
module noise_reduction 
#(
    parameter DATA_WIDTH = 16,
    //parameter SPLIT_MODE = 'd5,    //分离或者降噪模式配置，1：分离出说话的人声（背景歌声去除）   2：分离出歌声  3:去除旋律  4：分离旋律  5：分离出歌声中的人声
    parameter FFT_LENGTH = 'd1024,
    parameter TOTAL_FRAME = 'd45,  //将一段音频分成100个大帧
    parameter SMALL_FRAME = 'd21    //一个大帧是多少 FFT 帧
)
(   
    input                       clk,
    input                       sck,
    input                       rst_n/*synthesis PAP_MARK_DEBUG="1"*/,

    output wire [DATA_WIDTH - 1:0]  data_out/*synthesis PAP_MARK_DEBUG="1"*/,
    input  signed[DATA_WIDTH - 1:0]     data_in, /*synthesis PAP_MARK_DEBUG="1"*/
    input                       rst_rs232,
    input                       rs232_flag,
    input [7:0]                 rs232_data,
    //fft相关
    
    output reg                      xn_axi4s_data_tvalid,
    output   [16*2-1:0]             xn_axi4s_data_tdata ,
    output reg                      xn_axi4s_data_tlast ,
    input                           xn_axi4s_data_tready,
    output wire                     xn_axi4s_cfg_tvalid ,
    output reg                      xn_axi4s_cfg_tdata  ,
    input                           xk_axi4s_data_tvalid/*synthesis PAP_MARK_DEBUG="1"*/,
    input    [32*2-1:0]             xk_axi4s_data_tdata ,
    input                           xk_axi4s_data_tlast ,
    input    [3:0]                  SPLIT_MODE  /*synthesis PAP_MARK_DEBUG="1"*/ ,
    output wire [45:0]              spectrum_data,
    output wire ['d6 - 'd1:0]       frame_CNT1/*synthesis PAP_MARK_DEBUG="1"*/
  
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
localparam  TOTAL_FRAME_WIDTH     = clog2(TOTAL_FRAME);   
localparam  SMALL_FRAME_WIDTH     = clog2(SMALL_FRAME);   
localparam  FRAME_EN_END          = ((TOTAL_FRAME + 'd10)<={TOTAL_FRAME_WIDTH{1'b1}}) ? (TOTAL_FRAME + 'd10) : {TOTAL_FRAME_WIDTH{1'b1}};   
localparam  FFT_WIDTH             = clog2(FFT_LENGTH);    //10
wire signed [31:0]         xk_axi4s_data_tdata_imag/*synthesis PAP_MARK_DEBUG="1"*/;
wire signed [31:0]         xk_axi4s_data_tdata_real/*synthesis PAP_MARK_DEBUG="1"*/;

wire signed [23:0]         xk_axi4s_data_tdata_ifft_real/*synthesis PAP_MARK_DEBUG="1"*/;
wire                       almost_full1_1;
wire                       almost_full2_2;
reg  [15:0]                imag1;
reg  [15:0]                real1;
wire [23:0]                p/*synthesis PAP_MARK_DEBUG="1"*/;
wire [23:0]                p1/*synthesis PAP_MARK_DEBUG="1"*/;
wire [23:0]                p2/*synthesis PAP_MARK_DEBUG="1"*/;
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
reg                        rd_en1;
wire [15:0]                rd_data1;
reg                        rd_en2;
wire [15:0]                rd_data2;
reg                        rd_en3;
wire signed [15:0]         rd_data3/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [15:0]                wr_data3;
reg                        wr_en3;
reg                        wr_en3_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        start_rd;
reg  [FFT_WIDTH:0]         start_rd_cnt;
reg  [FFT_WIDTH - 'd1:0]   noise_addr;
reg  [FFT_WIDTH - 'd1:0]   sin_data_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        xn_axi4s_data_tvalid1;
reg  [2:0]                 cnt4;
reg  [FFT_WIDTH - 'd1:0]   fft_in_cnt;
reg  [1:0]                 fft_mode_cnt;
// reg  [31:0]                wr_data4/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        wr_en5;
reg                        wr_en5_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        wr_en4_reg/*synthesis PAP_MARK_DEBUG="1"*/;
wire [31:0]                rd_data4/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [FFT_WIDTH - 'd1:0]   sin_addr/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        wr_en4;
reg                        rd_en4;
reg                        rd_en5;
reg                        wr_en6/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [15:0]                 add_result/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        data_out_start;
wire                       almost_full6;
wire [7:0]                 sin_rd_data/*synthesis PAP_MARK_DEBUG="1"*/;
wire [7:0]                 noise_rd_data;
reg  [15:0]                data_test/*synthesis PAP_MARK_DEBUG="1"*/;
wire [TOTAL_FRAME - 'd1:0] vocal_rd_data;
reg  [FFT_WIDTH - 'd1:0]   vocal_addr ;
wire [TOTAL_FRAME - 'd1:0] sing_rd_data;
reg  [FFT_WIDTH - 'd1:0]   sing_addr ;
wire [TOTAL_FRAME - 'd1:0] move_rhythm_rd_data;
reg  [FFT_WIDTH - 'd1:0]   move_rhythm_addr ;
wire [TOTAL_FRAME - 'd1:0] rhythm_rd_data;
reg  [FFT_WIDTH - 'd1:0]   rhythm_addr ;
wire [TOTAL_FRAME - 'd1:0] split_sing_vocal_rd_data;
reg  [FFT_WIDTH - 'd1:0]   split_sing_vocal_addr;
reg  [TOTAL_FRAME - 'd1:0] split_rd_data;
reg  [TOTAL_FRAME  :0]     split_rd_data1/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [FFT_WIDTH - 1'b1:0]  noise_reduction_addr;
wire [TOTAL_FRAME:0]       noise_reduction_rd_data;
reg  [31:0]                fft_result_data;
wire signed [15:0]         p_1;  //ifft后重叠相加部分是有符号数的计算，故重新定义
wire signed [15:0]         rd_data5;
reg  [9:0]                 zeroCrossing_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [9:0]                 zeroCrossing_cnt_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [9:0]                 zeroCrossing_cnt2/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [9:0]                 zeroCrossing_cnt2_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg  signed [15:0]         wr_data3_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        frame_valid_en2/*synthesis PAP_MARK_DEBUG="1"*/;

reg  [31:0]                wr_data4;

reg [FFT_WIDTH - 'd1:0]    voice_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        frame_valid_en/*synthesis PAP_MARK_DEBUG="1"*/; 
reg [SMALL_FRAME_WIDTH - 'd1:0] frame_valid_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
reg [TOTAL_FRAME_WIDTH - 'd1:0] frame_CNT/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        rd_en3_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg                        rd_en3_pose_flag/*synthesis PAP_MARK_DEBUG="1"*/;

reg [7:0] xk_axi4s_data_tlast_cnt;
reg  [23:0] wr_data6_real;
reg  [23:0] wr_data6_imag;
reg [9:0]  wr_addr6;
reg wr_en6_1;
reg wr_en6_reg;
reg [9:0]  rd_addr6;
wire [23:0] rd_data6_real;
wire [23:0] rd_data6_imag;
wire [15:0] rd_data6_real1/*synthesis PAP_MARK_DEBUG="1"*/;
wire [15:0] rd_data6_imag1/*synthesis PAP_MARK_DEBUG="1"*/;
reg [15:0] real2;
reg [15:0] imag2;
reg [15:0] xk_axi4s_data_tdata_real_reg/*synthesis PAP_MARK_DEBUG="1"*/;
reg [15:0] xk_axi4s_data_tdata_imag_reg/*synthesis PAP_MARK_DEBUG="1"*/;
assign rd_data6_real1 = rd_data6_real[22:7]/*synthesis PAP_MARK_DEBUG="1"*/;
assign rd_data6_imag1 = rd_data6_imag[22:7]/*synthesis PAP_MARK_DEBUG="1"*/;
reg [9:0] wr_addr7;
reg wr_en7;
reg [9:0] rd_addr7;
wire rd_data7;


reg  [3:0]                 cnt5;

reg [8:0]  cnt_1024/*synthesis PAP_MARK_DEBUG="1"*/;
reg signed [30:0] short_time_energy/*synthesis PAP_MARK_DEBUG="1"*/;
reg [15:0]  data_in_reg;
reg         voice_flag;
parameter        INIT         = 8'b00000000;
parameter        WAIT_DATA    = 8'b00000001;  //等待数据
parameter        FFT_MODE_CFG = 8'b00000010;  //FFT模式配置成fft or ifft
parameter        SIN_WINDOW   = 8'B00100000;  //加窗
parameter        FFT_DATA_IN  = 8'b00000100;  //将加sin窗后的数据传给fft_demo
parameter        FFT_DATA_OUT = 8'b00001000;  //等待数据变换完成，接收传出的数据，将其存储进fifo或ram里面，进行ifft或者加窗输出
parameter        END_DATA_OUT = 8'b00010000;  //对频域的数据进行处理,处理完以后跳转到FFT_MODE_CFG设置成ifft，
parameter signed threshold_hign = 16'b0111111111111111;  //+32767
parameter signed threshold_low  = 16'b1000000000000000; // -32768

parameter signed threshold_hign1 = 16'b0000000000011111;  //+32767
parameter signed threshold_low1  = 16'b1111111111100000; // -32768

parameter signed threshold_hign2 = 16'b0000000000000111;  //+12
parameter signed threshold_low2  = 16'b1111111111111000; // -0100

parameter signed threshold_hign3 = 10000;
//assign xn_axi4s_data_tvalid = (state == FFT_DATA_IN) xn_axi4s_data_tvalid1_reg4 : 1'b0;
//assign xn_axi4s_data_tdata = (fft_mode_cnt == 'd1 ) ? {16'd0,data_test} : rd_data4 ;
assign xn_axi4s_data_tdata = rd_data4 ;
assign xk_axi4s_data_tdata_ifft_real = xk_axi4s_data_tdata[31:8];  //ifft 后的结果是扩大了256倍的。
assign xk_axi4s_data_tdata_imag = xk_axi4s_data_tdata[63:32];
assign xk_axi4s_data_tdata_real = xk_axi4s_data_tdata[31:0];
assign xn_axi4s_cfg_tvalid = (state == FFT_MODE_CFG) ? 1'b1:1'b0; //状态机处于fft配置模式就拉高
assign frame_CNT1 = (frame_CNT < TOTAL_FRAME) ? (frame_CNT) : (TOTAL_FRAME - 1'b1);
assign almost_full1_1 = ~almost_full1;
assign almost_full2_2 = ~almost_full2;
assign p_1 = p[23:8];
assign spectrum_data = (SPLIT_MODE == 'd6) ? split_rd_data1 : {1'b0,split_rd_data};

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_test <= 'd0;
    end
    else if (rd_en4 == 1'b1) begin
        data_test <= data_test + 1'b1;
    end
    else begin
        data_test <= 'd0;
    end
end
//状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n | rst_rs232) begin
        state <= INIT;
    end
    else begin
        case (state)
            INIT: begin
                if (~rst_n) begin
                    state <= INIT;
                end
                else begin
                    state <= WAIT_DATA;
                end
            end
            WAIT_DATA: begin
                if (almost_full3) begin
                    state <= FFT_MODE_CFG;    //数据准备好就跳转到
                end
                else begin
                    state <= WAIT_DATA;
                end
            end
            FFT_MODE_CFG:begin
                if (fft_mode_cnt == 'd0) begin
                    state <= SIN_WINDOW;
                end
                else begin
                    state <= FFT_DATA_IN ;
                end
                
            end
            SIN_WINDOW:begin
                if (sin_data_cnt == (FFT_LENGTH - 1'b1)) begin
                    state <= FFT_DATA_IN;
                end
            end
            FFT_DATA_IN:begin
                if (fft_in_cnt == (FFT_LENGTH - 1'b1) ) begin
                    state <= FFT_DATA_OUT;
                end
            end
            FFT_DATA_OUT:begin
                if (xk_axi4s_data_tlast_reg1 == 1'b1 && fft_mode_cnt == 'd1) begin
                    state <= FFT_MODE_CFG;
                end
                else if (xk_axi4s_data_tlast_reg1 == 1'b1 && fft_mode_cnt == 'd2) begin
                    state <= END_DATA_OUT;
                end
            end
            END_DATA_OUT:begin
                if (sin_data_cnt == (FFT_LENGTH - 1'b1)) begin
                    state <= INIT;
                end
            end
            
            
            default: state <= INIT;
        endcase
    end
end

//状态机内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a <= 'd0;
        b <= 'd0;
        sin_addr <= {FFT_WIDTH{1'b1}};  //和fifo取出的值同步才行，加1后的地址为0，这是才是第一个数据，和fifo对应。
        rd_en3 <= 'd0;
        noise_addr <= 'd0;
        vocal_addr <= 'd0;
        rd_addr7 <= 'd0;
        wr_en4 <= 'd0;
        cnt4   <= 'd0;
        rd_en4 <= 'd0;
        fft_in_cnt <= 'd0;
        xn_axi4s_data_tlast <= 'd0;
        xn_axi4s_data_tvalid <= 'd0;
        xn_axi4s_data_tvalid1 <= 'd0;
        fft_mode_cnt <= 'd0;
        xn_axi4s_cfg_tdata <= 1'b0;
        sin_data_cnt <= 'd0;
        xk_axi4s_data_tlast_reg <= 'd0;
        imag1 <= 'd0;
        real1 <= 'd0;
        wr_en5 <= 1'b0;
        rd_en5 <= 1'b0;
        wr_en6 <= 1'b0;
        wr_en5_reg <= 1'b0;
        add_result <= 'd0;
        fifo_rst <= 1'b1;  //fifo清空
        xk_axi4s_data_tlast_reg1 <= 'd0;
        sing_addr <= 'd0;
        move_rhythm_addr <= 'd0;
        rhythm_addr <= 'd0;
        split_sing_vocal_addr <= 'd0;
        noise_reduction_addr <= 'd0;
    end
    else begin
        case (state)
            INIT :begin
                a <= 'd0;
                b <= 'd0;
                sin_addr <= {FFT_WIDTH{1'b1}};  //和fifo取出的值同步才行，加1后的地址为0，这是才是第一个值
                rd_en3 <= 'd0;
                noise_addr <= 'd0;
                vocal_addr <= 'd0;
                rd_addr7 <= 'd0;
                wr_en4 <= 'd0;
                cnt4   <= 'd0;
                rd_en4 <= 'd0;
                fft_in_cnt <= 'd0;
                xn_axi4s_data_tlast <= 'd0;
                xn_axi4s_data_tvalid <= 'd0;
                xn_axi4s_data_tvalid1 <= 'd0;
                fft_mode_cnt <= 'd0;
                xn_axi4s_cfg_tdata <= 1'b1;
                sin_data_cnt <= 'd0;
                xk_axi4s_data_tlast_reg <= 'd0;
                imag1 <= 'd0;
                real1 <= 'd0;
                wr_en5 <= 1'b0;
                rd_en5 <= 1'b0;
                wr_en6 <= 1'b0;
                wr_en5_reg <= 1'b0;
                add_result <= 'd0;
                fifo_rst <= 1'b1;  //fifo清空
                xk_axi4s_data_tlast_reg1 <= 'd0;
                sing_addr <= 'd0;
                move_rhythm_addr <= 'd0;
                rhythm_addr <= 'd0;
                split_sing_vocal_addr <= 'd0;
                noise_reduction_addr <= 'd0;
            end
            WAIT_DATA:begin
                fifo_rst <= 1'b0; 
            end
            FFT_MODE_CFG:begin
                fft_mode_cnt <= fft_mode_cnt + 1'b1;
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
                xn_axi4s_cfg_tdata <= 1'b0;//下次就配置成ifft
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
            FFT_DATA_OUT:begin
                sin_addr <= {FFT_WIDTH{1'b1}};  //初始化下，之后要用到
                cnt4 <= 'd0;
                fifo_rst <= 1'b0;
                xk_axi4s_data_tlast_reg <= xk_axi4s_data_tlast;
                xk_axi4s_data_tlast_reg1 <= xk_axi4s_data_tlast_reg;
                if (xk_axi4s_data_tvalid == 1'b1) begin
                    wr_en4 <= 1'b1;
                    noise_addr <= noise_addr + 1'b1;
                    vocal_addr <= vocal_addr + 1'b1;
                    rd_addr7 <= rd_addr7 + 1'b1;
                    sing_addr <= sing_addr + 1'b1;
                    move_rhythm_addr <= move_rhythm_addr + 1'b1;
                    rhythm_addr <= rhythm_addr + 1'b1;
                    split_sing_vocal_addr <= split_sing_vocal_addr + 1'b1;
                    noise_reduction_addr <= noise_reduction_addr + 1'b1;
                    if (xk_axi4s_data_tdata_imag > threshold_hign  ) begin   // 虚部处理
                        imag1 <= threshold_hign;
                    end
                    else if (xk_axi4s_data_tdata_imag < threshold_low) begin
                        imag1 <= threshold_low;
                    end
                    else begin
                        imag1 <= xk_axi4s_data_tdata_imag[15:0];  //阈值处理
                    end
                    if (fft_mode_cnt == 'd1) begin
                        if (xk_axi4s_data_tdata_real > threshold_hign ) begin   //实部处理
                            real1 <= threshold_hign;
                        end
                        else if (xk_axi4s_data_tdata_real < threshold_low) begin
                            real1 <= threshold_low;
                        end
                        else begin
                            real1 <= xk_axi4s_data_tdata_real[15:0];
                        end
                    end
                    else begin
                        if (xk_axi4s_data_tdata_ifft_real > threshold_hign ) begin   //iff后的实部处理
                            real1 <= threshold_hign;
                        end
                        else if (xk_axi4s_data_tdata_ifft_real < threshold_low) begin
                            real1 <= threshold_low;
                        end
                        else begin
                            real1 <= xk_axi4s_data_tdata_ifft_real[15:0];
                        end               
                    end
                end
                else begin
                    wr_en4 <= 1'b0;
                    noise_addr <= noise_addr;
                    vocal_addr <= vocal_addr;
                    sing_addr <= sing_addr;
                    rd_addr7 <= rd_addr7;
                    move_rhythm_addr <= move_rhythm_addr;
                    rhythm_addr <= rhythm_addr ;
                    split_sing_vocal_addr <= split_sing_vocal_addr ;
                    noise_reduction_addr <= noise_reduction_addr ;
                end
            end
            END_DATA_OUT:begin      //前面的128个数据与上一次ifft的结果（存进FIFO的数据）重叠相加，后面的128个数据写进fifo
                if (cnt4 > 'd4) begin
                    cnt4 <= cnt4;
                end
                else begin
                    cnt4   <= cnt4 + 1'b1;      
                end
    
                a <= rd_data4[15:0];         //只用输出实部就行
                b <= sin_rd_data;
                sin_addr <= sin_addr + 1'b1;
                rd_en4 <= 1'b1;
    
                if (p_1 + rd_data5 > threshold_hign  ) begin    //重叠相加部分
                    add_result <= threshold_hign;
                end
                else if (p_1 + rd_data5 < threshold_low) begin
                    add_result <= threshold_low;
                end
                else begin
                    add_result <= p_1 + rd_data5;  //阈值处理
                end
    
    
                if (sin_data_cnt == (FFT_LENGTH - 1'b1)) begin
                    wr_en5 <= 1'b0; 
                    wr_en5_reg <= 1'b0;
                end
                else if (sin_data_cnt == (FFT_LENGTH/2 - 'd2)) begin
                    rd_en5 <= 1'b0;
                end
                else if (sin_data_cnt == (FFT_LENGTH/2 - 1'b1)) begin
                    wr_en5_reg <= 1'b1;
                end
                else if (sin_data_cnt == (FFT_LENGTH/2)) begin
                    wr_en6 <= 1'b0;
                end
    
                else if (cnt4 == 'd2) begin  //相当于延迟2个时钟周期在写进去    
                    rd_en5 <= 1'b1;
                end
                else if (cnt4 == 'd3) begin  //相当于延迟3个时钟周期在写进去
                    wr_en5 <= 1'b1;
                end
                else if (cnt4 == 'd4) begin  //相当于延迟3个时钟周期在写进去
                    wr_en6 <= 1'b1;
                end
    
                if (wr_en5 == 1'b1) begin
                    sin_data_cnt <=  sin_data_cnt + 1'b1;  //sin_data_cnt 自动清零了，后续不用置零
                end
    
            end
        endcase
    end
end

//一帧的过零个数统计
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        wr_data3_reg <= 'd0;
    end
    else begin
        wr_data3_reg <= wr_data3;
    end
end

always @(posedge clk or negedge rst_n)   //阈值判断后的过零个数
begin
    if (~rst_n) begin
        zeroCrossing_cnt <= 'd0;
        zeroCrossing_cnt_reg <= 'd0;
    end
    else if (wr_en3_reg == 1'b0) begin
        zeroCrossing_cnt <= 'd0;
    end
    else if (wr_en3_reg == 1'b1 && (wr_data3_reg[15] ^ wr_data3[15]) && ((wr_data3_reg >threshold_hign2) || (wr_data3_reg < threshold_low2))) begin
        zeroCrossing_cnt <= zeroCrossing_cnt+1'b1;
        zeroCrossing_cnt_reg <= zeroCrossing_cnt;
    end
end

always @(posedge clk or negedge rst_n) //未经阈值判断的过零个数
begin
    if (~rst_n) begin
        zeroCrossing_cnt2 <= 'd0;
        zeroCrossing_cnt2_reg <= 'd0;
    end
    else if (wr_en3_reg == 1'b0) begin
        zeroCrossing_cnt2 <= 'd0;
    end
    else if (wr_en3_reg == 1'b1 && (wr_data3_reg[15] ^ wr_data3[15]) ) begin
        zeroCrossing_cnt2 <= zeroCrossing_cnt2+1'b1;
        zeroCrossing_cnt2_reg <= zeroCrossing_cnt2;
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



always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        short_time_energy <= 'd0;
    end
    else if (cnt_1024 == 'd511) begin
        short_time_energy <= 'd0;
    end
    else if (short_time_energy >= threshold_hign3) begin
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
    if (~rst_n) begin
        frame_valid_en <= 'd0;

    end
    else if (frame_CNT == FRAME_EN_END) begin
        frame_valid_en <= 1'b0;

    end
    // else if ( frame_valid_en == 1'b1 && frame_CNT == 'd4  && cnt5 <= 'd3) begin  //排除突发噪声的干扰。
    //     frame_valid_en <= 1'b0;
    //     cnt5 <= 'd0;
    // end
    // else if (voice_flag == 1'b1 && SPLIT_MODE == 'd6) begin
    //     frame_valid_en <= 1'b1;
    // end
    else if (zeroCrossing_cnt_reg >= 'd80 && zeroCrossing_cnt2_reg <= 'd250 && wr_en3_reg == 1'b0) begin
        frame_valid_en <= 1'b1;
    end
end

//对应一整段音频的处理大帧频段计数
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        frame_CNT <= 'd0;
    end
    else if (frame_valid_en == 1'b1 && frame_valid_cnt == 'd15 && rd_en3_pose_flag == 1'b1 && frame_CNT == 'd0) begin
        frame_CNT <= frame_CNT + 1'b1; 
    end
    else if (frame_valid_en == 1'b1 && frame_valid_cnt == (SMALL_FRAME - 'd1) && rd_en3_pose_flag == 1'b1) begin  //21帧是一个大帧
        frame_CNT <= frame_CNT + 1'b1;
    end
    else if (frame_valid_en == 1'b0) begin
        frame_CNT <= 'd0;
    end
end
//有效帧计数
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        frame_valid_cnt <= 'd0;
    end
    else if (frame_valid_en == 1'b1 && rd_en3_pose_flag == 1'b1) begin
        if (frame_valid_cnt == 'd15 && frame_CNT == 'd0) begin
            frame_valid_cnt <= 'd0;
        end
        else if (frame_valid_cnt == (SMALL_FRAME - 'd1)) begin
            frame_valid_cnt <= 'd0;
        end
        else begin
            frame_valid_cnt <= frame_valid_cnt + 1'b1;
        end
    end
    else if (frame_valid_en == 1'b0) begin
        frame_valid_cnt <= 'd0;
    end
end

//rd_en3边沿检测
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        rd_en3_reg <= 'd0;
        rd_en3_pose_flag <= 'd0;
    end
    else  begin
        rd_en3_reg <= rd_en3;
        rd_en3_pose_flag <= (~rd_en3_reg) & rd_en3;
    end
end

//分离模式的选择
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n) begin
        split_rd_data <= 'd0;
        split_rd_data1 <= 'd0;
    end
    else if (SPLIT_MODE == 'd1) begin
        split_rd_data <= vocal_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd2) begin
        split_rd_data <= sing_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd3) begin
        split_rd_data <= move_rhythm_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd4) begin
        split_rd_data <= rhythm_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd5) begin
        split_rd_data <= split_sing_vocal_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd6) begin
        split_rd_data1 <= noise_reduction_rd_data ;
        fft_result_data <= {imag1,real1};
    end
    else if (SPLIT_MODE == 'd7) begin
        split_rd_data <= {TOTAL_FRAME{rd_data7}};
        fft_result_data <= {imag1,real1};
    end
    
end

//sin_window_result这个fifo，用来存储加窗后的结果ifft的输入，与存储阈值化处理以后要进行ifft的输入，这里是进行写入数据的选择
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
    else if (state == FFT_DATA_OUT && fft_mode_cnt == 'd1) begin  //将fft的结果阈值化处理，并将噪声分量置0
        wr_en4_reg1 <= wr_en4;
        wr_en4_reg <= wr_en4_reg1;
        if (split_rd_data1[TOTAL_FRAME - 'd4 - frame_CNT1 ] == 1'b1 && SPLIT_MODE == 'd6) begin
            wr_data4 <= 'd0;
        end
        else if (SPLIT_MODE == 'd7 && split_rd_data[0] == 1'b1) begin
            wr_data4 <= 'd0;
        end
        else if (split_rd_data[TOTAL_FRAME - 'd1 - frame_CNT1] == 1'b1 && SPLIT_MODE != 'd6) begin
            wr_data4 <= 'd0;
        end
        else begin
            wr_data4 <= fft_result_data;
        end
    end
    else if (state == FFT_DATA_OUT && fft_mode_cnt == 'd2) begin     // 将反fft的结果阈值化处理，
        wr_en4_reg <= wr_en4;
        wr_data4 <= {16'd0,real1}; 
    end
    else begin
        wr_en4_reg <= 1'b0;
        wr_data4 <= 'd0; 
        wr_en4_reg1 <= 'd0;
    end
end
//cnt计数
always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        cnt_512 <= 'd0;
    end
    else begin
        cnt_512 <= cnt_512 + 1'b1;
    end
end

//写delay_128_fifo 使能生成
always @(posedge sck or negedge rst_n)
begin
    if(~rst_n) begin
        delay_128_wr_en <= 'd0;
    end
    else if(cnt_512 == (FFT_LENGTH/2 - 1'b1)) begin
        delay_128_wr_en <= 1'b1;
    end
    else begin
        delay_128_wr_en <= delay_128_wr_en;
    end
end

//////////////////在clk时钟下，生成将两个fifo的数据的读使能 与交叉写进另外一个fifo的写使能，模拟移动步长

always @(posedge clk or negedge rst_n)   //实际上连的是几乎空，因为读时钟比写时钟快很多，而几乎满是在写时钟下控制的
begin
    if(~rst_n) begin
        almost_full1_reg1 <= 1'b0;
        almost_full2_reg1 <= 1'b0;
        almost_full1_reg2 <= 1'b0;
        almost_full2_reg2 <= 1'b0;
    end
    else begin
        almost_full1_reg1 <= almost_full1_1;
        almost_full2_reg1 <= almost_full2_2;
        almost_full1_reg2 <= almost_full1_reg1;
        almost_full2_reg2 <= almost_full2_reg1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        start_rd <= 'd0;
    end
    else if (start_rd_cnt == (FFT_LENGTH - 1'b1)) begin
        start_rd <= 1'b0;
    end
    else if(almost_full1_reg2 & almost_full2_reg2) begin
        start_rd <= 'd1;
    end
    else begin
        start_rd <= start_rd;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        start_rd_cnt <= 'd0;
    end
    else if (start_rd == 1'b0 && wr_en3_reg == 'd0) begin
        start_rd_cnt <= 'd0;
    end
    else if(start_rd == 1'b1) begin
        start_rd_cnt <= start_rd_cnt + 1'b1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        rd_en1 <= 'd0;
        rd_en2 <= 'd0;
    end
    else if(start_rd_cnt <= (FFT_LENGTH/2 - 1'b1)) begin
        rd_en1 <= start_rd;
        wr_data3 <= rd_data1;
        rd_en2 <= 1'b0;
    end
    else if(start_rd_cnt == (FFT_LENGTH/2) || start_rd_cnt == (FFT_LENGTH/2 + 1'b1)) begin
        rd_en2 <= start_rd;
        wr_data3 <= rd_data1;
        rd_en1 <= 1'b0;
    end
    else begin
        rd_en2 <= start_rd;
        wr_data3 <= rd_data2;
        rd_en1 <= 1'b0;      
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        wr_en3 <= 'd0;
        wr_en3_reg <= 'd0;
    end
    else  begin
        wr_en3 <= rd_en1 + rd_en2;
        wr_en3_reg <= wr_en3;
    end
end

always @(posedge sck or negedge rst_n) begin  //输出最终数据的使能
    if(~rst_n) begin
        data_out_start <= 'd0;
    end
    else if(almost_full6 == 1'b1) begin
        data_out_start <= 1'b1;
    end
end

//自适应降噪模块
//串口接收数据，开始自适应收集频谱使能
reg     clloct_start/*synthesis PAP_MARK_DEBUG="1"*/;
reg     rst_2;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        clloct_start <= 1'b0;
        rst_2 <= 1'b0;
    end
    else if (rs232_data == 8'b00110001 && rs232_flag == 1'b1) begin
        clloct_start <= 1'b1;
        rst_2 <= 1'b1;
    end
    else if (xk_axi4s_data_tlast_cnt == 'd128) begin   //收集128个数据后，停止收集
        clloct_start <= 1'b0;
        rst_2 <= 1'b0;
    end
    else begin
        rst_2 <= 1'b0;
    end
end
//xk_axi4s_data_tlast 计数

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        xk_axi4s_data_tlast_cnt <= 'd0;
    end
    else if (xk_axi4s_data_tlast_reg == 1'b1 && clloct_start == 1'b1 && fft_mode_cnt == 'd1) begin
        xk_axi4s_data_tlast_cnt <= xk_axi4s_data_tlast_cnt + 1'b1;
    end
    else if (clloct_start == 1'b0) begin
        xk_axi4s_data_tlast_cnt <= 'd0;
    end
end

//rd_addr6 在xk_axi4s_data_tvalid自增
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rd_addr6 <= 'd0;
    end
    else if (xk_axi4s_data_tvalid == 1'b1  && fft_mode_cnt == 'd1) begin
        rd_addr6 <= rd_addr6 + 1'b1;
    end
    else begin
        rd_addr6 <= 'd0;
    end
end

reg clloct_start_reg;
//xk_axi4s_data_tdata_real_reg,xk_axi4s_data_tdata_imag_reg 用来存储xk_axi4s_data_tdata的值
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        xk_axi4s_data_tdata_real_reg <= 'd0;
        xk_axi4s_data_tdata_imag_reg <= 'd0;
        real2 <= 'd0;
        imag2 <= 'd0;
        clloct_start_reg <= 'd0;
    end
    else begin
        //负数变正数，三目运算符
        xk_axi4s_data_tdata_real_reg <= (xk_axi4s_data_tdata[15] == 1'b0) ? xk_axi4s_data_tdata[15:0] :~(xk_axi4s_data_tdata[15:0] - 1'b1);
        xk_axi4s_data_tdata_imag_reg <= (xk_axi4s_data_tdata[47] == 1'b0) ? xk_axi4s_data_tdata[47:32]:~(xk_axi4s_data_tdata[47:32] - 1'b1);
        real2 <= real1 - rd_data6_real1;
        imag2 <= imag1 - rd_data6_imag1;
        clloct_start_reg <= clloct_start;

    end
end

//wr_data6_real,wr_data6_imag :xk_axi4s_data_tdata_real_reg+rd_data6_real
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_data6_real <= 'd0;
        //wr_data6_imag <= 'd0;
        wr_en6_reg <= 1'b0;
    end
    else begin
        wr_data6_real <= xk_axi4s_data_tdata_real_reg + rd_data6_real + xk_axi4s_data_tdata_imag_reg;
        //wr_data6_imag <= xk_axi4s_data_tdata_imag_reg + rd_data6_imag;
        wr_en6_reg <= wr_en6_1;

    end

end

//wr_en6 为xk_axi4s_data_tvalid 打两拍
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_en6_1 <= 1'b0;
    end
    else if (xk_axi4s_data_tvalid == 1'b1 && fft_mode_cnt == 'd1 && clloct_start == 1'b1) begin
        wr_en6_1 <= 1'b1;
    end
    else begin
        wr_en6_1 <= 1'b0;
    end
end

//wr_addr6 在wr_en6_reg为1时自增
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        wr_addr6 <= 'd0;
    end
    else if (wr_en6_reg == 1'b1) begin
        wr_addr6 <= wr_addr6 + 1'b1;
    end
    else begin
        wr_addr6 <= 'd0;
    end
end

//噪音幅度值大小排序算法，状态机实现
reg  [4:0]  state2;
parameter INTI2 = 5'b00001;
parameter WAIT_DATA2 = 5'b00010;
parameter WR_ADDR = 5'b00100;  //生成对称坐标的值
parameter WR_EN  = 5'b01000;

parameter paixu_number = 'd25;

reg [4:0]  paixu_cnt;
reg  cnt_1;
reg [23:0]   max_value;
reg [23:0]   max_value_last;

//状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state2 <= INTI2;
    end
    else begin
        case(state2)
            INTI2:begin
                if (clloct_start_reg &(~clloct_start)) begin
                    state2 <= WAIT_DATA2;
                end
            end
            WAIT_DATA2:begin
                if (xk_axi4s_data_tlast_reg == 1'b1 && fft_mode_cnt == 'd1) begin
                    state2 <= WR_EN;
                end
            end
            WR_ADDR:begin
                state2 <= WR_EN;
            end
            WR_EN:begin
                if (paixu_cnt == paixu_number) begin
                    state2 <= INTI2;
                end
                else if (cnt_1 == 1'b1) begin
                    state2 <= WAIT_DATA2;
                end
                else begin
                    state2 <= WR_ADDR;
                end
            end
        endcase
    end
end
//内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cnt_1 <= 1'b0;
        wr_en7 <= 1'b0;
        max_value_last <= {24{1'b1}};
        max_value <= 'd0;
        wr_addr7 <= 'd0;
        paixu_cnt <= 'd0;
    end
    else begin
        case(state2)
            INTI2:begin
                cnt_1 <= 1'b0;
                wr_en7 <= 1'b0;
                max_value_last <= {24{1'b1}};
                max_value <= 'd0;
                wr_addr7 <= 'd0;
                paixu_cnt <= 'd0;
            end
            WAIT_DATA2:begin
                cnt_1 <= 1'b0;
                wr_en7 <= 1'b0;
                if (rd_addr6 >= 'd1) begin
                    if (max_value < rd_data6_real && rd_data6_real < max_value_last) begin
                        max_value <= rd_data6_real;
                        wr_addr7 <= rd_addr6 - 1'b1;
                    end
                end
            end
            WR_ADDR:begin
                wr_en7 <= 1'b0;
                wr_addr7 <=  'd1024 - wr_addr7 ;
                paixu_cnt <= paixu_cnt + 1'b1;
                max_value_last <= max_value;
                max_value <= 'd0;
            end
            WR_EN:begin
                cnt_1 <= cnt_1 + 1'b1;
                wr_en7 <= 1'b1;
            end
        endcase
    end
end

i_10_24_ram i_10_24_ram1 (
  .wr_data(wr_data6_real),    // input [23:0]
  .wr_addr(wr_addr6),    // input [9:0]
  .wr_en(wr_en6_reg),        // input
  .wr_clk(clk),      // input
  .wr_rst(rst_2),      // input
  .rd_addr(rd_addr6),    // input [9:0]
  .rd_data(rd_data6_real),    // output [23:0]
  .rd_clk(clk),      // input
  .rd_rst(rst_2)       // input
);



i_1_10_ram i_1_10_ram (
  .wr_data(1'b1),    // input
  .wr_addr(wr_addr7),    // input [9:0]
  .wr_en(wr_en7),        // input
  .wr_clk(clk),      // input
  .wr_rst(rst_2),      // input
  .rd_addr(rd_addr7),    // input [9:0]
  .rd_data(rd_data7),    // output
  .rd_clk(clk),      // input
  .rd_rst(rst_2)       // input
);

// i_10_24_ram i_10_24_ram2 (
//   .wr_data(wr_data6_imag),    // input [23:0]
//   .wr_addr(wr_addr6),    // input [9:0]
//   .wr_en(wr_en6_reg),        // input
//   .wr_clk(clk),      // input
//   .wr_rst(rst_2),      // input
//   .rd_addr(rd_addr6),    // input [9:0]
//   .rd_data(rd_data6_imag),    // output [23:0]
//   .rd_clk(clk),      // input
//   .rd_rst(rst_2)       // input
// );

Dual_length_2048_almost_1024_fifo nomal_fifo (
  .wr_clk(sck),                // input
  .wr_rst(~rst_n),                // input
  .wr_en(rst_n),                  // input
  .wr_data(data_in),              // input [15:0]
  .wr_full(),              // output
  .almost_full(),      // output+
  .rd_clk(clk),                // input
  .rd_rst(~rst_n),                // input
  .rd_en(rd_en1),                  // input
  .rd_data(rd_data1),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty(almost_full1)     // output
);

Dual_length_1024_almost_512_fifo delay_128_fifo (
  .wr_clk(sck),                // input
  .wr_rst(~rst_n),                // input
  .wr_en(delay_128_wr_en),                  // input
  .wr_data(data_in),              // input [15:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_clk(clk),                // input
  .rd_rst(~rst_n),                // input
  .rd_en(rd_en2),                  // input
  .rd_data(rd_data2),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty(almost_full2)     // output
);

Single_length_2048_almost_1024_fifo data_merge_fifo (  //这个FIFO是模拟移动步长为128，256个数据，一帧的暂存
  .clk(clk),                      // input
  .rst(~rst_n),                      // input
  .wr_en(wr_en3_reg),                  // input
  .wr_data(wr_data3),              // input [15:0]
  .wr_full(),              // output
  .almost_full(almost_full3),      // output
  .rd_en(rd_en3),                  // input
  .rd_data(rd_data3),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

Single_length_1024_width_32 sin_window_result (  //这个fifo用来存储加窗后的结果ifft的输入，与存储阈值化处理以后要进行ifft的输入
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

sin_window sin_window_inst (
  .addr(sin_addr),          // input [9:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(sin_rd_data)     // output [7:0]
);

noise_rom noise_rom_inst (
  .addr(noise_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(noise_rd_data)     // output [2:0]
);

simmpe_mult simmpe_mult_inst (
  .a(a),        // input [15:0]
  .b(b),        // input [7:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [23:0]
);

simmpe_mult simmpe_mult1_inst (
  .a(imag1),        // input [15:0]
  .b(noise_rd_data),        // input [7:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p1)         // output [23:0]
);

simmpe_mult simmpe_mult2_inst (
  .a(real1),        // input [15:0]
  .b(noise_rd_data),        // input [7:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p2)         // output [23:0]
);



single_length_256_width_16_fifo ifft_add_fifo (
  .clk(clk),                      // input
  .rst(~rst_n),                      // input
  .wr_en(wr_en5_reg),                  // input
  .wr_data(p_1),              // input [15:0]
  .wr_full(),              // output
  .almost_full(),      // output
  .rd_en(rd_en5),                  // input
  .rd_data(rd_data5),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

Dual_length_1024_almost_512_fifo output_fifo (
  .wr_clk(clk),                // input
  .wr_rst(~rst_n),                // input
  .wr_en(wr_en6),                  // input
  .wr_data(add_result),              // input [15:0]
  .wr_full(),              // output
  .almost_full(almost_full6),      // output+
  .rd_clk(sck),                // input
  .rd_rst(~rst_n),                // input
  .rd_en(data_out_start),                  // input
  .rd_data(data_out),              // output [15:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

split_vocal_rom split_vocal_rom_inst (
  .addr(vocal_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(vocal_rd_data)     // output [99:0]
);

split_sing_rom split_sing_rom_inst (
  .addr(sing_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(sing_rd_data)     // output [99:0]
);

move_rhythm_rom move_rhythm_rom (
  .addr(move_rhythm_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(move_rhythm_rd_data)     // output [99:0]
);

split_rhythm_rom split_rhythm_rom_inst (
  .addr(rhythm_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(rhythm_rd_data)     // output [99:0]
);

split_sing_vocal_rom split_sing_vocal_rom_inst (
  .addr(split_sing_vocal_addr),          // input [7:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(split_sing_vocal_rd_data)     // output [99:0]
);

noise_reduction1_rom the_instance_name (
  .addr(noise_reduction_addr),          // input [9:0]
  .clk(clk),            // input
  .rst(~rst_n),            // input
  .rd_data(noise_reduction_rd_data)     // output [45:0]
);

endmodule 