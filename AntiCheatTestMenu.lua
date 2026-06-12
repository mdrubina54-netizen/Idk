-- ================================================
--   AntiCheat Test Menu v3
--   Fixed: ESP (R6+R15), Aimbot toggle (no hold)
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
    AimSmoothing    = 8,

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
}

-- ─────────────────────────────────────────────
--  DRAWING OBJECTS PER PLAYER
-- ─────────────────────────────────────────────
local Pool = {}

local FOVCircle     = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color     = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled    = false
FOVCircle.NumSides  = 64
FOVCircle.Radius    = Cfg.AimFOV
FOVCircle.Visible   = false

local function newDraw(t, props)
    local d = Drawing.new(t)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function initESP(p)
    if Pool[p] then return end
    Pool[p] = {
        box  = newDraw("Square", {Visible=false, Filled=false, Thickness=1, Color=Color3.fromRGB(255,255,255)}),
        line = newDraw("Line",   {Visible=false, Thickness=1,  Color=Color3.fromRGB(0,200,255)}),
        hbg  = newDraw("Square", {Visible=false, Filled=true,  Thickness=1, Color=Color3.fromRGB(30,30,30)}),
        hbar = newDraw("Square", {Visible=false, Filled=true,  Thickness=1, Color=Color3.fromRGB(0,255,80)}),
        name = newDraw("Text",   {Visible=false, Size=13, Color=Color3.fromRGB(255,255,255), Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
        dist = newDraw("Text",   {Visible=false, Size=12, Color=Color3.fromRGB(255,255,200), Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
    }
end

local function removeESP(p)
    if not Pool[p] then return end
    for _, d in pairs(Pool[p]) do pcall(function() d:Remove() end) end
    Pool[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then initESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    initESP(p)
    p.CharacterAdded:Connect(function() task.wait(1) initESP(p) end)
end)
Players.PlayerRemoving:Connect(removeESP)

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────
local function w2s(pos)
    local sp, depth, vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), depth, vis
end

-- Works for BOTH R6 and R15
local function getCharInfo(p)
    local char = p.Character
    if not char then return nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not root or not head then return nil end
    return char, root, head, hum
end

-- Get screen bounding box that works on R6 and R15
local function getScreenBounds(char, root)
    -- Collect all BaseParts
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local found = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local sp, depth, vis = w2s(part.Position)
            if vis and depth > 0 then
                found = true
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
            end
        end
    end
    -- fallback: just use root
    if not found then
        local sp, depth, vis = w2s(root.Position)
        if vis and depth > 0 then
            return sp.X-20, sp.Y-40, sp.X+20, sp.Y+40, true
        end
        return 0,0,0,0,false
    end
    return minX, minY, maxX, maxY, true
end

-- ─────────────────────────────────────────────
--  AIMBOT
-- ─────────────────────────────────────────────
local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local bestDist, bestPos = math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if Cfg.TeamCheck and p.Team == LocalPlayer.Team then continue end
        local char, root, head, hum = getCharInfo(p) or (nil,nil,nil,nil)
        if not char then continue end
        if hum.Health <= 0 then continue end
        local bone = (Cfg.AimbotBone == "Head") and head or root
        local sp, depth, vis = w2s(bone.Position)
        if not vis or depth <= 0 then continue end
        local d = (sp - center).Magnitude
        if d < Cfg.AimFOV and d < bestDist then
            bestDist = d
            bestPos  = bone.Position
        end
    end
    return bestPos
end

-- ─────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────
local T = {
    bg      = Color3.fromRGB(14,14,20),
    bar     = Color3.fromRGB(22,22,32),
    panel   = Color3.fromRGB(20,20,28),
    border  = Color3.fromRGB(55,55,80),
    accent  = Color3.fromRGB(110,65,220),
    accentH = Color3.fromRGB(140,90,255),
    text    = Color3.fromRGB(225,225,240),
    dim     = Color3.fromRGB(120,120,150),
    ton     = Color3.fromRGB(100,60,210),
    toff    = Color3.fromRGB(45,45,65),
    close   = Color3.fromRGB(200,50,55),
    mini    = Color3.fromRGB(190,150,25),
    slbg    = Color3.fromRGB(35,35,55),
}

-- ─────────────────────────────────────────────
--  SCREEN GUI
-- ─────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "ACMenuV3"
SG.ResetOnSpawn   = false
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local WIN = Instance.new("Frame", SG)
WIN.Size             = UDim2.new(0,430,0,380)
WIN.Position         = UDim2.new(0.5,-215,0.5,-190)
WIN.BackgroundColor3 = T.bg
WIN.BorderSizePixel  = 0
WIN.ClipsDescendants = false
Instance.new("UICorner",WIN).CornerRadius = UDim.new(0,8)
local ws=Instance.new("UIStroke",WIN) ws.Color=T.border ws.Thickness=1.5

-- Title bar
local BAR = Instance.new("Frame",WIN)
BAR.Size=UDim2.new(1,0,0,32) BAR.BackgroundColor3=T.bar BAR.BorderSizePixel=0
Instance.new("UICorner",BAR).CornerRadius=UDim.new(0,8)
local cov=Instance.new("Frame",BAR)
cov.Size=UDim2.new(1,0,0,8) cov.Position=UDim2.new(0,0,1,-8)
cov.BackgroundColor3=T.bar cov.BorderSizePixel=0

local TITLE=Instance.new("TextLabel",BAR)
TITLE.Size=UDim2.new(1,-80,1,0) TITLE.Position=UDim2.new(0,10,0,0)
TITLE.BackgroundTransparency=1 TITLE.Text="  ⚔  AntiCheat Test Menu v3"
TITLE.TextColor3=T.text TITLE.Font=Enum.Font.GothamBold TITLE.TextSize=13
TITLE.TextXAlignment=Enum.TextXAlignment.Left

local function mkBtn(xOff, bg, lbl)
    local b=Instance.new("TextButton",BAR)
    b.Size=UDim2.new(0,22,0,18) b.Position=UDim2.new(1,xOff,0.5,-9)
    b.BackgroundColor3=bg b.Text=lbl b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold b.TextSize=11 b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    return b
end
local CBTN=mkBtn(-6, T.close,"✕")
local MBTN=mkBtn(-32,T.mini, "─")

-- Drag
local drag,dragOrig,mOrig
BAR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true dragOrig=WIN.Position mOrig=i.Position
    end
end)
BAR.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-mOrig
        WIN.Position=UDim2.new(dragOrig.X.Scale,dragOrig.X.Offset+d.X,
                               dragOrig.Y.Scale,dragOrig.Y.Offset+d.Y)
    end
end)

local minimized=false
MBTN.MouseButton1Click:Connect(function()
    minimized=not minimized
    WIN.Size=minimized and UDim2.new(0,430,0,32) or UDim2.new(0,430,0,380)
    WIN.ClipsDescendants=minimized
end)
CBTN.MouseButton1Click:Connect(function()
    pcall(function() FOVCircle:Remove() end)
    for p in pairs(Pool) do removeESP(p) end
    SG:Destroy()
end)

-- Tab row
local TABROW=Instance.new("Frame",WIN)
TABROW.Size=UDim2.new(1,-16,0,28) TABROW.Position=UDim2.new(0,8,0,36)
TABROW.BackgroundTransparency=1 TABROW.BorderSizePixel=0

-- Clip + scroll area
local CLIP=Instance.new("Frame",WIN)
CLIP.Size=UDim2.new(1,-16,1,-76) CLIP.Position=UDim2.new(0,8,0,70)
CLIP.BackgroundTransparency=1 CLIP.BorderSizePixel=0
CLIP.ClipsDescendants=true

-- ─────────────────────────────────────────────
--  TAB SYSTEM
-- ─────────────────────────────────────────────
local TABS={} local TABBTNS={} local TAB_ORDER={}
local TAB_W=130

local function showTab(name)
    for n,p in pairs(TABS) do p.Visible=(n==name) end
    for n,b in pairs(TABBTNS) do
        b.BackgroundColor3=(n==name) and T.accent or T.bar
        b.TextColor3=(n==name) and Color3.new(1,1,1) or T.dim
    end
end

local function addTab(name)
    local idx=#TAB_ORDER
    table.insert(TAB_ORDER,name)
    local btn=Instance.new("TextButton",TABROW)
    btn.Size=UDim2.new(0,TAB_W,1,0) btn.Position=UDim2.new(0,idx*(TAB_W+4),0,0)
    btn.BackgroundColor3=T.bar btn.Text=name btn.TextColor3=T.dim
    btn.Font=Enum.Font.GothamSemibold btn.TextSize=12 btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local sf=Instance.new("ScrollingFrame",CLIP)
    sf.Size=UDim2.new(1,0,1,0) sf.BackgroundTransparency=1 sf.BorderSizePixel=0
    sf.ScrollBarThickness=4 sf.ScrollBarImageColor3=T.accent
    sf.CanvasSize=UDim2.new(0,0,0,0) sf.Visible=false
    TABS[name]=sf TABBTNS[name]=btn
    btn.MouseButton1Click:Connect(function() showTab(name) end)
    return sf
end

-- ─────────────────────────────────────────────
--  COMPONENT BUILDERS
-- ─────────────────────────────────────────────
local IH=30 local SH=24 local SLTH=50 local PAD=6
local cursors={}
local function cy(page) cursors[page]=cursors[page] or PAD return cursors[page] end
local function ay(page,h) cursors[page]=(cursors[page] or PAD)+h+4 page.CanvasSize=UDim2.new(0,0,0,cursors[page]+10) end

local function addSection(page,lbl)
    local y=cy(page)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,SH) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.accent f.BackgroundTransparency=0.78 f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-12,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=lbl l.TextColor3=T.accentH
    l.Font=Enum.Font.GothamBold l.TextSize=11 l.TextXAlignment=Enum.TextXAlignment.Left
    ay(page,SH)
