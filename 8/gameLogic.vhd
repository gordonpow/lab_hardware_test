library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gameLogic is
    port (
        i_clk            : in  std_logic;
        i_rst            : in  std_logic;
        i_vSync          : in  std_logic;
        i_leftUp         : in  std_logic;
        i_leftDown       : in  std_logic;
        i_rightUp        : in  std_logic;
        i_rightDown      : in  std_logic;
        o_leftPaddleY_b  : out std_logic_vector(9 downto 0);
        o_rightPaddleY_b : out std_logic_vector(9 downto 0);
        o_ballX_b        : out std_logic_vector(9 downto 0);
        o_ballY_b        : out std_logic_vector(9 downto 0);
        o_leftScore_b    : out std_logic_vector(3 downto 0);
        o_rightScore_b   : out std_logic_vector(3 downto 0);
        o_gameState_b    : out std_logic_vector(1 downto 0);
        o_winner         : out std_logic
    );
end entity gameLogic;

architecture rtl of gameLogic is
    -- 定義 FSM 狀態類型 (大寫)
    type STATE is (ST_IDLE, ST_PLAY, ST_SCORE, ST_OVER);

    -- 狀態暫存器
    signal v_state_r : STATE;
    signal v_state_w : STATE;

    -- 常數定義
    constant c_paddleWidth_l   : integer := 10;
    constant c_paddleHeight_l  : integer := 60;
    constant c_paddleSpeed_l   : integer := 5;
    constant c_ballSize_l      : integer := 8;
    constant c_ballSpeedX_l    : integer := 4;
    constant c_ballSpeedY_l    : integer := 3;
    constant c_winScore_l      : integer := 3;

    -- 遊戲物件位置與速度暫存器
    signal v_leftPaddleY_r  : integer range 0 to 480;
    signal v_leftPaddleY_w  : integer range 0 to 480;
    signal v_rightPaddleY_r : integer range 0 to 480;
    signal v_rightPaddleY_w : integer range 0 to 480;

    signal v_ballX_r  : integer range -50 to 700;
    signal v_ballX_w  : integer range -50 to 700;
    signal v_ballY_r  : integer range -50 to 500;
    signal v_ballY_w  : integer range -50 to 500;
    signal v_ballVx_r : integer range -10 to 10;
    signal v_ballVx_w : integer range -10 to 10;
    signal v_ballVy_r : integer range -10 to 10;
    signal v_ballVy_w : integer range -10 to 10;

    -- 分數暫存器
    signal v_leftScore_r  : integer range 0 to 15;
    signal v_leftScore_w  : integer range 0 to 15;
    signal v_rightScore_r : integer range 0 to 15;
    signal v_rightScore_w : integer range 0 to 15;

    -- 得分後暫停延遲計數器
    signal v_delayCount_r : integer range 0 to 127;
    signal v_delayCount_w : integer range 0 to 127;

    -- 贏家標記
    signal v_winner_r : std_logic;
    signal v_winner_w : std_logic;

    -- 垂直同步信號邊緣偵測暫存器
    signal v_vSyncPrev_r : std_logic;
    signal v_frameTick_w : std_logic;

