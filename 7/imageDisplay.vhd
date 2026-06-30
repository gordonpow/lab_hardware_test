----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    2026/06/30
-- Design Name:    VGA Image Display System
-- Module Name:    imageDisplay - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--   VGA 影像顯示系統頂層模組 (VHDL 版本)
--   從 Block RAM 讀取 256x256 的 24-bit 影像，置中顯示在 640x480 @ 60Hz VGA 螢幕上
--
-- Dependencies:
--   vgaController.vhd
--   blk_mem_gen_0 (Block Memory Generator IP)
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity imageDisplay is
    generic (
        g_imgStartX_l : integer := 192;   -- 影像置中的起始 X 座標 ((640 - 256) / 2)
        g_imgStartY_l : integer := 112;   -- 影像置中的起始 Y 座標 ((480 - 256) / 2)
        g_imgWidth_l  : integer := 256;   -- 影像寬度
        g_imgHeight_l : integer := 256    -- 影像高度
    );
    port (
        i_clk_r      : in  std_logic;                     -- 系統時脈輸入 (100MHz)
        i_rst_r      : in  std_logic;                     -- 重設輸入 (高電位有效)
        o_hSync_w    : out std_logic;                     -- VGA 水平同步信號
        o_vSync_w    : out std_logic;                     -- VGA 垂直同步信號
        o_vgaRed_w   : out std_logic_vector(5 downto 0);  -- VGA 紅色輸出 (6-bit)
        o_vgaGreen_w : out std_logic_vector(5 downto 0);  -- VGA 綠色輸出 (6-bit)
        o_vgaBlue_w  : out std_logic_vector(5 downto 0)   -- VGA 藍色輸出 (6-bit)
    );
end imageDisplay;

architecture Behavioral of imageDisplay is

    -- ========================================================================
    -- 元件宣告 (Components)
    -- ========================================================================
    component vgaController is
        generic (
            g_hActive_l     : integer := 640;
            g_hFrontPorch_l : integer := 16;
            g_hSyncPulse_l  : integer := 96;
            g_hBackPorch_l  : integer := 48;
            g_hTotal_l      : integer := 800;
            g_vActive_l     : integer := 480;
            g_vFrontPorch_l : integer := 10;
            g_vSyncPulse_l  : integer := 2;
            g_vBackPorch_l  : integer := 33;
            g_vTotal_l      : integer := 525
        );
        port (
            i_clk_r          : in  std_logic;
            i_rst_r          : in  std_logic;
            o_hSync_w        : out std_logic;
            o_vSync_w        : out std_logic;
            o_videoActive_w  : out std_logic;
            o_pixelX_w       : out std_logic_vector(9 downto 0);
            o_pixelY_w       : out std_logic_vector(9 downto 0)
        );
    end component;

    component blk_mem_gen_0 is
        port (
            clka      : in  std_logic;
            rsta      : in  std_logic;
            ena       : in  std_logic;
            addra     : in  std_logic_vector(31 downto 0);
            douta     : out std_logic_vector(31 downto 0);
            rsta_busy : out std_logic
        );
    end component;

    -- ========================================================================
    -- 內部信號宣告 (Signals)
    -- ========================================================================
    -- 1. 時脈除頻邏輯：100MHz 除頻為 25MHz 像素時脈
    signal v_clkDiv_r : unsigned(1 downto 0) := (others => '0');
    signal v_pClk_w   : std_logic;

    -- VGA 控制器接線
    signal v_hSync_w       : std_logic;
    signal v_vSync_w       : std_logic;
    signal v_videoActive_w : std_logic;
    signal v_pixelX_w      : std_logic_vector(9 downto 0);
    signal v_pixelY_w      : std_logic_vector(9 downto 0);

    -- 2. ROM 位址計算與範圍判斷
    signal v_inImageRegion_w : std_logic;
    signal v_romAddr_r       : unsigned(15 downto 0) := (others => '0');

    -- ROM 影像資料接線與重設忙碌訊號線 (使用 v_ 前綴與 _w 寫入修飾)
    signal v_romData_w  : std_logic_vector(31 downto 0);
    signal v_rstaBusy_w : std_logic;
    signal v_bramAddr_w : std_logic_vector(31 downto 0);

    -- 3. 延遲對齊邏輯 (打拍暫存器)
    signal v_hSyncDelay_r         : std_logic := '1';
    signal v_vSyncDelay_r         : std_logic := '1';
    signal v_videoActiveDelay_r   : std_logic := '0';
    signal v_inImageRegionDelay_r : std_logic := '0';

