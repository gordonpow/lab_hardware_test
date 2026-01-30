library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CounterFSM is
    Port (
        i_clk        : in  STD_LOGIC;
        i_rst        : in  STD_LOGIC;
        i_en         : in  STD_LOGIC;
        i_Cnt1_lim_up: in  STD_LOGIC;
        i_Cnt2_lim_up: in  STD_LOGIC;
        o_Cnt1_q     : out STD_LOGIC;
        o_Cnt2_q     : out STD_LOGIC
    );
end CounterFSM;

architecture Behavioral of CounterFSM is

    type StateType is (Idle, Cnt1Count, Cnt2Count);
    signal CurrentState, NextState : StateType;

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

    -- Next State and Output Logic Process
    process (CurrentState, i_en, i_Cnt1_lim_up, i_Cnt2_lim_up)
    begin
        -- Default assignments to prevent latches
        NextState <= CurrentState;
        o_Cnt1_q <= '0';
        o_Cnt2_q <= '0';

        case CurrentState is
            when Idle =>
                if i_en = '1' then
                    NextState <= Cnt1Count;
                else
                    NextState <= Idle;
                end if;

            when Cnt1Count =>
                o_Cnt1_q <= '1';
                if i_Cnt1_lim_up = '1' then
                    NextState <= Cnt2Count;
                end if;

            when Cnt2Count =>
                o_Cnt2_q <= '1';
                if i_Cnt2_lim_up = '1' then
                    NextState <= Cnt1Count;
                end if;
                
            when others =>
                NextState <= Idle;
        end case;
    end process;

end Behavioral;
