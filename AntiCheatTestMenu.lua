-- MOBILE POWER-TESTING PIPELINE (FORCE HEAD SILENT AIM)
-- Features: Unfilled Vectors, Break-Lock Tracking, Drag-Drop FAB, True Head Redirect

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
-- ENGINE CORE VARIABLES
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Options = {
    Aimbot = false, AimAssist = false, SilentAim = false, FOVCircle = false, FOVRadius = 150,
    EspMaster = false, EspLines = false, LinePos = "Bottom", EspBoxes = false, BoxStyle = "Full Box", EspNames = false, 
    NamePos = "Top", EspHealth = false, HealthPos = "Left", DistancePos = "Bottom", EspSkeleton = false,
    Fly = false, FlySpeed = 50, VelocitySpeed = false, WalkSpeedValue = 16, AutoHeal = false
}

-- Center Crosshair Initialization
local FOVCircleObj = Drawing.new("Circle")
FOVCircleObj.Color = Color3.fromRGB(255, 60, 60)
FOVCircleObj.Thickness = 2
FOVCircleObj.NumSides = 64
FOVCircleObj.Filled = false
FOVCircleObj.Visible = false

local Cache = {}

-- ==========================================
-- TARGETING FRAMEWORK (WITH AUTOMATIC BREAK-LOCK)
-- ==========================================
local function GetClosestPlayer()
    local Target = nil
    local ShortestDistance = math.huge
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local targetScreenPos = Vector2.new(pos.X, pos.Y)
                    local magnitude = (targetScreenPos - ScreenCenter).Magnitude
                    
                    -- Target MUST be inside the active FOV range pool
                    if magnitude < ShortestDistance then
                        if not Options.FOVCircle or magnitude <= Options.FOVRadius then
                            ShortestDistance = magnitude
                            Target = player
                        end
                    end
                end
            end
        end
    end
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
-- ABSOLUTE HEAD-REDIRECT METAMETHOD SYSTEMS
-- ==========================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Options.SilentAim and not checkcaller() then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            
            -- Hook Method 1: Intercept standard spatial raycasts and force destination to target head
            if method == "Raycast" and self == workspace then
                local origin = args[1]
                args[2] = (head.Position - origin).Unit * 1000 -- Forces direction straight to target head
                return oldNamecall(self, unpack(args))
            end
            
            -- Hook Method 2: Forces legacy ray engines to map directly onto the head coordinates
            if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "findPartOnRayWithIgnoreList" then
                args[1] = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000)
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- Hook Method 3: Mouse position property indexing overrides
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if Options.SilentAim and not checkcaller() and self == LocalPlayer:GetMouse() then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            if index == "Hit" then
                return target.Character.Head.CFrame
            elseif index == "Target" then
                return target.Character.Head
            end
        end
    end
    return oldIndex(self, index)
end)

-- ==========================================
-- MOBILE FLOATING QUICK-TOGGLE BUTTON (FAB)
-- ==========================================
local MobileFAB = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

MobileFAB.Name = "MobileFAB_AC"
MobileFAB.Parent = CoreGui
MobileFAB.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MobileFAB
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 65, 0, 65)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "TEST\nOFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 65, 65)
ToggleButton.TextSize = 14.00

UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = ToggleButton

UIStroke.Color = Color3.fromRGB(255, 65, 65)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleButton

local dragging, dragInput, dragStart, startPos
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local ActiveTestingState = false
ToggleButton.MouseButton1Click:Connect(function()
    ActiveTestingState = not ActiveTestingState
    if ActiveTestingState then
        ToggleButton.Text = "TEST\nON"
        ToggleButton.TextColor3 = Color3.fromRGB(65, 255, 65)
        UIStroke.Color = Color3.fromRGB(65, 255, 65)
        
        Options.SilentAim = true
        Options.Fly = true
        Options.VelocitySpeed = true
    else
        ToggleButton.Text = "TEST\nOFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 65, 65)
        UIStroke.Color = Color3.fromRGB(255, 65, 65)
        
        Options.SilentAim = false
        Options.Fly = false
        Options.VelocitySpeed = false
    end
    Rayfield:Notify({Title = "Testing Suite Update", Content = "Silent Head Lock & Flight Modules Synchronized.", Duration = 2})
end)

