-- MOBILE COMPLETE STRESS-TESTING SUITE (MODIFIED)
-- Features: Non-Scoped Instant Head Lock, Skeleton ESP, Distance Tracking, Health Bars, Floating Menu

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
local CoreGui = game:GetService("CoreGui")

local Options = {
    Aimbot = false, FOVCircle = false, FOVRadius = 150,
    EspMaster = false, EspLines = false, LinePos = "Bottom", EspBoxes = false, BoxStyle = "Full Box", EspNames = false, 
    EspHealth = false, EspDistance = false, EspSkeleton = false,
    Fly = false, FlySpeed = 50, VelocitySpeed = false, WalkSpeedValue = 16
}

local Cache = {}

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
local function GetClosestPlayer()
    local Target = nil
    local ShortestDistance = math.huge
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
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
-- MOBILE FLOATING MENU TAB (DRAGGABLE)
-- ==========================================
local MobileUI = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TabTitle = Instance.new("TextLabel")
local ButtonContainer = Instance.new("ScrollingFrame")
local UIGridLayout = Instance.new("UIGridLayout")
local UICornerMain = Instance.new("UICorner")

MobileUI.Name = "MobileFloatingTab_AC"
MobileUI.Parent = CoreGui
MobileUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = MobileUI
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 200) -- Cleaned height scaling for remaining items
MainFrame.Active = true
MainFrame.BorderSizePixel = 0

UICornerMain.CornerRadius = UDim.new(0, 12)
UICornerMain.Parent = MainFrame

TabTitle.Name = "TabTitle"
TabTitle.Parent = MainFrame
TabTitle.BackgroundTransparency = 1
TabTitle.Size = UDim2.new(1, 0, 0, 35)
TabTitle.Font = Enum.Font.SourceSansBold
TabTitle.Text = "QUICK TOGGLES"
TabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TabTitle.TextSize = 15

ButtonContainer.Name = "ButtonContainer"
ButtonContainer.Parent = MainFrame
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Position = UDim2.new(0, 10, 0, 40)
ButtonContainer.Size = UDim2.new(1, -20, 1, -50)
ButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 260)
ButtonContainer.ScrollBarThickness = 2

UIGridLayout.Parent = ButtonContainer
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.CellPadding = UDim2.new(0, 0, 0, 8)
UIGridLayout.CellSize = UDim2.new(1, 0, 0, 36)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function CreateQuickToggle(name, configKey)
    local btn = Instance.new("TextButton")
    local corner = Instance.new("UICorner")
    local stroke = Instance.new("UIStroke")
    
    btn.Parent = ButtonContainer
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(240, 70, 70)
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(240, 70, 70)
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Options[configKey] = not Options[configKey]
        if Options[configKey] then
            btn.Text = name .. ": ON"
            btn.TextColor3 = Color3.fromRGB(70, 240, 70)
            stroke.Color = Color3.fromRGB(70, 240, 70)
        else
            btn.Text = name .. ": OFF"
            btn.TextColor3 = Color3.fromRGB(240, 70, 70)
            stroke.Color = Color3.fromRGB(240, 70, 70)
        end
    end)
end

CreateQuickToggle("Instant Head Lock", "Aimbot")
CreateQuickToggle("Master ESP Engine", "EspMaster")
CreateQuickToggle("Skeleton Vector ESP", "EspSkeleton")
CreateQuickToggle("Flight Hack Engine", "Fly")

-- ==========================================
-- MAIN INTERFACE TABS (RAYFIELD)
-- ==========================================
local CombatTab = Window:CreateTab("Combat", nil)
CombatTab:CreateToggle({ Name = "Instant Head Lock (No-Scope)", CurrentValue = false, Callback = function(v) Options.Aimbot = v end })
CombatTab:CreateToggle({ Name = "Display FOV Target Field", CurrentValue = false, Callback = function(v) Options.FOVCircle = v end })
CombatTab:CreateSlider({ Name = "FOV Size", Range = {50, 1000}, Increment = 10, CurrentValue = 150, Callback = function(v) Options.FOVRadius = v end })

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

    -- Direct Perspective Instant Lock Loop (Bypasses Scopes & Interpolations)
    if Options.Aimbot then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
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
                    local distanceValue = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0)

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

                    -- Distance Output Tracking Labels (In Studs)
                    if Options.EspDistance then
                        draw.Distance.Text = tostring(distanceValue) .. " studs"
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