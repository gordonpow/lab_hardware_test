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
    -- signal NextState    : CountState := StateUp;

    -- 除頻器與計數變數命名 (雙駝峰格式)
    signal DivCounter    : unsigned(25 downto 0) := (others => '0');
    signal Clk_2Hz       : STD_LOGIC;
    signal LedCounter    : unsigned(7 downto 0)  := (others => '0');
    signal clk_1Hz_q0    : STD_LOGIC;

begin

    -- 狀態機：控制 NextState
    FSM: process(i_rst,i_clk,i_up_down)
    begin
        if i_rst = '1' then
            CurrentState <= StateUp;
        elsif rising_edge(i_clk) then
            if i_up_down = '1' then
                CurrentState <= StateUp;
            else
                CurrentState <= StateDown;
            end if;
        end if;
    end process;

    -- 狀態機：控制 CurrentState (由於按鍵操作通常較慢，此處可選擇掛在 i_clk 或 Clk_2Hz，為了與計數同步我們統一掛在 Clk_2Hz 上)


    -- 控制 DivCounter (除頻計數動作)
    div:process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            DivCounter <= (others => '0');
            Clk_2Hz <= '0';
        elsif rising_edge(i_clk) then
            DivCounter <= DivCounter + 1;
            Clk_2Hz <= DivCounter(0);
        end if;
    end process;

    -- 擷取特定位元作為慢時脈 (100MHz 取 25 位元大約是 1.5Hz)
    

    -- 控制 LedCounter (數值計數)
    Counter:process(Clk_2Hz, i_rst)
    begin
        if i_rst = '1' then
            LedCounter <= (others => '0');
        elsif rising_edge(Clk_2Hz) then
            case CurrentState is
                when StateUp =>
                    LedCounter <= LedCounter + 1;
                when StateDown =>
                    LedCounter <= LedCounter - 1;
                when others =>
                    LedCounter <= LedCounter;
            end case;
        end if;
    end process;

    -- 輸出賦值
    o_led <= std_logic_vector(LedCounter);

end Behavioral;
