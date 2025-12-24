`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 07:09:42 PM
// Design Name: 
// Module Name: CntS
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


module CntS #(
    parameter WIDTH = 16,
    parameter RST_VLU = 0
)(
    input wire clk,
    input wire rstn,      // Active low reset
    input wire [WIDTH-1:0] d, // Load value (max count)
    input wire ce,        // Count enable
    output reg [WIDTH-1:0] q, // Counter output
    output wire co        // Carry out
);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= RST_VLU;
        end else if (ce) begin
            if (q == d) begin
                q <= 0;
            end else begin
                q <= q + 1;
            end
        end
    end

    assign co = (q == d) && ce;

endmodule
