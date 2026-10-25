--[[
    Kanha UI — Full Rayfield Edition
    Aimbot (instant snap, range, wallcheck)
    Silent Aim (GU hook + FireServer hook, wallcheck)
    ESP, Fly, Speed, TP Button (draggable), AutoHeal, InfHealth, AutoKill
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera

local LP   = Players.LocalPlayer
local reps = game:GetService("ReplicatedStorage")

-- ============================================================
--  GAME MODULES  (pcall so the script doesn't die on wrong game)
-- ============================================================
local U, EL, GU
pcall(function()
    U  = require(reps.Modules.Utility)
    EL = require(reps.Modules.EnumLibrary)
    GU = require(reps.Modules.GameplayUtility)
end)

pcall(function()
    local gun = require(LP.PlayerScripts.Modules.ItemTypes.Gun)
    if gun and gun.IsFullyAiming then
        gun.IsFullyAiming = function() return true end
    end
end)

-- ============================================================
--  SETTINGS
-- ============================================================
local S = {
    -- Main / Aimbot
    Aimbot          = false,
    AimbotRange     = 500,    -- studs (3D world distance)
    AimSilent       = false,
    HitPart         = "Head",
    FovCircle       = false,
    FovSize         = 90,     -- screen-space pixels
    TeamCheck       = false,
    WallCheck       = false,
    TeamCheckType   = "Enemy Only",

    -- Visual
    EnableESP        = true,
    ESPTeamCheck     = false,
    ESPTeamCheckType = "Enemy Only",
    ESPLine          = false,
    ESPLinePos       = "Bottom",
    ESPLineColor     = Color3.fromRGB(239, 68, 68),
    ESPBox           = false,
    ESPBoxType       = "2D",
    ESPBoxColor      = Color3.fromRGB(59, 130, 246),
    ESPHealth        = false,
    ESPHealthPos     = "Left",
    ESPHealthColor   = Color3.fromRGB(34, 197, 94),
    ESPName          = false,
    ESPNamePos       = "Top",
    ESPNameColor     = Color3.fromRGB(245, 245, 245),
    ESPDistance      = false,
    ESPDistancePos   = "Bottom",
    ESPDistanceColor = Color3.fromRGB(251, 191, 36),
    ESPSkeleton      = false,

    -- Extra
    Fly             = false,
    FlySpeed        = 50,
    SpeedVelocity   = false,
    Velocity        = 16,
    TPNearestPlayer = false,
    TPTeamCheck     = "Enemy Only",
    AutoHeal        = false,
    InfHealth       = false,
    AutoKill        = false,
}

-- ============================================================
--  UTILITIES
-- ============================================================
local function W2S(pos)
    local v, inView = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z, inView
end

local function GetTeamColor(player)
    return Color3.fromBrickColor(player.TeamColor)
end

local function PassesTeamFilter(player, checkType)
    if checkType == "All" then return true end
    local sameColor = player.TeamColor == LP.TeamColor
    local sameTeam  = (player.Team ~= nil and player.Team == LP.Team) or sameColor
    if checkType == "Team Color" then return not sameColor end
    if checkType == "Same Team"  then return sameTeam      end
    if checkType == "Enemy Only" then return not sameTeam  end
    return true
end

-- Wall check — works for both a BasePart (target part) or a character model
local function WallCheckPart(partPos, charModel)
    local origin = Camera.CFrame.Position
    local dir    = partPos - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = charModel
        and {LP.Character, Workspace.Terrain, charModel}
        or  {LP.Character, Workspace.Terrain}
    local res = Workspace:Raycast(origin, dir, params)
    -- visible if nothing blocked, or if the hit is inside the character
    if not res then return true end
    if charModel and res.Instance:IsDescendantOf(charModel) then return true end
    return false
end

local function PassesWallCheck(character)
    if not S.WallCheck then return true end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return WallCheckPart(hrp.Position, character)
end

local function GetBox(char)
    local head = char:FindFirstChild("Head")
    local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("HumanoidRootPart")
    if not head or not foot then return nil end
    local hs, hd, ho = W2S(head.Position + Vector3.new(0, 0.6, 0))
    local fs, fd, fo = W2S(foot.Position - Vector3.new(0, 2.5, 0))
    if not ho or not fo or hd < 0 or fd < 0 then return nil end
    local h  = math.abs(fs.Y - hs.Y)
    local w  = h * 0.52
    local cx = (hs.X + fs.X) * 0.5
    return { x = cx - w*0.5, y = hs.Y, w = w, h = h, cx = cx, cy = (hs.Y + fs.Y)*0.5 }
end

-- ============================================================
--  TARGET ACQUISITION
-- ============================================================

-- Used by: silent aim (CollectionService entity system)
local function target()
    local center   = Camera.ViewportSize / 2
    local bestPart, bestDist = nil, S.FovSize

    for _, entity in CollectionService:GetTagged("Entity") do
        if entity == LP.Character then continue end

        if S.TeamCheck then
            local p = Players:GetPlayerFromCharacter(entity)
            if p and not PassesTeamFilter(p, S.TeamCheckType) then continue end
        end

        local part = entity:FindFirstChild(S.HitPart, true)
        if not part or not part:IsA("BasePart") then continue end

        -- Wall check for silent aim
        if S.WallCheck and not WallCheckPart(part.Position, entity) then continue end

        -- Range check (3D)
        local dist3d = (part.Position - Camera.CFrame.Position).Magnitude
        if dist3d > S.AimbotRange then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist = d; bestPart = part end
    end

    return bestPart
end

-- Used by: hard aimbot + TP (Players service)
local function GetClosestPlayer()
    local center    = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local best, bestDist = nil, S.FovSize

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local hum = p.Character:FindFirstChild("Humanoid")
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end
        if S.TeamCheck and not PassesTeamFilter(p, S.TeamCheckType) then continue end

        -- 3D range check
        local dist3d = (hrp.Position - Camera.CFrame.Position).Magnitude
        if dist3d > S.AimbotRange then continue end

        -- Wall check for aimbot
        if S.WallCheck and not PassesWallCheck(p.Character) then continue end

        local ss, depth, onScreen = W2S(hrp.Position)
        if onScreen and depth > 0 then
            local d = (ss - center).Magnitude
            if d < bestDist then bestDist = d; best = p end
        end
    end

    return best
end

-- ============================================================
--  CFD  (camera data encoder for UseItem hook)
-- ============================================================
local function CFD(origin, part)
    if not U then return nil end
    local cf = part.CFrame
    local d  = {}
    d[utf8.char(1)] = {
        [utf8.char(0)] = U:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
        [utf8.char(1)] = U:EncodeCFrame(cf),
        [utf8.char(2)] = part,
        [utf8.char(3)] = U:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
    }
    return d
end

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local SKEL_PAIRS = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},   {"LeftUpperArm","LeftLowerArm"},   {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},  {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},   {"LeftUpperLeg","LeftLowerLeg"},   {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},  {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local DB = {}

local function NL(t, c) local l=Drawing.new("Line");   l.Visible=false;l.Thickness=t;l.Color=c;   return l end
local function NS(f, t) local s=Drawing.new("Square"); s.Visible=false;s.Filled=f or false;if t then s.Transparency=t end; return s end
local function NT(sz,c,o) local t=Drawing.new("Text"); t.Visible=false;t.Size=sz;t.Center=c;t.Outline=o; return t end

local function AddPlayer(player)
    if player == LP or DB[player] then return end
    local d = {
        Box         = NS(false),
        BoxFill     = NS(true, 0.7),
        CornerLines = {},
        Name        = NT(13, true, true),
        Distance    = NT(12, true, true),
        HealthBG    = NS(true),
        HealthFill  = NS(true),
        Line        = NL(1, Color3.new(1,1,1)),
        Skeleton    = {},
    }
    d.HealthBG.Color = Color3.fromRGB(25, 25, 25)
    for i = 1, 8 do d.CornerLines[i] = NL(1.5, Color3.new(1,1,1)) end
    for _, pair in ipairs(SKEL_PAIRS) do
        table.insert(d.Skeleton, { line = NL(1, Color3.new(1,1,1)), a = pair[1], b = pair[2] })
    end
    DB[player] = d
end

local function RemovePlayer(player)
    local d = DB[player]; if not d then return end
    for _, obj in pairs({ d.Box, d.BoxFill, d.Name, d.Distance, d.HealthBG, d.HealthFill, d.Line }) do obj:Remove() end
    for _, l  in ipairs(d.CornerLines) do l:Remove() end
    for _, sk in ipairs(d.Skeleton)    do sk.line:Remove() end
    DB[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do AddPlayer(p) end
Players.PlayerAdded:Connect(function(p) task.wait(1); AddPlayer(p) end)
Players.PlayerRemoving:Connect(RemovePlayer)

local function DrawCornerBox(d, box, col)
    local x,y,w,h = box.x,box.y,box.w,box.h
    local lx,ly   = w*0.22, h*0.22
    local corners  = {
        {Vector2.new(x,y),     Vector2.new(x+lx,y),     Vector2.new(x,y+ly)    },
        {Vector2.new(x+w,y),   Vector2.new(x+w-lx,y),   Vector2.new(x+w,y+ly)  },
        {Vector2.new(x,y+h),   Vector2.new(x+lx,y+h),   Vector2.new(x,y+h-ly)  },
        {Vector2.new(x+w,y+h), Vector2.new(x+w-lx,y+h), Vector2.new(x+w,y+h-ly)},
    }
    local i = 1
    for _, c in ipairs(corners) do
        d.CornerLines[i].From=c[1]; d.CornerLines[i].To=c[2]; d.CornerLines[i].Color=col; d.CornerLines[i].Visible=true; i+=1
        d.CornerLines[i].From=c[1]; d.CornerLines[i].To=c[3]; d.CornerLines[i].Color=col; d.CornerLines[i].Visible=true; i+=1
    end
end

local function HideCorner(d) for _,l in ipairs(d.CornerLines) do l.Visible=false end end

-- ============================================================
--  FOV CIRCLE
-- ============================================================
local FovCircle        = Drawing.new("Circle")
FovCircle.Visible      = false
FovCircle.Thickness    = 1
FovCircle.NumSides     = 64
FovCircle.Color        = Color3.fromRGB(255, 255, 255)
FovCircle.Filled       = false
FovCircle.Transparency = 1

-- ============================================================
--  FLY
-- ============================================================
local flyConn
local function SetFly(on)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    if not on then hum.PlatformStand = false; return end
    hum.PlatformStand = true
    flyConn = RunService.RenderStepped:Connect(function()
        if not S.Fly then
            hum.PlatformStand = false; flyConn:Disconnect(); flyConn = nil; return
        end
        local dir, cf = Vector3.zero, Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis  end
        hrp.AssemblyLinearVelocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * S.FlySpeed
    end)
end

-- ============================================================
--  TP NEAREST
-- ============================================================
local function TPNearest()
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local ph  = p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character:FindFirstChild("Humanoid")
        if not ph or not hum or hum.Health <= 0 then continue end
        if not PassesTeamFilter(p, S.TPTeamCheck) then continue end
        local d = (ph.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist = d; best = p end
    end
    if best and best.Character then
        local ph = best.Character:FindFirstChild("HumanoidRootPart")
        if ph then hrp.CFrame = ph.CFrame + ph.CFrame.LookVector * 3 end
    end
end

-- ============================================================
--  LOAD RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"
))()

local Window = Rayfield:CreateWindow({
    Name                 = "Kanha UI",
    LoadingTitle         = "Kanha UI",
    LoadingSubtitle      = "@#9002111185000#",
    Theme                = "Default",
    DisableBuildWarnings = true,
    ConfigurationSaving  = { Enabled = false, FileName = "KanhaUI" },
})

-- ============================================================
--  MAIN TAB
-- ============================================================
local MainTab = Window:CreateTab("Main", "crosshair")

MainTab:CreateSection("Aimbot")

MainTab:CreateToggle({
    Name = "Aimbot", CurrentValue = false, Flag = "Aimbot",
    Callback = function(v) S.Aimbot = v end,
})

MainTab:CreateSlider({
    Name = "Aimbot Range (studs)", Range = {50, 2000}, Increment = 25,
    CurrentValue = S.AimbotRange, Flag = "AimbotRange",
    Callback = function(v) S.AimbotRange = v end,
})

MainTab:CreateToggle({
    Name = "Aim Silent", CurrentValue = false, Flag = "AimSilent",
    Callback = function(v) S.AimSilent = v end,
})

MainTab:CreateDivider()

MainTab:CreateToggle({
    Name = "Fov Circle", CurrentValue = false, Flag = "FovCircle",
    Callback = function(v) S.FovCircle = v end,
})

MainTab:CreateSlider({
    Name = "Fov Size", Range = {10, 500}, Increment = 5,
    CurrentValue = S.FovSize, Flag = "FovSize",
    Callback = function(v) S.FovSize = v end,
})

MainTab:CreateDivider()
MainTab:CreateSection("Filters")

MainTab:CreateToggle({
    Name = "Team Check", CurrentValue = false, Flag = "TeamCheck",
    Callback = function(v) S.TeamCheck = v end,
})

MainTab:CreateDropdown({
    Name = "Team Check Type",
    Options = {"Enemy Only", "Same Team", "Team Color", "All"},
    CurrentOption = "Enemy Only", Flag = "TeamCheckType",
    Callback = function(v) S.TeamCheckType = v end,
})

MainTab:CreateToggle({
    Name = "Wall Check (Aimbot + Silent)", CurrentValue = false, Flag = "WallCheck",
    Callback = function(v) S.WallCheck = v end,
})

-- ============================================================
--  VISUAL TAB
-- ============================================================
local VisualTab = Window:CreateTab("Visual", "eye")

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "Enable ESP", CurrentValue = true, Flag = "EnableESP",
    Callback = function(v) S.EnableESP = v end,
})

VisualTab:CreateToggle({
    Name = "Team Check (ESP)", CurrentValue = false, Flag = "ESPTeamCheck",
    Callback = function(v) S.ESPTeamCheck = v end,
})

VisualTab:CreateDropdown({
    Name = "Team Check Type (ESP)",
    Options = {"Team Color", "Enemy Only", "Same Team", "All"},
    CurrentOption = "Enemy Only", Flag = "ESPTeamCheckType",
    Callback = function(v) S.ESPTeamCheckType = v end,
})

VisualTab:CreateSection("Tracer")

VisualTab:CreateToggle({
    Name = "ESP Line", CurrentValue = false, Flag = "ESPLine",
    Callback = function(v) S.ESPLine = v end,
})
VisualTab:CreateDropdown({
    Name = "Line Position", Options = {"Top","Bottom","Side","Center"},
    CurrentOption = "Bottom", Flag = "ESPLinePos",
    Callback = function(v) S.ESPLinePos = v end,
})
VisualTab:CreateColorPicker({
    Name = "Line Color", Color = S.ESPLineColor, Flag = "ESPLineColor",
    Callback = function(v) S.ESPLineColor = v end,
})

VisualTab:CreateSection("Box")

VisualTab:CreateToggle({
    Name = "ESP Box", CurrentValue = false, Flag = "ESPBox",
    Callback = function(v) S.ESPBox = v end,
})
VisualTab:CreateDropdown({
    Name = "Box Type", Options = {"2D","Corner","2D+Filled"},
    CurrentOption = "2D", Flag = "ESPBoxType",
    Callback = function(v) S.ESPBoxType = v end,
})
VisualTab:CreateColorPicker({
    Name = "Box Color", Color = S.ESPBoxColor, Flag = "ESPBoxColor",
    Callback = function(v) S.ESPBoxColor = v end,
})

VisualTab:CreateSection("Health")

VisualTab:CreateToggle({
    Name = "ESP Health", CurrentValue = false, Flag = "ESPHealth",
    Callback = function(v) S.ESPHealth = v end,
})
VisualTab:CreateDropdown({
    Name = "Health Position", Options = {"Left","Right","Top","Bottom"},
    CurrentOption = "Left", Flag = "ESPHealthPos",
    Callback = function(v) S.ESPHealthPos = v end,
})
VisualTab:CreateColorPicker({
    Name = "Health Color", Color = S.ESPHealthColor, Flag = "ESPHealthColor",
    Callback = function(v) S.ESPHealthColor = v end,
})

VisualTab:CreateSection("Name")

VisualTab:CreateToggle({
    Name = "ESP Name", CurrentValue = false, Flag = "ESPName",
    Callback = function(v) S.ESPName = v end,
})
VisualTab:CreateDropdown({
    Name = "Name Position", Options = {"Top","Bottom"},
    CurrentOption = "Top", Flag = "ESPNamePos",
    Callback = function(v) S.ESPNamePos = v end,
})
VisualTab:CreateColorPicker({
    Name = "Name Color", Color = S.ESPNameColor, Flag = "ESPNameColor",
    Callback = function(v) S.ESPNameColor = v end,
})

VisualTab:CreateSection("Distance")

VisualTab:CreateToggle({
    Name = "ESP Distance", CurrentValue = false, Flag = "ESPDistance",
    Callback = function(v) S.ESPDistance = v end,
})
VisualTab:CreateDropdown({
    Name = "Distance Position", Options = {"Top","Bottom"},
    CurrentOption = "Bottom", Flag = "ESPDistancePos",
    Callback = function(v) S.ESPDistancePos = v end,
})
VisualTab:CreateColorPicker({
    Name = "Distance Color", Color = S.ESPDistanceColor, Flag = "ESPDistanceColor",
    Callback = function(v) S.ESPDistanceColor = v end,
})

VisualTab:CreateSection("Skeleton")

VisualTab:CreateToggle({
    Name = "ESP Skeleton", CurrentValue = false, Flag = "ESPSkeleton",
    Callback = function(v) S.ESPSkeleton = v end,
})

-- ============================================================
--  EXTRA TAB
-- ============================================================
local ExtraTab = Window:CreateTab("Extra", "zap")

ExtraTab:CreateSection("Movement")

ExtraTab:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "Fly",
    Callback = function(v) S.Fly = v; if not v then SetFly(false) end end,
})
ExtraTab:CreateSlider({
    Name = "Fly Speed", Range = {5, 300}, Increment = 5,
    CurrentValue = S.FlySpeed, Flag = "FlySpeed",
    Callback = function(v) S.FlySpeed = v end,
})

