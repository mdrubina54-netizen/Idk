-- Roblox Anticheat Testing GUI
-- Comprehensive cheat menu with multiple tabs and customizable features

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnticheatTestGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Window
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 350, 0, 450)
MainWindow.Position = UDim2.new(0.5, -175, 0.5, -225)
MainWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainWindow.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainWindow.BorderSizePixel = 2
MainWindow.Parent = ScreenGui
MainWindow.Draggable = true
MainWindow.Active = true

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderColor3 = Color3.fromRGB(0, 150, 255)
TitleBar.BorderSizePixel = 1
TitleBar.Parent = MainWindow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "ANTICHEAT TEST"
TitleLabel.Parent = TitleBar

-- Minimize Button
local MinButton = Instance.new("TextButton")
MinButton.Name = "MinButton"
MinButton.Size = UDim2.new(0, 35, 0, 35)
MinButton.Position = UDim2.new(1, -70, 0, 0)
MinButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinButton.TextColor3 = Color3.fromRGB(0, 150, 255)
MinButton.TextSize = 16
MinButton.Font = Enum.Font.GothamBold
MinButton.Text = "−"
MinButton.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -35, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.Parent = TitleBar

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 30)
TabContainer.Position = UDim2.new(0, 0, 0, 35)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainWindow

-- Tab Buttons
local function createTabButton(name, position)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "Tab"
    tabBtn.Size = UDim2.new(0, 110, 1, 0)
    tabBtn.Position = UDim2.new(0, position, 0, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    tabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.Text = name
    tabBtn.Parent = TabContainer
    return tabBtn
end

local AimbotTabBtn = createTabButton("Aimbot", 0)
local VisualTabBtn = createTabButton("Visual", 110)
local ExtraTabBtn = createTabButton("Extra", 220)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, 0, 1, -65)
ContentArea.Position = UDim2.new(0, 0, 0, 65)
ContentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -10, 1, 0)
ScrollFrame.Position = UDim2.new(0, 5, 0, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = ContentArea

-- Settings Table
local Settings = {
    Aimbot = {
        Enabled = false,
        AimbotType = "Aimlock",
        ShowFOV = false,
        FOV = 100,
        TeamCheck = true,
        TeamCheckType = "Different",
        WallCheck = false
    },
    Visual = {
        ESPEnabled = false,
        ESPLine = true,
        ESPLineColor = Color3.fromRGB(0, 255, 0),
        ESPLinePosition = "Top",
        ESPBox = false,
        ESPBoxColor = Color3.fromRGB(255, 0, 0),
        ESPBoxType = "Filled",
        ESPHealthBar = true,
        ESPHealthColor = Color3.fromRGB(0, 255, 0),
        ESPHealthPosition = "Left",
        ESPName = true,
        ESPNameColor = Color3.fromRGB(255, 255, 255),
        ESPNamePosition = "Top",
        ESPDistance = true,
        ESPDistanceColor = Color3.fromRGB(255, 255, 255),
        ESPDistancePosition = "Bottom",
        ESPSkeleton = false,
        ESPSkeletonColor = Color3.fromRGB(0, 255, 255)
    },
    Extra = {
        TPEnabled = false,
        FlyEnabled = false,
        FlySpeed = 50,
        VelocitySpeed = 100,
        NoClip = false,
        NoRecoil = false
    }
}

-- Helper Functions
local function createToggle(parent, label, callback, yOffset)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 25)
    container.Position = UDim2.new(0, 5, 0, yOffset)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local label_obj = Instance.new("TextLabel")
    label_obj.Size = UDim2.new(1, -35, 1, 0)
    label_obj.BackgroundTransparency = 1
    label_obj.TextColor3 = Color3.fromRGB(200, 200, 200)
    label_obj.TextSize = 12
    label_obj.Font = Enum.Font.Gotham
    label_obj.Text = label
    label_obj.TextXAlignment = Enum.TextXAlignment.Left
    label_obj.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 30, 0, 20)
    toggle.Position = UDim2.new(1, -30, 0.5, -10)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 10
    toggle.Font = Enum.Font.GothamBold
    toggle.Text = "OFF"
    toggle.Parent = container
    
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 50)
        if callback then callback(state) end
    end)
    
    return toggle, container
