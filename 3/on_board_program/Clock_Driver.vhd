library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Clock_Divider is
    Generic (
        SYS_CLK_FREQ : integer := 50_000_000 -- 50MHz 主時脈
    );
    Port (
        i_clk      : in  STD_LOGIC;
        i_rst      : in  STD_LOGIC;
        Clk_2Hz   : out STD_LOGIC  -- 2Hz 致能脈波 (1 cycle 寬度)
    );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
    signal DivCounter    : unsigned(25 downto 0) := (others => '0');

begin
        -- 控制 DivCounter (除頻計數動作)
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            DivCounter <= (others => '0');
            Clk_2Hz <= '0';
        elsif rising_edge(i_clk) then
            DivCounter <= DivCounter + 1;
            Clk_2Hz <= DivCounter(24);
        end if;
    end process;
end Behavioral;