end

local function baseRow(page)
    local y=cy(page)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,IH) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.panel f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",f) st.Color=T.border st.Thickness=1
    ay(page,IH)
    return f
end

local function rlabel(f,txt)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-60,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=T.text
    l.Font=Enum.Font.Gotham l.TextSize=12 l.TextXAlignment=Enum.TextXAlignment.Left
end

local function addToggle(page,lbl,key,cb)
    local f=baseRow(page)
    rlabel(f,lbl)
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

local function addDropdown(page,lbl,key,opts,cb)
    local f=baseRow(page)
    rlabel(f,lbl)
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
        Cfg[key]=opts[idx] btn.Text=opts[idx]
        if cb then cb(opts[idx]) end
    end)
end

local function addSlider(page,lbl,key,mn,mx,cb)
    local y=cy(page)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,-4,0,SLTH) f.Position=UDim2.new(0,2,0,y)
    f.BackgroundColor3=T.panel f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local st=Instance.new("UIStroke",f) st.Color=T.border st.Thickness=1
    ay(page,SLTH)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,0,18) l.Position=UDim2.new(0,10,0,4)
    l.BackgroundTransparency=1 l.Text=lbl..": "..Cfg[key]
    l.TextColor3=T.text l.Font=Enum.Font.Gotham l.TextSize=12
    l.TextXAlignment=Enum.TextXAlignment.Left
    local track=Instance.new("Frame",f)
    track.Size=UDim2.new(1,-20,0,6) track.Position=UDim2.new(0,10,0,34)
    track.BackgroundColor3=T.slbg track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local pct=(Cfg[key]-mn)/(mx-mn)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(pct,0,1,0) fill.BackgroundColor3=T.accent fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12) knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(pct,0,0.5,0)
    knob.BackgroundColor3=Color3.new(1,1,1) knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local sliding=false
    local function upd(x)
        local t=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(mn+t*(mx-mn))
        Cfg[key]=v fill.Size=UDim2.new(t,0,1,0) knob.Position=UDim2.new(t,0,0.5,0)
        l.Text=lbl..": "..v if cb then cb(v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
end

local function addInfo(page,txt)
    local f=baseRow(page)
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-10,1,0) l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=T.dim
    l.Font=Enum.Font.Gotham l.TextSize=11 l.TextXAlignment=Enum.TextXAlignment.Left
