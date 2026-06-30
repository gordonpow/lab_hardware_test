----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    2026/06/30
-- Design Name:    VGA Controller
-- Module Name:    vgaController - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--   VGA 640x480 @ 60Hz 時序控制器 (VHDL 版本)
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vgaController is
    generic (
        g_hActive_l     : integer := 640;     -- 水平有效區域長度
        g_hFrontPorch_l : integer := 16;      -- 水平前廊長度
        g_hSyncPulse_l  : integer := 96;      -- 水平同步脈衝長度
        g_hBackPorch_l  : integer := 48;      -- 水平後廊長度
        g_hTotal_l      : integer := 800;     -- 水平總長度

        g_vActive_l     : integer := 480;     -- 垂直有效區域長度
        g_vFrontPorch_l : integer := 10;      -- 垂直前廊長度
        g_vSyncPulse_l  : integer := 2;       -- 垂直同步脈衝長度
        g_vBackPorch_l  : integer := 33;      -- 垂直後廊長度
        g_vTotal_l      : integer := 525      -- 垂直總長度
    );
    port (
        i_clk_r          : in  std_logic;                     -- 輸入像素時脈 (25MHz)
        i_rst_r          : in  std_logic;                     -- 輸入非同步高電位重設
        o_hSync_w        : out std_logic;                     -- 輸出水平同步訊號
        o_vSync_w        : out std_logic;                     -- 輸出垂直同步訊號
        o_videoActive_w  : out std_logic;                     -- 輸出有效顯示區域訊號
        o_pixelX_w       : out std_logic_vector(9 downto 0);  -- 輸出當前 X 座標
        o_pixelY_w       : out std_logic_vector(9 downto 0)   -- 輸出當前 Y 座標
    );
end vgaController;

architecture Behavioral of vgaController is

    -- 內部變數 (使用變數 v_ 前綴與暫存器修飾 _r 或組合邏輯修飾 _w)
    signal v_hCount_r      : unsigned(9 downto 0) := (others => '0');
    signal v_vCount_r      : unsigned(9 downto 0) := (others => '0');
    signal v_hSync_r       : std_logic := '1';
    signal v_vSync_r       : std_logic := '1';
    signal v_videoActive_w : std_logic;

begin

    -- 水平計數器邏輯
    H_COUNT: process(i_clk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_hCount_r <= (others => '0');
        elsif rising_edge(i_clk_r) then
            if v_hCount_r = to_unsigned(g_hTotal_l - 1, 10) then
                v_hCount_r <= (others => '0');
            else
                v_hCount_r <= v_hCount_r + 1;
            end if;
        end if;
    end process H_COUNT;

    -- 垂直計數器邏輯
    V_COUNT: process(i_clk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_vCount_r <= (others => '0');
        elsif rising_edge(i_clk_r) then
            if v_hCount_r = to_unsigned(g_hTotal_l - 1, 10) then
                if v_vCount_r = to_unsigned(g_vTotal_l - 1, 10) then
                    v_vCount_r <= (others => '0');
                else
                    v_vCount_r <= v_vCount_r + 1;
                end if;
            end if;
        end if;
    end process V_COUNT;

    -- 水平同步訊號產生 (HSync 在同步脈衝區為低電位)
    H_SYNC: process(i_clk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_hSync_r <= '1';
        elsif rising_edge(i_clk_r) then
            if (v_hCount_r >= to_unsigned(g_hActive_l + g_hFrontPorch_l, 10)) and
               (v_hCount_r < to_unsigned(g_hActive_l + g_hFrontPorch_l + g_hSyncPulse_l, 10)) then
                v_hSync_r <= '0';
            else
                v_hSync_r <= '1';
            end if;
        end if;
    end process H_SYNC;

    -- 垂直同步訊號產生 (VSync 在同步脈衝區為低電位)
    V_SYNC: process(i_clk_r, i_rst_r)
    begin
        if i_rst_r = '1' then
            v_vSync_r <= '1';
        elsif rising_edge(i_clk_r) then
            if (v_vCount_r >= to_unsigned(g_vActive_l + g_vFrontPorch_l, 10)) and
               (v_vCount_r < to_unsigned(g_vActive_l + g_vFrontPorch_l + g_vSyncPulse_l, 10)) then
                v_vSync_r <= '0';
            else
                v_vSync_r <= '1';
            end if;
        end if;
    end process V_SYNC;

    -- 有效顯示區域判定
    v_videoActive_w <= '1' when (v_hCount_r < to_unsigned(g_hActive_l, 10)) and
                                (v_vCount_r < to_unsigned(g_vActive_l, 10))
                       else '0';

    -- 輸出埠指派 (使用寫入 _w 修飾)
    o_hSync_w       <= v_hSync_r;
    o_vSync_w       <= v_vSync_r;
    o_videoActive_w <= v_videoActive_w;
    
    o_pixelX_w      <= std_logic_vector(v_hCount_r) when (v_hCount_r < to_unsigned(g_hActive_l, 10)) else (others => '0');
    o_pixelY_w      <= std_logic_vector(v_vCount_r) when (v_vCount_r < to_unsigned(g_vActive_l, 10)) else (others => '0');

end Behavioral;
