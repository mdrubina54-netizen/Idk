--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Menu Core Setup
local Menu = {
    Visible = true,
    CurrentTab = "Aimbot",
    Position = Vector2.new(200, 200),
    Size = Vector2.new(480, 360),
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    UIObjects = {}
}

--// Feature Settings Matrix
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
    },
    Settings = {}
}

--// Persistent Drawing Garbage Collector
local function ClearUIObjects()
    for _, obj in pairs(Menu.UIObjects) do
        pcall(function() obj:Remove() end)
    end
    Menu.UIObjects = {}
end

--// Object Factory
local function Draw(type, properties)
    local obj = Drawing.new(type)
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    table.insert(Menu.UIObjects, obj)
    return obj
end

--// Base FOV Ring
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 180, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Filled = false
FOVCircle.Visible = false

--// Interactive Coordinate Collisions Hook
local ClickZones = {}
local function AddZone(pos, size, callback)
    table.insert(ClickZones, {X1 = pos.X, Y1 = pos.Y, X2 = pos.X + size.X, Y2 = pos.Y + size.Y, Action = callback})
end

--// Main Render Function
local function CompileGUI()
    ClearUIObjects()
    ClickZones = {}

    if not Menu.Visible then
        FOVCircle.Visible = false
        return
    end

    -- Dynamic FOV Update
    if Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Settings.Aimbot.FOVRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Background Core Frame
    Draw("Square", {Position = Menu.Position, Size = Menu.Size, Color = Color3.fromRGB(20, 20, 20), Filled = true, Thickness = 0, Visible = true})
    Draw("Square", {Position = Menu.Position, Size = Vector2.new(Menu.Size.X, 35), Color = Color3.fromRGB(30, 30, 30), Filled = true, Thickness = 0, Visible = true})
    Draw("Text", {Text = "Anticheat Test Environment Matrix", Position = Menu.Position + Vector2.new(15, 10), Size = 16, Color = Color3.fromRGB(255, 255, 255), Font = 2, Visible = true})

    -- Minimize Button [-]
    local MinPos = Menu.Position + Vector2.new(Menu.Size.X - 55, 5)
    Draw("Square", {Position = MinPos, Size = Vector2.new(20, 20), Color = Color3.fromRGB(45, 45, 45), Filled = true, Visible = true})
    Draw("Text", {Text = "-", Position = MinPos + Vector2.new(6, 0), Size = 18, Color = Color3.fromRGB(255, 255, 255), Visible = true})
    AddZone(MinPos, Vector2.new(20, 20), function() Menu.Visible = false end)

    -- Close Button [X]
    local ClosePos = Menu.Position + Vector2.new(Menu.Size.X - 30, 5)
    Draw("Square", {Position = ClosePos, Size = Vector2.new(20, 20), Color = Color3.fromRGB(150, 40, 40), Filled = true, Visible = true})
    Draw("Text", {Text = "X", Position = ClosePos + Vector2.new(5, 2), Size = 14, Color = Color3.fromRGB(255, 255, 255), Visible = true})
    AddZone(ClosePos, Vector2.new(20, 20), function()
        ClearUIObjects()
        FOVCircle:Remove()
        Menu.Visible = false
        script:Destroy()
    end)

    -- Sidebar Base
    Draw("Square", {Position = Menu.Position + Vector2.new(0, 35), Size = Vector2.new(130, Menu.Size.Y - 35), Color = Color3.fromRGB(25, 25, 25), Filled = true, Thickness = 0, Visible = true})

    -- Sidebar Tabs Setup
    local Tabs = {"Aimbot", "Visuals", "Settings"}
    for idx, tabName in ipairs(Tabs) do
        local tabY = Menu.Position.Y + 35 + ((idx - 1) * 40)
        local isSelected = Menu.CurrentTab == tabName
        
        local TabBtn = Draw("Square", {Position = Vector2.new(Menu.Position.X, tabY), Size = Vector2.new(130, 40), Color = isSelected and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(25, 25, 25), Filled = true, Thickness = 0, Visible = true})
        Draw("Text", {Text = tabName, Position = Vector2.new(Menu.Position.X + 20, tabY + 12), Size = 14, Color = isSelected and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(160, 160, 160), Font = 2, Visible = true})
        
        AddZone(Vector2.new(Menu.Position.X, tabY), Vector2.new(130, 40), function()
            Menu.CurrentTab = tabName
            CompileGUI()
        end)
    end

    -- Dynamic Content Offset Configuration
    local contentX = Menu.Position.X + 150
    local contentY = Menu.Position.Y + 55

    local function ToggleElement(text, state, callback)
        local BoxPos = Vector2.new(contentX, contentY)
        Draw("Square", {Position = BoxPos, Size = Vector2.new(16, 16), Color = state and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(50, 50, 50), Filled = true, Thickness = 0, Visible = true})
        Draw("Text", {Text = text, Position = BoxPos + Vector2.new(26, 0), Size = 14, Color = Color3.fromRGB(220, 220, 220), Visible = true})
        AddZone(BoxPos, Vector2.new(200, 16), callback)
        contentY = contentY + 28
    end

    local function SelectionElement(label, current, callback)
        local SelPos = Vector2.new(contentX, contentY)
        Draw("Square", {Position = SelPos, Size = Vector2.new(180, 22), Color = Color3.fromRGB(40, 40, 40), Filled = true, Visible = true})
        Draw("Text", {Text = label .. ": " .. current, Position = SelPos + Vector2.new(8, 4), Size = 13, Color = Color3.fromRGB(255, 255, 255), Visible = true})
        AddZone(SelPos, Vector2.new(180, 22), callback)
        contentY = contentY + 32
    end

    local function SliderElement(label, val, max, callback)
        Draw("Text", {Text = label .. ": " .. tostring(val), Position = Vector2.new(contentX, contentY), Size = 13, Color = Color3.fromRGB(220, 220, 220), Visible = true})
        local SliderBg = Vector2.new(contentX, contentY + 16)
        Draw("Square", {Position = SliderBg, Size = Vector2.new(200, 8), Color = Color3.fromRGB(45, 45, 45), Filled = true, Visible = true})
        Draw("Square", {Position = SliderBg, Size = Vector2.new((val / max) * 200, 8), Color = Color3.fromRGB(0, 180, 255), Filled = true, Visible = true})
        AddZone(SliderBg, Vector2.new(200, 8), callback)
        contentY = contentY + 38
    end

    -- Tab Elements Controller
    if Menu.CurrentTab == "Aimbot" then
        ToggleElement("Enable Engine Aimbot", Settings.Aimbot.Enabled, function() Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled end)
        SelectionElement("Target Tracking Bone", Settings.Aimbot.TargetPart, function() Settings.Aimbot.TargetPart = (Settings.Aimbot.TargetPart == "Head") and "HumanoidRootPart" or "Head" end)
        ToggleElement("Show Area FOV Circle", Settings.Aimbot.ShowFOV, function() Settings.Aimbot.ShowFOV = not Settings.Aimbot.ShowFOV end)
        SliderElement("Aim FOV Limit", Settings.Aimbot.FOVRadius, 400, function()
            Settings.Aimbot.FOVRadius = Settings.Aimbot.FOVRadius + 50
            if Settings.Aimbot.FOVRadius > 400 then Settings.Aimbot.FOVRadius = 50 end
        end)
    elseif Menu.CurrentTab == "Visuals" then
        ToggleElement("Master ESP Toggle", Settings.Visuals.Enabled, function() Settings.Visuals.Enabled = not Settings.Visuals.Enabled end)
        ToggleElement("2D Box ESP Tracking", Settings.Visuals.Box, function() Settings.Visuals.Box = not Settings.Visuals.Box end)
        ToggleElement("Tracer Snaplines", Settings.Visuals.Line, function() Settings.Visuals.Line = not Settings.Visuals.Line end)
        SelectionElement("Tracer Origin Point", Settings.Visuals.LinePos, function()
            local m = {"Bottom", "Top", "Side"}
            Settings.Visuals.LinePos = m[(table.find(m, Settings.Visuals.LinePos) % #m) + 1]
        end)
        ToggleElement("Structural Health Bar", Settings.Visuals.HealthBar, function() Settings.Visuals.HealthBar = not Settings.Visuals.HealthBar end)
        SelectionElement("Health Bar Alignment", Settings.Visuals.HealthBarPos, function()
            local m = {"Left", "Right", "Top", "Bottom"}
            Settings.Visuals.HealthBarPos = m[(table.find(m, Settings.Visuals.HealthBarPos) % #m) + 1]
        end)
        ToggleElement("Display Target Name", Settings.Visuals.Name, function() Settings.Visuals.Name = not Settings.Visuals.Name end)
        SelectionElement("Name Text Array Positioning", Settings.Visuals.NamePos, function() Settings.Visuals.NamePos = (Settings.Visuals.NamePos == "Top") and "Bottom" or "Top" end)
        ToggleElement("Display Target Distance", Settings.Visuals.Distance, function() Settings.Visuals.Distance = not Settings.Visuals.Distance end)
        SelectionElement("Distance Text Layering", Settings.Visuals.DistancePos, function() Settings.Visuals.DistancePos = (Settings.Visuals.DistancePos == "Top") and "Bottom" or "Top" end)
    elseif Menu.CurrentTab == "Settings" then
        Draw("Text", {Text = "System Testing Menu Hotkeys:", Position = Vector2.new(contentX, contentY), Size = 14, Color = Color3.fromRGB(200, 200, 200), Visible = true})
        contentY = contentY + 20
        Draw("Text", {Text = "- Press [INSERT] to safely open/hide UI", Position = Vector2.new(contentX, contentY), Size = 13, Color = Color3.fromRGB(150, 150, 150), Visible = true})
        contentY = contentY + 18
        Draw("Text", {Text = "- Hold [Right-Click] to force target tracking lock", Position = Vector2.new(contentX, contentY), Size = 13, Color = Color3.fromRGB(150, 150, 150), Visible = true})
    end
end

--// UI Interactive Drag & Click Engine Input Connectors
UserInputService.InputBegan:Connect(function(input)
    if not Menu.Visible then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = UserInputService:GetMouseLocation()
        
        -- Header Drag Detection Area Bounds Check
        if mouse.X >= Menu.Position.X and mouse.X <= Menu.Position.X + Menu.Size.X and mouse.Y >= Menu.Position.Y and mouse.Y <= Menu.Position.Y + 35 then
            Menu.Dragging = true
            Menu.DragOffset = mouse - Menu.Position
            return
        end

        -- Button Interaction Zone Checks
        for _, zone in pairs(ClickZones) do
            if mouse.X >= zone.X1 and mouse.X <= zone.X2 and mouse.Y >= zone.Y1 and mouse.Y <= zone.Y2 then
                zone.Action()
                CompileGUI()
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

-- Frame Update Dragger Execution Pipeline
RunService.RenderStepped:Connect(function()
    if Menu.Dragging and Menu.Visible then
        Menu.Position = UserInputService:GetMouseLocation() - Menu.DragOffset
        CompileGUI()
    end
end)

-- Global Visibility Toggle Key (Insert)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        Menu.Visible = not Menu.Visible
        CompileGUI()
    end
end)

-- Initial Startup Compile Execution
CompileGUI()


--// ==========================================
--// CORE MECHANICS: MATHEMATICAL CALCULATIONS (AIMBOT)
--// ==========================================
local function GetClosestTargetToCrosshair()
    local nearestTarget = nil
    local shortestDist = Settings.Aimbot.ShowFOV and Settings.Aimbot.FOVRadius or math.huge
    local mouseLoc = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetBone = player.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            if targetBone then
                local vector, onScreen = Camera:WorldToViewportPoint(targetBone.Position)
                if onScreen then
                    local screenDist = (Vector2.new(vector.X, vector.Y) - mouseLoc).Magnitude
                    if screenDist < shortestDist then
                        shortestDist = screenDist
                        nearestTarget = targetBone
                    end
                end
            end
        end
    end
    return nearestTarget
end

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestTargetToCrosshair()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)


--// ==========================================
--// CORE MECHANICS: ESP CACHE RENDERING PIPELINE
--// ==========================================
local ESPCache = {}

local function ClearPlayerESP(player)
    if ESPCache[player] then
        for _, drawObj in pairs(ESPCache[player]) do
            pcall(function() drawObj:Remove() end)
        end
        ESPCache[player] = nil
    end
end

Players.PlayerRemoving:Connect(ClearPlayerESP)

RunService.RenderStepped:Connect(function()
    if not Settings.Visuals.Enabled then
        for p, _ in pairs(ESPCache) do ClearPlayerESP(p) end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            if not ESPCache[player] then
                ESPCache[player] = {
                    Box = Drawing.new("Square"),
                    Line = Drawing.new("Line"),
                    HealthBarBg = Drawing.new("Square"),
                    HealthBarFill = Drawing.new("Square"),
                    NameText = Drawing.new("Text"),
                    DistText = Drawing.new("Text")
                }
            end

            local cache = ESPCache[player]
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                -- Depth Projection Scale Adjustments
                local factor = 1 / (hrpPos.Z * math.tan(math.rad(Camera.FieldOfView / 2))) * 1000
                local w, h = 4 * factor, 5.5 * factor
                local x, y = hrpPos.X - w / 2, hrpPos.Y - h / 2

                -- Box Configurations
                cache.Box.Visible = Settings.Visuals.Box
                cache.Box.Size = Vector2.new(w, h)
                cache.Box.Position = Vector2.new(x, y)
                cache.Box.Color = Color3.fromRGB(255, 60, 60)
                cache.Box.Thickness = 1
                cache.Box.Filled = false

                -- Snapline Matrix
                cache.Line.Visible = Settings.Visuals.Line
                cache.Line.To = Vector2.new(hrpPos.X, hrpPos.Y)
                cache.Line.Color = Color3.fromRGB(255, 230, 100)
                if Settings.Visuals.LinePos == "Bottom" then
                    cache.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Settings.Visuals.LinePos == "Top" then
                    cache.Line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                else
                    cache.Line.From = Vector2.new(0, Camera.ViewportSize.Y / 2)
                end

                -- Health Matrix Calculations
                cache.HealthBarBg.Visible = Settings.Visuals.HealthBar
                cache.HealthBarFill.Visible = Settings.Visuals.HealthBar
                local rawHp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                
                cache.HealthBarBg.Color = Color3.fromRGB(40, 0, 0)
                cache.HealthBarBg.Filled = true
                cache.HealthBarFill.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 100), rawHp)
                cache.HealthBarFill.Filled = true

                if Settings.Visuals.HealthBarPos == "Left" then
                    cache.HealthBarBg.Position = Vector2.new(x - 6, y)
                    cache.HealthBarBg.Size = Vector2.new(3, h)
                    cache.HealthBarFill.Position = Vector2.new(x - 6, y + (h * (1 - rawHp)))
                    cache.HealthBarFill.Size = Vector2.new(3, h * rawHp)
                elseif Settings.Visuals.HealthBarPos == "Right" then
                    cache.HealthBarBg.Position = Vector2.new(x + w + 3, y)
                    cache.HealthBarBg.Size = Vector2.new(3, h)
                    cache.HealthBarFill.Position = Vector2.new(x + w + 3, y + (h * (1 - rawHp)))
                    cache.HealthBarFill.Size = Vector2.new(3, h * rawHp)
                elseif Settings.Visuals.HealthBarPos == "Top" then
                    cache.HealthBarBg.Position = Vector2.new(x, y - 6)
                    cache.HealthBarBg.Size = Vector2.new(w, 3)
                    cache.HealthBarFill.Position = Vector2.new(x, y - 6)
                    cache.HealthBarFill.Size = Vector2.new(w * rawHp, 3)
                else
                    cache.HealthBarBg.Position = Vector2.new(x, y + h + 3)
                    cache.HealthBarBg.Size = Vector2.new(w, 3)
                    cache.HealthBarFill.Position = Vector2.new(x, y + h + 3)
                    cache.HealthBarFill.Size = Vector2.new(w * rawHp, 3)
                end

                -- Player Text Names Engine
                cache.NameText.Visible = Settings.Visuals.Name
                cache.NameText.Text = player.Name
                cache.NameText.Size = 13
                cache.NameText.Center = true
                cache.NameText.Color = Color3.fromRGB(255, 255, 255)
                cache.NameText.Position = (Settings.Visuals.NamePos == "Top") and Vector2.new(hrpPos.X, y - 18) or Vector2.new(hrpPos.X, y + h + 6)

                -- Real-time Range Vector Tracking 
                cache.DistText.Visible = Settings.Visuals.Distance
                local distance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0)
                cache.DistText.Text = tostring(distance) .. " Studs"
                cache.DistText.Size = 11
                cache.DistText.Center = true
                cache.DistText.Color = Color3.fromRGB(180, 180, 180)
                cache.DistText.Position = (Settings.Visuals.DistancePos == "Bottom") and Vector2.new(hrpPos.X, y + h + (Settings.Visuals.Name.Enabled and 20 or 6)) or Vector2.new(hrpPos.X, y - 32)
            else
                for _, obj in pairs(cache) do obj.Visible = false end
            end
        else
            ClearPlayerESP(player)
        end
    end
end)