end

-- ─────────────────────────────────────────────
--  POPULATE TABS
-- ─────────────────────────────────────────────
local pgAim = addTab("⚙ Aimbot")
local pgVis = addTab("👁 Visuals")
local pgSet = addTab("🔧 Settings")

-- AIMBOT
addSection(pgAim,"AIMBOT")
addToggle  (pgAim,"Enable Aimbot",   "AimbotEnabled")
addDropdown(pgAim,"Target Bone",     "AimbotBone", {"Head","HumanoidRootPart"})
addToggle  (pgAim,"Team Check",      "TeamCheck")
addSection (pgAim,"FOV")
addToggle  (pgAim,"Show FOV Circle", "ShowFOV", function(v)
    FOVCircle.Visible = v and Cfg.AimbotEnabled
end)
addSlider  (pgAim,"Aim FOV",         "AimFOV",      20, 500, function(v) FOVCircle.Radius=v end)
addSlider  (pgAim,"Smoothing (low=fast)","AimSmoothing", 1, 20)
addSection (pgAim,"INFO")
addInfo    (pgAim,"Aimbot is TOGGLE — no holding needed")
addInfo    (pgAim,"Works without scope, R6 and R15")

-- VISUALS
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

-- SETTINGS
addSection (pgSet,"AIMBOT")
addSlider  (pgSet,"Max FOV",          "AimFOV",     20, 500)
addSlider  (pgSet,"Smoothing",        "AimSmoothing",1, 20)
addSection (pgSet,"ESP")
addSlider  (pgSet,"Max Distance (studs)","MaxDist", 100, 2000)
addSection (pgSet,"ABOUT")
addInfo    (pgSet,"ESP uses all BaseParts — works R6+R15")
addInfo    (pgSet,"For own-game anticheat testing only")

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

    -- AIMBOT — toggle, no hold required
    if Cfg.AimbotEnabled then
        local tPos = getBestTarget()
        if tPos then
            local sp, _, vis = w2s(tPos)
            if vis then
                local delta  = sp - center
                local smooth = math.max(Cfg.AimSmoothing, 1)
                if mousemoverel then
                    mousemoverel(delta.X / smooth, delta.Y / smooth)
                else
                    -- camera lerp fallback
                    local dir = (tPos - Camera.CFrame.Position).Unit
                    local goal = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
                    Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / smooth)
                end
            end
        end
    end

    -- ESP
    for player, o in pairs(Pool) do
        local show = false
        if Cfg.ESPEnabled and player ~= LocalPlayer then
            local char, root, head, hum = getCharInfo(player) or (nil,nil,nil,nil)
            if char and hum and hum.Health > 0 then
                local minX,minY,maxX,maxY,found = getScreenBounds(char, root)
                local rootSP, rootD, rootVis = w2s(root.Position)
                local dist3 = (Camera.CFrame.Position - root.Position).Magnitude

                if found and dist3 <= Cfg.MaxDist then
                    show = true
                    local pad = 4
                    local bx = minX - pad
                    local by = minY - pad
                    local bw = (maxX - minX) + pad*2
                    local bh = (maxY - minY) + pad*2

                    -- BOX
                    o.box.Visible  = Cfg.ESPBox
                    o.box.Position = Vector2.new(bx, by)
                    o.box.Size     = Vector2.new(bw, bh)

                    -- LINE
                    o.line.Visible = Cfg.ESPLine
                    local lFrom = center
                    if Cfg.ESPLinePos == "Top" then
                        lFrom = Vector2.new(center.X, 0)
                    elseif Cfg.ESPLinePos == "Side" then
                        lFrom = Vector2.new(rootSP.X < center.X and 0 or vp.X, center.Y)
                    end
                    o.line.From = lFrom
                    o.line.To   = Vector2.new(bx + bw/2, by + bh)

                    -- HEALTH BAR
                    local hp  = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local BT  = 4
                    o.hbg.Visible  = Cfg.ESPHealthBar
                    o.hbar.Visible = Cfg.ESPHealthBar
                    o.hbar.Color   = Color3.fromHSB(hp * 0.33, 1, 1)
                    if Cfg.ESPHealthBarPos == "Left" then
                        o.hbg.Position  = Vector2.new(bx-BT-2, by)
                        o.hbg.Size      = Vector2.new(BT, bh)
                        o.hbar.Position = Vector2.new(bx-BT-2, by + bh*(1-hp))
                        o.hbar.Size     = Vector2.new(BT, bh*hp)
                    elseif Cfg.ESPHealthBarPos == "Right" then
                        o.hbg.Position  = Vector2.new(bx+bw+2, by)
                        o.hbg.Size      = Vector2.new(BT, bh)
                        o.hbar.Position = Vector2.new(bx+bw+2, by + bh*(1-hp))
                        o.hbar.Size     = Vector2.new(BT, bh*hp)
                    elseif Cfg.ESPHealthBarPos == "Top" then
                        o.hbg.Position  = Vector2.new(bx, by-BT-2)
                        o.hbg.Size      = Vector2.new(bw, BT)
                        o.hbar.Position = Vector2.new(bx, by-BT-2)
                        o.hbar.Size     = Vector2.new(bw*hp, BT)
                    else -- Bottom
                        o.hbg.Position  = Vector2.new(bx, by+bh+2)
                        o.hbg.Size      = Vector2.new(bw, BT)
                        o.hbar.Position = Vector2.new(bx, by+bh+2)
                        o.hbar.Size     = Vector2.new(bw*hp, BT)
                    end

                    -- NAME
                    o.name.Visible  = Cfg.ESPName
                    o.name.Text     = player.Name
                    o.name.Position = Cfg.ESPNamePos == "Top"
                        and Vector2.new(bx+bw/2, by-15)
                        or  Vector2.new(bx+bw/2, by+bh+2)

                    -- DISTANCE
                    local nameOff = (Cfg.ESPName and Cfg.ESPNamePos == "Bottom") and 14 or 0
                    o.dist.Visible  = Cfg.ESPDistance
                    o.dist.Text     = math.floor(dist3).."m"
                    o.dist.Position = Cfg.ESPDistancePos == "Top"
                        and Vector2.new(bx+bw/2, by - (Cfg.ESPName and Cfg.ESPNamePos=="Top" and 28 or 15))
                        or  Vector2.new(bx+bw/2, by+bh+2+nameOff)
                end
            end
        end
        if not show then
            for _, d in pairs(o) do d.Visible = false end
        end
    end
end)

print("[ACMenu v3] Loaded — ESP fixed, Aimbot is toggle (no hold)")
