library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Clock_Divider is
    Generic (
        SYS_CLK_FREQ : integer := 50_000_000 -- 50MHz 主時脈
    );
    Port (
        i_clk      : in  STD_LOGIC;
        i_res      : in  STD_LOGIC;
        i_restart  : in  STD_LOGIC; -- 來自 FSM，要求重新計時
        o_en_2hz   : out STD_LOGIC  -- 2Hz 致能脈波 (1 cycle 寬度)
    );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
    constant DIV_LIMIT : integer := (SYS_CLK_FREQ / 2) - 1;
    signal div_cnt     : integer range 0 to DIV_LIMIT := 0;
begin
    process(i_clk, i_res)
    begin
        if i_res = '1' then
            div_cnt <= 0;
            o_en_2hz <= '0';
        elsif rising_edge(i_clk) then
            -- 當主電路要求重新計時，馬上歸零
            if i_restart = '1' then
                div_cnt <= 0;
                o_en_2hz <= '0';
            else
                if div_cnt >= DIV_LIMIT then
                    div_cnt <= 0;
                    o_en_2hz <= '1'; -- 產生一個 cycle 的高電位
                else
                    div_cnt <= div_cnt + 1;
                    o_en_2hz <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;