-- ================================================
--   Advanced Menu GUI | Aimbot + ESP + Settings
--   Uses Drawing API | For personal anticheat testing
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- ================================================
-- CONFIG / STATE
-- ================================================
local Config = {
    -- Aimbot
    AimbotEnabled     = false,
    AimbotPart        = "Head",       -- "Head" | "HumanoidRootPart"
    ShowFOVCircle     = true,
    AimFOV            = 150,

    -- ESP
    ESPEnabled        = false,
    ESPLine           = false,
    ESPLineFrom       = "Bottom",     -- "Top" | "Bottom" | "Side"
    ESPBox            = false,
    ESPHealthBar      = false,
    ESPHealthBarPos   = "Left",       -- "Top" | "Left" | "Right" | "Bottom"
    ESPName           = false,
    ESPNamePos        = "Top",        -- "Top" | "Bottom"
    ESPDistance       = false,
    ESPDistancePos    = "Bottom",     -- "Top" | "Bottom"

    -- Settings
    TeamCheck         = false,
    MaxDistance       = 500,
    AimbotKey         = Enum.UserInputType.MouseButton2,
    HighlightTarget   = true,
    SmoothFactor      = 0.3,
}

-- ================================================
-- DRAWING OBJECTS POOL
-- ================================================
local ESPObjects   = {}
local FOVCircle    = Drawing.new("Circle")
FOVCircle.Visible  = false
FOVCircle.Radius   = Config.AimFOV
FOVCircle.Color    = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness= 1.5
FOVCircle.Filled   = false
FOVCircle.Transparency = 0.8

