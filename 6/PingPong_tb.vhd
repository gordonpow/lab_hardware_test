LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY pingpong_tb IS
END pingpong_tb;
 
ARCHITECTURE behavior OF pingpong_tb IS
 
-- Component Declaration for the Unit Under Test (UUT)
 
COMPONENT pingpong
    Port (
           i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_swL : in STD_LOGIC;
           i_swR : in STD_LOGIC;
           o_led : out STD_LOGIC_VECTOR (7 downto 0)
           );
END COMPONENT;
 
--Inputs
signal clock : std_logic := '0';
signal reset : std_logic := '0';
signal swL : std_logic;
signal swR : std_logic; 
signal led : std_logic_vector(7 downto 0);
--Outputs
--signal counter : std_logic_vector(3 downto 0);
 
-- Clock period definitions
constant clock_period : time := 20 ns;
 
BEGIN
 
-- Instantiate the Unit Under Test (UUT)
uut: pingpong PORT MAP (
           i_clk => clock,
           i_rst => reset, 
           i_swL => swL,
           i_swR => swR,
           o_led => led
);
 
-- Clock process definitions
clock_process :process
begin
clock <= '0';
wait for clock_period/2;
clock <= '1';
wait for clock_period/2;
end process;
 
-- Stimulus process
stim_proc: process
begin
        -- 1. Reset
        reset <= '0';
        swL <= '0';
        swR <= '0';
        wait for 100 ns;
        reset <= '1';
        wait for 100 ns; -- Wait for initial settle

        -- 2. Serve (Left Side Starts)
        -- Pulse swL to start the game (MovingR state)
        swL <= '1';
        wait for 50 ns;
        swL <= '0';

        -- 3. Rally: Left -> Right (Hit)
        -- Wait until ball reaches the rightmost position (led(0) becomes '1')
        wait until led(0) = '1';
        wait for 20 ns; -- Simulate reaction time
        swR <= '1';     -- Right player hits
        wait for 50 ns; -- Button press duration
        swR <= '0';

        -- 4. Rally: Right -> Left (Hit)
        -- Wait until ball reaches the leftmost position (led(7) becomes '1')
        wait until led(7) = '1';
        wait for 20 ns;
        swL <= '1';     -- Left player hits
        wait for 50 ns;
        swL <= '0';

        -- 5. Rally: Left -> Right (Miss)
        -- Wait until ball passes (led(0) becomes '1' and then goes off or state changes)
        -- Wait until ball reaches the rightmost position (led(0) becomes '1')
        wait until led(0) = '1';
        -- Right player FAILS to hit (Miss)
        -- Wait for the state to transition to Lwin (LEDs will change)
        wait for 500 ns; 

        -- 6. Serve after Miss (Left Scored, Left Serves)
        -- In Lwin state, swL needs to be pressed to serve again
        swL <= '1';
        wait for 50 ns; -- Serve
        swL <= '0';

        -- 7. Early Hit (Fault)
        -- Wait for ball to be somewhere in the middle (e.g., led(4) becomes '1')
        wait until led(4) = '1';
        -- Right player hits too early (Fault)
        swR <= '1';
        wait for 50 ns;
        swR <= '0';
        
        -- Game should enter Lwin state (Right fault)
        wait for 200 ns;

        wait;
end process;
 
END;
