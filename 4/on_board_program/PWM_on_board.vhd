library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity PWM is

  generic (
    DATA_WIDTH : integer := 8
  );
  port (
    i_clk    : in std_logic;
    i_rst    : in std_logic;
    i_en     : in std_logic;
    i_Period : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    i_Duty   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
    o_Cnt1_q : out std_logic_vector(7 downto 0);
    o_Cnt2_q : out std_logic_vector(7 downto 0);
    o_Pwmout : out std_logic
  );
end PWM;

architecture Behavioral of PWM is

  type StateType is (Idle, Cnt1Count, Cnt2Count);
  signal CurrentState : StateType;

  signal r_Cnt1 : UNSIGNED(7 downto 0);
  signal r_Cnt2 : UNSIGNED(7 downto 0);

  signal i_Cnt1_lim_up : UNSIGNED(7 downto 0);
  signal i_Cnt2_lim_up : UNSIGNED(7 downto 0);
begin

  Conversion :process (i_Period, i_Duty)
  begin
    i_Cnt2_lim_up <= unsigned(i_Duty) - 1;
    if unsigned(i_Period) >= unsigned(i_Duty) then
      i_Cnt1_lim_up <= unsigned(i_Period) - unsigned(i_Duty);
    else
      i_Cnt1_lim_up <= (others => '0');
    end if;
  end process;

  -- State Transition Process
  FSM :process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      CurrentState <= Idle;
    elsif rising_edge(i_clk) then
      if i_en = '0' then
        CurrentState <= Idle;
      else
        case CurrentState is
          when Idle =>
            if i_en = '1' then
              CurrentState <= Cnt1Count;
            end if;

          when Cnt1Count =>
            if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
              CurrentState <= Cnt2Count;
            end if;

          when Cnt2Count =>
            if r_Cnt2 >= unsigned(i_Cnt2_lim_up) then
              CurrentState <= Cnt1Count;
            end if;

          when others =>
            CurrentState <= Idle;
        end case;
      end if;
    end if;
  end process;

  -- Counter Logic Process
  Counter :process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      r_Cnt1 <= (others => '0');
      r_Cnt2 <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_en = '0' or CurrentState = Idle then
        r_Cnt1 <= (others => '0');
        r_Cnt2 <= (others => '0');
      else
        -- Active Counter Logic
        if CurrentState = Cnt1Count then
          -- FIX: Reset immediately when limit is reached to prevent counting to Limit+1
          if r_Cnt1 >= unsigned(i_Cnt1_lim_up) then
            r_Cnt1 <= (others => '0');
            r_Cnt2 <= to_unsigned(1, 8); -- Start Cnt2 immediately
          else
            r_Cnt1 <= r_Cnt1 + 1;
            r_Cnt2 <= (others => '0');
          end if;

        elsif CurrentState = Cnt2Count then
          if r_Cnt2 >= unsigned(i_Cnt2_lim_up) then
            r_Cnt2 <= (others => '0');
            r_Cnt1 <= to_unsigned(1, 8); -- Start Cnt1 immediately
          else
            r_Cnt2 <= r_Cnt2 + 1;
            r_Cnt1 <= (others => '0');
          end if;
        else
          r_Cnt1 <= (others => '0');
          r_Cnt2 <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- Output Assignments
  o_Cnt1_q <= std_logic_vector(r_Cnt1);
  o_Cnt2_q <= std_logic_vector(r_Cnt2);

  Output :process (CurrentState)
  begin
    if CurrentState = Cnt2Count then
      o_Pwmout <= '1';
    else
      o_Pwmout <= '0';
    end if;
  end process;

end Behavioral;
