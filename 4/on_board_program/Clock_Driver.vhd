library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Clock_Divider is
  generic (
    SYS_CLK_FREQ : integer := 100_000_000 -- 50MHz �D�ɯ�
  );
  port (
    i_clk    : in std_logic;
    i_rst    : in std_logic;
    Clk_2Hz  : out std_logic; -- 2Hz �P��ߪi (1 cycle �e��)
    CLK_1khz : out std_logic
  );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
  signal DivCounter : unsigned(25 downto 0) := (others => '0');

begin
  -- ���� DivCounter (���W�p�ưʧ@)
  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      DivCounter <= (others => '0');
      Clk_2Hz    <= '0';
    elsif rising_edge(i_clk) then
      DivCounter <= DivCounter + 1;
      Clk_2Hz    <= DivCounter(25);
      CLK_1khz   <= DivCounter(8);
    end if;
  end process;
end Behavioral;