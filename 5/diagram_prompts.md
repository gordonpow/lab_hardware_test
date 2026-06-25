# 硬體設計圖表通用生成提示詞 (Diagram Generation Prompts)

本文件整理了根據 `img` 資料夾中 `.drawio` 檔（Breakdown 圖、架構圖、FSM 狀態圖、AOV 圖）與 `.json` 檔（MSC 時序圖）分析提煉出的**通用提示詞 (Prompts)**。

這些提示詞可用於引導 AI 助理（如 LLM）依據特定設計需求，直接生成符合排版與色彩規範的 Draw.io XML 程式碼或波形 JSON 設定。

---

## 視覺與排版通用規範 (Universal Styles)
所有 Draw.io XML 與波形 JSON 必須符合以下要求：
1. **背景顏色**：預設背景為黑色 (`background="#000000"`)。
2. **線段與方塊防遮擋**：所有連線線段**絕對不可**被任何方塊、圓圈遮擋或穿越。必須設定起點與終點的相對位置點（如 `exitX`/`exitY`、`entryX`/`entryY`），必要時使用折線並設定轉折點 (`points`) 繞開元件。
3. **字體顏色與背景**：
   - 預設文字為白色 (`fontColor=#FFFFFF`)。
   - 若背景顏色偏淡（如黃色 `#FFFF00`、青色 `#00FFFF` 等），則將字體顏色改為黑色 (`fontColor=#000000`)。
   - 時序圖或連線上的 Label 若在黑底下看不清，必須加上標籤背景色 (`labelBackgroundColor`)。

---

## 1. Breakdown 樹狀階層分解圖 (Module Hierarchy)

### 提示詞 (Prompt)
```markdown
角色：你是一位專業的硬體架構繪圖工程師。請為我生成一個 Draw.io XML 代碼，用以呈現硬體模組的樹狀階層分解圖（Breakdown Chart）。

設計規範：
1. 【畫布設定】：
   - 背景必須為黑色：`background="#000000"`。
   - 啟用網格對齊：`grid="1" gridSize="5"`。
2. 【節點樣式】：
   - 所有節點皆為無圓角的矩形 (`rounded=0;whiteSpace=wrap;html=1;`)。
   - 第一層（頂層模組，如 Pingpong）：
     - 填充色：綠色 (`fillColor=#60a917`)
     - 邊框色：深綠色 (`strokeColor=#2D7600`)
     - 字體色：白色 (`fontColor=#ffffff`)
     - 建議尺寸：`width="120" height="40"`
   - 第二層（子模組，如 CLK_DIV, FSM, LED_P）：
     - 填充色：紅色 (`fillColor=#FF0000`)
     - 邊框色：黑色 (`strokeColor=#000000`)
     - 字體色：白色 (`fontColor=#ffffff`)
     - 建議尺寸：`width="60" height="40"`
   - 第三層（子功能或狀態，如 MovingR, MovingL）：
     - 填充色：橘色 (`fillColor=#FF8000`)
     - 邊框色：黑色 (`strokeColor=#000000`)
     - 字體色：白色 (`fontColor=#ffffff`)
     - 建議尺寸：`width="60" height="40"`
3. 【連線樣式與避空規則】：
   - 使用無折角的垂直/水平直線：`style="edgeStyle=none;rounded=0;html=1;"`。
   - 起點（父節點）：底邊中央 `exitX=0.5;exitY=1;exitDx=0;exitDy=0;`。
   - 終點（子節點）：頂邊中央 `entryX=0.5;entryY=0;entryDx=0;entryDy=0;`。
   - 連線顏色：與**終點節點（子節點）的填充色相同**（例如：連往第二層的線用紅色 `#FF0000`；連往第三層的線用橘色 `#FF8000`）。
   - 若線段上有標籤，標籤的 `fontColor` 與線段顏色相同。
   - 確保線段絕不穿透或被任何方塊遮擋。

請根據以下模組階層關係，輸出完整的 Draw.io XML：
[在此輸入你的模組階層結構，例如：
- Pingpong (頂層)
  - CLK_DIV (第二層)
  - FSM (第二層)
    - MovingR (第三層)
    - MovingL (第三層)
    - Rwin (第三層)
    - Lwin (第三層)
  - LED_P (第二層)
  - score_L_p (第二層)
  - score_R_p (第二層)
]
```

---

## 2. RTL 模組架構與資料流圖 (RTL Architecture)

### 提示詞 (Prompt)
```markdown
角色：你是一位數位 IC 設計工程師。請為我生成一個 Draw.io XML 代碼，用以呈現硬體內部模組互連、外部接腳與資料/控制流的架構圖（RTL Architecture Diagram）。

