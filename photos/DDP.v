`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 07:11:27 PM
// Design Name: 
// Module Name: DDP
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


module DDP #(
    parameter DW = 15, // 32k depth -> 15 bits
    parameter H_LEN = 200,
    parameter V_LEN = 150
)(
    input wire pclk,
    input wire rstn,
    input wire hen,
    input wire ven,
    input wire test_mode, // 1 for white screen (Task 3-1), 0 for VRAM image (Task 3-2)
    input wire [11:0] rdata, // 12-bit RGB from VRAM
    output wire [DW-1:0] raddr,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue
);

    reg [11:0] x_cnt;
    reg [11:0] y_cnt;
    reg hen_d;
    
    // Edge detection for hen to increment vertical counter
    always @(posedge pclk or negedge rstn) begin
        if (!rstn) begin
            hen_d <= 1'b0;
        end else begin
            hen_d <= hen;
        end
    end
    
    wire hen_fall = hen_d & ~hen;

    // Horizontal Counter (Pixel coordinate on screen)
    always @(posedge pclk or negedge rstn) begin
        if (!rstn) begin
            x_cnt <= 0;
        end else begin
            if (!hen) begin
                x_cnt <= 0;
            end else begin
                x_cnt <= x_cnt + 1;
            end
        end
    end

    // Vertical Counter (Line coordinate on screen)
    always @(posedge pclk or negedge rstn) begin
        if (!rstn) begin
            y_cnt <= 0;
        end else begin
            if (!ven) begin
                y_cnt <= 0;
            end else if (hen_fall) begin
                y_cnt <= y_cnt + 1;
            end
        end
    end

    // Coordinate scaling (4x4 pixels -> 1 VRAM pixel)
    wire [11:0] x_idx = x_cnt[11:2]; // Divide by 4
    wire [11:0] y_idx = y_cnt[11:2]; // Divide by 4

    // Address generation
    // Address = y * Width + x
    // Ensure we don't read out of bounds if screen is larger than scaled VRAM
    wire [DW-1:0] addr_calc = y_idx * H_LEN + x_idx;
    assign raddr = addr_calc;

    // Output Logic
    // Delay enable signals to match Block RAM latency (usually 1 or 2 cycles, assuming 1 here)
    reg hen_out_d, ven_out_d;
    always @(posedge pclk) begin
        hen_out_d <= hen;
        ven_out_d <= ven;
    end

    assign {red, green, blue} = (hen_out_d && ven_out_d) ? (test_mode ? 12'hFFF : rdata) : 12'h000;

endmodule

