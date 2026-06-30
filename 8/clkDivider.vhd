library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clkDivider is
    port (
        i_clk      : in  std_logic;
        i_rst      : in  std_logic;
        o_pixelEn  : out std_logic
    );
end entity clkDivider;

architecture rtl of clkDivider is
    signal v_clkCount_r : unsigned(1 downto 0);
    signal v_clkCount_w : unsigned(1 downto 0);
begin
    -- 循序邏輯：更新計數器暫存器
    CLK_DIV_REG : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            v_clkCount_r <= (others => '0');
        elsif rising_edge(i_clk) then
            v_clkCount_r <= v_clkCount_w;
        end if;
    end process CLK_DIV_REG;

    -- 組合邏輯：下一狀態與輸出
    v_clkCount_w <= v_clkCount_r + 1;
    
    -- 每4個時脈週期產生一個像素時脈致能脈衝 (100MHz / 4 = 25MHz)
    o_pixelEn <= '1' when v_clkCount_r = "11" else '0';

end architecture rtl;
