# 硬體設計圖表通用生成提示詞 (Diagram Generation Prompts)

本文件整理了根據 `img` 資料夾中 `.drawio` 檔（Breakdown 圖、架構圖、FSM 狀態圖、AOV 圖）與 `.json` 檔（MSC 時序圖）分析提煉出的**通用提示詞 (Prompts)**。

這些提示詞可用於引導 AI 助理依據使用者提供的**任意模組結構、狀態機或信號定義**，自動生成符合黑色背景、高可讀性、防線段遮擋的 Draw.io XML 程式碼或波形 JSON 設定。

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

## 1. Breakdown 樹狀階層分解圖 (Module Hierarchy)

### 提示詞 (Prompt)
角色：你是一位專業的硬體架構繪圖工程師。請為我生成一個 Draw.io XML 代碼，用以呈現硬體模組的樹狀階層分解圖 (Breakdown Chart)。

設計規範：
1. 畫布設定：
   - 背景必須為黑色：background="#000000"。
   - 啟用網格對齊：grid="1" gridSize="5"。
2. 分層與配色規則：
   - 請根據我輸入的模組結構，自動識別階層的總深度 D。
   - 每一層必須分配一個完全不同且在黑色背景上明亮醒目的填充顏色 (例如：層級 1 為綠色、層級 2 為紅色、層級 3 為橘色，或自訂其他高對比色彩序列)。
   - 對於每一層的節點樣式：
     - 第 1 層 (頂層)：矩形，無圓角 (rounded=0;whiteSpace=wrap;html=1;)。
       - 填充色：自訂顏色 1 (fillColor=顏色A)
       - 邊框色：顏色 1 的深色版 (strokeColor=深A)
       - 字體色：白色 (fontColor=#ffffff)
       - 建議尺寸較大：width="120" height="40"
     - 第 2 層 (子模組層)：矩形，無圓角 (rounded=0;whiteSpace=wrap;html=1;)。
       - 填充色：自訂顏色 2，必須不同於顏色 1 (fillColor=顏色B)
       - 邊框色：黑色 (strokeColor=#000000)
       - 字體色：白色 (fontColor=#ffffff)
       - 建議尺寸：width="60" height="40"
     - 第 k 層 (更深階層，k >= 3)：矩形，無圓角 (rounded=0;whiteSpace=wrap;html=1;)。
       - 填充色：自訂顏色 k，必須不同於上層顏色 (fillColor=顏色C...)
       - 邊框色：黑色 (strokeColor=#000000)
       - 字體色：白色 (fontColor=#ffffff)
       - 尺寸由上至下逐漸縮小或保持一致：width="60" height="40"
3. 連線樣式與避空規則：
   - 使用無折角的垂直/水平直線：style="edgeStyle=none;rounded=0;html=1;"。
   - 起點 (父節點)：底邊中央 exitX=0.5;exitY=1;exitDx=0;exitDy=0;。
   - 終點 (子節點)：頂邊中央 entryX=0.5;entryY=0;entryDx=0;entryDy=0;。
   - 連線顏色：與終點節點 (子節點) 的填充色相同，以便區分不同分支的流向。
   - 若線段上有標籤，標籤的 fontColor 與線段顏色相同。
   - 確保線段絕不穿透或被任何方塊遮擋，且完全對齊網格。

請根據我以下提供之 "自訂層級與電路定義" 模組結構，輸出完整的 Draw.io XML：
[在此輸入你的子電路分層結構與各層定義，例如：
- 第一層：[模組A名稱] (頂層電路)
  - 第二層：[子模組B1]、[子模組B2] (子模組層)
    - 第三層：[子模組C1] (細部分解層)
]

---

## 2. RTL 模組架構與資料流圖 (RTL Architecture)

### 提示詞 (Prompt)
角色：你是一位數位 IC 設計工程師。請為我生成一個 Draw.io XML 代碼，用以呈現硬體內部模組互連、外部接腳與資料/控制流的架構圖 (RTL Architecture Diagram)。

設計規範：
1. 畫布設定：
   - 背景必須為黑色：background="#000000"。
   - 啟用網格對齊：grid="1" gridSize="10"。
2. 節點與模組框樣式：
   - 最外圍大框 (Top Module)：
     - 樣式：矩形，無圓角 (rounded=0;whiteSpace=wrap;html=1;)。
     - 填充色：選用一個與內部子模組對比度高的色系 (例如紅色 #FF0000 或深灰色)。
     - 邊框色：黑色 (strokeColor=#000000;strokeWidth=5;)
     - 字體色與對齊：字體為黑色 (fontColor=#000000) 或白色 (視填充色深淺而定)，靠左上對齊 (align=left;horizontal=1;verticalAlign=top;)。
     - 必須置於最底層，作為包裹內部子模組的容器大框。
   - 內部子模組 (Sub-modules)：
     - 每個子模組必須分配不同且高對比的填充色 (例如：時脈邏輯用青色 #00FFFF、控制核心用橘色 #FF8000、運算顯示用黃色 #FFFF00 等)。
     - 為確保文字清晰，偏亮填充色使用黑色字 (fontColor=#000000)；偏暗填充色使用白色字 (fontColor=#ffffff)。
     - 建議使用黑邊與粗外框 (strokeColor=#000000;strokeWidth=5;)。
3. 信號線與走線防遮擋：
   - 外部輸入腳位 (如 i_clk, i_rst 等)：
     - 從外框左側外部水平連入對應內部模組的左側。
     - 線條樣式：白色粗線 (strokeColor=#FFFFFF;strokeWidth=5;)，帶箭頭。
     - 文字標籤：字體為黑色，加上白色背景 (labelBackgroundColor=#FFFFFF) 以防黑底看不清。
   - 內部訊號線：
     - 使用與其發出源頭 (驅動) 模組相同的色系。
     - 信號線必須使用直角折線 (rounded=0 或 rounded=1)。
     - 連線的轉折點 (points) 必須明確規避所有內部模組，嚴禁穿過或被任何模組方塊擋住。
   - 外部輸出腳位 (如 o_led, o_seg 等)：
     - 從發出模組右側水平拉出至外框右側。
     - 線條樣式：與發出模組同色之粗線 (strokeWidth=5)，字體需保持高對比。

請根據我以下提供之 "自訂內部子模組與信號定義"，輸出完整的 Draw.io XML：
[在此輸入自訂的模組互連與接腳描述，例如：
- 外框模組：[頂層名稱]
- 內部子模組與配色定義：[模組1](顏色A)、[模組2](顏色B)
- 外部輸入腳位：[腳位A] -> [模組1]
- 內部訊號流向：[模組1].[訊號A] -> [模組2].[訊號B]
- 外部輸出腳位：[模組2].[訊號C] -> 外部
]

---

## 3. FSM 有限狀態機狀態轉移圖 (Finite State Machine)

### 提示詞 (Prompt)
角色：你是一位專業的硬體控制設計工程師。請為我生成一個 Draw.io XML 代碼，用以展示自訂有限狀態機 (FSM) 的狀態與轉移關係圖。

設計規範：
1. 畫布設定：
   - 背景必須為黑色：background="#000000"。
   - 啟用網格：grid="1" gridSize="10"。
2. 狀態節點樣式：
   - 所有狀態節點皆為圓形/正圓 (ellipse;whiteSpace=wrap;html=1;aspect=fixed;)，尺寸建議為 width="80" height="80"。
   - 為不同的狀態分配完全不同的明亮填充色以利快速識別。
   - 為了可讀性，文字顏色設為高對比色 (如白字 fontColor=#ffffff 或黑字 fontColor=#000000)。
3. 狀態轉移線與條件標籤：
   - 轉移線必須為帶有箭頭的直線或曲線 (edgeStyle=none;html=1;)。
   - 線條顏色：與轉移發出源頭 (起點狀態) 的填充色相同，以便一眼看出轉移來源。
   - 轉移條件文字 (Label)：
     - 字體為白色 (fontColor=#FFFFFF) 或高對比色。
     - 必須設定與線條相同的標籤背景色 (labelBackgroundColor)，確保文字在黑色畫布上不會與線段混淆且清晰可辨。
4. 防重疊與避空規範：
   - 當兩狀態間存在雙向轉移或多個交叉轉移時，必須通過調整 exitDx/y 和 entryDx/y 連接坐標，或使用轉折點 (points) 將不同方向的線拉開，絕不能重合或遮擋狀態圓圈。
   - 線段不得穿越任何圓圈。

請根據我以下提供之 "自訂 FSM 狀態與轉移條件"，輸出完整的 Draw.io XML：
[在此輸入 FSM 的狀態與轉移描述，例如：
- 狀態列表：[狀態A]、[狀態B]、[狀態C]
- 轉移條件：
  - [狀態A] --(條件1)--> [狀態B]
  - [狀態B] --(條件2)--> [狀態C]
]

---

## 4. AOV 活動狀態軌跡與統計圖 (Activity On Vertex)

### 提示詞 (Prompt)
角色：你是一位系統分析工程師。請為我生成一個 Draw.io XML 代碼，用以展示系統在一段運行中各個狀態節點 (Vertex) 被觸發的路徑與次數統計圖 (AOV Diagram)。

設計規範：
1. 畫布設定：
   - 背景必須為黑色：background="#000000"。
   - 啟用網格：grid="1" gridSize="10"。
2. 狀態節點樣式：
   - 所有節點為正圓 (ellipse;whiteSpace=wrap;html=1;aspect=fixed;)，尺寸建議為 width="80" height="80"。
   - 節點配色：為不同功能的節點分配不同且明亮的填充色，字體設為高對比黑色 (fontColor=#000000) 或白色。
3. 路徑邊樣式與權重：
   - 使用粗線條以凸顯路徑流向 (strokeWidth=4 或 5)。
   - 依據路徑的類型或優先級分配不同的明亮顏色 (例如：正常流向用深藍、得分/觸發分支用綠色或粉紅色、異常分支用紅色)。
   - 邊上的文字 (如經過次數、權重數字) 置於線段中央，字體顏色設為白色或黑色，以求高對比。
4. 防遮擋走線規範：
   - 連線起終點需精確設置 (如 exitX=0.5;exitY=1 到 entryX=0.5;entryY=0)，線條絕不可穿越或與圓圈本體重疊。

請根據我以下提供之 "自訂頂點與帶權重路徑"，輸出完整的 Draw.io XML：
[在此輸入 AOV 節點與邊的描述，例如：
- 節點列表與位置：[節點A] (坐標x,y)、[節點B] (坐標x,y)
- 路徑關係與權重：[節點A] --(權重值、線條顏色)--> [節點B]
]

---

## 5. MSC 信號時序波形圖 (Message Sequence / Timing Chart)

### 提示詞 (Prompt)
角色：你是一位數位電路驗證工程師。請為我生成一個符合特定格式的 JSON 資料，該資料用於渲染黑色背景下的信號時序波形圖 (Timing Waveform Chart)。

JSON 欄位格式規範：
1. 全域屬性：
   - name (string): 波形專案名稱。
   - total_cycles (int): 整個時序圖的總週期數。
   - cycle_width (int): 每個時序週期的寬度，固定設為 30。
   - signals (array): 包含多個信號定義的陣列。
2. 信號定義欄位：
   每個信號物件必須包含：
   - name (string): 信號名稱。必須符合 VHDL/Verilog 命名法 (如輸入以 i_ 開頭、輸出以 o_ 開頭、內部變數為雙駝峰格式)。
   - type (string): 信號類型。必須是下列之一：
     - "CLK"：時脈信號，波形自動 high/low 交替。
     - "INPUT"：單線輸入訊號，值為 "0", "1" 或 "X"。
     - "BUS_DATA"：多位元資料匯流排，會以方塊塊狀顯示數值。
     - "BUS_STATE"：狀態機狀態匯流排，會以方塊塊狀顯示狀態字串。
   - color (string): 十六進位顏色碼。為了在黑色背景上清晰顯現，必須選用高飽和度、高對比的亮色系，且不同信號必須使用不同顏色：
     - 時脈 (CLK) 建議用明綠色 (如 "#43f477")
     - 復位訊號 建議用亮藍色 (如 "#414bcc")
     - 其他輸入 建議用紫色 (如 "#c94cfb") 或紅色 (如 "#f40807")
     - 輸出匯流排 建議用洋紅色 (如 "#f908a7")
     - 狀態匯流排 建議用黃綠色 (如 "#c0e249")
   - values (array of string): 每個時脈週期對應的信號值。長度必須與 total_cycles 匹配。
   - bits (int): 信號的位元寬度 (單線信號為 1，多位元為 8 或自訂寬度)。
   - clk_rising_edge (boolean): 固定為 true。
   - clk_mod (int): 固定為 1。
   - pinned (boolean): 固定為 false。
   - sticky (boolean): 固定為 false。
   - input_base 與 display_base (int): 固定為 10。

請根據我以下提供之 "自訂信號行為與時序需求"，輸出對應格式 of JSON：
[在此輸入自訂信號與其時序數據，例如：
1. i_clk (CLK): 週期高低交替，總共 [N] 個週期。
2. [信號名稱] ([信號類型]): [週期數值變化描述]
]
