library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is
    Port (
        i_clk        : in  STD_LOGIC;
        i_rst        : in  STD_LOGIC;
        i_en         : in  STD_LOGIC;
        i_Cnt1_lim_up: in  STD_LOGIC_VECTOR(7 downto 0);
        i_Cnt2_lim_up: in  STD_LOGIC_VECTOR(7 downto 0);
        o_Cnt1_q     : out STD_LOGIC_VECTOR(7 downto 0);
        o_Cnt2_q     : out STD_LOGIC_VECTOR(7 downto 0);
        o_Pwmout     : out STD_LOGIC
    );
end PWM;

architecture Behavioral of PWM is

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
                if i_en = '1' then
                    NextState <= Cnt1Count;
                else
                    NextState <= Idle;
                end if;

            when Cnt1Count =>
                if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
                    NextState <= Cnt2Count;
                end if;

            when Cnt2Count =>
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
            if i_en = '0' or CurrentState = Idle then 
                r_Cnt1 <= (others => '0');
                r_Cnt2 <= (others => '0');
            else
                -- Active Counter Logic
                if CurrentState = Cnt1Count then
                    -- FIX: Reset immediately when limit is reached to prevent counting to Limit+1
                    if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
                        r_Cnt1 <= (others => '0');
                        r_Cnt2 <= to_unsigned(1, 8); -- Start Cnt2 immediately
                    else
                         r_Cnt1 <= r_Cnt1 + 1;
                         r_Cnt2 <= (others => '0');
                    end if;
                    
                elsif CurrentState = Cnt2Count then
                    if r_Cnt2 >= unsigned(i_Cnt2_lim_up) then
                         r_Cnt2 <= (others => '0');
                         r_Cnt1 <= to_unsigned(1, 8); -- Start Cnt1 immediately
                    else
                         r_Cnt2 <= r_Cnt2 + 1;
                         r_Cnt1 <= (others => '0');
                    end if;
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
    


    process (CurrentState)
    begin
        if CurrentState = Cnt2Count then
            o_Pwmout <= '1';
        else
            o_Pwmout <= '0';
        end if;
    end process;

end Behavioral;
