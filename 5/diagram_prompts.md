# 硬體設計圖表通用生成提示詞 (Diagram Generation Prompts)

本文件整理了根據 `img` 資料夾中 `.drawio` 檔（Breakdown 圖、架構圖、FSM 狀態圖、AOV 圖）與 `.json` 檔（MSC 時序圖）分析提煉出的**通用提示詞 (Prompts)**。

為了避免後台傳輸時發生字元編碼錯誤 (invalid UTF-8)，且為了提高 LLM 生成 XML/JSON 的精準度，本文件將**提示詞 (Prompts) 本體全部以英文撰寫**。

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
```markdown
Role: You are a professional hardware architecture diagram engineer. Please generate a Draw.io XML code to represent the tree-like module hierarchy decomposition chart (Breakdown Chart) of a hardware project.

Design Rules:
1. Canvas Settings:
   - Background color: Black (background="#000000").
   - Grid: Enabled (grid="1" gridSize="5").
2. Hierarchy and Color Rules:
   - Analyze the input module hierarchy and identify the total depth D.
   - Assign a unique, bright, and high-contrast fill color for each layer/depth on the black background.
   - Node Styles:
     - Level 1 (Top module): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized larger, e.g., width="120" height="40". White text (fontColor=#ffffff). fillColor=Color_A, strokeColor=Darker_Color_A.
     - Level 2 (Sub-modules): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized medium, e.g., width="60" height="40". White text (fontColor=#ffffff). fillColor=Color_B, strokeColor=#000000.
     - Level k (Deeper layers, k >= 3): Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;). Sized smaller or equal. White text (fontColor=#ffffff). fillColor=Color_C, strokeColor=#000000.
3. Edge and Routing Rules:
   - Use straight line connections without bends: style="edgeStyle=none;rounded=0;html=1;".
   - Start point (parent): Bottom center (exitX=0.5;exitY=1;exitDx=0;exitDy=0;).
   - End point (child): Top center (entryX=0.5;entryY=0;entryDx=0;entryDy=0;).
   - Edge color: Must match the fillColor of the target (child) node.
   - If there is a label on the edge, the fontColor must match the edge color.
   - Edges must NOT cross or be blocked by any rectangles, and must align with the grid.

Please generate the complete Draw.io XML based on the following custom hierarchy:
[Input your custom hierarchy here, e.g.:
- Level 1: Top_Module_Name
  - Level 2: Sub_Module_A, Sub_Module_B
    - Level 3: Sub_A_1, Sub_A_2
]
```

---

## 2. RTL 模組架構與資料流圖 (RTL Architecture)

### 提示詞 (Prompt)
```markdown
Role: You are a digital IC design engineer. Please generate a Draw.io XML code to represent the internal sub-module interconnection, external pin connections, and data/control flows (RTL Architecture Diagram).

Design Rules:
1. Canvas Settings:
   - Background color: Black (background="#000000").
   - Grid: Enabled (grid="1" gridSize="10").
2. Node and Boundary Styles:
   - Outermost container (Top Module):
     - Style: Rectangle without rounded corners (rounded=0;whiteSpace=wrap;html=1;).
     - Fill color: Red (#FF0000) or dark grey to contrast with internal modules.
     - Border: Black (strokeColor=#000000;strokeWidth=5;).
     - Text alignment: Align top-left (align=left;horizontal=1;verticalAlign=top;). Font size 19. White or black text depending on contrast.
     - Must be placed at the very bottom layer as a container.
   - Internal Sub-modules:
     - Assign different high-contrast fill colors (e.g., cyan #00FFFF for clock dividers, orange #FF8000 for control state machines, yellow #FFFF00 for operation/display logic).
     - Text color: Black (fontColor=#000000) for light-colored nodes; white (fontColor=#ffffff) for dark-colored nodes.
     - Border: Black and thick (strokeColor=#000000;strokeWidth=5;).
3. Signal Edge Routing:
   - External Input Pins (e.g., i_clk, i_rst):
     - Flow from the left outside to the corresponding sub-module's left side.
     - Edge style: White thick line (strokeColor=#FFFFFF;strokeWidth=5;) with arrow.
     - Label: Black text with a solid white background (labelBackgroundColor=#FFFFFF) to ensure readability on the black canvas.
   - Internal Signals:
     - Edge color must match the fillColor of its driver (source) module.
     - Use orthogonal routing (rounded=0 or rounded=1).
     - Control points (points) must be set to route around modules, strictly avoiding passing through or being blocked by any rectangles.
   - External Output Pins (e.g., o_led):
     - Flow from the sub-module's right side to the right outside.
     - Edge style: Thick line matching the driver module's color (strokeWidth=5).

Please generate the complete Draw.io XML based on the following custom signals and sub-modules:
[Input your custom sub-module interconnection here, e.g.:
- Top Container: Top_Name
- Sub-modules with color: Module_A(color A), Module_B(color B)
- Inputs: Pin_In -> Module_A
- Internals: Module_A.Sig -> Module_B.Sig
- Outputs: Module_B.Sig -> Pin_Out
]
```

---

## 3. FSM 有限狀態機狀態轉移圖 (Finite State Machine)

