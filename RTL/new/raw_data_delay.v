/* =======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: GBK
* ========================================================================
*/
// 由于 FIFO 是在下个时钟周期才执行指令，因此控制和数据信号需要延迟
//
module raw_data_delay (
  input                 sck,              //cmos pxiel clock
  input                 cmos_href,              //cmos hsync refrence
	input                 cmos_vsync,             //cmos vsync
	input     [7:0]       cmos_data,              //cmos data

  output                cmos_href_delay,              //cmos hsync refrence
	output                cmos_vsync_delay,             //cmos vsync
	output    [7:0]       cmos_data_delay               //cmos data
);

reg [2:0] cmos_href_buf ;
reg [2:0] cmos_vsync_buf ;
reg [7:0] cmos_data_d0 ;
reg [7:0] cmos_data_d1 ;
reg [7:0] cmos_data_d2 ;


always @(posedge sck) begin 
  cmos_href_buf <= {cmos_href_buf[1:0], cmos_href} ;
end

always @(posedge sck) begin 
  cmos_vsync_buf <= {cmos_vsync_buf[1:0], cmos_vsync} ;
end

always @(posedge sck)
begin 
  cmos_data_d0 <= cmos_data ;
  cmos_data_d1 <= cmos_data_d0 ;
  cmos_data_d2 <= cmos_data_d1 ;
end

assign cmos_href_delay = cmos_href_buf[2] ;
assign cmos_vsync_delay = cmos_vsync_buf[2] ;
assign cmos_data_delay = cmos_data_d2 ;



endmodule
