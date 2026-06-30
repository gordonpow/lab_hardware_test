library ieee;
use ieee.std_logic_1164.all;

entity pongGameTop_tb is
end entity pongGameTop_tb;

architecture sim of pongGameTop_tb is

    -- 宣告元件連接埠信號 (符合規範)
    signal v_clk_r       : std_logic := '0';
    signal v_rst_r       : std_logic := '1';
    signal v_leftUp_r    : std_logic := '0';
    signal v_leftDown_r  : std_logic := '0';
    signal v_rightUp_r   : std_logic := '0';
    signal v_rightDown_r : std_logic := '0';

    signal v_hSync_w     : std_logic;
    signal v_vSync_w     : std_logic;
    signal v_vgaRed_w    : std_logic_vector(3 downto 0);
    signal v_vgaGreen_w  : std_logic_vector(3 downto 0);
    signal v_vgaBlue_w   : std_logic_vector(3 downto 0);

    -- 100 MHz 時脈週期定義 (10 ns)
    constant c_clkPeriod_l : time := 10 ns;

begin

    -- 實例化待測元件 (UUT)
    uut: entity work.pongGameTop
        port map (
            i_clk        => v_clk_r,
            i_rst        => v_rst_r,
            i_leftUp     => v_leftUp_r,
            i_leftDown   => v_leftDown_r,
            i_rightUp    => v_rightUp_r,
            i_rightDown  => v_rightDown_r,
            o_hSync      => v_hSync_w,
            o_vSync      => v_vSync_w,
            o_vgaRed_b   => v_vgaRed_w,
            o_vgaGreen_b => v_vgaGreen_w,
            o_vgaBlue_b  => v_vgaBlue_w
        );

    -- 產生系統時脈 (100 MHz)
    clk_process : process
    begin
        v_clk_r <= '0';
        wait for c_clkPeriod_l / 2;
        v_clk_r <= '1';
        wait for c_clkPeriod_l / 2;
    end process;

    -- 測試激勵訊號產生
    stim_process : process
    begin
        -- 1. 系統重置
        v_rst_r <= '1';
        wait for 100 ns;
        v_rst_r <= '0';
        wait for 100 ns;

        -- 2. 模擬持續按下按鍵以啟動遊戲與移動擋板
        -- 由於遊戲物理位置是在 vSync 下降沿 (約 15.68 ms) 更新，
        -- 按鍵必須維持為 '1' 直到跨越此更新點。
        v_leftUp_r    <= '1';
        v_rightDown_r <= '1';

        -- 讓模擬運行足夠時間 (20 ms) 以越過第一個 vSync 下降沿 (15.68 ms)
        wait for 20 ms;
        v_leftUp_r    <= '0';
        v_rightDown_r <= '0';
        wait for 1 ms;

        -- 結束模擬
        assert false report "Simulation Finished" severity failure;
        wait;
    end process;

end architecture sim;
