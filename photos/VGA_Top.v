module VGA_Top (
    input wire clk,       // 100MHz
    input wire rstn,      // Active low reset
    input wire [1:0] SW,  // SW[0]: Test Mode (White), SW[1]: Video Mode (Animation)
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire VGA_HS,
    output wire VGA_VS
);
    // Clock Divider 100MHz -> 50MHz
    reg pclk;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) pclk <= 0;
        else pclk <= ~pclk;
    end

    wire hs, vs, hen, ven;
    wire [14:0] base_raddr; // Address within a frame (0-29999)
    // We'll instantiate 14 separate VRAM IPs, each stores one full frame.
    // Each VRAM is read with the same `base_raddr`; the selected VRAM's output
    // is routed to the rest of the logic by a small mux below.
    wire [11:0] vram_dout [0:9]; // outputs from each VRAM instance
    wire [11:0] rdata; // selected VRAM data forwarded to DDP
    wire [3:0] r, g, b;

    // Frame Animation Logic (Task 3-3)
    reg [25:0] frame_timer;
    reg [3:0] frame_sel; // 4 bits for 10 frames (0-9)
    
    always @(posedge pclk or negedge rstn) begin
        if (!rstn) begin
            frame_timer <= 0;
            frame_sel <= 0;
        end else begin
            if (SW[1]) begin // Video Mode
                if (frame_timer == 25000000) begin // ~0.5 sec per frame (50MHz clock)
                    frame_timer <= 0;
                    if (frame_sel == 9) // Reset after 10th frame (0-9)
                        frame_sel <= 0;
                    else
                        frame_sel <= frame_sel + 1;
                end else begin
                    frame_timer <= frame_timer + 1;
                end
            end else begin
                frame_sel <= 0;
            end
        end
    end

    // No combined final address needed — each VRAM holds a whole frame
    // and is indexed by the same per-frame pixel address `base_raddr`.

    DST dst_inst (
        .pclk(pclk),
        .rstn(rstn),
        .hs(hs),
        .vs(vs),
        .hen(hen),
        .ven(ven)
    );

    // Instantiate 10 separate VRAM IPs manually
    // Each IP (VRAM_0 to VRAM_9) must be created in Vivado and load a different COE file.
    
    VRAM_0 vram0 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[0]) );
    VRAM_1 vram1 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[1]) );
    VRAM_2 vram2 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[2]) );
    VRAM_3 vram3 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[3]) );
    VRAM_4 vram4 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[4]) );
    VRAM_5 vram5 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[5]) );
    VRAM_6 vram6 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[6]) );
    VRAM_7 vram7 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[7]) );
    VRAM_8 vram8 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[8]) );
    VRAM_9 vram9 ( .clka(clk), .wea(1'b0), .addra(15'd0), .dina(12'd0), .clkb(pclk), .addrb(base_raddr), .doutb(vram_dout[9]) );

    // Small combinational multiplexer: select which VRAM's output drives rdata
    reg [11:0] rdata_reg;
    assign rdata = rdata_reg;

    always @(*) begin
        case (frame_sel)
            4'd0:  rdata_reg = vram_dout[0];
            4'd1:  rdata_reg = vram_dout[1];
            4'd2:  rdata_reg = vram_dout[2];
            4'd3:  rdata_reg = vram_dout[3];
            4'd4:  rdata_reg = vram_dout[4];
            4'd5:  rdata_reg = vram_dout[5];
            4'd6:  rdata_reg = vram_dout[6];
            4'd7:  rdata_reg = vram_dout[7];
            4'd8:  rdata_reg = vram_dout[8];
            4'd9:  rdata_reg = vram_dout[9];
            default: rdata_reg = vram_dout[0];
        endcase
    end

    DDP #(
        .DW(15),
        .H_LEN(200),
        .V_LEN(150)
    ) ddp_inst (
        .pclk(pclk),
        .rstn(rstn),
        .hen(hen),
        .ven(ven),
        .test_mode(SW[0]),
        .rdata(rdata),
        .raddr(base_raddr),
        .red(r),
        .green(g),
        .blue(b)
    );

    assign VGA_HS = hs;
    assign VGA_VS = vs;
    assign VGA_R = r;
    assign VGA_G = g;
    assign VGA_B = b;

endmodule