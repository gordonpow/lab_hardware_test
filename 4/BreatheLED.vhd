library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BreatheLED is
    Port (
        i_clk        : in  STD_LOGIC;
        i_rst        : in  STD_LOGIC;
        i_en         : in  STD_LOGIC;
        o_led        : out STD_LOGIC
    );
end BreatheLED;

architecture Behavioral of BreatheLED is

    -- PWM 狀態機定義 (基於第三題)
    type StateType is (Idle, HighState, LowState);
    signal CurrentState, NextState : StateType;
    
    -- PWM 計數器 (基於第三題)
    signal r_CntHigh : UNSIGNED(7 downto 0); -- 等同於 Cnt1
    signal r_CntLow  : UNSIGNED(7 downto 0); -- 等同於 Cnt2
    
    -- 動態 Limit (呼吸效果關鍵)
    signal r_LimitHigh : UNSIGNED(7 downto 0);
    signal r_LimitLow  : UNSIGNED(7 downto 0);
    
    -- 呼吸調變計數器 (慢速計數器，用於改變亮度)
    signal r_BreathCounter : UNSIGNED(15 downto 0);
    signal r_BreathDir     : STD_LOGIC; -- 0: 變亮, 1: 變暗
    
    -- 定義 PWM 週期，假設總和為 255
    constant PWM_PERIOD : UNSIGNED(7 downto 0) := to_unsigned(255, 8);

begin

    -----------------------------------------------------
    -- PWM 核心狀態機 (Current State Register)
    -----------------------------------------------------
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            CurrentState <= Idle;
        elsif rising_edge(i_clk) then
            if i_en = '0' then
                CurrentState <= Idle;
            else
                CurrentState <= NextState;
            end if;
        end if;
    end process;

    -----------------------------------------------------
    -- PWM 核心狀態機 (Next State Logic)
    -----------------------------------------------------
    process (CurrentState, i_en, r_CntHigh, r_CntLow, r_LimitHigh, r_LimitLow)
    begin
        NextState <= CurrentState;
        
        case CurrentState is
            when Idle =>
                if i_en = '1' then
                    NextState <= HighState;
                else
                    NextState <= Idle;
                end if;

            when HighState =>
                -- 當高電位計數達到極限，切換到低電位
                if r_CntHigh >= r_LimitHigh then
                    if r_LimitLow = 0 then -- 如果低電位時間為0，直接循環高電位
                         NextState <= HighState;
                    else
                         NextState <= LowState;
                    end if;
                end if;

            when LowState =>
                -- 當低電位計數達到極限，切換到高電位
                if r_CntLow >= r_LimitLow then
                    if r_LimitHigh = 0 then -- 如果高電位時間為0，直接循環低電位
                         NextState <= LowState;
                    else
                         NextState <= HighState;
                    end if;
                end if;
                
            when others =>
                NextState <= Idle;
        end case;
    end process;

    -----------------------------------------------------
    -- PWM 計數邏輯 (Counter Logic)
    -----------------------------------------------------
    -- 控制 r_CntHigh
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_CntHigh <= (others => '0');
        elsif rising_edge(i_clk) then
            if CurrentState = HighState then
                if r_CntHigh >= r_LimitHigh then
                    r_CntHigh <= to_unsigned(1, 8);
                else
                    r_CntHigh <= r_CntHigh + 1;
                end if;
            else
                r_CntHigh <= (others => '0');
            end if;
        end if;
    end process;

    -- 控制 r_CntLow
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_CntLow <= (others => '0');
        elsif rising_edge(i_clk) then
            if CurrentState = LowState then
                if r_CntLow >= r_LimitLow then
                    r_CntLow <= to_unsigned(1, 8);
                else
                    r_CntLow <= r_CntLow + 1;
                end if;
            else
                r_CntLow <= (others => '0');
            end if;
        end if;
    end process;

    -----------------------------------------------------
    -- 呼吸調變邏輯 (Breathing Modulation)
    -----------------------------------------------------
    -- 控制呼吸計數器 (速度控制)
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_BreathCounter <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_en = '1' then
                r_BreathCounter <= r_BreathCounter + 1;
            else
                r_BreathCounter <= (others => '0');
            end if;
        end if;
    end process;

    -- 控制呼吸方向
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_BreathDir <= '0';
        elsif rising_edge(i_clk) then
            if i_en = '1' and r_BreathCounter = 0 then
                if r_LimitHigh = PWM_PERIOD then
                    r_BreathDir <= '1'; -- 開始變暗
                elsif r_LimitHigh = 0 then
                    r_BreathDir <= '0'; -- 開始變亮
                end if;
            end if;
        end if;
    end process;

    -- 控制動態 Limit (亮度調整)
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_LimitHigh <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_en = '1' and r_BreathCounter = 0 then
                if r_BreathDir = '0' then
                    if r_LimitHigh < PWM_PERIOD then
                        r_LimitHigh <= r_LimitHigh + 1;
                    end if;
                else
                    if r_LimitHigh > 0 then
                        r_LimitHigh <= r_LimitHigh - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- r_LimitLow 為 PWM_PERIOD - r_LimitHigh
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_LimitLow <= PWM_PERIOD;
        elsif rising_edge(i_clk) then
            r_LimitLow <= PWM_PERIOD - r_LimitHigh;
        end if;
    end process;

    -----------------------------------------------------
    -- 輸出分配
    -----------------------------------------------------
    -- 1數的時候輸出1 (HighState)，換另外一個計數器的時候輸出0 (LowState)
    process (CurrentState)
    begin
        if CurrentState = HighState then
            o_led <= '1';
        else
            o_led <= '0';
        end if;
    end process;

end Behavioral;