### 提示詞 (Prompt)
```markdown
Role: You are a professional hardware control logic engineer. Please generate a Draw.io XML code to represent a custom Finite State Machine (FSM) state transition diagram.

Design Rules:
1. Canvas Settings:
   - Background color: Black (background="#000000").
   - Grid: Enabled (grid="1" gridSize="10").
2. State Node Styles:
   - All states are circle/ellipse (ellipse;whiteSpace=wrap;html=1;aspect=fixed;), sized width="80" height="80".
   - Assign unique, bright fill colors for different states (e.g., red, orange, green, yellow).
   - Text color: High-contrast white (fontColor=#ffffff) or black (fontColor=#000000).
3. Transition Edge Styles:
   - Edges must have arrows (edgeStyle=none;html=1;).
   - Edge color: Must match the fillColor of the source (start) state node.
   - Transition conditions (Label):
     - White text (fontColor=#FFFFFF) or high contrast.
     - Must set a label background color (labelBackgroundColor) matching the edge color to prevent blending.
4. Edge Collision Avoidance:
   - For bidirectional transitions (e.g., State_A <=> State_B) or intersecting edges, adjust the terminal coordinates (exitDx/y and entryDx/y) or use routing points to separate the lines.
   - Edges must NOT overlap or cross over any circle nodes.

Please generate the complete Draw.io XML based on the following custom FSM transitions:
[Input your FSM states and transitions here, e.g.:
- States: State_A, State_B, State_C
- Transitions:
  - State_A --(Cond_1)--> State_B
  - State_B --(Cond_2)--> State_C
]
```

---

## 4. AOV 活動狀態軌跡與統計圖 (Activity On Vertex)

### 提示詞 (Prompt)
```markdown
Role: You are a system analysis engineer. Please generate a Draw.io XML code to represent the state trigger paths and transition frequencies (AOV Diagram) of a running system.

Design Rules:
1. Canvas Settings:
   - Background color: Black (background="#000000").
   - Grid: Enabled (grid="1" gridSize="10").
2. Node Styles:
   - All vertices are circle/ellipse (ellipse;whiteSpace=wrap;html=1;aspect=fixed;), sized width="80" height="80".
   - Assign different bright fill colors for distinct node categories, with black text (fontColor=#000000) or high-contrast white.
3. Path Edge Styles:
   - Use thick edges to emphasize flow (strokeWidth=4 or 5).
   - Color code edges based on transition types (e.g., dark blue for primary loop, green or pink for branches, red for exceptions).
   - Label text (e.g., transition counts) should be placed at the center of the edge with white or black color to maximize contrast.
4. Routing Rules:
   - Set source/target points carefully (e.g., exitX=0.5;exitY=1 to entryX=0.5;entryY=0). Edges must not pass through or overlap with circle shapes.

Please generate the complete Draw.io XML based on the following custom vertices and paths:
[Input your custom vertices and paths here, e.g.:
- Nodes with coordinates: Node_A(x,y), Node_B(x,y)
- Path connections: Node_A --(weight, color)--> Node_B
]
```

---

## 5. MSC 信號時序波形圖 (Message Sequence / Timing Chart)

### 提示詞 (Prompt)
```markdown
Role: You are a digital circuit verification engineer. Please generate a JSON file in a specific format to render a signal timing waveform chart on a black background.

JSON Schema Specifications:
1. Global Properties:
   - name (string): Waveform project name.
   - total_cycles (int): Total clock cycles.
   - cycle_width (int): Width per cycle, fixed to 30.
   - signals (array): An array containing signal definitions.
2. Signal Object Properties:
   Each signal object must contain:
   - name (string): Signal name (follows VHDL/Verilog naming conventions, i.e., prefix i_ for inputs, o_ for outputs, camelCase for internal variables).
   - type (string): Signal type. Must be one of:
     - "CLK" (auto toggle)
     - "INPUT" (single-line inputs: "0", "1", "X")
     - "BUS_DATA" (multi-bit data bus)
     - "BUS_STATE" (state bus)
   - color (string): Hex color code. Must use bright, high-contrast colors on the black background. Different signals must have different colors:
     - CLK: Bright green (e.g., "#43f477")
     - Reset: Bright blue (e.g., "#414bcc")
     - Inputs: Purple (e.g., "#c94cfb") or red (e.g., "#f40807")
     - Output Bus: Magenta (e.g., "#f908a7")
     - State Bus: Yellow-green (e.g., "#c0e249")
   - values (array of string): Signal value per cycle. Length must match total_cycles.
   - bits (int): Bit width (1 for single line, 8 or custom for bus).
   - clk_rising_edge (boolean): Fixed to true.
   - clk_mod (int): Fixed to 1.
   - pinned (boolean): Fixed to false.
   - sticky (boolean): Fixed to false.
   - input_base and display_base (int): Fixed to 10.

Please generate the JSON based on the following custom signal behaviors:
[Input your custom signals and timing sequence here, e.g.:
1. i_clk (CLK): 38 cycles.
2. i_rst (INPUT): 0 for cycle 0, 1 for the rest.
]
```
