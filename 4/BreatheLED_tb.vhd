library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BreatheLED_tb is
-- Testbench has no ports
end BreatheLED_tb;

architecture Behavioral of BreatheLED_tb is

    component BreatheLED
        Port (
            i_clk        : in  STD_LOGIC;
            i_rst        : in  STD_LOGIC;
            i_en         : in  STD_LOGIC;
            o_led        : out STD_LOGIC
        );
    end component;

    -- Signals
    signal i_clk : STD_LOGIC := '0';
    signal i_rst : STD_LOGIC := '0';
    signal i_en  : STD_LOGIC := '0';
    signal o_led : STD_LOGIC;

    -- Clock period definitions
    constant i_clk_period : time := 10 ns;

begin

    -- Instantiate UUT
    uut: BreatheLED PORT MAP (
        i_clk => i_clk,
        i_rst => i_rst,
        i_en  => i_en,
        o_led => o_led
    );

    -- Clock process
    i_clk_process :process
    begin
        i_clk <= '0';
        wait for i_clk_period/2;
        i_clk <= '1';
        wait for i_clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        i_rst <= '1';
        wait for 100 ns;
        i_rst <= '0';
        
        wait for i_clk_period*10;

        -- Enable
        i_en <= '1';
        
        -- Simulate for a long time to see the breathing effect
        -- Because PWM_PERIOD is 255 and r_BreathCounter is 16-bit, 
        -- it takes many cycles to see full brightness change.
        wait for 500 us;

        -- Disable
        i_en <= '0';
        wait for 10 us;
        
        -- Final wait
        wait;
    end process;

end Behavioral;
