library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity videoGenerator is
    port (
        i_clk            : in  std_logic;
        i_pixelEn        : in  std_logic;
        i_pixelX_b       : in  std_logic_vector(9 downto 0);
        i_pixelY_b       : in  std_logic_vector(9 downto 0);
        i_videoOn        : in  std_logic;
        i_leftPaddleY_b  : in  std_logic_vector(9 downto 0);
        i_rightPaddleY_b : in  std_logic_vector(9 downto 0);
        i_ballX_b        : in  std_logic_vector(9 downto 0);
        i_ballY_b        : in  std_logic_vector(9 downto 0);
        i_leftScore_b    : in  std_logic_vector(3 downto 0);
        i_rightScore_b   : in  std_logic_vector(3 downto 0);
        i_gameState_b    : in  std_logic_vector(1 downto 0);
        i_winner         : in  std_logic;
        o_vgaRed_b       : out std_logic_vector(3 downto 0);
        o_vgaGreen_b     : out std_logic_vector(3 downto 0);
        o_vgaBlue_b      : out std_logic_vector(3 downto 0)
    );
end entity videoGenerator;

architecture rtl of videoGenerator is
    -- 像素與物件位置訊號
    signal v_pixelX : integer;
    signal v_pixelY : integer;
    
    signal v_leftPaddleY  : integer;
    signal v_rightPaddleY : integer;
    signal v_ballX        : integer;
    signal v_ballY        : integer;
    signal v_leftScore    : integer range 0 to 15;
    signal v_rightScore   : integer range 0 to 15;
    
    -- 顏色輸出暫存器
    signal v_vgaRed_r   : std_logic_vector(3 downto 0);
    signal v_vgaRed_w   : std_logic_vector(3 downto 0);
    signal v_vgaGreen_r : std_logic_vector(3 downto 0);
    signal v_vgaGreen_w : std_logic_vector(3 downto 0);
    signal v_vgaBlue_r  : std_logic_vector(3 downto 0);
    signal v_vgaBlue_w  : std_logic_vector(3 downto 0);

    -- 3x5 字型定義 (一律用大寫型態)
    type FONT_ARRAY is array (0 to 15) of std_logic_vector(14 downto 0);
    constant c_fonts_b : FONT_ARRAY := (
        0  => "111101101101111", -- '0'
        1  => "010010010010010", -- '1'
        2  => "111001111100111", -- '2'
        3  => "111001111001111", -- '3'
        4  => "101101111001001", -- '4'
        5  => "111100111001111", -- '5'
        6  => "111100111101111", -- '6'
        7  => "111001001001001", -- '7'
        8  => "111101111101111", -- '8'
        9  => "111101111001111", -- '9'
        10 => "111101111100100", -- 'P'
        11 => "101101101111101", -- 'W'
        12 => "111010010010111", -- 'I'
        13 => "101111101101101", -- 'N'
        14 => "100100100100111", -- 'L'
        15 => "111101111101101"  -- 'R'
    );

    -- 繪圖區域判定
    signal v_drawLeftPaddle  : std_logic;
    signal v_drawRightPaddle : std_logic;
    signal v_drawBall        : std_logic;
    signal v_drawNet         : std_logic;
    
    -- 文字渲染訊號
    signal v_drawLeftScore  : std_logic;
    signal v_drawRightScore : std_logic;
    signal v_drawWinnerText : std_logic;
    signal v_winnerTextPixel: std_logic;

