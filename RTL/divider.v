`timescale 1ns / 1ps
module divider(
    input [31:0] dividend,
    input [31:0] divisor,
    input start,
    input clk,
    input rst,
    output [31:0] quotient,
    output [31:0] remainder,
    output reg busy
);
    wire ready;
    reg [4:0] count;
    reg [31:0] reg_q;
    reg [31:0] reg_r;
    reg [31:0] reg_b;
    reg busy2, r_sign;

    assign ready = ~busy & busy2;
    wire [32:0] sub_add = r_sign ? ({reg_r, quotient[31]} + {1'b0, reg_b}) : ({reg_r, quotient[31]} - {1'b0, reg_b});
    assign remainder = r_sign ? reg_r + reg_b : reg_r;
    assign quotient = reg_q;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            count <= 5'b0;
            busy <= 0;
            busy2 <= 0;
        end else begin
            busy2 <= busy;
            if (start) begin
                reg_r <= 32'b0;
                r_sign <= 0;
                reg_q <= dividend;
                reg_b <= divisor;
                count <= 5'b0;
                busy <= 1'b1;
            end else if (busy) begin
                reg_r <= sub_add[31:0];
                r_sign <= sub_add[32];
                reg_q <= {reg_q[30:0], ~sub_add[32]};
                count <= count + 1;
                if (count == 5'b11111) busy <= 0;
            end
        end
    end
endmodule