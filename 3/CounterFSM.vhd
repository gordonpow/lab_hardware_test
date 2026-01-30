library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CounterFSM is
    Port (
        i_clk        : in  STD_LOGIC;
        i_rst        : in  STD_LOGIC;
        i_en         : in  STD_LOGIC;
        i_Cnt1_lim_up: in  STD_LOGIC;
        i_Cnt2_lim_up: in  STD_LOGIC;
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
            CurrentState <= NextState;
        end if;
    end process;

    -- Next State Logic
    process (CurrentState, i_en, i_Cnt1_lim_up, i_Cnt2_lim_up)
    begin
        NextState <= CurrentState;
        
        case CurrentState is
            when Idle =>
                if i_en = '1' then
                    NextState <= Cnt1Count;
                else
                    NextState <= Idle;
                end if;

            when Cnt1Count =>
                if i_Cnt1_lim_up = '1' then
                    NextState <= Cnt2Count;
                end if;

            when Cnt2Count =>
                if i_Cnt2_lim_up = '1' then
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
            -- Default behavior: Reset counters if not in their active state
            -- This handles the "Reset CntX" requirement when switching states
            
            -- Counter 1 Control
            if CurrentState = Cnt1Count then
                -- Check limit here to avoid counting past limit if limit is derived combinatorially
                -- However, FSM switches state on limit. 
                -- If we are in Cnt1Count and limit is high, value is already at limit (presumably).
                -- We just increment if we are staying in the state.
                -- But since NextState logic handles transition, we can just check if we are STAYING in Cnt1Count?
                -- Or simply: if in Cnt1Count, increment. The state transition will kill it next cycle.
                -- But wait, if Limit is reached, we want to STOP incrementing?
                -- User: "Cnt1 counts to limit value... set state... reset Cnt1".
                -- If limit is high, we transition. Next cycle CurrentState is Cnt2Count.
                -- In Cnt2Count, r_Cnt1 will fall through to 'else' block (or specific assignment) and reset.
                
                -- Optimization: If limit is high, we can reset immediately or hold?
                -- "Reset Cnt1" usually means it goes to 0.
                -- If we are transitioning, the NEXT state cleans it up.
                -- So here we just increment.
                
                -- Check for wrap-around or hold? User didn't say. Assumed free running up to limit.
                r_Cnt1 <= r_Cnt1 + 1;
                r_Cnt2 <= (others => '0'); -- Ensure Cnt2 is 0 while Cnt1 counts
            elsif CurrentState = Cnt2Count then
                -- Counter 2 Control
                r_Cnt2 <= r_Cnt2 + 1;
                r_Cnt1 <= (others => '0'); -- Ensure Cnt1 is 0 while Cnt2 counts
            else
                -- Idle or Others
                r_Cnt1 <= (others => '0');
                r_Cnt2 <= (others => '0');
            end if;
        end if;
    end process;

    -- Output Assignments
    o_Cnt1_q <= STD_LOGIC_VECTOR(r_Cnt1);
    o_Cnt2_q <= STD_LOGIC_VECTOR(r_Cnt2);

end Behavioral;
