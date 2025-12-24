module vga_timing(
    input         clk_50m,    // 50MHz像素时钟
    input         rst_n,      // 复位（低有效）
    output reg    hsync,      // 行同步
    output reg    vsync,      // 场同步
    output reg    valid,      // 有效显示区域标志
    output reg [10:0] xpos,   // 水平像素坐标（0~799）
    output reg [10:0] ypos    // 垂直像素坐标（0~599）
);

// 800x600@72Hz 时序参数（单位：像素）- 已调整向左平移75像素
parameter H_TOTAL = 1115;  // 行总周期（原1040+75=1115）
parameter H_SYNC  = 128;   // 行同步宽度
parameter H_BACK  = 163;   // 行后沿（原88+75=163，向左平移75像素）
parameter H_VALID = 800;   // 行有效显示
parameter H_FRONT = 24;    // 行前沿（1115-128-163-800=24）

parameter V_TOTAL = 666;   // 场总周期
parameter V_SYNC  = 6;     // 场同步宽度
parameter V_BACK  = 23;    // 场后沿
parameter V_VALID = 600;   // 场有效显示
parameter V_FRONT = 3;     // 场前沿

// 行计数器
reg [10:0] h_cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) h_cnt <= 11'd0;
    else if(h_cnt == H_TOTAL - 1) h_cnt <= 11'd0;
    else h_cnt <= h_cnt + 11'd1;
end

// 场计数器
reg [10:0] v_cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) v_cnt <= 11'd0;
    else if(h_cnt == H_TOTAL - 1) begin
        if(v_cnt == V_TOTAL - 1) v_cnt <= 11'd0;
        else v_cnt <= v_cnt + 11'd1;
    end
end

// 行同步信号（低有效）
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) hsync <= 1'b1;
    else if(h_cnt < H_SYNC) hsync <= 1'b0;
    else hsync <= 1'b1;
end

// 场同步信号（低有效）
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) vsync <= 1'b1;
    else if(v_cnt < V_SYNC) vsync <= 1'b0;
    else vsync <= 1'b1;
end

// 有效显示区域
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        valid <= 1'b0;
        xpos  <= 11'd0;
        ypos  <= 11'd0;
    end
    else if((h_cnt >= H_SYNC + H_BACK) && (h_cnt < H_SYNC + H_BACK + H_VALID) 
         && (v_cnt >= V_SYNC + V_BACK) && (v_cnt < V_SYNC + V_BACK + V_VALID)) begin
        valid <= 1'b1;
        xpos  <= h_cnt - (H_SYNC + H_BACK);  // 有效区x坐标0~799
        ypos  <= v_cnt - (V_SYNC + V_BACK);  // 有效区y坐标0~599
    end
    else begin
        valid <= 1'b0;
        xpos  <= 11'd0;
        ypos  <= 11'd0;
    end
end

endmodule
