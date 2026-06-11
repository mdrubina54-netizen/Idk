-- ============================================
--   AntiCheat Test Menu | By Rone
--   For personal game anticheat testing only
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- SETTINGS STATE
-- ============================================
local Settings = {
    -- Aimbot
    AimbotEnabled = false,
    AimbotTarget = "Head",       -- "Head" | "Body"
    ShowFOVCircle = true,
    AimFOV = 100,
    TeamCheck = true,

    -- Visuals
    ESPEnabled = false,
    EspLine = false,
    EspLinePos = "Bottom",       -- "Top" | "Bottom" | "Side"
    EspBox = false,
    EspHealthBar = false,
    EspHealthBarPos = "Left",    -- "Top" | "Left" | "Right" | "Bottom"
    EspName = false,
    EspNamePos = "Top",          -- "Top" | "Bottom"
    EspDistance = false,
    EspDistancePos = "Bottom",   -- "Top" | "Bottom"

    -- Settings Tab
    MenuTheme = "Dark",
    MenuOpacity = 0.92,
    AimSmoothing = 0.2,
    AimPrediction = false,
    DebugMode = false,
}

-- ============================================
-- GUI SETUP
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ACTestMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Colors
local C = {
    BG        = Color3.fromRGB(15, 15, 20),
    Panel     = Color3.fromRGB(22, 22, 30),
    Header    = Color3.fromRGB(18, 18, 24),
    Accent    = Color3.fromRGB(99, 102, 241),
    AccentHov = Color3.fromRGB(129, 132, 255),
    TabActive = Color3.fromRGB(99, 102, 241),
    TabIdle   = Color3.fromRGB(30, 30, 40),
    Text      = Color3.fromRGB(220, 220, 235),
    SubText   = Color3.fromRGB(140, 140, 160),
    Toggle_ON = Color3.fromRGB(99, 102, 241),
    Toggle_OFF= Color3.fromRGB(50, 50, 65),
    Slider_BG = Color3.fromRGB(35, 35, 50),
    Dropdown  = Color3.fromRGB(28, 28, 38),
    Hover     = Color3.fromRGB(38, 38, 55),
    Close     = Color3.fromRGB(220, 60, 60),
    Minimize  = Color3.fromRGB(220, 165, 30),
    Divider   = Color3.fromRGB(35, 35, 50),
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(radius, parent)
    return create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(color, thickness, parent)
    return create("UIStroke", {Color = color, Thickness = thickness}, parent)
end

local function padding(t, b, l, r, parent)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b),
        PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r)
    }, parent)
end

local function tween(obj, props, t)
    game:GetService("TweenService"):Create(obj,
        TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- ============================================
-- MAIN WINDOW
-- ============================================
local MainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 420, 0, 480),
    Position = UDim2.new(0.5, -210, 0.5, -240),
    BackgroundColor3 = C.BG,
    BorderSizePixel = 0,
}, ScreenGui)
corner(10, MainFrame)
stroke(C.Accent, 1.2, MainFrame)

-- Drop shadow
local Shadow = create("ImageLabel", {
    Size = UDim2.new(1, 24, 1, 24),
    Position = UDim2.new(0, -12, 0, -12),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5554236805",
    ImageColor3 = Color3.new(0,0,0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(23,23,277,277),
    ZIndex = 0,
}, MainFrame)

-- Minimized bar
local MinBar = create("Frame", {
    Name = "MinBar",
    Size = UDim2.new(0, 420, 0, 36),
    Position = UDim2.new(0.5, -210, 0.5, -240),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
    Visible = false,
}, ScreenGui)
corner(8, MinBar)
stroke(C.Accent, 1, MinBar)

-- ============================================
-- HEADER
-- ============================================
local Header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
}, MainFrame)
corner(10, Header)

-- Fix bottom corners of header
create("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = C.Header,
    BorderSizePixel = 0,
}, Header)

