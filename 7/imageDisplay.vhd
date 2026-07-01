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
--   VGA 影像顯示系統子模組 (VHDL 版本)
--   從 Block RAM 讀取 256x256 的 24-bit 影像，置中顯示在 640x480 @ 60Hz VGA 螢幕上
--
-- Dependencies:
--   blk_mem_gen_0 (Block Memory Generator IP)
--
-- Revision:
-- Revision 0.03 - Added input registering to fix hold/setup time issues (blue line fix)
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
        i_pClk_r         : in  std_logic;                     -- 像素時脈輸入 (25MHz)
        i_rst_r          : in  std_logic;                     -- 重設輸入 (高電位有效)
        i_hSync_r        : in  std_logic;                     -- VGA 控制器水平同步信號
        i_vSync_r        : in  std_logic;                     -- VGA 控制器垂直同步信號
        i_videoActive_r  : in  std_logic;                     -- VGA 控制器有效顯示區域信號
        i_pixelX_r       : in  std_logic_vector(9 downto 0);  -- VGA 控制器 X 座標
        i_pixelY_r       : in  std_logic_vector(9 downto 0);  -- VGA 控制器 Y 座標
        o_hSync_w        : out std_logic;                     -- VGA 水平同步信號 (延遲對齊後)
        o_vSync_w        : out std_logic;                     -- VGA 垂直同步信號 (延遲對齊後)
        o_vgaRed_w       : out std_logic_vector(5 downto 0);  -- VGA 紅色輸出 (6-bit)
        o_vgaGreen_w     : out std_logic_vector(5 downto 0);  -- VGA 綠色輸出 (6-bit)
        o_vgaBlue_w      : out std_logic_vector(5 downto 0)   -- VGA 藍色輸出 (6-bit)
    );
end imageDisplay;

architecture Behavioral of imageDisplay is

    -- ========================================================================
    -- 元件宣告 (Components)
    -- ========================================================================
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
    -- 1. 輸入訊號同步鎖存暫存器 (防止跨模組 setup/hold time 違規與亮藍線問題)
    signal v_pixelXReg_r       : std_logic_vector(9 downto 0) := (others => '0');
    signal v_pixelYReg_r       : std_logic_vector(9 downto 0) := (others => '0');
    signal v_videoActiveReg_r  : std_logic := '0';
    signal v_hSyncReg_r        : std_logic := '1';
    signal v_vSyncReg_r        : std_logic := '1';

    -- 2. ROM 位址計算與範圍判斷
    signal v_inImageRegion_r : std_logic := '0';
    signal v_romAddr_w       : unsigned(15 downto 0);

    -- ROM 影像資料接線與重設忙碌訊號線 (使用 v_ 前綴與 _w 寫入修飾)
    signal v_romData_w  : std_logic_vector(31 downto 0);
    signal v_rstaBusy_w : std_logic;
    signal v_bramAddr_w : std_logic_vector(31 downto 0);

    -- 3. 延遲對齊邏輯 (打拍暫存器，對齊 BRAM 的 3 拍延遲)
    signal v_hSyncDelay1_r       : std_logic := '1';
    signal v_hSyncDelay2_r       : std_logic := '1';
    signal v_vSyncDelay1_r       : std_logic := '1';
    signal v_vSyncDelay2_r       : std_logic := '1';
    signal v_videoActiveDelay1_r : std_logic := '0';
    signal v_videoActiveDelay2_r : std_logic := '0';
    signal v_inImageRegionDelay_r : std_logic := '0';

