----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    2026/07/01
-- Design Name:    VGA Image Display System
-- Module Name:    top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--   VGA 影像顯示系統頂層模組 (VHDL 版本)
--   作為整個系統的頂層，實例化 vgaController 與 imageDisplay 子模組並進行接線
--
-- Dependencies:
--   vgaController.vhd
--   imageDisplay.vhd
--
-- Revision:
-- Revision 0.02 - Added vgaController and imageDisplay instantiation and wiring
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port (
        i_clk_r      : in  std_logic;                     -- 系統時脈輸入 (100MHz)
        i_rst_r      : in  std_logic;                     -- 重設輸入 (高電位有效)
        o_hSync_w    : out std_logic;                     -- VGA 水平同步信號
        o_vSync_w    : out std_logic;                     -- VGA 垂直同步信號
        o_vgaRed_w   : out std_logic_vector(5 downto 0);  -- VGA 紅色輸出 (6-bit)
        o_vgaGreen_w : out std_logic_vector(5 downto 0);  -- VGA 綠色輸出 (6-bit)
        o_vgaBlue_w  : out std_logic_vector(5 downto 0)   -- VGA 藍色輸出 (6-bit)
    );
end top;

architecture Behavioral of top is

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

    component imageDisplay is
        generic (
            g_imgStartX_l : integer := 192;
            g_imgStartY_l : integer := 112;
            g_imgWidth_l  : integer := 256;
            g_imgHeight_l : integer := 256
        );
        port (
            i_pClk_r         : in  std_logic;
            i_rst_r          : in  std_logic;
            i_hSync_r        : in  std_logic;
            i_vSync_r        : in  std_logic;
            i_videoActive_r  : in  std_logic;
            i_pixelX_r       : in  std_logic_vector(9 downto 0);
            i_pixelY_r       : in  std_logic_vector(9 downto 0);
            o_hSync_w        : out std_logic;
            o_vSync_w        : out std_logic;
            o_vgaRed_w       : out std_logic_vector(5 downto 0);
            o_vgaGreen_w     : out std_logic_vector(5 downto 0);
            o_vgaBlue_w      : out std_logic_vector(5 downto 0)
        );
    end component;

    -- ========================================================================
    -- 內部訊號宣告 (Signals)
    -- ========================================================================
    -- 1. 時脈除頻邏輯：100MHz 除頻為 25MHz 像素時脈
    signal v_clkDiv_r : unsigned(1 downto 0) := (others => '0');
    signal v_pClk_w   : std_logic;

    -- 2. VGA 控制器至影像顯示子模組的接線訊號
    signal v_hSyncCtrl_w       : std_logic;
    signal v_vSyncCtrl_w       : std_logic;
    signal v_videoActiveCtrl_w : std_logic;
    signal v_pixelXCtrl_w      : std_logic_vector(9 downto 0);
    signal v_pixelYCtrl_w      : std_logic_vector(9 downto 0);

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
    -- 2. 實例化獨立 VGA 控制器模組
    -- ========================================================================
    u_vgaController : vgaController
        port map (
            i_clk_r          => v_pClk_w,
            i_rst_r          => i_rst_r,
            o_hSync_w        => v_hSyncCtrl_w,
            o_vSync_w        => v_vSyncCtrl_w,
            o_videoActive_w  => v_videoActiveCtrl_w,
            o_pixelX_w       => v_pixelXCtrl_w,
            o_pixelY_w       => v_pixelYCtrl_w
        );

    -- ========================================================================
    -- 3. 實例化影像顯示子模組
    -- ========================================================================
    u_imageDisplay : imageDisplay
        generic map (
            g_imgStartX_l => 192,
            g_imgStartY_l => 112,
            g_imgWidth_l  => 256,
            g_imgHeight_l => 256
        )
        port map (
            i_pClk_r         => v_pClk_w,
            i_rst_r          => i_rst_r,
            i_hSync_r        => v_hSyncCtrl_w,
            i_vSync_r        => v_vSyncCtrl_w,
            i_videoActive_r  => v_videoActiveCtrl_w,
            i_pixelX_r       => v_pixelXCtrl_w,
            i_pixelY_r       => v_pixelYCtrl_w,
            o_hSync_w        => o_hSync_w,
            o_vSync_w        => o_vSync_w,
            o_vgaRed_w       => o_vgaRed_w,
            o_vgaGreen_w     => o_vgaGreen_w,
            o_vgaBlue_w      => o_vgaBlue_w
        );

end Behavioral;
