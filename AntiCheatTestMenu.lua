-- ============================================
--   AC Test Menu | Drawing API Version
--   For personal game anticheat testing only
-- ============================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

-- ============================================
-- SETTINGS STATE
-- ============================================
local S = {
    -- Aimbot
    AimbotEnabled  = false,
    AimbotTarget   = "Head",
    ShowFOV        = true,
    AimFOV         = 120,
    TeamCheck      = true,
    AimSmoothing   = 5,
    AimPrediction  = false,

    -- Visuals
    ESPEnabled     = false,
    EspBox         = false,
    EspLine        = false,
    EspLinePos     = "Bottom",
    EspHealthBar   = false,
    EspHealthPos   = "Left",
    EspName        = false,
    EspNamePos     = "Top",
    EspDistance    = false,
    EspDistPos     = "Bottom",

    -- Colors (can be changed)
    BoxColor       = Color3.fromRGB(255, 255, 80),
    LineColor      = Color3.fromRGB(255, 80, 80),
    NameColor      = Color3.fromRGB(255, 255, 255),
    DistColor      = Color3.fromRGB(180, 180, 255),
    FOVColor       = Color3.fromRGB(99, 102, 241),
    HealthHigh     = Color3.fromRGB(50, 220, 80),
    HealthLow      = Color3.fromRGB(220, 50, 50),
}

-- ============================================
-- DRAWING API HELPERS
-- ============================================
local function newLine(color, thick)
    local d = Drawing.new("Line")
    d.Visible   = false
    d.Color     = color or Color3.new(1,1,1)
    d.Thickness = thick or 1
    d.ZIndex    = 1
    return d
end

local function newRect(color, thick, filled)
    local d = Drawing.new("Square")
    d.Visible   = false
    d.Color     = color or Color3.new(1,1,1)
    d.Thickness = thick or 1
    d.Filled    = filled or false
    d.ZIndex    = 1
    return d
end

local function newText(color, size)
    local d = Drawing.new("Text")
    d.Visible  = false
    d.Color    = color or Color3.new(1,1,1)
    d.Size     = size or 13
    d.Font     = Drawing.Fonts.Plex
    d.Outline  = true
    d.OutlineColor = Color3.new(0,0,0)
    d.ZIndex   = 2
    return d
end

local function newCircle(color, thick)
    local d = Drawing.new("Circle")
    d.Visible   = false
    d.Color     = color or Color3.new(1,1,1)
    d.Thickness = thick or 1
    d.Filled    = false
    d.ZIndex    = 3
    return d
end

local function lerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

-- ============================================
-- FOV CIRCLE (Drawing)
-- ============================================
local fovCircle = newCircle(S.FOVColor, 1.5)

-- ============================================
-- ESP POOL
-- ============================================
local espPool = {}

local function getESP(player)
    if not espPool[player] then
        espPool[player] = {
            -- Box (4 lines)
            boxTop    = newLine(S.BoxColor, 1.2),
            boxBot    = newLine(S.BoxColor, 1.2),
            boxLeft   = newLine(S.BoxColor, 1.2),
            boxRight  = newLine(S.BoxColor, 1.2),
            -- Line from screen edge
            traceLine = newLine(S.LineColor, 1),
            -- Health bar bg + fill
            hbBG      = newRect(Color3.fromRGB(0,0,0), 0, true),
            hbFill    = newRect(S.HealthHigh, 0, true),
            -- Name + Distance text
            nameText  = newText(S.NameColor, 13),
            distText  = newText(S.DistColor, 12),
        }
    end
    return espPool[player]
end

local function hideESP(player)
    local e = espPool[player]
    if not e then return end
    for _, d in pairs(e) do d.Visible = false end
end

local function removeESP(player)
    local e = espPool[player]
    if not e then return end
    for _, d in pairs(e) do d:Remove() end
    espPool[player] = nil
end

Players.PlayerRemoving:Connect(removeESP)

-- ============================================
-- GUI SETUP
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name             = "ACTestMenu"
gui.ResetOnSpawn     = false
gui.DisplayOrder     = 999
gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
gui.Parent           = LocalPlayer:WaitForChild("PlayerGui")

