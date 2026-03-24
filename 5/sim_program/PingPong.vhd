library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity pingpong is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_swL : in STD_LOGIC;
           i_swR : in STD_LOGIC;
           o_led : out STD_LOGIC_VECTOR (7 downto 0)
           );
end pingpong;

architecture Behavioral of pingpong is
type STATE_TYPE is (MovingR, MovingL, Lwin, Rwin);
signal state : STATE_TYPE;
signal prev_state: STATE_TYPE;
signal led_r : STD_LOGIC_VECTOR (7 downto 0);
signal scoreL : STD_LOGIC_VECTOR (3 downto 0);
signal scoreR : STD_LOGIC_VECTOR (3 downto 0);

signal slow_clk : STD_LOGIC;
signal cnt : unsigned(24 downto 0) := (others => '0');

begin
	o_led <= led_r;

	CLK_DIV:process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            cnt <= (others => '0');
            slow_clk <= '0';
        elsif rising_edge(i_clk) then
            cnt <= cnt + 1;
            slow_clk <= cnt(1);  --位元越大越慢
        end if;
    end process;
        
    FSM:process(i_clk, i_rst, i_swL, i_swR, led_r)
    begin
        if i_rst='0' then
            state <= MovingR;
        elsif i_clk'event and i_clk='1' then
             case state is
                when MovingR => --S0 右移中
                    --if (led_r = "00000001" and i_swR = '0') or (led_r > "00000001" and i_swR = '1') then --右沒打到或提早(改)
                    if (led_r < "00000001") or (led_r > "00000001" and i_swR = '1') then
                        state <= Lwin;
                    elsif led_r(0)='1' and i_swR ='1' then --右打到 then
                        state <= MovingL;
                    end if;
                when MovingL => --S1 左移中
                    --if (led_r = "10000000" and i_swL = '0') or (led_r < "10000000" and i_swL = '1') then --左沒打到或提早(改)
                    if (led_r = "00000000") or (led_r < "10000000" and i_swL = '1') then
                        state <= Rwin;
                    elsif led_r(7)='1' and i_swL ='1' then --左打到 then
                       state <= MovingR;
                    end if;
                when Lwin =>    --S3 
                    if i_swL ='1' then --左發球
                       state <= MovingR;
                 end if;
                when Rwin =>    --S2
                    if i_swR ='1' then --右發球
                       state <= MovingL;
                    end if;
                when others => 
                    null;
            end case;
        end if;
    end process;

	LED_P:process(slow_clk, i_rst, state, prev_state)
	begin
		if i_rst='0' then
			led_r <= "10000000";
		elsif slow_clk'event and slow_clk='1' then
			prev_state <= state;
			case state is
				when MovingR => --S0 右移中
					if (prev_state = Lwin) then
						led_r <= "10000000";
					elsif (prev_state <= MovingL or prev_state <= MovingR) then
						led_r(7         ) <= '0';
						led_r(6 downto 0) <= led_r(7 downto 1); --led_r >> 1
					end if;          
				when MovingL => --S1 左移中
					if (prev_state = Rwin) then
						led_r <= "00000001";
					elsif (prev_state <= MovingR or prev_state <= MovingL) then            
						led_r(7 downto 1) <= led_r(6 downto 0); --led_r << 1            
						led_r(         0) <= '0';
					end if;
				when Lwin =>    --S3 
					if (prev_state = MovingR) then
						led_r <= "11110000";
					end if;
				when Rwin =>    --S2
					if (prev_state = MovingL) then
						led_r <= "00001111";
					end if;
				when others => 
					null;
			end case;    
		end if;
	end process;
	
	score_L_p:process(slow_clk, i_rst, state)
	begin
		if i_rst='0' then
			scoreL <= "0000";
		elsif slow_clk'event and slow_clk='1' then
			case state is
				when MovingR => --S0 右移中
					null;
				when MovingL => --S1 左移中
					null;
				when Lwin =>    --S3 
					if (prev_state = MovingR) then
						scoreL <= scoreL + '1';
					end if;
				when Rwin =>    --S2
					null;
				when others => 
					null;
			end case;    
		end if;
	end process;
	
	score_R_p:process(slow_clk, i_rst, state)
	begin
		if i_rst='0' then
			scoreR <= "0000";
		elsif slow_clk'event and slow_clk='1' then
			case state is
				when MovingR => --S0 右移中
					null;
				when MovingL => --S1 左移中
					null;
				when Lwin =>    --S3 
					null; 
				when Rwin =>    --S2
					if (prev_state = MovingL) then
						scoreR <= scoreR + '1';
					end if;
				when others => 
					null;
			end case;    
		end if;
	end process;
	

end Behavioral;