設計規範：
1. 【畫布設定】：
   - 背景必須為黑色：`background="#000000"`。
   - 啟用網格對齊：`grid="1" gridSize="10"`。
2. 【節點與模組框樣式】：
   - 頂層外圍大框 (Top Module，如 Pingpong)：
     - 樣式：矩形，無圓角 (`rounded=0;whiteSpace=wrap;html=1;`)。
     - 填充色：紅色 (`fillColor=#FF0000`)
     - 邊框色：黑色 (`strokeColor=#000000;strokeWidth=5;`)
     - 字體色與對齊：字體為黑色 (`fontColor=#000000`)，大小為 19，且靠左上對齊 (`align=left;horizontal=1;verticalAlign=top;`)。
     - 必須置於最底層以作為容器大框。
   - 內部子模組：
     - 時脈相關（如 CLK_DIV）：青色填充 (`fillColor=#00FFFF;strokeColor=#000000;fontColor=#000000;strokeWidth=5;`)。
     - 控制與狀態機（如 FSM）：橘色填充 (`fillColor=#FF8000;strokeColor=#000000;fontColor=#000000;strokeWidth=5;`)。
     - 執行與運算邏輯（如 LED_P, score_L_p, score_R_p）：黃色填充 (`fillColor=#FFFF00;fontColor=#000000;`)。
     - 由於背景偏淡，內部子模組字體均為**黑色**以確保清晰度。
3. 【信號線與走線防遮擋】：
   - 外部輸入腳位（i_clk, i_rst, i_swL, i_swR）：
     - 從外框左側外部，水平均勻連入對應內部模組的左側。
     - 線條樣式：白色粗線 (`strokeColor=#FFFFFF;strokeWidth=5;`)，帶箭頭。
     - 文字標籤：字體為黑色，並加上白色背景 (`labelBackgroundColor=#FFFFFF`) 以防黑底看不清。
   - 內部信號線：
     - 使用與其**發出源頭模組相同**的色系。
     - 來自 CLK_DIV 的除頻時脈 (`slow_clk`)：青色粗線 (`strokeColor=#00FFFF;strokeWidth=5;`)。
     - 來自 FSM 的控制狀態 (`state`)：橘色粗線 (`strokeColor=#FF8000;strokeWidth=5;`)。
     - 信號線 must 使用直角折線 (`rounded=0` 或 `rounded=1`)。
     - 連線的轉折點 (`points`) 必須明確規避所有模組，**嚴禁穿過或被任何模組方塊擋住**。
   - 外部輸出腳位（如 led_r）：
     - 從黃色模組右側水平拉出至外框右側。
     - 線條樣式：黃色粗線 (`strokeColor=#FFFF00;strokeWidth=5;`)，字體為黑色，白色背景。

請根據以下腳位與模組連接關係，輸出完整的 Draw.io XML：
[在此輸入模組互連與接腳描述，例如：
- 外部輸入：i_clk -> CLK_DIV; i_rst -> 外框(Pingpong); i_swL -> FSM; i_swR -> FSM
- 內部信號：
  - CLK_DIV 產生 slow_clk 連入 LED_P, score_L_p, score_R_p
  - FSM 產生 state 控制訊號連入 LED_P, score_L_p, score_R_p
- 外部輸出：LED_P 輸出 led_r 到右側外部
]
```

---

## 3. FSM 有限狀態機狀態轉移圖 (Finite State Machine)

### 提示詞 (Prompt)
```markdown
角色：你是一位專業的硬體控制設計工程師。請為我生成一個 Draw.io XML 代碼，用以展示有限狀態機（FSM）的狀態與轉移關係圖。

設計規範：
1. 【畫布設定】：
   - 背景必須為黑色：`background="#000000"`。
   - 啟用網格：`grid="1" gridSize="10"`。
