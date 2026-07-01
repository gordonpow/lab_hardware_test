library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity linkTransceiver is
    Port ( i_clk      : in STD_LOGIC;
           i_rst      : in STD_LOGIC;
           i_slowClk  : in STD_LOGIC;
           i_boardId  : in STD_LOGIC;
           i_txStart  : in STD_LOGIC;
           i_txData   : in STD_LOGIC;
           o_rxReady  : out STD_LOGIC;
           o_rxData   : out STD_LOGIC;
           io_line    : inout STD_LOGIC
           );
end linkTransceiver;

architecture Behavioral of linkTransceiver is

    -- 傳送控制暫存器 (慢速時脈下)
    signal r_txPulse_r    : STD_LOGIC := '0';
    signal r_txPulse_w    : STD_LOGIC := '0';
    signal r_txType_r     : STD_LOGIC := '0';  -- '0' 代表傳球, '1' 代表得分
    signal r_txType_w     : STD_LOGIC := '0';
    signal r_txCnt_r      : unsigned(2 downto 0) := "000";
    signal r_txCnt_w      : unsigned(2 downto 0) := "000";

    -- 接收移位暫存器 (慢速時脈下)
    signal r_rxReg_r      : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal r_rxReg_w      : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal r_rxHighCnt_r  : unsigned(2 downto 0) := "000";
    signal r_rxHighCnt_w  : unsigned(2 downto 0) := "000";

    signal r_rxReady_r    : STD_LOGIC := '0';
    signal r_rxReady_w    : STD_LOGIC := '0';
    signal r_rxData_r     : STD_LOGIC := '0';
    signal r_rxData_w     : STD_LOGIC := '0';

    signal w_rxVal_r      : STD_LOGIC := '0';

begin

    o_rxReady <= r_rxReady_r;
    o_rxData  <= r_rxData_r;

    -- 1. TX_GEN: 慢速時脈下運作，穩定的脈衝發送
    TX_GEN : process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_txPulse_r <= '0';
            r_txType_r  <= '0';
            r_txCnt_r   <= "000";
        elsif rising_edge(i_slowClk) then
            r_txPulse_r <= r_txPulse_w;
            r_txType_r  <= r_txType_w;
            r_txCnt_r   <= r_txCnt_w;
        end if;
    end process;

    process(r_txPulse_r, r_txType_r, r_txCnt_r, i_txStart, i_txData)
    begin
        r_txPulse_w <= r_txPulse_r;
        r_txType_w  <= r_txType_r;
        r_txCnt_w   <= r_txCnt_r;

        if r_txPulse_r = '0' then
            if i_txStart = '1' then
                r_txPulse_w <= '1';
                r_txType_w  <= i_txData;
                if i_txData = '0' then
                    r_txCnt_w <= "001"; -- 傳球高電平 1 拍
                else
                    r_txCnt_w <= "011"; -- 得分同步高電平 3 拍
                end if;
            end if;
        else
            if r_txCnt_r > 0 then
                r_txCnt_w <= r_txCnt_r - 1;
            else
                r_txPulse_w <= '0';
            end if;
        end if;
    end process;

    -- 2. RX_DET: 慢速時脈下運作，採用穩定的移位判定
    RX_DET : process(i_slowClk, i_rst)
    begin
        if i_rst = '1' then
            r_rxReg_r     <= "00";
            r_rxHighCnt_r <= "000";
            r_rxReady_r   <= '0';
            r_rxData_r    <= '0';
        elsif rising_edge(i_slowClk) then
            r_rxReg_r     <= r_rxReg_w;
            r_rxHighCnt_r <= r_rxHighCnt_w;
            r_rxReady_r   <= r_rxReady_w;
            r_rxData_r    <= r_rxData_w;
        end if;
    end process;

    r_rxReg_w <= r_rxReg_r(0) & w_rxVal_r;

    process(r_rxReg_r, r_rxHighCnt_r, w_rxVal_r)
    begin
        r_rxHighCnt_w <= r_rxHighCnt_r;
        r_rxReady_w   <= '0';
        r_rxData_w    <= '0';

        if w_rxVal_r = '1' then
            r_rxHighCnt_w <= r_rxHighCnt_r + 1;
        else
            -- 當脈衝結束時（由 1 變 0）
            if r_rxHighCnt_r = 1 or r_rxHighCnt_r = 2 then
                r_rxReady_w <= '1';
                r_rxData_w  <= '0'; -- 傳球脈衝接收完成
            elsif r_rxHighCnt_r >= 3 then
                r_rxReady_w <= '1';
                r_rxData_w  <= '1'; -- 得分同步接收完成
            end if;
            r_rxHighCnt_w <= "000";
        end if;
    end process;

    -- 3. TRI_CTRL: 慢速時域自發自收屏蔽，100% 防拖尾防雜訊
    TRI_CTRL : process(r_txPulse_r, io_line)
    begin
        if r_txPulse_r = '1' then
            w_rxVal_r <= '0';
        else
            w_rxVal_r <= io_line;
        end if;
    end process;

    -- 實體雙向三態輸出：發送時輸出 r_txPulse_r
    io_line <= r_txPulse_r when r_txPulse_r = '1' else 'Z';

end Behavioral;
