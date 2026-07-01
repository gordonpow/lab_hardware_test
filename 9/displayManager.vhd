library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity displayManager is
    Port ( i_slowClk  : in STD_LOGIC;
           i_rst      : in STD_LOGIC;
           i_state    : in STD_LOGIC_VECTOR(2 downto 0);
           i_scoreL   : in STD_LOGIC_VECTOR(3 downto 0);
           i_scoreR   : in STD_LOGIC_VECTOR(3 downto 0);
           i_boardId  : in STD_LOGIC;
           o_led      : out STD_LOGIC_VECTOR(7 downto 0)
           );
end displayManager;

architecture Behavioral of displayManager is

    -- LED 燈號位移暫存器
    signal r_ledReg_r     : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal r_ledReg_w     : STD_LOGIC_VECTOR(7 downto 0) := "00000000";

    -- 狀態延遲暫存器
    signal r_stateDelay_r : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal r_stateDelay_w : STD_LOGIC_VECTOR(2 downto 0) := "000";

    -- 得分狀態下 1.5秒 (150拍 100Hz) 的三段式顯示計時器暫存器
    signal r_scoreTimer_r : integer range 0 to 150 := 150;
    signal r_scoreTimer_w : integer range 0 to 150 := 150;

    -- LED 移位 0.5秒計數器 (100Hz 下計數 50 拍)
    signal r_shiftTimer_r : integer range 0 to 49 := 0;
    signal r_shiftTimer_w : integer range 0 to 49 := 0;

    -- GameOver 贏家 LED 閃爍計數器 (3.0秒 = 300 拍)
    signal r_gameoverTimer_r : integer range 0 to 300 := 0;
    signal r_gameoverTimer_w : integer range 0 to 300 := 0;

    -- 得分對應 LED 燈號
    signal w_scoreLled    : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    signal w_scoreRled    : STD_LOGIC_VECTOR(7 downto 0) := "00000000";

