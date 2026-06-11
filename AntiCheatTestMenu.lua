--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Menu Configurations & States
local Menu = {
    Visible = true,
    CurrentTab = "Aimbot", -- Default Tab
    Position = Vector2.new(100, 100),
    Size = Vector2.new(500, 350),
    Dragging = false,
    DragStart = Vector2.new(0,0),
    Drawings = {}
}

--// Feature Settings (Modify defaults here)
local Settings = {
    Aimbot = {
        Enabled = false,
        TargetPart = "Head", -- "Head" or "HumanoidRootPart" (Body)
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

--// Helper Function to Create Drawing Objects
local function createDrawing(type, properties)
    local d = Drawing.new(type)
    for prop, val in pairs(properties) do
        d[prop] = val
    end
    table.insert(Menu.Drawings, d)
    return d
end

--// FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Filled = false

--// --- GUI Rendering System ---
local function RenderGUI()
    -- Clear previous frames frames to prevent ghosting
    for _, d in pairs(Menu.Drawings) do d:Remove() end
    Menu.Drawings = {}

    if not Menu.Visible then 
        FOVCircle.Visible = false
        return 
    end

    -- Update FOV Circle
    FOVCircle.Visible = Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.Aimbot.FOVRadius

    -- Main Background Frame
    local MainFrame = createDrawing("Square", {
        Position = Menu.Position,
        Size = Menu.Size,
        Color = Color3.fromRGB(25, 25, 25),
        Filled = true,
        Thickness = 0,
        Visible = true
    })

    -- Title Bar
    local TitleBar = createDrawing("Square", {
        Position = Menu.Position,
        Size = Vector2.new(Menu.Size.X, 30),
        Color = Color3.fromRGB(35, 35, 35),
        Filled = true,
        Thickness = 0,
        Visible = true
    })

    local TitleText = createDrawing("Text", {
        Text = "Anticheat Test Environment Menu",
        Position = Menu.Position + Vector2.new(10, 6),
        Size = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Font = 2,
        Visible = true
    })

    -- Close Button [X]
    local CloseBtn = createDrawing("Text", {
        Text = "X",
        Position = Menu.Position + Vector2.new(Menu.Size.X - 25, 6),
        Size = 16,
        Color = Color3.fromRGB(200, 50, 50),
        Font = 2,
        Visible = true
    })

    -- Minimize Button [-]
    local MinimizeBtn = createDrawing("Text", {
        Text = "-",
        Position = Menu.Position + Vector2.new(Menu.Size.X - 45, 4),
        Size = 20,
        Color = Color3.fromRGB(200, 200, 200),
        Font = 2,
        Visible = true
    })

    -- Sidebar (Tabs Area)
    local Sidebar = createDrawing("Square", {
        Position = Menu.Position + Vector2.new(0, 30),
        Size = Vector2.new(120, Menu.Size.Y - 30),
        Color = Color3.fromRGB(30, 30, 30),
        Filled = true,
        Thickness = 0,
        Visible = true
    })

    -- Tab Rendering Function
    local function DrawTabButton(name, yOffset)
        local isCurrent = (Menu.CurrentTab == name)
        local TabBtn = createDrawing("Square", {
            Position = Menu.Position + Vector2.new(0, 30 + yOffset),
            Size = Vector2.new(120, 35),
            Color = isCurrent and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(30, 30, 30),
            Filled = true,
            Thickness = 0,
            Visible = true
        })
        local TabTxt = createDrawing("Text", {
            Text = name,
            Position = TabBtn.Position + Vector2.new(15, 10),
            Size = 14,
            Color = isCurrent and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(150, 150, 150),
            Font = 2,
            Visible = true
        })
    end

    DrawTabButton("Aimbot", 0)
    DrawTabButton("Visuals", 35)
    DrawTabButton("Settings", 70)

    -- Content Elements Render Loop Helper
    local contentY = 45
    local function AddToggle(label, state, callback)
        local ToggleBox = createDrawing("Square", {
            Position = Menu.Position + Vector2.new(140, contentY),
            Size = Vector2.new(15, 15),
            Color = state and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(60, 60, 60),
            Filled = true,
            Visible = true
        })
        createDrawing("Text", {
            Text = label,
            Position = Menu.Position + Vector2.new(165, contentY - 1),
            Size = 14,
            Color = Color3.fromRGB(220, 220, 220),
            Visible = true
        })
        contentY = contentY + 25
    end

    local function AddSlider(label, val, max, callback)
        createDrawing("Text", {
            Text = label .. ": " .. tostring(val),
            Position = Menu.Position + Vector2.new(140, contentY),
            Size = 14,
            Color = Color3.fromRGB(220, 220, 220),
            Visible = true
        })
        local SliderBg = createDrawing("Square", {
            Position = Menu.Position + Vector2.new(140, contentY + 18),
            Size = Vector2.new(200, 6),
            Color = Color3.fromRGB(50, 50, 50),
            Filled = true,
            Visible = true
        })
        local SliderFill = createDrawing("Square", {
            Position = SliderBg.Position,
            Size = Vector2.new((val / max) * 200, 6),
            Color = Color3.fromRGB(0, 180, 255),
            Filled = true,
            Visible = true
        })
        contentY = contentY + 35
    end

    local function AddSelector(label, currentMode, callback)
        createDrawing("Text", {
            Text = label .. ": [" .. currentMode .. "]",
            Position = Menu.Position + Vector2.new(140, contentY),
            Size = 14,
            Color = Color3.fromRGB(0, 180, 255),
            Visible = true
        })
        contentY = contentY + 25
    end

    -- Render Interactive Elements Based on Selected Tab
    if Menu.CurrentTab == "Aimbot" then
        AddToggle("Enable Aimbot", Settings.Aimbot.Enabled)
        AddSelector("Target Part Mode", Settings.Aimbot.TargetPart)
        AddToggle("Show FOV Circle", Settings.Aimbot.ShowFOV)
        AddSlider("FOV Size", Settings.Aimbot.FOVRadius, 500)
        
    elseif Menu.CurrentTab == "Visuals" then
        AddToggle("Enable Master Visuals", Settings.Visuals.Enabled)
        AddToggle("Box ESP", Settings.Visuals.Box)
        AddToggle("Snapline ESP", Settings.Visuals.Line)
        AddSelector("Snapline Mode", Settings.Visuals.LinePos)
        AddToggle("Health Bar", Settings.Visuals.HealthBar)
        AddSelector("Health Bar Mode", Settings.Visuals.HealthBarPos)
        AddToggle("Player Name ESP", Settings.Visuals.Name)
        AddSelector("Name Placement", Settings.Visuals.NamePos)
        AddToggle("Distance Track", Settings.Visuals.Distance)
        AddSelector("Distance Placement", Settings.Visuals.DistancePos)
        
    elseif Menu.CurrentTab == "Settings" then
        createDrawing("Text", {
            Text = "Press [INSERT] to completely hide GUI.",
            Position = Menu.Position + Vector2.new(140, contentY),
            Size = 14,
            Color = Color3.fromRGB(150, 150, 150),
            Visible = true
        })
        contentY = contentY + 25
        createDrawing("Text", {
            Text = "Click structural texts / toggles to flip values.",
            Position = Menu.Position + Vector2.new(140, contentY),
            Size = 14,
            Color = Color3.fromRGB(150, 150, 150),
            Visible = true
        })
    end
end

--// --- Click and Drag Functionality Interceptor ---
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Menu.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        
        -- Window Closing Logic
        if mousePos.X >= Menu.Position.X + Menu.Size.X - 30 and mousePos.X <= Menu.Position.X + Menu.Size.X and mousePos.Y >= Menu.Position.Y and mousePos.Y <= Menu.Position.Y + 30 then
            Menu.Visible = false
            FOVCircle:Remove()
            for _, d in pairs(Menu.Drawings) do d:Remove() end
            script:Destroy() -- Terminates environment hook safely
            return
        end

        -- Minimize Window Logic
        if mousePos.X >= Menu.Position.X + Menu.Size.X - 50 and mousePos.X <= Menu.Position.X + Menu.Size.X - 30 and mousePos.Y >= Menu.Position.Y and mousePos.Y <= Menu.Position.Y + 30 then
            Menu.Visible = false
            return
        end

        -- Header Dragger Capture Hook
        if mousePos.X >= Menu.Position.X and mousePos.X <= Menu.Position.X + Menu.Size.X and mousePos.Y >= Menu.Position.Y and mousePos.Y <= Menu.Position.Y + 30 then
            Menu.Dragging = true
            Menu.DragStart = mousePos - Menu.Position
            return
        end

        -- Tab switching clicks
        if mousePos.X >= Menu.Position.X and mousePos.X <= Menu.Position.X + 120 then
            if mousePos.Y >= Menu.Position.Y + 30 and mousePos.Y <= Menu.Position.Y + 65 then
                Menu.CurrentTab = "Aimbot"
            elseif mousePos.Y >= Menu.Position.Y + 65 and mousePos.Y <= Menu.Position.Y + 100 then
                Menu.CurrentTab = "Visuals"
            elseif mousePos.Y >= Menu.Position.Y + 100 and mousePos.Y <= Menu.Position.Y + 135 then
                Menu.CurrentTab = "Settings"
            end
            RenderGUI()
            return
        end

        -- Menu Control Panel State Toggles Interaction Map
        if mousePos.X >= Menu.Position.X + 140 and mousePos.X <= Menu.Position.X + Menu.Size.X then
            if Menu.CurrentTab == "Aimbot" then
                if mousePos.Y >= Menu.Position.Y + 45 and mousePos.Y <= Menu.Position.Y + 65 then
                    Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
                elseif mousePos.Y >= Menu.Position.Y + 70 and mousePos.Y <= Menu.Position.Y + 90 then
                    Settings.Aimbot.TargetPart = (Settings.Aimbot.TargetPart == "Head") and "HumanoidRootPart" or "Head"
                elseif mousePos.Y >= Menu.Position.Y + 95 and mousePos.Y <= Menu.Position.Y + 115 then
                    Settings.Aimbot.ShowFOV = not Settings.Aimbot.ShowFOV
                elseif mousePos.Y >= Menu.Position.Y + 120 and mousePos.Y <= Menu.Position.Y + 150 then
                    -- Simple incremental slider click emulator
                    Settings.Aimbot.FOVRadius = Settings.Aimbot.FOVRadius + 50
                    if Settings.Aimbot.FOVRadius > 300 then Settings.Aimbot.FOVRadius = 50 end
                end
            elseif Menu.CurrentTab == "Visuals" then
                if mousePos.Y >= Menu.Position.Y + 45 and mousePos.Y <= Menu.Position.Y + 65 then
                    Settings.Visuals.Enabled = not Settings.Visuals.Enabled
                elseif mousePos.Y >= Menu.Position.Y + 70 and mousePos.Y <= Menu.Position.Y + 90 then
                    Settings.Visuals.Box = not Settings.Visuals.Box
                elseif mousePos.Y >= Menu.Position.Y + 95 and mousePos.Y <= Menu.Position.Y + 115 then
                    Settings.Visuals.Line = not Settings.Visuals.Line
                elseif mousePos.Y >= Menu.Position.Y + 120 and mousePos.Y <= Menu.Position.Y + 140 then
                    local modes = {"Bottom", "Top", "Side"}
                    local idx = table.find(modes, Settings.Visuals.LinePos) or 1
                    Settings.Visuals.LinePos = modes[(idx % #modes) + 1]
                elseif mousePos.Y >= Menu.Position.Y + 145 and mousePos.Y <= Menu.Position.Y + 165 then
                    Settings.Visuals.HealthBar = not Settings.Visuals.HealthBar
                elseif mousePos.Y >= Menu.Position.Y + 170 and mousePos.Y <= Menu.Position.Y + 190 then
                    local modes = {"Left", "Right", "Top", "Bottom"}
                    local idx = table.find(modes, Settings.Visuals.HealthBarPos) or 1
                    Settings.Visuals.HealthBarPos = modes[(idx % #modes) + 1]
                elseif mousePos.Y >= Menu.Position.Y + 195 and mousePos.Y <= Menu.Position.Y + 215 then
                    Settings.Visuals.Name = not Settings.Visuals.Name
                elseif mousePos.Y >= Menu.Position.Y + 220 and mousePos.Y <= Menu.Position.Y + 240 then
                    Settings.Visuals.NamePos = (Settings.Visuals.NamePos == "Top") and "Bottom" or "Top"
                elseif mousePos.Y >= Menu.Position.Y + 245 and mousePos.Y <= Menu.Position.Y + 265 then
                    Settings.Visuals.Distance = not Settings.Visuals.Distance
                elseif mousePos.Y >= Menu.Position.Y + 270 and mousePos.Y <= Menu.Position.Y + 290 then
                    Settings.Visuals.DistancePos = (Settings.Visuals.DistancePos == "Top") and "Bottom" or "Top"
                end
            end
            RenderGUI()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Menu.Dragging = false
    end
end)

-- Window Un-Minimize Toggle Hook
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        Menu.Visible = not Menu.Visible
        RenderGUI()
    end
end)

RunService.RenderStepped:Connect(function()
    if Menu.Dragging and Menu.Visible then
        Menu.Position = UserInputService:GetMouseLocation() - Menu.DragStart
        RenderGUI()
    end
end)

--// Initial Render Setup Initialization
RenderGUI()


--// --- CORE MECHANICS: AIMBOT WITHOUT SCOPE ---
local function GetClosestPlayerToMouse()
    local target = nil
    local maxDist = Settings.Aimbot.ShowFOV and Settings.Aimbot.FOVRadius or math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local part = player.Character:FindFirstChild(Settings.Aimbot.TargetPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        target = part
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled then
        local targetPart = GetClosestPlayerToMouse()
        if targetPart and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then -- Right Click Locks on Target
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end
end)


--// --- CORE MECHANICS: DRAWING API ESP SYSTEM ---
local ActiveESPs = {}

local function CreateESPStorage(player)
    if ActiveESPs[player] then return end
    ActiveESPs[player] = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        Health = Drawing.new("Square"),
        HealthBg = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
end

local function RemoveESPStorage(player)
    if ActiveESPs[player] then
        for _, drawObj in pairs(ActiveESPs[player]) do drawObj:Remove() end
        ActiveESPs[player] = nil
    end
end

Players.PlayerRemoving:Connect(RemoveESPStorage)

RunService.RenderStepped:Connect(function()
    if not Settings.Visuals.Enabled then
        for p, _ in pairs(ActiveESPs) do RemoveESPStorage(p) end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            CreateESPStorage(player)
            local container = ActiveESPs[player]
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character.Humanoid
            
            local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                -- Calculate dynamic sizing metrics based on camera depth projection distance
                local scaleFactor = 1 / (hrpPos.Z * math.tan(math.rad(Camera.FieldOfView / 2))) * 1000
                local width, height = 4 * scaleFactor, 6 * scaleFactor
                local x, y = hrpPos.X - width / 2, hrpPos.Y - height / 2

                -- Box ESP configuration
                container.Box.Visible = Settings.Visuals.Box
                container.Box.Size = Vector2.new(width, height)
                container.Box.Position = Vector2.new(x, y)
                container.Box.Color = Color3.fromRGB(255, 0, 0)
                container.Box.Thickness = 1
                container.Box.Filled = false

                -- Snapline ESP configuration Matrix
                container.Line.Visible = Settings.Visuals.Line
                container.Line.To = Vector2.new(hrpPos.X, hrpPos.Y)
                container.Line.Color = Color3.fromRGB(255, 255, 0)
                container.Line.Thickness = 1
                if Settings.Visuals.LinePos == "Bottom" then
                    container.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Settings.Visuals.LinePos == "Top" then
                    container.Line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                elseif Settings.Visuals.LinePos == "Side" then
                    container.Line.From = Vector2.new(0, Camera.ViewportSize.Y / 2)
                end

                -- Healthbar Render Configuration Matrix
                container.Health.Visible = Settings.Visuals.HealthBar
                container.HealthBg.Visible = Settings.Visuals.HealthBar
                local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                container.HealthBg.Color = Color3.fromRGB(50, 0, 0)
                container.HealthBg.Filled = true
                container.Health.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255,0,0), 1 - hpPct)
                container.Health.Filled = true

                if Settings.Visuals.HealthBarPos == "Left" then
                    container.HealthBg.Position = Vector2.new(x - 6, y)
                    container.HealthBg.Size = Vector2.new(4, height)
                    container.Health.Position = Vector2.new(x - 6, y + (height * (1 - hpPct)))
                    container.Health.Size = Vector2.new(4, height * hpPct)
                elseif Settings.Visuals.HealthBarPos == "Right" then
                    container.HealthBg.Position = Vector2.new(x + width + 2, y)
                    container.HealthBg.Size = Vector2.new(4, height)
                    container.Health.Position = Vector2.new(x + width + 2, y + (height * (1 - hpPct)))
                    container.Health.Size = Vector2.new(4, height * hpPct)
                elseif Settings.Visuals.HealthBarPos == "Top" then
                    container.HealthBg.Position = Vector2.new(x, y - 6)
                    container.HealthBg.Size = Vector2.new(width, 4)
                    container.Health.Position = Vector2.new(x, y - 6)
                    container.Health.Size = Vector2.new(width * hpPct, 4)
                elseif Settings.Visuals.HealthBarPos == "Bottom" then
                    container.HealthBg.Position = Vector2.new(x, y + height + 2)
                    container.HealthBg.Size = Vector2.new(width, 4)
                    container.Health.Position = Vector2.new(x, y + height + 2)
                    container.Health.Size = Vector2.new(width * hpPct, 4)
                end

                -- Text Name Display Engine Matrix
                container.Name.Visible = Settings.Visuals.Name
                container.Name.Text = player.Name
                container.Name.Size = 14
                container.Name.Center = true
                container.Name.Color = Color3.fromRGB(255, 255, 255)
                container.Name.Position = (Settings.Visuals.NamePos == "Top") and Vector2.new(hrpPos.X, y - 20) or Vector2.new(hrpPos.X, y + height + 5)

                -- Distance Calculation Tracking Matrix
                container.Distance.Visible = Settings.Visuals.Distance
                local actualDistance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0)
                container.Distance.Text = tostring(actualDistance) .. " studs"
                container.Distance.Size = 12
                container.Distance.Center = true
                container.Distance.Color = Color3.fromRGB(200, 200, 200)
                container.Distance.Position = (Settings.Visuals.DistancePos == "Bottom") and Vector2.new(hrpPos.X, y + height + (Settings.Visuals.Name.Enabled and 20 or 5)) or Vector2.new(hrpPos.X, y - 35)
            else
                -- Off-screen characters safety clamp hidden state
                for _, drawObj in pairs(container) do drawObj.Visible = false end
            end
        else
            RemoveESPStorage(player)
        end
    end
end)