2. 【狀態節點樣式】：
   - 所有狀態節點皆為圓形/正圓 (`ellipse;whiteSpace=wrap;html=1;aspect=fixed;`)，尺寸建議為 `width="80" height="80"`。
   - 為不同的狀態分配不同的填充色以利識別（字體統一為白色 `fontColor=#ffffff`）：
     - 右移狀態 (MovingR)：紅色填充 (`fillColor=#FF0000`)
     - 左移狀態 (MovingL)：橘色填充 (`fillColor=#FF8000`)
     - 右勝狀態 (Rwin)：暗黃色填充 (`fillColor=#666600`)
     - 左勝狀態 (Lwin)：綠色填充 (`fillColor=#4D9900`)
3. 【狀態轉移線與條件標籤】：
   - 轉移線必須為帶有箭頭的直線或曲線 (`edgeStyle=none;html=1;`)。
   - 線條顏色：與**轉移發出源頭（起點狀態）的填充色相同**（例如：從 MovingR 出發的轉移線為紅色 `#FF0000`；從 MovingL 出發的為橘色 `#FF8000`）。
   - 轉移條件文字 (Label)：
     - 字體為白色 (`fontColor=#FFFFFF`)。
     - 必須設定與線條同色的標籤背景色 (`labelBackgroundColor`)。例如，紅色線上的標籤背景為紅色，橘色線上的標籤背景為橘色。這能保證在黑色畫布上清晰可辨。
4. 【防重疊與避空規範】：
   - 當兩狀態間存在雙向轉移（如 MovingR <=> MovingL）時，必須通過不同的 `exitDx/y` 和 `entryDx/y` 坐標，或使用轉折點 (`points`) 將兩條線拉開，**絕不能重合或遮擋彼此的文字**。
   - 線段不得穿越任何圓圈。

請根據以下 FSM 的狀態與轉移關係，輸出完整的 Draw.io XML：
[在此輸入 FSM 狀態與轉移條件描述，例如：
- MovingR (紅色) --(右邊接到 / 紅色線)--> MovingL (橘色)
- MovingR (紅色) --(右邊漏接 / 紅色線)--> Lwin (綠色)
- MovingL (橘色) --(左邊接到 / 橘色線)--> MovingR (紅色)
- MovingL (橘色) --(左邊漏接 / 橘色線)--> Rwin (暗黃)
- Lwin (綠色) --(左邊發球 / 綠色線)--> MovingR (紅色)
- Rwin (暗黃) --(右邊發球 / 暗黃線)--> MovingL (橘色)
]
```

---

## 4. AOV 活動狀態軌跡與統計圖 (Activity On Vertex)

### 提示詞 (Prompt)
```markdown
角色：你是一位系統分析工程師。請為我生成一個 Draw.io XML 代碼，用以展示系統在一段運行中各個狀態節點（Vertex）被觸發的路徑與次數統計圖（AOV Diagram）。

設計規範：
1. 【畫布設定】：
   - 背景必須為黑色：`background="#000000"`。
   - 啟用網格：`grid="1" gridSize="10"`。
2. 【狀態節點樣式】：
   - 所有節點為正圓 (`ellipse;whiteSpace=wrap;html=1;aspect=fixed;`)，尺寸建議為 `width="80" height="80"`。
   - 節點配色（填充色亮麗，字體設為黑色 `fontColor=#000000`）：
     - 開始 (Start)：紅色填充 (`fillColor=#FF0000`)
     - 右移 (MovingR)：黃色填充 (`fillColor=#FFFF00`)
     - 左移 (MovingL)：綠色填充 (`fillColor=#00FF00`)
     - 左勝 (Lwin)：橘色填充 (`fillColor=#FF8000`)
     - 右勝 (Rwin)：青色填充 (`fillColor=#00FFFF`)
3. 【路徑邊樣式與權重】：
   - 使用粗線條以凸顯路徑流向 (`strokeWidth=4` 或 `5`)。
   - 根據路徑的特徵或重要性分配不同顏色：
     - 主軸連續得分/對打路徑：深藍色粗線 (`strokeColor=#006EAF;fillColor=#1ba1e2;`)
     - 左側得分/發球分支：綠色粗線 (`strokeColor=#2D7600;fillColor=#60a917;`)
     - 右側得分/發球分支：粉色粗線 (`strokeColor=#A50040;fillColor=#d80073;`)
     - 初始流向：紅色線 (`strokeColor=#FF0000;`)
   - 邊上的文字（如經過次數，例如 "8", "6"）置於線段中央，字體顏色設為白色或黑色，以求高對比。
