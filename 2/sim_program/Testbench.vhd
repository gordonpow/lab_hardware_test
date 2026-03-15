library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Testbench is
end Testbench;

architecture Sim of Testbench is

    -- Component Declaration matched to DualCounters_Top.vhd
    component DualCounters_Top is
        Generic (
            WIDTH : integer := 8
        );
        Port (
            i_clk         : in  STD_LOGIC;
            i_res         : in  STD_LOGIC;
            
            -- Counter 1 Interface
            i_cnt1_en     : in  STD_LOGIC;
            i_cnt1_load   : in  STD_LOGIC;
            i_cnt1_up_down: in  STD_LOGIC;
            i_cnt1_d      : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            i_cnt1_lim_up : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            i_cnt1_lim_lo : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            o_cnt1_q      : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            
            -- Counter 2 Interface
            i_cnt2_en     : in  STD_LOGIC;
            i_cnt2_load   : in  STD_LOGIC;
            i_cnt2_up_down: in  STD_LOGIC;
            i_cnt2_d      : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            i_cnt2_lim_up : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            i_cnt2_lim_lo : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
            o_cnt2_q      : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0)
        );
    end component;

    -- Signals
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '0';
    
    -- Counter 1 Signals
    signal cnt1_en, cnt1_load, cnt1_up_dn : STD_LOGIC := '0';
    signal cnt1_din, cnt1_lim_up, cnt1_lim_lo, cnt1_q : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- Counter 2 Signals
    signal cnt2_en, cnt2_load, cnt2_up_dn : STD_LOGIC := '0';
    signal cnt2_din, cnt2_lim_up, cnt2_lim_lo, cnt2_q : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    constant clk_period : time := 10 ns;

begin

    UUT: DualCounters_Top
    generic map (WIDTH => 8)
    port map (
        i_clk => clk, 
        i_res => rst,
        
        i_cnt1_en => cnt1_en, 
        i_cnt1_load => cnt1_load, 
        i_cnt1_up_down => cnt1_up_dn,
        i_cnt1_d => cnt1_din, 
        i_cnt1_lim_up => cnt1_lim_up, 
        i_cnt1_lim_lo => cnt1_lim_lo, 
        o_cnt1_q => cnt1_q,
        
        i_cnt2_en => cnt2_en, 
        i_cnt2_load => cnt2_load, 
        i_cnt2_up_down => cnt2_up_dn,
        i_cnt2_d => cnt2_din, 
        i_cnt2_lim_up => cnt2_lim_up, 
        i_cnt2_lim_lo => cnt2_lim_lo, 
        o_cnt2_q => cnt2_q
    );

    -- Clock Process
    process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Stimulus Process
    process
    begin
        -- Initialize
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        
        -- Setup Counter 1: Up Count, Limit 2 to 5
        cnt1_lim_lo <= x"02";
        cnt1_lim_up <= x"05";
        cnt1_up_dn <= '1'; -- Up
        cnt1_en <= '1';
        
        -- Setup Counter 2: Down Count, Limit 3 to 8
        cnt2_lim_lo <= x"03";
        cnt2_lim_up <= x"08";
        cnt2_up_dn <= '0'; -- Down
        -- Load initial value 8 for Counter 2
        cnt2_din <= x"08";
        cnt2_load <= '1';
        cnt2_en <= '1';
        wait for clk_period;
        cnt2_load <= '0';

        -- Let them run
        wait for 100 ns;

        -- Change Counter 1 to Down
        cnt1_up_dn <= '0';
        wait for 50 ns;

        wait;
    end process;

end Sim;