ExtraTab:CreateDivider()

ExtraTab:CreateToggle({
    Name = "Speed Velocity", CurrentValue = false, Flag = "SpeedVelocity",
    Callback = function(v) S.SpeedVelocity = v end,
})
ExtraTab:CreateSlider({
    Name = "Velocity", Range = {1, 150}, Increment = 1,
    CurrentValue = S.Velocity, Flag = "Velocity",
    Callback = function(v) S.Velocity = v end,
})

ExtraTab:CreateSection("Teleport")

ExtraTab:CreateToggle({
    Name = "TP Nearest Player", CurrentValue = false, Flag = "TPNearestPlayer",
    Callback = function(v)
        S.TPNearestPlayer = v
        -- Show/hide the draggable TP button
        if _TPBtn then _TPBtn.Visible = v end
    end,
})
ExtraTab:CreateDropdown({
    Name = "TP Team Check",
    Options = {"Enemy Only", "Same Team", "Team Color", "All"},
    CurrentOption = "Enemy Only", Flag = "TPTeamCheck",
    Callback = function(v) S.TPTeamCheck = v end,
})

ExtraTab:CreateSection("Misc")

ExtraTab:CreateToggle({
    Name = "Auto Heal", CurrentValue = false, Flag = "AutoHeal",
    Callback = function(v) S.AutoHeal = v end,
})
ExtraTab:CreateToggle({
    Name = "Inf Health", CurrentValue = false, Flag = "InfHealth",
    Callback = function(v) S.InfHealth = v end,
})
ExtraTab:CreateToggle({
    Name = "Auto Kill", CurrentValue = false, Flag = "AutoKill",
    Callback = function(v) S.AutoKill = v end,
})