-- ================================================
-- UTILITY
-- ================================================
local function WorldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetBoundingBox(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local head = character:FindFirstChild("Head")
    if not head then return nil end

    local topPos,    topOnScreen    = WorldToViewport(head.Position + Vector3.new(0, head.Size.Y / 2, 0))
    local bottomPos, bottomOnScreen = WorldToViewport(rootPart.Position - Vector3.new(0, 3, 0))

    if not topOnScreen and not bottomOnScreen then return nil end

    local height = math.abs(bottomPos.Y - topPos.Y)
    local width  = height * 0.45
    local centerX = (topPos.X + bottomPos.X) / 2

    return {
        Top    = topPos,
        Bottom = bottomPos,
        Width  = width,
        Height = height,
        CenterX= centerX,
        Left   = centerX - width / 2,
        Right  = centerX + width / 2,
    }
end

local function GetClosestPlayer()
    local closest, closestDist = nil, Config.AimFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local part = char:FindFirstChild(Config.AimbotPart)
        if not part then continue end

        local screenPos, onScreen, depth = WorldToViewport(part.Position)
        if not onScreen or depth > Config.MaxDistance then continue end

        local dist = (screenPos - center).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = player
        end
    end
    return closest
end

-- ================================================
-- ESP DRAWING
-- ================================================
local function GetOrCreateESP(player)
    if not ESPObjects[player] then
        ESPObjects[player] = {
            Box        = Drawing.new("Square"),
            HealthBg   = Drawing.new("Square"),
            HealthFill = Drawing.new("Square"),
            Line       = Drawing.new("Line"),
            Name       = Drawing.new("Text"),
            Distance   = Drawing.new("Text"),
        }
        local e = ESPObjects[player]

        e.Box.Visible       = false
        e.Box.Color         = Color3.fromRGB(255, 255, 255)
        e.Box.Thickness     = 1.5
        e.Box.Filled        = false

        e.HealthBg.Visible  = false
        e.HealthBg.Color    = Color3.fromRGB(0, 0, 0)
        e.HealthBg.Filled   = true
        e.HealthBg.Thickness= 1

        e.HealthFill.Visible  = false
        e.HealthFill.Color    = Color3.fromRGB(0, 255, 80)
        e.HealthFill.Filled   = true
        e.HealthFill.Thickness= 1

        e.Line.Visible      = false
        e.Line.Color        = Color3.fromRGB(255, 80, 80)
        e.Line.Thickness    = 1.2

        e.Name.Visible      = false
        e.Name.Color        = Color3.fromRGB(255, 255, 255)
        e.Name.Size         = 13
        e.Name.Font         = Drawing.Fonts.UI
        e.Name.Center       = true
        e.Name.Outline      = true

        e.Distance.Visible  = false
        e.Distance.Color    = Color3.fromRGB(200, 200, 200)
        e.Distance.Size     = 12
        e.Distance.Font     = Drawing.Fonts.UI
        e.Distance.Center   = true
        e.Distance.Outline  = true
    end
    return ESPObjects[player]
end

local function HideESP(e)
    e.Box.Visible        = false
    e.HealthBg.Visible   = false
    e.HealthFill.Visible = false
    e.Line.Visible       = false
    e.Name.Visible       = false
    e.Distance.Visible   = false
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local e = GetOrCreateESP(player)

        if not Config.ESPEnabled then HideESP(e) continue end
        if Config.TeamCheck and player.Team == LocalPlayer.Team then HideESP(e) continue end

        local char = player.Character
        if not char then HideESP(e) continue end

        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then HideESP(e) continue end

        local bb = GetBoundingBox(char)
        if not bb then HideESP(e) continue end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local dist = rootPart and math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude) or 0

        if dist > Config.MaxDistance then HideESP(e) continue end

        -- BOX
        if Config.ESPBox then
            e.Box.Visible   = true
            e.Box.Size      = Vector2.new(bb.Width, bb.Height)
            e.Box.Position  = Vector2.new(bb.Left, bb.Top.Y)
        else
            e.Box.Visible = false
        end

        -- HEALTH BAR
        if Config.ESPHealthBar then
            local hp     = humanoid.Health
            local maxHp  = humanoid.MaxHealth
            local ratio  = math.clamp(hp / maxHp, 0, 1)
            local barW   = 4
            local barH   = bb.Height

            local bx, by
            local pos = Config.ESPHealthBarPos
            if pos == "Left" then
                bx = bb.Left - barW - 2; by = bb.Top.Y
                e.HealthBg.Size   = Vector2.new(barW, barH)
                e.HealthFill.Size = Vector2.new(barW, barH * ratio)
                e.HealthBg.Position   = Vector2.new(bx, by)
                e.HealthFill.Position = Vector2.new(bx, by + barH * (1 - ratio))
            elseif pos == "Right" then
                bx = bb.Right + 2; by = bb.Top.Y
                e.HealthBg.Size   = Vector2.new(barW, barH)
                e.HealthFill.Size = Vector2.new(barW, barH * ratio)
                e.HealthBg.Position   = Vector2.new(bx, by)
                e.HealthFill.Position = Vector2.new(bx, by + barH * (1 - ratio))
            elseif pos == "Top" then
                bx = bb.Left; by = bb.Top.Y - barW - 2
                e.HealthBg.Size   = Vector2.new(bb.Width, barW)
                e.HealthFill.Size = Vector2.new(bb.Width * ratio, barW)
                e.HealthBg.Position   = Vector2.new(bx, by)
                e.HealthFill.Position = Vector2.new(bx, by)
            elseif pos == "Bottom" then
                bx = bb.Left; by = bb.Bottom.Y + 2
                e.HealthBg.Size   = Vector2.new(bb.Width, barW)
                e.HealthFill.Size = Vector2.new(bb.Width * ratio, barW)
                e.HealthBg.Position   = Vector2.new(bx, by)
                e.HealthFill.Position = Vector2.new(bx, by)
            end

            local gr = math.floor((1 - ratio) * 255)
            local rr = math.floor(ratio * 255)
            e.HealthFill.Color = Color3.fromRGB(255 - rr, rr, 0)
            e.HealthBg.Visible   = true
            e.HealthFill.Visible = true
        else
            e.HealthBg.Visible   = false
            e.HealthFill.Visible = false
        end

        -- LINE
        if Config.ESPLine then
            e.Line.Visible = true
            local vp = Camera.ViewportSize
            local from
            local lp = Config.ESPLineFrom
            if lp == "Top"    then from = Vector2.new(vp.X / 2, 0)
            elseif lp == "Side" then from = Vector2.new(0, vp.Y / 2)
            else                     from = Vector2.new(vp.X / 2, vp.Y)
            end
            e.Line.From = from
            e.Line.To   = bb.Bottom
        else
            e.Line.Visible = false
        end

        -- NAME
        if Config.ESPName then
            e.Name.Visible = true
            e.Name.Text    = player.Name
            local np = Config.ESPNamePos
            if np == "Top" then
                e.Name.Position = Vector2.new(bb.CenterX, bb.Top.Y - 15)
            else
                e.Name.Position = Vector2.new(bb.CenterX, bb.Bottom.Y + 2)
            end
        else
            e.Name.Visible = false
        end

        -- DISTANCE
        if Config.ESPDistance then
            e.Distance.Visible = true
            e.Distance.Text    = dist .. "m"
            local dp = Config.ESPDistancePos
            local nameOffset = Config.ESPName and 14 or 0
            if dp == "Top" then
                e.Distance.Position = Vector2.new(bb.CenterX, bb.Top.Y - 15 - nameOffset)
            else
                e.Distance.Position = Vector2.new(bb.CenterX, bb.Bottom.Y + 2 + nameOffset)
            end
        else
            e.Distance.Visible = false
        end
    end
