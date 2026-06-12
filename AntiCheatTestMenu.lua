-- MOBILE COMPLETE STRESS-TESTING SUITE (MODIFIED - CLEAN INTERFACE & STABLE LOCK)
-- Features: Sticky Non-Scoped Instant Head Lock, Skeleton ESP, Metric Distance Tracking, Health Bars

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "AC Stress Tester",
   LoadingTitle = "Mobile Engine Online",
   LoadingSubtitle = "Delta Execution Module",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- ==========================================
-- ENGINE CONFIGURATION VARIABLES
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local Options = {
    Aimbot = false, FOVCircle = false, FOVRadius = 150,
    MaxAimRangeMeters = 100,
    EspMaster = false, EspLines = false, LinePos = "Bottom", EspBoxes = false, BoxStyle = "Full Box", EspNames = false, 
    EspHealth = false, EspDistance = false, EspSkeleton = false,
    Fly = false, FlySpeed = 50, VelocitySpeed = false, WalkSpeedValue = 16
}

local Cache = {}
local STUDS_PER_METER = 28
local CurrentActiveTarget = nil -- Persistent target structure for sticky validation

-- Center Crosshair Initialization
local FOVCircleObj = Drawing.new("Circle")
FOVCircleObj.Color = Color3.fromRGB(255, 60, 60)
FOVCircleObj.Thickness = 2
FOVCircleObj.NumSides = 48
FOVCircleObj.Filled = false
FOVCircleObj.Visible = false

