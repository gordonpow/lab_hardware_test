library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity boardController is
    Port ( i_clk      : in STD_LOGIC;  -- 系統主時脈 (50MHz)
           i_rst      : in STD_LOGIC;  -- 同步重置 (高電平有效)
           i_slowClk  : in STD_LOGIC;  -- 100Hz 同步時脈
           i_sw       : in STD_LOGIC;  -- 玩家按鍵
           i_boardId  : in STD_LOGIC;  -- 板端ID ('0'為左，'1'為右)
           i_rxReady  : in STD_LOGIC;  -- 接收完成指示
           i_rxData   : in STD_LOGIC;  -- 接收資料 ('0'為球，'1'為得分)
           o_txStart  : out STD_LOGIC;
           o_txData   : out STD_LOGIC;
           o_state    : out STD_LOGIC_VECTOR(2 downto 0);
           o_scoreL   : out STD_LOGIC_VECTOR(3 downto 0);
           o_scoreR   : out STD_LOGIC_VECTOR(3 downto 0)
           );
end boardController;

architecture Behavioral of boardController is

    -- 狀態宣告 (小駝峰命名法)
    type STATE_TYPE is (ST_IDLE, ST_MOVING_R, ST_MOVING_L, ST_PASSING, ST_WAIT_OPP, ST_LWIN, ST_RWIN, ST_GAMEOVER);
    signal r_state_r, r_state_w         : STATE_TYPE := ST_IDLE;
    signal r_prevState_r, r_prevState_w : STATE_TYPE := ST_IDLE;

    -- 球在板內位移步數 (0 到 7)
    signal r_stepCnt_r    : unsigned(2 downto 0) := "000";
    signal r_stepCnt_w    : unsigned(2 downto 0) := "000";

    -- 球在每格停留 0.5 秒 (100Hz 時脈下計數 50 拍) 的計數暫存器
    signal r_shiftTimer_r : integer range 0 to 49 := 0;
    signal r_shiftTimer_w : integer range 0 to 49 := 0;

    -- GameOver 閃爍結束自動重置計時器 (3.0秒 = 300 拍)
    signal r_gameoverTimer_r : integer range 0 to 300 := 0;
    signal r_gameoverTimer_w : integer range 0 to 300 := 0;

    -- 按鍵去彈跳與沿偵測暫存器 (系統時脈下)
    signal r_swReg_r      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_swReg_w      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_swDeb_r      : STD_LOGIC := '0';
    signal r_swDeb_w      : STD_LOGIC := '0';
    signal r_swDebPrev_r  : STD_LOGIC := '0';
    signal r_swDebPrev_w  : STD_LOGIC := '0';
    signal w_swPressed_r  : STD_LOGIC := '0';

    -- 比分暫存器
    signal r_scoreL_r     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal r_scoreL_w     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal r_scoreR_r     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal r_scoreR_w     : STD_LOGIC_VECTOR(3 downto 0) := "0000";

    -- 得分指示燈 (對應 8-bit LED)
    signal r_scoreLled_r  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_scoreLled_w  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_scoreRled_r  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal r_scoreRled_w  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- 傳送控制與輸出暫存器
    signal r_txStart_r    : STD_LOGIC := '0';
    signal r_txStart_w    : STD_LOGIC := '0';
    signal r_txData_r     : STD_LOGIC := '0';
    signal r_txData_w     : STD_LOGIC := '0';

    -- 內部狀態解碼 (對接 RX 端的解碼結果)
    signal w_rxBall_r     : STD_LOGIC := '0';
    signal w_rxScore_r    : STD_LOGIC := '0';

