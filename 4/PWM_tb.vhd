library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_tb is
-- Testbench has no ports
end PWM_tb;

architecture Behavioral of PWM_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component PWM
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
    end component;

    -- Inputs
    signal i_clk         : STD_LOGIC := '0';
    signal i_rst         : STD_LOGIC := '0';
    signal i_en          : STD_LOGIC := '0';
    signal i_Cnt1_lim_up : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal i_Cnt2_lim_up : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- Outputs
    signal o_Cnt1_q      : STD_LOGIC_VECTOR(7 downto 0);
    signal o_Cnt2_q      : STD_LOGIC_VECTOR(7 downto 0);
    signal o_Pwmout      : STD_LOGIC;

    -- Internal signals for test control
    signal r_DutyCycle   : UNSIGNED(7 downto 0) := to_unsigned(1, 8);

    -- Clock period definitions
    constant i_clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: PWM PORT MAP (
        i_clk         => i_clk,
        i_rst         => i_rst,
        i_en          => i_en,
        i_Cnt1_lim_up => i_Cnt1_lim_up,
        i_Cnt2_lim_up => i_Cnt2_lim_up,
        o_Cnt1_q      => o_Cnt1_q,
        o_Cnt2_q      => o_Cnt2_q,
        o_Pwmout      => o_Pwmout
    );

    -- Clock process definitions
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
        -- Initialize Limits
        i_Cnt1_lim_up <= std_logic_vector(to_unsigned(100, 8)); -- Limit 1 is fixed at 100
        i_Cnt2_lim_up <= std_logic_vector(r_DutyCycle);        -- Limit 2 follows DutyCycle

        -- hold reset state for 100 ns.
        i_rst <= '1';
        wait for 100 ns;
        i_rst <= '0';

        wait for i_clk_period*10;

        -- Test Case: Dynamic Duty Cycle
        i_en <= '1';
        
        -- Loop to increment duty cycle
        for i in 1 to 50 loop
            -- Update the limit with current duty cycle
            i_Cnt2_lim_up <= std_logic_vector(r_DutyCycle);
            
            -- Wait for several PWM cycles to see the change
            -- One PWM cycle = (100 + DutyCycle) clock cycles
            -- Let's wait for (100 + 100) * 2 cycles to be safe per increment
            wait for i_clk_period * 400;
            
            -- Increment Duty Cycle
            if r_DutyCycle < 100 then
                r_DutyCycle <= r_DutyCycle + 1;
            end if;
        end loop;

        -- Test Case 2: Global Disable
        i_en <= '0';
        wait for i_clk_period * 50;
        
        -- Test Case 3: Re-enable
        i_en <= '1';
        wait for i_clk_period * 100;

        wait;
    end process;

end Behavioral;