begin

    -- ========================================================================
    -- 1. 同步鎖存所有輸入訊號
    -- ========================================================================
    REG_INPUT: process(i_pClk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_pixelXReg_r      <= (others => '0');
            v_pixelYReg_r      <= (others => '0');
            v_videoActiveReg_r <= '0';
            v_hSyncReg_r       <= '1';
            v_vSyncReg_r       <= '1';
        elsif rising_edge(i_pClk_r) then
            v_pixelXReg_r      <= i_pixelX_r;
            v_pixelYReg_r      <= i_pixelY_r;
            v_videoActiveReg_r <= i_videoActive_r;
            v_hSyncReg_r       <= i_hSync_r;
            v_vSyncReg_r       <= i_vSync_r;
        end if;
    end process REG_INPUT;

    -- ========================================================================
    -- 2. ROM 位址計算與範圍判斷 (使用時序邏輯暫存器防止 Gate Delay 與 Glitch 影響時序)
    -- ========================================================================
    REGION_PROC: process(i_pClk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_inImageRegion_r <= '0';
        elsif rising_edge(i_pClk_r) then
            if (unsigned(v_pixelXReg_r) >= to_unsigned(g_imgStartX_l, 10)) and
               (unsigned(v_pixelXReg_r) < to_unsigned(g_imgStartX_l + g_imgWidth_l, 10)) and
               (unsigned(v_pixelYReg_r) >= to_unsigned(g_imgStartY_l, 10)) and
               (unsigned(v_pixelYReg_r) < to_unsigned(g_imgStartY_l + g_imgHeight_l, 10)) then
                v_inImageRegion_r <= '1';
            else
                v_inImageRegion_r <= '0';
            end if;
        end if;
    end process REGION_PROC;

    -- ROM 讀取位址組合邏輯 (判斷條件使用當前組合邏輯值，保證位址即時算出提早一拍，以對齊 BRAM 的讀取延遲)
    v_romAddr_w <= to_unsigned((to_integer(unsigned(v_pixelYReg_r)) - g_imgStartY_l) * g_imgWidth_l + 
                               (to_integer(unsigned(v_pixelXReg_r)) - g_imgStartX_l), 16)
                   when (unsigned(v_pixelXReg_r) >= to_unsigned(g_imgStartX_l, 10)) and
                        (unsigned(v_pixelXReg_r) < to_unsigned(g_imgStartX_l + g_imgWidth_l, 10)) and
                        (unsigned(v_pixelYReg_r) >= to_unsigned(g_imgStartY_l, 10)) and
                        (unsigned(v_pixelYReg_r) < to_unsigned(g_imgStartY_l + g_imgHeight_l, 10))
                   else (others => '0');

    -- ========================================================================
    -- 3. 實例化 Block Memory Generator IP (blk_mem_gen_0)
    -- ========================================================================
    v_bramAddr_w <= "00000000000000" & std_logic_vector(v_romAddr_w) & "00";

    u_blk_mem_gen_0 : blk_mem_gen_0
        port map (
            clka      => i_pClk_r,                                           -- Port A 時脈輸入 (像素時脈 25MHz)
            rsta      => i_rst_r,                                            -- Port A 重設輸入
            ena       => '1',                                                -- Port A 啟動信號 (常開)
            addra     => v_bramAddr_w,                                       -- 讀取位址
            douta     => v_romData_w,                                        -- Port A 輸出資料 (32-bit)
            rsta_busy => v_rstaBusy_w                                        -- Port A 重設忙碌訊號輸出
        );

    -- ========================================================================
    -- 4. 延遲對齊邏輯
    --    同步與顯示有效訊號做 2 級延遲打拍，影像區域判定做 1 級延遲打拍 (共 3 拍總延遲)
    -- ========================================================================
    DELAY_ALIGN: process(i_pClk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_hSyncDelay1_r        <= '1';
            v_hSyncDelay2_r        <= '1';
            v_vSyncDelay1_r        <= '1';
            v_vSyncDelay2_r        <= '1';
            v_videoActiveDelay1_r  <= '0';
            v_videoActiveDelay2_r  <= '0';
            v_inImageRegionDelay_r <= '0';
        elsif rising_edge(i_pClk_r) then
            v_hSyncDelay1_r        <= v_hSyncReg_r;
            v_hSyncDelay2_r        <= v_hSyncDelay1_r;
            v_vSyncDelay1_r        <= v_vSyncReg_r;
            v_vSyncDelay2_r        <= v_vSyncDelay1_r;
            v_videoActiveDelay1_r  <= v_videoActiveReg_r;
            v_videoActiveDelay2_r  <= v_videoActiveDelay1_r;
            v_inImageRegionDelay_r <= v_inImageRegion_r;
        end if;
    end process DELAY_ALIGN;

    -- ========================================================================
    -- 5. 影像色彩輸出控制
    --    影像區域外，當處於顯示有效區時，顯示深藍色背景 (6'h00, 6'h00, 6'h10)；
    --    其餘非有效區必須為純黑。
    -- ========================================================================
    o_hSync_w <= v_hSyncDelay1_r;
    o_vSync_w <= v_vSyncDelay1_r;

    o_vgaRed_w   <= v_romData_w(23 downto 18) when (v_videoActiveDelay2_r = '1' and v_inImageRegionDelay_r = '1') else (others => '0');
    o_vgaGreen_w <= v_romData_w(15 downto 10) when (v_videoActiveDelay2_r = '1' and v_inImageRegionDelay_r = '1') else (others => '0');
    o_vgaBlue_w  <= v_romData_w(7 downto 2)   when (v_videoActiveDelay2_r = '1' and v_inImageRegionDelay_r = '1') else
                    "000000"                  when (v_videoActiveDelay2_r = '1') else (others => '0');

end Behavioral;