end

-- ================================================
-- AIMBOT
-- ================================================
local function UpdateAimbot(dt)
    -- FOV Circle
    local vp = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    FOVCircle.Radius   = Config.AimFOV
    FOVCircle.Visible  = Config.ShowFOVCircle

    if not Config.AimbotEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local target = GetClosestPlayer()
    if not target then return end

    local char = target.Character
    if not char then return end

    local part = char:FindFirstChild(Config.AimbotPart)
    if not part then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, Config.SmoothFactor)
end

-- ================================================
-- GUI SETUP
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "AdvancedMenu"
ScreenGui.ResetOnSpawn     = false
ScreenGui.IgnoreGuiInset   = true
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent           = LocalPlayer:WaitForChild("PlayerGui")

-- Colors
local C = {
    BG       = Color3.fromRGB(15, 15, 20),
    Header   = Color3.fromRGB(20, 20, 28),
    Tab      = Color3.fromRGB(25, 25, 35),
    TabSel   = Color3.fromRGB(100, 60, 220),
    Accent   = Color3.fromRGB(110, 70, 230),
    Toggle   = Color3.fromRGB(30, 30, 42),
    ToggleOn = Color3.fromRGB(100, 60, 220),
    Text     = Color3.fromRGB(220, 220, 230),
    Sub      = Color3.fromRGB(140, 140, 160),
    Slider   = Color3.fromRGB(50, 50, 70),
    SliderFg = Color3.fromRGB(110, 70, 230),
    Border   = Color3.fromRGB(50, 45, 80),
    Close    = Color3.fromRGB(200, 60, 60),
    Minimize = Color3.fromRGB(60, 60, 80),
    DropBG   = Color3.fromRGB(22, 22, 32),
}

local W, H    = 380, 420
local minimized = false
local dragging, dragStart, startPos = false, nil, nil

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size            = UDim2.new(0, W, 0, H)
Main.Position        = UDim2.new(0.5, -W/2, 0.5, -H/2)
Main.BackgroundColor3= C.BG
Main.BorderSizePixel = 0
Main.Active          = true
Main.Parent          = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color     = C.Border
MainStroke.Thickness = 1.2

-- HEADER
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 36)
Header.BackgroundColor3 = C.Header
Header.BorderSizePixel  = 0
Header.Parent           = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local HeaderFix = Instance.new("Frame") -- cover bottom corners
HeaderFix.Size             = UDim2.new(1, 0, 0, 10)
HeaderFix.Position         = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = C.Header
HeaderFix.BorderSizePixel  = 0
HeaderFix.Parent           = Header

-- Title
local Title = Instance.new("TextLabel")
Title.Size               = UDim2.new(1, -80, 1, 0)
Title.Position           = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text               = "⚡ AdvMenu"
Title.TextColor3         = C.Text
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Left
Title.Parent             = Header

-- CLOSE BUTTON
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size               = UDim2.new(0, 24, 0, 24)
CloseBtn.Position           = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3   = C.Close
CloseBtn.Text               = "✕"
CloseBtn.TextColor3         = Color3.fromRGB(255,255,255)
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.TextSize           = 12
CloseBtn.BorderSizePixel    = 0
CloseBtn.Parent             = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    FOVCircle:Remove()
    for _, e in pairs(ESPObjects) do
        for _, d in pairs(e) do pcall(function() d:Remove() end) end
    end