begin

    -- 對接解碼訊號
    w_rxBall_r  <= '1' when (i_rxReady = '1' and i_rxData = '0') else '0';
    w_rxScore_r <= '1' when (i_rxReady = '1' and i_rxData = '1') else '0';

    -- 輸出映射
    o_txStart <= r_txStart_r;
    o_txData  <= r_txData_r;
    o_scoreL  <= r_scoreL_r;
    o_scoreR  <= r_scoreR_r;

    -- 將狀態編碼成 3-bit 輸出給 displayManager
    o_state <= "000" when r_state_r = ST_IDLE else
               "001" when r_state_r = ST_MOVING_R else
               "010" when r_state_r = ST_MOVING_L else
               "011" when r_state_r = ST_PASSING else
               "100" when r_state_r = ST_WAIT_OPP else
               "101" when r_state_r = ST_LWIN else
               "110" when r_state_r = ST_RWIN else
               "111"; -- GameOver

    -- [boardController 內部的 3 個 Process]

    -- 1. KEY_DEBOUNCE: 機械按鍵去彈跳 (系統時脈下運作)
    KEY_DEBOUNCE : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_swReg_r     <= (others => '0');
            r_swDeb_r     <= '0';
        elsif rising_edge(i_clk) then
            r_swReg_r     <= r_swReg_w;
            r_swDeb_r     <= r_swDeb_w;
        end if;
    end process;

    r_swReg_w <= r_swReg_r(6 downto 0) & i_sw;
    
    r_swDeb_w <= '1' when r_swReg_r = "11111111" else
                 '0' when r_swReg_r = "00000000" else
                 r_swDeb_r;
                 
    w_swPressed_r <= '1' when (r_swDeb_r = '1' and r_swDebPrev_r = '0') else '0';

    -- 2. FSM_CTRL: 遊戲主狀態機 (100Hz 慢速時脈下運作)
    FSM_CTRL : process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_state_r         <= ST_IDLE;
            r_prevState_r     <= ST_IDLE;
            r_stepCnt_r       <= "000";
            r_shiftTimer_r    <= 0;
            r_gameoverTimer_r <= 0;
            r_txStart_r       <= '0';
            r_txData_r        <= '0';
            r_swDebPrev_r     <= '0';
        elsif rising_edge(i_slowClk) then
            r_state_r         <= r_state_w;
            r_prevState_r     <= r_prevState_w;
            r_stepCnt_r       <= r_stepCnt_w;
            r_shiftTimer_r    <= r_shiftTimer_w;
            r_gameoverTimer_r <= r_gameoverTimer_w;
            r_txStart_r       <= r_txStart_w;
            r_txData_r        <= r_txData_w;
            r_swDebPrev_r     <= r_swDebPrev_w;
        end if;
    end process;

    r_prevState_w <= r_state_r;
    r_swDebPrev_w <= r_swDeb_r;

    -- 狀態機狀態移轉與傳送啟動邏輯 (組合 Process)
    FSM_TRANSITION : process(r_state_r, r_prevState_r, i_boardId, w_swPressed_r, w_rxBall_r, w_rxScore_r, 
                             r_scoreL_r, r_scoreR_r, r_stepCnt_r, r_shiftTimer_r, r_gameoverTimer_r)
    begin
        r_state_w         <= r_state_r;
        r_stepCnt_w       <= r_stepCnt_r;
        r_shiftTimer_w    <= r_shiftTimer_r;
        r_gameoverTimer_w <= r_gameoverTimer_r;
        r_txStart_w       <= '0';
        r_txData_w        <= '0';

        case r_state_r is
            when ST_IDLE =>
                r_stepCnt_w       <= "000";
                r_shiftTimer_w    <= 0;
                r_gameoverTimer_w <= 0;
                if i_boardId = '0' then
                    if w_swPressed_r = '1' then
                        r_state_w <= ST_MOVING_R; -- 左發球往右
                    end if;
                else
                    if w_rxBall_r = '1' then
                        r_state_w <= ST_MOVING_R; -- 右板收球往右
                    end if;
                end if;
                if w_rxScore_r = '1' then
                    if i_boardId = '0' then
                        r_state_w <= ST_LWIN;  -- 收到得分信號，左贏
                    else
                        r_state_w <= ST_RWIN;  -- 收到得分信號，右贏
                    end if;
                end if;

            when ST_MOVING_R =>
                r_gameoverTimer_w <= 0;
                if r_state_r /= r_prevState_r then
                    r_stepCnt_w    <= "000";
                    r_shiftTimer_w <= 0;
                else
                    if r_stepCnt_r = 7 then
                        if i_boardId = '0' then  -- 左板移出最右端，傳送球
                            if r_shiftTimer_r = 49 then
                                r_state_w   <= ST_PASSING;
                                r_txStart_w <= '1';
                                r_txData_w  <= '0';  -- '0' 代表傳球
                            else
                                r_shiftTimer_w <= r_shiftTimer_r + 1;
                            end if;
                        else  -- 右板最右端，必須擊球
                            if w_swPressed_r = '1' then
                                r_state_w <= ST_MOVING_L; -- 擊球成功，反彈向左
                            elsif r_shiftTimer_r = 49 then
                                r_state_w   <= ST_LWIN; -- 右板漏球，左得分
                                r_txStart_w <= '1';
                                r_txData_w  <= '1'; -- 得分同步
                            else
                                r_shiftTimer_w <= r_shiftTimer_r + 1;
                            end if;
                        end if;
                    else
                        -- 移動中 (stepCnt < 7)
                        if w_swPressed_r = '1' then
                            if i_boardId = '1' then -- 右板提早擊球判定漏球
                                r_state_w   <= ST_LWIN;
                                r_txStart_w <= '1';
                                r_txData_w  <= '1';
                            end if;
                        elsif r_shiftTimer_r = 49 then
                            r_shiftTimer_w <= 0;
                            r_stepCnt_w    <= r_stepCnt_r + 1;
                        else
                            r_shiftTimer_w <= r_shiftTimer_r + 1;
                        end if;
                    end if;
                end if;

            when ST_MOVING_L =>
                r_gameoverTimer_w <= 0;
                if r_state_r /= r_prevState_r then
                    r_stepCnt_w    <= "000";
                    r_shiftTimer_w <= 0;
                else
                    if r_stepCnt_r = 7 then
                        if i_boardId = '1' then  -- 右板移出最左端，傳送球
                            if r_shiftTimer_r = 49 then
                                r_state_w   <= ST_PASSING;
                                r_txStart_w <= '1';
                                r_txData_w  <= '0';
                            else
                                r_shiftTimer_w <= r_shiftTimer_r + 1;
                            end if;
                        else  -- 左板最左端，必須擊球
                            if w_swPressed_r = '1' then
                                r_state_w <= ST_MOVING_R; -- 擊球成功，反彈向右
                            elsif r_shiftTimer_r = 49 then
                                r_state_w   <= ST_RWIN; -- 左板漏球，右得分
                                r_txStart_w <= '1';
                                r_txData_w  <= '1';
                            else
                                r_shiftTimer_w <= r_shiftTimer_r + 1;
                            end if;
                        end if;
                    else
                        -- 移動中 (stepCnt < 7)
                        if w_swPressed_r = '1' then
                            if i_boardId = '0' then -- 左板提早擊球判定漏球
                                r_state_w   <= ST_RWIN;
                                r_txStart_w <= '1';
                                r_txData_w  <= '1';
                            end if;
                        elsif r_shiftTimer_r = 49 then
                            r_shiftTimer_w <= 0;
                            r_stepCnt_w    <= r_stepCnt_r + 1;
                        else
                            r_shiftTimer_w <= r_shiftTimer_r + 1;
                        end if;
                    end if;
                end if;

            when ST_PASSING =>
                r_state_w <= ST_WAIT_OPP;

            when ST_WAIT_OPP =>
                r_stepCnt_w    <= "000";
                r_shiftTimer_w <= 0;
                if w_rxBall_r = '1' then
                    if i_boardId = '0' then
                        r_state_w <= ST_MOVING_L; -- 左板收球，往左移動
                    else
                        r_state_w <= ST_MOVING_R; -- 右板收球，往右移動
                    end if;
                elsif w_rxScore_r = '1' then
                    if i_boardId = '0' then
                        r_state_w <= ST_LWIN;  -- 收到得分信號，左贏
                    else
                        r_state_w <= ST_RWIN;  -- 收到得分信號，右贏
                    end if;
                end if;

            when ST_LWIN =>
                r_stepCnt_w    <= "000";
                r_shiftTimer_w <= 0;
                if r_scoreL_r = "1000" then -- 左方贏 (達到8分)
                    r_state_w <= ST_GAMEOVER;
                elsif i_boardId = '1' and w_swPressed_r = '1' then -- 輸家(右板)發球
                    r_state_w <= ST_MOVING_L; -- 右發球往左移
                elsif i_boardId = '0' and w_rxBall_r = '1' then -- 贏家(左板)等球
                    r_state_w <= ST_MOVING_L; -- 左板收球往左移
                end if;

            when ST_RWIN =>
                r_stepCnt_w    <= "000";
                r_shiftTimer_w <= 0;
                if r_scoreR_r = "1000" then -- 右方贏 (達到8分)
                    r_state_w <= ST_GAMEOVER;
                elsif i_boardId = '0' and w_swPressed_r = '1' then -- 輸家(左板)發球
                    r_state_w <= ST_MOVING_R; -- 左發球往右移
                elsif i_boardId = '1' and w_rxBall_r = '1' then -- 贏家(右板)等球
                    r_state_w <= ST_MOVING_R; -- 右板收球往右移
                end if;

            when ST_GAMEOVER =>
                r_stepCnt_w    <= "000";
                r_shiftTimer_w <= 0;
                if r_state_r /= r_prevState_r then
                    r_gameoverTimer_w <= 0;
                elsif r_gameoverTimer_r = 299 then -- 閃爍 3.0 秒結束
                    r_gameoverTimer_w <= 0;
                    if r_scoreL_r = "1000" then
                        r_state_w <= ST_LWIN; -- 遊戲重新開始，由輸方(右板)發球
                    else
                        r_state_w <= ST_RWIN; -- 遊戲重新開始，由輸方(left板)發球
                    end if;
                else
                    r_gameoverTimer_w <= r_gameoverTimer_r + 1;
                end if;

            when others =>
                r_state_w <= ST_IDLE;
        end case;
    end process;

    -- 3. SCORE_CNT: 得分計數暫存器 (100Hz 慢速時脈下運作)
    SCORE_CNT : process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_scoreL_r    <= "0000";
            r_scoreR_r    <= "0000";
            r_scoreLled_r <= (others => '0');
            r_scoreRled_r <= (others => '0');
        elsif rising_edge(i_slowClk) then
            r_scoreL_r    <= r_scoreL_w;
            r_scoreR_r    <= r_scoreR_w;
            r_scoreLled_r <= r_scoreLled_w;
            r_scoreRled_r <= r_scoreRled_w;
        end if;
    end process;

    process(r_state_r, r_prevState_r, r_scoreL_r, r_scoreR_r, r_scoreLled_r, r_scoreRled_r, r_gameoverTimer_r)
    begin
        r_scoreL_w    <= r_scoreL_r;
        r_scoreR_w    <= r_scoreR_r;
        r_scoreLled_w <= r_scoreLled_r;
        r_scoreRled_w <= r_scoreRled_r;

        -- 判定左贏的狀態轉移邊緣，累加分數
        if r_state_r = ST_LWIN and r_prevState_r /= ST_LWIN then
            if r_scoreL_r < "1000" then
                r_scoreL_w <= std_logic_vector(unsigned(r_scoreL_r) + 1);
            end if;
        end if;

        -- 判定右贏的狀態轉移邊緣，累加分數
        if r_state_r = ST_RWIN and r_prevState_r /= ST_RWIN then
            if r_scoreR_r < "1000" then
                r_scoreR_w <= std_logic_vector(unsigned(r_scoreR_r) + 1);
            end if;
        end if;

        -- 當 GameOver 閃爍完畢自動重新開始時，將雙方分數歸零！
        if r_state_r = ST_GAMEOVER and r_gameoverTimer_r = 299 then
            r_scoreL_w <= "0000";
            r_scoreR_w <= "0000";
        end if;

        -- 得分分數轉換成 8-bit LED 比分條
        case r_scoreL_w is
            when "0001" => r_scoreLled_w <= "00000001";
            when "0010" => r_scoreLled_w <= "00000011";
            when "0011" => r_scoreLled_w <= "00000111";
            when "0100" => r_scoreLled_w <= "00001111";
            when "0101" => r_scoreLled_w <= "00011111";
            when "0110" => r_scoreLled_w <= "00111111";
            when "0111" => r_scoreLled_w <= "01111111";
            when "1000" => r_scoreLled_w <= "11111111";
            when others => r_scoreLled_w <= "00000000";
        end case;

        case r_scoreR_w is
            when "0001" => r_scoreRled_w <= "10000000";
            when "0010" => r_scoreRled_w <= "11000000";
            when "0011" => r_scoreRled_w <= "11100000";
            when "0100" => r_scoreRled_w <= "11110000";
            when "0101" => r_scoreRled_w <= "11111000";
            when "0110" => r_scoreRled_w <= "11111100";
            when "0111" => r_scoreRled_w <= "11111110";
            when "1000" => r_scoreRled_w <= "11111111";
            when others => r_scoreRled_w <= "00000000";
        end case;
    end process;

end Behavioral;
