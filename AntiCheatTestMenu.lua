--// Core Game Environment Hooks
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Ensure Environment Execution Validation
if not Drawing then
    error("Fatal: Your current Executor environment does not support the Drawing API!")
end

--// Framework State Memory
local Menu = {
    Visible = true,
    CurrentTab = "Aimbot",
    Position = Vector2.new(150, 150),
    Size = Vector2.new(460, 340),
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    Cache = {}
}

--// Feature Values Definition Matrix
local Settings = {
    Aimbot = {
        Enabled = false,
        TargetPart = "Head", -- "Head" or "HumanoidRootPart"
        ShowFOV = false,
        FOVRadius = 100
    },
    Visuals = {
        Enabled = false,
        Box = false,
        Line = false,
        LinePos = "Bottom", -- "Top", "Bottom", "Side"
        HealthBar = false,
        HealthBarPos = "Left", -- "Top", "Left", "Right", "Bottom"
        Name = false,
        NamePos = "Top", -- "Top", "Bottom"
        Distance = false,
        DistancePos = "Bottom" -- "Top", "Bottom"
    }
}

--// Static Interactive Boundary Map
local Hitboxes = {}

--// High Performance Garbage Collector
local function PurgeRenderCache()
    for _, item in pairs(Menu.Cache) do
        pcall(function() item:Remove() end)
    end
    Menu.Cache = {}
end

--// Base Vector Factory Setup
local function CreatePrimitive(type, properties)
    local drawObj = Drawing.new(type)
    for key, val in pairs(properties) do
        drawObj[key] = val
    end
    table.insert(Menu.Cache, drawObj)
    return drawObj
end

--// Master FOV Overlap Instance
local FOVRing = Drawing.new("Circle")
FOVRing.Color = Color3.fromRGB(0, 185, 255)
FOVRing.Thickness = 1
FOVRing.NumSides = 45
FOVRing.Filled = false
FOVRing.Visible = false

--// Interactive Click Registration Hook
local function RegisterClickZone(pos, size, callback)
    table.insert(Hitboxes, {
        MinX = pos.X,
        MinY = pos.Y,
        MaxX = pos.X + size.X,
        MaxY = pos.Y + size.Y,
        Trigger = callback
    })
end

