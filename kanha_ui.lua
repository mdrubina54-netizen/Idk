--[[
    Kanha UI — Rayfield Edition
    Silent Aim: GU.GetEntitiesFromRaycast + UseItem.FireServer hooks
    Tested on: Synapse X / KRNL / Fluxus
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera

local LP   = Players.LocalPlayer
local reps = game:GetService("ReplicatedStorage")

-- ============================================================
--  GAME MODULE REQUIRES
-- ============================================================
local U  = require(reps.Modules.Utility)
local EL = require(reps.Modules.EnumLibrary)
local GU = require(reps.Modules.GameplayUtility)

local _ok, gun = pcall(require, LP.PlayerScripts.Modules.ItemTypes.Gun)
if _ok and gun and gun.IsFullyAiming then
    gun.IsFullyAiming = function() return true end
end

-- ============================================================
--  SETTINGS  (written to by Rayfield callbacks)
-- ============================================================
local S = {
    -- Main
    Aimbot          = false,
    AimSilent       = false,
    HitPart         = "Head",
    FovCircle       = false,
    FovSize         = 90,
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
--  LOAD RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"
))()

local Window = Rayfield:CreateWindow({
    Name             = "Kanha UI",
    LoadingTitle     = "Kanha UI",
    LoadingSubtitle  = "cracked by rony",
    Theme            = "Default",
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled  = false,
        FileName = "KanhaUI",
    },
})

-- ============================================================
--  MAIN TAB
-- ============================================================
local MainTab = Window:CreateTab("Main", "crosshair")

MainTab:CreateSection("Aimbot")

MainTab:CreateToggle({
    Name         = "Aimbot",
    CurrentValue = S.Aimbot,
    Flag         = "Aimbot",
    Callback     = function(v) S.Aimbot = v end,
})

MainTab:CreateToggle({
    Name         = "Aim Silent",
    CurrentValue = S.AimSilent,
    Flag         = "AimSilent",
    Callback     = function(v) S.AimSilent = v end,
})

MainTab:CreateDivider()

MainTab:CreateToggle({
    Name         = "Fov Circle",
    CurrentValue = S.FovCircle,
    Flag         = "FovCircle",
    Callback     = function(v) S.FovCircle = v end,
})

MainTab:CreateSlider({
    Name         = "Fov Size",
    Range        = {1, 360},
    Increment    = 1,
    CurrentValue = S.FovSize,
    Flag         = "FovSize",
    Callback     = function(v) S.FovSize = v end,
})

MainTab:CreateDivider()

MainTab:CreateToggle({
    Name         = "Team Check",
    CurrentValue = S.TeamCheck,
    Flag         = "TeamCheck",
    Callback     = function(v) S.TeamCheck = v end,
})

MainTab:CreateDropdown({
    Name          = "Team Check Type",
    Options       = {"Enemy Only", "Same Team", "Team Color", "All"},
    CurrentOption = S.TeamCheckType,
    Flag          = "TeamCheckType",
    Callback      = function(v) S.TeamCheckType = v end,
})

MainTab:CreateDivider()

MainTab:CreateToggle({
    Name         = "Wall Check",
    CurrentValue = S.WallCheck,
    Flag         = "WallCheck",
    Callback     = function(v) S.WallCheck = v end,
})

-- ============================================================
--  VISUAL TAB
-- ============================================================
local VisualTab = Window:CreateTab("Visual", "eye")

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name         = "Enable ESP",
    CurrentValue = S.EnableESP,
    Flag         = "EnableESP",
    Callback     = function(v) S.EnableESP = v end,
})

VisualTab:CreateToggle({
    Name         = "Team Check",
    CurrentValue = S.ESPTeamCheck,
    Flag         = "ESPTeamCheck",
    Callback     = function(v) S.ESPTeamCheck = v end,
})

VisualTab:CreateDropdown({
    Name          = "Team Check Type",
    Options       = {"Team Color", "Enemy Only", "Same Team", "All"},
    CurrentOption = S.ESPTeamCheckType,
    Flag          = "ESPTeamCheckType",
    Callback      = function(v) S.ESPTeamCheckType = v end,
})

VisualTab:CreateDivider()

-- ESP Line
VisualTab:CreateSection("Tracer")