create("TextLabel", {
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚔  AC Test Menu",
    TextColor3 = C.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Close Button
local CloseBtn = create("TextButton", {
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = C.Close,
    Text = "✕",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, Header)
corner(6, CloseBtn)

-- Minimize Button
local MinBtn = create("TextButton", {
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -70, 0.5, -14),
    BackgroundColor3 = C.Minimize,
    Text = "–",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, Header)
corner(6, MinBtn)

-- ============================================
-- DRAGGING
-- ============================================
local dragging, dragStart, startPos = false, nil, nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- MinBar dragging
local draggingMin, dragStartMin, startPosMin = false, nil, nil
MinBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMin = true
        dragStartMin = input.Position
        startPosMin = MinBar.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingMin and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartMin
        MinBar.Position = UDim2.new(
            startPosMin.X.Scale, startPosMin.X.Offset + delta.X,
            startPosMin.Y.Scale, startPosMin.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMin = false
    end
end)

-- ============================================
-- MINIMIZE / CLOSE LOGIC
-- ============================================
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- Sync MinBar position to MainFrame
        MinBar.Position = UDim2.new(
            MainFrame.Position.X.Scale, MainFrame.Position.X.Offset,
            MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset
        )
        MinBar.Visible = true

        -- Update MinBar title
        for _, v in ipairs(MinBar:GetChildren()) do
            if v:IsA("TextLabel") then v:Destroy() end
        end
        create("TextLabel", {
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = "⚔  AC Test Menu  [minimized]",
            TextColor3 = C.SubText,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, MinBar)

        local restoreBtn = create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -36, 0.5, -14),
            BackgroundColor3 = C.Minimize,
            Text = "□",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
        }, MinBar)
        corner(6, restoreBtn)
        restoreBtn.MouseButton1Click:Connect(function()
            minimized = false
            MainFrame.Position = MinBar.Position
            MainFrame.Visible = true
            MinBar.Visible = false
        end)

        MainFrame.Visible = false
    else
        MainFrame.Position = MinBar.Position
        MainFrame.Visible = true
        MinBar.Visible = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {BackgroundTransparency = 1}, 0.2)
    wait(0.2)
    ScreenGui:Destroy()
end)

-- ============================================
-- TAB BAR
-- ============================================
local TabBar = create("Frame", {
    Size = UDim2.new(1, -16, 0, 32),
    Position = UDim2.new(0, 8, 0, 50),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, MainFrame)
corner(8, TabBar)

local TabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, TabBar)
padding(3, 3, 6, 6, TabBar)

-- Content area
local ContentArea = create("Frame", {
    Size = UDim2.new(1, -16, 1, -100),
    Position = UDim2.new(0, 8, 0, 90),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, MainFrame)
corner(8, ContentArea)

-- ============================================
-- SCROLL FRAME HELPER
-- ============================================
local function makeScrollFrame(parent)
    local sf = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, parent)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sf)
    padding(8, 8, 10, 10, sf)
    return sf
end

-- ============================================
-- WIDGET BUILDERS
-- ============================================

-- Section label
local function addSection(parent, text)
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "  " .. text:upper(),
        TextColor3 = C.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    -- divider
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = C.Divider,
        BorderSizePixel = 0,
    }, lbl)
end

-- Toggle row
local function addToggle(parent, label, settingKey, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
    }, parent)
    corner(6, row)
    padding(0,0,10,10, row)

    create("TextLabel", {
        Size = UDim2.new(1, -52, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local pill = create("Frame", {
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -40, 0.5, -11),
        BackgroundColor3 = Settings[settingKey] and C.Toggle_ON or C.Toggle_OFF,
        BorderSizePixel = 0,
    }, row)
    corner(11, pill)

    local knob = create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = Settings[settingKey]
            and UDim2.new(1, -19, 0.5, -8)
            or  UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
    }, pill)
    corner(8, knob)

    local btn = create("TextButton", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
    }, row)

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local on = Settings[settingKey]
        tween(pill, {BackgroundColor3 = on and C.Toggle_ON or C.Toggle_OFF}, 0.15)
        tween(knob, {Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.15)
        if callback then callback(on) end
    end)

    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = C.Hover}) end)
    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = C.BG}) end)

    return row
end