local C = {
    BG        = Color3.fromRGB(13, 13, 18),
    Panel     = Color3.fromRGB(20, 20, 28),
    Header    = Color3.fromRGB(16, 16, 22),
    Accent    = Color3.fromRGB(99, 102, 241),
    TabActive = Color3.fromRGB(99, 102, 241),
    TabIdle   = Color3.fromRGB(28, 28, 38),
    Text      = Color3.fromRGB(220, 220, 235),
    Sub       = Color3.fromRGB(130, 130, 155),
    ON        = Color3.fromRGB(99, 102, 241),
    OFF       = Color3.fromRGB(45, 45, 60),
    SliderBG  = Color3.fromRGB(32, 32, 46),
    Drop      = Color3.fromRGB(26, 26, 36),
    Hover     = Color3.fromRGB(36, 36, 52),
    Close     = Color3.fromRGB(210, 55, 55),
    Minimize  = Color3.fromRGB(210, 160, 25),
    Divider   = Color3.fromRGB(32, 32, 46),
}

local function mk(cls, props, par)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if par then o.Parent=par end
    return o
end
local function corner(r,p) return mk("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(col,th,p) return mk("UIStroke",{Color=col,Thickness=th},p) end
local function pad(t,b,l,r,p)
    return mk("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p)
end
local function tw(obj,props,t)
    TweenService:Create(obj,TweenInfo.new(t or 0.14,Enum.EasingStyle.Quad),props):Play()
end

-- ============================================
-- MAIN WINDOW
-- ============================================
local Win = mk("Frame",{
    Size=UDim2.new(0,420,0,490),
    Position=UDim2.new(0.5,-210,0.5,-245),
    BackgroundColor3=C.BG,
    BorderSizePixel=0,
}, gui)
corner(10,Win)
stroke(C.Accent,1.2,Win)

-- Minimized bar
local MinBar = mk("Frame",{
    Size=UDim2.new(0,420,0,36),
    Position=UDim2.new(0.5,-210,0.5,-245),
    BackgroundColor3=C.Header,
    BorderSizePixel=0,
    Visible=false,
},gui)
corner(8,MinBar)
stroke(C.Accent,1,MinBar)

mk("TextLabel",{
    Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="⚔  AC Test Menu  [minimized]",
    TextColor3=C.Sub, TextSize=12, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,
},MinBar)

local restoreBtn = mk("TextButton",{
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-32,0.5,-13),
    BackgroundColor3=C.Minimize, Text="□",
    TextColor3=Color3.new(1,1,1), TextSize=14, Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},MinBar)
corner(6,restoreBtn)

-- ============================================
-- HEADER
-- ============================================
local Hdr = mk("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.Header,BorderSizePixel=0},Win)
corner(10,Hdr)
mk("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.Header,BorderSizePixel=0},Hdr)

mk("TextLabel",{
    Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,14,0,0),
    BackgroundTransparency=1, Text="⚔  AC Test Menu",
    TextColor3=C.Text, TextSize=15, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
},Hdr)

local CloseBtn = mk("TextButton",{
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-34,0.5,-13),
    BackgroundColor3=C.Close, Text="✕",
    TextColor3=Color3.new(1,1,1), TextSize=12, Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},Hdr)
corner(6,CloseBtn)

local MinBtn = mk("TextButton",{
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-66,0.5,-13),
    BackgroundColor3=C.Minimize, Text="–",
    TextColor3=Color3.new(1,1,1), TextSize=15, Font=Enum.Font.GothamBold,
    BorderSizePixel=0,
},Hdr)
corner(6,MinBtn)

-- ============================================
-- DRAGGING
-- ============================================
local function makeDraggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
end
makeDraggable(Hdr, Win)
makeDraggable(MinBar, MinBar)

-- ============================================
-- MINIMIZE / CLOSE
-- ============================================
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = true
    MinBar.Position = Win.Position
    Win.Visible = false
    MinBar.Visible = true
