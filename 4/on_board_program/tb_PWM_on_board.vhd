library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench 的 entity 永遠是空的，因為它不與外部硬體接線
entity tb_PWM is
end tb_PWM;

architecture behavior of tb_PWM is

    -- 1. 宣告要測試的零件 (UUT - Unit Under Test)
    component PWM is
        Port (
            i_clk        : in  STD_LOGIC;
            i_rst        : in  STD_LOGIC;
            i_en         : in  STD_LOGIC;
            i_Period     : in  STD_LOGIC_VECTOR(7 downto 0);
            i_Duty       : in  STD_LOGIC_VECTOR(7 downto 0);
            o_Cnt1_q     : out STD_LOGIC_VECTOR(7 downto 0);
            o_Cnt2_q     : out STD_LOGIC_VECTOR(7 downto 0);
            o_Pwmout     : out STD_LOGIC
        );
    end component;

    -- 2. 宣告用來連接測試零件的虛擬導線 (Signals)
    signal clk        : STD_LOGIC := '0';
    signal rst        : STD_LOGIC := '0';
    signal en         : STD_LOGIC := '0';
    signal period_val : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal duty_val   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    
    -- 觀察用的輸出訊號
    signal cnt1_out   : STD_LOGIC_VECTOR(7 downto 0);
    signal cnt2_out   : STD_LOGIC_VECTOR(7 downto 0);
    signal pwm_out    : STD_LOGIC;

    -- 3. 定義時脈週期常數 (假設為 1kHz，即 1ms 週期)
    -- 為了模擬速度快一點，我們這裡用 10 ns (100MHz) 來代表一個 tick
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 4. 實例化 (把測試零件拿出來接線)
    uut: PWM
    port map (
        i_clk        => clk,
        i_rst        => rst,
        i_en         => en,
        i_Period     => period_val,
        i_Duty       => duty_val,
        o_Cnt1_q     => cnt1_out,
        o_Cnt2_q     => cnt2_out,
        o_Pwmout     => pwm_out
    );

    -- 5. 產生無窮迴圈的時脈 (Clock Process)
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 6. 主要測試劇本 (Stimulus Process)
    stim_proc: process
    begin
        -- [場景 1] 系統初始化與重置
        rst <= '1';
        en  <= '0';
        period_val <= std_logic_vector(to_unsigned(100, 8)); -- 設定總週期為 100 拍
        duty_val   <= std_logic_vector(to_unsigned(20, 8));  -- 設定初始 Duty 為 20 拍 (20%)
        wait for CLK_PERIOD * 5; -- 等待 5 個時脈讓系統重置乾淨
        
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        -- 啟動系統
        en <= '1';
        
        -- 觀察 20% Duty 的波形 (等待 1.5 個週期，約 150 拍)
        -- 預期：高電位 20 拍，低電位 80 拍
        wait for CLK_PERIOD * 150; 

        -- [場景 2] 動態改變 Duty 變為 80%
        duty_val <= std_logic_vector(to_unsigned(80, 8));
        
        -- 觀察 80% Duty 的波形 (等待 1.5 個週期，約 150 拍)
        -- 預期：高電位 80 拍，低電位 20 拍
        wait for CLK_PERIOD * 150;

        -- [場景 3] 測試極端值：100% Duty (全亮)
        duty_val <= std_logic_vector(to_unsigned(100, 8));
        wait for CLK_PERIOD * 150;

        -- [場景 4] 測試極端值：0% Duty (全暗)
        duty_val <= std_logic_vector(to_unsigned(0, 8));
        wait for CLK_PERIOD * 150;

        -- 測試結束，停止模擬 (讓時脈停止的方法有很多，這是一種簡單的印出訊息)
        assert false report "Simulation Finished" severity failure;
        wait;
    end process;

end behavior;