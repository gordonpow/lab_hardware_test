----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2026/03/15 22:15:26
-- Design Name: 
-- Module Name: Top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top is
  port (
    i_clk        : in std_logic;
    i_rst        : in std_logic;
    i_en         : in std_logic;
    i_speed_up   : in std_logic;
    i_speed_down : in std_logic;

    o_Pwmout : out std_logic
  );
end Top;

architecture Behavioral of Top is

  signal Div_2hz  : std_logic;
  signal Div_1khz : std_logic;
  component Clock_Divider is
    generic (
      SYS_CLK_FREQ : integer := 50_000_000
    );
    port (
      i_clk    : in std_logic;
      i_rst    : in std_logic;
      Clk_2Hz  : out std_logic;
      CLK_1khz : out std_logic
    );
  end component;
  signal i_Period : std_logic_vector(7 downto 0);
  signal i_Duty   : std_logic_vector(7 downto 0);

  component PWM is
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
  end component;
  signal up_q0   : std_logic;
  signal up_q1   : std_logic;
  signal down_q0 : std_logic;
  signal down_q1 : std_logic;

  signal LoopCnt    : integer range 255 downto 0;
  signal SpeedCnt   : integer range 20 downto 0;
  signal FlashSpeed : integer range 20 downto 0;
  signal flag       : std_logic;

  signal s_Pwmout : std_logic;

begin

  Inst_Clock_Divider : Clock_Divider
  generic map(
    SYS_CLK_FREQ => 100_000_000 -- ]AOlDɯ߬ 50MHz
  )
  port map
  (
    i_clk    => i_clk,
    i_rst    => i_rst,
    Clk_2Hz  => div_2hz, -- ��X 2Hz �ߪi�����A��
    Clk_1khz => div_1khz
  );
  PWM1 : PWM

  port map
  (
    i_clk    => div_1khz,
    i_rst    => i_rst,
    i_en     => i_en,
    i_Period => std_logic_vector(to_unsigned(255, 8)),
    i_Duty   => i_Duty,
    o_Pwmout => s_Pwmout
  );

  -- ==============================================================
  -- ���s����G���޿� (�]�t��t����)
  -- ==============================================================
  Speed_control :process (div_1khz, i_rst)
  begin
    if i_rst = '1' then
      FlashSpeed <= 10; -- ���m�ɦ^�� 50% �G��
      up_q0      <= '0';
      up_q1      <= '0';
      down_q0    <= '0';
      down_q1    <= '0';

    elsif rising_edge(div_1khz) then
      -- 1. �N�{�b�����s���A�u���v�i�Ȧs���� (�s�y�ɶ��t)
      up_q0 <= i_speed_up;
      up_q1 <= up_q0;

      down_q0 <= i_speed_down;
      down_q1 <= down_q0;

      -- 2. �P�_�O�_���u����U������ (Rising Edge)�v
      -- �� q0(�{�b)�O 1�A�B q1(�W�@��)�O 0�A�N�����s��Q���U�I
      if (up_q0 = '1' and up_q1 = '0') then
        if FlashSpeed > 0 then
          FlashSpeed <= FlashSpeed - 5; -- �C�����U�W�[ 10% �G��
        end if;

      elsif (down_q0 = '1' and down_q1 = '0') then
        if FlashSpeed < 20 then
          FlashSpeed <= FlashSpeed + 5;
        end if;
      end if;

    end if;
  end process;
  process (s_Pwmout, i_rst, FlashSpeed)
  begin
    if (i_rst = '1') then
      LoopCnt <= 0;
      flag    <= '0';
    elsif rising_edge(s_Pwmout) then
      if (SpeedCnt <= FlashSpeed) then
        SpeedCnt     <= SpeedCnt + 1;
      else
        SpeedCnt <= 0;

        if (LoopCnt >= 254) then
          flag           <= '1';
        elsif (LoopCnt <= 1) then
          flag           <= '0';

        end if;
        if (flag = '1') then
          if (LoopCnt >= 1) then
            LoopCnt <= LoopCnt - 1;
          end if;
        else
          if (LoopCnt <= 254) then
            LoopCnt     <= LoopCnt + 1;
          end if;
        end if;

      end if;
    end if;
  end process;

  i_Duty   <= std_logic_vector(to_unsigned(LoopCnt, 8));
  o_Pwmout <= s_Pwmout;
end Behavioral;
