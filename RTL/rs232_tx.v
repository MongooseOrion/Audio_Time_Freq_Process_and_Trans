module  rs232_tx
#(
    parameter   UART_BPS    =   'd9600      ,
    parameter   CLK_FREQ    =   'd50_000_000
)
(
    input   wire            sys_clk     ,
    input   wire            sys_rst_n   ,
    input   wire    [7:0]   rs232_tx_data     ,
    input   wire            rs232_tx_flag     ,

    output  reg             tx
);            
parameter   BAUD_CNT_MAX    =   CLK_FREQ / UART_BPS;
reg     [7:0]   pi_date_reg;
reg             work_en     ;
reg     [15:0]  baud_cnt    ;
reg             bit_flag    ;
reg     [3:0]   bit_cnt     ;
//保存发送数据，避免传进来的数据发生变化导致数据传输错误
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pi_date_reg <=  8'b0;
    else    if(rs232_tx_flag == 1'b1)
        pi_date_reg <=  rs232_tx_data;
    else    
        pi_date_reg <= pi_date_reg;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        work_en <=  1'b0;
    else    if(rs232_tx_flag == 1'b1)
        work_en <=  1'b1;
    else    if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        work_en <=  1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        baud_cnt    <=  16'd0;
    else    if((work_en ==  1'b0) || (baud_cnt == BAUD_CNT_MAX - 1))
        baud_cnt    <=  16'd0;
    else    if(work_en ==  1'b1)
        baud_cnt    <=  baud_cnt + 1'b1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bit_flag    <=  1'b0;
    else    if(baud_cnt == 16'd1)
        bit_flag    <=  1'b1;
    else
        bit_flag    <=  1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bit_cnt <=  4'd0;
    else    if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        bit_cnt <=  4'd0;
    else    if((work_en ==  1'b1) && (bit_flag == 1'b1))
        bit_cnt <=  bit_cnt + 1'b1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        tx  <=  1'b1;
    else    if(bit_flag == 1'b1)
        case(bit_cnt)
            0:tx <=  1'b0;
            1:tx <=  pi_date_reg[0];
            2:tx <=  pi_date_reg[1];
            3:tx <=  pi_date_reg[2];
            4:tx <=  pi_date_reg[3];
            5:tx <=  pi_date_reg[4];
            6:tx <=  pi_date_reg[5];
            7:tx <=  pi_date_reg[6];
            8:tx <=  pi_date_reg[7];
            9:tx <=  1'b1;
            default:tx  <=  1'b1;
        endcase

endmodule