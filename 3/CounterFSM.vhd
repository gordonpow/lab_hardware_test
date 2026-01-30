library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CounterFSM is
    Port (
        i_clk        : in  STD_LOGIC;
        i_rst        : in  STD_LOGIC;
        i_en         : in  STD_LOGIC;
        i_Cnt1_lim_up: in  STD_LOGIC_VECTOR(7 downto 0); -- Changed to 8-bit Vector
        i_Cnt2_lim_up: in  STD_LOGIC_VECTOR(7 downto 0); -- Changed to 8-bit Vector
        o_Cnt1_q     : out STD_LOGIC_VECTOR(7 downto 0);
        o_Cnt2_q     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end CounterFSM;

architecture Behavioral of CounterFSM is

    type StateType is (Idle, Cnt1Count, Cnt2Count);
    signal CurrentState, NextState : StateType;
    
    signal r_Cnt1 : UNSIGNED(7 downto 0);
    signal r_Cnt2 : UNSIGNED(7 downto 0);

begin

    -- State Register Process
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            CurrentState <= Idle;
        elsif rising_edge(i_clk) then
            if i_en = '0' then
                -- Global Idle override: If i_en is 0, force Idle state
                -- This satisfies "When i_en triggers set state to idle" (interpreted as Disable)
                CurrentState <= Idle;
            else
                CurrentState <= NextState;
            end if;
        end if;
    end process;

    -- Next State Logic
    process (CurrentState, i_en, i_Cnt1_lim_up, i_Cnt2_lim_up, r_Cnt1, r_Cnt2)
    begin
        NextState <= CurrentState;
        
        case CurrentState is
            when Idle =>
                -- Wait for Enable (handled by State Register, effectively)
                -- If i_en='1' (and not overridden), we start.
                -- Since State Register forces Idle if en=0, here we just say:
                if i_en = '1' then
                    NextState <= Cnt1Count;
                else
                    NextState <= Idle;
                end if;

            when Cnt1Count =>
                -- Check against 8-bit limit
                if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
                    NextState <= Cnt2Count;
                end if;

            when Cnt2Count =>
                -- Check against 8-bit limit
                if r_Cnt2 >= unsigned(i_Cnt2_lim_up) then
                    NextState <= Cnt1Count;
                end if;
                
            when others =>
                NextState <= Idle;
        end case;
    end process;

    -- Counter Logic Process
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_Cnt1 <= (others => '0');
            r_Cnt2 <= (others => '0');
        elsif rising_edge(i_clk) then
            -- Check for Global Disable/Idle Reset
            if i_en = '0' or CurrentState = Idle then 
                r_Cnt1 <= (others => '0');
                r_Cnt2 <= (others => '0');
            else
                -- Active Counter Logic
                if CurrentState = Cnt1Count then
                    -- Increment Cnt1
                    if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
                        -- If limit reached, the FSM *will* transition next cycle.
                        -- We can hold, reset, or wrap. 
                        -- Per requirement "Set state to Cnt2... Reset Cnt1".
                        -- The reset happens naturally when CurrentState becomes Cnt2Count (see 'else' block).
                        -- So here we just increment or hold? 
                        -- Let's allow it to hit the limit value exactly (>= check covers it).
                        -- If we increment here, it might go Limit+1 for one cycle before transition.
                        -- Usually "Count to Limit" implies it reaches Limit, then Reset.
                        
                        -- To ensure CLEAN reset on transition, we rely on the logic below (Active Cnt2 -> Reset Cnt1).
                        -- Just increment.
                        r_Cnt1 <= r_Cnt1 + 1;
                    else
                         r_Cnt1 <= r_Cnt1 + 1;
                    end if;
                    
                    r_Cnt2 <= (others => '0');
                    
                elsif CurrentState = Cnt2Count then
                    if r_Cnt2 >= unsigned(i_Cnt2_lim_up) then
                         r_Cnt2 <= r_Cnt2 + 1;
                    else
                         r_Cnt2 <= r_Cnt2 + 1;
                    end if;
                    
                    r_Cnt1 <= (others => '0');
                else
                    r_Cnt1 <= (others => '0');
                    r_Cnt2 <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- Output Assignments
    o_Cnt1_q <= STD_LOGIC_VECTOR(r_Cnt1);
    o_Cnt2_q <= STD_LOGIC_VECTOR(r_Cnt2);

end Behavioral;