end)

-- MINIMIZE BUTTON
local MinBtn = Instance.new("TextButton")
MinBtn.Size               = UDim2.new(0, 24, 0, 24)
MinBtn.Position           = UDim2.new(1, -58, 0, 6)
MinBtn.BackgroundColor3   = C.Minimize
MinBtn.Text               = "—"
MinBtn.TextColor3         = C.Text
MinBtn.Font               = Enum.Font.GothamBold
MinBtn.TextSize           = 13
MinBtn.BorderSizePixel    = 0
MinBtn.Parent             = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local ContentArea = Instance.new("Frame")
ContentArea.Size             = UDim2.new(1, 0, 1, -36)
ContentArea.Position         = UDim2.new(0, 0, 0, 36)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent           = Main

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentArea.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, W, 0, 36) or UDim2.new(0, W, 0, H)
    MinBtn.Text = minimized and "□" or "—"
end)

-- DRAG
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Main.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ================================================
-- TAB BAR
-- ================================================
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -10, 0, 30)
TabBar.Position         = UDim2.new(0, 5, 0, 5)
TabBar.BackgroundColor3 = C.Tab
TabBar.BorderSizePixel  = 0
TabBar.Parent           = ContentArea
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 6)
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
TabLayout.Padding       = UDim.new(0, 2)
Instance.new("UIPadding", TabBar).PaddingLeft = UDim.new(0, 4)

-- SCROLL AREA
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size             = UDim2.new(1, -10, 1, -48)
ScrollFrame.Position         = UDim2.new(0, 5, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel  = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = C.Accent
ScrollFrame.CanvasSize       = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent           = ContentArea

local ContentLayout = Instance.new("UIListLayout", ScrollFrame)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding   = UDim.new(0, 0)
Instance.new("UIPadding", ScrollFrame).PaddingTop = UDim.new(0, 4)

-- ================================================
-- COMPONENT BUILDERS
-- ================================================
local function Spacer(parent, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h or 6)
    f.BackgroundTransparency = 1
    f.Parent = parent
end

local function SectionLabel(parent, text)
    Spacer(parent, 4)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -10, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text             = "  " .. text
    lbl.TextColor3       = C.Accent
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = parent
    Spacer(parent, 2)
end

local function Toggle(parent, label, default, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -10, 0, 34)
    row.BackgroundColor3 = C.Toggle
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", row).PaddingLeft = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = C.Text
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 36, 0, 18)
    pill.Position         = UDim2.new(1, -46, 0.5, -9)
    pill.BackgroundColor3 = default and C.ToggleOn or C.Slider
    pill.BorderSizePixel  = 0
    pill.Parent           = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.Parent           = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        state = not state
        pill.BackgroundColor3 = state and C.ToggleOn or C.Slider
        knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        callback(state)
    end)
    Spacer(parent, 2)
    return row
end

local function Dropdown(parent, label, options, default, callback)
    local wrap = Instance.new("Frame")
    wrap.Size             = UDim2.new(1, -10, 0, 34)
    wrap.BackgroundColor3 = C.Toggle
    wrap.BorderSizePixel  = 0
    wrap.ClipsDescendants = false
    wrap.Parent           = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.5, 0, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = C.Text
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = wrap

    local valBtn = Instance.new("TextButton")
    valBtn.Size             = UDim2.new(0, 120, 0, 24)
    valBtn.Position         = UDim2.new(1, -130, 0.5, -12)
    valBtn.BackgroundColor3 = C.DropBG
    valBtn.Text             = default .. " ▾"
    valBtn.TextColor3       = C.Sub
    valBtn.Font             = Enum.Font.Gotham
    valBtn.TextSize         = 12
    valBtn.BorderSizePixel  = 0
    valBtn.Parent           = wrap
    Instance.new("UICorner", valBtn).CornerRadius = UDim.new(0, 5)

    local dropdown = Instance.new("Frame")
    dropdown.Size             = UDim2.new(0, 120, 0, #options * 26 + 4)
    dropdown.Position         = UDim2.new(1, -130, 1, 2)
    dropdown.BackgroundColor3 = C.DropBG
    dropdown.BorderSizePixel  = 0
    dropdown.Visible          = false
    dropdown.ZIndex           = 10
    dropdown.Parent           = wrap
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)
    local ddStroke = Instance.new("UIStroke", dropdown)
    ddStroke.Color     = C.Border
    ddStroke.Thickness = 1
    local ddLayout = Instance.new("UIListLayout", dropdown)
    ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", dropdown).PaddingTop = UDim.new(0, 2)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size               = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundTransparency = 1
        optBtn.Text               = opt
        optBtn.TextColor3         = C.Text
        optBtn.Font               = Enum.Font.Gotham
        optBtn.TextSize           = 12
        optBtn.ZIndex             = 11
        optBtn.Parent             = dropdown
        optBtn.MouseButton1Click:Connect(function()
            valBtn.Text   = opt .. " ▾"
            dropdown.Visible = false
            callback(opt)
        end)
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0
            optBtn.BackgroundColor3 = Color3.fromRGB(40, 38, 55)
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
        end)
    end

    valBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    Spacer(parent, 2)
    return wrap