begin

    -- 狀態延遲暫存器與計時器暫存器處理 (慢速時脈)
    process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_stateDelay_r    <= "000";
            r_scoreTimer_r    <= 150;
            r_shiftTimer_r    <= 0;
            r_gameoverTimer_r <= 0;
        elsif rising_edge(i_slowClk) then
            r_stateDelay_r    <= r_stateDelay_w;
            r_scoreTimer_r    <= r_scoreTimer_w;
            r_shiftTimer_r    <= r_shiftTimer_w;
            r_gameoverTimer_r <= r_gameoverTimer_w;
        end if;
    end process;
    
    r_stateDelay_w <= i_state;

    -- 三段式得分計時組合邏輯 (顯示分數 1.0秒 -> 燈全滅 0.5秒 -> 顯示發球球位)
    process(i_state, r_stateDelay_r, r_scoreTimer_r)
    begin
        r_scoreTimer_w <= r_scoreTimer_r;
        if i_state = "101" or i_state = "110" then -- ST_LWIN 或 ST_RWIN
            if i_state /= r_stateDelay_r then
                r_scoreTimer_w <= 150; -- 剛進入得分狀態，重置為 150 拍 (1.5秒)
            elsif r_scoreTimer_r > 0 then
                r_scoreTimer_w <= r_scoreTimer_r - 1;
            end if;
        else
            r_scoreTimer_w <= 150;
        end if;
    end process;

    -- 0.5秒位移計時組合邏輯
    process(i_state, r_stateDelay_r, r_shiftTimer_r)
    begin
        r_shiftTimer_w <= r_shiftTimer_r;
        if i_state = "001" or i_state = "010" then
            if i_state /= r_stateDelay_r then
                r_shiftTimer_w <= 0;
            elsif r_shiftTimer_r = 49 then
                r_shiftTimer_w <= 0;
            else
                r_shiftTimer_w <= r_shiftTimer_r + 1;
            end if;
        else
            r_shiftTimer_w <= 0;
        end if;
    end process;

    -- GameOver 閃爍計時組合邏輯
    process(i_state, r_stateDelay_r, r_gameoverTimer_r)
    begin
        r_gameoverTimer_w <= r_gameoverTimer_r;
        if i_state = "111" then
            if i_state /= r_stateDelay_r then
                r_gameoverTimer_w <= 0;
            elsif r_gameoverTimer_r = 299 then
                r_gameoverTimer_w <= 0;
            else
                r_gameoverTimer_w <= r_gameoverTimer_r + 1;
            end if;
        else
            r_gameoverTimer_w <= 0;
        end if;
    end process;

    -- 1. LED_DRV: LED 燈號位移驅動 (慢速時脈下運作)
    LED_DRV : process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_ledReg_r <= "00000000";
        elsif rising_edge(i_slowClk) then
            r_ledReg_r <= r_ledReg_w;
        end if;
    end process;

    process(i_state, r_stateDelay_r, r_ledReg_r, i_boardId, r_shiftTimer_r)
    begin
        r_ledReg_w <= r_ledReg_r;
        case i_state is
            when "000" => -- ST_IDLE
                if i_boardId = '0' then
                    r_ledReg_w <= "00000001"; -- 左板發球起點 (物理最左端 LED0)
                else
                    r_ledReg_w <= "00000000"; -- 右板預設無球
                end if;

            when "001" => -- ST_MOVING_R (往右移)
                if i_state /= r_stateDelay_r then
                    -- 剛進入，往右移起點皆為 LED0 (物理最左端)
                    r_ledReg_w <= "00000001";
                elsif r_shiftTimer_r = 49 then
                    -- 只有在 0.5 秒計時計滿時，才執行左移位 (LED0 -> LED7)
                    r_ledReg_w(7 downto 1) <= r_ledReg_r(6 downto 0);
                    r_ledReg_w(0)          <= '0';
                end if;

            when "010" => -- ST_MOVING_L (往左移)
                if i_state /= r_stateDelay_r then
                    -- 剛進入，往左移起點皆為 LED7 (物理最右端)
                    r_ledReg_w <= "10000000";
                elsif r_shiftTimer_r = 49 then
                    -- 只有在 0.5 秒計時計滿時，才執行右移位 (LED7 -> LED0)
                    r_ledReg_w(7)          <= '0';
                    r_ledReg_w(6 downto 0) <= r_ledReg_r(7 downto 1);
                end if;

            when "011" | "100" => -- ST_PASSING, ST_WAIT_OPP
                r_ledReg_w <= "00000000"; -- 球已出界

            when others =>
                r_ledReg_w <= "00000000";
        end case;
    end process;

    -- 2. SCORE_DRV: 得分計數轉換至得分指示燈 (純組合邏輯，作為組合 Process)
    SCORE_DRV : process(i_scoreL, i_scoreR)
    begin
        case i_scoreL is
            when "0001" => w_scoreLled <= "00000001";
            when "0010" => w_scoreLled <= "00000011";
            when "0011" => w_scoreLled <= "00000111";
            when "0100" => w_scoreLled <= "00001111";
            when "0101" => w_scoreLled <= "00011111";
            when "0110" => w_scoreLled <= "00111111";
            when "0111" => w_scoreLled <= "01111111";
            when "1000" => w_scoreLled <= "11111111";
            when others => w_scoreLled <= "00000000";
        end case;

        case i_scoreR is
            when "0001" => w_scoreRled <= "10000000"; -- 1分亮 LED7
            when "0010" => w_scoreRled <= "11000000"; -- 2分亮 LED7..6
            when "0011" => w_scoreRled <= "11100000"; -- 3分亮 LED7..5
            when "0100" => w_scoreRled <= "11110000"; -- 4分亮 LED7..4
            when "0101" => w_scoreRled <= "11111000"; -- 5分亮 LED7..3
            when "0110" => w_scoreRled <= "11111100"; -- 6分亮 LED7..2
            when "0111" => w_scoreRled <= "11111110"; -- 7分亮 LED7..1
            when "1000" => w_scoreRled <= "11111111"; -- 8分亮 LED7..0 (全亮)
            when others => w_scoreRled <= "00000000";
        end case;
    end process;

    -- 3. LED_MUX: 多工選擇輸出控制 (組合 Process)
    LED_MUX : process(i_state, r_ledReg_r, w_scoreLled, w_scoreRled, i_boardId, r_scoreTimer_r, 
                      r_gameoverTimer_r, i_scoreL, i_scoreR)
    begin
        case i_state is
            when "001" | "010" =>
                o_led <= r_ledReg_r; -- 顯示位移球位
                
            when "101" => -- ST_LWIN (左板贏，右板輸，右板發球)
                if r_scoreTimer_r > 50 then
                    -- [階段1] 剛進入得分 1.0秒內顯示雙方分數
                    if i_boardId = '0' then
                        o_led <= w_scoreLled;
                    else
                        o_led <= w_scoreRled;
                    end if;
                elsif r_scoreTimer_r > 0 then
                    -- [階段2] 隨後 0.5秒燈全滅
                    o_led <= "00000000";
                else
                    -- [階段3] 1.5秒後，發球方(右板)在起點顯示球
                    if i_boardId = '1' then
                        o_led <= "10000000"; -- 右板發球起點 (物理最右端 LED7)
                    else
                        o_led <= "00000000"; -- 左板不顯示球
                    end if;
                end if;
                
            when "110" => -- ST_RWIN (右板贏，左板輸，左板發球)
                if r_scoreTimer_r > 50 then
                    -- [階段1] 剛進入得分 1.0秒內顯示雙方分數
                    if i_boardId = '0' then
                        o_led <= w_scoreLled;
                    else
                        o_led <= w_scoreRled;
                    end if;
                elsif r_scoreTimer_r > 0 then
                    -- [階段2] 隨後 0.5秒燈全滅
                    o_led <= "00000000";
                else
                    -- [階段3] 1.5秒後，發球方(左板)在起點顯示球
                    if i_boardId = '0' then
                        o_led <= "00000001"; -- 左板發球起點 (物理最左端 LED0)
                    else
                        o_led <= "00000000"; -- 右板不顯示球
                    end if;
                end if;
                
            when "111" => -- ST_GAMEOVER
                if i_scoreL = "1000" then -- 左板贏
                    if i_boardId = '0' then
                        -- 左板 (贏家) 閃爍：50拍亮、50拍滅
                        if (r_gameoverTimer_r / 50) rem 2 = 0 then
                            o_led <= "11111111";
                        else
                            o_led <= "00000000";
                        end if;
                    else
                        -- 右板 (輸家) 全滅
                        o_led <= "00000000";
                    end if;
                else -- 右板贏
                    if i_boardId = '1' then
                        -- 右板 (贏家) 閃爍
                        if (r_gameoverTimer_r / 50) rem 2 = 0 then
                            o_led <= "11111111";
                        else
                            o_led <= "00000000";
                        end if;
                    else
                        -- 左板 (輸家) 全滅
                        o_led <= "00000000";
                    end if;
                end if;
                
            when others =>
                o_led <= r_ledReg_r;
        end case;
    end process;

end Behavioral;
