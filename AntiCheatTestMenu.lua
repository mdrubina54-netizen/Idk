-- ================================================
--   AntiCheat Test Menu
--   Fixed: no UIListLayout crash, no scope aimbot
-- ================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  CONFIG
-- ─────────────────────────────────────────────
local Cfg = {
    AimbotEnabled   = false,
    AimbotBone      = "Head",
    TeamCheck       = false,
    ShowFOV         = true,
    AimFOV          = 120,
    AimSmoothing    = 10,   -- 1-20, higher = smoother

    ESPEnabled      = false,
    ESPBox          = false,
    ESPLine         = false,
    ESPLinePos      = "Bottom",
    ESPHealthBar    = false,
    ESPHealthBarPos = "Left",
    ESPName         = false,
    ESPNamePos      = "Top",
    ESPDistance     = false,
    ESPDistancePos  = "Bottom",
    MaxDist         = 1000,

    BoxColor        = Color3.fromRGB(255,255,255),
    LineColor       = Color3.fromRGB(0,200,255),
    TextColor       = Color3.fromRGB(255,255,255),
}

-- ─────────────────────────────────────────────
--  DRAWING POOL
-- ─────────────────────────────────────────────
local Pool = {}

local FOVCircle      = Drawing.new("Circle")
FOVCircle.Thickness  = 1.5
FOVCircle.Color      = Color3.fromRGB(255,255,255)
FOVCircle.Filled     = false
FOVCircle.NumSides   = 64
FOVCircle.Radius     = Cfg.AimFOV
FOVCircle.Visible    = false

local function newDraw(t, props)
    local d = Drawing.new(t)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function initESP(p)
    if Pool[p] then return end
    Pool[p] = {
        box   = newDraw("Square",{Visible=false,Filled=false,Thickness=1,Color=Cfg.BoxColor}),
        line  = newDraw("Line",  {Visible=false,Thickness=1, Color=Cfg.LineColor}),
        hbg   = newDraw("Square",{Visible=false,Filled=true, Thickness=1,Color=Color3.fromRGB(30,30,30)}),
        hbar  = newDraw("Square",{Visible=false,Filled=true, Thickness=1,Color=Color3.fromRGB(0,255,80)}),
        name  = newDraw("Text",  {Visible=false,Size=13,Color=Cfg.TextColor,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0)}),
        dist  = newDraw("Text",  {Visible=false,Size=12,Color=Cfg.TextColor,Center=true,Outline=true,OutlineColor=Color3.new(0,0,0)}),
    }
end

local function removeESP(p)
    if not Pool[p] then return end
    for _,d in pairs(Pool[p]) do d:Remove() end
    Pool[p] = nil
end

Players.PlayerAdded:Connect(function(p)
    initESP(p)
    p.CharacterAdded:Connect(function() task.wait(1) initESP(p) end)
end)
Players.PlayerRemoving:Connect(removeESP)
for _,p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then initESP(p) end
end

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────
local function w2s(pos)
    local sp,depth,vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X,sp.Y), depth, vis
end

local function getChar(p)
    local c = p.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChild("Head")
    local m = c:FindFirstChildOfClass("Humanoid")
    if r and h and m then return c,r,h,m end
end

-- ─────────────────────────────────────────────
--  AIMBOT (no scope needed — purely FOV-based)
-- ─────────────────────────────────────────────
local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local bestD, bestPos = math.huge, nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if Cfg.TeamCheck and p.Team == LocalPlayer.Team then continue end
        local c,r,h,m = getChar(p)
        if not c or m.Health <= 0 then continue end
        local bone = (Cfg.AimbotBone == "Head") and h or r
        local sp, depth, vis = w2s(bone.Position)
        if not vis or depth < 0 then continue end
        local d = (sp - center).Magnitude
        if d < Cfg.AimFOV and d < bestD then
            bestD   = d
            bestPos = bone.Position
        end
    end
    return bestPos
