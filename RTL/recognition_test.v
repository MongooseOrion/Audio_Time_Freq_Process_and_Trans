module recognition_test 
#(
    parameter VQLBG_NUMBER   = 'd3,  //2的三次方，8个码本
    parameter MFCC_NUMBER = 'd31,  //表示一列码本有31
    parameter SPEAKER_NUMBER = 'd4  //表示有四个人的码本
    
)
(
    input             clk,
    input             rst_n,
    input [7:0]       rs232_rx_data,
    input             mfcc_extraction_end,
    input  [8:0]      mfcc_data,
    output [13:0]     mfcc_addr,
    input  [8:0]      vqlbg_data,
    output reg[10:0]  vplbg_addr,
    output  reg[2:0]  recognition_result ,
    output  reg       recognition_result_flag ,
    input   [8:0]     mfcc_number 
);
    
reg          cfg_valid_disteu;
reg          cfg_last_disteu;
reg  [8:0]   cfg_data_disteu;
wire          o_ready_disteu;
wire          o_valid_disteu/*synthesis PAP_MARK_DEBUG="1"*/;
wire [31:0]   o_data_disteu/*synthesis PAP_MARK_DEBUG="1"*/;
wire[29:0]    o_data_disteu1/*synthesis PAP_MARK_DEBUG="1"*/;
reg [31:0]    o_data_disteu_reg/*synthesis PAP_MARK_DEBUG="1"*/;
wire          done/*synthesis PAP_MARK_DEBUG="1"*/;
reg  [2:0]    cnt1;
reg  [2:0]    cnt2;
reg [8:0]     MFCC_FRAME_NUMBER/*synthesis PAP_MARK_DEBUG="1"*/;
wire [10:0]   vplbg_addr1;

reg [10:0] vqlbg_addr_bias [0:3];
initial begin
    vqlbg_addr_bias[0] = MFCC_NUMBER * (0 << 4);
    vqlbg_addr_bias[1] = MFCC_NUMBER * (1 << 4);
    vqlbg_addr_bias[2] = MFCC_NUMBER * (2 << 4);
    vqlbg_addr_bias[3] = MFCC_NUMBER * (3 << 4);
end

parameter INIT           = 5'b00001;
parameter CFG_DISTEU     = 5'b00010;
parameter DISTEU_COMPUTE = 5'b00100;
parameter MEAN_RESULT    = 5'b01000;
parameter RESULT_OUTPUT  = 5'b10000;


//保存mfcc的帧数
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        MFCC_FRAME_NUMBER <= 'd0;
    end
    else if (rs232_rx_data[7:3] == 5'b01011 && mfcc_extraction_end == 1'b1) begin
        MFCC_FRAME_NUMBER <= mfcc_number - 1'b1;  
    end
end

reg  [4:0] state/*synthesis PAP_MARK_DEBUG="1"*/;
//状态机跳转
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= INIT;
    end
    else begin
        case (state)
            INIT: begin
                if (mfcc_extraction_end == 1'b1 && rs232_rx_data[7:3]== 5'b01011) begin
                    state <= CFG_DISTEU;
                end
            end
            CFG_DISTEU: begin
                if (cfg_last_disteu == 1'b1) begin
                    state <= DISTEU_COMPUTE ;
                end
            end
            DISTEU_COMPUTE: begin
                if (o_valid_disteu == 1'b1) begin
                    state <= MEAN_RESULT ;
                end
            end
            MEAN_RESULT: begin
                if (cnt1 == SPEAKER_NUMBER - 1'b1 && ~done == 1'b1) begin
                    state <= RESULT_OUTPUT ;
                end
                else if (~done == 1'b1) begin
                    state <= CFG_DISTEU ;
                end
            end
            RESULT_OUTPUT: begin
                if (cnt2 == 'd3) begin
                    state <= INIT;
                end
            end
        endcase
    end
end

//内部信号
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cfg_valid_disteu <= 1'b0;
        cfg_last_disteu <= 1'b0;
        cfg_data_disteu <= 'd0;
        cnt1 <= 'd0;
        recognition_result <= 'd0;
        o_data_disteu_reg <= 'd0;
        cnt2 <= 'd0;
        recognition_result_flag <= 'd0;
    end
    else begin
        case (state)
            INIT: begin
                cfg_valid_disteu <= 1'b0;
                cfg_last_disteu <= 1'b0;
                cfg_data_disteu <= 'd0;
                cnt1 <= 'd0;
                recognition_result <= 'd0;
                o_data_disteu_reg <= 'd0;
                cnt2 <= 'd0;
                recognition_result_flag <= 'd0;
            end
            CFG_DISTEU: begin
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
                    cfg_data_disteu <= cfg_data_disteu + 1'b1;
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
            MEAN_RESULT: begin
                if (~done == 1'b1) begin
                    cnt1 <= cnt1 + 1'b1;
                    cfg_data_disteu <= 'd0;
                    if (cnt1 == 'd0) begin   //表示第一个说话人码本的结果
                        o_data_disteu_reg <= o_data_disteu;
                        recognition_result <= cnt1;
                    end
                    else if (o_data_disteu_reg > o_data_disteu) begin
                        recognition_result <= cnt1;
                        o_data_disteu_reg <= o_data_disteu;
                    end
                end
            end
            RESULT_OUTPUT: begin
                if (o_data_disteu_reg >= 'd22200) begin  //表示无结果
                    recognition_result <= {3{1'b1}};
                end
                else begin
                    recognition_result <= recognition_result;
                end
                if (cnt2 >= 'd1) begin
                    recognition_result_flag <= 'd0;  //拉高一个时钟周期
                end
                else begin
                    recognition_result_flag <= 1'b1;
                end
                cnt2 <= cnt2 + 1'b1;
            end

        endcase
    end
end


always @(*) begin
    if (~rst_n) begin
        vplbg_addr = 'd0;
    end
    else if (rs232_rx_data[7:3] == 5'b01011) begin
        vplbg_addr = vplbg_addr1 +  vqlbg_addr_bias[cnt1[1:0]];   
    end
end

disteu disteu_inst (
    .clk            (clk),
    .rst_n          (rst_n),
    .rd_data_d      (mfcc_data),
    .rd_addr_d      (mfcc_addr),        //待计算的ram
    .rd_data_r      (vqlbg_data),  //待计算的ram,如z = disteu(d, r);   表示r的数据
    .rd_addr_r      (vplbg_addr1),         //
    .cfg_valid      (cfg_valid_disteu),
    .cfg_data       (cfg_data_disteu),
    .cfg_last       (cfg_last_disteu),
    .cfg_mode_data  (6'b101111),
    .o_ready        (o_ready_disteu),
    .o_valid        (o_valid_disteu),
    .o_data         (o_data_disteu1)
);

divider divider_inst (
    .clk(clk),
    .rst(rst_n),
    .start(o_valid_disteu),
    .dividend({2'b00,o_data_disteu1}),
    .divisor({23'd0,MFCC_FRAME_NUMBER}),
    .quotient(o_data_disteu),
    .remainder(),
    .busy(done)
);


endmodule