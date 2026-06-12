-- ================================================
--   AntiCheat Test Menu | by Claude
--   Tabs: Aimbot | Visuals | Settings
--   Drawing API ESP + Aimbot (no scope required)
-- ================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera        = workspace.CurrentCamera

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

-- ─────────────────────────────────────────────
--  CONFIG (runtime state)
-- ─────────────────────────────────────────────
local Config = {
    -- Aimbot
    AimbotEnabled    = false,
    AimbotBone       = "Head",          -- "Head" | "HumanoidRootPart"
    TeamCheck        = false,
    ShowFOVCircle    = true,
    AimFOV           = 120,

    -- Visuals
    ESPEnabled       = false,
    ESPLine          = false,
    ESPLinePos       = "Bottom",        -- Top | Bottom | Side
    ESPBox           = false,
    ESPHealthBar     = false,
    ESPHealthBarPos  = "Left",          -- Top | Left | Right | Bottom
    ESPName          = false,
    ESPNamePos       = "Top",           -- Top | Bottom
    ESPDistance      = false,
    ESPDistancePos   = "Bottom",        -- Top | Bottom

    -- Settings
    AimKey           = Enum.UserInputType.MouseButton2,
    AimSmoothing     = 0.15,
    ESPColor         = Color3.fromRGB(255, 80, 80),
    BoxColor         = Color3.fromRGB(255, 255, 255),
    LineColor        = Color3.fromRGB(0, 200, 255),
    TextColor        = Color3.fromRGB(255, 255, 255),
    HealthBarColor   = Color3.fromRGB(0, 255, 80),
    MaxESPDistance   = 1000,
    MenuOpen         = true,
}

-- ─────────────────────────────────────────────
--  DRAWING POOL
-- ─────────────────────────────────────────────
local ESPObjects = {}   -- [player] = { box, line, healthBar, nameText, distText }
local FOVCircle  = Drawing.new("Circle")
FOVCircle.Thickness  = 1
FOVCircle.Color      = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled     = false
FOVCircle.Transparency = 1
FOVCircle.NumSides   = 64
FOVCircle.Radius     = Config.AimFOV
FOVCircle.Position   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
FOVCircle.Visible    = false

local function newDrawing(type_, props)
    local d = Drawing.new(type_)
    for k,v in pairs(props) do d[k] = v end
    return d
end

