// ������̫������
module eth_trans (

    input                       sys_clk,                    // 50MHz
    input                       rst_n,
    input                       rst_n_test,
    output                      led,
    
    // �������������
    input [15:0]                ldata_in,
    input [15:0]                rdata_in,

    // RJ45 ����ʱ��
    output                      e_mdc,                      //MDIO��ʱ���źţ����ڶ�дPHY�ļĴ���
    inout                       e_mdio,                     //MDIO�������źţ����ڶ�дPHY�ļĴ���                         
    output [3:0]                rgmii_txd,                  //RGMII ��������
    output                      rgmii_txctl,                //RGMII ������Ч�ź�
    output                      rgmii_txc,                  //125Mhz ethernet rgmii tx clock
    input    [3:0]              rgmii_rxd,                  //RGMII ��������
    input                       rgmii_rxctl,                //RGMII ����������Ч�ź�
    input                       rgmii_rxc                   //125Mhz ethernet gmii rx clock    
);

wire   [ 7:0]   gmii_txd;
wire            gmii_tx_en;
wire            gmii_tx_er;
wire            gmii_tx_clk;
wire            gmii_crs;
wire            gmii_col;
wire   [ 7:0]   gmii_rxd;
wire            gmii_rx_dv;
wire            gmii_rx_er;
wire            gmii_rx_clk;
wire  [ 1:0]    speed_selection; // 1x gigabit, 01 100Mbps, 00 10mbps
wire            duplex_mode;     // 1 full, 0 half



//MDIO config
assign speed_selection = 2'b10;
assign duplex_mode = 1'b1;


util_gmii_to_rgmii util_gmii_to_rgmii_m0(
	.reset          (1'b0),
	
	.rgmii_td                   (rgmii_txd),
	.rgmii_tx_ctl               (rgmii_txctl),
	.rgmii_txc                  (rgmii_txc),
	.rgmii_rd                   (rgmii_rxd),
	.rgmii_rx_ctl               (rgmii_rxctl),
	.gmii_rx_clk                (gmii_rx_clk),
	.gmii_txd                   (gmii_txd),
	.gmii_tx_en                 (gmii_tx_en),
	.gmii_tx_er                 (1'b0),
	.gmii_tx_clk                (gmii_tx_clk),
	.gmii_crs                   (gmii_crs),
	.gmii_col                   (gmii_col),
	.gmii_rxd                   (gmii_rxd),
    .rgmii_rxc                  (rgmii_rxc),//add
	.gmii_rx_dv                 (gmii_rx_dv),
	.gmii_rx_er                 (gmii_rx_er),
	.speed_selection            (speed_selection),
	.duplex_mode                (duplex_mode),
    .led                        (led),
    .pll_phase_shft_lock        (),
    .clk                        (),
    .sys_clk                    (sys_clk)
	);


//////////////////// CMOS FIFO/////////////////// 
wire [10:0] fifo_data_count;
wire [7:0]  fifo_data;
wire        fifo_rd_en;

udp_tx_buffer udp_tx_fifo(
    .wr_clk             (sys_clk),
    .wr_rst             (!rst_n),
    .wr_en              (rst_n),
    .wr_data            (data),
    .wr_full            (),
    .wr_water_level     (),
    .almost_full        (),
    .rd_clk             (gmii_rx_clk),
    .rd_rst             (!rst),
    .rd_en              (fifo_rd_en),
    .rd_data            (fifo_data),
    .rd_empty           (),
    .rd_water_level     (fifo_data_count),
    .almost_empty       ()
);

mac_test mac_top (
 .gmii_tx_clk            (gmii_tx_clk        ),
 .gmii_rx_clk            (gmii_rx_clk        ) ,
 .rst_n                  (rst_n              ),
 
 .cmos_vsync              (cmos_vsync        ),
 .cmos_href               (cmos_href         ),
 .reg_conf_done           (reg_conf_done     ),
 .fifo_data               (fifo_data         ),         
 .fifo_data_count         (fifo_data_count   ),            
 .fifo_rd_en              (fifo_rd_en        ),    
 
 
 .udp_send_data_length   (16'd1024           ), 
 .gmii_rx_dv             (gmii_rx_dv         ),
 .gmii_rxd               (gmii_rxd           ),
 .gmii_tx_en             (gmii_tx_en         ),
 .gmii_txd               (gmii_txd           )
 
);	

endmodule