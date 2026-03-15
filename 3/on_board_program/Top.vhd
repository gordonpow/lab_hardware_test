library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =========================================
-- 頂層模組：系統外殼 (將除頻器與狀態機接線)
-- =========================================
entity System_Top is
    Generic (
        WIDTH : integer := 4
    );
    Port (
        i_clk         : in  STD_LOGIC;
        i_rst         : in  STD_LOGIC;
        
        -- 控制與資料介面
        i_en          : in  STD_LOGIC;
--        i_Cnt1_lim_up           : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        i_Cnt2_lim_up           : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        
        -- 輸出介面
        o_led           : out STD_LOGIC_VECTOR(7 downto 0)
    );
end System_Top;

architecture Structural of System_Top is

    -- 1. 宣告除頻器元件 (如同宣告零件的規格書)
    component Clock_Divider is
        Generic (
            SYS_CLK_FREQ : integer := 50_000_000
        );
        Port (
            i_clk      : in  STD_LOGIC;
            i_rst      : in  STD_LOGIC;
            Clk_2Hz   : out STD_LOGIC
        );
    end component;

    -- 2. 宣告主狀態機與計數器元件
    component CounterFSM is
        Generic (
            DATA_WIDTH : integer := 4
        );
        Port (
            i_clk        : in  STD_LOGIC;
            i_rst        : in  STD_LOGIC;
            i_en         : in  STD_LOGIC;
            i_Cnt1_lim_up: in  STD_LOGIC_VECTOR(DATA_WIDTH -1 downto 0);
            i_Cnt2_lim_up: in  STD_LOGIC_VECTOR(DATA_WIDTH -1 downto 0);
            o_Cnt1_q     : out STD_LOGIC_VECTOR(DATA_WIDTH -1 downto 0);
            o_Cnt2_q     : out STD_LOGIC_VECTOR(DATA_WIDTH -1 downto 0)
        );
    end component;

    -- 3. 宣告內部連線訊號 (用來把兩個零件銲接在一起的導線)
    signal sig_en_2hz      : STD_LOGIC;
    signal sig_restart_div : STD_LOGIC;

begin

    -- =========================================
    -- 實例化 (Instantiation) 與 接線 (Port Map)
    -- =========================================

    -- 零件 A：除頻器
    Inst_Clock_Divider: Clock_Divider
    generic map (
        SYS_CLK_FREQ => 100_000_000 -- 假設你的板子主時脈為 50MHz
    )
    port map (
        i_clk     => i_clk,
        i_rst     => i_rst,
        Clk_2Hz  => sig_en_2hz       -- 輸出 2Hz 脈波給狀態機
    );

    -- 零件 B：狀態機計數器
    CounterFSM1: CounterFSM

    port map (
        i_clk         => sig_en_2hz,
        i_rst         => i_rst,
        i_en          => i_en,
        i_Cnt1_lim_up => "1111",
        i_Cnt2_lim_up => i_Cnt2_lim_up,
        o_Cnt1_q      => o_led(3 downto 0),
        o_Cnt2_q      => o_led(7 downto 4)
    );

end Structural;