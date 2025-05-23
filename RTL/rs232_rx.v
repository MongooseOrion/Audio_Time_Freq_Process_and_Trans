module  rs232_rx
#(
    parameter   UART_BPS    =   'd9600      ,
    parameter   CLK_FREQ    =   'd50_000_000
)
(
    input   wire            sys_clk     ,
    input   wire            sys_rst_n   ,
    input   wire            rx          ,

    output  reg     [7:0]   rs232_rx_data     ,
    output  reg             rs232_rx_flag
);

parameter   BAUD_CNT_MAX    =   CLK_FREQ / UART_BPS;

reg             rx_reg1     ;
reg             rx_reg2     ;
reg             rx_reg3     ;
reg             start_flag  ;
reg             work_en     ;
reg     [15:0]  baud_cnt    ;
reg             bit_flag    ;
reg     [3:0]   bit_cnt     ;
reg     [7:0]   rx_data     ;
reg             rx_flag     ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_reg1 <=  1'b1;
    else
        rx_reg1 <=  rx;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_reg2 <=  1'b1;
    else
        rx_reg2 <=  rx_reg1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_reg3 <=  1'b1;
    else
        rx_reg3 <=  rx_reg2;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        start_flag  <=  1'b0;
    else    if((rx_reg3 == 1'b1) && (rx_reg2 == 1'b0) && (work_en == 1'b0))
        start_flag  <=  1'b1;
    else
        start_flag  <=  1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        work_en <=  1'b0;
    else    if(start_flag == 1'b1)
        work_en <=  1'b1;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        work_en <=  1'b0;
    else
        work_en <=  work_en;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        baud_cnt    <=  16'd0;
    else    if((baud_cnt == BAUD_CNT_MAX - 1) || (work_en == 1'b0))
        baud_cnt    <=  16'd0;
    else
        baud_cnt    <=  baud_cnt + 1'b1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bit_flag    <=  1'b0;
    else    if(baud_cnt == BAUD_CNT_MAX / 2 - 1)
        bit_flag    <=  1'b1;
    else
        bit_flag    <=  1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bit_cnt <=  4'd0;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        bit_cnt <=  4'd0;
    else    if(bit_flag == 1'b1)
        bit_cnt <=  bit_cnt + 1'b1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_data <=  8'b0;
    else    if((bit_cnt >= 4'd1) && (bit_cnt <= 4'd8) && (bit_flag == 1'b1))
        rx_data <=  {rx_reg3,rx_data[7:1]};

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_flag <=  1'b0;
    else    if((bit_cnt == 4'd8) && (bit_flag == 1'b1))
        rx_flag <=  1'b1;
    else
        rx_flag <=  1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rs232_rx_data <=  8'b0;
    else    if(rx_flag == 1'b1)
        rs232_rx_data <=  rx_data;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rs232_rx_flag <=  1'b0;
    else
        rs232_rx_flag <=  rx_flag;

endmodule