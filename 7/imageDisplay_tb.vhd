----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    2026/06/30
-- Design Name:    VGA Image Display System Testbench
-- Module Name:    imageDisplay_tb - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--   VGA 影像顯示系統測試平台 (VHDL 版本)
--
-- Dependencies:
--   imageDisplay.vhd
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity imageDisplay_tb is
end imageDisplay_tb;

architecture Behavioral of imageDisplay_tb is

    -- ========================================================================
    -- 待測元件宣告 (UUT)
    -- ========================================================================
    component imageDisplay is
        generic (
            g_imgStartX_l : integer := 192;
            g_imgStartY_l : integer := 112;
            g_imgWidth_l  : integer := 256;
            g_imgHeight_l : integer := 256
        );
        port (
            i_clk_r      : in  std_logic;
            i_rst_r      : in  std_logic;
            o_hSync_w    : out std_logic;
            o_vSync_w    : out std_logic;
            o_vgaRed_w   : out std_logic_vector(5 downto 0);
            o_vgaGreen_w : out std_logic_vector(5 downto 0);
            o_vgaBlue_w  : out std_logic_vector(5 downto 0)
        );
    end component;

    -- ========================================================================
    -- 測試信號宣告 (Signals)
    -- ========================================================================
    signal v_clk_r      : std_logic := '0';
    signal v_rst_r      : std_logic := '1';
    signal v_hSync_w    : std_logic;
    signal v_vSync_w    : std_logic;
    signal v_vgaRed_w   : std_logic_vector(5 downto 0);
    signal v_vgaGreen_w : std_logic_vector(5 downto 0);
    signal v_vgaBlue_w  : std_logic_vector(5 downto 0);

    -- 系統主時脈週期 (100MHz = 10ns)
    constant c_clkPeriod_l : time := 10 ns;

begin

    -- ========================================================================
    -- 實例化待測模組 (UUT)
    -- ========================================================================
    uut : imageDisplay
        generic map (
            g_imgStartX_l => 192,
            g_imgStartY_l => 112,
            g_imgWidth_l  => 256,
            g_imgHeight_l => 256
        )
        port map (
            i_clk_r      => v_clk_r,
            i_rst_r      => v_rst_r,
            o_hSync_w    => v_hSync_w,
            o_vSync_w    => v_vSync_w,
            o_vgaRed_w   => v_vgaRed_w,
            o_vgaGreen_w => v_vgaGreen_w,
            o_vgaBlue_w  => v_vgaBlue_w
        );

    -- ========================================================================
    -- 時脈產生產生器 (100MHz)
    -- ========================================================================
    CLK_GEN: process
    begin
        v_clk_r <= '0';
        wait for c_clkPeriod_l / 2;
        v_clk_r <= '1';
        wait for c_clkPeriod_l / 2;
    end process CLK_GEN;

    -- ========================================================================
    -- 測試激勵與結果報告控制
    -- ========================================================================
    STIMULUS: process
    begin
        -- 初始化重設，持續 100ns
        v_rst_r <= '1';
        wait for 100 ns;
        v_rst_r <= '0';
        
        report "==================================================" severity note;
        report "VGA Image Display System Simulation Start..." severity note;
        report "==================================================" severity note;

        -- 模擬運行 150000ns (足以觀察多個水平同步訊號的切換)
        wait for 150000 ns;

        report "Simulation finished. Please check HSync, VSync and color outputs in waveform." severity note;
        report "Current HSync = " & std_logic'image(v_hSync_w) & ", VSync = " & std_logic'image(v_vSync_w) severity note;
        report "==================================================" severity note;
        
        -- 結束模擬
        assert false report "Simulation finished successfully" severity failure;
        wait;
    end process STIMULUS;

    -- ========================================================================
    -- 監控水平同步訊號的改變
    -- ========================================================================
    MONITOR: process(v_hSync_w)
    begin
        if rising_edge(v_hSync_w) then
            report "HSync Rising Edge (Sync Pulse End)" severity note;
        elsif falling_edge(v_hSync_w) then
            report "HSync Falling Edge (Sync Pulse Start)" severity note;
        end if;
    end process MONITOR;

end Behavioral;