end

local function createSlider(parent, label, minVal, maxVal, default, callback, yOffset)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 35)
    container.Position = UDim2.new(0, 5, 0, yOffset)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local label_obj = Instance.new("TextLabel")
    label_obj.Size = UDim2.new(1, 0, 0, 15)
    label_obj.BackgroundTransparency = 1
    label_obj.TextColor3 = Color3.fromRGB(200, 200, 200)
    label_obj.TextSize = 11
    label_obj.Font = Enum.Font.Gotham
    label_obj.Text = label .. ": " .. default
    label_obj.TextXAlignment = Enum.TextXAlignment.Left
    label_obj.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 18)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local currentValue = default
    local function updateSlider(input)
        local relativeX = input.Position.X - sliderBg.AbsolutePosition.X
        local percentage = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(minVal + (maxVal - minVal) * percentage)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        label_obj.Text = label .. ": " .. currentValue
        if callback then callback(currentValue) end
    end
    
    sliderBg.InputBegan:Connect(function(input, gpe)
        if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        updateSlider(input)
        
        local connection
        connection = Mouse.Move:Connect(function()
            updateSlider(Mouse)
        end)
        
        UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    
    sliderFill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
    return container
end

local function createColorPicker(parent, label, defaultColor, callback, yOffset)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 25)
    container.Position = UDim2.new(0, 5, 0, yOffset)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local label_obj = Instance.new("TextLabel")
    label_obj.Size = UDim2.new(1, -35, 1, 0)
    label_obj.BackgroundTransparency = 1
    label_obj.TextColor3 = Color3.fromRGB(200, 200, 200)
    label_obj.TextSize = 11
    label_obj.Font = Enum.Font.Gotham
    label_obj.Text = label
    label_obj.TextXAlignment = Enum.TextXAlignment.Left
    label_obj.Parent = container
    
    local colorBox = Instance.new("Frame")
    colorBox.Size = UDim2.new(0, 30, 0, 20)
    colorBox.Position = UDim2.new(1, -30, 0.5, -10)
    colorBox.BackgroundColor3 = defaultColor
    colorBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
    colorBox.BorderSizePixel = 1
    colorBox.Parent = container
    
    colorBox.MouseButton1Click:Connect(function()
        local colorPicker = Instance.new("ColorPickerDialog")
        colorPicker:PromptAsync()
        if colorPicker.Color then
            colorBox.BackgroundColor3 = colorPicker.Color
            if callback then callback(colorPicker.Color) end
        end
    end)
    
    return container
end

local function createCombobox(parent, label, options, default, callback, yOffset)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 30)
    container.Position = UDim2.new(0, 5, 0, yOffset)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local label_obj = Instance.new("TextLabel")
    label_obj.Size = UDim2.new(1, 0, 0, 15)
    label_obj.BackgroundTransparency = 1
    label_obj.TextColor3 = Color3.fromRGB(200, 200, 200)
    label_obj.TextSize = 11
    label_obj.Font = Enum.Font.Gotham
    label_obj.Text = label
    label_obj.TextXAlignment = Enum.TextXAlignment.Left
    label_obj.Parent = container
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 15)
    button.Position = UDim2.new(0, 0, 0, 15)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.TextSize = 10
    button.Font = Enum.Font.Gotham
    button.Text = default
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(70, 70, 70)
    button.Parent = container
    
    local dropdownOpen = false
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, #options * 20)
    dropdown.Position = UDim2.new(0, 0, 0, 15)
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdown.BorderColor3 = Color3.fromRGB(0, 150, 255)
    dropdown.BorderSizePixel = 1
    dropdown.Visible = false
    dropdown.ZIndex = 100
    dropdown.Parent = container
    
    for i, option in ipairs(options) do
        local optionBtn = Instance.new("TextButton")
        optionBtn.Size = UDim2.new(1, 0, 0, 20)
        optionBtn.Position = UDim2.new(0, 0, 0, (i-1) * 20)
        optionBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        optionBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        optionBtn.TextSize = 10
        optionBtn.Font = Enum.Font.Gotham
        optionBtn.Text = option
        optionBtn.BorderSizePixel = 0
        optionBtn.Parent = dropdown
        
        optionBtn.MouseButton1Click:Connect(function()
            button.Text = option
            dropdown.Visible = false
            dropdownOpen = false
            if callback then callback(option) end
        end)
    end
    
    button.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        dropdown.Visible = dropdownOpen
    end)
    
    return container