VisualTab:CreateToggle({
    Name         = "ESP Line",
    CurrentValue = S.ESPLine,
    Flag         = "ESPLine",
    Callback     = function(v) S.ESPLine = v end,
})

VisualTab:CreateDropdown({
    Name          = "ESP Line Position",
    Options       = {"Top", "Bottom", "Side", "Center"},
    CurrentOption = S.ESPLinePos,
    Flag          = "ESPLinePos",
    Callback      = function(v) S.ESPLinePos = v end,
})

VisualTab:CreateColorPicker({
    Name     = "ESP Line Color",
    Color    = S.ESPLineColor,
    Flag     = "ESPLineColor",
    Callback = function(v) S.ESPLineColor = v end,
})

-- ESP Box
VisualTab:CreateSection("Box")

VisualTab:CreateToggle({
    Name         = "ESP Box",
    CurrentValue = S.ESPBox,
    Flag         = "ESPBox",
    Callback     = function(v) S.ESPBox = v end,
})

VisualTab:CreateDropdown({
    Name          = "ESP Box Type",
    Options       = {"2D", "Corner", "2D+Filled"},
    CurrentOption = S.ESPBoxType,
    Flag          = "ESPBoxType",
    Callback      = function(v) S.ESPBoxType = v end,
})

VisualTab:CreateColorPicker({
    Name     = "ESP Box Color",
    Color    = S.ESPBoxColor,
    Flag     = "ESPBoxColor",
    Callback = function(v) S.ESPBoxColor = v end,
})

-- ESP Health
VisualTab:CreateSection("Health")

VisualTab:CreateToggle({
    Name         = "ESP Health",
    CurrentValue = S.ESPHealth,
    Flag         = "ESPHealth",
    Callback     = function(v) S.ESPHealth = v end,
})

VisualTab:CreateDropdown({
    Name          = "Health Position",
    Options       = {"Left", "Right", "Top", "Bottom"},
    CurrentOption = S.ESPHealthPos,
    Flag          = "ESPHealthPos",
    Callback      = function(v) S.ESPHealthPos = v end,
})

VisualTab:CreateColorPicker({
    Name     = "ESP Health Color",
    Color    = S.ESPHealthColor,
    Flag     = "ESPHealthColor",
    Callback = function(v) S.ESPHealthColor = v end,
})

-- ESP Name
VisualTab:CreateSection("Name")

VisualTab:CreateToggle({
    Name         = "ESP Name",
    CurrentValue = S.ESPName,
    Flag         = "ESPName",
    Callback     = function(v) S.ESPName = v end,
})

VisualTab:CreateDropdown({
    Name          = "Name Position",
    Options       = {"Top", "Bottom"},
    CurrentOption = S.ESPNamePos,
    Flag          = "ESPNamePos",
    Callback      = function(v) S.ESPNamePos = v end,
})

VisualTab:CreateColorPicker({
    Name     = "ESP Name Color",
    Color    = S.ESPNameColor,
    Flag     = "ESPNameColor",
    Callback = function(v) S.ESPNameColor = v end,
})

-- ESP Distance
VisualTab:CreateSection("Distance")

VisualTab:CreateToggle({
    Name         = "ESP Distance",
    CurrentValue = S.ESPDistance,
    Flag         = "ESPDistance",
    Callback     = function(v) S.ESPDistance = v end,
})

VisualTab:CreateDropdown({
    Name          = "Distance Position",
    Options       = {"Top", "Bottom"},
    CurrentOption = S.ESPDistancePos,
    Flag          = "ESPDistancePos",
    Callback      = function(v) S.ESPDistancePos = v end,
})

VisualTab:CreateColorPicker({
    Name     = "ESP Distance Color",
    Color    = S.ESPDistanceColor,
    Flag     = "ESPDistanceColor",
    Callback = function(v) S.ESPDistanceColor = v end,
})

-- ESP Skeleton
VisualTab:CreateSection("Skeleton")

VisualTab:CreateToggle({
    Name         = "ESP Skeleton",
    CurrentValue = S.ESPSkeleton,
    Flag         = "ESPSkeleton",
    Callback     = function(v) S.ESPSkeleton = v end,
})