-- ============================================================
--  DRAGGABLE TP BUTTON
-- ============================================================
local tpGui = Instance.new("ScreenGui")
tpGui.Name          = "KanhaTPBtn"
tpGui.ResetOnSpawn  = false
tpGui.DisplayOrder  = 999
tpGui.IgnoreGuiInset = true

if gethui then
    tpGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(tpGui)
    tpGui.Parent = CoreGui
else
    tpGui.Parent = CoreGui
end

local tpBtn = Instance.new("TextButton")
tpBtn.Size                  = UDim2.new(0, 96, 0, 40)
tpBtn.Position              = UDim2.new(0.5, -48, 0.85, 0)
tpBtn.AnchorPoint           = Vector2.new(0, 0)
tpBtn.BackgroundColor3      = Color3.fromRGB(12, 12, 24)
tpBtn.TextColor3            = Color3.fromRGB(200, 185, 255)
tpBtn.Font                  = Enum.Font.GothamBold
tpBtn.TextSize              = 13
tpBtn.Text                  = "⚡  TP"
tpBtn.BorderSizePixel       = 0
tpBtn.AutoButtonColor       = false
tpBtn.Visible               = false    -- shown only when toggle is on
tpBtn.ZIndex                = 10
tpBtn.Parent                = tpGui