end)
restoreBtn.MouseButton1Click:Connect(function()
    minimized = false
    Win.Position = MinBar.Position
    Win.Visible = true
    MinBar.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do removeESP(p) end
    fovCircle:Remove()
    gui:Destroy()
end)

-- ============================================
-- TAB BAR + CONTENT
-- ============================================
local TabBar = mk("Frame",{
    Size=UDim2.new(1,-16,0,32), Position=UDim2.new(0,8,0,50),
    BackgroundColor3=C.Panel, BorderSizePixel=0,
},Win)
corner(8,TabBar)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},TabBar)
pad(3,3,6,6,TabBar)

local Content = mk("Frame",{
    Size=UDim2.new(1,-16,1,-98), Position=UDim2.new(0,8,0,90),
    BackgroundColor3=C.Panel, BorderSizePixel=0, ClipsDescendants=true,
},Win)
corner(8,Content)

local tabs, activeTab = {}, nil

local function makeScroll(parent)
    local sf = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3,
        ScrollBarImageColor3=C.Accent, CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
    },parent)
    mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sf)
    pad(8,8,10,10,sf)
    return sf
end

local function addTab(name, icon)
    local btn = mk("TextButton",{
        Size=UDim2.new(0,108,1,-6), BackgroundColor3=C.TabIdle,
        Text=icon.."  "..name, TextColor3=C.Sub,
        TextSize=12, Font=Enum.Font.GothamSemibold, BorderSizePixel=0,
    },TabBar)
    corner(6,btn)

    local page = mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},Content)
    local scroll = makeScroll(page)
    tabs[name] = {btn=btn, page=page, scroll=scroll}

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        if activeTab then
            tabs[activeTab].page.Visible = false
            tw(tabs[activeTab].btn,{BackgroundColor3=C.TabIdle})
            tabs[activeTab].btn.TextColor3 = C.Sub
        end
        activeTab = name
        page.Visible = true
        tw(btn,{BackgroundColor3=C.TabActive})
        btn.TextColor3 = Color3.new(1,1,1)
    end)
    return scroll
end

-- ============================================
-- WIDGET BUILDERS
-- ============================================
local function addSection(scroll, text)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},scroll)
    mk("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=text:upper(), TextColor3=C.Accent, TextSize=10,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    },f)
    mk("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Divider,BorderSizePixel=0},f)
end

local function addToggle(scroll, label, key, cb)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.BG,BorderSizePixel=0},scroll)
    corner(6,row); pad(0,0,10,10,row)
    mk("TextLabel",{
        Size=UDim2.new(1,-52,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=C.Text, TextSize=13,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    },row)
    local pill = mk("Frame",{
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-38,0.5,-10),
        BackgroundColor3=S[key] and C.ON or C.OFF, BorderSizePixel=0,
    },row)
    corner(10,pill)
    local knob = mk("Frame",{
        Size=UDim2.new(0,14,0,14),
        Position=S[key] and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    },pill)
    corner(7,knob)
    local btn = mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},row)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        local on = S[key]
        tw(pill,{BackgroundColor3=on and C.ON or C.OFF})
        tw(knob,{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if cb then cb(on) end
    end)
    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.Hover}) end)
    row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.BG}) end)
end

