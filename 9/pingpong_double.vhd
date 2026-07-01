library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pingpong_double is
    Generic ( g_maxCnt : integer := 499999 ); -- 預設 100Hz 分頻 (100MHz下)
    Port ( i_clk      : in STD_LOGIC;  -- 系統主時脈
           i_rst      : in STD_LOGIC;  -- 非同步重置 (低電平有效)
           i_sw       : in STD_LOGIC;  -- 玩家按鍵 (擊球/發球)
           i_boardId  : in STD_LOGIC;  -- 板端識別ID ('0'為左板，'1'為右板)
           io_line    : inout STD_LOGIC;  -- 共享雙板通訊線
           o_led      : out STD_LOGIC_VECTOR (7 downto 0)  -- 8-bit LED 燈號輸出
           );
end pingpong_double;

architecture Structural of pingpong_double is

    -- 宣告子模組組件
    component clkDivider
        Generic ( g_maxCnt : integer := 499999 );
        Port ( i_clk       : in STD_LOGIC;
               i_rst       : in STD_LOGIC;
               o_slowClk   : out STD_LOGIC
               );
    end component;

    component boardController
        Port ( i_clk      : in STD_LOGIC;
               i_rst      : in STD_LOGIC;
               i_slowClk  : in STD_LOGIC;
               i_sw       : in STD_LOGIC;
               i_boardId  : in STD_LOGIC;
               i_rxReady  : in STD_LOGIC;
               i_rxData   : in STD_LOGIC;
               o_txStart  : out STD_LOGIC;
               o_txData   : out STD_LOGIC;
               o_state    : out STD_LOGIC_VECTOR(2 downto 0);
               o_scoreL   : out STD_LOGIC_VECTOR(3 downto 0);
               o_scoreR   : out STD_LOGIC_VECTOR(3 downto 0)
               );
    end component;

    component linkTransceiver
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
    end component;

    component displayManager
        Port ( i_slowClk  : in STD_LOGIC;
               i_rst      : in STD_LOGIC;
               i_state    : in STD_LOGIC_VECTOR(2 downto 0);
               i_scoreL   : in STD_LOGIC_VECTOR(3 downto 0);
               i_scoreR   : in STD_LOGIC_VECTOR(3 downto 0);
               i_boardId  : in STD_LOGIC;
               o_led      : out STD_LOGIC_VECTOR(7 downto 0)
               );
    end component;

    -- 宣告內部元件連線信號 (駝峰命名法)
    signal w_slowClk   : STD_LOGIC;
    signal w_txStart   : STD_LOGIC;
    signal w_txData    : STD_LOGIC;
    signal w_rxReady   : STD_LOGIC;
    signal w_rxData    : STD_LOGIC;
    
    signal w_state     : STD_LOGIC_VECTOR(2 downto 0);
    signal w_scoreL    : STD_LOGIC_VECTOR(3 downto 0);
    signal w_scoreR    : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- 1. 實體化時脈分頻模組
    u_clkDivider : clkDivider
        generic map (
            g_maxCnt => g_maxCnt
        )
        port map (
            i_clk     => i_clk,
            i_rst     => i_rst,
            o_slowClk => w_slowClk
        );

    -- 2. 實體化板端控制器
    u_boardController : boardController
        port map (
            i_clk     => i_clk,
            i_rst     => i_rst,
            i_slowClk => w_slowClk,
            i_sw      => i_sw,
            i_boardId => i_boardId,
            i_rxReady => w_rxReady,
            i_rxData  => w_rxData,
            o_txStart => w_txStart,
            o_txData  => w_txData,
            o_state   => w_state,
            o_scoreL  => w_scoreL,
            o_scoreR  => w_scoreR
        );

    -- 3. 實體化雙板通訊收發器
    u_linkTransceiver : linkTransceiver
        port map (
            i_clk     => i_clk,
            i_rst     => i_rst,
            i_slowClk => w_slowClk,
            i_boardId => i_boardId,
            i_txStart => w_txStart,
            i_txData  => w_txData,
            o_rxReady => w_rxReady,
            o_rxData  => w_rxData,
            io_line   => io_line
        );

    -- 4. 實體化顯示與計分管理器
    u_displayManager : displayManager
        port map (
            i_slowClk => w_slowClk,
            i_rst     => i_rst,
            i_state   => w_state,
            i_scoreL  => w_scoreL,
            i_scoreR  => w_scoreR,
            i_boardId => i_boardId,
            o_led     => o_led
        );

end Structural;
