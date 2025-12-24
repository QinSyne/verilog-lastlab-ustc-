`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 07:11:50 PM
// Design Name: 
// Module Name: DST
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

module DST #(
    parameter H_SW = 120,
    parameter H_BP = 64,
    parameter H_ACT = 800,
    parameter H_FP = 56,
    parameter V_SW = 6,
    parameter V_BP = 23,
    parameter V_ACT = 600,
    parameter V_FP = 37
)(
    input wire pclk,
    input wire rstn,
    output wire hs,
    output wire vs,
    output wire hen,
    output wire ven
);

    localparam H_TOTAL = H_SW + H_BP + H_ACT + H_FP;
    localparam V_TOTAL = V_SW + V_BP + V_ACT + V_FP;

    wire [11:0] h_cnt;
    wire h_co;
    wire [11:0] v_cnt;
    wire v_co;

    // Horizontal Counter
    CntS #(
        .WIDTH(12),
        .RST_VLU(0)
    ) cnt_h_inst (
        .clk(pclk),
        .rstn(rstn),
        .d(H_TOTAL - 1),
        .ce(1'b1),
        .q(h_cnt),
        .co(h_co)
    );

    // Vertical Counter
    CntS #(
        .WIDTH(12),
        .RST_VLU(0)
    ) cnt_v_inst (
        .clk(pclk),
        .rstn(rstn),
        .d(V_TOTAL - 1),
        .ce(h_co), // Increment when horizontal counter wraps
        .q(v_cnt),
        .co(v_co)
    );

    // Generate Sync Signals (Active High as per tutorial implication, usually Low but let's stick to positive logic for pulses)
    // If the monitor expects negative sync, we might need to invert these at the top level.
    // Standard 800x600@72Hz is +HSync +VSync.
    assign hs = (h_cnt < H_SW);
    assign vs = (v_cnt < V_SW);

    // Generate Enable Signals
    assign hen = (h_cnt >= (H_SW + H_BP)) && (h_cnt < (H_SW + H_BP + H_ACT));
    assign ven = (v_cnt >= (V_SW + V_BP)) && (v_cnt < (V_SW + V_BP + V_ACT));

endmodule