-- ============================================================
--  EXTRA TAB
-- ============================================================
local ExtraTab = Window:CreateTab("Extra", "zap")

ExtraTab:CreateSection("Movement")

ExtraTab:CreateToggle({
    Name         = "Fly",
    CurrentValue = S.Fly,
    Flag         = "Fly",
    Callback     = function(v)
        S.Fly = v
        if not v then SetFly(false) end
    end,
})

ExtraTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {1, 200},
    Increment    = 1,
    CurrentValue = S.FlySpeed,
    Flag         = "FlySpeed",
    Callback     = function(v) S.FlySpeed = v end,
})

ExtraTab:CreateDivider()

ExtraTab:CreateToggle({
    Name         = "Speed Velocity",
    CurrentValue = S.SpeedVelocity,
    Flag         = "SpeedVelocity",
    Callback     = function(v) S.SpeedVelocity = v end,
})

ExtraTab:CreateSlider({
    Name         = "Velocity",
    Range        = {1, 100},
    Increment    = 1,
    CurrentValue = S.Velocity,
    Flag         = "Velocity",
    Callback     = function(v) S.Velocity = v end,
})

ExtraTab:CreateSection("Teleport")

ExtraTab:CreateToggle({
    Name         = "TP Nearest Player",
    CurrentValue = S.TPNearestPlayer,
    Flag         = "TPNearestPlayer",
    Callback     = function(v) S.TPNearestPlayer = v end,
})

ExtraTab:CreateDropdown({
    Name          = "TP Team Check",
    Options       = {"Enemy Only", "Same Team", "Team Color", "All"},
    CurrentOption = S.TPTeamCheck,
    Flag          = "TPTeamCheck",
    Callback      = function(v) S.TPTeamCheck = v end,
})

ExtraTab:CreateSection("Misc")

ExtraTab:CreateToggle({
    Name         = "Auto Heal",
    CurrentValue = S.AutoHeal,
    Flag         = "AutoHeal",
    Callback     = function(v) S.AutoHeal = v end,
})

ExtraTab:CreateToggle({
    Name         = "Inf Health",
    CurrentValue = S.InfHealth,
    Flag         = "InfHealth",
    Callback     = function(v) S.InfHealth = v end,
})

ExtraTab:CreateToggle({
    Name         = "Auto Kill",
    CurrentValue = S.AutoKill,
    Flag         = "AutoKill",
    Callback     = function(v) S.AutoKill = v end,
})

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
    local sameTeam  = (player.Team ~= nil) and (player.Team == LP.Team) or sameColor
    if checkType == "Team Color" then return not sameColor end
    if checkType == "Same Team"  then return sameTeam      end
    if checkType == "Enemy Only" then return not sameTeam  end
    return true
end

local function PassesWallCheck(character)
    if not S.WallCheck then return true end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, Workspace.Terrain}
    local result = Workspace:Raycast(Camera.CFrame.Position,
        hrp.Position - Camera.CFrame.Position, params)
    return result and result.Instance and result.Instance:IsDescendantOf(character)
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
local function target()
    local center = Camera.ViewportSize / 2
    local bestPart, bestDist = nil, S.FovSize

    for _, entity in CollectionService:GetTagged("Entity") do
        if entity == LP.Character then continue end
        if S.TeamCheck then
            local p = Players:GetPlayerFromCharacter(entity)
            if p and not PassesTeamFilter(p, S.TeamCheckType) then continue end
        end
        local part = entity:FindFirstChild(S.HitPart, true)
        if not part or not part:IsA("BasePart") then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist = d; bestPart = part end
    end

    return bestPart
end

local function GetClosestPlayer()
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local best, bestDist = nil, S.FovSize

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local hum = p.Character:FindFirstChild("Humanoid")
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end
        if S.TeamCheck and not PassesTeamFilter(p, S.TeamCheckType) then continue end
        local ss, depth, onScreen = W2S(hrp.Position)
        if onScreen and depth > 0 then
            local d = (ss - center).Magnitude
            if d < bestDist then bestDist = d; best = p end
        end
    end

    return best
end

-- ============================================================
--  CFD
-- ============================================================
local function CFD(origin, part)
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

local function NewLine(t, c)
    local l = Drawing.new("Line")
    l.Visible = false; l.Thickness = t; l.Color = c
    return l
