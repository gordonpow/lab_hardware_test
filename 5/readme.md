# PingPong 乒乓遊戲專案 (VHDL)

本專案使用 VHDL 在 FPGA 開發板（基於 Xilinx Artix-7/Basys3 晶片）上實作雙人乒乓球電子遊戲。透過 LED 燈左右平移來模擬乒乓球的移動軌跡，並利用左右按鍵作為玩家的擊球開關。

---

## 1. 專題介紹
本專案為數位電路系統設計之硬體實作，旨在透過硬體描述語言 (VHDL) 構建一套完整的遊戲控制系統。
*   系統架構：採用模組化設計，包含除頻器 (CLK_DIV)、主控有限狀態機 (FSM)、LED 移動控制器 (LED_P) 以及左/右得分計數器 (score_L_p 與 score_R_p)。
*   硬體周邊對接：以 8 個 LED 燈代表乒乓球，左、右兩個按鍵分別作為玩家 L 和玩家 R 的擊球球拍。
*   遊戲規則：乒乓球在 LED 間來回移動，玩家必須在球到達邊緣的時脈週期內精準按下擊球鍵將球彈回，否則判定漏接或提前擊球，由對手得分。

---

## 2. 需求定義

### 2.1 系統功能需求
1.  初始化與復位 (Reset)：
    *   系統復位訊號 i_rst 為低電位有效 ('0')。
    *   當重置發生時，系統初始化為 MovingR 狀態，乒乓球位置預設在最左側 (o_led[7] = '1')，雙方分數歸零。
2.  時脈除頻 (Clock Division)：
    *   將板載高頻時鐘 i_clk 進行除頻，以適應人類肉眼所能觀察的 LED 移動速度，產生 slow_clk。
3.  擊球與對打規則：
    *   正常擊球：當球移動到邊緣（右玩家邊緣 o_led[0] = '1'，左玩家邊緣 o_led[7] = '1'），玩家在對應的慢時鐘週期內按下擊球鍵 (i_swL 或 i_swR)，球將轉向移動。
    *   提前擊球：球尚未到達邊緣，玩家便按下擊球鍵，視為失誤，由對手直接得分。
    *   漏接球：球已到達邊緣且越界（o_led 歸零），玩家仍未按鍵擊球，視為漏接，由對手直接得分。
4.  計分與發球模式：
    *   失誤後，系統進入得分狀態 (Lwin 或 Rwin)，LED 顯示對應玩家獲勝的特殊燈號（左贏顯示 11110000，右贏顯示 00001111）。
    *   得分方需手動按鍵進行發球，以重新開始下一局對打（Lwin 時左玩家按 i_swL 發球往右，Rwin 時右玩家按 i_swR 發球往左）。

