library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter is
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        up_down : in  STD_LOGIC; -- '1' for count up, '0' for count down
        q       : out STD_LOGIC_VECTOR (3 downto 0)
    );
end counter;

architecture Behavioral of counter is
    signal count_reg : unsigned(3 downto 0) := (others => '0');
begin

    process(clk, rst)
    begin
        if rst = '1' then
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            if up_down = '1' then
                -- Count Up
                if count_reg = 9 then
                    count_reg <= (others => '0');
                else
                    count_reg <= count_reg + 1;
                end if;
            else
                -- Count Down
                if count_reg = 0 then
                    count_reg <= to_unsigned(9, 4);
                else
                    count_reg <= count_reg - 1;
                end if;
            end if;
        end if;
    end process;

    q <= std_logic_vector(count_reg);

end Behavioral;