end

local function Slider(parent, label, min, max, default, callback)
    local wrap = Instance.new("Frame")
    wrap.Size             = UDim2.new(1, -10, 0, 50)
    wrap.BackgroundColor3 = C.Toggle
    wrap.BorderSizePixel  = 0
    wrap.Parent           = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -60, 0, 20)
    lbl.Position           = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = C.Text
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = wrap

    local valLbl = Instance.new("TextLabel")
    valLbl.Size               = UDim2.new(0, 50, 0, 20)
    valLbl.Position           = UDim2.new(1, -58, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text               = tostring(default)
    valLbl.TextColor3         = C.Accent
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextSize           = 13
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.Parent             = wrap

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -20, 0, 6)
    track.Position         = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = C.Slider
    track.BorderSizePixel  = 0
    track.Parent           = wrap
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.SliderFg
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    local function updateSlider(input)
        local trackPos  = track.AbsolutePosition
        local trackSize = track.AbsoluteSize
        local rel       = math.clamp((input.Position.X - trackPos.X) / trackSize.X, 0, 1)
        local val       = math.floor(min + rel * (max - min))
        fill.Size       = UDim2.new(rel, 0, 1, 0)
        valLbl.Text     = tostring(val)
        callback(val)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSlider(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(i)
        end
    end)

    Spacer(parent, 2)
    return wrap
end

-- ================================================
-- TAB SYSTEM
-- ================================================
local tabs     = {}
local tabPages = {}
local activePage = nil

local function MakeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 108, 1, -6)
    btn.BackgroundColor3 = C.Tab
    btn.Text             = name
    btn.TextColor3       = C.Sub
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = order
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local page = Instance.new("Frame")
    page.Size              = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible           = false
    page.Parent            = ScrollFrame
    local pl = Instance.new("UIListLayout", page)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Padding   = UDim.new(0, 2)
    Instance.new("UIPadding", page).PaddingLeft = UDim.new(0, 5)

    tabs[name]     = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        for n, b in pairs(tabs) do
            b.BackgroundColor3 = C.Tab
            b.TextColor3       = C.Sub
        end
        for n, p in pairs(tabPages) do
            p.Visible = false
        end
        btn.BackgroundColor3 = C.TabSel
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        page.Visible         = true
        activePage           = name
    end)

    return page
end

local pageAimbot  = MakeTab("Aimbot",  1)
local pageVisuals = MakeTab("Visuals", 2)
local pageSetting = MakeTab("Setting", 3)

-- Activate first tab
tabs["Aimbot"].BackgroundColor3 = C.TabSel
tabs["Aimbot"].TextColor3       = Color3.fromRGB(255,255,255)
tabPages["Aimbot"].Visible      = true

