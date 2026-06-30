library ieee;
use ieee.std_logic_1164.all;

entity pongGameTop is
    port (
        i_clk        : in  std_logic;
        i_rst        : in  std_logic;
        i_leftUp     : in  std_logic;
        i_leftDown   : in  std_logic;
        i_rightUp    : in  std_logic;
        i_rightDown  : in  std_logic;
        o_hSync      : out std_logic;
        o_vSync      : out std_logic;
        o_vgaRed_b   : out std_logic_vector(3 downto 0);
        o_vgaGreen_b : out std_logic_vector(3 downto 0);
        o_vgaBlue_b  : out std_logic_vector(3 downto 0)
    );
end entity pongGameTop;

architecture rtl of pongGameTop is

    -- 1. 內部訊號宣告 (符合變數命名規範，`v_` 開頭，Bus 用 `_b`)
    signal v_pixelEn_w       : std_logic;
    signal v_hSync_w         : std_logic;
    signal v_vSync_w         : std_logic;
    signal v_videoOn_w       : std_logic;
    signal v_pixelX_b        : std_logic_vector(9 downto 0);
    signal v_pixelY_b        : std_logic_vector(9 downto 0);
    
    signal v_leftPaddleY_b   : std_logic_vector(9 downto 0);
    signal v_rightPaddleY_b  : std_logic_vector(9 downto 0);
    signal v_ballX_b         : std_logic_vector(9 downto 0);
    signal v_ballY_b         : std_logic_vector(9 downto 0);
    signal v_leftScore_b     : std_logic_vector(3 downto 0);
    signal v_rightScore_b    : std_logic_vector(3 downto 0);
    signal v_gameState_b     : std_logic_vector(1 downto 0);
    signal v_winner_w        : std_logic;

begin

    -- 2. 實例化：時脈除頻模組
    u_clkDivider : entity work.clkDivider
        port map (
            i_clk     => i_clk,
            i_rst     => i_rst,
            o_pixelEn => v_pixelEn_w
        );

    -- 3. 實例化：VGA 同步控制器
    u_vgaController : entity work.vgaController
        port map (
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_pixelEn  => v_pixelEn_w,
            o_hSync    => v_hSync_w,
            o_vSync    => v_vSync_w,
            o_pixelX_b => v_pixelX_b,
            o_pixelY_b => v_pixelY_b,
            o_videoOn  => v_videoOn_w
        );

    -- 4. 實例化：遊戲邏輯與碰撞控制器
    u_gameLogic : entity work.gameLogic
        port map (
            i_clk            => i_clk,
            i_rst            => i_rst,
            i_vSync          => v_vSync_w,
            i_leftUp         => i_leftUp,
            i_leftDown       => i_leftDown,
            i_rightUp        => i_rightUp,
            i_rightDown      => i_rightDown,
            o_leftPaddleY_b  => v_leftPaddleY_b,
            o_rightPaddleY_b => v_rightPaddleY_b,
            o_ballX_b        => v_ballX_b,
            o_ballY_b        => v_ballY_b,
            o_leftScore_b    => v_leftScore_b,
            o_rightScore_b   => v_rightScore_b,
            o_gameState_b    => v_gameState_b,
            o_winner         => v_winner_w
        );

    -- 5. 實例化：影像與文字渲染模組
    u_videoGenerator : entity work.videoGenerator
        port map (
            i_clk            => i_clk,
            i_pixelEn        => v_pixelEn_w,
            i_pixelX_b       => v_pixelX_b,
            i_pixelY_b       => v_pixelY_b,
            i_videoOn        => v_videoOn_w,
            i_leftPaddleY_b  => v_leftPaddleY_b,
            i_rightPaddleY_b => v_rightPaddleY_b,
            i_ballX_b        => v_ballX_b,
            i_ballY_b        => v_ballY_b,
            i_leftScore_b    => v_leftScore_b,
            i_rightScore_b   => v_rightScore_b,
            i_gameState_b    => v_gameState_b,
            i_winner         => v_winner_w,
            o_vgaRed_b       => o_vgaRed_b,
            o_vgaGreen_b     => o_vgaGreen_b,
            o_vgaBlue_b      => o_vgaBlue_b
        );

    -- 6. 輸出同步訊號指派
    o_hSync <= v_hSync_w;
    o_vSync <= v_vSync_w;

end architecture rtl;
