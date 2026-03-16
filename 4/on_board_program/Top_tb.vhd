library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity tb_Top is
end tb_Top;

architecture behavior of tb_Top is

  -- 1. 宣告要測試的頂層模組
  component Top is
    port (
      i_clk        : in std_logic;
      i_rst        : in std_logic;
      i_en         : in std_logic;
      i_speed_up   : in std_logic;
      i_speed_down : in std_logic;
      o_Pwmout     : out std_logic
    );
  end component;

  -- 2. 宣告測試用的虛擬訊號
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1'; -- 預設先給重置訊號
  signal en         : std_logic := '0';
  signal speed_up   : std_logic := '0';
  signal speed_down : std_logic := '0';

  -- 觀察用輸出
  signal pwm_out : std_logic;

  -- 3. 時脈設定 (對應你系統的 50MHz = 20ns 週期)
  constant CLK_PERIOD : time := 10 ns;

begin

  -- 4. 實例化頂層模組
  uut : Top
  port map
  (
    i_clk        => clk,
    i_rst        => rst,
    i_en         => en,
    i_speed_up   => speed_up,
    i_speed_down => speed_down,
    o_Pwmout     => pwm_out
  );

  -- 5. 產生 50MHz 主時脈
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- 6. 主要測試劇本 (按鈕模擬)
  stim_proc : process
  begin
    -- [場景 1] 系統初始化
    rst        <= '1';
    en         <= '0';
    speed_up   <= '0';
    speed_down <= '0';
    wait for CLK_PERIOD * 10;

    -- 放開重置，啟動系統
    rst <= '0';
    wait for CLK_PERIOD * 10;
    en <= '1';

    -- 讓系統以預設速度 (FlashSpeed=50) 跑一段時間，觀察呼吸變化
    -- 注意：因為內部除頻到 1kHz，且要數到 255，這裡模擬時間會很長
    wait for 10 ms;

    -- [場景 2] 模擬按下一鍵「加速」 (i_speed_up)
    -- 模擬手指按下按鈕 50ms (這對 50MHz 時鐘來說是很長的時間，足以觸發邊緣偵測)
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0'; -- 手指放開
    wait for 20 us;
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0';
    wait for 20 us;
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0';
    wait for 20 us;
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0';
    wait for 20 us;
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0';
    wait for 20 us;
    speed_up <= '1';
    wait for 50 us;
    speed_up <= '0';
    -- 讓加速後的系統跑一段時間，觀察呼吸是否變快
    wait for 10 ms;

    -- [場景 3] 模擬按下一鍵「減速」 (i_speed_down)
    -- speed_down <= '1';
    -- wait for 5 ms;
    -- speed_down <= '0';
    -- 觀察減速後的狀態
    wait for 10 ms;

    -- 測試結束
    assert false report "Simulation Finished" severity failure;
    wait;
  end process;

end behavior;