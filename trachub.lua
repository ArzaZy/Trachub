--[[
═══════════════════════════════════════════════════════════════════
  TracHub v2.0.0 — Stable UI Edition
  Fixed UI rendering bug on Android. Pixel-perfect layout.
═══════════════════════════════════════════════════════════════════
--]]

if getgenv and getgenv().TracHub_Loaded then
    pcall(function() game.Players.LocalPlayer.PlayerGui.TracHubUI:Destroy() end)
    pcall(function() game:GetService("CoreGui").TracHubUI:Destroy() end)
end
if getgenv then getgenv().TracHub_Loaded = true end

--==== SERVICES ====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

--==== THEME ====
local Theme = {
    BgMain = Color3.fromRGB(18, 18, 24),
    BgSidebar = Color3.fromRGB(24, 24, 32),
    BgCard = Color3.fromRGB(30, 30, 42),
    Accent = Color3.fromRGB(168, 85, 247),
    Accent2 = Color3.fromRGB(56, 189, 248),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextSub = Color3.fromRGB(161, 161, 170),
    Danger = Color3.fromRGB(239, 68, 68),
    Success = Color3.fromRGB(34, 197, 94),
    
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontCode = Enum.Font.Code,
}

local Cleanup = { Instances={}, Connections={} }
local function track(i) table.insert(Cleanup.Instances, i); return i end
local function trackConn(c) table.insert(Cleanup.Connections, c); return c end

--==== BUILDER ====
local function new(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return track(i)
end
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.BgCard; s.Thickness = th or 1; s.Transparency = tr or 0.3
    s.Parent = p; return s
end

--==== NOTIFICATIONS ====
local Notif = { Container = nil }
function Notif.Init(parent)
    local c = new("Frame", { BackgroundTransparency=1, Size=UDim2.new(0,260,1,-80),
        Position=UDim2.new(1,-16,0,60), AnchorPoint=Vector2.new(1,0), ZIndex=900 }, parent)
    local l = Instance.new("UIListLayout", { Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, Parent=c })
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    Notif.Container = c
end
function Notif.Push(title, msg, kind)
    if not Notif.Container then return end
    local accent = Theme.Accent
    if kind == "success" then accent = Theme.Success elseif kind == "error" then accent = Theme.Danger end
    
    local card = new("Frame", { BackgroundColor3=Theme.BgCard, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true, Position=UDim2.new(1,40,0,0), ZIndex=901 }, Notif.Container)
    corner(card, 8); stroke(card, accent, 1.5, 0.2)
    
    new("Frame", { BackgroundColor3=accent, BorderSizePixel=0,
        Size=UDim2.new(0,4,1,-16), Position=UDim2.new(0,6,0,8) }, card)
    new("TextLabel", { BackgroundTransparency=1, Text=title, Font=Theme.FontBold,
        TextSize=13, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-20,0,16), Position=UDim2.new(0,16,0,8) }, card)
    new("TextLabel", { BackgroundTransparency=1, Text=msg, Font=Theme.FontMain, TextSize=12,
        TextColor3=Theme.TextSub, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-20,0,0), AutomaticSize=Enum.AutomaticSize.Y, Position=UDim2.new(0,16,0,26) }, card)
    
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Position=UDim2.new(0,0,0,0)}):Play()
    task.delay(3.5, function()
        if not card.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency=1, Position=UDim2.new(1,40,0,0)}):Play()
        task.delay(0.25, function() card:Destroy() end)
    end)
end

--==== UI COMPONENTS ====
local UI = {}

function UI.Card(parent, title)
    local card = new("Frame", { BackgroundColor3=Theme.BgCard, Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y, BorderSizePixel=0, ClipsDescendants=true }, parent)
    corner(card, 10)
    
    local topBar = new("Frame", { BackgroundColor3=Theme.BgMain, Size=UDim2.new(1,0,0,30),
        BorderSizePixel=0 }, card)
    corner(topBar, 10)
    new("Frame", { BackgroundColor3=Theme.BgMain, Size=UDim2.new(1,0,0,15),
        Position=UDim2.new(0,0,1,-15), BorderSizePixel=0 }, topBar)
        
    new("TextLabel", { BackgroundTransparency=1, Text=title, Font=Theme.FontBold,
        TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0) }, topBar)
    
    local inner = new("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,-20,0,0),
        Position=UDim2.fromOffset(10,10), AutomaticSize=Enum.AutomaticSize.Y }, card)
    Instance.new("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, Parent=inner})
    Instance.new("UIPadding", {PaddingTop=UDim.new(0,30), PaddingBottom=UDim.new(0,10), Parent=inner})
    
    return inner
end

function UI.Label(parent, text, color)
    return new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y, Text=text, Font=Theme.FontMain, TextSize=12,
        TextColor3=color or Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true }, parent)
