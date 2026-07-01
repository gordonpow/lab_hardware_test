library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clkDivider is
    Generic ( g_maxCnt : integer := 499999 ); -- 預設半計數為 500,000，以在 100MHz 系統主時脈下分頻產生 100Hz 慢速時脈
    Port ( i_clk       : in STD_LOGIC;
           i_rst       : in STD_LOGIC;
           o_slowClk   : out STD_LOGIC
           );
end clkDivider;

architecture Behavioral of clkDivider is

    -- 精確計數器與慢速時脈暫存器 (讀寫暫存修飾)
    signal r_cnt_r     : integer range 0 to g_maxCnt := 0;
    signal r_cnt_w     : integer range 0 to g_maxCnt := 0;
    signal r_slowClk_r : STD_LOGIC := '0';
    signal r_slowClk_w : STD_LOGIC := '0';

begin

    o_slowClk <= r_slowClk_r;

    -- 1. CLK_GEN: 產生 100Hz 的系統同步時脈
    CLK_GEN : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            r_cnt_r     <= 0;
            r_slowClk_r <= '0';
        elsif rising_edge(i_clk) then
            r_cnt_r     <= r_cnt_w;
            r_slowClk_r <= r_slowClk_w;
        end if;
    end process;

    process(r_cnt_r, r_slowClk_r)
    begin
        r_cnt_w     <= r_cnt_r;
        r_slowClk_w <= r_slowClk_r;

        if r_cnt_r = g_maxCnt then
            r_cnt_w     <= 0;
            r_slowClk_w <= not r_slowClk_r;
        else
            r_cnt_w     <= r_cnt_r + 1;
        end if;
    end process;

end Behavioral;
