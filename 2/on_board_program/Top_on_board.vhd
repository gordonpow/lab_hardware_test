library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =========================================
-- 系統頂層模組 (含時脈除頻與可配置計數器)
-- =========================================
entity System_Top is
    Generic (
        WIDTH : integer := 2
    );
    Port (
        i_clk         : in  STD_LOGIC;
        i_rst         : in  STD_LOGIC;
        
        -- 參數控制
        i_en          : in  STD_LOGIC;
        i_load        : in  STD_LOGIC;
        i_up_down     : in  STD_LOGIC;
        i_d           : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        i_limit_upper : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        i_limit_lower : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        
        -- 輸出顯示
        o_led           : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0)
    );
end System_Top;

architecture Structural of System_Top is

    -- 1. �ŧi���W������ (�p�P�ŧi�s�󪺳W���)
    component Clock_Divider is
        Generic (
            SYS_CLK_FREQ : integer := 50_000_000
        );
        Port (
            i_clk      : in  STD_LOGIC;
            i_res      : in  STD_LOGIC;
            i_restart  : in  STD_LOGIC;
            o_en_2hz   : out STD_LOGIC
        );
    end component;

    -- 2. 狀態機計數器
    component Main_FSM_Counter is
        Generic (
            DATA_WIDTH : integer
        );
        Port (
            i_clk         : in  STD_LOGIC;
            i_res         : in  STD_LOGIC;
            i_en_2hz      : in  STD_LOGIC;
            i_en          : in  STD_LOGIC;
            i_load        : in  STD_LOGIC;
            i_up_down     : in  STD_LOGIC;
            i_d           : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            i_limit_upper : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            i_limit_lower : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
            o_restart_div : out STD_LOGIC;
            o_q           : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0)
        );
    end component;

    -- 3. 內部訊號
    signal sig_en_2hz      : STD_LOGIC;
    signal sig_restart_div : STD_LOGIC;

begin

    -- =========================================
    -- 實例化與連接埠對應
    -- =========================================

    -- 實例化時脈除頻器
    Inst_Clock_Divider: Clock_Divider
    generic map (
        SYS_CLK_FREQ => 100_000_000 -- 預設頻率為 100MHz
    )
    port map (
        i_clk     => i_clk,
        i_res     => i_rst,
        i_restart => sig_restart_div, -- 觸發除頻器重置
        o_en_2hz  => sig_en_2hz       -- 輸出 2Hz 訊號
    );

    -- �s�� B�G���A���p�ƾ�
    Inst_Main_FSM: Main_FSM_Counter
    generic map (
        DATA_WIDTH => WIDTH
    )
    port map (
        i_clk         => i_clk,
        i_res         => i_rst,
        i_en_2hz      => sig_en_2hz,       -- 接收 2Hz 訊號
        i_en          => i_en,
        i_load        => i_load,
        i_up_down     => i_up_down,
        i_d           => i_d,
        i_limit_upper => i_limit_upper,
        i_limit_lower => i_limit_lower,
        o_restart_div => sig_restart_div,  -- 觸發除頻器重置
        o_q           => o_led
    );

end Structural;