-- ==========================================
-- TABS & TOGGLES SETUP
-- ==========================================
local CombatTab = Window:CreateTab("Combat", nil)
CombatTab:CreateToggle({ Name = "Silent Head Targeter", CurrentValue = false, Callback = function(v) Options.SilentAim = v end })
CombatTab:CreateToggle({ Name = "Camera Lock Loop", CurrentValue = false, Callback = function(v) Options.Aimbot = v end })
CombatTab:CreateToggle({ Name = "Aim Assist (Instant Snap)", CurrentValue = false, Callback = function(v) Options.AimAssist = v end })
CombatTab:CreateToggle({ Name = "Display FOV Circle", CurrentValue = false, Callback = function(v) Options.FOVCircle = v end })
CombatTab:CreateSlider({ Name = "FOV Size", Range = {50, 1000}, Increment = 10, CurrentValue = 150, Callback = function(v) Options.FOVRadius = v end })

local VisualsTab = Window:CreateTab("Visuals", nil)
VisualsTab:CreateToggle({ Name = "Master ESP", CurrentValue = false, Callback = function(v) Options.EspMaster = v end })
VisualsTab:CreateToggle({ Name = "ESP Line", CurrentValue = false, Callback = function(v) Options.EspLines = v end })
VisualsTab:CreateDropdown({ Name = "Line Origin", Options = {"Top", "Side", "Bottom"}, CurrentOption = {"Bottom"}, Callback = function(v) Options.LinePos = v[1] end })
VisualsTab:CreateToggle({ Name = "ESP Box", CurrentValue = false, Callback = function(v) Options.EspBoxes = v end })
VisualsTab:CreateDropdown({ Name = "ESP Box Selector", Options = {"Full Box", "Corner Box"}, CurrentOption = {"Full Box"}, Callback = function(v) Options.BoxStyle = v[1] end })
VisualsTab:CreateToggle({ Name = "ESP Name", CurrentValue = false, Callback = function(v) Options.EspNames = v end })
VisualsTab:CreateDropdown({ Name = "Name Origin", Options = {"Top", "Bottom"}, CurrentOption = {"Top"}, Callback = function(v) Options.NamePos = v[1] end })
VisualsTab:CreateToggle({ Name = "ESP Health Bar", CurrentValue = false, Callback = function(v) Options.EspHealth = v end })
VisualsTab:CreateDropdown({ Name = "Health Position", Options = {"Top", "Left", "Right"}, CurrentOption = {"Left"}, Callback = function(v) Options.HealthPos = v[1] end })
VisualsTab:CreateDropdown({ Name = "Distance Placement", Options = {"Top", "Bottom"}, CurrentOption = {"Bottom"}, Callback = function(v) Options.DistancePos = v[1] end })

local MovementTab = Window:CreateTab("Movement", nil)
MovementTab:CreateToggle({ Name = "Player Fly", CurrentValue = false, Callback = function(v) Options.Fly = v end })
MovementTab:CreateSlider({ Name = "Fly Speed", Range = {16, 500}, Increment = 5, CurrentValue = 50, Callback = function(v) Options.FlySpeed = v end })
MovementTab:CreateToggle({ Name = "Velocity Speed Mode", CurrentValue = false, Callback = function(v) Options.VelocitySpeed = v end })
MovementTab:CreateSlider({ Name = "Speed Value", Range = {16, 500}, Increment = 5, CurrentValue = 16, Callback = function(v) Options.WalkSpeedValue = v end })
MovementTab:CreateToggle({ Name = "Auto Heal", CurrentValue = false, Callback = function(v) Options.AutoHeal = v end })