-- Dropdown row
local function addDropdown(parent, label, settingKey, options, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 2,
    }, parent)
    corner(6, row)
    padding(0,0,10,10, row)

    create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    }, row)

    local dropBtn = create("TextButton", {
        Size = UDim2.new(0, 110, 0, 26),
        Position = UDim2.new(1, -110, 0.5, -13),
        BackgroundColor3 = C.Dropdown,
        Text = Settings[settingKey] .. "  ▾",
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, row)
    corner(6, dropBtn)
    stroke(C.Accent, 0.8, dropBtn)

    local opened = false
    local menuFrame = create("Frame", {
        Size = UDim2.new(0, 110, 0, #options * 28 + 4),
        Position = UDim2.new(1, -110, 1, 2),
        BackgroundColor3 = C.Dropdown,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
    }, row)
    corner(6, menuFrame)
    stroke(C.Accent, 0.8, menuFrame)
    padding(2,2,4,4, menuFrame)

    local menuLayout = create("UIListLayout", {
        Padding = UDim.new(0, 2),
    }, menuFrame)

    for _, opt in ipairs(options) do
        local optBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = Settings[settingKey] == opt and C.Accent or C.Dropdown,
            Text = opt,
            TextColor3 = Settings[settingKey] == opt and Color3.new(1,1,1) or C.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            ZIndex = 11,
        }, menuFrame)
        corner(5, optBtn)

        optBtn.MouseButton1Click:Connect(function()
            Settings[settingKey] = opt
            dropBtn.Text = opt .. "  ▾"
            menuFrame.Visible = false
            opened = false
            -- reset colors
            for _, c in ipairs(menuFrame:GetChildren()) do
                if c:IsA("TextButton") then
                    tween(c, {BackgroundColor3 = c.Text:gsub("  ▾","") == opt and C.Accent or C.Dropdown})
                    c.TextColor3 = c.Text:gsub("  ▾","") == opt and Color3.new(1,1,1) or C.Text
                end
            end
            if callback then callback(opt) end
        end)

        optBtn.MouseEnter:Connect(function()
            if Settings[settingKey] ~= opt then
                tween(optBtn, {BackgroundColor3 = C.Hover})
            end
        end)
        optBtn.MouseLeave:Connect(function()
            if Settings[settingKey] ~= opt then
                tween(optBtn, {BackgroundColor3 = C.Dropdown})
            end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        opened = not opened
        menuFrame.Visible = opened
    end)

    return row
end

-- Slider row
local function addSlider(parent, label, settingKey, minVal, maxVal, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = C.BG,
        BorderSizePixel = 0,
    }, parent)
    corner(6, row)
    padding(6,6,10,10, row)

    local topRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
    }, row)

    create("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, topRow)

    local valLabel = create("TextLabel", {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(Settings[settingKey]),
        TextColor3 = C.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, topRow)

    local track = create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = C.Slider_BG,
        BorderSizePixel = 0,
    }, row)
    corner(3, track)

    local pct = (Settings[settingKey] - minVal) / (maxVal - minVal)
    local fill = create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(3, fill)

    local thumb = create("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(pct, -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
    }, track)
    corner(7, thumb)

    local sliding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + relX * (maxVal - minVal))
            Settings[settingKey] = val
            valLabel.Text = tostring(val)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            thumb.Position = UDim2.new(relX, -7, 0.5, -7)
            if callback then callback(val) end
        end
    end)

    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = C.Hover}) end)
    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = C.BG}) end)

    return row
end

-- ============================================
-- TAB SYSTEM
-- ============================================
local tabs = {}
local activeTab = nil

local function makeTab(name, icon)
    local btn = create("TextButton", {
        Size = UDim2.new(0, 108, 1, -6),
        BackgroundColor3 = C.TabIdle,
        Text = icon .. "  " .. name,
        TextColor3 = C.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
    }, TabBar)
    corner(6, btn)

    local page = create("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = false,
    }, ContentArea)

    local scroll = makeScrollFrame(page)

    tabs[name] = {btn = btn, page = page, scroll = scroll}

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        if activeTab then
            tabs[activeTab].page.Visible = false
            tween(tabs[activeTab].btn, {BackgroundColor3 = C.TabIdle})
            tabs[activeTab].btn.TextColor3 = C.SubText
        end
        activeTab = name
        page.Visible = true
        tween(btn, {BackgroundColor3 = C.TabActive})
        btn.TextColor3 = Color3.new(1,1,1)
    end)

    return scroll
end

-- ============================================
-- BUILD TABS
-- ============================================

-- AIMBOT TAB
local aimScroll = makeTab("Aimbot", "🎯")
addSection(aimScroll, "Aimbot")
addToggle(aimScroll, "Enable Aimbot", "AimbotEnabled")
addDropdown(aimScroll, "Target Part", "AimbotTarget", {"Head", "Body"})
addToggle(aimScroll, "Team Check", "TeamCheck")
addToggle(aimScroll, "Show FOV Circle", "ShowFOVCircle")
addSlider(aimScroll, "Aim FOV Radius", "AimFOV", 20, 400)
addSection(aimScroll, "Advanced")
addSlider(aimScroll, "Aim Smoothing", "AimSmoothing", 1, 20)
addToggle(aimScroll, "Aim Prediction", "AimPrediction")

