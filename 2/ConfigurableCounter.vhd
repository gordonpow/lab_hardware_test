library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entity Definition for Configurable Counter
-- Supports:
-- 1. Programmable Upper and Lower Limits
-- 2. Up/Down Counting Direction
-- 3. Loadable Current Count
-- 4. Enable Signal
entity ConfigurableCounter is
    Generic (
        DATA_WIDTH : integer := 8
    );
    Port (
        i_clk         : in  STD_LOGIC;
        i_res         : in  STD_LOGIC; -- Asynchronous Reset
        i_en          : in  STD_LOGIC; -- Enable Counting
        i_load        : in  STD_LOGIC; -- Load specific value
        i_up_down     : in  STD_LOGIC; -- '1' = Up, '0' = Down
        i_d           : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Load Data
        i_limit_upper : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Upper Limit
        i_limit_lower : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Lower Limit
        o_q           : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)  -- Counter Output
    );
end ConfigurableCounter;

architecture Behavioral of ConfigurableCounter is
    signal CountReg : UNSIGNED(DATA_WIDTH - 1 downto 0);
begin

    process(i_clk, i_res)
    begin
        if i_res = '1' then
            -- Reset to 0 by default. User should set limits appropriately or use Load.
            CountReg <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_load = '1' then
                -- Load specific value
                CountReg <= unsigned(i_d);
            elsif i_en = '1' then
                if i_up_down = '1' then 
                    -- Up Counting
                    if CountReg >= unsigned(i_limit_upper) then
                        CountReg <= unsigned(i_limit_lower);
                    else
                        CountReg <= CountReg + 1;
                    end if;
                else 
                    -- Down Counting
                    if CountReg <= unsigned(i_limit_lower) then
                        CountReg <= unsigned(i_limit_upper);
                    else
                        CountReg <= CountReg - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    o_q <= std_logic_vector(CountReg);

end Behavioral;
