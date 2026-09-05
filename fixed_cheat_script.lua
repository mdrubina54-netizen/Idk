-- Safe Cheat Script with Error Handling
pcall(function()

getgenv().MenuOpen = true
getgenv().MenuPosition = UDim2.new(0, 20, 0, 20)

local phem1_plrs = game:GetService("Players")
local phem2_cs = game:GetService("CollectionService")
local phem_RunService = game:GetService("RunService")

local phem6 = phem1_plrs.LocalPlayer
local phem_PlayerGui = phem6:WaitForChild("PlayerGui")

-- Safe require for utility
local phem7, phem8 = nil, nil
pcall(function()
    local phem5 = game:GetService("ReplicatedStorage")
    phem7 = require(phem5.Modules.Utility)
    phem8 = phem7.Raycast
end)

if not phem8 then
    phem8 = function() return nil end
end

-- Initialize Config
if not getgenv().Config then
    getgenv().Config = {
        HitPart = "Head",
        LockTargetPart = "Head",
        AimSilentPart = "Head",
        BodyHitChance = 50,
        FOVRadius = 300,
        ShowFOV = true,
        ShowTracer = true,
        MagnetPull = false,
        MagnetLite = false,
        PullSpeed = 50,
        TargetTeammates = false,
        AutoFire = false,
        Aimbot = false,
        Aimlock = false,
        SilentAim = false,
        TeamCheck = true,
        TeamCheckType = "Exclude Team",
        Wallcheck = true,
        KatanaCheck = false,
        ESP = false,
        ESPLine = false,
        ESPLineColor = Color3.fromRGB(0, 255, 0),
        ESPLinePos = "Side",
        ESPBox = false,
        ESPBoxColor = Color3.fromRGB(255, 255, 0),
        ESPBoxType = "Corner",
        ESPHealthBar = false,
        ESPHealthColor = Color3.fromRGB(0, 255, 0),
        ESPHealthPos = "Left",
        ESPName = false,
        ESPNameColor = Color3.fromRGB(255, 255, 255),
        ESPNamePos = "Top",
        ESPDistance = false,
        ESPDistanceColor = Color3.fromRGB(200, 200, 200),
        ESPDistancePos = "Bottom",
        ESPSkeleton = false,
        ESPSkeletonColor = Color3.fromRGB(100, 150, 255),
        TeleportNearest = false,
        Fly = false,
        FlySpeed = 50,
        Velocity = false,
        VelocitySpeed = 50,
        NoClip = false
    }
end

local phem_cached_target = nil
local phem_last_target_time = 0
local phem_cache_duration = 0.05

-- FOV Circle
local phem4 = nil
pcall(function()
    phem4 = Drawing.new("Circle")
    phem4.Visible = false
    phem4.Radius = getgenv().Config.FOVRadius
    phem4.Color = Color3.fromRGB(255, 255, 255)
    phem4.Thickness = 1
    phem4.Filled = false
end)

-- Tracer Line
local phem_tracer = nil
pcall(function()
    phem_tracer = Drawing.new("Line")
    phem_tracer.Visible = false
    phem_tracer.Color = Color3.fromRGB(0, 255, 0)
    phem_tracer.Thickness = 2
end)

-- Wallcheck function
local function phem_wallcheck(phem_target)
    if not getgenv().Config.Wallcheck or not phem_target then return true end
    
    pcall(function()
        local phem_camera = workspace.CurrentCamera
        local phem_rayOrigin = phem_camera.CFrame.Position
        local phem_rayDirection = (phem_target.Position - phem_rayOrigin).Unit
        local phem_rayDistance = (phem_target.Position - phem_rayOrigin).Magnitude
        
        local phem_rayParams = RaycastParams.new()
        phem_rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        phem_rayParams.FilterDescendantsInstances = {phem6.Character}
        
        local phem_rayResult = workspace:Raycast(phem_rayOrigin, phem_rayDirection * phem_rayDistance, phem_rayParams)
        
        if not phem_rayResult then return true end
        return phem_rayResult.Instance:IsDescendantOf(phem_target.Parent)
    end)
    
    return true
end

-- Get target function
function phem9()
    if phem_cached_target and (tick() - phem_last_target_time) < phem_cache_duration then
        return phem_cached_target
    end
    
    pcall(function()
        local phem10 = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
        local phem11 = nil
        local phem12 = getgenv().Config.FOVRadius
        
        for phem13, phem14 in pairs(phem2_cs:GetTagged("Entity")) do
            if phem14 == phem6.Character then continue end
            
            local phem_targetPlayer = phem1_plrs:FindFirstChild(phem14.Name)
            if getgenv().Config.TeamCheck and phem_targetPlayer then
                local phem_myTeam = phem6.Team
                if phem_myTeam then
                    if getgenv().Config.TeamCheckType == "Exclude Team" and phem_targetPlayer.Team == phem_myTeam then
                        continue
                    elseif getgenv().Config.TeamCheckType == "Only Team" and phem_targetPlayer.Team ~= phem_myTeam then
                        continue
                    end
                end
            end
            
            local phem15 = phem14:FindFirstChild(getgenv().Config.HitPart, true)
            if not phem15 or not phem15:IsA("BasePart") then continue end
            
            local phem16, phem17 = workspace.CurrentCamera:WorldToViewportPoint(phem15.Position)
            if not phem17 then continue end
            
            if not phem_wallcheck(phem15) then continue end
            
            local phem18 = (phem10 - Vector2.new(phem16.X, phem16.Y)).Magnitude
            if phem18 < phem12 then
                phem12 = phem18
                phem11 = phem15
            end
        end
        
        phem_cached_target = phem11
        phem_last_target_time = tick()
    end)
    
    return phem_cached_target
end

-- RenderStepped for visuals and aimlock
phem_RunService.RenderStepped:Connect(function()
    pcall(function()
        if not getgenv().Config.Aimbot then return end
        
        if phem4 then
            phem4.Position = workspace.CurrentCamera.ViewportSize / 2
            phem4.Radius = getgenv().Config.FOVRadius
            phem4.Visible = getgenv().Config.ShowFOV
        end
        
        local phem_target = phem9()
        
        if phem_tracer and phem_target and getgenv().Config.ShowTracer then
            local phem_screenPos = workspace.CurrentCamera:WorldToViewportPoint(phem_target.Position)
            if phem_screenPos then
                local phem_screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                phem_tracer.From = phem_screenCenter
                phem_tracer.To = Vector2.new(phem_screenPos.X, phem_screenPos.Y)
                phem_tracer.Visible = true
            end
        elseif phem_tracer then
            phem_tracer.Visible = false
        end
        
        -- AIMLOCK
        if phem_target and getgenv().Config.Aimlock then
            local phem_lockPart = phem_target.Parent:FindFirstChild(getgenv().Config.LockTargetPart, true)
            if phem_lockPart then
                local phem_camera = workspace.CurrentCamera
                local phem_targetPos = phem_lockPart.Position
                local phem_cameraPos = phem_camera.CFrame.Position
                phem_camera.CFrame = CFrame.new(phem_cameraPos, phem_targetPos)
            end
        end
        
        -- MAGNET PULL
        if phem_target and getgenv().Config.MagnetPull then
            local phem_targetChar = phem_target.Parent
            if phem_targetChar and phem_targetChar:FindFirstChild("HumanoidRootPart") then
                local phem_root = phem_targetChar.HumanoidRootPart
                local phem_camera = workspace.CurrentCamera
                local phem_cameraPos = phem_camera.CFrame.Position
                local phem_cameraDir = phem_camera.CFrame.LookVector
                
                if getgenv().Config.MagnetLite then
                    local phem_screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                    local phem_targetScreen = workspace.CurrentCamera:WorldToViewportPoint(phem_root.Position)
                    
                    if phem_targetScreen then
                        local phem_screenDiff = phem_screenCenter - Vector2.new(phem_targetScreen.X, phem_targetScreen.Y)
                        local phem_screenDistance = phem_screenDiff.Magnitude
                        
                        if phem_screenDistance > 5 then
                            local phem_screenNorm = phem_screenDiff.Unit
                            local phem_right = phem_camera.CFrame.RightVector
                            local phem_up = phem_camera.CFrame.UpVector
                            local phem_pullDir = (phem_screenNorm.X * phem_right + phem_screenNorm.Y * phem_up).Unit
                            local phem_pullVel = phem_pullDir * getgenv().Config.PullSpeed
                            phem_root.AssemblyLinearVelocity = phem_pullVel
                        end
                    end
                else
                    local phem_pullDirection = (phem_cameraPos + (phem_cameraDir * 100) - phem_root.Position).Unit
                    local phem_pullVelocity = phem_pullDirection * getgenv().Config.PullSpeed
                    phem_root.AssemblyLinearVelocity = phem_pullVelocity
                end
            end
        end
    end)
end)

-- SILENT AIM - Override Raycast
if phem7 and phem7.Raycast then
    local phem_originalRaycast = phem7.Raycast
    
    phem7.Raycast = function(self, phem19, phem20, phem21, phem22, phem23, phem24)
        return pcall(function()
            if not getgenv().Config.Aimbot or not getgenv().Config.SilentAim then
                return phem_originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
            end
            
            if type(phem21) ~= "number" or phem21 < 100 then
                return phem_originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
            end
            
            local phem25 = phem9()
            if not phem25 then
                return phem_originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
            end
            
            local phem_silentTarget = phem25.Parent:FindFirstChild(getgenv().Config.AimSilentPart, true)
            if not phem_silentTarget then
                return phem_originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
            end
            
            local phem_bodyHit = phem_silentTarget
            if getgenv().Config.BodyHitChance < 100 and math.random(1, 100) > getgenv().Config.BodyHitChance then
                local phem_bodyParts = {}
                for _, part in pairs(phem_silentTarget.Parent:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= phem_silentTarget then
                        table.insert(phem_bodyParts, part)
                    end
                end
                if #phem_bodyParts > 0 then
                    phem_bodyHit = phem_bodyParts[math.random(1, #phem_bodyParts)]
                end
            end
            
            local phem26 = phem_bodyHit.Position
            local phem27 = (phem26 - phem19).Unit
            local phem28 = (phem26 - phem19).Magnitude
            
            if phem28 > phem21 then
                phem28 = phem21
                phem26 = phem19 + (phem27 * phem21)
            end
            
            return {
                Position = phem26,
                Distance = phem28,
                Instance = phem_bodyHit,
                Material = phem_bodyHit.Material,
                Normal = -phem27
            }
        end) or phem_originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
end

-- AUTO FIRE
local phem_lastFire = 0
local phem_fireRate = 0.1

phem_RunService.Heartbeat:Connect(function()
    pcall(function()
        if not getgenv().Config.Aimbot or not getgenv().Config.AutoFire then return end
        
        if (tick() - phem_lastFire) > phem_fireRate then
            local phem_target = phem9()
            if phem_target then
                local phem5 = game:GetService("ReplicatedStorage")
                local phem_fireRemote = phem5:FindFirstChild("Fire")
                local phem_shootRemote = phem5:FindFirstChild("Shoot")
                
                if phem_fireRemote then pcall(function() phem_fireRemote:FireServer() end) end
                if phem_shootRemote then pcall(function() phem_shootRemote:FireServer() end) end
                
                phem_lastFire = tick()
            end
        end
    end)
end)

-- GUI MENU
local phem_MainGui = Instance.new("ScreenGui")
phem_MainGui.Name = "CheatMenu"
phem_MainGui.ResetOnSpawn = false
phem_MainGui.Parent = phem_PlayerGui

local phem_MainFrame = Instance.new("Frame")
phem_MainFrame.Name = "MainFrame"
phem_MainFrame.Size = UDim2.new(0, 450, 0, 600)
phem_MainFrame.Position = getgenv().MenuPosition
phem_MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
phem_MainFrame.BorderSizePixel = 0
phem_MainFrame.Parent = phem_MainGui
phem_MainFrame.Draggable = true

-- Title Bar
local phem_TitleBar = Instance.new("Frame")
phem_TitleBar.Name = "TitleBar"
phem_TitleBar.Size = UDim2.new(1, 0, 0, 40)
phem_TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
phem_TitleBar.BorderSizePixel = 0
phem_TitleBar.Parent = phem_MainFrame

local phem_Title = Instance.new("TextLabel")
phem_Title.Text = "⚔ CHEAT MENU"
phem_Title.TextSize = 16
phem_Title.TextColor3 = Color3.fromRGB(0, 255, 100)
phem_Title.BackgroundTransparency = 1
phem_Title.Size = UDim2.new(1, -40, 1, 0)
phem_Title.Parent = phem_TitleBar

local phem_CloseBtn = Instance.new("TextButton")
phem_CloseBtn.Text = "X"
phem_CloseBtn.Size = UDim2.new(0, 40, 1, 0)
phem_CloseBtn.Position = UDim2.new(1, -40, 0, 0)
phem_CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
phem_CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
phem_CloseBtn.BorderSizePixel = 0
phem_CloseBtn.Parent = phem_TitleBar
phem_CloseBtn.MouseButton1Click:Connect(function()
    phem_MainFrame.Visible = not phem_MainFrame.Visible
end)

-- Tab Container
local phem_TabContainer = Instance.new("Frame")
phem_TabContainer.Name = "TabContainer"
phem_TabContainer.Size = UDim2.new(1, 0, 0, 35)
phem_TabContainer.Position = UDim2.new(0, 0, 0, 40)
phem_TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
phem_TabContainer.BorderSizePixel = 0
phem_TabContainer.Parent = phem_MainFrame

local phem_CurrentTab = "Aimbot"

local function phem_CreateTabButton(tabName, position)
    local btn = Instance.new("TextButton")
    btn.Text = tabName
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.Position = UDim2.new(0, position, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = phem_TabContainer
    
    btn.MouseButton1Click:Connect(function()
        phem_CurrentTab = tabName
        phem_UpdateTabContent()
        for _, child in pairs(phem_TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                if child.Text == tabName then
                    child.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
                else
                    child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                end
            end
        end
    end)
    return btn
end

phem_CreateTabButton("Aimbot", 0)
phem_CreateTabButton("Visual", 110)
phem_CreateTabButton("Extra", 220)

-- Content Frame
local phem_ContentFrame = Instance.new("ScrollingFrame")
phem_ContentFrame.Name = "ContentFrame"
phem_ContentFrame.Size = UDim2.new(1, 0, 1, -75)
phem_ContentFrame.Position = UDim2.new(0, 0, 0, 75)
phem_ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
phem_ContentFrame.BorderSizePixel = 0
phem_ContentFrame.ScrollBarThickness = 8
phem_ContentFrame.Parent = phem_MainFrame

local phem_UIListLayout = Instance.new("UIListLayout")
phem_UIListLayout.Padding = UDim.new(0, 8)
phem_UIListLayout.Parent = phem_ContentFrame

-- Helper Functions
local function phem_CreateToggle(parent, name, configKey)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 25)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(0, 280, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Text = if getgenv().Config[configKey] then "ON" else "OFF"
    toggle.Size = UDim2.new(0, 80, 1, 0)
    toggle.Position = UDim2.new(1, -80, 0, 0)
    toggle.BackgroundColor3 = if getgenv().Config[configKey] then Color3.fromRGB(0, 150, 100) else Color3.fromRGB(100, 100, 100)
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 11
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    
    toggle.MouseButton1Click:Connect(function()
        getgenv().Config[configKey] = not getgenv().Config[configKey]
        toggle.Text = if getgenv().Config[configKey] then "ON" else "OFF"
        toggle.BackgroundColor3 = if getgenv().Config[configKey] then Color3.fromRGB(0, 150, 100) else Color3.fromRGB(100, 100, 100)
    end)
    
    return container
end

local function phem_CreateSlider(parent, name, configKey, min, max)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 10)
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slider.BorderSizePixel = 0
    slider.Parent = container
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    local percent = (getgenv().Config[configKey] - min) / (max - min)
    fill.Size = UDim2.new(percent, 0, 1, 0)
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(math.round(getgenv().Config[configKey]))
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Position = UDim2.new(1, -40, 0, -5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    valueLabel.TextSize = 11
    valueLabel.Parent = container
    
    local phem_Dragging = false
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            phem_Dragging = true
        end
    end)
    
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            phem_Dragging = false
        end
    end)
    
    phem_RunService.RenderStepped:Connect(function()
        if phem_Dragging then
            local mouse = phem6:GetMouse()
            local percent = math.clamp((mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local value = min + (percent * (max - min))
            value = math.round(value)
            getgenv().Config[configKey] = value
            fill.Size = UDim2.new(percent, 0, 1, 0)
            valueLabel.Text = tostring(value)
        end
    end)
    
    return container
end

local function phem_CreateCombobox(parent, name, configKey, options)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -16, 0, 35)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(1, 0, 0, 15)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local dropdown = Instance.new("TextButton")
    dropdown.Text = getgenv().Config[configKey] or options[1]
    dropdown.Size = UDim2.new(0, 120, 0, 20)
    dropdown.Position = UDim2.new(0, 0, 0, 15)
    dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
    dropdown.TextSize = 11
    dropdown.BorderSizePixel = 1
    dropdown.BorderColor3 = Color3.fromRGB(100, 100, 100)
    dropdown.Parent = container
    
    local menuOpen = false
    local phem_DropdownMenu = nil
    
    dropdown.MouseButton1Click:Connect(function()
        if menuOpen then
            if phem_DropdownMenu then phem_DropdownMenu:Destroy() end
            menuOpen = false
            return
        end
        
        menuOpen = true
        phem_DropdownMenu = Instance.new("Frame")
        phem_DropdownMenu.Size = UDim2.new(0, 120, 0, 20 * #options)
        phem_DropdownMenu.Position = UDim2.new(0, 0, 0, 35)
        phem_DropdownMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        phem_DropdownMenu.BorderSizePixel = 1
        phem_DropdownMenu.BorderColor3 = Color3.fromRGB(100, 100, 100)
        phem_DropdownMenu.Parent = container
        
        for _, option in pairs(options) do
            local btn = Instance.new("TextButton")
            btn.Text = option
            btn.Size = UDim2.new(1, 0, 0, 20)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextSize = 11
            btn.BorderSizePixel = 0
            btn.Parent = phem_DropdownMenu
            
            btn.MouseButton1Click:Connect(function()
                getgenv().Config[configKey] = option
                dropdown.Text = option
                if phem_DropdownMenu then phem_DropdownMenu:Destroy() end
                menuOpen = false
            end)
        end
    end)
    
    return container
end

function phem_UpdateTabContent()
    phem_ContentFrame:ClearAllChildren()
    phem_UIListLayout.Parent = phem_ContentFrame
    
    if phem_CurrentTab == "Aimbot" then
        phem_CreateToggle(phem_ContentFrame, "Enable Aimbot", "Aimbot")
        phem_CreateToggle(phem_ContentFrame, "Aimlock (Camera)", "Aimlock")
        phem_CreateCombobox(phem_ContentFrame, "Lock Target Part", "LockTargetPart", {"Head", "Torso", "UpperTorso", "HumanoidRootPart"})
        phem_CreateToggle(phem_ContentFrame, "Silent Aim AutoFire", "SilentAim")
        phem_CreateCombobox(phem_ContentFrame, "Aim Silent Target", "AimSilentPart", {"Head", "Torso", "UpperTorso", "HumanoidRootPart"})
        phem_CreateSlider(phem_ContentFrame, "Body Hit Chance %", "BodyHitChance", 1, 100)
        phem_CreateToggle(phem_ContentFrame, "Auto Fire", "AutoFire")
        phem_CreateToggle(phem_ContentFrame, "Show FOV Circle", "ShowFOV")
        phem_CreateSlider(phem_ContentFrame, "FOV Radius", "FOVRadius", 50, 500)
        phem_CreateToggle(phem_ContentFrame, "Show Tracer", "ShowTracer")
        phem_CreateToggle(phem_ContentFrame, "Team Check", "TeamCheck")
        phem_CreateCombobox(phem_ContentFrame, "Team Check Type", "TeamCheckType", {"Exclude Team", "Only Team"})
        phem_CreateToggle(phem_ContentFrame, "Wallcheck", "Wallcheck")
        
    elseif phem_CurrentTab == "Visual" then
        phem_CreateToggle(phem_ContentFrame, "Enable ESP", "ESP")
        phem_CreateToggle(phem_ContentFrame, "ESP Line", "ESPLine")
        phem_CreateToggle(phem_ContentFrame, "ESP Box", "ESPBox")
        phem_CreateToggle(phem_ContentFrame, "ESP Health Bar", "ESPHealthBar")
        phem_CreateToggle(phem_ContentFrame, "ESP Name", "ESPName")
        phem_CreateToggle(phem_ContentFrame, "ESP Distance", "ESPDistance")
        phem_CreateToggle(phem_ContentFrame, "ESP Skeleton", "ESPSkeleton")
        
    elseif phem_CurrentTab == "Extra" then
        phem_CreateToggle(phem_ContentFrame, "Magnet Pull", "MagnetPull")
        phem_CreateToggle(phem_ContentFrame, "Magnet Lite", "MagnetLite")
        phem_CreateSlider(phem_ContentFrame, "Pull Speed", "PullSpeed", 10, 150)
        phem_CreateToggle(phem_ContentFrame, "Fly", "Fly")
        phem_CreateSlider(phem_ContentFrame, "Fly Speed", "FlySpeed", 10, 200)
        phem_CreateToggle(phem_ContentFrame, "Velocity", "Velocity")
        phem_CreateSlider(phem_ContentFrame, "Velocity Speed", "VelocitySpeed", 10, 200)
        phem_CreateToggle(phem_ContentFrame, "No Clip", "NoClip")
    end
end

phem_UpdateTabContent()

print("✓ Safe Cheat Script Loaded")
print("Enable Aimbot in menu to activate features")

end) -- end pcall
