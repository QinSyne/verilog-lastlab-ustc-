`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 07:12:08 PM
// Design Name: 
// Module Name: PS
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

module PS #(
    parameter WIDTH = 1
)(
    input wire s,
    input wire clk,
    output wire p
);
    reg s_d;
    always @(posedge clk) begin
        s_d <= s;
    end
    assign p = s & ~s_d;
endmodule

