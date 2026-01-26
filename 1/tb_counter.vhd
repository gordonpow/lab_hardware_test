library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_counter is
-- Testbench has no ports
end tb_counter;

architecture Behavioral of tb_counter is

    -- Component Declaration
    component counter
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        up_down : in  STD_LOGIC;
        q       : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component;

    -- Signal Declarations
    signal clk_tb     : STD_LOGIC := '0';
    signal rst_tb     : STD_LOGIC := '0';
    signal up_down_tb : STD_LOGIC := '0';
    signal q_tb       : STD_LOGIC_VECTOR (3 downto 0);

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: counter PORT MAP (
        clk     => clk_tb,
        rst     => rst_tb,
        up_down => up_down_tb,
        q       => q_tb
    );

    -- Clock Process
    clk_process :process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin		
        -- Hold reset state
        rst_tb <= '1';
        wait for 20 ns;	
        
        rst_tb <= '0';
        
        -- Test Count Up (0 to 9 to 0...)
        up_down_tb <= '1';
        wait for clk_period * 15; -- Wait enough cycles to wrap around

        -- Test Count Down (current to 0 to 9...)
        up_down_tb <= '0';
        wait for clk_period * 15;

        -- Test Reset mid-count
        rst_tb <= '1';
        wait for 20 ns;
        rst_tb <= '0';
        wait for clk_period * 5;

        -- End Simulation
        assert false report "Simulation Completed" severity failure;
        
        wait;
    end process;

end Behavioral;
