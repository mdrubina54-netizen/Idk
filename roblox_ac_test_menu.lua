-- ================================================
--   Anti-Cheat Test Menu | LocalScript
--   Keybind: RightShift = Show / Hide
-- ================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

local TOGGLE_KEY = Enum.KeyCode.RightShift   -- change if needed

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local State = {
    Aimbot        = false,
    AimAssist     = false,
    FOVCircle     = false,
    FOVSize       = 200,

    ESPEnabled    = false,
    ESPLine       = false,
    ESPLinePos    = "Bottom",
    ESPBox        = false,
    ESPName       = false,
    ESPNamePos    = "Top",
    ESPHealthBar  = false,
    ESPHealthPos  = "Left",
    ESPDistance   = false,
    ESPDistPos    = "Bottom",
    ESPSkeleton   = false,

    Fly           = false,
    FlySpeed      = 50,
    Velocity      = false,
    VelocitySpeed = 50,
    TPNearest     = false,
    AutoHeal      = false,
}

-- ══════════════════════════════════════
--  COLOURS
-- ══════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(13, 13, 20),
    Bar        = Color3.fromRGB(22, 22, 34),
    Tab        = Color3.fromRGB(26, 26, 40),
    TabActive  = Color3.fromRGB(108, 84, 230),
    Row        = Color3.fromRGB(28, 28, 44),
    Panel      = Color3.fromRGB(18, 18, 28),
    ON         = Color3.fromRGB(108, 84, 230),
    OFF        = Color3.fromRGB(48, 48, 68),
    Knob       = Color3.fromRGB(230, 228, 255),
    Text       = Color3.fromRGB(215, 215, 245),
    Sub        = Color3.fromRGB(130, 130, 170),
    SliderFill = Color3.fromRGB(108, 84, 230),
    SliderBG   = Color3.fromRGB(38, 38, 58),
    Close      = Color3.fromRGB(210, 55, 55),
    Minimize   = Color3.fromRGB(210, 165, 35),
    White      = Color3.new(1, 1, 1),
}

-- ══════════════════════════════════════
--  GUI ROOT
-- ══════════════════════════════════════
local Gui = Instance.new("ScreenGui")
Gui.Name            = "ACTestMenu"
Gui.ResetOnSpawn    = false
Gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() Gui.Parent = game:GetService("CoreGui") end)
if not ok then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function corner(obj, r)  local c=Instance.new("UICorner",obj); c.CornerRadius=UDim.new(0,r or 6) end
local function padding(obj,t,b,l,r)
    local p=Instance.new("UIPadding",obj)
    p.PaddingTop=UDim.new(0,t); p.PaddingBottom=UDim.new(0,b)
    p.PaddingLeft=UDim.new(0,l); p.PaddingRight=UDim.new(0,r)
end

-- ── Window ──
local WIN_W, WIN_H, BAR_H = 560, 430, 38
local Win = Instance.new("Frame")
Win.Name              = "Window"
Win.Size              = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position          = UDim2.new(0.5,-WIN_W/2, 0.5,-WIN_H/2)
Win.BackgroundColor3  = C.BG
Win.BorderSizePixel   = 0
Win.Active            = true
Win.Draggable         = true
Win.ClipsDescendants  = true
Win.Parent            = Gui
corner(Win, 10)

-- ── Title Bar ──
local Bar = Instance.new("Frame")
Bar.Size             = UDim2.new(1,0,0,BAR_H)
Bar.BackgroundColor3 = C.Bar
Bar.BorderSizePixel  = 0
Bar.Parent           = Win
corner(Bar, 10)
-- hide bottom-rounded corners of bar
local BarFill = Instance.new("Frame")
BarFill.Size=UDim2.new(1,0,0,10); BarFill.Position=UDim2.new(0,0,1,-10)
BarFill.BackgroundColor3=C.Bar; BarFill.BorderSizePixel=0; BarFill.Parent=Bar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size=UDim2.new(1,-100,1,0); TitleLbl.Position=UDim2.new(0,12,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="⚙  AC Test Menu"
TitleLbl.TextColor3=C.Text; TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextSize=14; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
TitleLbl.Parent=Bar

-- Close (✕)
local function makeBarBtn(label, color, offsetRight)
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,offsetRight,0,6)
    b.BackgroundColor3=color; b.Text=label
    b.TextColor3=C.White; b.Font=Enum.Font.GothamBold
    b.TextSize=12; b.BorderSizePixel=0; b.Parent=Bar
    corner(b,6)
    return b
