library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Main_FSM_Counter is
    Generic (
        DATA_WIDTH : integer := 8
    );
    Port (
        i_clk         : in  STD_LOGIC;
        i_res         : in  STD_LOGIC;
        i_en_2hz      : in  STD_LOGIC; -- 來自除頻器的致能訊號
        
        -- 控制介面
        i_en          : in  STD_LOGIC;
        i_load        : in  STD_LOGIC;
        i_up_down     : in  STD_LOGIC;
        i_d           : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        i_limit_upper : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        i_limit_lower : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
        
        o_restart_div : out STD_LOGIC; -- 輸出給除頻器，要求重新計時
        o_q           : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
    );
end Main_FSM_Counter;

architecture Behavioral of Main_FSM_Counter is
    -- 狀態機定義
    type state_type is (S_IDLE, S_LOAD, S_COUNT_UP, S_COUNT_DOWN);
    signal current_state, next_state : state_type;
    
    signal CountReg : UNSIGNED(DATA_WIDTH - 1 downto 0);
begin

    -- 狀態暫存器 (State Register)
    process(i_clk, i_res)
    begin
        if i_res = '1' then
            current_state <= S_IDLE;
        elsif rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;

    -- 下一個狀態邏輯 (Next State Logic)
    process(current_state, i_en, i_load, i_up_down)
    begin
        -- 預設狀態保持不變
        next_state <= current_state;
        
        case current_state is
            when S_IDLE =>
                if i_load = '1' then
                    next_state <= S_LOAD;
                elsif i_en = '1' then
                    if i_up_down = '1' then
                        next_state <= S_COUNT_UP;
                    else
                        next_state <= S_COUNT_DOWN;
                    end if;
                end if;
                
            when S_LOAD =>
                if i_load = '0' then
                    if i_en = '1' then
                        if i_up_down = '1' then next_state <= S_COUNT_UP;
                        else next_state <= S_COUNT_DOWN; end if;
                    else
                        next_state <= S_IDLE;
                    end if;
                end if;
                
            when S_COUNT_UP =>
                if i_load = '1' then
                    next_state <= S_LOAD;
                elsif i_en = '0' then
                    next_state <= S_IDLE;
                elsif i_up_down = '0' then
                    next_state <= S_COUNT_DOWN;
                end if;
                
            when S_COUNT_DOWN =>
                if i_load = '1' then
                    next_state <= S_LOAD;
                elsif i_en = '0' then
                    next_state <= S_IDLE;
                elsif i_up_down = '1' then
                    next_state <= S_COUNT_UP;
                end if;
                
            when others =>
                next_state <= S_IDLE;
        end case;
    end process;

    -- 動作輸出邏輯與計數器更新
    process(i_clk, i_res)
    begin
        if i_res = '1' then
        elsif rising_edge(i_clk) then
            o_restart_div <= '0'; -- 預設不重新計時
            
            -- 當狀態機進入 LOAD，或是狀態發生切換時 (例如從 IDLE 進入 COUNT，或 UP 變 DOWN)
            if next_state /= current_state then
                o_restart_div <= '1'; -- 通知除頻器歸零
            end if;

            -- 根據目前狀態執行計數動作
            case current_state is
                when S_LOAD =>
                    CountReg <= unsigned(i_d);
                    
                when S_COUNT_UP =>
                    -- 當發生狀態切換的瞬間(馬上觸發)，或是收到 2Hz 脈波時計數
                    if (next_state /= current_state) or (i_en_2hz = '1') then
                        if CountReg >= unsigned(i_limit_upper) then
                            CountReg <= unsigned(i_limit_lower);
                        else
                            CountReg <= CountReg + 1;
                        end if;
                    end if;
                    
                when S_COUNT_DOWN =>
                    if (next_state /= current_state) or (i_en_2hz = '1') then
                        if CountReg <= unsigned(i_limit_lower) then
                            CountReg <= unsigned(i_limit_upper);
                        else
                            CountReg <= CountReg - 1;
                        end if;
                    end if;
                    
                when S_IDLE =>
                    -- 保持原值
                    null;
            end case;
        end if;
    end process;

    o_q <= std_logic_vector(CountReg);

end Behavioral;