end

-- Create Tabs
local function createTab()
    local tab = Instance.new("Frame")
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.BorderSizePixel = 0
    return tab
end

local AimbotTab = createTab()
AimbotTab.Parent = ScrollFrame

local VisualTab = createTab()
VisualTab.Parent = ScrollFrame

local ExtraTab = createTab()
ExtraTab.Parent = ScrollFrame

-- Populate Aimbot Tab
local yPos = 0
createToggle(AimbotTab, "Enable Aimbot", function(state) Settings.Aimbot.Enabled = state end, yPos)
yPos = yPos + 30

createCombobox(AimbotTab, "Aimbot Type", {"Aimlock", "Prediction", "Silent"}, "Aimlock", function(val) Settings.Aimbot.AimbotType = val end, yPos)
yPos = yPos + 40

createToggle(AimbotTab, "Show FOV Circle", function(state) Settings.Aimbot.ShowFOV = state end, yPos)
yPos = yPos + 30

createSlider(AimbotTab, "FOV Radius", 10, 500, Settings.Aimbot.FOV, function(val) Settings.Aimbot.FOV = val end, yPos)
yPos = yPos + 45

createToggle(AimbotTab, "Team Check", function(state) Settings.Aimbot.TeamCheck = state end, yPos)
yPos = yPos + 30

createCombobox(AimbotTab, "Team Check Type", {"Different", "All", "Same"}, "Different", function(val) Settings.Aimbot.TeamCheckType = val end, yPos)
yPos = yPos + 40

createToggle(AimbotTab, "Wall Check", function(state) Settings.Aimbot.WallCheck = state end, yPos)

-- Populate Visual Tab
yPos = 0
createToggle(VisualTab, "Enable ESP", function(state) Settings.Visual.ESPEnabled = state end, yPos)
yPos = yPos + 30

createToggle(VisualTab, "ESP Line", function(state) Settings.Visual.ESPLine = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "ESP Line Color", Settings.Visual.ESPLineColor, function(col) Settings.Visual.ESPLineColor = col end, yPos)
yPos = yPos + 30

createCombobox(VisualTab, "ESP Line Position", {"Top", "Bottom", "Side", "Center"}, "Top", function(val) Settings.Visual.ESPLinePosition = val end, yPos)
yPos = yPos + 40

createToggle(VisualTab, "ESP Box", function(state) Settings.Visual.ESPBox = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "ESP Box Color", Settings.Visual.ESPBoxColor, function(col) Settings.Visual.ESPBoxColor = col end, yPos)
yPos = yPos + 30

createCombobox(VisualTab, "ESP Box Type", {"Solid", "Corner", "Filled"}, "Filled", function(val) Settings.Visual.ESPBoxType = val end, yPos)
yPos = yPos + 40

createToggle(VisualTab, "ESP Health Bar", function(state) Settings.Visual.ESPHealthBar = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "Health Bar Color", Settings.Visual.ESPHealthColor, function(col) Settings.Visual.ESPHealthColor = col end, yPos)
yPos = yPos + 30