end

local CloseBtn = makeBarBtn("✕", C.Close,   -32)
local MinBtn   = makeBarBtn("—", C.Minimize, -64)

-- hint
local Hint=Instance.new("TextLabel")
Hint.Size=UDim2.new(0,220,0,13); Hint.Position=UDim2.new(0,12,1,3)
Hint.BackgroundTransparency=1; Hint.Text="RightShift  →  show / hide"
Hint.TextColor3=C.Sub; Hint.Font=Enum.Font.Gotham; Hint.TextSize=10
Hint.TextXAlignment=Enum.TextXAlignment.Left; Hint.Parent=Win

-- ── Minimize / Close logic ──
local minimized = false
CloseBtn.MouseButton1Click:Connect(function() Gui:Destroy() end)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetH = minimized and BAR_H or WIN_H
    TweenService:Create(Win, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, WIN_W, 0, targetH)
    }):Play()
    MinBtn.Text = minimized and "▢" or "—"
end)

-- ── Keybind: show / hide ──
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == TOGGLE_KEY then
        Win.Visible = not Win.Visible
    end
end)

-- ══════════════════════════════════════
--  TAB + PANEL SYSTEM
-- ══════════════════════════════════════
local TabBar = Instance.new("Frame")
TabBar.Size=UDim2.new(0,112,1,-BAR_H); TabBar.Position=UDim2.new(0,0,0,BAR_H)
TabBar.BackgroundColor3=C.Tab; TabBar.BorderSizePixel=0; TabBar.Parent=Win
corner(TabBar,8)
local TL=Instance.new("UIListLayout",TabBar); TL.Padding=UDim.new(0,4); TL.SortOrder=Enum.SortOrder.LayoutOrder
padding(TabBar,8,8,6,6)

local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-120,1,-BAR_H-4); Content.Position=UDim2.new(0,118,0,BAR_H+2)
Content.BackgroundTransparency=1; Content.BorderSizePixel=0; Content.Parent=Win

local tabBtns, panels = {}, {}

local function newPanel(name)
    local f=Instance.new("ScrollingFrame")
    f.Name=name; f.Size=UDim2.new(1,0,1,0)
    f.BackgroundColor3=C.Panel; f.BorderSizePixel=0
    f.ScrollBarThickness=3; f.ScrollBarImageColor3=C.TabActive
    f.CanvasSize=UDim2.new(0,0,0,0); f.AutomaticCanvasSize=Enum.AutomaticSize.Y
    f.Visible=false; f.Parent=Content
    corner(f,8)
    local l=Instance.new("UIListLayout",f); l.Padding=UDim.new(0,5); l.SortOrder=Enum.SortOrder.LayoutOrder
    padding(f,8,8,10,10)
    panels[name]=f; return f
end

local function showTab(name)
    for k,p in pairs(panels) do p.Visible=(k==name) end
    for k,b in pairs(tabBtns) do
        local on=(k==name)
        b.BackgroundColor3 = on and C.TabActive or Color3.fromRGB(0,0,0)
        b.BackgroundTransparency = on and 0 or 1
        b.TextColor3 = on and C.White or C.Sub
    end
end

local function newTabBtn(name, icon, order)
    local b=Instance.new("TextButton")
    b.Name=name; b.Size=UDim2.new(1,0,0,34)
    b.BackgroundColor3=C.TabActive; b.BackgroundTransparency=1
    b.Text=icon.."  "..name; b.TextColor3=C.Sub
    b.Font=Enum.Font.GothamSemibold; b.TextSize=12
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.BorderSizePixel=0; b.LayoutOrder=order; b.Parent=TabBar
    corner(b,6); padding(b,0,0,8,0)
    tabBtns[name]=b
    b.MouseButton1Click:Connect(function() showTab(name) end)
