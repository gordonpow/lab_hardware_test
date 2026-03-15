library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Top Level Entity for Two Counters System
entity DualCounters_Top is
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
end DualCounters_Top;

architecture Structural of DualCounters_Top is

    component ConfigurableCounter is
        Generic (
            DATA_WIDTH : integer
        );
        Port (
            i_clk         : in  STD_LOGIC;
            i_res         : in  STD_LOGIC;
            i_en          : in  STD_LOGIC;
            i_load        : in  STD_LOGIC;
            i_up_down     : in  STD_LOGIC;
            i_d           : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            i_limit_upper : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            i_limit_lower : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            o_q           : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
        );
    end component;

begin

    -- Instance 1: Counter 1
    Counter1_Inst: ConfigurableCounter
    generic map (
        DATA_WIDTH => WIDTH
    )
    port map (
        i_clk         => i_clk,
        i_res         => i_res,
        i_en          => i_cnt1_en,
        i_load        => i_cnt1_load,
        i_up_down     => i_cnt1_up_down,
        i_d           => i_cnt1_d,
        i_limit_upper => i_cnt1_lim_up,
        i_limit_lower => i_cnt1_lim_lo,
        o_q           => o_cnt1_q
    );

    -- Instance 2: Counter 2
    Counter2_Inst: ConfigurableCounter
    generic map (
        DATA_WIDTH => WIDTH
    )
    port map (
        i_clk         => i_clk,
        i_res         => i_res,
        i_en          => i_cnt2_en,
        i_load        => i_cnt2_load,
        i_up_down     => i_cnt2_up_down,
        i_d           => i_cnt2_d,
        i_limit_upper => i_cnt2_lim_up,
        i_limit_lower => i_cnt2_lim_lo,
        o_q           => o_cnt2_q
    );

end Structural;
