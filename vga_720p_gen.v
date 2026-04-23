`timescale 1ns / 1ps
module vga_720p_core (
    input  wire        pix_clk,
    input  wire        rst_n,
    output reg         vga_hs,
    output reg         vga_vs,
    output reg [23:0]  vga_d
);
    // ================= 720P@60 VESA DMT 标准参数 =================
    // 水平: 1280(有效) + 110(前肩) + 40(同步) + 220(后肩) = 1650
    localparam H_ACT = 11'd1280, H_FP = 11'd110, H_SYNC = 11'd40, H_BP = 11'd220, H_TOT = 11'd1650;
    // 垂直:  720(有效)  +   5(前肩)  +  5(同步)  +  20(后肩)  =  750
    localparam V_ACT = 10'd720,  V_FP = 10'd5,   V_SYNC = 10'd5,   V_BP = 10'd20,  V_TOT = 10'd750;

    reg [10:0] h_cnt;
    reg [9:0]  v_cnt;

    always @(posedge pix_clk) begin
        if (!rst_n) h_cnt <= 0;
        else if (h_cnt == H_TOT - 1) h_cnt <= 0;
        else h_cnt <= h_cnt + 1'b1;
    end

    always @(posedge pix_clk) begin
        if (!rst_n) v_cnt <= 0;
        else if (h_cnt == H_TOT - 1) begin
            if (v_cnt == V_TOT - 1) v_cnt <= 0;
            else v_cnt <= v_cnt + 1'b1;
        end
    end

    // 同步信号 (720P标准：高电平有效)
    wire h_sync_active = (h_cnt >= H_ACT + H_FP) && (h_cnt < H_ACT + H_FP + H_SYNC);
    wire v_sync_active = (v_cnt >= V_ACT + V_FP) && (v_cnt < V_ACT + V_FP + V_SYNC);

    always @(posedge pix_clk) begin
    if (!rst_n) begin vga_hs <= 1'b1; vga_vs <= 1'b1; end
    else begin
        vga_hs <= ~h_sync_active;  // HSYNC 改为低电平有效
        vga_vs <= ~v_sync_active;  // 多数显示器兼容 VSYNC 低有效
    end
end

    // ================= 8色竖条生成 (RGB888) =================
    // 每条宽度 = 1280 / 8 = 160 像素
 wire [10:0] stripe_div = h_cnt / 11'd160; // 160用11位表示，杜绝截断为0
    wire [3:0]  stripe     = stripe_div[3:0]; // 取低4位供case使用
    
    reg [7:0] r_val, g_val, b_val;

    always @(*) begin
        case (stripe)
            4'd0: {r_val, g_val, b_val} = {8'hFF, 8'hFF, 8'hFF}; // 白
            4'd1: {r_val, g_val, b_val} = {8'hFF, 8'hFF, 8'h00}; // 黄
            4'd2: {r_val, g_val, b_val} = {8'h00, 8'hFF, 8'hFF}; // 青
            4'd3: {r_val, g_val, b_val} = {8'h00, 8'hFF, 8'h00}; // 绿
            4'd4: {r_val, g_val, b_val} = {8'hFF, 8'h00, 8'hFF}; // 品红
            4'd5: {r_val, g_val, b_val} = {8'hFF, 8'h00, 8'h00}; // 红
            4'd6: {r_val, g_val, b_val} = {8'h00, 8'h00, 8'hFF}; // 蓝
            4'd7: {r_val, g_val, b_val} = {8'h00, 8'h00, 8'h00}; // 黑
            default: {r_val, g_val, b_val} = 24'h000000;          // 同步/消隐期置黑
        endcase
    end

    // ================= 数据输出流水线 =================
    // ⚠️ 后期扩展接口：在此处替换 r_val/g_val/b_val 即可无缝接入旋转/缩放IP
    always @(posedge pix_clk) begin
        if (!rst_n) vga_d <= 24'h000000;
        else begin
            // 原理图网络名顺序：VGA1_D[23:16]=R, [15:8]=G, [7:0]=B
            // 若实际显示颜色错位，只需交换拼接顺序：{b_val, g_val, r_val}
            vga_d <= {r_val, g_val, b_val};
        end
    end

endmodule

