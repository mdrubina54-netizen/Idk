--[[
    Kanha UI — Full Executor Script
    Drawing API + RenderStepped loop
    Silent Aim: GU.GetEntitiesFromRaycast hook + UseItem.FireServer hook
    Tested on: Synapse X / KRNL / Fluxus
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera

local LP   = Players.LocalPlayer
local reps = game:GetService("ReplicatedStorage")

-- ============================================================
--  GAME MODULE REQUIRES
-- ============================================================
local U   = require(reps.Modules.Utility)
local EL  = require(reps.Modules.EnumLibrary)
local GU  = require(reps.Modules.GameplayUtility)

-- Patch IsFullyAiming so the gun always fires as if fully aimed
local _ok, gun = pcall(require, LP.PlayerScripts.Modules.ItemTypes.Gun)
if _ok and gun and gun.IsFullyAiming then
    gun.IsFullyAiming = function() return true end
end

-- ============================================================
--  SETTINGS  (mirrors every toggle / slider / combo in the UI)
-- ============================================================
local S = {
    -- Main tab
    Aimbot          = false,
    AimSilent       = false,
    HitPart         = "Head",       -- part name searched recursively on each entity
    FovCircle       = false,
    FovSize         = 90,           -- screen-space radius used by both aimbot + silent aim
    TeamCheck       = false,
    WallCheck       = false,
    TeamCheckType   = "Enemy Only", -- "Team Color" | "Enemy Only" | "Same Team" | "All"

    -- Visual tab
    EnableESP        = true,
    ESPTeamCheck     = false,
    ESPTeamCheckType = "Enemy Only",

    ESPLine          = false,
    ESPLinePos       = "Bottom",    -- "Top" | "Bottom" | "Side" | "Center"
    ESPLineColor     = Color3.fromRGB(239, 68, 68),

    ESPBox           = false,
    ESPBoxType       = "2D",        -- "2D+Filled" | "Corner" | "2D"
    ESPBoxColor      = Color3.fromRGB(59, 130, 246),

    ESPHealth        = false,
    ESPHealthPos     = "Left",      -- "Left" | "Right" | "Top" | "Bottom"
    ESPHealthColor   = Color3.fromRGB(34, 197, 94),

    ESPName          = false,
    ESPNamePos       = "Top",       -- "Top" | "Bottom"
    ESPNameColor     = Color3.fromRGB(245, 245, 245),

    ESPDistance      = false,
    ESPDistancePos   = "Bottom",    -- "Top" | "Bottom"
    ESPDistanceColor = Color3.fromRGB(251, 191, 36),

    ESPSkeleton      = false,

    -- Extra tab
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
--  Uses CollectionService "Entity" tags — matches the game's
--  own entity system. Falls back to player FOV check for aimbot.
-- ============================================================

-- Silent-aim target: searches CollectionService-tagged entities
local function target()
    local center = Camera.ViewportSize / 2
    local bestPart, bestDist = nil, S.FovSize

    for _, entity in CollectionService:GetTagged("Entity") do
        if entity == LP.Character then continue end

        -- Optional team check against entity's owning player
        if S.TeamCheck then
            local p = Players:GetPlayerFromCharacter(entity)
            if p and not PassesTeamFilter(p, S.TeamCheckType) then continue end
        end

        local part = entity:FindFirstChild(S.HitPart, true)
        if not part or not part:IsA("BasePart") then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then
            bestDist = d
            bestPart = part
        end
    end

    return bestPart
end

-- Hard-aimbot target: searches Players (camera lock-on)
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
--  CFD — builds the encoded camera-data table the server expects
--  origin  : Vector3  (local HumanoidRootPart position)
--  part    : BasePart (target hit part)
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
--  DRAWING OBJECTS PER PLAYER
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

local function NewLine(thickness, color)
    local l = Drawing.new("Line")
    l.Visible = false; l.Thickness = thickness; l.Color = color
    return l
end

local function NewSquare(filled, transparency)
    local s = Drawing.new("Square")
    s.Visible = false; s.Filled = filled or false
    if transparency then s.Transparency = transparency end
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

local function DrawCornerBox(d, box, col, pct)
    pct = pct or 0.22
    local x, y, w, h = box.x, box.y, box.w, box.h
    local lx, ly = w * pct, h * pct
    local corners = {
        { Vector2.new(x,   y),   Vector2.new(x+lx, y),    Vector2.new(x,   y+ly)   },
        { Vector2.new(x+w, y),   Vector2.new(x+w-lx, y),  Vector2.new(x+w, y+ly)   },
        { Vector2.new(x,   y+h), Vector2.new(x+lx, y+h),  Vector2.new(x,   y+h-ly) },
        { Vector2.new(x+w, y+h), Vector2.new(x+w-lx, y+h),Vector2.new(x+w, y+h-ly) },
    }
    local i = 1
    for _, c in ipairs(corners) do
        d.CornerLines[i].From = c[1]; d.CornerLines[i].To = c[2]
        d.CornerLines[i].Color = col; d.CornerLines[i].Visible = true; i += 1
        d.CornerLines[i].From = c[1]; d.CornerLines[i].To = c[3]
        d.CornerLines[i].Color = col; d.CornerLines[i].Visible = true; i += 1
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
--  SILENT AIM — two-layer hook
--
--  Layer 1: GU.GetEntitiesFromRaycast
--    Intercepts the server-bound raycast, bends the direction
--    toward the target part and extends maxDist if needed.
--
--  Layer 2: UseItem.FireServer
--    Replaces camdata with CFD() encoding so the server
--    believes the client's camera was aimed at the target.
--
--  Both layers are gated on S.AimSilent and are independent —
--  either alone gives partial effect; together they are complete.
-- ============================================================

-- Layer 1: Raycast direction bend
local _GetEntitiesFromRaycast = GU.GetEntitiesFromRaycast
GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
    if S.AimSilent then
        local t = target()
        if t then
            local dist = (t.Position - origin).Magnitude
            dir        = (t.Position - origin).Unit
            if dist > maxDist then maxDist = dist + 5 end
        end
    end
    return _GetEntitiesFromRaycast(self, envID, params, origin, dir, maxDist, ...)
end

-- Layer 2: Camera-data override on FireServer
local UseItem = reps.Remotes.Replication.Fighter.UseItem
local _UseItemFS
_UseItemFS = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
    if S.AimSilent and enumVal == EL:ToEnum("StartShooting") then
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local t    = target()
        if root and t then
            camdata = CFD(root.Position, t)
        end
    end
    return _UseItemFS(self, objID, enumVal, camdata, extra)
end))

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
--  SPEED
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not S.SpeedVelocity then return end
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = S.Velocity end
end)

