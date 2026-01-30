library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CounterFSM_tb is
-- Testbench has no ports
end CounterFSM_tb;

architecture Behavioral of CounterFSM_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component CounterFSM
        Port (
            i_clk        : in  STD_LOGIC;
            i_rst        : in  STD_LOGIC;
            i_en         : in  STD_LOGIC;
            i_Cnt1_lim_up: in  STD_LOGIC;
            i_Cnt2_lim_up: in  STD_LOGIC;
            o_Cnt1_q     : out STD_LOGIC_VECTOR(7 downto 0);
            o_Cnt2_q     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Inputs
    signal i_clk         : STD_LOGIC := '0';
    signal i_rst         : STD_LOGIC := '0';
    signal i_en          : STD_LOGIC := '0';
    signal i_Cnt1_lim_up : STD_LOGIC := '0';
    signal i_Cnt2_lim_up : STD_LOGIC := '0';

    -- Outputs
    signal o_Cnt1_q      : STD_LOGIC_VECTOR(7 downto 0);
    signal o_Cnt2_q      : STD_LOGIC_VECTOR(7 downto 0);

    -- Clock period definitions
    constant i_clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: CounterFSM PORT MAP (
        i_clk         => i_clk,
        i_rst         => i_rst,
        i_en          => i_en,
        i_Cnt1_lim_up => i_Cnt1_lim_up,
        i_Cnt2_lim_up => i_Cnt2_lim_up,
        o_Cnt1_q      => o_Cnt1_q,
        o_Cnt2_q      => o_Cnt2_q
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
        -- hold reset state for 100 ns.
        i_rst <= '1';
        wait for 100 ns;
        i_rst <= '0';

        wait for i_clk_period*10;

        -- Test Case 1: Enable system
        i_en <= '1';
        wait for i_clk_period*10;
        
        -- Observe Cnt1 counting
        wait for i_clk_period*5;
        
        -- Test Case 2: Cnt1 Limit Reached -> Switch to Cnt2
        i_Cnt1_lim_up <= '1';
        wait for i_clk_period;
        i_Cnt1_lim_up <= '0';
        
        -- Observe Cnt2 counting, Cnt1 reset
        wait for i_clk_period*10; 
        
        -- Test Case 3: Cnt2 Limit Reached -> Switch to Cnt1
        i_Cnt2_lim_up <= '1';
        wait for i_clk_period;
        i_Cnt2_lim_up <= '0';
        
        -- Observe Cnt1 counting again, Cnt2 reset
        wait for i_clk_period*10;

        -- Test Case 4: Disable System (Optional check for Idle return logic)
        i_en <= '0'; -- FSM currently only checks EN in Idle, so this might not stop it unless we add unconditional check.
                     -- Based on current FSM logic, once in Cnt1/2 state, EN is ignored.
                     -- The test will just end here.

        wait;
    end process;

end Behavioral;