--// Core UI Compiler Engine
local function BuildUI()
    PurgeRenderCache()
    Hitboxes = {}

    if not Menu.Visible then
        FOVRing.Visible = false
        return
    end

    -- Real-time Screen Radius FOV Calculation Tracker
    if Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV then
        FOVRing.Position = UserInputService:GetMouseLocation()
        FOVRing.Radius = Settings.Aimbot.FOVRadius
        FOVRing.Visible = true
    else
        FOVRing.Visible = false
    end

    -- Main GUI Base Frames Layout
    CreatePrimitive("Square", {Position = Menu.Position, Size = Menu.Size, Color = Color3.fromRGB(20, 20, 20), Filled = true, Thickness = 0, Visible = true})
    CreatePrimitive("Square", {Position = Menu.Position, Size = Vector2.new(Menu.Size.X, 32), Color = Color3.fromRGB(32, 32, 32), Filled = true, Thickness = 0, Visible = true})
    CreatePrimitive("Text", {Text = "Anticheat Verification Engine GUI", Position = Menu.Position + Vector2.new(12, 8), Size = 14, Color = Color3.fromRGB(255, 255, 255), Font = 2, Visible = true})

    -- Structural Action Controls [-] & [X]
    local MinimizeBtnPos = Menu.Position + Vector2.new(Menu.Size.X - 48, 6)
    CreatePrimitive("Square", {Position = MinimizeBtnPos, Size = Vector2.new(18, 18), Color = Color3.fromRGB(40, 40, 40), Filled = true, Visible = true})
    CreatePrimitive("Text", {Text = "-", Position = MinimizeBtnPos + Vector2.new(6, -1), Size = 16, Color = Color3.fromRGB(220, 220, 220), Visible = true})
    RegisterClickZone(MinimizeBtnPos, Vector2.new(18, 18), function() Menu.Visible = false end)

    local CloseBtnPos = Menu.Position + Vector2.new(Menu.Size.X - 24, 6)
    CreatePrimitive("Square", {Position = CloseBtnPos, Size = Vector2.new(18, 18), Color = Color3.fromRGB(160, 45, 45), Filled = true, Visible = true})
    CreatePrimitive("Text", {Text = "X", Position = CloseBtnPos + Vector2.new(5, 2), Size = 12, Color = Color3.fromRGB(255, 255, 255), Visible = true})
    RegisterClickZone(CloseBtnPos, Vector2.new(18, 18), function()
        PurgeRenderCache()
        FOVRing:Remove()
        Menu.Visible = false
        script:Destroy()
    end)

    -- Segmented Tabs Drawer Loop
    CreatePrimitive("Square", {Position = Menu.Position + Vector2.new(0, 32), Size = Vector2.new(115, Menu.Size.Y - 32), Color = Color3.fromRGB(26, 26, 26), Filled = true, Thickness = 0, Visible = true})
    local TabArray = {"Aimbot", "Visuals", "Settings"}
    
    for i, tabTitle in ipairs(TabArray) do
        local segmentY = Menu.Position.Y + 32 + ((i - i) * 36) + ((i - 1) * 36)
        local tabFocused = Menu.CurrentTab == tabTitle
        
        CreatePrimitive("Square", {Position = Vector2.new(Menu.Position.X, segmentY), Size = Vector2.new(115, 36), Color = tabFocused and Color3.fromRGB(36, 36, 36) or Color3.fromRGB(26, 26, 26), Filled = true, Thickness = 0, Visible = true})
        CreatePrimitive("Text", {Text = tabTitle, Position = Vector2.new(Menu.Position.X + 16, segmentY + 11), Size = 13, Color = tabFocused and Color3.fromRGB(0, 185, 255) or Color3.fromRGB(150, 150, 150), Font = 2, Visible = true})
        
        RegisterClickZone(Vector2.new(Menu.Position.X, segmentY), Vector2.new(115, 36), function()
            Menu.CurrentTab = tabTitle
        end)
    end

    -- Menu Elements Generator Context Functions
    local drawX = Menu.Position.X + 135
    local drawY = Menu.Position.Y + 50

    local function RenderToggle(title, isActive, triggerEvent)
        local anchor = Vector2.new(drawX, drawY)
        CreatePrimitive("Square", {Position = anchor, Size = Vector2.new(14, 14), Color = isActive and Color3.fromRGB(0, 185, 255) or Color3.fromRGB(55, 55, 55), Filled = true, Thickness = 0, Visible = true})
        CreatePrimitive("Text", {Text = title, Position = anchor + Vector2.new(24, 0), Size = 13, Color = Color3.fromRGB(215, 215, 215), Visible = true})
        RegisterClickZone(anchor, Vector2.new(180, 14), triggerEvent)
        drawY = drawY + 26
    end

    local function RenderSelector(title, currentVal, triggerEvent)
        local anchor = Vector2.new(drawX, drawY)
        CreatePrimitive("Square", {Position = anchor, Size = Vector2.new(170, 20), Color = Color3.fromRGB(36, 36, 36), Filled = true, Visible = true})
        CreatePrimitive("Text", {Text = title .. ": [" .. currentVal .. "]", Position = anchor + Vector2.new(8, 3), Size = 12, Color = Color3.fromRGB(255, 255, 255), Visible = true})
        RegisterClickZone(anchor, Vector2.new(170, 20), triggerEvent)
        drawY = drawY + 30
    end

    local function RenderSlider(title, val, maximum, triggerEvent)
        CreatePrimitive("Text", {Text = title .. ": " .. tostring(val), Position = Vector2.new(drawX, drawY), Size = 12, Color = Color3.fromRGB(215, 215, 215), Visible = true})
        local slideBarPos = Vector2.new(drawX, drawY + 15)
        CreatePrimitive("Square", {Position = slideBarPos, Size = Vector2.new(190, 6), Color = Color3.fromRGB(45, 45, 45), Filled = true, Visible = true})
        CreatePrimitive("Square", {Position = slideBarPos, Size = Vector2.new((val / maximum) * 190, 6), Color = Color3.fromRGB(0, 185, 255), Filled = true, Visible = true})
        RegisterClickZone(slideBarPos, Vector2.new(190, 6), triggerEvent)
        drawY = drawY + 36
    end

    -- Tab Elements Branch Handler Routing
    if Menu.CurrentTab == "Aimbot" then
        RenderToggle("Enable System Aimbot", Settings.Aimbot.Enabled, function() Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled end)
        RenderSelector("Target Hitbox Bone", Settings.Aimbot.TargetPart, function() Settings.Aimbot.TargetPart = (Settings.Aimbot.TargetPart == "Head") and "HumanoidRootPart" or "Head" end)
        RenderToggle("Render Dynamic FOV Radius", Settings.Aimbot.ShowFOV, function() Settings.Aimbot.ShowFOV = not Settings.Aimbot.ShowFOV end)
        RenderSlider("Field Of View Limit", Settings.Aimbot.FOVRadius, 350, function()
            Settings.Aimbot.FOVRadius = Settings.Aimbot.FOVRadius + 50
            if Settings.Aimbot.FOVRadius > 350 then Settings.Aimbot.FOVRadius = 50 end
        end)
    elseif Menu.CurrentTab == "Visuals" then
        RenderToggle("Master ESP State Activation", Settings.Visuals.Enabled, function() Settings.Visuals.Enabled = not Settings.Visuals.Enabled end)
        RenderToggle("2D Box Projections", Settings.Visuals.Box, function() Settings.Visuals.Box = not Settings.Visuals.Box end)
        RenderToggle("Directional Snaplines", Settings.Visuals.Line, function() Settings.Visuals.Line = not Settings.Visuals.Line end)
        RenderSelector("Snapline Anchor Target", Settings.Visuals.LinePos, function()
            local opt = {"Bottom", "Top", "Side"}
            Settings.Visuals.LinePos = opt[(table.find(opt, Settings.Visuals.LinePos) % #opt) + 1]
        end)
        RenderToggle("Health Progression Tracking", Settings.Visuals.HealthBar, function() Settings.Visuals.HealthBar = not Settings.Visuals.HealthBar end)
        RenderSelector("Health Alignment Layout", Settings.Visuals.HealthBarPos, function()
            local opt = {"Left", "Right", "Top", "Bottom"}
            Settings.Visuals.HealthBarPos = opt[(table.find(opt, Settings.Visuals.HealthBarPos) % #opt) + 1]
        end)
        RenderToggle("Draw Player Tag Names", Settings.Visuals.Name, function() Settings.Visuals.Name = not Settings.Visuals.Name end)
        RenderSelector("Name Tag Alignment Layer", Settings.Visuals.NamePos, function() Settings.Visuals.NamePos = (Settings.Visuals.NamePos == "Top") and "Bottom" or "Top" end)
        RenderToggle("Append Metric Distance", Settings.Visuals.Distance, function() Settings.Visuals.Distance = not Settings.Visuals.Distance end)
        RenderSelector("Distance Metric Axis", Settings.Visuals.DistancePos, function() Settings.Visuals.DistancePos = (Settings.Visuals.DistancePos == "Top") and "Bottom" or "Top" end)
    elseif Menu.CurrentTab == "Settings" then
        CreatePrimitive("Text", {Text = "System Interaction Hotkeys Setup:", Position = Vector2.new(drawX, drawY), Size = 13, Color = Color3.fromRGB(180, 180, 180), Visible = true})
        drawY = drawY + 22
        CreatePrimitive("Text", {Text = "- [INSERT]: Safely toggle entire interface overlay", Position = Vector2.new(drawX, drawY), Size = 12, Color = Color3.fromRGB(140, 140, 140), Visible = true})
        drawY = drawY + 18
        CreatePrimitive("Text", {Text = "- [HOLD RIGHT-CLICK]: Automatically locks camera track", Position = Vector2.new(drawX, drawY), Size = 12, Color = Color3.fromRGB(140, 140, 140), Visible = true})
    end
end

--// Core Input Event Engine Binding Hooks
UserInputService.InputBegan:Connect(function(input)
    if not Menu.Visible then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouseCoords = UserInputService:GetMouseLocation()
        
        -- Top-Header Drag Area Coordinates Check
        if mouseCoords.X >= Menu.Position.X and mouseCoords.X <= Menu.Position.X + Menu.Size.X and mouseCoords.Y >= Menu.Position.Y and mouseCoords.Y <= Menu.Position.Y + 32 then
            Menu.Dragging = true
            Menu.DragOffset = mouseCoords - Menu.Position
            return
        end

        -- Evaluate Dynamic Active Click Boundaries Map Loop
        for _, hitbox in pairs(Hitboxes) do
            if mouseCoords.X >= hitbox.MinX and mouseCoords.X <= hitbox.MaxX and mouseCoords.Y >= hitbox.MinY and mouseCoords.Y <= hitbox.MaxY then
                hitbox.Trigger()
                BuildUI()
                break
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Menu.Dragging = false
    end
end)

-- Structural Visibility Flip Bind [Insert Key]
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        Menu.Visible = not Menu.Visible
        BuildUI()
    end
end)

-- Continuous Drag Sync Step Tick Handler
RunService.RenderStepped:Connect(function()
    if Menu.Dragging and Menu.Visible then
        Menu.Position = UserInputService:GetMouseLocation() - Menu.DragOffset
        BuildUI()
    end
end)

-- Bootstrap Engine Run Setup Execution
BuildUI()


--// =======================================================
--// ENGINE MODULE: MATH CRITICAL POSITION FINDER (AIMBOT)
--// =======================================================
local function LocateNearestScreenTarget()
    local focalTarget = nil
    local shortestPixelDistance = Settings.Aimbot.ShowFOV and Settings.Aimbot.FOVRadius or math.huge
    local currentMousePoint = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local spatialPart = player.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            if spatialPart then
                local translationPoint, frameRendered = Camera:WorldToViewportPoint(spatialPart.Position)
                if frameRendered then
                    local displacementFactor = (Vector2.new(translationPoint.X, translationPoint.Y) - currentMousePoint).Magnitude
                    if displacementFactor < shortestPixelDistance then
                        shortestPixelDistance = displacementFactor
                        focalTarget = spatialPart
                    end
                end
            end
        end
    end
    return focalTarget
end

-- Camera Matrix Manipulation Hook Frame Loop
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local validPartTarget = LocateNearestScreenTarget()
        if validPartTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, validPartTarget.Position)
        end
    end
end)


--// =======================================================
--// ENGINE MODULE: FLUID HIGH PERFORMANCE ESP CACHE MANAGER
--// =======================================================
local PlayerESPMemoryCache = {}

local function WipePlayerESPMemory(targetPlayer)
    if PlayerESPMemoryCache[targetPlayer] then
        for _, renderingAsset in pairs(PlayerESPMemoryCache[targetPlayer]) do
            pcall(function() renderingAsset:Remove() end)
        end
        PlayerESPMemoryCache[targetPlayer] = nil
    end
end

Players.PlayerRemoving:Connect(WipePlayerESPMemory)

-- Continuous Projection Frame Pipeline Execution
RunService.RenderStepped:Connect(function()
    if not Settings.Visuals.Enabled then
        for registeredPlayer, _ in pairs(PlayerESPMemoryCache) do WipePlayerESPMemory(registeredPlayer) end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            if not PlayerESPMemoryCache[player] then
                PlayerESPMemoryCache[player] = {
                    OuterBox = Drawing.new("Square"),
                    TracerLine = Drawing.new("Line"),
                    HealthBarFrame = Drawing.new("Square"),
                    HealthBarActive = Drawing.new("Square"),
                    IdentityLabel = Drawing.new("Text"),
                    RangeLabel = Drawing.new("Text")
                }
            end

            local espGroup = PlayerESPMemoryCache[player]
            local trackingRoot = player.Character.HumanoidRootPart
            local targetHumanoid = player.Character.Humanoid
            local projectedPoint, isPointVisible = Camera:WorldToViewportPoint(trackingRoot.Position)

            if isPointVisible then
                -- Precise Depth View Scaling Scaling Matrices
                local zoomCompensationFactor = 1 / (projectedPoint.Z * math.tan(math.rad(Camera.FieldOfView / 2))) * 1000
                local widthDim, heightDim = 4 * zoomCompensationFactor, 5.5 * zoomCompensationFactor
                local positionX, positionY = projectedPoint.X - widthDim / 2, projectedPoint.Y - heightDim / 2

                -- 2D Bounding Box Logic Configuration
                espGroup.OuterBox.Visible = Settings.Visuals.Box
                espGroup.OuterBox.Size = Vector2.new(widthDim, heightDim)
                espGroup.OuterBox.Position = Vector2.new(positionX, positionY)
                espGroup.OuterBox.Color = Color3.fromRGB(245, 55, 55)
                espGroup.OuterBox.Thickness = 1
                espGroup.OuterBox.Filled = false

                -- Tracer Path Alignment Calculations Mapping
                espGroup.TracerLine.Visible = Settings.Visuals.Line
                espGroup.TracerLine.To = Vector2.new(projectedPoint.X, projectedPoint.Y)
                espGroup.TracerLine.Color = Color3.fromRGB(250, 215, 85)
                if Settings.Visuals.LinePos == "Bottom" then
                    espGroup.TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Settings.Visuals.LinePos == "Top" then
                    espGroup.TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                else
                    espGroup.TracerLine.From = Vector2.new(0, Camera.ViewportSize.Y / 2)
                end

                -- Linear Health Bar Multi-Orientation Calculations Array
                espGroup.HealthBarFrame.Visible = Settings.Visuals.HealthBar
                espGroup.HealthBarActive.Visible = Settings.Visuals.HealthBar
                local trackingHealthPercent = math.clamp(targetHumanoid.Health / targetHumanoid.MaxHealth, 0, 1)
                
                espGroup.HealthBarFrame.Color = Color3.fromRGB(35, 0, 0)
                espGroup.HealthBarFrame.Filled = true
                espGroup.HealthBarActive.Color = Color3.fromRGB(255, 45, 45):Lerp(Color3.fromRGB(45, 255, 115), trackingHealthPercent)
                espGroup.HealthBarActive.Filled = true

                if Settings.Visuals.HealthBarPos == "Left" then
                    espGroup.HealthBarFrame.Position = Vector2.new(positionX - 6, positionY)
                    espGroup.HealthBarFrame.Size = Vector2.new(3, heightDim)
                    espGroup.HealthBarActive.Position = Vector2.new(positionX - 6, positionY + (heightDim * (1 - trackingHealthPercent)))
                    espGroup.HealthBarActive.Size = Vector2.new(3, heightDim * trackingHealthPercent)
                elseif Settings.Visuals.HealthBarPos == "Right" then
                    espGroup.HealthBarFrame.Position = Vector2.new(positionX + widthDim + 3, positionY)
                    espGroup.HealthBarFrame.Size = Vector2.new(3, heightDim)
                    espGroup.HealthBarActive.Position = Vector2.new(positionX + widthDim + 3, positionY + (heightDim * (1 - trackingHealthPercent)))
                    espGroup.HealthBarActive.Size = Vector2.new(3, heightDim * trackingHealthPercent)
                elseif Settings.Visuals.HealthBarPos == "Top" then
                    espGroup.HealthBarFrame.Position = Vector2.new(positionX, positionY - 6)
                    espGroup.HealthBarFrame.Size = Vector2.new(widthDim, 3)
                    espGroup.HealthBarActive.Position = Vector2.new(positionX, positionY - 6)
                    espGroup.HealthBarActive.Size = Vector2.new(widthDim * trackingHealthPercent, 3)
                else
                    espGroup.HealthBarFrame.Position = Vector2.new(positionX, positi