-- ============================================================
--  INF HEALTH + AUTO HEAL
-- ============================================================
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
--  TP NEAREST PLAYER
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

    -- FOV circle
    FovCircle.Visible  = S.FovCircle
    FovCircle.Radius   = S.FovSize
    FovCircle.Position = center

    -- Hard aimbot (camera lock, only when AimSilent is off)
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

    -- ============================================================
    --  ESP LOOP
    -- ============================================================
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
        local function ResolveColor(base)
            return (S.ESPTeamCheck and S.ESPTeamCheckType == "Team Color") and teamCol or base
        end

        -- BOX
        if show and S.ESPBox then
            local col   = ResolveColor(S.ESPBoxColor)
            local btype = S.ESPBoxType
            HideCornerBox(d)
            if btype == "Corner" then
                d.Box.Visible = false; d.BoxFill.Visible = false
                DrawCornerBox(d, box, col)
            elseif btype == "2D+Filled" then
                d.Box.Visible = true; d.Box.Position = Vector2.new(box.x, box.y)
                d.Box.Size = Vector2.new(box.w, box.h); d.Box.Color = col; d.Box.Thickness = 1
                d.BoxFill.Visible = true; d.BoxFill.Position = Vector2.new(box.x, box.y)
                d.BoxFill.Size = Vector2.new(box.w, box.h); d.BoxFill.Color = col
            else
                d.Box.Visible = true; d.Box.Position = Vector2.new(box.x, box.y)
                d.Box.Size = Vector2.new(box.w, box.h); d.Box.Color = col; d.Box.Thickness = 1
                d.BoxFill.Visible = false
            end
        else
            d.Box.Visible = false; d.BoxFill.Visible = false; HideCornerBox(d)
        end

        -- NAME
        if show and S.ESPName then
            d.Name.Visible  = true; d.Name.Text  = player.Name
            d.Name.Color    = ResolveColor(S.ESPNameColor)
            d.Name.Position = S.ESPNamePos == "Top"
                and Vector2.new(box.cx, box.y - 15)
                or  Vector2.new(box.cx, box.y + box.h + 2)
        else d.Name.Visible = false end

        -- DISTANCE
        if show and S.ESPDistance then
            local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
            d.Distance.Visible  = true; d.Distance.Text  = dist .. " m"
            d.Distance.Color    = ResolveColor(S.ESPDistanceColor)
            d.Distance.Position = S.ESPDistancePos == "Top"
                and Vector2.new(box.cx, box.y  - (S.ESPName and 27 or 15))
                or  Vector2.new(box.cx, box.y  + box.h + (S.ESPName and 14 or 2))
        else d.Distance.Visible = false end

        -- HEALTH BAR
        if show and S.ESPHealth and hum then
            local ratio  = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local col    = ResolveColor(S.ESPHealthColor)
            local pos    = S.ESPHealthPos
            local isVert = (pos == "Left" or pos == "Right")
            local bw, bh, bx, by
            if isVert then
                bw = 4; bh = box.h
                bx = (pos == "Left") and (box.x - 6) or (box.x + box.w + 2); by = box.y
            else
                bw = box.w; bh = 4; bx = box.x
                by = (pos == "Top") and (box.y - 6) or (box.y + box.h + 2)
            end
            d.HealthBG.Visible  = true
            d.HealthBG.Position = Vector2.new(bx, by)
            d.HealthBG.Size     = Vector2.new(bw, bh)
            d.HealthFill.Visible = true; d.HealthFill.Color = col
            if isVert then
                local fh = bh * ratio
                d.HealthFill.Position = Vector2.new(bx, by + bh - fh)
                d.HealthFill.Size     = Vector2.new(bw, fh)
            else
                d.HealthFill.Position = Vector2.new(bx, by)
                d.HealthFill.Size     = Vector2.new(bw * ratio, bh)
            end
        else
            d.HealthBG.Visible = false; d.HealthFill.Visible = false
        end

        -- TRACER LINE
        if show and S.ESPLine then
            d.Line.Visible = true; d.Line.Color = ResolveColor(S.ESPLineColor)
            local lp = S.ESPLinePos
            d.Line.From = lp == "Top"    and Vector2.new(center.X, 0)
                       or lp == "Bottom" and Vector2.new(center.X, vp.Y)
                       or lp == "Side"   and Vector2.new(0, center.Y)
                       or center
            d.Line.To = Vector2.new(box.cx, box.cy)
        else d.Line.Visible = false end

        -- SKELETON
        if show and S.ESPSkeleton then
            for _, sk in ipairs(d.Skeleton) do
                local pa = char:FindFirstChild(sk.a)
                local pb = char:FindFirstChild(sk.b)
                if pa and pb then
                    local sa, da, oa = W2S(pa.Position)
                    local sb, db, ob = W2S(pb.Position)
                    if oa and ob and da > 0 and db > 0 then
                        sk.line.Visible = true; sk.line.From = sa; sk.line.To = sb
                        sk.line.Color = (S.ESPTeamCheck and S.ESPTeamCheckType == "Team Color")
                            and teamCol or Color3.fromRGB(255, 255, 255)
                    else sk.line.Visible = false end
                else sk.line.Visible = false end
            end
        else
            for _, sk in ipairs(d.Skeleton) do sk.line.Visible = false end
        end
    end
end)

-- ============================================================
--  KEYBINDS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        S.EnableESP = not S.EnableESP
    elseif input.KeyCode == Enum.KeyCode.F then
        S.Fly = not S.Fly
        if not S.Fly then SetFly(false) end
    elseif input.KeyCode == Enum.KeyCode.G then
        S.Aimbot = not S.Aimbot
    elseif input.KeyCode == Enum.KeyCode.H then
        S.AimSilent = not S.AimSilent
    end
end)

print("[Kanha UI] Loaded.")