local function addDropdown(scroll, label, key, opts, cb)
    local row = mk("Frame",{
        Size=UDim2.new(1,0,0,34), BackgroundColor3=C.BG,
        BorderSizePixel=0, ClipsDescendants=false, ZIndex=2,
    },scroll)
    corner(6,row); pad(0,0,10,10,row)
    mk("TextLabel",{
        Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=C.Text, TextSize=13,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
    },row)
    local dBtn = mk("TextButton",{
        Size=UDim2.new(0,115,0,24), Position=UDim2.new(1,-115,0.5,-12),
        BackgroundColor3=C.Drop, Text=S[key].."  ▾",
        TextColor3=C.Text, TextSize=12, Font=Enum.Font.Gotham,
        BorderSizePixel=0, ZIndex=3,
    },row)
    corner(6,dBtn); stroke(C.Accent,0.7,dBtn)

    local menu = mk("Frame",{
        Size=UDim2.new(0,115,0,#opts*26+4), Position=UDim2.new(1,-115,1,2),
        BackgroundColor3=C.Drop, BorderSizePixel=0, Visible=false, ZIndex=10,
    },row)
    corner(6,menu); stroke(C.Accent,0.7,menu)
    pad(2,2,4,4,menu)
    mk("UIListLayout",{Padding=UDim.new(0,2)},menu)

    for _, opt in ipairs(opts) do
        local ob = mk("TextButton",{
            Size=UDim2.new(1,0,0,22),
            BackgroundColor3=S[key]==opt and C.Accent or C.Drop,
            Text=opt, TextColor3=S[key]==opt and Color3.new(1,1,1) or C.Text,
            TextSize=12, Font=Enum.Font.Gotham, BorderSizePixel=0, ZIndex=11,
        },menu)
        corner(4,ob)
        ob.MouseButton1Click:Connect(function()
            S[key] = opt
            dBtn.Text = opt.."  ▾"
            menu.Visible = false
            for _, c in ipairs(menu:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = c.Text == opt and C.Accent or C.Drop
                    c.TextColor3 = c.Text == opt and Color3.new(1,1,1) or C.Text
                end
            end
            if cb then cb(opt) end
        end)
        ob.MouseEnter:Connect(function() if S[key]~=opt then tw(ob,{BackgroundColor3=C.Hover}) end end)
        ob.MouseLeave:Connect(function() if S[key]~=opt then tw(ob,{BackgroundColor3=C.Drop}) end end)
    end

    local open = false
    dBtn.MouseButton1Click:Connect(function()
        open = not open
        menu.Visible = open
    end)
end

local function addSlider(scroll, label, key, mn, mx, cb)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG,BorderSizePixel=0},scroll)
    corner(6,row); pad(6,6,10,10,row)
    local top = mk("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1},row)
    mk("TextLabel",{
        Size=UDim2.new(0.7,0,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=C.Text, TextSize=13, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
    },top)
    local vLbl = mk("TextLabel",{
        Size=UDim2.new(0.3,0,1,0), Position=UDim2.new(0.7,0,0,0),
        BackgroundTransparency=1, Text=tostring(S[key]),
        TextColor3=C.Accent, TextSize=13, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Right,
    },top)
    local track = mk("Frame",{
        Size=UDim2.new(1,0,0,5), Position=UDim2.new(0,0,1,6),
        BackgroundColor3=C.SliderBG, BorderSizePixel=0,
    },row)
    corner(3,track)
    local pct = (S[key]-mn)/(mx-mn)
    local fill = mk("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.Accent,BorderSizePixel=0},track)
    corner(3,fill)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,12,0,12), Position=UDim2.new(pct,-6,0.5,-6),
        BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0,
    },track)
    corner(6,thumb)

    local sliding = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
            local p = math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v = math.floor(mn+p*(mx-mn))
            S[key]=v; vLbl.Text=tostring(v)
            fill.Size=UDim2.new(p,0,1,0)
            thumb.Position=UDim2.new(p,-6,0.5,-6)
            if cb then cb(v) end
        end
    end)
    row.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.Hover}) end)
    row.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.BG}) end)
end

-- ============================================
-- BUILD TABS
-- ============================================

-- AIMBOT
local aim = addTab("Aimbot","🎯")
addSection(aim,"Aimbot")
addToggle(aim,"Enable Aimbot","AimbotEnabled")
addDropdown(aim,"Target Part","AimbotTarget",{"Head","Body"})
addToggle(aim,"Team Check","TeamCheck")
addToggle(aim,"Show FOV Circle","ShowFOV")
addSlider(aim,"FOV Radius","AimFOV",20,400)
addSection(aim,"Advanced")
addSlider(aim,"Smoothing (lower=faster)","AimSmoothing",1,20)
addToggle(aim,"Aim Prediction","AimPrediction")