begin

    -- ========================================================================
    -- 1. 時脈除頻邏輯：100MHz 除頻為 25MHz 像素時脈
    -- ========================================================================
    CLK_DIV: process(i_clk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_clkDiv_r <= (others => '0');
        elsif rising_edge(i_clk_r) then
            v_clkDiv_r <= v_clkDiv_r + 1;
        end if;
    end process CLK_DIV;
    
    v_pClk_w <= v_clkDiv_r(1);

    -- ========================================================================
    -- 實例化獨立 VGA 控制器模組
    -- ========================================================================
    u_vgaController : vgaController
        port map (
            i_clk_r          => v_pClk_w,
            i_rst_r          => i_rst_r,
            o_hSync_w        => v_hSync_w,
            o_vSync_w        => v_vSync_w,
            o_videoActive_w  => v_videoActive_w,
            o_pixelX_w       => v_pixelX_w,
            o_pixelY_w       => v_pixelY_w
        );

    -- ========================================================================
    -- 2. ROM 位址計算與範圍判斷
    --    計算當前像素是否落在影像顯示區內
    -- ========================================================================
    v_inImageRegion_w <= '1' when (unsigned(v_pixelX_w) >= to_unsigned(g_imgStartX_l, 10)) and
                                  (unsigned(v_pixelX_w) < to_unsigned(g_imgStartX_l + g_imgWidth_l, 10)) and
                                  (unsigned(v_pixelY_w) >= to_unsigned(g_imgStartY_l, 10)) and
                                  (unsigned(v_pixelY_w) < to_unsigned(g_imgStartY_l + g_imgHeight_l, 10))
                         else '0';

    -- ROM 讀取位址暫存器邏輯
    ROM_ADDR: process(v_pClk_w, i_rst_r)
        variable v_tempAddr : integer;
    begin
        if i_rst_r = '1' then
            v_romAddr_r <= (others => '0');
        elsif rising_edge(v_pClk_w) then
            if v_inImageRegion_w = '1' then
                -- 計算一維記憶體位址: (Y - Y_start) * Width + (X - X_start)
                v_tempAddr := (to_integer(unsigned(v_pixelY_w)) - g_imgStartY_l) * g_imgWidth_l + 
                              (to_integer(unsigned(v_pixelX_w)) - g_imgStartX_l);
                v_romAddr_r <= to_unsigned(v_tempAddr, 16);
            else
                v_romAddr_r <= (others => '0');
            end if;
        end if;
    end process ROM_ADDR;

    -- ========================================================================
    -- 實例化 Block Memory Generator IP (blk_mem_gen_0)
    -- ========================================================================
    v_bramAddr_w <= "00000000000000" & std_logic_vector(v_romAddr_r) & "00";

    u_blk_mem_gen_0 : blk_mem_gen_0
        port map (
            clka      => v_pClk_w,                                           -- Port A 時脈輸入 (像素時脈 25MHz)
            rsta      => i_rst_r,                                            -- Port A 重設輸入
            ena       => '1',                                                -- Port A 啟動信號 (常開)
            addra     => v_bramAddr_w,                                       -- 讀取位址 (使用靜態名稱，消除警告)
            douta     => v_romData_w,                                        -- Port A 輸出資料 (32-bit)
            rsta_busy => v_rstaBusy_w                                        -- Port A 重設忙碌訊號輸出
        );

    -- ========================================================================
    -- 3. 延遲對齊邏輯 (重要！)
    --    由於 Block RAM 讀取需要 1 個像素時脈的延遲，
    --    我們必須將 VGA 的控制與同步信號也延遲 1 個像素時脈，以確保影像色彩與掃描線位置完美對齊。
    -- ========================================================================
    DELAY_ALIGN: process(v_pClk_w, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_hSyncDelay_r         <= '1';
            v_vSyncDelay_r         <= '1';
            v_videoActiveDelay_r   <= '0';
            v_inImageRegionDelay_r <= '0';
        elsif rising_edge(v_pClk_w) then
            v_hSyncDelay_r         <= v_hSync_w;
            v_vSyncDelay_r         <= v_vSync_w;
            v_videoActiveDelay_r   <= v_videoActive_w;
            v_inImageRegionDelay_r <= v_inImageRegion_w;
        end if;
    end process DELAY_ALIGN;

    -- ========================================================================
    -- 4. 影像色彩輸出控制
    --    影像區域外，當處於顯示有效區時，顯示深藍色背景 (6'h00, 6'h00, 6'h10)；
    --    其餘非有效區必須為純黑。
    -- ========================================================================
    o_hSync_w <= v_hSyncDelay_r;
    o_vSync_w <= v_vSyncDelay_r;

    o_vgaRed_w   <= v_romData_w(23 downto 18) when (v_videoActiveDelay_r = '1' and v_inImageRegionDelay_r = '1') else (others => '0');
    o_vgaGreen_w <= v_romData_w(15 downto 10) when (v_videoActiveDelay_r = '1' and v_inImageRegionDelay_r = '1') else (others => '0');
    o_vgaBlue_w  <= v_romData_w(7 downto 2)   when (v_videoActiveDelay_r = '1' and v_inImageRegionDelay_r = '1') else
                    "010000"                  when (v_videoActiveDelay_r = '1') else (others => '0');

end Behavioral;