end

function UI.Row(parent, label, value)
    local row = new("Frame", { Size=UDim2.new(1,0,0,20), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local v = new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0),
        Position=UDim2.new(0.5,0,0,0), Text=tostring(value), Font=Theme.FontCode, TextSize=12,
        TextColor3=Theme.Accent2, TextXAlignment=Enum.TextXAlignment.Right }, row)
    return v
end

function UI.Button(parent, label, onClick, isDanger, isPrimary)
    local bg = Theme.BgMain
    if isDanger then bg = Theme.Danger elseif isPrimary then bg = Theme.Accent end
    local b = new("TextButton", { BackgroundColor3=bg, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,32), Text=label, Font=Theme.FontBold, TextSize=12,
        TextColor3=Theme.TextMain, AutoButtonColor=false }, parent)
    corner(b, 6)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(onClick)
        if not ok then Notif.Push("Error", tostring(err), "error") end
    end)
    return b
end

function UI.Toggle(parent, label, defaultState, onChange)
    local state = { Value = defaultState or false }
    local row = new("Frame", { Size=UDim2.new(1,0,0,28), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,-45,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
        
    local track = new("Frame", { Size=UDim2.fromOffset(36,20), Position=UDim2.new(1,-36,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=defaultState and Theme.Accent or Theme.BgMain, BorderSizePixel=0 }, row)
    corner(track, 10)
    
    local knob = new("Frame", { Size=UDim2.fromOffset(14,14),
        Position=defaultState and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=Theme.TextMain, BorderSizePixel=0 }, track)
    corner(knob, 7)
    
    local hit = new("TextButton", { BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Text="" }, track)
    hit.MouseButton1Click:Connect(function()
        state.Value = not state.Value
        local tc = state.Value and Theme.Accent or Theme.BgMain
        local tp = state.Value and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3)
        TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3=tc}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position=tp}):Play()
        if onChange then pcall(onChange, state.Value) end
    end)
    return state
end

function UI.Slider(parent, label, minV, maxV, default, onChange)
    local state = { Value = default or minV }
    local row = new("Frame", { Size=UDim2.new(1,0,0,45), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.7,0,0,16), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local vlbl = new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.3,0,0,16),
        Position=UDim2.new(0.7,0,0,0), Text=string.format("%.1f", default or minV),
        Font=Theme.FontCode, TextSize=12, TextColor3=Theme.Accent2, TextXAlignment=Enum.TextXAlignment.Right }, row)
        
    local track = new("Frame", { Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,25),
        BackgroundColor3=Theme.BgMain, BorderSizePixel=0 }, row)
    corner(track, 3)
    
    local fill = new("Frame", { Size=UDim2.fromScale(((default or minV)-minV)/(maxV-minV),1),
        BackgroundColor3=Theme.Accent, BorderSizePixel=0 }, track)
    corner(fill, 3)
    
    local knob = new("Frame", { Size=UDim2.fromOffset(12,12), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(((default or minV)-minV)/(maxV-minV),0,0.5,0),
        BackgroundColor3=Theme.TextMain, BorderSizePixel=0 }, track)
    corner(knob, 6)
    
    local hit = new("TextButton", { Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundTransparency=1, Text="" }, track)
        
    local function setVal(v)
        v = math.clamp(v, minV, maxV); state.Value = v
        vlbl.Text = string.format("%.1f", v)
        local rel = (v-minV)/(maxV-minV)
        fill.Size = UDim2.fromScale(rel,1)
        knob.Position = UDim2.new(rel,0,0.5,0)
        if onChange then pcall(onChange, v) end
    end
    
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X,1), 0, 1)
            setVal(minV + (maxV-minV)*rel)
            local mc, ec
            mc = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    local r2 = math.clamp((inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X,1), 0, 1)
                    setVal(minV + (maxV-minV)*r2)
                end
            end)
            ec = UserInputService.InputEnded:Connect(function(inp)
                if inp == input then mc:Disconnect(); ec:Disconnect() end
            end)
        end
    end)
    return state
end