end

local function NewSquare(filled, tr)
    local s = Drawing.new("Square")
    s.Visible = false; s.Filled = filled or false
    if tr then s.Transparency = tr end
    return s
end

local function NewText(size, center, outline)
    local t = Drawing.new("Text")
    t.Visible = false; t.Size = size; t.Center = center; t.Outline = outline
    return t
end

local function AddPlayer(player)
    if player == LP or DB[player] then return end
    local d = {
        Box         = NewSquare(false),
        BoxFill     = NewSquare(true, 0.7),
        CornerLines = {},
        Name        = NewText(13, true, true),
        Distance    = NewText(12, true, true),
        HealthBG    = NewSquare(true),
        HealthFill  = NewSquare(true),
        Line        = NewLine(1, Color3.new(1,1,1)),
        Skeleton    = {},
    }
    d.HealthBG.Color = Color3.fromRGB(25, 25, 25)
    for i = 1, 8 do d.CornerLines[i] = NewLine(1.5, Color3.new(1,1,1)) end
    for _, pair in ipairs(SKEL_PAIRS) do
        table.insert(d.Skeleton, { line = NewLine(1, Color3.new(1,1,1)), a = pair[1], b = pair[2] })
    end
    DB[player] = d
end

local function RemovePlayer(player)
    local d = DB[player]; if not d then return end
    for _, obj in pairs({ d.Box, d.BoxFill, d.Name, d.Distance, d.HealthBG, d.HealthFill, d.Line }) do
        obj:Remove()
    end
    for _, l  in ipairs(d.CornerLines) do l:Remove() end
    for _, sk in ipairs(d.Skeleton)    do sk.line:Remove() end
    DB[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do AddPlayer(p) end
Players.PlayerAdded:Connect(function(p) task.wait(1); AddPlayer(p) end)
Players.PlayerRemoving:Connect(RemovePlayer)

local function DrawCornerBox(d, box, col)
    local x, y, w, h = box.x, box.y, box.w, box.h
    local lx, ly = w * 0.22, h * 0.22
    local corners = {
        { Vector2.new(x,   y),   Vector2.new(x+lx, y),    Vector2.new(x,   y+ly)   },
        { Vector2.new(x+w, y),   Vector2.new(x+w-lx, y),  Vector2.new(x+w, y+ly)   },
        { Vector2.new(x,   y+h), Vector2.new(x+lx, y+h),  Vector2.new(x,   y+h-ly) },
        { Vector2.new(x+w, y+h), Vector2.new(x+w-lx, y+h),Vector2.new(x+w, y+h-ly) },
    }
    local i = 1
    for _, c in ipairs(corners) do
        d.CornerLines[i].From = c[1]; d.CornerLines[i].To = c[2]; d.CornerLines[i].Color = col; d.CornerLines[i].Visible = true; i+=1
        d.CornerLines[i].From = c[1]; d.CornerLines[i].To = c[3]; d.CornerLines[i].Color = col; d.CornerLines[i].Visible = true; i+=1
    end
end

local function HideCornerBox(d)
    for _, l in ipairs(d.CornerLines) do l.Visible = false end
end

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
--  SILENT AIM HOOKS
-- ============================================================
local _GetEntitiesFromRaycast = GU.GetEntitiesFromRaycast
GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
    if S.AimSilent then
        local t = target()
        if t then
            local dist = (t.Position - origin).Magnitude
            dir = (t.Position - origin).Unit
            if dist > maxDist then maxDist = dist + 5 end
        end
    end
    return _GetEntitiesFromRaycast(self, envID, params, origin, dir, maxDist, ...)
end

local UseItem = reps.Remotes.Replication.Fighter.UseItem
local _UseItemFS
_UseItemFS = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
    if S.AimSilent and enumVal == EL:ToEnum("StartShooting") then
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local t    = target()
        if root and t then camdata = CFD(root.Position, t) end
    end
    return _UseItemFS(self, objID, enumVal, camdata, extra)
end))