end

-- ─────────────────────────────────────────────
--  GUI THEME
-- ─────────────────────────────────────────────
local T = {
    bg       = Color3.fromRGB(14,14,20),
    bar      = Color3.fromRGB(20,20,30),
    panel    = Color3.fromRGB(20,20,28),
    border   = Color3.fromRGB(55,55,80),
    accent   = Color3.fromRGB(110,65,220),
    accentHi = Color3.fromRGB(140,90,255),
    text     = Color3.fromRGB(225,225,240),
    dim      = Color3.fromRGB(120,120,150),
    ton      = Color3.fromRGB(100,60,210),
    toff     = Color3.fromRGB(45,45,65),
    close    = Color3.fromRGB(200,50,55),
    mini     = Color3.fromRGB(190,150,25),
    sbar     = Color3.fromRGB(35,35,55),
}

-- ─────────────────────────────────────────────
--  SCREEN GUI
-- ─────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "ACMenu"
SG.ResetOnSpawn   = false
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Try to parent safely
local ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not ok then SG.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Main window
local WIN = Instance.new("Frame", SG)
WIN.Size             = UDim2.new(0,430,0,370)
WIN.Position         = UDim2.new(0.5,-215,0.5,-185)
WIN.BackgroundColor3 = T.bg
WIN.BorderSizePixel  = 0
WIN.ClipsDescendants = false
Instance.new("UICorner",WIN).CornerRadius = UDim.new(0,8)
local ws = Instance.new("UIStroke",WIN)
ws.Color=T.border ws.Thickness=1.5

-- Title bar
local BAR = Instance.new("Frame",WIN)
BAR.Size             = UDim2.new(1,0,0,32)
BAR.BackgroundColor3 = T.bar
BAR.BorderSizePixel  = 0
Instance.new("UICorner",BAR).CornerRadius = UDim.new(0,8)
-- cover bottom corners
local barcov = Instance.new("Frame",BAR)
barcov.Size=UDim2.new(1,0,0,8) barcov.Position=UDim2.new(0,0,1,-8)
barcov.BackgroundColor3=T.bar barcov.BorderSizePixel=0

local TITLE = Instance.new("TextLabel",BAR)
TITLE.Size=UDim2.new(1,-80,1,0) TITLE.Position=UDim2.new(0,10,0,0)
TITLE.BackgroundTransparency=1 TITLE.Text="  ⚔  AntiCheat Test Menu"
TITLE.TextColor3=T.text TITLE.Font=Enum.Font.GothamBold TITLE.TextSize=13
TITLE.TextXAlignment=Enum.TextXAlignment.Left

local function mkCtrlBtn(xOff, bg, lbl)
    local b = Instance.new("TextButton",BAR)
    b.Size=UDim2.new(0,22,0,18) b.Position=UDim2.new(1,xOff,0.5,-9)
    b.BackgroundColor3=bg b.Text=lbl b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold b.TextSize=11 b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    return b
end
local CLOSE = mkCtrlBtn(-6,  T.close, "✕")
local MINI  = mkCtrlBtn(-32, T.mini,  "─")

-- Drag
local dragging,dragOrig,mouseOrig
BAR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true dragOrig=WIN.Position mouseOrig=i.Position
    end
end)
BAR.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-mouseOrig
        WIN.Position=UDim2.new(dragOrig.X.Scale,dragOrig.X.Offset+d.X,
                               dragOrig.Y.Scale,dragOrig.Y.Offset+d.Y)
    end
end)

local minimized=false
MINI.MouseButton1Click:Connect(function()
    minimized=not minimized
    WIN.Size = minimized and UDim2.new(0,430,0,32) or UDim2.new(0,430,0,370)
    WIN.ClipsDescendants=minimized
end)
CLOSE.MouseButton1Click:Connect(function()
    FOVCircle:Remove()
    for p in pairs(Pool) do removeESP(p) end
    SG:Destroy()
end)

