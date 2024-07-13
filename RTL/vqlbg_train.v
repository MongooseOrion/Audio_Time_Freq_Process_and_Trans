module vqlbg_train 
#(
    parameter MFCC_FRAME_NUMBER = 'd200, //这个是总共的mfcc特征帧数量
    parameter VQLBG_NUMBER = 'd3,  //2的三次方，8个码本,目前只支持8个码本最多，因为码本存储空间ram的限制，如要更大，需修改vqlbg_addr_bias
    parameter MFCC_NUMBER = 'd31   //这个是一帧mfcc有多少个数值
    
)
(
    input              clk,
    input              rst_n,
    input [7:0]        rs232_rx_data,
    input              mfcc_extraction_end,
    output reg[12:0]   mfcc_addr,
    input  [8:0]       mfcc_data,
    input  [10:0]      vqlbg_addr,
    output [8:0]       vqlbg_rd_data,
    output  reg        train_down/*synthesis PAP_MARK_DEBUG="1"*/
);

parameter     division_contant = 7'd3;  // 相当于 3/128,分裂偏差

reg           cfg_last_disteu;
reg           cfg_last_mean ;

wire[12:0]    mean_mfcc_addr;
reg           cfg_valid_mean;
reg [8:0]     cfg_data_mean;
wire          o_ready_mean;
wire          o_valid_mean;
wire[8:0]     o_data_mean;

wire[12:0]    disteu_mfcc_addr;
wire [8:0]     disteu_rd_addr;
reg           cfg_valid_disteu/*synthesis PAP_MARK_DEBUG="1"*/;
reg [5:0]     cfg_mode_data_disteu/*synthesis PAP_MARK_DEBUG="1"*/;
reg [8:0]     cfg_data_disteu;
wire          o_ready_disteu;
wire          o_valid_disteu/*synthesis PAP_MARK_DEBUG="1"*/;
wire[29:0]    o_data_disteu;
reg [32:0]    sum_disteu_data/*synthesis PAP_MARK_DEBUG="1"*/;
reg [32:0]    sum_disteu_data_reg/*synthesis PAP_MARK_DEBUG="1"*/;


reg  signed[8:0]          vqlbg_rd_data_reg;
wire [15:0]               p;
wire [13:0]               p1;
wire [39:0]               p2;
wire signed [8:0]         p_1;
reg signed [8:0]          vqlbg_division1;
reg signed [8:0]          vqlbg_division2;
reg  [8:0]          vqlbg_wr_data;
reg  [10:0]         vqlbg_wr_addr;
reg  [10:0]         vqlbg_wr_addr1;
reg  [10:0]         vqlbg_rd_addr;
reg  [10:0]         vqlbg_rd_addr1;
reg                 vqlbg_wr_en;



reg [2:0]   cnt2/*synthesis PAP_MARK_DEBUG="1"*/;
reg [2:0]   cnt3/*synthesis PAP_MARK_DEBUG="1"*/;
reg [3:0]   cnt1/*synthesis PAP_MARK_DEBUG="1"*/;
reg [3:0]   cnt4/*synthesis PAP_MARK_DEBUG="1"*/;
reg   o_ready_mean_reg;
reg   o_ready_mean_negedge;
reg   o_valid_mean_reg;
reg   o_valid_mean_negedge/*synthesis PAP_MARK_DEBUG="1"*/;
reg   flag1;
reg   flag2;
reg     o_ready_disteu_reg;
reg     o_ready_disteu_negedge;
reg     o_valid_disteu_reg;
reg     o_valid_disteu_negedge/*synthesis PAP_MARK_DEBUG="1"*/;    
reg     o_valid_disteu_negedge_reg;    


wire [3:0]  disteu_mode1_rd_data;


reg [8:0] disteu_mode1_wr_addr;
wire       disteu_mode1_wr_en;
reg [8:0] disteu_mode1_rd_addr;

wire [8:0]  disteu_cfg_wr_data;
wire [8:0]  disteu_cfg_rd_data;