-- VISUALS
local vis = addTab("Visuals","👁")
addSection(vis,"ESP")
addToggle(vis,"Enable ESP","ESPEnabled")
addToggle(vis,"ESP Box","EspBox")
addSection(vis,"Lines")
addToggle(vis,"ESP Line","EspLine")
addDropdown(vis,"Line Position","EspLinePos",{"Top","Bottom","Side"})
addSection(vis,"Health Bar")
addToggle(vis,"ESP Health Bar","EspHealthBar")
addDropdown(vis,"Health Bar Side","EspHealthPos",{"Top","Left","Right","Bottom"})
addSection(vis,"Name & Distance")
addToggle(vis,"ESP Name","EspName")
addDropdown(vis,"Name Position","EspNamePos",{"Top","Bottom"})
addToggle(vis,"ESP Distance","EspDistance")
addDropdown(vis,"Distance Position","EspDistPos",{"Top","Bottom"})

-- SETTINGS
local set = addTab("Settings","⚙")
addSection(set,"Menu")
addToggle(set,"Debug Mode","DebugMode")
addSection(set,"Keybind")
addSection(set,"Info")
do
    local info = mk("TextLabel",{
        Size=UDim2.new(1,0,0,60), BackgroundTransparency=1,
        Text="Press [INSERT] to toggle menu visibility.\n\nFor anticheat testing on your own game only.",
        TextColor3=C.Sub, TextSize=12, Font=Enum.Font.Gotham,
        TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
    },set)
end

-- Activate Aimbot tab
tabs["Aimbot"].btn:MouseButton1Click()

-- ============================================
-- INSERT KEY TOGGLE
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Win.Visible = not Win.Visible
        if MinBar.Visible then MinBar.Visible = false end
    end
end)

-- ============================================
-- AIMBOT
-- ============================================
local function getTarget()
    local best, bestDist = nil, S.AimFOV
    local center = Camera.ViewportSize / 2

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if S.TeamCheck and p.Team == LocalPlayer.Team then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local partName = S.AimbotTarget == "Head" and "Head" or "HumanoidRootPart"
        local part = char:FindFirstChild(partName)
        if not part then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local d = (Vector2.new(sp.X,sp.Y) - center).Magnitude
            if d < bestDist then bestDist=d; best=part end
        end
    end
    return best
end

