module game_ctrl(
    input         clk_50m,
    input         rst_n,
    input  [10:0] xpos,    // VGA水平坐标
    input  [10:0] ypos,    // VGA垂直坐标
    input         valid,   // 有效显示区域标志
    input  [1:0]  key,     // 按键输入（01:左移，10:右移）
    output reg [11:0] rgb, // 输出RGB（12位：4R+4G+4B）
    output reg [7:0] score // 得分
);

// 游戏元素参数定义
parameter BOARD_W = 80;    // 板子宽度
parameter BOARD_H = 10;    // 板子高度
parameter BOARD_Y = 580;   // 板子垂直位置（底部）
parameter BALL_R  = 5;     // 小球半径
parameter POINT_W = 20;    // 得分点宽度
parameter POINT_H = 20;    // 得分点高度
parameter BORDER_W = 5;    // 边界宽度（像素）
parameter BORDER_MARGIN = 10; // 边界距屏幕边缘的内边距（像素）
parameter BIN_LED_SIZE = 12; // 二进制LED指示灯大小（正方形）
parameter BIN_LED_GAP = 4;  // LED之间的间隔
parameter SCORE_X = 680;   // 得分显示X位置
parameter SCORE_Y = 20;    // 得分显示Y位置

// 速度控制参数
// 50MHz / 500000 = 100Hz (10ms 更新一次位置)
parameter SPEED_CNT_MAX = 500000; 

// 板子坐标（仅水平移动）
reg [10:0] board_x;  // 板子左上角x坐标
// 小球坐标（中心）
reg [10:0] ball_x, ball_y;
// 小球运动速度（像素/帧）
reg [2:0] ball_vx, ball_vy;
// 小球运动方向（1:右/下，0:左/上）
reg ball_dir_x, ball_dir_y;
// 得分点坐标（示例：3个得分点）
reg [10:0] point_x[0:2], point_y[0:2];
reg [2:0] point_valid;  // 得分点是否有效（1:有效）

// 速度控制计数器
reg [19:0] speed_cnt;
wire move_en;

// 随机数生成器（LFSR - 线性反馈移位寄存器）
reg [15:0] lfsr;  // 16位LFSR用于生成随机数
wire feedback;
assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];  // 多项式反馈

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) lfsr <= 16'hACE1;  // 初始种子（非零）
    else lfsr <= {lfsr[14:0], feedback};  // 移位并反馈
end

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) speed_cnt <= 20'd0;
    else if(speed_cnt == SPEED_CNT_MAX - 1) speed_cnt <= 20'd0;
    else speed_cnt <= speed_cnt + 1'b1;
end

assign move_en = (speed_cnt == SPEED_CNT_MAX - 1);

// 二进制LED显示


// 初始化游戏元素
initial begin
    board_x = (800 - BOARD_W)/2;  // 板子居中
    ball_x = 400; ball_y = 300;  // 小球初始位置
    ball_vx = 2; ball_vy = 2;    // 小球初始速度
    ball_dir_x = 1; ball_dir_y = 1; // 初始向右下
    // 得分点初始位置
    point_x[0] = 200; point_y[0] = 100;
    point_x[1] = 400; point_y[1] = 100;
    point_x[2] = 600; point_y[2] = 100;
    point_valid = 3'b111;  // 所有得分点有效
    score = 8'd0;
end

// 1. 板子拖动逻辑（按键控制）
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) board_x <= (800 - BOARD_W)/2;
    else if(move_en) begin
        case(key)
            2'b01:  // 左移
                if(board_x > 4) board_x <= board_x - 4'd4; // 增加移动速度
            2'b10:  // 右移
                if(board_x < 800 - BOARD_W - 4) board_x <= board_x + 4'd4;
            default: board_x <= board_x;
        endcase
    end
end