end

-- ══════════════════════════════════════
--  WIDGET BUILDERS
-- ══════════════════════════════════════
local function secHeader(parent, text, order)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,20)
    f.BackgroundTransparency=1; f.LayoutOrder=order; f.Parent=parent
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.Text="  "..text
    l.TextColor3=C.TabActive; l.Font=Enum.Font.GothamBold
    l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
    -- divider line
    local d=Instance.new("Frame",f); d.Size=UDim2.new(1,0,0,1)
    d.Position=UDim2.new(0,0,1,-1); d.BackgroundColor3=C.TabActive
    d.BackgroundTransparency=0.7; d.BorderSizePixel=0
end

local function makeToggle(parent, label, key, order)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,32)
    row.BackgroundColor3=C.Row; row.BorderSizePixel=0
    row.LayoutOrder=order; row.Parent=parent; corner(row,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-54,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=C.Text; lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(0,38,0,20); track.Position=UDim2.new(1,-46,0.5,-10)
    track.BackgroundColor3=State[key] and C.ON or C.OFF
    track.BorderSizePixel=0; corner(track,10)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,16,0,16)
    knob.Position=State[key] and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3=C.Knob; knob.BorderSizePixel=0; corner(knob,8)

    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""

    btn.MouseButton1Click:Connect(function()
        State[key]=not State[key]
        local on=State[key]
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=on and C.ON or C.OFF}):Play()
        TweenService:Create(knob,TweenInfo.new(0.15),{Position=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end)
end

local function makeSelector(parent, label, key, opts, order)
    local h = 26 + 28
    local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,h)
    wrap.BackgroundColor3=C.Row; wrap.BorderSizePixel=0
    wrap.LayoutOrder=order; wrap.Parent=parent; corner(wrap,6)

    local lbl=Instance.new("TextLabel",wrap)
    lbl.Size=UDim2.new(1,-10,0,18); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=C.Sub; lbl.Font=Enum.Font.Gotham
    lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local holder=Instance.new("Frame",wrap)
    holder.Size=UDim2.new(1,-12,0,22); holder.Position=UDim2.new(0,6,0,24)
    holder.BackgroundTransparency=1
    local bl=Instance.new("UIListLayout",holder)
    bl.FillDirection=Enum.FillDirection.Horizontal; bl.Padding=UDim.new(0,4)

    local btns={}
    for _,opt in ipairs(opts) do
        local ob=Instance.new("TextButton",holder)
        ob.Size=UDim2.new(1/#opts,-4,1,0)
        ob.BackgroundColor3=(State[key]==opt) and C.TabActive or Color3.fromRGB(42,42,62)
        ob.Text=opt; ob.TextColor3=C.White
        ob.Font=Enum.Font.GothamSemibold; ob.TextSize=11
        ob.BorderSizePixel=0; corner(ob,5); btns[opt]=ob
        ob.MouseButton1Click:Connect(function()
            State[key]=opt
            for o,b in pairs(btns) do
                b.BackgroundColor3=(o==opt) and C.TabActive or Color3.fromRGB(42,42,62)
            end
        end)
    end
end

local function makeSlider(parent, label, key, minV, maxV, order)
    local wrap=Instance.new("Frame"); wrap.Size=UDim2.new(1,0,0,54)
    wrap.BackgroundColor3=C.Row; wrap.BorderSizePixel=0
    wrap.LayoutOrder=order; wrap.Parent=parent; corner(wrap,6)

    local lbl=Instance.new("TextLabel",wrap)
    lbl.Size=UDim2.new(0.65,0,0,18); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=C.Sub; lbl.Font=Enum.Font.Gotham
    lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local valLbl=Instance.new("TextLabel",wrap)
    valLbl.Size=UDim2.new(0.35,-10,0,18); valLbl.Position=UDim2.new(0.65,0,0,4)
    valLbl.BackgroundTransparency=1; valLbl.Text=tostring(State[key])
    valLbl.TextColor3=C.TabActive; valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=11; valLbl.TextXAlignment=Enum.TextXAlignment.Right

    local track=Instance.new("Frame",wrap)
    track.Size=UDim2.new(1,-20,0,6); track.Position=UDim2.new(0,10,0,38)
    track.BackgroundColor3=C.SliderBG; track.BorderSizePixel=0; corner(track,3)

    local pct0=(State[key]-minV)/(maxV-minV)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(pct0,0,1,0); fill.BackgroundColor3=C.SliderFill
    fill.BorderSizePixel=0; corner(fill,3)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14); knob.Position=UDim2.new(pct0,-7,0.5,-7)
    knob.BackgroundColor3=C.Knob; knob.BorderSizePixel=0; knob.ZIndex=3; corner(knob,7)

    local drag=false
    local hitbox=Instance.new("TextButton",track)
    hitbox.Size=UDim2.new(1,0,0,22); hitbox.Position=UDim2.new(0,0,0.5,-11)
    hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.ZIndex=4

    local function set(x)
        local p=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(minV+p*(maxV-minV))
        State[key]=v; valLbl.Text=tostring(v)
        fill.Size=UDim2.new(p,0,1,0)
        knob.Position=UDim2.new(p,-7,0.5,-7)
    end

    hitbox.MouseButton1Down:Connect(function() drag=true; set(UserInputService:GetMouseLocation().X) end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ══════════════════════════════════════
--  BUILD TABS
-- ══════════════════════════════════════

-- ── Aimbot ──
newTabBtn("Aimbot","🎯",1)
local AP=newPanel("Aimbot")
secHeader(AP,"AIMBOT",1)
makeToggle(AP,"Aimbot","Aimbot",2)
makeToggle(AP,"Aim Assist  (Instant Lock)","AimAssist",3)
secHeader(AP,"FIELD OF VIEW",4)
makeToggle(AP,"FOV Circle","FOVCircle",5)
makeSlider(AP,"FOV Size","FOVSize",50,1000,6)

-- ── Visuals ──
newTabBtn("Visuals","👁",2)
local VP=newPanel("Visuals")
secHeader(VP,"ESP",1)
makeToggle(VP,"Enable ESP","ESPEnabled",2)
makeToggle(VP,"ESP Box","ESPBox",3)
makeToggle(VP,"ESP Skeleton","ESPSkeleton",4)
secHeader(VP,"ESP LINE",5)
makeToggle(VP,"ESP Line","ESPLine",6)
makeSelector(VP,"Line Origin","ESPLinePos",{"Top","Side","Bottom"},7)
secHeader(VP,"ESP NAME",8)
makeToggle(VP,"ESP Name","ESPName",9)
makeSelector(VP,"Name Position","ESPNamePos",{"Top","Bottom"},10)
secHeader(VP,"HEALTH BAR",11)
makeToggle(VP,"ESP Health Bar","ESPHealthBar",12)
makeSelector(VP,"Health Bar Side","ESPHealthPos",{"Top","Left","Right"},13)
secHeader(VP,"DISTANCE",14)
makeToggle(VP,"ESP Distance","ESPDistance",15)
makeSelector(VP,"Distance Position","ESPDistPos",{"Top","Bottom"},16)

-- ── Player ──
newTabBtn("Player","🧍",3)
local PP=newPanel("Player")
secHeader(PP,"MOVEMENT",1)
makeToggle(PP,"Fly","Fly",2)
makeSlider(PP,"Fly Speed","FlySpeed",1,200,3)
makeToggle(PP,"Velocity","Velocity",4)
makeSlider(PP,"Velocity Speed","VelocitySpeed",1,200,5)
secHeader(PP,"MISC",6)
makeToggle(PP,"TP to Nearest Player","TPNearest",7)
makeToggle(PP,"Auto Heal","AutoHeal",8)

showTab("Aimbot")

-- ══════════════════════════════════════
--  STUB RUNTIME (hook your AC checks here)
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if State.AutoHeal then
        local char=LocalPlayer.Character
        if char then
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health=hum.MaxHealth end
        end
    end
    -- Add your other AC detection stubs below using State.*
    -- e.g. if State.Fly then ... end
end)

print("[AC Test Menu] Ready │ "..tostring(TOGGLE_KEY).." = show/hide")
