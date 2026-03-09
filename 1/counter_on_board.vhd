library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_on_board is
    Port ( 
        i_clk     : in  STD_LOGIC;
        i_rst     : in  STD_LOGIC;
        i_up_down : in  STD_LOGIC;
        o_led     : out STD_LOGIC_VECTOR (7 downto 0)
    );
end counter_on_board;

architecture Behavioral of counter_on_board is

    -- 狀態機定義
    type CountState is (StateUp, StateDown);
    signal CurrentState : CountState := StateUp;
    signal NextState    : CountState := StateUp;

    -- 除頻器與計數變數命名 (雙駝峰格式)
    signal DivCounter    : unsigned(25 downto 0) := (others => '0');
    signal DivCounter_d1 : STD_LOGIC := '0';
    signal ClkEnable     : STD_LOGIC := '0';
    signal LedCounter    : unsigned(7 downto 0)  := (others => '0');

begin

    -- 狀態機：控制 NextState
    process(i_up_down)
    begin
        if i_up_down = '1' then
            NextState <= StateUp;
        else
            NextState <= StateDown;
        end if;
    end process;

    -- 狀態機：控制 CurrentState
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            CurrentState <= StateUp;
        elsif rising_edge(i_clk) then
            CurrentState <= NextState;
        end if;
    end process;

    -- 控制 DivCounter (除頻計數動作)
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            DivCounter <= (others => '0');
        elsif rising_edge(i_clk) then
            DivCounter <= DivCounter + 1;
        end if;
    end process;

    -- 控制 ClkEnable (致能訊號：偵測特定位元的正緣)
    -- 100MHz (10ns) -> DivCounter(25) 的週期約為 0.671 秒 (約 1.49Hz)，接近人眼可視
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            ClkEnable <= '0';
            DivCounter_d1 <= '0';
        elsif rising_edge(i_clk) then
            -- 延遲一個 clock 為了抓正緣
            DivCounter_d1 <= DivCounter(25);
            
            -- 當現在是 1，前一個 clock 是 0，代表發生了 0 -> 1 的變化
            if DivCounter(25) = '1' and DivCounter_d1 = '0' then
                ClkEnable <= '1';
            else
                ClkEnable <= '0';
            end if;
        end if;
    end process;

    -- 控制 LedCounter (數值計數)
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            LedCounter <= (others => '0');
        elsif rising_edge(i_clk) then
            if ClkEnable = '1' then
                case CurrentState is
                    when StateUp =>
                        LedCounter <= LedCounter + 1;
                    when StateDown =>
                        LedCounter <= LedCounter - 1;
                    when others =>
                        LedCounter <= LedCounter;
                end case;
            end if;
        end if;
    end process;

    -- 輸出賦值
    o_led <= std_logic_vector(LedCounter);

end Behavioral;