local _corner = Instance.new("UICorner")
_corner.CornerRadius = UDim.new(0, 10)
_corner.Parent = tpBtn

local _stroke = Instance.new("UIStroke")
_stroke.Color     = Color3.fromRGB(120, 100, 250)
_stroke.Thickness = 1.5
_stroke.Parent    = tpBtn

local _hint = Instance.new("TextLabel")
_hint.Size              = UDim2.new(1, 0, 0, 14)
_hint.Position          = UDim2.new(0, 0, 1, 3)
_hint.BackgroundTransparency = 1
_hint.Text              = "hold & drag to move"
_hint.TextColor3        = Color3.fromRGB(120, 100, 180)
_hint.Font              = Enum.Font.Gotham
_hint.TextSize          = 10
_hint.ZIndex            = 10
_hint.Parent            = tpBtn

-- Expose to toggle callback above
_TPBtn = tpBtn

-- Drag + tap logic
local _isDrag    = false
local _dragOrig, _btnOrig, _totalDrag

tpBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        _isDrag    = true
        _totalDrag = 0
        _dragOrig  = inp.Position
        _btnOrig   = tpBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not _isDrag then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position - _dragOrig
        _totalDrag  = delta.Magnitude
        tpBtn.Position = UDim2.new(
            _btnOrig.X.Scale,
            _btnOrig.X.Offset + delta.X,
            _btnOrig.Y.Scale,
            _btnOrig.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if not _isDrag then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        _isDrag = false
        if _totalDrag < 8 then
            -- It's a tap — TP
            TPNearest()
            TweenService:Create(tpBtn, TweenInfo.new(0.08), {
                BackgroundColor3 = Color3.fromRGB(55, 35, 110)
            }):Play()
            task.delay(0.18, function()
                TweenService:Create(tpBtn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(12, 12, 24)
                }):Play()
            end)
        end
        -- else: it was a drag — reposition only, no TP
    end