4. 【防遮擋走線規範】：
   - 連線起終點需精確設置（如 `exitX=0.5;exitY=1` 到 `entryX=0.5;entryY=0`），不可與圓圈本體重疊。

請根據以下 AOV 頂點與帶權重的路徑關係，輸出完整的 Draw.io XML：
[在此輸入 AOV 節點與邊的描述，例如：
- Start --(紅線)--> MovingR (位置240, 160)
- Start --(綠線)--> MovingR (位置120, 160)
- Start --(粉線)--> MovingL (位置360, 160)
- MovingR(120,160) --(權重6, 綠線)--> Lwin(120,280)
- MovingR(240,160) --(權重8, 藍線)--> MovingL(240,280)
- MovingL(360,160) --(權重6, 粉線)--> Rwin(360,280)
]
```

---

## 5. MSC 信號時序波形圖 (Message Sequence / Timing Chart)

### 提示詞 (Prompt)
```markdown
角色：你是一位數位電路驗證工程師。請為我生成一個符合特定格式的 JSON 資料，該資料用於渲染黑色背景下的信號時序波形圖（Timing Waveform Chart）。

JSON 欄位格式規範：
1. 【全域屬性】：
   - `name` (string): 波形專案名稱。
   - `total_cycles` (int): 整個時序圖的總週期數。
   - `cycle_width` (int): 每個時序週期的寬度，固定設為 `30`。
   - `signals` (array): 包含多個信號定義的陣列。
2. 【信號定義欄位】：
   每個信號物件必須包含：
   - `name` (string): 信號名稱。符合 VHDL/Verilog 命名法（如輸入以 `i_` 開頭、輸出以 `o_` 開頭、內部變數為雙駝峰格式）。
   - `type` (string): 信號類型。必須是下列之一：
     - `"CLK"`：時脈信號，波形自動高低交替。
     - `"INPUT"`：單線輸入訊號，值為 "0", "1" 或 "X"。
     - `"BUS_DATA"`：多位元資料匯流排，會以方塊塊狀顯示數值。
     - `"BUS_STATE"`：狀態機狀態匯流排，會以方塊塊狀顯示狀態字串。
   - `color` (string): 十六進位顏色碼。為了在黑色背景上清晰顯現，必須選用高飽和度、高對比的亮色系：
     - 時脈 (`CLK`) 建議用明綠色：`"#43f477"`
     - 復位訊號 (`INPUT`) 建議用亮藍色：`"#414bcc"`
     - 輸入控制/開關 (`INPUT`) 建議用紫色或紅色：`"#c94cfb"` 或 `"#f40807"`
     - 輸出匯流排 (`BUS_DATA`) 建議用洋紅色：`"#f908a7"`
     - 狀態匯流排 (`BUS_STATE`) 建議用黃綠色或金黃色：`"#c0e249"`
   - `values` (array of string): 每個時脈週期對應的信號值（如 `"0"`, `"1"`, `"X"`, `"MovingR"`, `"rst"` 等）。長度必須與 `total_cycles` 匹配。
   - `bits` (int): 信號的位元寬度（單線信號為 `1`，匯流排信號如 `o_led` 為 `8`）。
   - `clk_rising_edge` (boolean): 固定為 `true`。
   - `clk_mod` (int): 固定為 `1`。
   - `pinned` (boolean): 固定為 `false`。
   - `sticky` (boolean): 固定為 `false`。
   - `input_base` 與 `display_base` (int): 固定為 `10`。

請根據以下信號行為，輸出對應格式的 JSON：
[在此輸入你要繪製的波形信號行為，例如：
1. i_clk (CLK): 週期高低交替，總共 38 個週期。
2. i_rst (INPUT): 在第 0 週期為 0，第 1 週期開始變為 1 並持續。
3. i_swL (INPUT): 在第 15、20、29 週期有觸發訊號 1，其餘為 X。
4. i_swR (INPUT): 在第 8、18 週期有觸發訊號 1，其餘為 X。
5. o_led (BUS_DATA, 8 bits): 初始為 0，隨後在 MovingR 和 MovingL 期間進行跑馬燈移位（如 128, 64, 32...），漏接時計分顯示 240。
6. State (BUS_STATE, 8 bits): 狀態移位序列 (rst -> MovingR -> MovingL -> Lwin ...)
]
```
