library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pingpong_double_tb is
end pingpong_double_tb;

architecture behavior of pingpong_double_tb is

    -- 宣告 UUT 元件
    component pingpong_double
        Generic ( g_maxCnt : integer := 499999 );
        Port ( i_clk      : in STD_LOGIC;
               i_rst      : in STD_LOGIC;
               i_sw       : in STD_LOGIC;
               i_boardId  : in STD_LOGIC;
               io_line    : inout STD_LOGIC;
               o_led      : out STD_LOGIC_VECTOR (7 downto 0)
               );
    end component;

    -- 測試平台訊號 (小駝峰 + 命名修飾)
    signal clk_tb         : STD_LOGIC := '0';
    signal rst_tb         : STD_LOGIC := '0';
    signal swL_tb         : STD_LOGIC := '0';
    signal swR_tb         : STD_LOGIC := '0';

    -- 雙板對接共享通訊線 (單一雙向)
    signal io_line_tb     : STD_LOGIC := 'H'; -- 弱上拉，防浮空

    -- LED 觀察訊號
    signal ledL_tb        : STD_LOGIC_VECTOR(7 downto 0);
    signal ledR_tb        : STD_LOGIC_VECTOR(7 downto 0);

    -- 時脈週期常數 (100MHz = 10ns 週期)
    constant c_clkPeriod_b : time := 10 ns;

begin

    -- 實體化左板 (i_boardId = '0'，傳入 g_maxCnt => 1 用於極速模擬，接 swL_tb 模擬左按鍵)
    u_left_board : pingpong_double
        generic map (
            g_maxCnt => 1
        )
        port map (
            i_clk     => clk_tb,
            i_rst     => rst_tb,
            i_sw      => swL_tb,
            i_boardId => '0',
            io_line   => io_line_tb,
            o_led     => ledL_tb
        );

    -- 實體化右板 (i_boardId = '1'，傳入 g_maxCnt => 1 用於極速模擬，接 swR_tb 模擬右按鍵)
    u_right_board : pingpong_double
        generic map (
            g_maxCnt => 1
        )
        port map (
            i_clk     => clk_tb,
            i_rst     => rst_tb,
            i_sw      => swR_tb,
            i_boardId => '1',
            io_line   => io_line_tb,
            o_led     => ledR_tb
        );

    -- 時脈產生 Process
    CLK_GEN_P : process
    begin
        clk_tb <= '0';
        wait for c_clkPeriod_b / 2;
        clk_tb <= '1';
        wait for c_clkPeriod_b / 2;
    end process;

    -- 測試刺激產生 Process (針對 100MHz / 模擬 g_maxCnt => 1 特化時序)
    -- 系統時脈 10ns，慢速時脈 slow_clk 完整週期為 40ns。球位移一格需要 50 拍 = 2 us。
    STIMULUS_P : process
    begin
        -- 1. 系統同步重置 (高電平有效)
        rst_tb <= '1';
        wait for 200 ns;
        rst_tb <= '0';
        wait for 500 ns;

        -- 2. 左板發球 (swL_tb 按下維持 2 us，確保 100% 被 slow_clk 採樣到)
        swL_tb <= '1';
        wait for 2 us;
        swL_tb <= '0';

        -- 3. 等待球在左板由左向右移動一格到邊界 (7格 * 2us = 14 us)
        wait for 14 us;

        -- 4. 球傳遞入右板，並在右板繼續向右移動走到最右端點 (7格 * 2us = 14 us + 1us 通訊)
        wait for 15 us;

        -- 5. 右板玩家在 LED7 亮起時，按下擊球鍵擊球防守 (維持 2 us)
        swR_tb <= '1';
        wait for 2 us;
        swR_tb <= '0';

        -- 6. 右板擊球成功反彈，球在右板向左移動 (7格 * 2us = 14 us，減去按鍵期間已移動的 2 us = 12 us)
        wait for 12 us;

        -- 7. 球再次跨板進入左板，並在左板向左移動 (7格 * 2us = 14 us + 1us 通訊)
        wait for 15 us;

        -- 8. 左板玩家「漏球」(不按下 swL_tb)，等待端點 50拍 (2us) 計滿出界
        wait for 3 us;

        -- 9. 左板漏球，對手(右板)得分。進入得分過渡狀態 (比分顯示 1.0秒 = 100拍 = 4us；燈滅 0.5秒 = 50拍 = 2us)
        -- 總計 1.5秒過渡 (150拍 = 6us)。我們等待 7us 讓其過渡到輸家(左板)在起點亮球。
        wait for 7 us;

        -- 10. 輸方 (左板) 在起點點亮球後，左板玩家重新按下擊球鍵發球 (維持 2 us)
        swL_tb <= '1';
        wait for 2 us;
        swL_tb <= '0';

        -- 11. 讓球在板子中移動 5 us 以觀察是否發球成功
        wait for 5 us;

        -- 停止模擬
        assert false report "Simulation Completed Successfully!" severity failure;
        wait;
    end process;

end behavior;