begin
    -- 邊緣偵測：當 vSync 發生下降沿 (進入垂直消隱期)，觸發物理位置更新
    v_frameTick_w <= '1' when (v_vSyncPrev_r = '1' and i_vSync = '0') else '0';

    -- 循序邏輯：時脈更新所有暫存器
    GAME_REG_UPDATE : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            v_state_r        <= ST_IDLE;
            v_leftPaddleY_r  <= 210; -- 初始位置居中
            v_rightPaddleY_r <= 210;
            v_ballX_r        <= 316; -- 初始球置中
            v_ballY_r        <= 236;
            v_ballVx_r       <= c_ballSpeedX_l;
            v_ballVy_r       <= c_ballSpeedY_l;
            v_leftScore_r    <= 0;
            v_rightScore_r   <= 0;
            v_delayCount_r   <= 0;
            v_winner_r       <= '0';
            v_vSyncPrev_r    <= '1';
        elsif rising_edge(i_clk) then
            v_vSyncPrev_r <= i_vSync;
            
            -- 只有在 frameTick 觸發時才更新遊戲狀態與所有物理暫存器
            if v_frameTick_w = '1' then
                v_state_r        <= v_state_w;
                v_leftPaddleY_r  <= v_leftPaddleY_w;
                v_rightPaddleY_r <= v_rightPaddleY_w;
                v_ballX_r        <= v_ballX_w;
                v_ballY_r        <= v_ballY_w;
                v_ballVx_r       <= v_ballVx_w;
                v_ballVy_r       <= v_ballVy_w;
                v_leftScore_r    <= v_leftScore_w;
                v_rightScore_r   <= v_rightScore_w;
                v_delayCount_r   <= v_delayCount_w;
                v_winner_r       <= v_winner_w;
            end if;
        end if;
    end process GAME_REG_UPDATE;

    -- 組合邏輯：計算下一狀態與暫存器寫入值
    GAME_COMB_LOGIC : process(v_state_r, v_leftPaddleY_r, v_rightPaddleY_r, v_ballX_r, v_ballY_r,
            v_ballVx_r, v_ballVy_r, v_leftScore_r, v_rightScore_r, v_delayCount_r,
            v_winner_r, i_leftUp, i_leftDown, i_rightUp, i_rightDown)
    begin
        -- 預設下一狀態與位置維持不變
        v_state_w        <= v_state_r;
        v_leftPaddleY_w  <= v_leftPaddleY_r;
        v_rightPaddleY_w <= v_rightPaddleY_r;
        v_ballX_w        <= v_ballX_r;
        v_ballY_w        <= v_ballY_r;
        v_ballVx_w       <= v_ballVx_r;
        v_ballVy_w       <= v_ballVy_r;
        v_leftScore_w    <= v_leftScore_r;
        v_rightScore_w   <= v_rightScore_r;
        v_delayCount_w   <= v_delayCount_r;
        v_winner_w       <= v_winner_r;

        case v_state_r is
            
            -- 狀態 ST_IDLE: 等待任意鍵開始
            when ST_IDLE =>
                -- 球置中，不移動
                v_ballX_w    <= 316;
                v_ballY_w    <= 236;
                v_ballVx_w   <= c_ballSpeedX_l;
                v_ballVy_w   <= c_ballSpeedY_l;
                v_leftScore_w  <= 0;
                v_rightScore_w <= 0;
                v_leftPaddleY_w  <= 210;
                v_rightPaddleY_w <= 210;
                v_delayCount_w <= 0;
                
                -- 任一鍵按下即進入遊戲
                if i_leftUp = '1' or i_leftDown = '1' or i_rightUp = '1' or i_rightDown = '1' then
                    v_state_w <= ST_PLAY;
                end if;

            -- 狀態 ST_PLAY: 遊戲進行中
            when ST_PLAY =>
                -- 1. 擋板移動與邊界限制
                if i_leftUp = '1' then
                    if v_leftPaddleY_r >= c_paddleSpeed_l then
                        v_leftPaddleY_w <= v_leftPaddleY_r - c_paddleSpeed_l;
                    else
                        v_leftPaddleY_w <= 0;
                    end if;
                elsif i_leftDown = '1' then
                    if v_leftPaddleY_r <= (480 - c_paddleHeight_l - c_paddleSpeed_l) then
                        v_leftPaddleY_w <= v_leftPaddleY_r + c_paddleSpeed_l;
                    else
                        v_leftPaddleY_w <= 480 - c_paddleHeight_l;
                    end if;
                end if;

                if i_rightUp = '1' then
                    if v_rightPaddleY_r >= c_paddleSpeed_l then
                        v_rightPaddleY_w <= v_rightPaddleY_r - c_paddleSpeed_l;
                    else
                        v_rightPaddleY_w <= 0;
                    end if;
                elsif i_rightDown = '1' then
                    if v_rightPaddleY_r <= (480 - c_paddleHeight_l - c_paddleSpeed_l) then
                        v_rightPaddleY_w <= v_rightPaddleY_r + c_paddleSpeed_l;
                    else
                        v_rightPaddleY_w <= 480 - c_paddleHeight_l;
                    end if;
                end if;

                -- 2. 球的位置更新
                v_ballX_w <= v_ballX_r + v_ballVx_r;
                v_ballY_w <= v_ballY_r + v_ballVy_r;

                -- 3. 碰撞牆壁檢測
                -- 上邊界
                if v_ballY_r + v_ballVy_r <= 0 then
                    v_ballVy_w <= abs(v_ballVy_r); -- 往正方向反彈
                -- 下邊界
                elsif v_ballY_r + v_ballVy_r >= (480 - c_ballSize_l) then
                    v_ballVy_w <= -abs(v_ballVy_r); -- 往負方向反彈
                end if;

                -- 4. 碰撞擋板檢測
                -- 左擋板碰撞 (X 範圍 30 ~ 40)
                if (v_ballX_r + v_ballVx_r <= 40) and (v_ballX_r >= 30) then
                    if (v_ballY_r + c_ballSize_l >= v_leftPaddleY_r) and (v_ballY_r <= v_leftPaddleY_r + c_paddleHeight_l) then
                        v_ballVx_w <= abs(v_ballVx_r); -- 往右彈起
                        
                        -- 微調 Y 反彈速度 (撞在上半部彈向上，下半部彈向下)
                        if v_ballY_r + (c_ballSize_l / 2) < v_leftPaddleY_r + (c_paddleHeight_l / 2) then
                            v_ballVy_w <= -c_ballSpeedY_l;
                        else
                            v_ballVy_w <= c_ballSpeedY_l;
                        end if;
                    end if;
                end if;

                -- 右擋板碰撞 (X 範圍 600 ~ 610)
                if (v_ballX_r + v_ballVx_r + c_ballSize_l >= 600) and (v_ballX_r <= 610) then
                    if (v_ballY_r + c_ballSize_l >= v_rightPaddleY_r) and (v_ballY_r <= v_rightPaddleY_r + c_paddleHeight_l) then
                        v_ballVx_w <= -abs(v_ballVx_r); -- 往左彈起
                        
                        -- 微調 Y 反彈速度
                        if v_ballY_r + (c_ballSize_l / 2) < v_rightPaddleY_r + (c_paddleHeight_l / 2) then
                            v_ballVy_w <= -c_ballSpeedY_l;
                        else
                            v_ballVy_w <= c_ballSpeedY_l;
                        end if;
                    end if;
                end if;

                -- 5. 出界與得分判定
                -- 左邊出界 -> 右玩家得分
                if v_ballX_r + v_ballVx_r <= 0 then
                    v_rightScore_w <= v_rightScore_r + 1;
                    if v_rightScore_r + 1 >= c_winScore_l then
                        v_winner_w <= '1'; -- 右玩家獲勝
                        v_state_w  <= ST_OVER;
                    else
                        v_state_w  <= ST_SCORE;
                        -- 得分後，直接指定下一次開球的速度 (朝右發球)
                        v_ballVx_w <= c_ballSpeedX_l;
                        v_ballVy_w <= c_ballSpeedY_l;
                    end if;
                    
                -- 右邊出界 -> 左玩家得分
                elsif v_ballX_r + v_ballVx_r >= 640 then
                    v_leftScore_w <= v_leftScore_r + 1;
                    if v_leftScore_r + 1 >= c_winScore_l then
                        v_winner_w <= '0'; -- 左玩家獲勝
                        v_state_w  <= ST_OVER;
                    else
                        v_state_w  <= ST_SCORE;
                        -- 得分後，直接指定下一次開球的速度 (朝左發球)
                        v_ballVx_w <= -c_ballSpeedX_l;
                        v_ballVy_w <= -c_ballSpeedY_l;
                    end if;
                end if;

            -- 狀態 ST_SCORE: 得分重置，延遲約 1 秒後重開球
            when ST_SCORE =>
                -- 球重置於中央，速度則維持剛才設定好的值
                v_ballX_w <= 316;
                v_ballY_w <= 236;
                
                -- 等待 60 個 frame (約 1 秒)
                if v_delayCount_r >= 60 then
                    v_delayCount_w <= 0;
                    v_state_w      <= ST_PLAY;
                else
                    v_delayCount_w <= v_delayCount_r + 1;
                end if;

            -- 狀態 ST_OVER: 遊戲結束，等待重新開始
            when ST_OVER =>
                -- 球置中靜止
                v_ballX_w <= 316;
                v_ballY_w <= 236;
                
                -- 玩家按下任何鍵則返回 IDLE 狀態
                if i_leftUp = '1' or i_leftDown = '1' or i_rightUp = '1' or i_rightDown = '1' then
                    v_state_w <= ST_IDLE;
                end if;

            when others =>
                v_state_w <= ST_IDLE;
        end case;
    end process GAME_COMB_LOGIC;

    -- 狀態輸出映射到 2-bit
    STATE_OUTPUT_MAP : process(v_state_r)
    begin
        case v_state_r is
            when ST_IDLE  => o_gameState_b <= "00";
            when ST_PLAY  => o_gameState_b <= "01";
            when ST_SCORE => o_gameState_b <= "10";
            when ST_OVER  => o_gameState_b <= "11";
        end case;
    end process STATE_OUTPUT_MAP;

    -- 暫存器輸出指派
    o_leftPaddleY_b  <= std_logic_vector(to_unsigned(v_leftPaddleY_r, 10));
    o_rightPaddleY_b <= std_logic_vector(to_unsigned(v_rightPaddleY_r, 10));
    o_ballX_b        <= std_logic_vector(to_unsigned(v_ballX_r, 10));
    o_ballY_b        <= std_logic_vector(to_unsigned(v_ballY_r, 10));
    o_leftScore_b    <= std_logic_vector(to_unsigned(v_leftScore_r, 4));
    o_rightScore_b   <= std_logic_vector(to_unsigned(v_rightScore_r, 4));
    o_winner         <= v_winner_r;

end architecture rtl;