end)

-- ============================================================
--  SILENT AIM HOOKS
-- ============================================================
if GU then
    local _orig = GU.GetEntitiesFromRaycast
    GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
        if S.AimSilent then
            local t = target()
            if t then
                local dist = (t.Position - origin).Magnitude
                dir    = (t.Position - origin).Unit
                if dist > maxDist then maxDist = dist + 5 end
            end
        end
        return _orig(self, envID, params, origin, dir, maxDist, ...)
    end
end

pcall(function()
    local UseItem = reps.Remotes.Replication.Fighter.UseItem
    local _hook
    _hook = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
        if S.AimSilent and EL and enumVal == EL:ToEnum("StartShooting") then
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local t    = target()
            if root and t then
                local cd = CFD(root.Position, t)
                if cd then camdata = cd end
            end
        end
        return _hook(self, objID, enumVal, camdata, extra)
    end))
end)

-- ============================================================
--  HEARTBEAT LOOPS
-- ============================================================
RunService.Heartbeat:Connect(function()
    -- Speed
    if S.SpeedVelocity then
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = S.Velocity end
    end

    -- Health
    local char = LP.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum then
        if S.InfHealth then
            hum.Health = hum.MaxHealth
        elseif S.AutoHeal and hum.Health < hum.MaxHealth then
            hum.Health = math.min(hum.MaxHealth, hum.Health + 3)
        end
    end

    -- Auto Kill
    if S.AutoKill then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            if S.TeamCheck and not PassesTeamFilter(p, S.TeamCheckType) then continue end
            local h = p.Character:FindFirstChild("Humanoid")
            if h and h.Health > 0 then h.Health = 0 end
        end
    end
end)

