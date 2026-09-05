-- Cheat Script with Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚔ Cheat Menu",
   LoadingTitle = "Loading Cheat Menu...",
   LoadingSubtitle = "by Dhhd",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- Initialize Services and Variables
local phem1_plrs = game:GetService("Players")
local phem2_cs = game:GetService("CollectionService")
local phem_RunService = game:GetService("RunService")
local phem6 = phem1_plrs.LocalPlayer

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
        ESPBox = false,
        ESPHealthBar = false,
        ESPName = false,
        ESPDistance = false,
        ESPSkeleton = false,
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

-- CREATE TABS
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local ExtraTab = Window:CreateTab("Extra", 4483362458)

-- AIMBOT TAB
AimbotTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Flag = "Aimbot",
   Callback = function(Value)
      getgenv().Config.Aimbot = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Aimlock (Camera)",
   CurrentValue = false,
   Flag = "Aimlock",
   Callback = function(Value)
      getgenv().Config.Aimlock = Value
   end,
})

AimbotTab:CreateDropdown({
   Name = "Lock Target Part",
   Options = {"Head", "Torso", "UpperTorso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "LockTargetPart",
   Callback = function(Option)
      getgenv().Config.LockTargetPart = Option[1]
   end,
})

AimbotTab:CreateToggle({
   Name = "Silent Aim AutoFire",
   CurrentValue = false,
   Flag = "SilentAim",
   Callback = function(Value)
      getgenv().Config.SilentAim = Value
   end,
})

AimbotTab:CreateDropdown({
   Name = "Aim Silent Target Part",
   Options = {"Head", "Torso", "UpperTorso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimSilentPart",
   Callback = function(Option)
      getgenv().Config.AimSilentPart = Option[1]
   end,
})

AimbotTab:CreateSlider({
   Name = "Body Hit Chance %",
   Range = {1, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 50,
   Flag = "BodyHitChance",
   Callback = function(Value)
      getgenv().Config.BodyHitChance = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Auto Fire",
   CurrentValue = false,
   Flag = "AutoFire",
   Callback = function(Value)
      getgenv().Config.AutoFire = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = true,
   Flag = "ShowFOV",
   Callback = function(Value)
      getgenv().Config.ShowFOV = Value
   end,
})

AimbotTab:CreateSlider({
   Name = "FOV Radius",
   Range = {50, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 300,
   Flag = "FOVRadius",
   Callback = function(Value)
      getgenv().Config.FOVRadius = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Show Tracer",
   CurrentValue = true,
   Flag = "ShowTracer",
   Callback = function(Value)
      getgenv().Config.ShowTracer = Value
   end,
})

AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Flag = "TeamCheck",
   Callback = function(Value)
      getgenv().Config.TeamCheck = Value
   end,
})

AimbotTab:CreateDropdown({
   Name = "Team Check Type",
   Options = {"Exclude Team", "Only Team"},
   CurrentOption = {"Exclude Team"},
   MultipleOptions = false,
   Flag = "TeamCheckType",
   Callback = function(Option)
      getgenv().Config.TeamCheckType = Option[1]
   end,
})

AimbotTab:CreateToggle({
   Name = "Wallcheck",
   CurrentValue = true,
   Flag = "Wallcheck",
   Callback = function(Value)
      getgenv().Config.Wallcheck = Value
   end,
})

-- VISUAL TAB
VisualTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESP",
   Callback = function(Value)
      getgenv().Config.ESP = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Line",
   CurrentValue = false,
   Flag = "ESPLine",
   Callback = function(Value)
      getgenv().Config.ESPLine = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Box",
   CurrentValue = false,
   Flag = "ESPBox",
   Callback = function(Value)
      getgenv().Config.ESPBox = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Health Bar",
   CurrentValue = false,
   Flag = "ESPHealthBar",
   Callback = function(Value)
      getgenv().Config.ESPHealthBar = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Name",
   CurrentValue = false,
   Flag = "ESPName",
   Callback = function(Value)
      getgenv().Config.ESPName = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Distance",
   CurrentValue = false,
   Flag = "ESPDistance",
   Callback = function(Value)
      getgenv().Config.ESPDistance = Value
   end,
})

VisualTab:CreateToggle({
   Name = "ESP Skeleton",
   CurrentValue = false,
   Flag = "ESPSkeleton",
   Callback = function(Value)
      getgenv().Config.ESPSkeleton = Value
   end,
})

-- EXTRA TAB
ExtraTab:CreateToggle({
   Name = "Magnet Pull",
   CurrentValue = false,
   Flag = "MagnetPull",
   Callback = function(Value)
      getgenv().Config.MagnetPull = Value
   end,
})

ExtraTab:CreateToggle({
   Name = "Magnet Lite (Side + Up)",
   CurrentValue = false,
   Flag = "MagnetLite",
   Callback = function(Value)
      getgenv().Config.MagnetLite = Value
   end,
})

ExtraTab:CreateSlider({
   Name = "Pull Speed",
   Range = {10, 150},
   Increment = 5,
   Suffix = "sp",
   CurrentValue = 50,
   Flag = "PullSpeed",
   Callback = function(Value)
      getgenv().Config.PullSpeed = Value
   end,
})

ExtraTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "Fly",
   Callback = function(Value)
      getgenv().Config.Fly = Value
   end,
})

ExtraTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 200},
   Increment = 5,
   Suffix = "sp",
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(Value)
      getgenv().Config.FlySpeed = Value
   end,
})

ExtraTab:CreateToggle({
   Name = "Velocity",
   CurrentValue = false,
   Flag = "Velocity",
   Callback = function(Value)
      getgenv().Config.Velocity = Value
   end,
})

ExtraTab:CreateSlider({
   Name = "Velocity Speed",
   Range = {10, 200},
   Increment = 5,
   Suffix = "sp",
   CurrentValue = 50,
   Flag = "VelocitySpeed",
   Callback = function(Value)
      getgenv().Config.VelocitySpeed = Value
   end,
})

ExtraTab:CreateToggle({
   Name = "No Clip",
   CurrentValue = false,
   Flag = "NoClip",
   Callback = function(Value)
      getgenv().Config.NoClip = Value
   end,
})

Rayfield:Notify({
   Title = "Script Loaded!",
   Content = "Cheat Menu Loaded Successfully",
   Duration = 2,
   Image = 4483362458,
})

print("✓ Rayfield Cheat Script Loaded")
print("Enable Aimbot in menu to activate features")