-- VISUALS TAB
local visScroll = makeTab("Visuals", "👁")
addSection(visScroll, "ESP")
addToggle(visScroll, "Enable ESP", "ESPEnabled")
addToggle(visScroll, "ESP Box", "EspBox")
addSection(visScroll, "Lines")
addToggle(visScroll, "ESP Line", "EspLine")
addDropdown(visScroll, "Line Position", "EspLinePos", {"Top", "Bottom", "Side"})
addSection(visScroll, "Health Bar")
addToggle(visScroll, "ESP Health Bar", "EspHealthBar")
addDropdown(visScroll, "Health Bar Side", "EspHealthBarPos", {"Top", "Left", "Right", "Bottom"})
addSection(visScroll, "Name & Distance")
addToggle(visScroll, "ESP Name", "EspName")
addDropdown(visScroll, "Name Position", "EspNamePos", {"Top", "Bottom"})
addToggle(visScroll, "ESP Distance", "EspDistance")
addDropdown(visScroll, "Distance Position", "EspDistancePos", {"Top", "Bottom"})

-- SETTINGS TAB
local setScroll = makeTab("Settings", "⚙")
addSection(setScroll, "Menu")
addDropdown(setScroll, "Theme", "MenuTheme", {"Dark", "Light", "Midnight", "Ocean"})
addSlider(setScroll, "UI Opacity %", "MenuOpacity", 60, 100)
addSection(setScroll, "Debug")
addToggle(setScroll, "Debug Mode", "DebugMode")

-- Activate first tab
tabs["Aimbot"].btn:MouseButton1Click()

-- ============================================
-- FOV CIRCLE DRAWING
-- ============================================
local fovCircle = create("Frame", {
    Size = UDim2.new(0, Settings.AimFOV * 2, 0, Settings.AimFOV * 2),
    Position = UDim2.new(0.5, -Settings.AimFOV, 0.5, -Settings.AimFOV),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, ScreenGui)
corner(Settings.AimFOV, fovCircle)
local fovStroke = stroke(C.Accent, 1.5, fovCircle)

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = Settings.ShowFOVCircle and Settings.AimbotEnabled
    if Settings.ShowFOVCircle and Settings.AimbotEnabled then
        local r = Settings.AimFOV
        fovCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
        fovCircle.Position = UDim2.new(0.5, -r, 0.5, -r)
        fovCircle:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, r)
    end
end)

-- ============================================
-- AIMBOT LOGIC (for testing)
-- ============================================
local function getClosestPlayer()
    local closest, closestDist = nil, Settings.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        -- Team check
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then continue end

        local partName = Settings.AimbotTarget == "Head" and "Head" or "HumanoidRootPart"
        local part = char:FindFirstChild(partName) or root

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = part
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Settings.AimbotEnabled then return end
    local target = getClosestPlayer()
    if not target then return end

    local cam = Camera
    local cf = cam.CFrame
    local targetPos = target.Position
    local smoothing = math.clamp(Settings.AimSmoothing / 10, 0.05, 1)
    local newCF = CFrame.new(cf.Position, targetPos)
    cam.CFrame = cf:Lerp(newCF, smoothing)
end)

-- ============================================
-- ESP DRAWING
-- ============================================
local espObjects = {}

local function clearESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if obj then obj:Destroy() end
        end
        espObjects[player] = nil
    end
end