function UI.Dropdown(parent, label, options, default, onChange)
    local state = { Value = default or options[1] }
    local row = new("Frame", { Size=UDim2.new(1,0,0,30), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local btn = new("TextButton", { Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
        BackgroundColor3=Theme.BgMain, BorderSizePixel=0, Text=" "..state.Value,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, AutoButtonColor=false }, row)
    corner(btn, 6)
    local list
    local function close() if list then list:Destroy(); list = nil end end
    btn.MouseButton1Click:Connect(function()
        if list then close(); return end
        list = new("Frame", { Size=UDim2.new(1,0,0,#options*26), Position=UDim2.new(0,0,1,4),
            BackgroundColor3=Theme.BgCard, BorderSizePixel=0, ZIndex=100 }, btn)
        corner(list, 6); stroke(list, Theme.BgMain, 1, 0.2)
        for i,opt in ipairs(options) do
            local o = new("TextButton", { Size=UDim2.new(1,0,0,26),
                Position=UDim2.new(0,0,0,(i-1)*26), BackgroundColor3=Theme.BgCard,
                BorderSizePixel=0, Text=" "..opt, Font=Theme.FontMain, TextSize=12,
                TextColor3=Theme.TextMain, AutoButtonColor=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=101 }, list)
            o.MouseButton1Click:Connect(function()
                state.Value = opt; btn.Text = " "..opt; close()
                if onChange then pcall(onChange, opt) end
            end)
        end
    end)
    return state
end

--==== ROOT GUI ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TracHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local attached = pcall(function() ScreenGui.Parent = CoreGui end)
if not attached then ScreenGui.Parent = PlayerGui end

Notif.Init(ScreenGui)

--==== MAIN WINDOW (FIXED SIZE) ====
local Main = new("Frame", { Name="Main", Size=UDim2.fromOffset(600, 380),
    Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Theme.BgMain, BorderSizePixel=0, ClipsDescendants=true }, ScreenGui)
corner(Main, 12)
stroke(Main, Theme.Accent, 1.5, 0.6)

-- Responsive
local function applyScale()
    local cam = Workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        local scale = math.clamp(math.min(vp.X/650, vp.Y/450), 0.65, 1)
        Main.Size = UDim2.fromOffset(600*scale, 380*scale)
    end
end
applyScale()
trackConn(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))

-- Title Bar
local TitleBar = new("Frame", { Size=UDim2.new(1,0,0,40), BackgroundColor3=Theme.BgSidebar,
    BorderSizePixel=0 }, Main)
corner(TitleBar, 12)
new("Frame", { Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20),
    BackgroundColor3=Theme.BgSidebar, BorderSizePixel=0 }, TitleBar)
    
new("Frame", { Size=UDim2.fromOffset(10,10), Position=UDim2.fromOffset(12,15),
    BackgroundColor3=Theme.Accent, BorderSizePixel=0 }, TitleBar)
new("TextLabel", { BackgroundTransparency=1, Position=UDim2.fromOffset(30,0),
    Size=UDim2.fromOffset(100,40), Text="TracHub", Font=Theme.FontBold, TextSize=14,
    TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, TitleBar)
new("TextLabel", { BackgroundTransparency=1, Position=UDim2.fromOffset(100,0),
    Size=UDim2.fromOffset(40,40), Text="v2.0", Font=Theme.FontMain, TextSize=11,
    TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left }, TitleBar)

-- Minimize & Close
local ctrl = new("Frame", { Size=UDim2.fromOffset(70,40), Position=UDim2.new(1,-70,0,0), BackgroundTransparency=1 }, TitleBar)
local function wBtn(t, x, c)
    local b = new("TextButton", { Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,x,0.5,0),
        AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=Theme.BgCard, BorderSizePixel=0,
        Text=t, Font=Theme.FontBold, TextSize=16, TextColor3=c }, ctrl)
    corner(b, 4); return b
end
local cBtn = wBtn("×", -8, Theme.Danger)
local mBtn = wBtn("—", -36, Theme.TextSub)

-- Draggable
local drag, dStart, sPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; dStart = i.Position; sPos = Main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
end)
trackConn(UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
    end
end))

-- Floating Button
local FloatBtn = new("TextButton", { Size=UDim2.fromOffset(46,46), Position=UDim2.new(1,-60,0,60),
    BackgroundColor3=Theme.Accent, BorderSizePixel=0, Text="T", Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Theme.TextMain, Visible=false }, ScreenGui)