-- ================================================
-- AIMBOT TAB
-- ================================================
SectionLabel(pageAimbot, "AIMBOT")
Toggle(pageAimbot, "Enable Aimbot", Config.AimbotEnabled, function(v)
    Config.AimbotEnabled = v
end)
Dropdown(pageAimbot, "Target Part", {"Head", "HumanoidRootPart"}, Config.AimbotPart, function(v)
    Config.AimbotPart = v
end)
Spacer(pageAimbot, 4)
SectionLabel(pageAimbot, "FOV")
Toggle(pageAimbot, "Show FOV Circle", Config.ShowFOVCircle, function(v)
    Config.ShowFOVCircle = v
    FOVCircle.Visible = v
end)
Slider(pageAimbot, "Aim FOV", 10, 600, Config.AimFOV, function(v)
    Config.AimFOV = v
end)
Spacer(pageAimbot, 4)
SectionLabel(pageAimbot, "SMOOTHING")
Slider(pageAimbot, "Smooth Factor (x10)", 1, 10, math.floor(Config.SmoothFactor * 10), function(v)
    Config.SmoothFactor = v / 10
end)

-- ================================================
-- VISUALS TAB
-- ================================================
SectionLabel(pageVisuals, "ESP")
Toggle(pageVisuals, "Enable ESP", Config.ESPEnabled, function(v)
    Config.ESPEnabled = v
end)
Spacer(pageVisuals, 4)

SectionLabel(pageVisuals, "ESP LINE")
Toggle(pageVisuals, "ESP Line", Config.ESPLine, function(v)
    Config.ESPLine = v
end)
Dropdown(pageVisuals, "Line Origin", {"Top","Bottom","Side"}, Config.ESPLineFrom, function(v)
    Config.ESPLineFrom = v
end)
Spacer(pageVisuals, 4)

SectionLabel(pageVisuals, "ESP BOX")
Toggle(pageVisuals, "ESP Box", Config.ESPBox, function(v)
    Config.ESPBox = v
end)
Spacer(pageVisuals, 4)

SectionLabel(pageVisuals, "HEALTH BAR")
Toggle(pageVisuals, "ESP Health Bar", Config.ESPHealthBar, function(v)
    Config.ESPHealthBar = v
end)
Dropdown(pageVisuals, "Health Bar Side", {"Top","Left","Right","Bottom"}, Config.ESPHealthBarPos, function(v)
    Config.ESPHealthBarPos = v
end)
Spacer(pageVisuals, 4)

SectionLabel(pageVisuals, "NAME")
Toggle(pageVisuals, "ESP Name", Config.ESPName, function(v)
    Config.ESPName = v
end)
Dropdown(pageVisuals, "Name Position", {"Top","Bottom"}, Config.ESPNamePos, function(v)
    Config.ESPNamePos = v
end)
Spacer(pageVisuals, 4)

SectionLabel(pageVisuals, "DISTANCE")
Toggle(pageVisuals, "ESP Distance", Config.ESPDistance, function(v)
    Config.ESPDistance = v
end)
Dropdown(pageVisuals, "Distance Position", {"Top","Bottom"}, Config.ESPDistancePos, function(v)
    Config.ESPDistancePos = v
end)

-- ================================================
-- SETTINGS TAB
-- ================================================
SectionLabel(pageSetting, "GENERAL")
Toggle(pageSetting, "Team Check", Config.TeamCheck, function(v)
    Config.TeamCheck = v
end)
Toggle(pageSetting, "Highlight Target", Config.HighlightTarget, function(v)
    Config.HighlightTarget = v
end)
Spacer(pageSetting, 4)

SectionLabel(pageSetting, "LIMITS")
Slider(pageSetting, "Max Distance (studs)", 50, 1000, Config.MaxDistance, function(v)
    Config.MaxDistance = v
end)
Spacer(pageSetting, 4)

SectionLabel(pageSetting, "UI")
Toggle(pageSetting, "Show FOV Circle", Config.ShowFOVCircle, function(v)
    Config.ShowFOVCircle = v
end)

-- ================================================
-- CLEANUP ON PLAYER LEFT
-- ================================================
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, d in pairs(ESPObjects[player]) do
            pcall(function() d:Remove() end)
        end
        ESPObjects[player] = nil
    end
end)

-- ================================================
-- MAIN LOOP
-- ================================================
RunService.RenderStepped:Connect(function(dt)
    UpdateAimbot(dt)
    UpdateESP()
end)

print("✅ AdvMenu loaded — RMB to aim, open menu to configure.")