-- ============================================
-- RENDER LOOP
-- ============================================
RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    local center = vp / 2

    -- FOV Circle
    fovCircle.Visible  = S.ShowFOV and S.AimbotEnabled
    fovCircle.Radius   = S.AimFOV
    fovCircle.Position = center
    fovCircle.Color    = S.FOVColor

    -- Aimbot
    if S.AimbotEnabled then
        local target = getTarget()
        if target then
            local smoothFactor = math.clamp(S.AimSmoothing / 100, 0.01, 1)
            if S.AimPrediction then
                local vel = target.AssemblyLinearVelocity or Vector3.zero
                local pred = target.Position + vel * 0.1
                local newCF = CFrame.new(Camera.CFrame.Position, pred)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, smoothFactor)
            else
                local newCF = CFrame.new(Camera.CFrame.Position, target.Position)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, smoothFactor)
            end
        end
    end

    -- ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not S.ESPEnabled then hideESP(player); continue end
        if S.TeamCheck and player.Team == LocalPlayer.Team then hideESP(player); continue end

        local char = player.Character
        if not char then hideESP(player); continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then hideESP(player); continue end

        local headPart = char:FindFirstChild("Head")
        local headPos, headOnScreen = Camera:WorldToViewportPoint(
            headPart and headPart.Position or root.Position + Vector3.new(0,2.5,0)
        )
        local feetPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,-3,0))
        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then hideESP(player); continue end

        local e = getESP(player)
        local hpct = math.clamp(hum.Health/hum.MaxHealth,0,1)
        local healthColor = lerpColor(S.HealthLow, S.HealthHigh, hpct)

        local boxH = math.abs(headPos.Y - feetPos.Y)
        local boxW = boxH * 0.55
        local bx   = headPos.X - boxW/2
        local by   = headPos.Y
        local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

        -- BOX
        local showBox = S.EspBox
        if showBox then
            -- top
            e.boxTop.From=Vector2.new(bx,by); e.boxTop.To=Vector2.new(bx+boxW,by)
            e.boxTop.Color=S.BoxColor; e.boxTop.Visible=true
            -- bottom
            e.boxBot.From=Vector2.new(bx,by+boxH); e.boxBot.To=Vector2.new(bx+boxW,by+boxH)
            e.boxBot.Color=S.BoxColor; e.boxBot.Visible=true
            -- left
            e.boxLeft.From=Vector2.new(bx,by); e.boxLeft.To=Vector2.new(bx,by+boxH)
            e.boxLeft.Color=S.BoxColor; e.boxLeft.Visible=true
            -- right
            e.boxRight.From=Vector2.new(bx+boxW,by); e.boxRight.To=Vector2.new(bx+boxW,by+boxH)
            e.boxRight.Color=S.BoxColor; e.boxRight.Visible=true
        else
            e.boxTop.Visible=false; e.boxBot.Visible=false
            e.boxLeft.Visible=false; e.boxRight.Visible=false
        end

        -- TRACE LINE
        if S.EspLine then
            local fx, fy
            if S.EspLinePos=="Bottom" then fx,fy=center.X,vp.Y
            elseif S.EspLinePos=="Top" then fx,fy=center.X,0
            else fx,fy=0,center.Y end
            e.traceLine.From=Vector2.new(fx,fy)
            e.traceLine.To=Vector2.new(headPos.X,by+boxH)
            e.traceLine.Color=S.LineColor; e.traceLine.Visible=true
        else e.traceLine.Visible=false end

        -- HEALTH BAR
        if S.EspHealthBar then
            local isV = S.EspHealthPos=="Left" or S.EspHealthPos=="Right"
            local pad = 3
            if isV then
                local bxPos = S.EspHealthPos=="Left" and (bx-7) or (bx+boxW+3)
                e.hbBG.Position=Vector2.new(bxPos,by)
                e.hbBG.Size=Vector2.new(4,boxH)
                e.hbBG.Color=Color3.fromRGB(0,0,0); e.hbBG.Visible=true
                e.hbFill.Size=Vector2.new(4,boxH*hpct)
                e.hbFill.Position=Vector2.new(bxPos,by+boxH*(1-hpct))
                e.hbFill.Color=healthColor; e.hbFill.Visible=true
            else
                local byPos = S.EspHealthPos=="Top" and (by-8) or (by+boxH+4)
                e.hbBG.Position=Vector2.new(bx,byPos)
                e.hbBG.Size=Vector2.new(boxW,4)
                e.hbBG.Color=Color3.fromRGB(0,0,0); e.hbBG.Visible=true
                e.hbFill.Size=Vector2.new(boxW*hpct,4)
                e.hbFill.Position=Vector2.new(bx,byPos)
                e.hbFill.Color=healthColor; e.hbFill.Visible=true
            end
        else e.hbBG.Visible=false; e.hbFill.Visible=false end

        -- NAME
        if S.EspName then
            local ny = S.EspNamePos=="Top" and (by-16) or (by+boxH+3)
            e.nameText.Text=player.Name
            e.nameText.Position=Vector2.new(headPos.X, ny)
            e.nameText.Center=true
            e.nameText.Color=S.NameColor; e.nameText.Visible=true
        else e.nameText.Visible=false end

        -- DISTANCE
        if S.EspDistance then
            local nameOffset = S.EspName and 14 or 0
            local dy
            if S.EspDistPos=="Top" then
                dy = by - 16 - nameOffset
            else
                dy = by + boxH + 3 + nameOffset
            end
            e.distText.Text=dist.."m"
            e.distText.Position=Vector2.new(headPos.X, dy)
            e.distText.Center=true
            e.distText.Color=S.DistColor; e.distText.Visible=true
        else e.distText.Visible=false end
    end
end)

print("[ACTestMenu] Ready — Drawing API active.")