createCombobox(VisualTab, "Health Position", {"Left", "Right", "Top", "Bottom"}, "Left", function(val) Settings.Visual.ESPHealthPosition = val end, yPos)
yPos = yPos + 40

createToggle(VisualTab, "ESP Name", function(state) Settings.Visual.ESPName = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "Name Color", Settings.Visual.ESPNameColor, function(col) Settings.Visual.ESPNameColor = col end, yPos)
yPos = yPos + 30

createCombobox(VisualTab, "Name Position", {"Top", "Bottom"}, "Top", function(val) Settings.Visual.ESPNamePosition = val end, yPos)
yPos = yPos + 40

createToggle(VisualTab, "ESP Distance", function(state) Settings.Visual.ESPDistance = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "Distance Color", Settings.Visual.ESPDistanceColor, function(col) Settings.Visual.ESPDistanceColor = col end, yPos)
yPos = yPos + 30

createCombobox(VisualTab, "Distance Position", {"Top", "Bottom"}, "Bottom", function(val) Settings.Visual.ESPDistancePosition = val end, yPos)
yPos = yPos + 40

createToggle(VisualTab, "ESP Skeleton", function(state) Settings.Visual.ESPSkeleton = state end, yPos)
yPos = yPos + 30

createColorPicker(VisualTab, "Skeleton Color", Settings.Visual.ESPSkeletonColor, function(col) Settings.Visual.ESPSkeletonColor = col end, yPos)

-- Populate Extra Tab
yPos = 0
createToggle(ExtraTab, "TP to Nearest", function(state) Settings.Extra.TPEnabled = state end, yPos)
yPos = yPos + 30

createToggle(ExtraTab, "Enable Fly", function(state) Settings.Extra.FlyEnabled = state end, yPos)
yPos = yPos + 30

createSlider(ExtraTab, "Fly Speed", 1, 200, Settings.Extra.FlySpeed, function(val) Settings.Extra.FlySpeed = val end, yPos)
yPos = yPos + 45

createSlider(ExtraTab, "Velocity Speed", 1, 200, Settings.Extra.VelocitySpeed, function(val) Settings.Extra.VelocitySpeed = val end, yPos)
yPos = yPos + 45

createToggle(ExtraTab, "No Clip", function(state) Settings.Extra.NoClip = state end, yPos)
yPos = yPos + 30

createToggle(ExtraTab, "No Recoil", function(state) Settings.Extra.NoRecoil = state end, yPos)

-- Update Canvas Size
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(500, yPos + 100))

-- Tab Switching
local function showTab(tab)
    AimbotTab.Visible = false
    VisualTab.Visible = false
    ExtraTab.Visible = false
    tab.Visible = true
end

AimbotTabBtn.MouseButton1Click:Connect(function()
    showTab(AimbotTab)
    AimbotTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    AimbotTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    VisualTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ExtraTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
end)

VisualTabBtn.MouseButton1Click:Connect(function()
    showTab(VisualTab)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    VisualTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AimbotTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    AimbotTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ExtraTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
end)

ExtraTabBtn.MouseButton1Click:Connect(function()
    showTab(ExtraTab)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    ExtraTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AimbotTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    AimbotTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    VisualTabBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Start with Aimbot Tab
showTab(AimbotTab)
AimbotTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
AimbotTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Minimize Functionality
local minimized = false
MinButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        ContentArea.Visible = false
        TabContainer.Visible = false
        MainWindow.Size = UDim2.new(0, 350, 0, 35)
    else
        ContentArea.Visible = true
        TabContainer.Visible = true
        MainWindow.Size = UDim2.new(0, 350, 0, 450)
    end
end)

-- Close Button
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Print Settings for Debugging
print("Anticheat Testing GUI Loaded!")
print("Settings Table:", Settings)

-- Additional: Add keybind to toggle GUI visibility (Delete key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui.Visible = not ScreenGui.Visible
    end
end)