corner(FloatBtn, 23); stroke(FloatBtn, Theme.TextMain, 1.5, 0.8)
FloatBtn.MouseButton1Click:Connect(function() Main.Visible = true; FloatBtn.Visible = false end)
cBtn.MouseButton1Click:Connect(function() Main.Visible = false; FloatBtn.Visible = true end)
mBtn.MouseButton1Click:Connect(function() Main.Visible = false; FloatBtn.Visible = true end)

--==== SIDEBAR & CONTENT ====
local Sidebar = new("Frame", { Size=UDim2.new(0,120,1,-40), Position=UDim2.new(0,0,0,40),
    BackgroundColor3=Theme.BgSidebar, BorderSizePixel=0 }, Main)
new("Frame", { Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,0,0,0), BackgroundColor3=Theme.BgCard }, Sidebar)

-- Kunci posisi sidebar pakai UIListLayout + Padding
Instance.new("UIListLayout", { Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder, Parent=Sidebar })
Instance.new("UIPadding", { PaddingTop=UDim.new(0,8), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), Parent=Sidebar })

local Content = new("Frame", { Size=UDim2.new(1,-120,1,-40), Position=UDim2.new(0,120,0,40), BackgroundTransparency=1 }, Main)
local Pages, TabBtns = {}, {}

local function makeTab(name, order)
    -- Gunakan TextLabel di dalam TextButton agar text tidak tabrakan dengan layout
    local btn = new("TextButton", { Size=UDim2.new(1,0,0,34), BackgroundColor3=Theme.BgSidebar,
        BackgroundTransparency=1, BorderSizePixel=0, Text="", AutoButtonColor=false, LayoutOrder=order }, Sidebar)
    corner(btn, 6)
    
    local lbl = new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,-10,1,0),
        Position=UDim2.fromOffset(10,0), Text=name, Font=Theme.FontMain, TextSize=12,
        TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left }, btn)
    
    local page = new("ScrollingFrame", { Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=2, ScrollBarImageColor3=Theme.Accent,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=false }, Content)
    Instance.new("UIPadding", { PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12), Parent=page })
    Instance.new("UIListLayout", { Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder, Parent=page })
    
    Pages[name] = page
    TabBtns[name] = { btn = btn, lbl = lbl }
    
    btn.MouseButton1Click:Connect(function()
        for n, t in pairs(TabBtns) do
            local active = (n == name)
            TweenService:Create(t.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = active and Theme.Accent or Theme.BgSidebar,
                BackgroundTransparency = active and 0 or 1
            }):Play()
            t.lbl.TextColor3 = active and Theme.TextMain or Theme.TextSub
            Pages[n].Visible = active
        end
    end)
    return page
end

--==== TAB 1: HOME ====
local HomeP = makeTab("Home", 1)
local c1 = UI.Card(HomeP, "Information")
UI.Row(c1, "Version", "2.0.0")
UI.Row(c1, "Executor", (typeof(identifyexecutor)=="function") and identifyexecutor() or "Unknown")
UI.Row(c1, "PlaceId", tostring(game.PlaceId))
UI.Row(c1, "JobId", game.JobId ~= "" and game.JobId or "Private")

--==== TAB 2: PLAYER ====
local PlayerP = makeTab("Player", 2)
local c2 = UI.Card(PlayerP, "Character Stats")
local healthR = UI.Row(c2, "Health", "100")
local speedR = UI.Row(c2, "WalkSpeed", "16.0")
local jumpR = UI.Row(c2, "JumpPower", "50.0")

local function getHum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") or nil end
local function refresh()
    local h = getHum()
    if h then
        healthR.Text = string.format("%d", h.Health)
        speedR.Text = string.format("%.1f", h.WalkSpeed)
        jumpR.Text = string.format("%.1f", h.JumpPower)
    end
end
trackConn(LocalPlayer.CharacterAdded:Connect(function() task.wait(1); refresh() end))
UI.Button(c2, "Refresh Stats", refresh)

local c3 = UI.Card(PlayerP, "Modifications")
UI.Slider(c3, "WalkSpeed", 16, 200, 16, function(v) local h=getHum(); if h then h.WalkSpeed=v end end)
UI.Slider(c3, "JumpPower", 50, 200, 50, function(v) local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end)
UI.Button(c3, "Reset Character", function() local h=getHum(); if h then h.Health=0 end end, true)