begin
    -- 轉換輸入信號為整數，便於做範圍判定
    v_pixelX <= to_integer(unsigned(i_pixelX_b));
    v_pixelY <= to_integer(unsigned(i_pixelY_b));
    
    v_leftPaddleY  <= to_integer(unsigned(i_leftPaddleY_b));
    v_rightPaddleY <= to_integer(unsigned(i_rightPaddleY_b));
    v_ballX        <= to_integer(unsigned(i_ballX_b));
    v_ballY        <= to_integer(unsigned(i_ballY_b));
    v_leftScore    <= to_integer(unsigned(i_leftScore_b));
    v_rightScore   <= to_integer(unsigned(i_rightScore_b));

    RGB_REG_UPDATE : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_pixelEn = '1' then
                v_vgaRed_r   <= v_vgaRed_w;
                v_vgaGreen_r <= v_vgaGreen_w;
                v_vgaBlue_r  <= v_vgaBlue_w;
            end if;
        end if;
    end process RGB_REG_UPDATE;

    -- 1. 擋板繪圖判定 (左擋板 X:30-40, 右擋板 X:600-610)
    v_drawLeftPaddle <= '1' when (v_pixelX >= 30 and v_pixelX < 40) and 
                                 (v_pixelY >= v_leftPaddleY and v_pixelY < v_leftPaddleY + 60) 
                        else '0';

    v_drawRightPaddle <= '1' when (v_pixelX >= 600 and v_pixelX < 610) and 
                                  (v_pixelY >= v_rightPaddleY and v_pixelY < v_rightPaddleY + 60) 
                         else '0';

    -- 2. 球體繪圖判定 (球 8x8 像素)
    v_drawBall <= '1' when (v_pixelX >= v_ballX and v_pixelX < v_ballX + 8) and 
                           (v_pixelY >= v_ballY and v_pixelY < v_ballY + 8) 
                  else '0';

    -- 3. 中央虛線網子繪圖判定 (X:319-320，每 16 像素畫 8 像素)
    v_drawNet <= '1' when (v_pixelX >= 319 and v_pixelX <= 320) and 
                          ((v_pixelY mod 16) < 8) 
                 else '0';

    -- 4. 雙方分數繪圖判定 (字型放大 8 倍: 寬 24 像素, 高 40 像素)
    -- 左分數顯示區：X 在 [180, 203], Y 在 [40, 79]
    LEFT_SCORE_RENDER : process(v_pixelX, v_pixelY, v_leftScore)
        variable col : integer;
        variable row : integer;
        variable idx : integer;
    begin
        v_drawLeftScore <= '0';
        if (v_pixelX >= 180 and v_pixelX < 204) and (v_pixelY >= 40 and v_pixelY < 80) then
            col := (v_pixelX - 180) / 8;
            row := (v_pixelY - 40) / 8;
            idx := row * 3 + col;
            if idx >= 0 and idx < 15 then
                if c_fonts_b(v_leftScore)(14 - idx) = '1' then
                    v_drawLeftScore <= '1';
                end if;
            end if;
        end if;
    end process LEFT_SCORE_RENDER;

    -- 右分數顯示區：X 在 [436, 459], Y 在 [40, 79]
    RIGHT_SCORE_RENDER : process(v_pixelX, v_pixelY, v_rightScore)
        variable col : integer;
        variable row : integer;
        variable idx : integer;
    begin
        v_drawRightScore <= '0';
        if (v_pixelX >= 436 and v_pixelX < 460) and (v_pixelY >= 40 and v_pixelY < 80) then
            col := (v_pixelX - 436) / 8;
            row := (v_pixelY - 40) / 8;
            idx := row * 3 + col;
            if idx >= 0 and idx < 15 then
                if c_fonts_b(v_rightScore)(14 - idx) = '1' then
                    v_drawRightScore <= '1';
                end if;
            end if;
        end if;
    end process RIGHT_SCORE_RENDER;

    -- 5. 遊戲結束 (ST_OVER) 畫面 Winner 資訊顯示
    -- 中央顯示 "WIN" (W: 260-283, I: 300-323, N: 340-363)
    -- 左方或右方對應玩家 "P 1" (P: 140-163, 1: 180-203) 或 "P 2" (P: 476-499, 2: 516-539)
    WINNER_TEXT_RENDER : process(v_pixelX, v_pixelY, i_winner)
        variable col : integer;
        variable row : integer;
        variable idx : integer;
    begin
        v_winnerTextPixel <= '0';
        
        if (v_pixelY >= 200 and v_pixelY < 240) then
            -- 顯示 W
            if (v_pixelX >= 260 and v_pixelX < 284) then
                col := (v_pixelX - 260) / 8;
                row := (v_pixelY - 200) / 8;
                idx := row * 3 + col;
                v_winnerTextPixel <= c_fonts_b(11)(14 - idx); -- W
            -- 顯示 I
            elsif (v_pixelX >= 300 and v_pixelX < 324) then
                col := (v_pixelX - 300) / 8;
                row := (v_pixelY - 200) / 8;
                idx := row * 3 + col;
                v_winnerTextPixel <= c_fonts_b(12)(14 - idx); -- I
            -- 顯示 N
            elsif (v_pixelX >= 340 and v_pixelX < 364) then
                col := (v_pixelX - 340) / 8;
                row := (v_pixelY - 200) / 8;
                idx := row * 3 + col;
                v_winnerTextPixel <= c_fonts_b(13)(14 - idx); -- N
            
            -- 玩家 1 (左邊獲勝)
            elsif i_winner = '0' then
                if (v_pixelX >= 140 and v_pixelX < 164) then
                    col := (v_pixelX - 140) / 8;
                    row := (v_pixelY - 200) / 8;
                    idx := row * 3 + col;
                    v_winnerTextPixel <= c_fonts_b(10)(14 - idx); -- P
                elsif (v_pixelX >= 180 and v_pixelX < 204) then
                    col := (v_pixelX - 180) / 8;
                    row := (v_pixelY - 200) / 8;
                    idx := row * 3 + col;
                    v_winnerTextPixel <= c_fonts_b(1)(14 - idx);  -- 1
                end if;
                
            -- 玩家 2 (右邊獲勝)
            elsif i_winner = '1' then
                if (v_pixelX >= 476 and v_pixelX < 500) then
                    col := (v_pixelX - 476) / 8;
                    row := (v_pixelY - 200) / 8;
                    idx := row * 3 + col;
                    v_winnerTextPixel <= c_fonts_b(10)(14 - idx); -- P
                elsif (v_pixelX >= 516 and v_pixelX < 540) then
                    col := (v_pixelX - 516) / 8;
                    row := (v_pixelY - 200) / 8;
                    idx := row * 3 + col;
                    v_winnerTextPixel <= c_fonts_b(2)(14 - idx);  -- 2
                end if;
            end if;
        end if;
    end process WINNER_TEXT_RENDER;

    v_drawWinnerText <= '1' when (i_gameState_b = "11" and v_winnerTextPixel = '1') else '0';

    -- 6. 組合顏色邏輯
    COLOR_MIXER : process(i_videoOn, i_gameState_b, i_winner, v_pixelX, v_drawLeftPaddle, v_drawRightPaddle,
            v_drawBall, v_drawNet, v_drawLeftScore, v_drawRightScore, v_drawWinnerText)
    begin
        -- 預設黑色
        v_vgaRed_w   <= "0000";
        v_vgaGreen_w <= "0000";
        v_vgaBlue_w  <= "0000";

        if i_videoOn = '1' then
            
            -- 在結束畫面時，為獲勝方上底色 (深藍色)，非獲勝方維持黑底
            if i_gameState_b = "11" then
                if i_winner = '0' and v_pixelX < 320 then
                    -- 左方獲勝，左半部為深藍色
                    v_vgaRed_w   <= "0000";
                    v_vgaGreen_w <= "0000";
                    v_vgaBlue_w  <= "0100";
                elsif i_winner = '1' and v_pixelX >= 320 then
                    -- 右方獲勝，右半部為深藍色
                    v_vgaRed_w   <= "0000";
                    v_vgaGreen_w <= "0000";
                    v_vgaBlue_w  <= "0100";
                end if;
            end if;

            -- 優先著色文字與遊戲物件
            if v_drawWinnerText = '1' then
                -- 贏家宣告字樣為金黃色
                v_vgaRed_w   <= "1111";
                v_vgaGreen_w <= "1101";
                v_vgaBlue_w  <= "0000";
            
            elsif v_drawLeftScore = '1' or v_drawRightScore = '1' then
                -- 分數顯示為黃色
                v_vgaRed_w   <= "1111";
                v_vgaGreen_w <= "1111";
                v_vgaBlue_w  <= "0000";
                
            elsif v_drawLeftPaddle = '1' or v_drawRightPaddle = '1' then
                -- 擋板顯示為青色
                v_vgaRed_w   <= "0000";
                v_vgaGreen_w <= "1111";
                v_vgaBlue_w  <= "1111";
                
            elsif v_drawBall = '1' then
                -- 乒乓球為白色
                v_vgaRed_w   <= "1111";
                v_vgaGreen_w <= "1111";
                v_vgaBlue_w  <= "1111";
                
            elsif v_drawNet = '1' and i_gameState_b /= "11" then
                -- 網子中線為灰色
                v_vgaRed_w   <= "1000";
                v_vgaGreen_w <= "1000";
                v_vgaBlue_w  <= "1000";
            end if;
            
        end if;
    end process COLOR_MIXER;

    -- 輸出指派
    o_vgaRed_b   <= v_vgaRed_r;
    o_vgaGreen_b <= v_vgaGreen_r;
    o_vgaBlue_b  <= v_vgaBlue_r;

end architecture rtl;
