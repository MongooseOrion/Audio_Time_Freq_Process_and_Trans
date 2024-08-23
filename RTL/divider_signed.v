`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/25 10:49:15
// Design Name: 
// Module Name: DIV
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module divider_signed(
input [31:0] dividend,
input [31:0] divisor,
input start,
input clock,
input reset,
output [31:0] q,
output [31:0] r, 
output reg busy,
output reg done
);
reg [4:0] count;
reg [31:0] reg_q;
reg [31:0] reg_r;
reg [31:0] reg_b;
reg busy2,r_sign;
reg flag1,flag2;
wire ready;
wire [32:0] add_sub;
wire [31:0] r_temp;
wire [31:0] q_temp;
assign ready=~busy&busy2;
assign add_sub=r_sign?({reg_r,q_temp[31]}+{1'b0,reg_b}):({reg_r,q_temp[31]}-{1'b0,reg_b});
assign q_temp=reg_q;
assign q=flag1?(~q_temp+1):q_temp;
assign r_temp=r_sign?reg_r+reg_b:reg_r;
assign r=flag2?(~r_temp+1):r_temp;
always @ (posedge clock or negedge reset)
begin
   if(reset==0) 
   begin
      count<=5'b0;
      busy<=1'b0;
      done <= 1'b0;
      busy2<=1'b0;
   end
   else
   begin
      busy2<=busy;
      if(start)
      begin
         reg_r<=32'b0;
         count<=5'b0;
         r_sign<=1'b0;
         busy<=1'b1;
         flag1<=dividend[31]^divisor[31];
         flag2<=dividend[31];
         reg_q<=dividend[31]?~(dividend-1):dividend;
         reg_b<=divisor[31]?~(divisor-1):divisor;
         done <= 1'b0;
      end
      else if(busy)
      begin
         reg_q<={reg_q[30:0],~add_sub[32]};
         reg_r<=add_sub[31:0];
         r_sign<=add_sub[32];
         count<=count+5'b1;
            if(count==5'b11111) begin
             busy<=0;
             done <= 1'b1;
            end
      end
      else done <=1'b0;
   end
end
endmodule