-- ==========================================
-- MAIN SYSTEM LOOP PIPELINE
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

    -- Optional Camera tracking interpolate loop
    if Options.Aimbot or Options.AimAssist then
        local target = GetClosestPlayer()
        if target and target.Character then
            local aimTarget = target.Character:FindFirstChild("Head")
            if aimTarget then
                if Options.AimAssist then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Position)
                elseif Options.Aimbot then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimTarget.Position), 0.20)
                end
            end
        end
    end

    -- Physics Manipulations
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")

        if Options.AutoHeal and hum.Health < hum.MaxHealth and hum.Health > 0 then
            hum.Health = math.min(hum.Health + 1, hum.MaxHealth)
        end

        if Options.VelocitySpeed then
            if hum.MoveDirection.Magnitude > 0 then
                root.Velocity = hum.MoveDirection * Options.WalkSpeedValue + Vector3.new(0, root.Velocity.Y, 0)
            end
        else
            hum.WalkSpeed = Options.WalkSpeedValue
        end

        if Options.Fly then
            hum.PlatformStand = true
            root.Velocity = (hum.MoveDirection.Magnitude > 0 and hum.MoveDirection * Options.FlySpeed) or Vector3.new(0, 0, 0) + Vector3.new(0, 0.5, 0)
        else
            if hum.PlatformStand then hum.PlatformStand = false end
        end
    end

    -- Visual Rendering Engine
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Options.EspMaster and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local character = player.Character
                local rootPart = character.HumanoidRootPart
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    if not Cache[player] then
                        Cache[player] = {
                            Box = Drawing.new("Square"),
                            Line = Drawing.new("Line"),
                            Name = Drawing.new("Text"),
                            HealthBar = Drawing.new("Line"),
                            Corners = {
                                TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"),
                                TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
                                BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"),
                                BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line")
                            }
                        }
                    end
                    
                    local draw = Cache[player]
                    local scale = 1 / (pos.Z * 0.01)
                    local boxSize = Vector2.new(35 * scale, 50 * scale)
                    local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

                    -- Render Full UNFILLED Box Option
                    if Options.EspBoxes and Options.BoxStyle == "Full Box" then
                        draw.Box.Size = boxSize
                        draw.Box.Position = boxPos
                        draw.Box.Color = Color3.fromRGB(255, 255, 255)
                        draw.Box.Thickness = 1
                        draw.Box.Filled = false
                        draw.Box.Visible = true
                    else
                        draw.Box.Visible = false
                    end

                    -- Corner Boxes Logic
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
                        for _, line in pairs(c) do line.Color = Color3.fromRGB(255, 255, 255); line.Thickness = 1.5; line.Visible = true end
                    else
                        for _, line in pairs(draw.Corners) do line.Visible = false end
                    end

                    -- Line Vector Tracking
                    if Options.EspLines then
                        local startOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        if Options.LinePos == "Top" then startOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
                        elseif Options.LinePos == "Side" then startOrigin = Vector2.new(0, Camera.ViewportSize.Y / 2) end
                        draw.Line.From = startOrigin; draw.Line.To = Vector2.new(pos.X, pos.Y); draw.Line.Color = Color3.fromRGB(0, 255, 255); draw.Line.Visible = true
                    else draw.Line.Visible = false end

                    -- Text Name Overlays
                    if Options.EspNames then
                        draw.Name.Text = player.Name; draw.Name.Size = math.clamp(14 * scale, 12, 16); draw.Name.Center = true; draw.Name.Color = Color3.fromRGB(255, 255, 255); draw.Name.Visible = true
                        draw.Name.Position = Vector2.new(pos.X, Options.NamePos == "Top" and (boxPos.Y - 15) or (boxPos.Y + boxSize.Y + 5))
                    else draw.Name.Visible = false end

                    -- Health Vectors
                    if Options.EspHealth then
                        local pct = humanoid.Health / humanoid.MaxHealth
                        draw.HealthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0); draw.HealthBar.Thickness = 2
                        if Options.HealthPos == "Left" then
                            draw.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y); draw.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + (boxSize.Y * (1 - pct)))
                        elseif Options.HealthPos == "Right" then
                            draw.HealthBar.From = Vector2.new(boxPos.X + boxSize.X + 5, boxPos.Y + boxSize.Y); draw.HealthBar.To = Vector2.new(boxPos.X + boxSize.X + 5, boxPos.Y + (boxSize.Y * (1 - pct)))
                        else
                            draw.HealthBar.From = Vector2.new(boxPos.X, boxPos.Y - 5); draw.HealthBar.To = Vector2.new(boxPos.X + (boxSize.X * pct), boxPos.Y - 5)
                        end
                        draw.HealthBar.Visible = true
                    else draw.HealthBar.Visible = false end
                else ClearPlayerCache(player) end
            else ClearPlayerCache(player) end
        end
    end
end)