// 2. 小球运动逻辑
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        ball_x <= 400; ball_y <= 300;
        ball_dir_x <= 1; ball_dir_y <= 1;
        ball_vx <= 2; ball_vy <= 2;
    end
    else if(move_en) begin
        // 水平运动
        if(ball_dir_x) ball_x <= ball_x + ball_vx;  // 右移
        else ball_x <= ball_x - ball_vx;            // 左移
        // 垂直运动
        if(ball_dir_y) ball_y <= ball_y + ball_vy;  // 下移
        else ball_y <= ball_y - ball_vy;            // 上移

        // 边界碰撞：左右边框
        if(ball_x <= BALL_R + ball_vx)
            ball_dir_x <= 1; // 向右
        else if(ball_x >= 800 - BALL_R - ball_vx)
            ball_dir_x <= 0; // 向左
            
        // 边界碰撞：上边框
        if(ball_y <= BALL_R + ball_vy)
            ball_dir_y <= 1; // 向下

        // 板子碰撞：检测小球是否碰到板子
        if((ball_y + BALL_R >= BOARD_Y) && (ball_y + BALL_R <= BOARD_Y + BOARD_H + ball_vy)
           && (ball_x >= board_x - BALL_R) && (ball_x <= board_x + BOARD_W + BALL_R))
            ball_dir_y <= 0;  // 反弹向上
            
        // 落地（游戏重置）
        if(ball_y >= 600 - BALL_R) begin
            ball_x <= 400; ball_y <= 300;
            ball_dir_x <= 1; ball_dir_y <= 1;
        end
    end