-- ============================================================
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

    -- FOV circle
    FovCircle.Visible  = S.FovCircle
    FovCircle.Radius   = S.FovSize
    FovCircle.Position = center

    -- Hard aimbot — instant snap every frame
    if S.Aimbot and not S.AimSilent then
        local p = GetClosestPlayer()
        if p and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local dir = (head.Position - Camera.CFrame.Position).Unit
                -- Instant snap: assign CFrame directly, no tweening
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.lookAt(
                    Vector3.zero, dir, Vector3.yAxis
                )
            end
        end
    end

    -- Fly activation
    if S.Fly and not flyConn then SetFly(true) end

    -- ============================================================
    --  ESP
    -- ============================================================
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local d = DB[player]; if not d then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        local show = S.EnableESP and char and hum and hum.Health > 0 and hrp ~= nil
        if show and S.ESPTeamCheck then
            show = PassesTeamFilter(player, S.ESPTeamCheckType)
        end
        local box = show and GetBox(char) or nil
        if show then show = box ~= nil and PassesWallCheck(char) end

        local teamCol = GetTeamColor(player)
        local function RC(base)
            return (S.ESPTeamCheck and S.ESPTeamCheckType == "Team Color") and teamCol or base
        end

        -- BOX
        if show and S.ESPBox then
            local col = RC(S.ESPBoxColor); HideCorner(d)
            if S.ESPBoxType == "Corner" then
                d.Box.Visible = false; d.BoxFill.Visible = false
                DrawCornerBox(d, box, col)
            elseif S.ESPBoxType == "2D+Filled" then
                d.Box.Visible=true; d.Box.Position=Vector2.new(box.x,box.y); d.Box.Size=Vector2.new(box.w,box.h); d.Box.Color=col; d.Box.Thickness=1
                d.BoxFill.Visible=true; d.BoxFill.Position=Vector2.new(box.x,box.y); d.BoxFill.Size=Vector2.new(box.w,box.h); d.BoxFill.Color=col
            else
                d.Box.Visible=true; d.Box.Position=Vector2.new(box.x,box.y); d.Box.Size=Vector2.new(box.w,box.h); d.Box.Color=col; d.Box.Thickness=1
                d.BoxFill.Visible=false
            end
        else d.Box.Visible=false; d.BoxFill.Visible=false; HideCorner(d) end

        -- NAME
        if show and S.ESPName then
            d.Name.Visible=true; d.Name.Text=player.Name; d.Name.Color=RC(S.ESPNameColor)
            d.Name.Position = S.ESPNamePos=="Top" and Vector2.new(box.cx,box.y-15) or Vector2.new(box.cx,box.y+box.h+2)
        else d.Name.Visible=false end

        -- DISTANCE
        if show and S.ESPDistance then
            local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
            d.Distance.Visible=true; d.Distance.Text=dist.." m"; d.Distance.Color=RC(S.ESPDistanceColor)
            d.Distance.Position = S.ESPDistancePos=="Top"
                and Vector2.new(box.cx, box.y - (S.ESPName and 27 or 15))
                or  Vector2.new(box.cx, box.y + box.h + (S.ESPName and 14 or 2))
        else d.Distance.Visible=false end

        -- HEALTH BAR
        if show and S.ESPHealth and hum then
            local ratio = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
            local col = RC(S.ESPHealthColor); local pos = S.ESPHealthPos
            local isVert = (pos=="Left" or pos=="Right")
            local bw, bh, bx, by
            if isVert then
                bw=4; bh=box.h; bx=(pos=="Left") and (box.x-6) or (box.x+box.w+2); by=box.y
            else
                bw=box.w; bh=4; bx=box.x; by=(pos=="Top") and (box.y-6) or (box.y+box.h+2)
            end
            d.HealthBG.Visible=true; d.HealthBG.Position=Vector2.new(bx,by); d.HealthBG.Size=Vector2.new(bw,bh)
            d.HealthFill.Visible=true; d.HealthFill.Color=col
            if isVert then
                local fh=bh*ratio; d.HealthFill.Position=Vector2.new(bx,by+bh-fh); d.HealthFill.Size=Vector2.new(bw,fh)
            else
                d.HealthFill.Position=Vector2.new(bx,by); d.HealthFill.Size=Vector2.new(bw*ratio,bh)
            end
        else d.HealthBG.Visible=false; d.HealthFill.Visible=false end

        -- TRACER LINE
        if show and S.ESPLine then
            d.Line.Visible=true; d.Line.Color=RC(S.ESPLineColor)
            local lp=S.ESPLinePos
            d.Line.From = lp=="Top" and Vector2.new(center.X,0) or lp=="Bottom" and Vector2.new(center.X,vp.Y) or lp=="Side" and Vector2.new(0,center.Y) or center
            d.Line.To   = Vector2.new(box.cx, box.cy)
        else d.Line.Visible=false end

        -- SKELETON
        if show and S.ESPSkeleton then
            for _, sk in ipairs(d.Skeleton) do
                local pa=char:FindFirstChild(sk.a); local pb=char:FindFirstChild(sk.b)
                if pa and pb then
                    local sa,da,oa=W2S(pa.Position); local sb,db,ob=W2S(pb.Position)
                    if oa and ob and da>0 and db>0 then
                        sk.line.Visible=true; sk.line.From=sa; sk.line.To=sb
                        sk.line.Color=(S.ESPTeamCheck and S.ESPTeamCheckType=="Team Color") and teamCol or Color3.fromRGB(255,255,255)
                    else sk.line.Visible=false end
                else sk.line.Visible=false end
            end
        else for _,sk in ipairs(d.Skeleton) do sk.line.Visible=false end end
    end
end)

-- ============================================================
--  READY NOTIFICATION
-- ============================================================
Rayfield:Notify({
    Title    = "Kanha UI",
    Content  = "Loaded ✓  —  K to toggle UI",
    Duration = 4,
    Image    = "check-circle",
})