reg [8:0] disteu_cfg_wr_addr;
wire       disteu_cfg_wr_en;
reg [8:0] disteu_cfg_rd_addr;

reg [9:0]    state/*synthesis PAP_MARK_DEBUG="1"*/;
reg [7:0]     cruent_vqlbg_number_addr [0:3];
initial begin
    cruent_vqlbg_number_addr[0] = MFCC_NUMBER * 1;
    cruent_vqlbg_number_addr[1] = MFCC_NUMBER * 2;
    cruent_vqlbg_number_addr[2] = MFCC_NUMBER * 4;
    cruent_vqlbg_number_addr[3] = MFCC_NUMBER * 8;
end

reg [3:0]     cruent_vqlbg_number [0:3];
initial begin
    cruent_vqlbg_number[0] = 4'd1;
    cruent_vqlbg_number[1] = 4'd3;
    cruent_vqlbg_number[2] = 4'd7;
    cruent_vqlbg_number[3] = 4'd15;
end

reg [9:0]   vqlbg_addr_bias [0:3];
initial begin
    vqlbg_addr_bias[0] = 10'd0;
    vqlbg_addr_bias[1] = 10'd320;
    vqlbg_addr_bias[2] = 10'd640;
    vqlbg_addr_bias[3] = 10'd960;
end
parameter  INIT             = 10'b0000000001;   //初始化
parameter  MFCC_MEAN_CFG    = 10'b0000000010;   //mean模块配置
parameter  MFCC_MEAN_START  = 10'b0000000100;   //求平均值生成第一列码本
parameter  VQLBG_DIVISION   = 10'b0000001000;   //分裂码本

parameter  DISTEU_CFG       = 10'b0000010000;  //
parameter  DISTEU_COMPUTE   = 10'b0000100000;   //
parameter  MEAN_INIT        = 10'b0001000000;   // 用来生成计算哪些列的平均值的信号
parameter  MEAN_CFG         = 10'b0010000000; 
parameter  MEAN_COMPUTE     = 10'b0100000000;   //
parameter  RESULT_JUDGMENT  = 10'b1000000000;   //