-- Tab row
local TABROW = Instance.new("Frame",WIN)
TABROW.Size=UDim2.new(1,-16,0,28) TABROW.Position=UDim2.new(0,8,0,36)
TABROW.BackgroundTransparency=1 TABROW.BorderSizePixel=0

-- Content clip frame
local CLIP = Instance.new("Frame",WIN)
CLIP.Size=UDim2.new(1,-16,1,-76) CLIP.Position=UDim2.new(0,8,0,70)
CLIP.BackgroundTransparency=1 CLIP.BorderSizePixel=0
CLIP.ClipsDescendants=true

-- ─────────────────────────────────────────────
--  TAB SYSTEM  (no UIListLayout anywhere)
-- ─────────────────────────────────────────────
local TABS = {}
local TABBTNS = {}
local ACTIVE_TAB = nil
local TAB_ORDER = {}

local TAB_W = 130  -- px per tab button

local function showTab(name)
    ACTIVE_TAB = name
    for n,page in pairs(TABS) do
        page.Visible = (n==name)
    end
    for n,btn in pairs(TABBTNS) do
        btn.BackgroundColor3 = (n==name) and T.accent or T.bar
        btn.TextColor3       = (n==name) and Color3.new(1,1,1) or T.dim
    end
end

local function addTab(name)
    local idx = #TAB_ORDER
    table.insert(TAB_ORDER,name)

    local btn = Instance.new("TextButton",TABROW)
    btn.Size=UDim2.new(0,TAB_W,1,0)
    btn.Position=UDim2.new(0,idx*(TAB_W+4),0,0)
    btn.BackgroundColor3=T.bar btn.BorderSizePixel=0
    btn.Text=name btn.TextColor3=T.dim
    btn.Font=Enum.Font.GothamSemibold btn.TextSize=12
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)

    -- scrollable page
    local sf = Instance.new("ScrollingFrame",CLIP)
    sf.Size=UDim2.new(1,0,1,0) sf.Position=UDim2.new(0,0,0,0)
    sf.BackgroundTransparency=1 sf.BorderSizePixel=0
    sf.ScrollBarThickness=4 sf.ScrollBarImageColor3=T.accent
    sf.CanvasSize=UDim2.new(0,0,0,0)   -- we'll update manually
    sf.Visible=false

    TABS[name]=sf TABBTNS[name]=btn
    btn.MouseButton1Click:Connect(function() showTab(name) end)
    return sf
end

-- ─────────────────────────────────────────────
--  COMPONENT BUILDERS  (absolute Y positioning)
-- ─────────────────────────────────────────────
local ITEM_H  = 30
local SEC_H   = 24
local PADDING = 6

-- Each page tracks its own Y cursor
local cursors = {}
local function getY(page)
    cursors[page] = cursors[page] or PADDING
    return cursors[page]
end
local function advY(page, h)
    cursors[page] = (cursors[page] or PADDING) + h + 4
    -- update canvas
    page.CanvasSize = UDim2.new(0,0,0,cursors[page]+8)
end

local function addSection(page, label)
    local y = getY(page)
    local f = Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,SEC_H) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.accent f.BackgroundTransparency=0.78 f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-12,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=label
    l.TextColor3=T.accentHi l.Font=Enum.Font.GothamBold l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left
    advY(page, SEC_H)
end

local function baseRow(page)
    local y = getY(page)
    local f = Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,ITEM_H) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.panel f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",f) st.Color=T.border st.Thickness=1
    advY(page, ITEM_H)
    return f, y
end

local function rowLabel(f, text)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-60,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=text
    l.TextColor3=T.text l.Font=Enum.Font.Gotham l.TextSize=12
    l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