-- ============================================================
--  FLY
-- ============================================================
local flyConn
function SetFly(on)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    if not on then hum.PlatformStand = false; return end
    hum.PlatformStand = true
    flyConn = RunService.RenderStepped:Connect(function()
        if not S.Fly then
            hum.PlatformStand = false
            flyConn:Disconnect(); flyConn = nil
            return
        end
        local dir = Vector3.zero
        local cf  = Camera.CFrame
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
--  SPEED / HEALTH LOOPS
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not S.SpeedVelocity then return end
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = S.Velocity end
end)

RunService.Heartbeat:Connect(function()
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChild("Humanoid"); if not hum then return end
    if S.InfHealth then
        hum.Health = hum.MaxHealth
    elseif S.AutoHeal and hum.Health < hum.MaxHealth then
        hum.Health = math.min(hum.MaxHealth, hum.Health + 3)
    end
end)

-- ============================================================
--  TP NEAREST
-- ============================================================
local tpCd = 0
local function TPNearest()
    local now = tick(); if now - tpCd < 0.5 then return end; tpCd = now
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
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

    FovCircle.Visible  = S.FovCircle
    FovCircle.Radius   = S.FovSize
    FovCircle.Position = center

    if S.Aimbot and not S.AimSilent then
        local p = GetClosestPlayer()
        if p and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,
                    Camera.CFrame.Position + (head.Position - Camera.CFrame.Position).Unit)
            end
        end
    end

    if S.TPNearestPlayer then TPNearest() end

    if S.AutoKill then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end

    if S.Fly and not flyConn then SetFly(true) end

    -- ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local d = DB[player]; if not d then continue end

        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        local show = S.EnableESP and char and hum and hum.Health > 0 and hrp
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
            local col = RC(S.ESPBoxColor); HideCornerBox(d)
            if S.ESPBoxType == "Corner" then
                d.Box.Visible = false; d.BoxFill.Visible = false
                DrawCornerBox(d, box, col)
            elseif S.ESPBoxType == "2D+Filled" then
                d.Box.Visible = true; d.Box.Position = Vector2.new(box.x,box.y); d.Box.Size = Vector2.new(box.w,box.h); d.Box.Color = col; d.Box.Thickness = 1
                d.BoxFill.Visible = true; d.BoxFill.Position = Vector2.new(box.x,box.y); d.BoxFill.Size = Vector2.new(box.w,box.h); d.BoxFill.Color = col
            else
                d.Box.Visible = true; d.Box.Position = Vector2.new(box.x,box.y); d.Box.Size = Vector2.new(box.w,box.h); d.Box.Color = col; d.Box.Thickness = 1
                d.BoxFill.Visible = false
            end
        else d.Box.Visible = false; d.BoxFill.Visible = false; HideCornerBox(d) end

        -- NAME
        if show and S.ESPName then
            d.Name.Visible = true; d.Name.Text = player.Name; d.Name.Color = RC(S.ESPNameColor)
            d.Name.Position = S.ESPNamePos == "Top" and Vector2.new(box.cx, box.y-15) or Vector2.new(box.cx, box.y+box.h+2)
        else d.Name.Visible = false end

        -- DISTANCE
        if show and S.ESPDistance then
            local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
            d.Distance.Visible = true; d.Distance.Text = dist.." m"; d.Distance.Color = RC(S.ESPDistanceColor)
            d.Distance.Position = S.ESPDistancePos == "Top"
                and Vector2.new(box.cx, box.y - (S.ESPName and 27 or 15))
                or  Vector2.new(box.cx, box.y + box.h + (S.ESPName and 14 or 2))
        else d.Distance.Visible = false end

        -- HEALTH
        if show and S.ESPHealth and hum then
            local ratio = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
            local col = RC(S.ESPHealthColor); local pos = S.ESPHealthPos
            local isVert = (pos == "Left" or pos == "Right")
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

        -- LINE
        if show and S.ESPLine then
            d.Line.Visible=true; d.Line.Color=RC(S.ESPLineColor)
            local lp=S.ESPLinePos
            d.Line.From = lp=="Top" and Vector2.new(center.X,0) or lp=="Bottom" and Vector2.new(center.X,vp.Y) or lp=="Side" and Vector2.new(0,center.Y) or center
            d.Line.To = Vector2.new(box.cx, box.cy)
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

Rayfield:Notify({
    Title   = "Kanha UI",
    Content = "Loaded. K to toggle UI.",
    Duration = 4,
    Image   = "check",
})