assign disteu_cfg_wr_en = (disteu_mode1_rd_addr >= 'd1 && disteu_mode1_rd_addr <= MFCC_FRAME_NUMBER && disteu_mode1_rd_data == cnt1) ? 1'b1: 1'b0;   //mean_init状态机相关
assign disteu_cfg_wr_data = disteu_mode1_rd_addr - 1'b1;
assign disteu_mode1_wr_en = (cfg_mode_data_disteu[5:4] == 2'b01) ? o_valid_disteu : 1'b0;
assign p_1 = p[15:7];
//跳转逻辑
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= INIT;
        cnt2 <= 'd0;
        train_down <= 'd0;
    end
    else begin
        case (state)
            INIT: begin
                train_down <= 'd0;
                cnt2 <= 'd0;
                if (rs232_rx_data[7:3] == 5'b01010 && mfcc_extraction_end == 1'b1) begin
                    state <= MFCC_MEAN_CFG;
                end
            end
            MFCC_MEAN_CFG: begin
                if (cfg_last_mean == 1'b1) begin
                    state <= MFCC_MEAN_START;
                end
            end
            MFCC_MEAN_START: begin
                if (o_valid_mean_negedge == 1'b1) begin
                    state <= VQLBG_DIVISION;
                end
            end
            VQLBG_DIVISION: begin
                if (cnt3 == 'd2) begin
                    state <= DISTEU_CFG;   //直接跳转到配置模式，因为第一次是对所有列求disteu
                end
            end
            DISTEU_CFG: begin
                if (cfg_last_disteu == 1'b1) begin
                    state <= DISTEU_COMPUTE ;
                end
            end
            DISTEU_COMPUTE: begin
                if (o_valid_disteu_negedge == 1'b1 && cnt1 == cruent_vqlbg_number[cnt2]) begin
                    state <=  RESULT_JUDGMENT;
                end
                else if (o_valid_disteu_negedge == 1'b1) begin
                    state <= MEAN_INIT ;
                end
            end
            MEAN_INIT: begin
                if ( disteu_mode1_rd_addr == (MFCC_FRAME_NUMBER + 'd3)) begin
                    if (disteu_cfg_wr_addr == 'd0 ) begin   //没有找到最近的列，在MEAN_COMPUTE状态机写0数据
                        state <= MEAN_COMPUTE; 
                    end
                    else begin
                        state <= MEAN_CFG;
                    end
                end
            end
            MEAN_CFG: begin
                if (cfg_last_mean == 1'b1) begin
                    state <= MEAN_COMPUTE;
                end
            end
            MEAN_COMPUTE: begin
                if (disteu_cfg_wr_addr == 'd0 && cnt1 == cruent_vqlbg_number[cnt2] && vqlbg_wr_addr == (p1[8:0] + MFCC_NUMBER - 1'b1)) begin
                    state <=  RESULT_JUDGMENT;
                end
                else if (disteu_cfg_wr_addr == 'd0) begin
                    if (vqlbg_wr_addr == (p1[8:0] + MFCC_NUMBER - 1'b1)) begin
                        state <= MEAN_INIT;
                    end
                end
                else if (o_valid_mean_negedge == 1'b1) begin
                    state <= DISTEU_CFG;
                end
            end
            RESULT_JUDGMENT: begin
                if (flag2 == 1'b0) begin
                    state <= DISTEU_CFG;    //第一次计算到这里，至少还要再计算一次相对失真
                end
                else if ((sum_disteu_data + p2[39:7]) > sum_disteu_data_reg) begin
                // else if (cnt4 == 'd7) begin
                    if (cnt2 == VQLBG_NUMBER - 1'b1) begin
                        state <= INIT;
                        train_down <= 1'b1;
                    end
                    else begin
                        state <= VQLBG_DIVISION;
                        cnt2 <= cnt2 + 1'b1; 
                    end

                end
                else begin
                    state <= DISTEU_CFG;

                end
            end

        endcase
    end
end

//状态机内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cfg_valid_mean <= 'd0;
        cfg_data_mean <= 'd0;
        vqlbg_wr_addr <= 'd0;
        vqlbg_wr_en <= 'd0;
        vqlbg_wr_data <= 'd0;
        vqlbg_wr_addr <= 'd0;
        vqlbg_rd_addr1 <= 'd0;
        flag1 <= 'd0;
        cfg_mode_data_disteu <= 'd0;
        disteu_mode1_rd_addr <= 'd0;
        cnt1 <= 'd0;
        sum_disteu_data <= 'd0;
        cfg_valid_disteu <= 'd0;
        flag2 <= 'd0;
        cfg_data_disteu <= 'd0;
        sum_disteu_data_reg <= 'd0;
        cnt3 <= 'd0;
        disteu_cfg_wr_addr <= 'd0;
        disteu_cfg_rd_addr <= 'd0;
        cfg_last_disteu <= 'd0;
        cfg_last_mean <= 'd0;
        cnt4 <= 'd0;
    end
    else begin
        case (state)
            INIT: begin
                cfg_valid_mean <= 'd0;
                cfg_data_mean <= 'd0;
                vqlbg_wr_addr <= 'd0;
                vqlbg_wr_en <= 'd0;
                vqlbg_wr_data <= 'd0;
                vqlbg_wr_addr <= 'd0;
                vqlbg_rd_addr1 <= 'd0;
                flag1 <= 'd0;
                cfg_mode_data_disteu <= 'd0;
                disteu_mode1_rd_addr <= 'd0;
                cnt1 <= 'd0;
                sum_disteu_data <= 'd0;
                flag2 <= 'd0;
                cfg_valid_disteu <= 'd0;
                cfg_data_disteu <= 'd0;
                sum_disteu_data_reg <= 'd0;
                cnt3 <= 'd0;
                disteu_cfg_wr_addr <= 'd0;
                disteu_cfg_rd_addr <= 'd0;
                cfg_last_disteu <= 'd0;
                cfg_last_mean <= 'd0;
                cnt4 <= 'd0;
            end
            MFCC_MEAN_CFG: begin
                if (o_ready_mean == 1'b1) begin
                    if (cfg_data_mean == MFCC_FRAME_NUMBER - 1'b1) begin  //cfg_data_mean是需要计算的列的个数计数信号
                        cfg_valid_mean <= 1'b0;             
                    end
                    else begin
                        cfg_valid_mean <= 1'b1;               
                    end
                end
                else begin
                    cfg_valid_mean <= 1'b0; 
                end
                
                if (cfg_data_mean == MFCC_FRAME_NUMBER - 'd2) begin   //最后一位数据拉高
                    cfg_last_mean <= 1'b1;
                end
                else begin
                    cfg_last_mean <= 1'b0;
                end

                if (cfg_valid_mean == 1'b1) begin
                    cfg_data_mean <= cfg_data_mean + 1'b1;
                end
                else begin
                    cfg_data_mean <= 'd0;
                end
            end
            MFCC_MEAN_START: begin//我在mean模块，写的数据输出逻辑是连续输出的  
                vqlbg_wr_en <= o_valid_mean;                     //把结果写进vqlbgram的第一列
                vqlbg_wr_data <= o_data_mean ;

                if (vqlbg_wr_en == 1'b1) begin
                    vqlbg_wr_addr <= vqlbg_wr_addr + 1'b1;
                end
                else begin
                    vqlbg_wr_addr <= 'd0;
                end
            end
            VQLBG_DIVISION: begin                         //码本分裂，通用版
                flag2 <= 'd0;
                cnt4 <= 'd0;
                if (cnt3 == 'd0) begin
                    vqlbg_wr_addr <= cruent_vqlbg_number_addr[cnt2] +  vqlbg_rd_addr1 - 'd3;  //分裂时，先写进分裂后半部分码本，
                    vqlbg_wr_data <= vqlbg_division2;
                end
                else begin
                    vqlbg_wr_addr <= vqlbg_rd_addr1 - 'd3;
                    vqlbg_wr_data <= vqlbg_division1;
                end
                


                if (vqlbg_rd_addr1 == (cruent_vqlbg_number_addr[cnt2] + 'd5) ) begin  
                    vqlbg_rd_addr1 <= 'd0;         
                    cnt3 <= cnt3 + 1'b1;          //cnt3决定写进vqlbg ram 里面的是division1,还是division2，也作为状态机跳转的逻辑
                end
                else begin
                    vqlbg_rd_addr1 <= vqlbg_rd_addr1 + 1'b1;
                end
                
                if ((vqlbg_rd_addr1 >= 'd3) && (vqlbg_rd_addr1 <= (cruent_vqlbg_number_addr[cnt2] + 'd2)) ) begin
                    vqlbg_wr_en <= 1'b1;
                end
                else begin
                    vqlbg_wr_en <= 1'b0;
                end

            end

            DISTEU_CFG: begin
                if (flag1 == 1'b0) begin   // 表示对当前的码本进行disteu进行计算
                    cfg_mode_data_disteu <={2'b01,cruent_vqlbg_number[cnt2]};
                    if (o_ready_disteu == 1'b1) begin
                        if (cfg_data_disteu == MFCC_FRAME_NUMBER - 1'b1) begin  //cfg_data_disteu是需要计算的列的个数计数信号
                            cfg_valid_disteu <= 1'b0;             
                        end
                        else begin
                            cfg_valid_disteu <= 1'b1;               
                        end
                    end
                    else begin
                        cfg_valid_disteu <= 1'b0; 
                    end
    
                    if (cfg_valid_disteu == 1'b1) begin
                        cfg_data_disteu <= cfg_data_disteu + 1'b1;  //cfg要清零，当cfgdata为198时，会卡在下一个状态机
                    end
                    else begin
                        cfg_data_disteu <= 'd0;
                    end

                    if (cfg_data_disteu == MFCC_FRAME_NUMBER - 'd2) begin   //最后一位数据拉高
                        cfg_last_disteu <= 1'b1;
                    end
                    else begin
                        cfg_last_disteu <= 1'b0;
                    end
                end

                else begin
                    cfg_mode_data_disteu <={2'b00,cnt1};
                    disteu_cfg_rd_addr <= disteu_cfg_rd_addr + 1'b1;
                    cfg_data_disteu <= disteu_cfg_rd_data;
                    if (disteu_cfg_rd_addr == 'd1) begin
                        cfg_valid_disteu <= 1'b1;
                    end
                    else if (disteu_cfg_rd_addr == disteu_cfg_wr_addr + 1'b1) begin
                        cfg_valid_disteu <= 1'b0;
                    end

                    if (disteu_cfg_rd_addr == disteu_cfg_wr_addr) begin   //最后一位数据拉高
                        cfg_last_disteu <= 1'b1;
                    end
                    else begin
                        cfg_last_disteu <= 1'b0;
                    end
                end
            end

            DISTEU_COMPUTE: begin   //模式1的话这里不用写逻辑，因为再外面的always生成了信号
                disteu_mode1_rd_addr <= 'd0;  //清零
                disteu_cfg_wr_addr <= 'd0;
                disteu_cfg_rd_addr <= 'd0;
                if (o_valid_disteu_negedge == 1'b1 && cfg_mode_data_disteu[5:4] == 2'b00) begin   //模式0才计数相加一次
                    cnt1 <= cnt1 + 1'b1;   //cnt1 用来指定disteu 模式0 用来计算码本的第几列
                end
                else if (cfg_mode_data_disteu[5:4] == 2'b00) begin   //有效值输出了，加一次，不和上面合并写，是因为合并写后，对于后面的判断条件时序上来不及
                    if (o_valid_disteu == 1'b1) begin
                        sum_disteu_data <= o_data_disteu + sum_disteu_data;
                    end
                end
                

            end

            MEAN_INIT: begin            //这个状态机相当matlab中的 [m,ind] = min(z, [], 2);,这里有可能 ind 为0；，所以要加逻辑
                flag1 <= 1'b1;
                disteu_mode1_rd_addr <= disteu_mode1_rd_addr + 1'b1;
                if (disteu_cfg_wr_en == 1'b1) begin
                    disteu_cfg_wr_addr <= disteu_cfg_wr_addr + 1'b1;    //这里等会要加清零信号
                end
            end

            MEAN_CFG: begin
                disteu_cfg_rd_addr <= disteu_cfg_rd_addr + 1'b1;
                cfg_data_mean <= disteu_cfg_rd_data;
                if (disteu_cfg_rd_addr == 'd1) begin
                    cfg_valid_mean <= 1'b1;
                end
                else if (disteu_cfg_rd_addr == disteu_cfg_wr_addr + 1'b1) begin
                    cfg_valid_mean <= 1'b0;
                end

                if (disteu_cfg_rd_addr == disteu_cfg_wr_addr) begin   //最后一位数据拉高
                    cfg_last_mean <= 1'b1;
                end
                else begin
                    cfg_last_mean <= 1'b0;
                end

                vqlbg_wr_addr <= p1[8:0];   //第几列的起始地址
            end
             
            MEAN_COMPUTE: begin
                if (disteu_cfg_wr_addr == 'd0) begin
                    vqlbg_wr_data <= 'd0;
                    if (vqlbg_wr_addr == p1[8:0] + MFCC_NUMBER - 1'b1) begin
                        vqlbg_wr_en <= 1'b0;
                        cnt1 <= cnt1 + 1'b1;
                        disteu_cfg_rd_addr <= 'd0;
                    end
                    else begin
                        vqlbg_wr_en <= 1'b1;
                    end
                end
                else begin
                    vqlbg_wr_en <= o_valid_mean;                     
                    vqlbg_wr_data <= o_data_mean ;
                    disteu_cfg_rd_addr <= 'd0;   //清零，DISTEU_CFG 状态机要用
                end
                
                if (vqlbg_wr_en == 1'b1) begin
                    vqlbg_wr_addr <= vqlbg_wr_addr + 1'b1;
                end
                else begin
                    vqlbg_wr_addr <= vqlbg_wr_addr;
                end
            end

            RESULT_JUDGMENT: begin
                disteu_cfg_rd_addr <= 'd0;
                cnt3 <= 'd0;
                flag1 <= 'd0;
                cnt1 <= 'd0;
                flag2 <= 1'b1;
                cnt4 <= cnt4 + 1'b1;
                sum_disteu_data_reg <= sum_disteu_data;
                sum_disteu_data <= 'd0;
                vqlbg_rd_addr1 <= 'd0;
                cfg_data_disteu <= 'd0;
            end

        endcase
    end
end





//边沿检测
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        o_ready_mean_reg <= 1'b0;
        o_ready_mean_negedge <= 1'b0;
        vqlbg_rd_data_reg <= 'd0;
        o_valid_mean_reg <= 'd0;
        o_valid_mean_negedge <= 'd0;
        vqlbg_division1 <= 'd0;
        vqlbg_division2 <= 'd0;
        o_ready_disteu_reg <= 'd0;
        o_ready_disteu_negedge <= 'd0;
        o_valid_disteu_reg <= 'd0;
        o_valid_disteu_negedge <= 'd0;
        o_valid_disteu_negedge_reg <= 'd0;

    end
    else begin
        o_ready_mean_reg <= o_ready_mean;
        o_ready_mean_negedge <= (o_ready_mean_reg & (~o_ready_mean));
        o_valid_mean_reg <= o_valid_mean;
        o_valid_mean_negedge <= (o_valid_mean_reg & (~o_valid_mean));

        o_ready_disteu_reg <= o_ready_disteu;
        o_ready_disteu_negedge <= (o_ready_disteu_reg & (~o_ready_disteu));
        o_valid_disteu_reg <= o_valid_disteu;
        o_valid_disteu_negedge <= (o_valid_disteu_reg & (~o_valid_disteu));
        o_valid_disteu_negedge_reg <= o_valid_disteu_negedge;

        vqlbg_rd_data_reg <= vqlbg_rd_data;
        vqlbg_division1 <= vqlbg_rd_data_reg + p_1;
        vqlbg_division2 <= vqlbg_rd_data_reg - p_1;
        
    end
end

always @(*) begin
    if (~rst_n) begin
        vqlbg_rd_addr <= 'd0;
    end
    else if (rs232_rx_data[7:3] == 5'b01011) begin
        vqlbg_rd_addr <= vqlbg_addr ;   //这个是recongnition_test 输入的，那边已经有偏移地址，不用加
    end
    else if (state == VQLBG_DIVISION) begin
        vqlbg_rd_addr <= vqlbg_rd_addr1 + vqlbg_addr_bias[rs232_rx_data[1:0]];
    end
    else begin
        vqlbg_rd_addr <= disteu_rd_addr + vqlbg_addr_bias[rs232_rx_data[1:0]];
    end
end

always @(*) begin
    if (~rst_n) begin
        vqlbg_wr_addr1 <= 'd0;
    end
    else if (rs232_rx_data[7:3] == 5'b01010) begin
        vqlbg_wr_addr1 <= vqlbg_wr_addr +  vqlbg_addr_bias[rs232_rx_data[1:0]];  
    end
end

always @(*) begin
    if (~rst_n) begin
        mfcc_addr <= 'd0;
    end
    else if (state == DISTEU_COMPUTE || state == DISTEU_CFG) begin
        mfcc_addr <= disteu_mfcc_addr;
    end
    else begin
        mfcc_addr <= mean_mfcc_addr;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        disteu_mode1_wr_addr <= 'd0;
    end
    else if (o_valid_disteu == 1'b1) begin
        disteu_mode1_wr_addr <= disteu_mode1_wr_addr + 1'b1;
    end
    else begin
        disteu_mode1_wr_addr <= 'd0;
    end
end

mean mean_inst (
    .clk        (clk) ,
    .rst_n      (rst_n) ,
    .data_in    (mfcc_data) ,
    .addr       (mean_mfcc_addr)  ,        //待计算的ram
    .cfg_valid  (cfg_valid_mean) ,
    .cfg_data   (cfg_data_mean)     ,
    .cfg_last   (cfg_last_mean),
    .o_ready    (o_ready_mean)  ,
    .o_valid    (o_valid_mean)  ,
    .o_data     (o_data_mean) 
);


disteu disteu_inst (
    .clk            (clk),
    .rst_n          (rst_n),
    .rd_data_d      (mfcc_data),
    .rd_addr_d      (disteu_mfcc_addr),        //待计算的ram
    .rd_data_r      (vqlbg_rd_data),  //待计算的ram,如z = disteu(d, r);   表示r的数据
    .rd_addr_r      (disteu_rd_addr),         //
    .cfg_valid      (cfg_valid_disteu),
    .cfg_data       (cfg_data_disteu),
    .cfg_last       (cfg_last_disteu),
    .cfg_mode_data  (cfg_mode_data_disteu),
    .o_ready        (o_ready_disteu),
    .o_valid        (o_valid_disteu),
    .o_data         (o_data_disteu)
);


length_2048_width_9_ram vqlbg_ram (       //存储码本
  .wr_data(vqlbg_wr_data),    // input [8:0]
  .wr_addr(vqlbg_wr_addr1),    // input [10:0]
  .wr_en  (vqlbg_wr_en  ),        // input
  .wr_clk (clk          ),      // input
  .wr_rst (~rst_n       ),      // input
  .rd_addr(vqlbg_rd_addr),    // input [10:0]  //后期要加上偏移地址
  .rd_data(vqlbg_rd_data),    // output [8:0]
  .rd_clk (clk          ),      // input
  .rd_rst (~rst_n       )       // input
);



length_512_width_4_ram length_512_width_4_ram_inst1 (   //存储disteu mode1模式的输出
  .wr_data(o_data_disteu[3:0]),    // input [3:0]
  .wr_addr(disteu_mode1_wr_addr),    // input [8:0]
  .wr_en(disteu_mode1_wr_en),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(disteu_mode1_rd_addr),    // input [8:0]
  .rd_data(disteu_mode1_rd_data),    // output [3:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);

length_512_width_9_ram length_512_width_4_ram_inst2 (   //存储cfg数据的输入
  .wr_data(disteu_cfg_wr_data),    // input [8:0]
  .wr_addr(disteu_cfg_wr_addr),    // input [8:0]
  .wr_en(disteu_cfg_wr_en),        // input
  .wr_clk(clk),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(disteu_cfg_rd_addr),    // input [8:0]
  .rd_data(disteu_cfg_rd_data),    // output [8:0]
  .rd_clk(clk),      // input
  .rd_rst(~rst_n)       // input
);


simple_multi_9x7 simple_multi_9x7_inst (
  .a(vqlbg_rd_data),        // input [8:0]
  .b(division_contant),        // input [6:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p)         // output [15:0]
);

simple_multi_5x9_unsigned simple_multi_5x9_unsigned_inst1 (  //用来计算每列码本的起始地址
  .a(MFCC_NUMBER),        // input [4:0]
  .b({'d0,cnt1[3:0]}),        // input [8:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p1)         // output [13:0]
);

simple_multi_33x7_unsigned the_instance_name (
  .a(sum_disteu_data),        // input [32:0]
  .b(division_contant),        // input [6:0]
  .clk(clk),    // input
  .rst(~rst_n),    // input
  .ce(1'b1),      // input
  .p(p2)         // output [39:0]
);




endmodule