local function initESP(player)
    if ESPObjects[player] then return end
    ESPObjects[player] = {
        box       = newDrawing("Square",    {Visible=false, Filled=false, Thickness=1, Color=Config.BoxColor}),
        line      = newDrawing("Line",      {Visible=false, Thickness=1, Color=Config.LineColor}),
        healthBar = newDrawing("Square",    {Visible=false, Filled=true,  Thickness=1, Color=Config.HealthBarColor}),
        healthBg  = newDrawing("Square",    {Visible=false, Filled=true,  Thickness=1, Color=Color3.fromRGB(40,40,40)}),
        nameText  = newDrawing("Text",      {Visible=false, Size=13, Color=Config.TextColor, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
        distText  = newDrawing("Text",      {Visible=false, Size=12, Color=Config.TextColor, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
    }
end

local function removeESP(player)
    if not ESPObjects[player] then return end
    for _, d in pairs(ESPObjects[player]) do d:Remove() end
    ESPObjects[player] = nil
end

-- ─────────────────────────────────────────────
--  HELPER: WorldToViewport safe
-- ─────────────────────────────────────────────
local function w2vp(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), sp.Z, onScreen
end

local function getCharParts(player)
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not head or not hum then return nil end
    return char, root, head, hum
end

-- ─────────────────────────────────────────────
--  AIMBOT
-- ─────────────────────────────────────────────
local function getBestTarget()
    local bestDist, bestPos = math.huge, nil
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if Config.TeamCheck and p.Team == LocalPlayer.Team then continue end

        local char, root, head, hum = getCharParts(p)
        if not char then continue end
        if hum.Health <= 0 then continue end

        local bone = Config.AimbotBone == "Head" and head or root
        local sp, depth, onScreen = w2vp(bone.Position)
        if not onScreen or depth < 0 then continue end

        local dist = (sp - center).Magnitude
        if dist < Config.AimFOV and dist < bestDist then
            bestDist = dist
            bestPos  = bone.CFrame.Position
        end
    end
    return bestPos
end

-- ─────────────────────────────────────────────
--  GUI THEME
-- ─────────────────────────────────────────────
local THEME = {
    bg         = Color3.fromRGB(15, 15, 20),
    tab        = Color3.fromRGB(22, 22, 30),
    tabActive  = Color3.fromRGB(100, 60, 200),
    accent     = Color3.fromRGB(120, 70, 230),
    panel      = Color3.fromRGB(20, 20, 28),
    border     = Color3.fromRGB(50, 50, 70),
    text       = Color3.fromRGB(220, 220, 240),
    textDim    = Color3.fromRGB(130, 130, 160),
    toggle_on  = Color3.fromRGB(100, 60, 200),
    toggle_off = Color3.fromRGB(50, 50, 70),
    slider_bg  = Color3.fromRGB(35, 35, 50),
    slider_fg  = Color3.fromRGB(100, 60, 200),
    close      = Color3.fromRGB(200, 50, 60),
    minimize   = Color3.fromRGB(200, 160, 30),
}

-- ─────────────────────────────────────────────
--  ScreenGui
-- ─────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "ACTestMenu"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset   = true
ScreenGui.Parent           = (syn and syn.protect_gui and syn.protect_gui(ScreenGui)) or game:GetService("CoreGui")

-- ─────────────────────────────────────────────
--  Main Frame
-- ─────────────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 420, 0, 360)
MainFrame.Position          = UDim2.new(0.5, -210, 0.5, -180)
MainFrame.BackgroundColor3  = THEME.bg
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color     = THEME.border
mainStroke.Thickness = 1.5

-- ── Title Bar ──
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = THEME.tab
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text              = "  🛡 AntiCheat Test Menu"
titleLabel.Size              = UDim2.new(1, -80, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3        = THEME.text
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextSize          = 13
titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
titleLabel.Parent            = TitleBar

-- Close / Minimize buttons
local function mkBtn(xOff, bg, lbl)
    local b = Instance.new("TextButton")
    b.Size              = UDim2.new(0, 24, 0, 20)
    b.Position          = UDim2.new(1, xOff, 0.5, -10)
    b.BackgroundColor3  = bg
    b.Text              = lbl
    b.TextColor3        = Color3.new(1,1,1)
    b.Font              = Enum.Font.GothamBold
    b.TextSize          = 11
    b.BorderSizePixel   = 0
    b.Parent            = TitleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local CloseBtn    = mkBtn(-6,  THEME.close,    "✕")
local MinimizeBtn = mkBtn(-34, THEME.minimize, "─")

-- Draggable
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = i.Position
        startPos  = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0, 420, 0, 32)
        or  UDim2.new(0, 420, 0, 360)
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    FOVCircle:Remove()
    for p,_ in pairs(ESPObjects) do removeESP(p) end
end)

-- ── Tab Bar ──
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, 30)
TabBar.Position         = UDim2.new(0, 0, 0, 32)
TabBar.BackgroundColor3 = THEME.panel
TabBar.BorderSizePixel  = 0
TabBar.Parent           = MainFrame

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection  = Enum.FillDirection.Horizontal
tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
tabLayout.Padding        = UDim.new(0, 2)

-- ── Content Area ──
local Content = Instance.new("ScrollingFrame")
Content.Size               = UDim2.new(1, 0, 1, -62)
Content.Position           = UDim2.new(0, 0, 0, 62)
Content.BackgroundColor3   = THEME.bg
Content.BorderSizePixel    = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = THEME.accent
Content.CanvasSize         = UDim2.new(0,0,0,0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent             = MainFrame

local contentLayout = Instance.new("UIListLayout", Content)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding   = UDim.new(0, 2)

local contentPad = Instance.new("UIPadding", Content)
contentPad.PaddingLeft   = UDim.new(0, 8)
contentPad.PaddingRight  = UDim.new(0, 8)
contentPad.PaddingTop    = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 6)

-- ─────────────────────────────────────────────
--  Tab system
-- ─────────────────────────────────────────────
local tabPages = {}
local tabBtns  = {}
local currentTab = nil

local function showTab(name)
    currentTab = name
    for n, page in pairs(tabPages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabBtns) do
        btn.BackgroundColor3 = (n == name) and THEME.tabActive or THEME.tab
        btn.TextColor3       = (n == name) and Color3.new(1,1,1) or THEME.textDim
    end
end

local function addTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = THEME.tab
    btn.Text             = name
    btn.TextColor3       = THEME.textDim
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = order
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local page = Instance.new("Frame")
    page.Name              = name
    page.Size              = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible           = false
    page.Parent            = Content

    local pl = Instance.new("UIListLayout", page)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Padding   = UDim.new(0, 4)

    tabPages[name] = page
    tabBtns[name]  = btn

    btn.MouseButton1Click:Connect(function() showTab(name) end)
    return page
end

-- ─────────────────────────────────────────────
--  Component builders
-- ─────────────────────────────────────────────
local function sectionLabel(parent, text, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = THEME.accent
    f.BackgroundTransparency = 0.75
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

    local l = Instance.new("TextLabel", f)
    l.Size              = UDim2.new(1, 8, 1, 0)
    l.Position          = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text              = text
    l.TextColor3        = THEME.accent
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = 11
    l.TextXAlignment    = Enum.TextXAlignment.Left
    return f
end

local function row(parent, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = THEME.panel
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color     = THEME.border
    stroke.Thickness = 1
    return f
end

-- Toggle
local function addToggle(parent, label, configKey, order, onChange)
    local f = row(parent, order)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size              = UDim2.new(1, -56, 1, 0)
    lbl.Position          = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = THEME.text
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local tog = Instance.new("TextButton", f)
    tog.Size             = UDim2.new(0, 40, 0, 20)
    tog.Position         = UDim2.new(1, -48, 0.5, -10)
    tog.BackgroundColor3 = Config[configKey] and THEME.toggle_on or THEME.toggle_off
    tog.Text             = ""
    tog.BorderSizePixel  = 0
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", tog)
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = Config[configKey] and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    tog.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]
        tog.BackgroundColor3 = on and THEME.toggle_on or THEME.toggle_off
        knob.Position        = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
        if onChange then onChange(on) end
    end)
    return f
end

-- Dropdown selector
local function addDropdown(parent, label, configKey, options, order, onChange)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = THEME.panel
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = THEME.border stroke.Thickness = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0, 160, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = THEME.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Cycle button
    local btn = Instance.new("TextButton", f)
    btn.Size             = UDim2.new(0, 100, 0, 22)
    btn.Position         = UDim2.new(1, -108, 0.5, -11)
    btn.BackgroundColor3 = THEME.accent
    btn.Text             = Config[configKey]
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local idx = 1
    for i,v in ipairs(options) do if v == Config[configKey] then idx = i end end

    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        Config[configKey] = options[idx]
        btn.Text = options[idx]
        if onChange then onChange(options[idx]) end
    end)
    return f