### 2.2 腳位定義 (Pin Assignment)
以下腳位配置定義於 [pingpong.xdc](file:///c:/pytorch_project/hardware_test/5/on_board_program/pingpong.xdc) 中：
```vhdl
-- Ports description (English annotation format)
-- i_clk    : system clock (PIN Y9)
-- i_rst    : system reset, active low (PIN F22)
-- i_swL    : left player switch (PIN T18)
-- i_swR    : right player switch (PIN R16)
-- o_led[7] : left border LED (PIN U14)
-- o_led[6] : LED 6 (PIN U19)
-- o_led[5] : LED 5 (PIN W22)
-- o_led[4] : LED 4 (PIN V22)
-- o_led[3] : LED 3 (PIN U21)
-- o_led[2] : LED 2 (PIN U22)
-- o_led[1] : LED 1 (PIN T21)
-- o_led[0] : right border LED (PIN T22)
```

---

## 視覺與排版通用規範 (Universal Styles)
所有由提示詞生成的 Draw.io XML 與波形 JSON 必須符合以下要求：
1. 背景顏色：預設背景為黑色 (background="#000000")。
2. 線段與方塊防遮擋：所有連線線段絕對不可被任何方塊、圓圈遮擋或穿越。必須設定起點與終點的相對位置點 (如 exitX/exitY、entryX/entryY)，必要時使用折線並設定轉折點 (points) 繞開元件。
3. 字體顏色與背景：
   - 預設文字為白色 (fontColor=#FFFFFF)。
   - 若背景顏色偏淡 (如黃色 #FFFF00、青色 #00FFFF 等)，則將字體顏色改為黑色 (fontColor=#000000)。
   - 時序圖或連線上的 Label 若在黑底下看不清，必須加上標籤背景色 (labelBackgroundColor)。

---

## 3. Breakdown 樹狀階層分解圖
Breakdown 圖用於展示系統各個子功能與狀態機的階層拆解：
*   第一層：頂層乒乓模組 (Pingpong Top-level Entity)。
*   第二層：硬體電路功能分解，包含除頻器、遊戲狀態控制 (FSM)、顯示處理 (LED_P) 與左/右計分處理器。
*   第三層：狀態機 FSM 所包含的 4 個運作狀態 (MovingR, MovingL, Lwin, Rwin)。

![Break Down](./img/BreakDown.png)

*   圖檔與圖片編輯檔存放在 [img](file:///c:/pytorch_project/hardware_test/5/img/) 資料夾中。
*   原始編輯檔請參考 [BreakDown.drawio](file:///c:/pytorch_project/hardware_test/5/img/BreakDown.drawio)

> **繪圖指引 (Diagram Generation Prompt)**：
> 可複製以下通用提示詞至 AI 助理生成對應的 Draw.io XML：
> ```markdown
> Role: You are a professional hardware architecture diagram engineer. Please generate a Draw.io XML code to represent the tree-like module hierarchy decomposition chart (Breakdown Chart) of a hardware project.
> 
> Design Rules:
> 1. Canvas Settings:
>    - Background color: Black (background="#000000").
>    - Grid: Enabled (grid="1" gridSize="5").
> 2. Hierarchy and Color Rules:
>    - Analyze the input module hierarchy and identify the total depth D.
>    - Assign a unique, bright, and high-contrast fill color for each layer/depth on the black background.
>    - Node Styles:
>      - Level 1 (Top module): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized larger, e.g., width="120" height="40". White text (fontColor=#ffffff). fillColor=Color_A, strokeColor=Darker_Color_A.
>      - Level 2 (Sub-modules): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized medium, e.g., width="60" height="40". White text (fontColor=#ffffff). fillColor=Color_B, strokeColor=#000000.
>      - Level k (Deeper layers, k >= 3): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized smaller or equal. White text (fontColor=#ffffff). fillColor=Color_C, strokeColor=#000000.
> 3. Edge and Routing Rules:
>    - Use straight line connections without bends: style="edgeStyle=none;rounded=0;html=1;".
>    - Start point (parent): Bottom center (exitX=0.5;exitY=1;exitDx=0;exitDy=0;).
>    - End point (child): Top center (entryX=0.5;entryY=0;entryDx=0;entryDy=0;).
>    - Edge color: Must match the fillColor of the target (child) node.
>    - If there is a label on the edge, the fontColor must match the edge color.
>    - Edges must NOT cross or be blocked by any rectangles, and must align with the grid.
> 
> Please generate the complete Draw.io XML based on the following custom hierarchy:
> [Input your custom hierarchy here]
> ```

---

## 4. 架構圖 (RTL Architecture)
架構圖展示了本專案模組內部的實體資料流與控制信號互連關係：
*   i_clk 與 i_rst 輸入至除頻模組 CLK_DIV 產生 slow_clk。
*   主狀態機 FSM 根據擊球鍵輸入 (i_swL, i_swR) 與目前球位置 led_r 控制當前遊戲狀態 state。
*   顯示處理器 LED_P 與計分器依據 slow_clk 以及 state/prev_state 控制 LED 燈號平移與計分累加。

![架構圖](./img/架構圖.png)

*   圖檔與圖片編輯檔存放在 [img](file:///c:/pytorch_project/hardware_test/5/img/) 資料夾中。
*   原始編輯檔請參考 [架構圖.drawio](file:///c:/pytorch_project/hardware_test/5/img/架構圖.drawio)

> **繪圖指引 (Diagram Generation Prompt)**：
> 可複製以下通用提示詞至 AI 助理生成對應的 Draw.io XML：
> ```markdown
> Role: You are a digital IC design engineer. Please generate a Draw.io XML code to represent the internal sub-module interconnection, external pin connections, and data/control flows (RTL Architecture Diagram).
> 
> Design Rules:
> 1. Canvas Settings:
>    - Background color: Black (background="#000000").
>    - Grid: Enabled (grid="1" gridSize="10").
> 2. Node and Boundary Styles:
>    - Outermost container (Top Module):
>      - Style: Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;).
>      - Fill color: Red (#FF0000) or dark grey to contrast with internal modules.
>      - Border: Black (strokeColor=#000000;strokeWidth=5;).
>      - Text alignment: Align top-left (align=left;horizontal=1;verticalAlign=top;). Font size 19. White or black text depending on contrast.
>      - Must be placed at the very bottom layer as a container.
>    - Internal Sub-modules:
>      - Assign different high-contrast fill colors (e.g., cyan #00FFFF for clock dividers, orange #FF8000 for control state machines, yellow #FFFF00 for operation/display logic).
>      - Text color: Black (fontColor=#000000) for light-colored nodes; white (fontColor=#ffffff) for dark-colored nodes.
>      - Border: Black and thick (strokeColor=#000000;strokeWidth=5;).
> 3. Signal Edge Routing:
>    - External Input Pins (e.g., i_clk, i_rst):
>      - Flow from the left outside to the corresponding sub-module's left side.
>      - Edge style: White thick line (strokeColor=#FFFFFF;strokeWidth=5;) with arrow.
>      - Label: Black text with a solid white background (labelBackgroundColor=#FFFFFF) to ensure readability on the black canvas.
>    - Internal Signals:
>      - Edge color must match the fillColor of its driver (source) module.
>      - Use orthogonal routing (rounded=0 or rounded=1).
>      - Control points (points) must be set to route around modules, strictly avoiding passing through or being blocked by any rectangles.
>    - External Output Pins (e.g., o_led):
>      - Flow from the sub-module's right side to the right outside.
>      - Edge style: Thick line matching the driver module's color (strokeWidth=5).
> 
> Please generate the complete Draw.io XML based on the following custom signals and sub-modules:
> [Input your custom sub-module interconnection here]
> ```

---

## 5. FSM 狀態轉移圖
本狀態機核心控制邏輯包含四個主要狀態的切換：
1.  MovingR：球向右移動。若右玩家正確擊球，轉向 MovingL；若漏接或提前擊球，轉向 Lwin（左方得分）。
2.  MovingL：球向左移動。若左玩家正確擊球，轉向 MovingR；若漏接或提前擊球，轉向 Rwin（右方得分）。
3.  Lwin：左得分狀態。等待左玩家按下 i_swL（左發球）後，切換回 MovingR。
4.  Rwin：右得分狀態。等待右玩家按下 i_swR（右發球）後，切換回 MovingL。

![有限狀態機](./img/FSM.png)

*   圖檔與圖片編輯檔存放在 [img](file:///c:/pytorch_project/hardware_test/5/img/) 資料夾中。
*   原始編輯檔請參考 [FSM.drawio](file:///c:/pytorch_project/hardware_test/5/img/FSM.drawio)

> **繪圖指引 (Diagram Generation Prompt)**：
> 可複製以下通用提示詞至 AI 助理生成對應的 Draw.io XML：
> ```markdown
> Role: You are a professional hardware control logic engineer. Please generate a Draw.io XML code to represent a custom Finite State Machine (FSM) state transition diagram.
> 
> Design Rules:
> 1. Canvas Settings:
>    - Background color: Black (background="#000000").
>    - Grid: Enabled (grid="1" gridSize="10").
> 2. State Node Styles:
>    - All states are circle/ellipse (ellipse;whiteSpace=wrap;html=1;aspect=fixed;), sized width="80" height="80".
>    - Assign unique, bright fill colors for different states (e.g., red, orange, green, yellow).
>    - Text color: High-contrast white (fontColor=#ffffff) or black (fontColor=#000000).
> 3. Transition Edge Styles:
>    - Edges must have arrows (edgeStyle=none;html=1;).
>    - Edge color: Must match the fillColor of the source (start) state node.
>    - Transition conditions (Label):
>      - White text (fontColor=#FFFFFF) or high contrast.
>      - Must set a label background color (labelBackgroundColor) matching the edge color to prevent blending.
> 4. Edge Collision Avoidance:
>    - For bidirectional transitions (e.g., State_A <=> State_B) or intersecting edges, adjust the terminal coordinates (exitDx/y and entryDx/y) or use routing points to separate the lines.
>    - Edges must NOT overlap or cross over any circle nodes.
> 
> Please generate the complete Draw.io XML based on the following custom FSM transitions:
> [Input your FSM states and transitions here]
> ```

---

## 6. MSC 圖 (Message Sequence Chart)
時序信號圖 (MSC) 展示系統在不同週期下，輸入與輸出信號的時序交替行為：
*   信號時脈 i_clk 規律震盪。
*   玩家按下 i_swL 或 i_swR 時，狀態 State 由移動模式過渡至得分模式，伴隨 o_led 輸出資料的對應變化。

![訊息序列圖](./img/MSC.png)

*   圖檔與圖片編輯檔存放在 [img](file:///c:/pytorch_project/hardware_test/5/img/) 資料夾中。
*   時序資料配置檔請參考 [5.json](file:///c:/pytorch_project/hardware_test/5/img/5.json)

> **繪圖指引 (Diagram Generation Prompt)**：
> 可複製以下通用提示詞至 AI 助理生成對應的波形 JSON：
> ```markdown
> Role: You are a digital circuit verification engineer. Please generate a JSON file in a specific format to render a signal timing waveform chart on a black background.
> 
> JSON Schema Specifications:
> 1. Global Properties:
>    - name (string): Waveform project name.
>    - total_cycles (int): Total clock cycles.
>    - cycle_width (int): Width per cycle, fixed to 30.
>    - signals (array): An array containing signal definitions.
> 2. Signal Object Properties:
>    Each signal object must contain:
>    - name (string): Signal name (follows VHDL/Verilog naming conventions, i.e., prefix i_ for inputs, o_ for outputs, camelCase for internal variables).
>    - type (string): Signal type. Must be one of:
>      - "CLK" (auto toggle)
>      - "INPUT" (single-line inputs: "0", "1", "X")
>      - "BUS_DATA" (multi-bit data bus)
>      - "BUS_STATE" (state bus)
>    - color (string): Hex color code. Must use bright, high-contrast colors on the black background. Different signals must have different colors:
>      - CLK: Bright green (e.g., "#43f477")
>      - Reset: Bright blue (e.g., "#414bcc")
>      - Inputs: Purple (e.g., "#c94cfb") or red (e.g., "#f40807")
>      - Output Bus: Magenta (e.g., "#f908a7")
>      - State Bus: Yellow-green (e.g., "#c0e249")
>    - values (array of string): Signal value per cycle. Length must match total_cycles.
>    - bits (int): Bit width (1 for single line, 8 or custom for bus).
>    - clk_rising_edge (boolean): Fixed to true.
>    - clk_mod (int): Fixed to 1.
>    - pinned (boolean): Fixed to false.
>    - sticky (boolean): Fixed to false.
>    - input_base and display_base (int): Fixed to 10.
> 
> Please generate the JSON based on the following custom signal behaviors:
> [Input your custom signals and timing sequence here]
> ```

---

## 7. AOV 圖 (Activity On Vertex)
AOV 圖以頂點作為活動狀態，展現乒乓球來回對打時所觸發的各種行為路徑與事件流向：
*   藍色主線：球來回正常對打的循環路徑 (MovingR <=> MovingL)。
*   綠色支線：左方得分/發球，但右方因漏接或提前擊球失誤，使左方獲勝 (Lwin) 的行為路徑。
*   紅色支線：右方得分/發球，但左方因漏接或提前擊球失誤，使右方獲勝 (Rwin) 的行為路徑。

![非週期操作](./img/AOV.png)

*   圖檔與圖片編輯檔存放在 [img](file:///c:/pytorch_project/hardware_test/5/img/) 資料夾中。
*   原始編輯檔請參考 [AOV.drawio](file:///c:/pytorch_project/hardware_test/5/img/AOV.drawio)

> **繪圖指引 (Diagram Generation Prompt)**：
> 可複製以下通用提示詞至 AI 助理生成對應的 Draw.io XML：
> ```markdown
> Role: You are a system analysis engineer. Please generate a Draw.io XML code to represent the state trigger paths and transition frequencies (AOV Diagram) of a running system.
> 
> Design Rules:
> 1. Canvas Settings:
>    - Background color: Black (background="#000000").
>    - Grid: Enabled (grid="1" gridSize="10").
> 2. Node Styles:
>    - All vertices are circle/ellipse (ellipse;whiteSpace=wrap;html=1;aspect=fixed;), sized width="80" height="80".
>    - Assign different bright fill colors for distinct node categories, with black text (fontColor=#000000) or high-contrast white.
> 3. Path Edge Styles:
>    - Use thick edges to emphasize flow (strokeWidth=4 or 5).
>    - Color code edges based on transition types (e.g., dark blue for primary loop, green or pink for branches, red for exceptions).
>    - Label text (e.g., transition counts) should be placed at the center of the edge with white or black color to maximize contrast.
> 4. Routing Rules:
>    - Set source/target points carefully (e.g., exitX=0.5;exitY=1 to entryX=0.5;entryY=0). Edges must not pass through or overlap with circle shapes.
> 
> Please generate the complete Draw.io XML based on the following custom vertices and paths:
> [Input your custom vertices and paths here]
> ```

---

## 8. 如何驗證

### 8.1 模擬驗證平台
本專案透過 VHDL Testbench [PingPong_tb.vhd](file:///c:/pytorch_project/hardware_test/5/sim_program/PingPong_tb.vhd) 於 ModelSim 模擬環境下進行邏輯電路驗證。

### 8.2 測試場景設計
模擬驗證中設計了以下幾種關鍵情境，以確保電路行為完全符合設計需求：
1.  初始復位與發球：測試系統上電後在第 23ns 釋放復位，左方在 MovingR 狀態下開始傳球。
2.  正常對打：在第 553ns (球到達右端 o_led[0] = '1')，右玩家正確按下擊球鍵 (swR = '1')，成功將球往左回擊。
3.  提前擊球 (左方違規)：在球尚未到達左邊界時，左玩家提前於第 933ns 按下 swL = '1'，系統立即判定左方失誤，右方得分且狀態轉為 Rwin。
4.  漏接球 (左方違規)：球到達左邊界且越界後（o_led 變為 0），左玩家仍未按鍵擊球，系統於第 2213ns 判定漏接，右方得分且狀態轉為 Rwin。

### 8.3 模擬結果與分析

#### 模擬波形 (原圖)
![模擬結果](./img/模擬成果(原圖).png)

#### 模擬波形 (標示版)
![模擬結果標示](./img/模擬成果(標示).png)

*   紅色標示：系統重置，預設向右移動。
*   橙色標示：球員提前擊球，直接進入得分狀態。
*   黃色標示：球員漏接球越界，對方得分。
*   灰色標示：球員在正確時機擊球，成功切換移動方向。

---

## 9. 成果展示

### 9.1 實機演示影片
您可以透過點擊下方連結觀看實機在 FPGA 開發板上的完整運作影片：

[![實機展示影片](https://img.youtube.com/vi/o6TW9HDYMb0/0.jpg)](https://youtube.com/shorts/o6TW9HDYMb0?feature=share)

### 9.2 實機運作 GIF 效果展示
以下為各項遊戲功能在開發板上的實機運作 GIF 成果：

#### 1. 初始化與發球
遊戲開始時，LED 朝向對手方向開始移動。
![初始化與發球](./gif/發球.gif)

#### 2. 來回對打
兩位玩家在正確時間點按下按鍵，LED 成功在兩端點之間來回反彈。
![對打](./gif/對打.gif)

#### 3. 分數顯示與 Game Over
當玩家失誤時對方得分，且當達到獲勝條件或重置時，七段顯示器會即時更新雙方得分。
![分數顯示](./gif/分數顯示.gif)