local function drawESP(player)
    if player == LocalPlayer then return end
    if Settings.TeamCheck and player.Team == LocalPlayer.Team then
        clearESP(player)
        return
    end
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        clearESP(player)
        return
    end

    local torsoPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        clearESP(player)
        return
    end

    if not espObjects[player] then espObjects[player] = {} end
    local obj = espObjects[player]

    local vp = Camera.ViewportSize
    local headPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))
    local feetPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, -3, 0))
    local boxH = math.abs(headPos.Y - feetPos.Y)
    local boxW = boxH * 0.6
    local boxX = torsoPos.X - boxW / 2
    local boxY = headPos.Y

    local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
    local healthPct = hum.Health / hum.MaxHealth

    -- BOX
    if Settings.EspBox then
        if not obj.box then
            obj.box = create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, ScreenGui)
            stroke(Color3.fromRGB(255,255,80), 1.5, obj.box)
        end
        obj.box.Position = UDim2.new(0, boxX, 0, boxY)
        obj.box.Size = UDim2.new(0, boxW, 0, boxH)
        obj.box.Visible = true
    elseif obj.box then obj.box.Visible = false end

    -- LINE
    if Settings.EspLine then
        if not obj.line then
            obj.line = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,80,80),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 1, 0, 0),
            }, ScreenGui)
        end
        local fromX, fromY
        if Settings.EspLinePos == "Bottom" then fromX, fromY = vp.X/2, vp.Y
        elseif Settings.EspLinePos == "Top" then fromX, fromY = vp.X/2, 0
        else fromX, fromY = 0, vp.Y/2 end

        local dx = torsoPos.X - fromX
        local dy = torsoPos.Y - fromY
        local len = math.sqrt(dx*dx + dy*dy)
        local angle = math.atan2(dy, dx)
        obj.line.Position = UDim2.new(0, fromX, 0, fromY)
        obj.line.Size = UDim2.new(0, len, 0, 1)
        obj.line.Rotation = math.deg(angle)
        obj.line.Visible = true
    elseif obj.line then obj.line.Visible = false end

    -- HEALTH BAR
    if Settings.EspHealthBar then
        if not obj.hbBG then
            obj.hbBG = create("Frame", {BackgroundColor3 = Color3.fromRGB(40,40,40), BorderSizePixel = 0}, ScreenGui)
            corner(2, obj.hbBG)
            obj.hbFill = create("Frame", {BackgroundColor3 = Color3.fromRGB(50,220,80), BorderSizePixel = 0}, obj.hbBG)
            corner(2, obj.hbFill)
        end
        local pad = 3
        local pos = Settings.EspHealthBarPos
        local isV = pos == "Left" or pos == "Right"
        if isV then
            obj.hbBG.Size = UDim2.new(0, 5, 0, boxH)
            local bx = pos == "Left" and (boxX - 8) or (boxX + boxW + 3)
            obj.hbBG.Position = UDim2.new(0, bx, 0, boxY)
            obj.hbFill.Size = UDim2.new(1, 0, healthPct, 0)
            obj.hbFill.Position = UDim2.new(0, 0, 1 - healthPct, 0)
        else
            obj.hbBG.Size = UDim2.new(0, boxW, 0, 5)
            local by = pos == "Top" and (boxY - 8) or (boxY + boxH + 3)
            obj.hbBG.Position = UDim2.new(0, boxX, 0, by)
            obj.hbFill.Size = UDim2.new(healthPct, 0, 1, 0)
            obj.hbFill.Position = UDim2.new(0, 0, 0, 0)
        end
        obj.hbBG.Visible = true
    elseif obj.hbBG then obj.hbBG.Visible = false end

    -- NAME
    if Settings.EspName then
        if not obj.name then
            obj.name = create("TextLabel", {
                BackgroundTransparency = 1,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextStrokeTransparency = 0.4,
                TextStrokeColor3 = Color3.new(0,0,0),
                Size = UDim2.new(0, 100, 0, 16),
            }, ScreenGui)
        end
        obj.name.Text = player.Name
        local ny = Settings.EspNamePos == "Top" and (boxY - 18) or (boxY + boxH + 3)
        obj.name.Position = UDim2.new(0, torsoPos.X - 50, 0, ny)
        obj.name.Visible = true
    elseif obj.name then obj.name.Visible = false end

    -- DISTANCE
    if Settings.EspDistance then
        if not obj.dist then
            obj.dist = create("TextLabel", {
                BackgroundTransparency = 1,
                TextColor3 = C.SubText,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextStrokeTransparency = 0.4,
                TextStrokeColor3 = Color3.new(0,0,0),
                Size = UDim2.new(0, 80, 0, 14),
            }, ScreenGui)
        end
        obj.dist.Text = dist .. "m"
        local dy2 = Settings.EspDistancePos == "Top" and (boxY - (Settings.EspName and 34 or 18)) or (boxY + boxH + (Settings.EspName and 18 or 3))
        obj.dist.Position = UDim2.new(0, torsoPos.X - 40, 0, dy2)
        obj.dist.Visible = true
    elseif obj.dist then obj.dist.Visible = false end
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(clearESP)

RunService.RenderStepped:Connect(function()
    if not Settings.ESPEnabled then
        for player, _ in pairs(espObjects) do clearESP(player) end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        drawESP(player)
    end
end)

print("[ACTestMenu] Loaded — for anticheat testing only.")