end
integer i;
// 3. 得分点碰撞检测
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        score <= 8'd0;
        point_valid <= 3'b111;
    end
    else begin
        // 游戏重置时重置分数和绿点（随机位置）
        if(move_en && ball_y >= 600 - BALL_R) begin
             score <= 8'd0;
             point_valid <= 3'b111;
             // 使用随机数重新设置绿点位置
             point_x[0] <= 50 + (lfsr[9:0] % 700);  // x范围: 50-750
             point_y[0] <= 50 + (lfsr[5:0] % 350);  // y范围: 50-400
             point_x[1] <= 50 + ((lfsr[15:6] + 200) % 700);
             point_y[1] <= 50 + ((lfsr[11:6] + 20) % 350);
             point_x[2] <= 50 + ((lfsr[7:0] + 400) % 700);
             point_y[2] <= 50 + ((lfsr[13:8] + 40) % 350);
        end
        // 击中所有绿点后重置绿点（保留分数，随机位置）
        else if(point_valid == 3'b000) begin
            point_valid <= 3'b111;  // 重置所有绿点
            // 使用随机数设置新位置
            point_x[0] <= 50 + (lfsr[9:0] % 700);
            point_y[0] <= 50 + (lfsr[5:0] % 350);
            point_x[1] <= 50 + ((lfsr[15:6] + 200) % 700);
            point_y[1] <= 50 + ((lfsr[11:6] + 20) % 350);
            point_x[2] <= 50 + ((lfsr[7:0] + 400) % 700);
            point_y[2] <= 50 + ((lfsr[13:8] + 40) % 350);
        end
        else begin
            for( i=0; i<3; i=i+1) begin
                if(point_valid[i] && (ball_x >= point_x[i] - BALL_R) && (ball_x <= point_x[i] + POINT_W + BALL_R)
                   && (ball_y >= point_y[i] - BALL_R) && (ball_y <= point_y[i] + POINT_H + BALL_R)) begin
                    point_valid[i] <= 1'b0;  // 得分点失效
                    score <= score + 8'd1;   // 得分+1
                end
            end
        end
    end
end

// 4. VGA显示逻辑（绘制游戏元素）
// 二进制LED显示逻辑 - 显示8位二进制（score[7:0]）
// 从右到左显示：bit0(最右) -> bit7(最左)
wire [7:0] led_on;  // 8个LED的状态
wire [7:0] in_led;  // 当前像素是否在某个LED区域内
genvar j;
generate
    for(j=0; j<8; j=j+1) begin : led_gen
        // LED位置计算：从右到左排列
        wire [10:0] led_x = SCORE_X + (7-j) * (BIN_LED_SIZE + BIN_LED_GAP);
        wire [10:0] led_y = SCORE_Y;
        // 判断当前像素是否在LED i的区域内
        assign in_led[j] = (xpos >= led_x) && (xpos < led_x + BIN_LED_SIZE) &&
                          (ypos >= led_y) && (ypos < led_y + BIN_LED_SIZE);
        // LED状态：如果该位为1则亮（白色），否则暗（灰色）
        assign led_on[j] = score[j];//二进制显示分数
    end
endgenerate

// 判断是否在任意一个LED区域内以及对应的颜色
wire in_any_led = |in_led;
wire [11:0] led_color = 
    (in_led[0] && led_on[0]) ? 12'hFFF :
    (in_led[1] && led_on[1]) ? 12'hFFF :
    (in_led[2] && led_on[2]) ? 12'hFFF :
    (in_led[3] && led_on[3]) ? 12'hFFF :
    (in_led[4] && led_on[4]) ? 12'hFFF :
    (in_led[5] && led_on[5]) ? 12'hFFF :
    (in_led[6] && led_on[6]) ? 12'hFFF :
    (in_led[7] && led_on[7]) ? 12'hFFF :
    (in_led[0] && !led_on[0]) ? 12'h333 :
    (in_led[1] && !led_on[1]) ? 12'h333 :
    (in_led[2] && !led_on[2]) ? 12'h333 :
    (in_led[3] && !led_on[3]) ? 12'h333 :
    (in_led[4] && !led_on[4]) ? 12'h333 :
    (in_led[5] && !led_on[5]) ? 12'h333 :
    (in_led[6] && !led_on[6]) ? 12'h333 :
    (in_led[7] && !led_on[7]) ? 12'h333 : 12'h000;

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) rgb <= 12'h000;  // 黑屏
    else if(valid) begin
        // 绘制白色边界（在屏幕最外侧，右边框特别强调）
        if((xpos < BORDER_W) ||                           // 左边框
           (xpos >= 800 - BORDER_W) ||                    // 右边框（最外侧）
           (ypos < BORDER_W) ||                           // 上边框
           (ypos >= 600 - BORDER_W))                      // 下边框
            rgb <= 12'hFFF;  // 白色边界
        // 绘制二进制LED显示（亮=白色，暗=深灰）
        else if(in_any_led)
            rgb <= led_color;
        // 绘制板子（蓝色）
        else if((ypos >= BOARD_Y) && (ypos <= BOARD_Y + BOARD_H)
           && (xpos >= board_x) && (xpos <= board_x + BOARD_W))
            rgb <= 12'h00F;
        // 绘制小球（红色）
        else if(((xpos > ball_x ? xpos - ball_x : ball_x - xpos)*(xpos > ball_x ? xpos - ball_x : ball_x - xpos) + 
                 (ypos > ball_y ? ypos - ball_y : ball_y - ypos)*(ypos > ball_y ? ypos - ball_y : ball_y - ypos)) <= BALL_R*BALL_R)
            rgb <= 12'hF00;
        // 绘制得分点（绿色，有效时显示）
        else if((point_valid[0] && (xpos >= point_x[0]) && (xpos <= point_x[0]+POINT_W) 
                && (ypos >= point_y[0]) && (ypos <= point_y[0]+POINT_H))
             || (point_valid[1] && (xpos >= point_x[1]) && (xpos <= point_x[1]+POINT_W) 
                && (ypos >= point_y[1]) && (ypos <= point_y[1]+POINT_H))
             || (point_valid[2] && (xpos >= point_x[2]) && (xpos <= point_x[2]+POINT_W) 
                && (ypos >= point_y[2]) && (ypos <= point_y[2]+POINT_H)))
            rgb <= 12'h0F0;
        // 背景（黑色）
        else rgb <= 12'h000;
    end
    else rgb <= 12'h000;  // 无效区黑屏
end

endmodule