--==== TAB 3: MOVEMENT ====
local MoveP = makeTab("Movement", 3)
local c4 = UI.Card(MoveP, "Fly (WASD/Space)")
local flyS = { Active=false, BV=nil, Conn=nil, Speed=60 }
UI.Toggle(c4, "Enable Fly", false, function(on)
    if on then
        local c = LocalPlayer.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyS.Active = true
        local h = getHum(); if h then h.PlatformStand = true end
        local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = hrp; flyS.BV = bv
        flyS.Conn = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera; local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            bv.Velocity = move * flyS.Speed
        end)
    else
        if flyS.Conn then flyS.Conn:Disconnect() end
        if flyS.BV then flyS.BV:Destroy() end
        local h = getHum(); if h then h.PlatformStand = false end
    end
end)
UI.Slider(c4, "Fly Speed", 20, 300, 60, function(v) flyS.Speed = v end)

local c5 = UI.Card(MoveP, "Noclip")
local noclipConn
UI.Toggle(c5, "Enable Noclip", false, function(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then for _,v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end end
        end)
    else if noclipConn then noclipConn:Disconnect() end end
end)

--==== TAB 4: VISUAL ====
local VisP = makeTab("Visual", 4)
local c6 = UI.Card(VisP, "Lighting & Camera")
local origL = { Ambient=Lighting.Ambient, Brightness=Lighting.Brightness }
UI.Toggle(c6, "Fullbright", false, function(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.Brightness = 2
    else for k,v in pairs(origL) do pcall(function() Lighting[k]=v end) end end
end)
local cam = Workspace.CurrentCamera
UI.Slider(c6, "Field of View", 40, 120, cam.FieldOfView, function(v) if cam then cam.FieldOfView=v end end)
UI.Button(c6, "Restore Defaults", function()
    for k,v in pairs(origL) do pcall(function() Lighting[k]=v end) end
    if cam then cam.FieldOfView = 70 end
end, false, true)

--==== TAB 5: UTILITY ====
local UtilP = makeTab("Utility", 5)
local c7 = UI.Card(UtilP, "Performance")
local fpsR = UI.Row(c7, "FPS", "0")
local pingR = UI.Row(c7, "Ping", "0")
local posR = UI.Row(c7, "Position", "0,0,0")

local fc, fl = 0, tick()
trackConn(RunService.RenderStepped:Connect(function()
    fc = fc + 1
    if tick() - fl >= 1 then
        fpsR.Text = tostring(fc); fc = 0; fl = tick()
        local ch = LocalPlayer.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local p = ch.HumanoidRootPart.Position
            posR.Text = string.format("%.0f,%.0f,%.0f", p.X,p.Y,p.Z)
        end
        pcall(function() pingR.Text = string.format("%.0fms", Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    end
end))

local c8 = UI.Card(UtilP, "Actions")
UI.Button(c8, "Copy PlaceId", function()
    if typeof(setclipboard)=="function" then pcall(setclipboard, tostring(game.PlaceId)); Notif.Push("Copied", "PlaceId", "success") end
end)
UI.Button(c8, "Rejoin Server", function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end, false, true)

--==== TAB 6: SETTINGS ====
local SetP = makeTab("Settings", 6)
local c9 = UI.Card(SetP, "Customization")
UI.Dropdown(c9, "Accent", {"Purple", "Cyan", "Pink", "Emerald"}, "Purple", function(opt)
    local map = { Purple=Color3.fromRGB(168,85,247), Cyan=Color3.fromRGB(6,182,212), Pink=Color3.fromRGB(236,72,153), Emerald=Color3.fromRGB(16,185,129) }
    if map[opt] then
        Theme.Accent = map[opt]
        stroke(Main, Theme.Accent, 1.5, 0.6)
        Notif.Push("Theme", "Changed to "..opt, "success")
    end
end)
UI.Button(c9, "Unload TracHub", function()
    for _,v in ipairs(Cleanup.Instances) do pcall(function() v:Destroy() end) end
    for _,c in ipairs(Cleanup.Connections) do pcall(function() c:Disconnect() end) end
    if getgenv then getgenv().TracHub_Loaded = false end
end, true)

--==== BOOT ====
pcall(function()
    TabBtns["Home"].btn.BackgroundColor3 = Theme.Accent
    TabBtns["Home"].btn.BackgroundTransparency = 0
    TabBtns["Home"].lbl.TextColor3 = Theme.TextMain
    Pages["Home"].Visible = true
end)
task.delay(0.5, function() Notif.Push("TracHub v2.0", "Loaded successfully.", "success") end)