end

-- Slider
local function addSlider(parent, label, configKey, min, max, order, onChange)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 46)
    f.BackgroundColor3 = THEME.panel
    f.BorderSizePixel  = 0
    f.LayoutOrder      = order
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", f) stroke.Color = THEME.border stroke.Thickness = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,-10, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. Config[configKey]
    lbl.TextColor3 = THEME.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", f)
    track.Size             = UDim2.new(1, -20, 0, 6)
    track.Position         = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = THEME.slider_bg
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((Config[configKey]-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = THEME.slider_fg
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((Config[configKey]-min)/(max-min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local sliding = false
    local function update(x)
        local abs = track.AbsolutePosition.X
        local wid = track.AbsoluteSize.X
        local t   = math.clamp((x - abs) / wid, 0, 1)
        local val = math.floor(min + t*(max-min))
        Config[configKey] = val
        fill.Size     = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, 0, 0.5, 0)
        lbl.Text      = label .. ": " .. val
        if onChange then onChange(val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    return f
end

-- ─────────────────────────────────────────────
--  BUILD TABS
-- ─────────────────────────────────────────────
local pgAimbot  = addTab("⚙ Aimbot",  1)
local pgVisuals = addTab("👁 Visuals", 2)
local pgSettings= addTab("🔧 Settings",3)

-- ── AIMBOT TAB ──
sectionLabel(pgAimbot, "AIMBOT CORE", 1)
addToggle(pgAimbot,   "Enable Aimbot",        "AimbotEnabled", 2)
addDropdown(pgAimbot, "Bone Target",          "AimbotBone",    {"Head","HumanoidRootPart"}, 3)
addToggle(pgAimbot,   "Team Check",           "TeamCheck",     4)

sectionLabel(pgAimbot, "FOV", 10)
addToggle(pgAimbot,   "Show FOV Circle",      "ShowFOVCircle", 11, function(v)
    FOVCircle.Visible = v and Config.AimbotEnabled
end)
addSlider(pgAimbot,   "Aim FOV",              "AimFOV",        20, 500, 12, function(v)
    FOVCircle.Radius = v
end)

-- ── VISUALS TAB ──
sectionLabel(pgVisuals, "ESP CORE", 1)
addToggle(pgVisuals,   "Enable ESP",             "ESPEnabled",    2)

sectionLabel(pgVisuals, "ESP LINE", 10)
addToggle(pgVisuals,   "ESP Line",               "ESPLine",       11)
addDropdown(pgVisuals, "Line Origin",             "ESPLinePos",    {"Top","Bottom","Side"}, 12)

sectionLabel(pgVisuals, "ESP BOX", 20)
addToggle(pgVisuals,   "ESP Box",                "ESPBox",        21)

sectionLabel(pgVisuals, "HEALTH BAR", 30)
addToggle(pgVisuals,   "ESP Health Bar",          "ESPHealthBar",  31)
addDropdown(pgVisuals, "Health Bar Position",     "ESPHealthBarPos",{"Top","Left","Right","Bottom"}, 32)

sectionLabel(pgVisuals, "NAME & DISTANCE", 40)
addToggle(pgVisuals,   "ESP Name",               "ESPName",       41)
addDropdown(pgVisuals, "Name Position",           "ESPNamePos",    {"Top","Bottom"}, 42)
addToggle(pgVisuals,   "ESP Distance",            "ESPDistance",   43)
addDropdown(pgVisuals, "Distance Position",       "ESPDistancePos",{"Top","Bottom"}, 44)

-- ── SETTINGS TAB ──
sectionLabel(pgSettings, "AIMBOT SETTINGS", 1)
addSlider(pgSettings, "Aim Smoothing (×0.01)",  "AimSmoothing",  1, 100, 2, function(v)
    Config.AimSmoothing = v * 0.01
end)

sectionLabel(pgSettings, "ESP SETTINGS", 10)
addSlider(pgSettings, "Max ESP Distance",       "MaxESPDistance",100, 2000, 11)

sectionLabel(pgSettings, "INFO", 20)
local infoRow = row(pgSettings, 21)
local infoLbl = Instance.new("TextLabel", infoRow)
infoLbl.Size = UDim2.new(1,-10,1,0)
infoLbl.Position = UDim2.new(0,10,0,0)
infoLbl.BackgroundTransparency = 1
infoLbl.Text = "Hold RMB to aim  •  For anticheat testing only"
infoLbl.TextColor3 = THEME.textDim
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 11
infoLbl.TextXAlignment = Enum.TextXAlignment.Left

showTab("⚙ Aimbot")

-- ─────────────────────────────────────────────
--  Player ESP init/cleanup
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() initESP(p) end)
    initESP(p)
end)
Players.PlayerRemoving:Connect(removeESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then initESP(p) end
end

-- ─────────────────────────────────────────────
--  RENDER LOOP
-- ─────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    -- FOV Circle
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Position = center
    FOVCircle.Radius   = Config.AimFOV
    FOVCircle.Visible  = Config.ShowFOVCircle and Config.AimbotEnabled

    -- Aimbot
    if Config.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getBestTarget()
        if target then
            local sp = Camera:WorldToViewportPoint(target)
            local spVec = Vector2.new(sp.X, sp.Y)
            local smoothed = center + (spVec - center) * (1 - math.clamp(Config.AimSmoothing, 0.01, 1))
            -- Move mouse via mousemoverel (executor dependent)
            local delta = smoothed - center
            if mousemoverel then
                mousemoverel(delta.X, delta.Y)
            elseif Mouse.Delta then
                -- fallback: direct camera CFrame aim
                local dir = (target - Camera.CFrame.Position).Unit
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            end
        end
    end

    -- ESP
    for player, objs in pairs(ESPObjects) do
        local visible = false
        if Config.ESPEnabled and player ~= LocalPlayer then
            local char, root, head, hum = getCharParts(player)
            if char and hum.Health > 0 then
                -- Get screen bounds via character parts
                local parts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                local allOnScreen = false

                for _, pn in ipairs(parts) do
                    local part = char:FindFirstChild(pn) or root
                    local sp, depth, onScreen = w2vp(part.Position)
                    if onScreen and depth > 0 then
                        allOnScreen = true
                        if sp.X < minX then minX = sp.X end
                        if sp.Y < minY then minY = sp.Y end
                        if sp.X > maxX then maxX = sp.X end
                        if sp.Y > maxY then maxY = sp.Y end
                    end
                end

                local rootSP, rootDepth, rootOnScreen = w2vp(root.Position)
                local dist = (Camera.CFrame.Position - root.Position).Magnitude

                if allOnScreen and dist <= Config.MaxESPDistance then
                    visible = true
                    local bx, by = minX - 4, minY - 4
                    local bw, bh = (maxX - minX) + 8, (maxY - minY) + 8
                    local headSP = w2vp(head.Position)

                    -- BOX
                    objs.box.Visible  = Config.ESPBox
                    objs.box.Position = Vector2.new(bx, by)
                    objs.box.Size     = Vector2.new(bw, bh)
                    objs.box.Color    = Config.BoxColor

                    -- LINE
                    objs.line.Visible = Config.ESPLine
                    local lineFrom = center
                    if Config.ESPLinePos == "Top" then
                        lineFrom = Vector2.new(center.X, 0)
                    elseif Config.ESPLinePos == "Side" then
                        lineFrom = Vector2.new(rootSP.X < center.X and 0 or Camera.ViewportSize.X, center.Y)
                    end
                    objs.line.From  = lineFrom
                    objs.line.To    = rootSP
                    objs.line.Color = Config.LineColor

                    -- HEALTH BAR
                    local healthPct = hum.Health / hum.MaxHealth
                    objs.healthBg.Visible = Config.ESPHealthBar
                    objs.healthBar.Visible = Config.ESPHealthBar
                    local barThick = 4
                    if Config.ESPHealthBarPos == "Left" then
                        objs.healthBg.Position = Vector2.new(bx - barThick - 2, by)
                        objs.healthBg.Size     = Vector2.new(barThick, bh)
                        objs.healthBar.Position = Vector2.new(bx - barThick - 2, by + bh*(1-healthPct))
                        objs.healthBar.Size     = Vector2.new(barThick, bh*healthPct)
                    elseif Config.ESPHealthBarPos == "Right" then
                        objs.healthBg.Position = Vector2.new(bx + bw + 2, by)
                        objs.healthBg.Size     = Vector2.new(barThick, bh)
                        objs.healthBar.Position = Vector2.new(bx + bw + 2, by + bh*(1-healthPct))
                        objs.healthBar.Size     = Vector2.new(barThick, bh*healthPct)
                    elseif Config.ESPHealthBarPos == "Top" then
                        objs.healthBg.Position = Vector2.new(bx, by - barThick - 2)
                        objs.healthBg.Size     = Vector2.new(bw, barThick)
                        objs.healthBar.Position = Vector2.new(bx, by - barThick - 2)
                        objs.healthBar.Size     = Vector2.new(bw*healthPct, barThick)
                    else -- Bottom
                        objs.healthBg.Position = Vector2.new(bx, by + bh + 2)
                        objs.healthBg.Size     = Vector2.new(bw, barThick)
                        objs.healthBar.Position = Vector2.new(bx, by + bh + 2)
                        objs.healthBar.Size     = Vector2.new(bw*healthPct, barThick)
                    end
                    objs.healthBg.Color  = Color3.fromRGB(30,30,30)
                    objs.healthBar.Color = Color3.fromHSB(healthPct*0.33, 1, 1)

                    -- NAME
                    objs.nameText.Visible = Config.ESPName
                    objs.nameText.Text    = player.Name
                    objs.nameText.Color   = Config.TextColor
                    if Config.ESPNamePos == "Top" then
                        objs.nameText.Position = Vector2.new(bx + bw/2, by - 14)
                    else
                        objs.nameText.Position = Vector2.new(bx + bw/2, by + bh + 2)
                    end

                    -- DISTANCE
                    objs.distText.Visible = Config.ESPDistance
                    objs.distText.Text    = math.floor(dist) .. "m"
                    objs.distText.Color   = Config.TextColor
                    local distY = Config.ESPNamePos == "Bottom" and by + bh + 14 or by + bh + 2
                    if Config.ESPDistancePos == "Top" then
                        objs.distText.Position = Vector2.new(bx + bw/2, by - (Config.ESPName and 26 or 14))
                    else
                        objs.distText.Position = Vector2.new(bx + bw/2, distY)
                    end
                end
            end
        end
        if not visible then
            for _, d in pairs(objs) do d.Visible = false end
        end
    end
end)

print("[ACTestMenu] Loaded. Use tabs: Aimbot | Visuals | Settings")