-- Toggle
local function addToggle(page, label, key, cb)
    local f = baseRow(page)
    rowLabel(f, label)

    local tog=Instance.new("TextButton",f)
    tog.Size=UDim2.new(0,38,0,20) tog.Position=UDim2.new(1,-46,0.5,-10)
    tog.BackgroundColor3=Cfg[key] and T.ton or T.toff
    tog.Text="" tog.BorderSizePixel=0
    Instance.new("UICorner",tog).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",tog)
    knob.Size=UDim2.new(0,14,0,14) knob.BorderSizePixel=0
    knob.BackgroundColor3=Color3.new(1,1,1)
    knob.Position=Cfg[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    tog.MouseButton1Click:Connect(function()
        Cfg[key]=not Cfg[key]
        local on=Cfg[key]
        tog.BackgroundColor3=on and T.ton or T.toff
        knob.Position=on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
        if cb then cb(on) end
    end)
end

-- Dropdown (cycle)
local function addDropdown(page, label, key, opts, cb)
    local f = baseRow(page)
    rowLabel(f, label)

    local btn=Instance.new("TextButton",f)
    btn.Size=UDim2.new(0,105,0,22) btn.Position=UDim2.new(1,-112,0.5,-11)
    btn.BackgroundColor3=T.accent btn.Text=tostring(Cfg[key])
    btn.TextColor3=Color3.new(1,1,1) btn.Font=Enum.Font.GothamSemibold
    btn.TextSize=11 btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)

    local idx=1
    for i,v in ipairs(opts) do if v==Cfg[key] then idx=i break end end

    btn.MouseButton1Click:Connect(function()
        idx=(idx%#opts)+1
        Cfg[key]=opts[idx]
        btn.Text=opts[idx]
        if cb then cb(opts[idx]) end
    end)
end

-- Slider (taller row)
local SL_H = 48
local function addSlider(page, label, key, mn, mx, cb)
    local y = getY(page)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,SL_H) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.panel f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",f) st.Color=T.border st.Thickness=1
    advY(page, SL_H)

    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,-10,0,18) lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1 lbl.Text=label..": "..Cfg[key]
    lbl.TextColor3=T.text lbl.Font=Enum.Font.Gotham lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local track=Instance.new("Frame",f)
    track.Size=UDim2.new(1,-20,0,6) track.Position=UDim2.new(0,10,0,32)
    track.BackgroundColor3=T.sbar track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local pct=(Cfg[key]-mn)/(mx-mn)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(pct,0,1,0)
    fill.BackgroundColor3=T.accent fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12) knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(pct,0,0.5,0)
    knob.BackgroundColor3=Color3.new(1,1,1) knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local sliding=false
    local function upd(x)
        local ax=track.AbsolutePosition.X
        local aw=track.AbsoluteSize.X
        local t=math.clamp((x-ax)/aw,0,1)
        local v=math.floor(mn+t*(mx-mn))
        Cfg[key]=v
        fill.Size=UDim2.new(t,0,1,0)
        knob.Position=UDim2.new(t,0,0.5,0)
        lbl.Text=label..": "..v
        if cb then cb(v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=true upd(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
            upd(i.Position.X)
        end
    end)
end

-- Info label
local function addInfo(page, text)
    local f = baseRow(page)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=text
    l.TextColor3=T.dim l.Font=Enum.Font.Gotham l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left
end

-- ─────────────────────────────────────────────
--  BUILD TABS
-- ─────────────────────────────────────────────
local pgAim = addTab("⚙ Aimbot")
local pgVis = addTab("👁 Visuals")
local pgSet = addTab("🔧 Settings")

-- ── AIMBOT ──
addSection(pgAim,"AIMBOT")
addToggle  (pgAim,"Enable Aimbot",   "AimbotEnabled")
addDropdown(pgAim,"Target Bone",     "AimbotBone",  {"Head","HumanoidRootPart"})
addToggle  (pgAim,"Team Check",      "TeamCheck")
addSection (pgAim,"FOV")
addToggle  (pgAim,"Show FOV Circle", "ShowFOV", function(v)
    FOVCircle.Visible = v and Cfg.AimbotEnabled
end)
addSlider  (pgAim,"Aim FOV",         "AimFOV",  20, 500, function(v)
    FOVCircle.Radius=v
end)
addSlider  (pgAim,"Smoothing",       "AimSmoothing", 1, 20)

-- ── VISUALS ──
addSection (pgVis,"ESP CORE")
addToggle  (pgVis,"Enable ESP",       "ESPEnabled")

addSection (pgVis,"LINE")
addToggle  (pgVis,"ESP Line",         "ESPLine")
addDropdown(pgVis,"Line Origin",      "ESPLinePos", {"Top","Bottom","Side"})

addSection (pgVis,"BOX")
addToggle  (pgVis,"ESP Box",          "ESPBox")

addSection (pgVis,"HEALTH BAR")
addToggle  (pgVis,"Health Bar",       "ESPHealthBar")
addDropdown(pgVis,"Bar Position",     "ESPHealthBarPos",{"Top","Left","Right","Bottom"})

addSection (pgVis,"NAME")
addToggle  (pgVis,"ESP Name",         "ESPName")
addDropdown(pgVis,"Name Position",    "ESPNamePos",{"Top","Bottom"})

addSection (pgVis,"DISTANCE")
addToggle  (pgVis,"ESP Distance",     "ESPDistance")
addDropdown(pgVis,"Distance Position","ESPDistancePos",{"Top","Bottom"})

-- ── SETTINGS ──
addSection (pgSet,"AIMBOT")
addInfo    (pgSet,"Hold Right Mouse Button to aim")
addInfo    (pgSet,"Works without scope — FOV based")

addSection (pgSet,"ESP")
addSlider  (pgSet,"Max Distance",     "MaxDist", 100, 2000)

addSection (pgSet,"ABOUT")
addInfo    (pgSet,"For own-game anticheat testing only")
addInfo    (pgSet,"Drawing API: zero Roblox UI lag")

showTab("⚙ Aimbot")

-- ─────────────────────────────────────────────
--  RENDER LOOP
-- ─────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)

    -- FOV circle
    FOVCircle.Position = center
    FOVCircle.Radius   = Cfg.AimFOV
    FOVCircle.Visible  = Cfg.ShowFOV and Cfg.AimbotEnabled

    -- AIMBOT  (no scope check — works always when RMB held)
    if Cfg.AimbotEnabled
    and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local tPos = getBestTarget()
        if tPos then
            local sp,_,_ = w2s(tPos)
            local delta  = sp - center
            local smooth = math.clamp(Cfg.AimSmoothing,1,20)
            -- Move aim via mousemoverel (Synapse/KRNL/etc)
            if mousemoverel then
                mousemoverel(delta.X/smooth, delta.Y/smooth)
            else
                -- Fallback: rotate camera toward target
                local dir = (tPos - Camera.CFrame.Position).Unit
                local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position+dir)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, 1/smooth)
            end
        end
    end

    -- ESP
    for player, o in pairs(Pool) do
        local show = false
        if Cfg.ESPEnabled and player ~= LocalPlayer then
            local c,r,h,m = getChar(player)
            if c and m.Health > 0 then
                local bonePoints = {"Head","UpperTorso","LowerTorso",
                    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}
                local minX,minY,maxX,maxY = math.huge,math.huge,-math.huge,-math.huge
                local any = false
                for _,bn in ipairs(bonePoints) do
                    local part = c:FindFirstChild(bn) or r
                    local sp,depth,vis = w2s(part.Position)
                    if vis and depth>0 then
                        any=true
                        if sp.X<minX then minX=sp.X end
                        if sp.Y<minY then minY=sp.Y end
                        if sp.X>maxX then maxX=sp.X end
                        if sp.Y>maxY then maxY=sp.Y end
                    end
                end

                local rootSP,rootD,rootVis = w2s(r.Position)
                local dist3 = (Camera.CFrame.Position - r.Position).Magnitude

                if any and dist3<=Cfg.MaxDist then
                    show=true
                    local bx,by = minX-4, minY-4
                    local bw,bh = (maxX-minX)+8, (maxY-minY)+8

                    -- BOX
                    o.box.Visible   = Cfg.ESPBox
                    o.box.Position  = Vector2.new(bx,by)
                    o.box.Size      = Vector2.new(bw,bh)
                    o.box.Color     = Cfg.BoxColor

                    -- LINE
                    o.line.Visible  = Cfg.ESPLine
                    local lineFrom  = center
                    if Cfg.ESPLinePos=="Top" then
                        lineFrom = Vector2.new(center.X, 0)
                    elseif Cfg.ESPLinePos=="Side" then
                        lineFrom = Vector2.new(rootSP.X<center.X and 0 or vp.X, center.Y)
                    end
                    o.line.From  = lineFrom
                    o.line.To    = Vector2.new(bx+bw/2, by+bh)
                    o.line.Color = Cfg.LineColor

                    -- HEALTH BAR
                    local hp   = math.clamp(m.Health/m.MaxHealth,0,1)
                    local BAR_T = 4
                    o.hbg.Visible  = Cfg.ESPHealthBar
                    o.hbar.Visible = Cfg.ESPHealthBar
                    o.hbar.Color   = Color3.fromHSB(hp*0.33,1,1)
                    if Cfg.ESPHealthBarPos=="Left" then
                        o.hbg.Position  = Vector2.new(bx-BAR_T-2, by)
                        o.hbg.Size      = Vector2.new(BAR_T, bh)
                        o.hbar.Position = Vector2.new(bx-BAR_T-2, by+bh*(1-hp))
                        o.hbar.Size     = Vector2.new(BAR_T, bh*hp)
                    elseif Cfg.ESPHealthBarPos=="Right" then
                        o.hbg.Position  = Vector2.new(bx+bw+2, by)
                        o.hbg.Size      = Vector2.new(BAR_T, bh)
                        o.hbar.Position = Vector2.new(bx+bw+2, by+bh*(1-hp))
                        o.hbar.Size     = Vector2.new(BAR_T, bh*hp)
                    elseif Cfg.ESPHealthBarPos=="Top" then
                        o.hbg.Position  = Vector2.new(bx, by-BAR_T-2)
                        o.hbg.Size      = Vector2.new(bw, BAR_T)
                        o.hbar.Position = Vector2.new(bx, by-BAR_T-2)
                        o.hbar.Size     = Vector2.new(bw*hp, BAR_T)
                    else
                        o.hbg.Position  = Vector2.new(bx, by+bh+2)
                        o.hbg.Size      = Vector2.new(bw, BAR_T)
                        o.hbar.Position = Vector2.new(bx, by+bh+2)
                        o.hbar.Size     = Vector2.new(bw*hp, BAR_T)
                    end

                    -- NAME
                    o.name.Visible  = Cfg.ESPName
                    o.name.Text     = player.Name
                    o.name.Position = Cfg.ESPNamePos=="Top"
                        and Vector2.new(bx+bw/2, by-15)
                        or  Vector2.new(bx+bw/2, by+bh+2)

                    -- DISTANCE
                    local nameOff = (Cfg.ESPName and Cfg.ESPNamePos=="Bottom") and 14 or 0
                    o.dist.Visible  = Cfg.ESPDistance
                    o.dist.Text     = math.floor(dist3).."m"
                    o.dist.Position = Cfg.ESPDistancePos=="Top"
                        and Vector2.new(bx+bw/2, by-(Cfg.ESPName and Cfg.ESPNamePos=="Top" and 28 or 15))
                        or  Vector2.new(bx+bw/2, by+bh+2+nameOff)
                end
            end
        end
        if not show then
            for _,d in pairs(o) do d.Visible=false end
        end
    end
end)

print("[ACMenu] Loaded — RMB to aim, no scope needed")