-- R15/R6 Rig Bones Matrix Mapping for Skeleton ESP
local SkeletonBones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    -- R6 Fallback Mapping
    {"Torso", "Head"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

-- ==========================================
-- HIGH-PERFORMANCE TARGETING POOL
-- ==========================================
local function IsValidTarget(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    local head = player.Character:FindFirstChild("Head")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    
    if not head or not root or not humanoid or humanoid.Health <= 0 then return false end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Range Tracking validation
    local distanceInMeters = (root.Position - localCharacter.HumanoidRootPart.Position).Magnitude / STUDS_PER_METER
    if distanceInMeters > Options.MaxAimRangeMeters then return false end
    
    return true
end

local function GetClosestPlayer()
    -- Maintain target locked state if target remains active and valid to prevent unlocking anomalies
    if CurrentActiveTarget and IsValidTarget(CurrentActiveTarget) then
        local head = CurrentActiveTarget.Character.Head
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local magnitude = (Vector2.new(pos.X, pos.Y) - ScreenCenter).Magnitude
        
        if not Options.FOVCircle or magnitude <= Options.FOVRadius then
            return CurrentActiveTarget
        end
    end

    local Target = nil
    local ShortestDistance = math.huge
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local head = player.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
                local targetScreenPos = Vector2.new(pos.X, pos.Y)
                local magnitude = (targetScreenPos - ScreenCenter).Magnitude
                
                if magnitude < ShortestDistance then
                    if not Options.FOVCircle or magnitude <= Options.FOVRadius then
                        ShortestDistance = magnitude
                        Target = player
                    end
                end
            end
        end
    end
    
    CurrentActiveTarget = Target
    return Target
end

local function ClearPlayerCache(player)
    if Cache[player] then
        for _, obj in pairs(Cache[player]) do
            if type(obj) == "table" then
                for _, subObj in pairs(obj) do pcall(function() subObj:Remove() end) end
            else
                pcall(function() obj:Remove() end)
            end
        end
        Cache[player] = nil
    end
end
Players.PlayerRemoving:Connect(ClearPlayerCache)

-- ==========================================
-- MAIN INTERFACE TABS (RAYFIELD)
-- ==========================================
local CombatTab = Window:CreateTab("Combat", nil)
CombatTab:CreateToggle({ Name = "Instant Head Lock (No-Scope)", CurrentValue = false, Callback = function(v) Options.Aimbot = v end })
CombatTab:CreateToggle({ Name = "Display FOV Target Field", CurrentValue = false, Callback = function(v) Options.FOVCircle = v end })
CombatTab:CreateSlider({ Name = "FOV Size (Pixels)", Range = {50, 1000}, Increment = 10, CurrentValue = 150, Callback = function(v) Options.FOVRadius = v end })
CombatTab:CreateSlider({ Name = "Max Aim Range (Meters)", Range = {5, 100}, Increment = 1, CurrentValue = 100, Callback = function(v) Options.MaxAimRangeMeters = v end })

local VisualsTab = Window:CreateTab("Visuals", nil)
VisualsTab:CreateToggle({ Name = "Master ESP Master-Switch", CurrentValue = false, Callback = function(v) Options.EspMaster = v end })
VisualsTab:CreateToggle({ Name = "ESP Bounding Boxes", CurrentValue = false, Callback = function(v) Options.EspBoxes = v end })
VisualsTab:CreateDropdown({ Name = "ESP Box Selector", Options = {"Full Box", "Corner Box"}, CurrentOption = {"Full Box"}, Callback = function(v) Options.BoxStyle = v[1] end })
VisualsTab:CreateToggle({ Name = "ESP Player Bones Skeleton", CurrentValue = false, Callback = function(v) Options.EspSkeleton = v end })
VisualsTab:CreateToggle({ Name = "ESP Health Bars", CurrentValue = false, Callback = function(v) Options.EspHealth = v end })
VisualsTab:CreateToggle({ Name = "ESP Distance Tracker", CurrentValue = false, Callback = function(v) Options.EspDistance = v end })
VisualsTab:CreateToggle({ Name = "ESP Username Labels", CurrentValue = false, Callback = function(v) Options.EspNames = v end })
VisualsTab:CreateToggle({ Name = "ESP Snap Lines", CurrentValue = false, Callback = function(v) Options.EspLines = v end })

local MovementTab = Window:CreateTab("Movement", nil)
MovementTab:CreateToggle({ Name = "Player Flight", CurrentValue = false, Callback = function(v) Options.Fly = v end })
MovementTab:CreateSlider({ Name = "Flight Vector Velocity", Range = {16, 500}, Increment = 5, CurrentValue = 50, Callback = function(v) Options.FlySpeed = v end })
MovementTab:CreateToggle({ Name = "Velocity Speed Mode", CurrentValue = false, Callback = function(v) Options.VelocitySpeed = v end })
MovementTab:CreateSlider({ Name = "Speed Value", Range = {16, 500}, Increment = 5, CurrentValue = 16, Callback = function(v) Options.WalkSpeedValue = v end })

-- ==========================================
-- CORE SYSTEM RUNTIME PIPELINE
-- ==========================================
RunService.RenderStepped:Connect(function()
    local CenterPoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if Options.FOVCircle then
        FOVCircleObj.Position = CenterPoint
        FOVCircleObj.Radius = Options.FOVRadius
        FOVCircleObj.Visible = true
    else
        FOVCircleObj.Visible = false
    end

    -- Direct Perspective Instant Lock Loop
    if Options.Aimbot then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            -- Set perspective locking cleanly avoiding tracking degradation anomalies
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        else
            CurrentActiveTarget = nil
        end
    else
        CurrentActiveTarget = nil
    end

    -- Movement Physics Processing
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")

        if Options.VelocitySpeed then
            if hum.MoveDirection.Magnitude > 0 then
                root.Velocity = hum.MoveDirection * Options.WalkSpeedValue + Vector3.new(0, root.Velocity.Y, 0)
            end
        else hum.WalkSpeed = Options.WalkSpeedValue end

        if Options.Fly then
            hum.PlatformStand = true
            root.Velocity = (hum.MoveDirection.Magnitude > 0 and hum.MoveDirection * Options.FlySpeed) or Vector3.new(0, 0, 0) + Vector3.new(0, 0.4, 0)
        else
            if hum.PlatformStand then hum.PlatformStand = false end
        end
    end

    -- Complete ESP Rendering Interface
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Options.EspMaster and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local character = player.Character
                local rootPart = character.HumanoidRootPart
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                local topPos, topOnScreen = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3.1, 0))
                local bottomPos, bottomOnScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3.4, 0))
                
                if topOnScreen and bottomOnScreen then
                    if not Cache[player] then
                        Cache[player] = {
                            Box = Drawing.new("Square"), Line = Drawing.new("Line"), Name = Drawing.new("Text"),
                            HealthBar = Drawing.new("Line"), Distance = Drawing.new("Text"), Skeleton = {},
                            Corners = {
                                TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"), TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
                                BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"), BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line")
                            }
                        }
                        for i = 1, #SkeletonBones do Cache[player].Skeleton[i] = Drawing.new("Line") end
                    end
                    
                    local draw = Cache[player]
                    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
                    local boxSize = Vector2.new(boxHeight * 0.60, boxHeight)
                    local boxPos = Vector2.new(topPos.X - boxSize.X / 2, topPos.Y)
                    
                    local distanceValueStuds = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0
                    local distanceValueMeters = math.floor(distanceValueStuds / STUDS_PER_METER)

                    -- Bounding Box Framework
                    if Options.EspBoxes and Options.BoxStyle == "Full Box" then
                        draw.Box.Size = boxSize; draw.Box.Position = boxPos; draw.Box.Color = Color3.fromRGB(255, 255, 255); draw.Box.Thickness = 1; draw.Box.Filled = false; draw.Box.Visible = true
                    else draw.Box.Visible = false end

                    -- Corner Boxes Framework
                    if Options.EspBoxes and Options.BoxStyle == "Corner Box" then
                        local cornerLength = boxSize.X / 4
                        local c = draw.Corners
                        c.TL1.From = boxPos; c.TL1.To = boxPos + Vector2.new(cornerLength, 0)
                        c.TL2.From = boxPos; c.TL2.To = boxPos + Vector2.new(0, cornerLength)
                        local tr = boxPos + Vector2.new(boxSize.X, 0)
                        c.TR1.From = tr; c.TR1.To = tr + Vector2.new(-cornerLength, 0)
                        c.TR2.From = tr; c.TR2.To = tr + Vector2.new(0, cornerLength)
                        local bl = boxPos + Vector2.new(0, boxSize.Y)
                        c.BL1.From = bl; c.BL1.To = bl + Vector2.new(cornerLength, 0)
                        c.BL2.From = bl; c.BL2.To = bl + Vector2.new(0, -cornerLength)
                        local br = boxPos + boxSize
                        c.BR1.From = br; c.BR1.To = br + Vector2.new(-cornerLength, 0)
                        c.BR2.From = br; c.BR2.To = br + Vector2.new(0, -cornerLength)
                        for _, line in pairs(c) do line.Color = Color3.fromRGB(255, 255, 255); line.Thickness = 1; line.Visible = true end
                    else for _, line in pairs(draw.Corners) do line.Visible = false end end

                    -- High-Performance Skeleton Drawing Processor
                    if Options.EspSkeleton then
                        for idx, bonePair in ipairs(SkeletonBones) do
                            local partA = character:FindFirstChild(bonePair[1])
                            local partB = character:FindFirstChild(bonePair[2])
                            local lineVec = draw.Skeleton[idx]
                            
                            if partA and partB and lineVec then
                                local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
                                local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)
                                
                                if onScreenA and onScreenB then
                                    lineVec.From = Vector2.new(posA.X, posA.Y)
                                    lineVec.To = Vector2.new(posB.X, posB.Y)
                                    lineVec.Color = Color3.fromRGB(255, 255, 255)
                                    lineVec.Thickness = 1
                                    lineVec.Visible = true
                                else lineVec.Visible = false end
                            elseif lineVec then lineVec.Visible = false end
                        end
                    else for _, lineVec in pairs(draw.Skeleton) do lineVec.Visible = false end end

                    -- Real-Time Dynamic Health Bars
                    if Options.EspHealth then
                        local pct = humanoid.Health / humanoid.MaxHealth
                        draw.HealthBar.From = Vector2.new(boxPos.X - 6, boxPos.Y + boxSize.Y)
                        draw.HealthBar.To = Vector2.new(boxPos.X - 6, boxPos.Y + (boxSize.Y * (1 - pct)))
                        draw.HealthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                        draw.HealthBar.Thickness = 2
                        draw.HealthBar.Visible = true
                    else draw.HealthBar.Visible = false end

                    -- Distance Output Tracking Labels (In Metric Meters)
                    if Options.EspDistance then
                        draw.Distance.Text = tostring(distanceValueMeters) .. " m"
                        draw.Distance.Size = 12
                        draw.Distance.Center = true
                        draw.Distance.Color = Color3.fromRGB(240, 240, 70)
                        draw.Distance.Position = Vector2.new(topPos.X, boxPos.Y + boxSize.Y + 4)
                        draw.Distance.Visible = true
                    else draw.Distance.Visible = false end

                    -- Standard Username Text Labels
                    if Options.EspNames then
                        draw.Name.Text = player.Name; draw.Name.Size = 13; draw.Name.Center = true; draw.Name.Color = Color3.fromRGB(255, 255, 255); draw.Name.Visible = true
                        draw.Name.Position = Vector2.new(topPos.X, boxPos.Y - 14)
                    else draw.Name.Visible = false end

                    -- Snap Lines Processing
                    if Options.EspLines then
                        local startOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        if Options.LinePos == "Top" then startOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
                        elseif Options.LinePos == "Side" then startOrigin = Vector2.new(0, Camera.ViewportSize.Y / 2) end
                        draw.Line.From = startOrigin; draw.Line.To = Vector2.new(topPos.X, topPos.Y + (boxSize.Y / 2)); draw.Line.Color = Color3.fromRGB(0, 255, 255); draw.Line.Visible = true
                    else draw.Line.Visible = false end
                else ClearPlayerCache(player) end
            else ClearPlayerCache(player) end
        end
    end
end)
