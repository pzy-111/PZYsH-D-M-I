`timescale 1ns / 1ps
module vga_top (
    input  wire        sys_clk_50m,   // 板载 50MHz
    input  wire        sys_rst_n,     // 按键复位(低有效)
    // VGA2 / J6_VGA 接口
    output wire        vga_clk,       // VGA1_CLK (M19)
    output wire        vga_hs,        // VGA1_HSYNC (G10)
    output wire        vga_vs,        // VGA1_VSYNC (A20)
    output wire [23:0] vga_d          // VGA1_D23 ~ VGA1_D0
);

    wire pll_pix_clk;
    wire pll_locked;
    wire rst_high;

    // 复位与PLL锁定联合复位 (高有效)
    assign rst_high = (~sys_rst_n) | (~pll_locked);

    // 例化您提供的 altpll IP (50MHz -> 74.25MHz)
    pll_1 u_pll_74m (
        .areset (rst_high),
        .inclk0 (sys_clk_50m),
        .c0     (pll_pix_clk),
        .locked (pll_locked)
    );

    // 视频时序与彩条生成核心
    vga_720p_core u_core (
        .pix_clk (pll_pix_clk),
        .rst_n   (~rst_high),
        .vga_hs  (vga_hs),
        .vga_vs  (vga_vs),
        .vga_d   (vga_d)
    );

    // 像素时钟直接输出至 ADV7123 CLK 引脚
    assign vga_clk = pll_pix_clk;

endmodule

