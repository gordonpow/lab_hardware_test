library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vgaController is
    port (
        i_clk      : in  std_logic;
        i_rst      : in  std_logic;
        i_pixelEn  : in  std_logic;
        o_hSync    : out std_logic;
        o_vSync    : out std_logic;
        o_pixelX_b : out std_logic_vector(9 downto 0);
        o_pixelY_b : out std_logic_vector(9 downto 0);
        o_videoOn  : out std_logic
    );
end entity vgaController;

architecture rtl of vgaController is
    -- VGA 640x480 @ 60Hz 參數常數定義
    constant c_hActive_l     : integer := 640;
    constant c_hFrontPorch_l : integer := 16;
    constant c_hSync_l       : integer := 96;
    constant c_hBackPorch_l  : integer := 48;
    constant c_hTotal_l      : integer := 800;

    constant c_vActive_l     : integer := 480;
    constant c_vFrontPorch_l : integer := 10;
    constant c_vSync_l       : integer := 2;
    constant c_vBackPorch_l  : integer := 33;
    constant c_vTotal_l      : integer := 525;

    -- 計數器暫存器 (讀取與寫入訊號)
    signal v_hCount_r : unsigned(9 downto 0);
    signal v_hCount_w : unsigned(9 downto 0);
    signal v_vCount_r : unsigned(9 downto 0);
    signal v_vCount_w : unsigned(9 downto 0);

    -- 同步與視訊有效暫存器
    signal v_hSync_r   : std_logic;
    signal v_hSync_w   : std_logic;
    signal v_vSync_r   : std_logic;
    signal v_vSync_w   : std_logic;
    signal v_videoOn_r : std_logic;
    signal v_videoOn_w : std_logic;

begin
    -- 循序邏輯：時脈更新暫存器
    VGA_REG_UPDATE : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            v_hCount_r  <= (others => '0');
            v_vCount_r  <= (others => '0');
            v_hSync_r   <= '1';
            v_vSync_r   <= '1';
            v_videoOn_r <= '0';
        elsif rising_edge(i_clk) then
            if i_pixelEn = '1' then
                v_hCount_r  <= v_hCount_w;
                v_vCount_r  <= v_vCount_w;
                v_hSync_r   <= v_hSync_w;
                v_vSync_r   <= v_vSync_w;
                v_videoOn_r <= v_videoOn_w;
            end if;
        end if;
    end process VGA_REG_UPDATE;

    -- 水平計數邏輯
    H_COUNT_LOGIC : process(v_hCount_r)
    begin
        if v_hCount_r = (c_hTotal_l - 1) then
            v_hCount_w <= (others => '0');
        else
            v_hCount_w <= v_hCount_r + 1;
        end if;
    end process H_COUNT_LOGIC;

    -- 垂直計數邏輯
    V_COUNT_LOGIC : process(v_vCount_r, v_hCount_r)
    begin
        v_vCount_w <= v_vCount_r;
        if v_hCount_r = (c_hTotal_l - 1) then
            if v_vCount_r = (c_vTotal_l - 1) then
                v_vCount_w <= (others => '0');
            else
                v_vCount_w <= v_vCount_r + 1;
            end if;
        end if;
    end process V_COUNT_LOGIC;

    -- 水平同步訊號產生：在 Active+FP 到 Active+FP+Sync 期間為低電位 (主動低電位)
    v_hSync_w <= '0' when (v_hCount_r >= (c_hActive_l + c_hFrontPorch_l)) and 
                          (v_hCount_r < (c_hActive_l + c_hFrontPorch_l + c_hSync_l)) 
                else '1';

    -- 垂直同步訊號產生：在 Active+FP 到 Active+FP+Sync 期間為低電位 (主動低電位)
    v_vSync_w <= '0' when (v_vCount_r >= (c_vActive_l + c_vFrontPorch_l)) and 
                          (v_vCount_r < (c_vActive_l + c_vFrontPorch_l + c_vSync_l)) 
                else '1';

    -- 顯示有效區域判定：當 H 與 V 計數器都在 Active 範圍內
    v_videoOn_w <= '1' when (v_hCount_r < c_hActive_l) and (v_vCount_r < c_vActive_l) else '0';

    -- 輸出指派
    o_hSync    <= v_hSync_r;
    o_vSync    <= v_vSync_r;
    o_videoOn  <= v_videoOn_r;
    o_pixelX_b <= std_logic_vector(v_hCount_r);
    o_pixelY_b <= std_logic_vector(v_vCount_r);

end architecture rtl;
