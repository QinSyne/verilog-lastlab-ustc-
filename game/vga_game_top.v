module vga_game_top(
    input         clk,        // Nexys4 DDR 100MHz 时钟
    input         rst_n,      // CPU_RESETN
    input         BTNL,       // 左键
    input         BTNR,       // 右键
    output        VGA_HS,     // VGA行同步
    output        VGA_VS,     // VGA场同步
    output [3:0]  VGA_R,      // VGA 红色分量
    output [3:0]  VGA_G,      // VGA 绿色分量
    output [3:0]  VGA_B,      // VGA 蓝色分量
    output [7:0]  LED         // LED显示得分
);

// 1. 时钟分频：100MHz -> 50MHz
reg clk_50m;
always @(posedge clk) begin
    if(!rst_n) clk_50m <= 1'b0;
    else clk_50m <= ~clk_50m;
end

// 2. 信号映射
wire [1:0] key;
assign key = {BTNR, BTNL}; // 10:右移, 01:左移

wire [11:0] rgb;
assign VGA_R = rgb[11:8];
assign VGA_G = rgb[7:4];
assign VGA_B = rgb[3:0];

// 中间信号
wire [10:0] xpos, ypos;
wire        valid;
wire [7:0]  score;

assign LED = score; // 将得分显示在LED上

// 3. 模块例化
// 例化VGA时序模块
vga_timing u_vga_timing(
    .clk_50m(clk_50m),
    .rst_n(rst_n),
    .hsync(VGA_HS),
    .vsync(VGA_VS),
    .valid(valid),
    .xpos(xpos),
    .ypos(ypos)
);

// 例化游戏控制模块
game_ctrl u_game_ctrl(
    .clk_50m(clk_50m),
    .rst_n(rst_n),
    .xpos(xpos),
    .ypos(ypos),
    .valid(valid),
    .key(key),
    .rgb(rgb),
    .score(score)
);

endmodule