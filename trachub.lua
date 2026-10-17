--[[
═══════════════════════════════════════════════════════════════════
  TracHub v1.2.0 — Ultimate Edition
  Full feature, vibrant UI, and mobile-optimized.
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

local Capabilities = {
    SetClipboard = (typeof(setclipboard) == "function"),
    Executor = (typeof(identifyexecutor) == "function") and identifyexecutor() or "Unknown"
}

--==== VIBRANT THEME ====
local Theme = {
    BgMain = Color3.fromRGB(12, 12, 18),      -- Deep Dark
    BgPanel = Color3.fromRGB(22, 22, 33),     -- Panel
    BgElement = Color3.fromRGB(35, 35, 52),   -- Elements
    Accent = Color3.fromRGB(168, 85, 247),    -- Purple
    Accent2 = Color3.fromRGB(6, 182, 212),    -- Cyan
    TextMain = Color3.fromRGB(255, 255, 255),
    TextSub = Color3.fromRGB(148, 163, 184),
    Danger = Color3.fromRGB(239, 68, 68),
    Success = Color3.fromRGB(34, 197, 94),
    
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontBlack = Enum.Font.GothamBlack,
    FontCode = Enum.Font.Code,
}

local Cleanup = { Instances={}, Connections={} }
local function trackInst(i) table.insert(Cleanup.Instances, i); return i end
local function trackConn(c) table.insert(Cleanup.Connections, c); return c end

--==== UI BUILDERS ====
local function new(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return trackInst(i)
end

local function addCorner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c
end

local function addStroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.BgElement; s.Thickness = th or 1; s.Transparency = tr or 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

--==== NOTIFICATIONS ====
local Notifications = { Container = nil, Active = 0, Max = 3 }
function Notifications.Init(parent)
    local c = new("Frame", { BackgroundTransparency=1, Size=UDim2.new(0,260,1,-80),
        Position=UDim2.new(1,-16,0,60), AnchorPoint=Vector2.new(1,0), ZIndex=900 }, parent)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0,8); l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right; l.Parent = c
    Notifications.Container = c
end
function Notifications.Push(title, msg, kind)
    if not Notifications.Container or Notifications.Active >= Notifications.Max then return end
    Notifications.Active = Notifications.Active + 1
    local accent = Theme.Accent
    if kind == "success" then accent = Theme.Success elseif kind == "error" then accent = Theme.Danger end
    
    local card = new("Frame", { BackgroundColor3=Theme.BgPanel, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true, Position=UDim2.new(1,40,0,0), ZIndex=901 }, Notifications.Container)
    addCorner(card, 8); addStroke(card, accent, 1.5, 0.2)
    
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
        Notifications.Active = math.max(0, Notifications.Active - 1)
        if not card.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency=1, Position=UDim2.new(1,40,0,0)}):Play()
        task.delay(0.25, function() card:Destroy() end)
    end)
end

--==== UI COMPONENTS ====
local UI = {}

function UI.Card(parent, title, icon)
    local card = new("Frame", { BackgroundColor3=Theme.BgPanel, Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y, BorderSizePixel=0, ClipsDescendants=true }, parent)
    addCorner(card, 12); addStroke(card, Theme.BgElement, 1, 0.5)
    
    local topBar = new("Frame", { BackgroundColor3=Theme.BgElement, Size=UDim2.new(1,0,0,36),
        BorderSizePixel=0 }, card)
    addCorner(topBar, 12)
    new("Frame", { BackgroundColor3=Theme.BgElement, Size=UDim2.new(1,0,0,20),
        Position=UDim2.new(0,0,1,-20), BorderSizePixel=0 }, topBar)
        
    new("TextLabel", { BackgroundTransparency=1, Text=title, Font=Theme.FontBold,
        TextSize=13, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,12,0,0) }, topBar)
    if icon then
        new("TextLabel", { BackgroundTransparency=1, Text=icon, Font=Theme.FontMain,
            TextSize=14, TextColor3=Theme.Accent2, TextXAlignment=Enum.TextXAlignment.Right,
            Size=UDim2.fromOffset(20,36), Position=UDim2.new(1,-32,0,0) }, topBar)
    end
    
    local inner = new("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,-24,0,0),
        Position=UDim2.fromOffset(12,12), AutomaticSize=Enum.AutomaticSize.Y }, card)
    Instance.new("UIListLayout", {Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder, Parent=inner})
    Instance.new("UIPadding", {PaddingTop=UDim.new(0,38), PaddingBottom=UDim.new(0,10), Parent=inner})
    
    return inner
end

function UI.Label(parent, text, color)
    return new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y, Text=text, Font=Theme.FontMain, TextSize=12,
        TextColor3=color or Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true }, parent)
end

function UI.Row(parent, label, value)
    local row = new("Frame", { Size=UDim2.new(1,0,0,24), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local v = new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0),
        Position=UDim2.new(0.5,0,0,0), Text=tostring(value), Font=Theme.FontCode, TextSize=12,
        TextColor3=Theme.Accent2, TextXAlignment=Enum.TextXAlignment.Right }, row)
    return v
end

function UI.Button(parent, label, onClick, isDanger, isPrimary)
    local bg = Theme.BgElement
    if isDanger then bg = Theme.Danger elseif isPrimary then bg = Theme.Accent end
    
    local b = new("TextButton", { BackgroundColor3=bg, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,36), Text=label, Font=Theme.FontBold, TextSize=12,
        TextColor3=Theme.TextMain, AutoButtonColor=false }, parent)
    addCorner(b, 8)
    
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency=0.2}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency=0}):Play() end)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(onClick)
        if not ok then Notifications.Push("Error", tostring(err), "error") end
    end)
    return b
end

function UI.Toggle(parent, label, defaultState, onChange)
    local state = { Value = defaultState or false }
    local row = new("Frame", { Size=UDim2.new(1,0,0,32), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,-50,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
        
    local track = new("Frame", { Size=UDim2.fromOffset(40,22), Position=UDim2.new(1,-40,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=defaultState and Theme.Accent or Theme.BgMain, BorderSizePixel=0 }, row)
    addCorner(track, 11)
    
    local knob = new("Frame", { Size=UDim2.fromOffset(16,16),
        Position=defaultState and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=Theme.TextMain, BorderSizePixel=0 }, track)
    addCorner(knob, 8)
    
    local hit = new("TextButton", { BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Text="" }, track)
    
    hit.MouseButton1Click:Connect(function()
        state.Value = not state.Value
        local tc = state.Value and Theme.Accent or Theme.BgMain
        local tp = state.Value and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3=tc}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position=tp}):Play()
        if onChange then pcall(onChange, state.Value) end
    end)
    return state
end

function UI.Slider(parent, label, minV, maxV, default, onChange)
    local state = { Value = default or minV }
    local row = new("Frame", { Size=UDim2.new(1,0,0,50), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.7,0,0,16), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local vlbl = new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.3,0,0,16),
        Position=UDim2.new(0.7,0,0,0), Text=string.format("%.1f", default or minV),
        Font=Theme.FontCode, TextSize=13, TextColor3=Theme.Accent2, TextXAlignment=Enum.TextXAlignment.Right }, row)
        
    local track = new("Frame", { Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,30),
        BackgroundColor3=Theme.BgMain, BorderSizePixel=0 }, row)
    addCorner(track, 3)
    
    local fill = new("Frame", { Size=UDim2.fromScale(((default or minV)-minV)/(maxV-minV),1),
        BackgroundColor3=Theme.Accent, BorderSizePixel=0 }, track)
    addCorner(fill, 3)
    
    local knob = new("Frame", { Size=UDim2.fromOffset(14,14), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(((default or minV)-minV)/(maxV-minV),0,0.5,0),
        BackgroundColor3=Theme.TextMain, BorderSizePixel=0 }, track)
    addCorner(knob, 7); addStroke(knob, Theme.Accent, 2, 0)
    
    local hit = new("TextButton", { Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0.5,0),
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
    local row = new("Frame", { Size=UDim2.new(1,0,0,34), BackgroundTransparency=1 }, parent)
    new("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0), Text=label,
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, row)
    local btn = new("TextButton", { Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
        BackgroundColor3=Theme.BgElement, BorderSizePixel=0, Text=" "..state.Value.." ▾",
        Font=Theme.FontMain, TextSize=12, TextColor3=Theme.TextMain, AutoButtonColor=false }, row)
    addCorner(btn, 6)
    local list
    local function close() if list then list:Destroy(); list = nil end end
    btn.MouseButton1Click:Connect(function()
        if list then close(); return end
        list = new("Frame", { Size=UDim2.new(1,0,0,#options*28), Position=UDim2.new(0,0,1,4),
            BackgroundColor3=Theme.BgPanel, BorderSizePixel=0, ZIndex=100 }, btn)
        addCorner(list, 6); addStroke(list, Theme.BgElement, 1, 0.2)
        for i,opt in ipairs(options) do
            local o = new("TextButton", { Size=UDim2.new(1,0,0,28),
                Position=UDim2.new(0,0,0,(i-1)*28), BackgroundColor3=Theme.BgPanel,
                BorderSizePixel=0, Text=" "..opt, Font=Theme.FontMain, TextSize=12,
                TextColor3=Theme.TextMain, AutoButtonColor=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=101 }, list)
            o.MouseButton1Click:Connect(function()
                state.Value = opt; btn.Text = " "..opt.." ▾"; close()
                if onChange then pcall(onChange, opt) end
            end)
        end
    end)
    return state
end

--==== ROOT GUI SETUP ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TracHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local attached = pcall(function() ScreenGui.Parent = CoreGui end)
if not attached then ScreenGui.Parent = PlayerGui end

Notifications.Init(ScreenGui)

--==== MAIN WINDOW ====
local Main = new("Frame", { Name="Main", Size=UDim2.fromOffset(680,440),
    Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Theme.BgMain, BorderSizePixel=0, ClipsDescendants=true }, ScreenGui)
addCorner(Main, 16)
addStroke(Main, Theme.Accent, 1.5, 0.7)

-- Gradient Background halus untuk Main
local bgGrad = Instance.new("UIGradient", Main)
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.BgMain),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 30))
})
bgGrad.Rotation = 45

local function applyResponsive()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local scale = math.clamp(math.min(vp.X/750, vp.Y/500), 0.7, 1)
    Main.Size = UDim2.fromOffset(680*scale, 440*scale)
end
applyResponsive()
trackConn(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive))

-- Title Bar
local TitleBar = new("Frame", { Size=UDim2.new(1,0,0,46), BackgroundColor3=Theme.BgPanel,
    BorderSizePixel=0 }, Main)
addCorner(TitleBar, 16)
new("Frame", { Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,1,-24),
    BackgroundColor3=Theme.BgPanel, BorderSizePixel=0 }, TitleBar)
    
-- Logo
local logo = new("Frame", { Size=UDim2.fromOffset(12,12), Position=UDim2.fromOffset(16,17),
    BackgroundColor3=Theme.Accent, BorderSizePixel=0 }, TitleBar)
addCorner(logo, 3)
new("TextLabel", { BackgroundTransparency=1, Position=UDim2.fromOffset(36,0),
    Size=UDim2.fromOffset(100,46), Text="TracHub", Font=Theme.FontBlack, TextSize=16,
    TextColor3=Theme.TextMain, TextXAlignment=Enum.TextXAlignment.Left }, TitleBar)
new("TextLabel", { BackgroundTransparency=1, Position=UDim2.fromOffset(120,0),
    Size=UDim2.fromOffset(50,46), Text="v1.2.0", Font=Theme.FontMain, TextSize=11,
    TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left }, TitleBar)

-- Window Controls
local ctrlFrame = new("Frame", { Size=UDim2.fromOffset(80,46), Position=UDim2.new(1,-80,0,0), BackgroundTransparency=1 }, TitleBar)
local function winBtn(text, xOff, col)
    local b = new("TextButton", { Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,xOff,0.5,0),
        AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=Theme.BgElement, BorderSizePixel=0,
        Text=text, Font=Theme.FontBold, TextSize=16, TextColor3=col, AutoButtonColor=false }, ctrlFrame)
    addCorner(b, 6)
    return b
end
local closeBtn = winBtn("×", -10, Theme.Danger)
local minBtn = winBtn("—", -44, Theme.TextSub)

-- Draggable Logic
local drag, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
end)
trackConn(UserInputService.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

-- Minimize/Restore Logic
local FloatingBtn = new("TextButton", { Size=UDim2.fromOffset(50,50), Position=UDim2.new(1,-70,0,70),
    BackgroundColor3=Theme.Accent, BorderSizePixel=0, Text="T", Font=Theme.FontBlack, TextSize=22,
    TextColor3=Theme.TextMain, Visible=false }, ScreenGui)
addCorner(FloatingBtn, 25); addStroke(FloatingBtn, Theme.TextMain, 1.5, 0.7)
FloatingBtn.MouseButton1Click:Connect(function() Main.Visible = true; FloatingBtn.Visible = false end)
closeBtn.MouseButton1Click:Connect(function() Main.Visible = false; FloatingBtn.Visible = true end)
minBtn.MouseButton1Click:Connect(function() Main.Visible = false; FloatingBtn.Visible = true end)

--==== SIDEBAR & CONTENT ====
local Sidebar = new("Frame", { Size=UDim2.new(0,150,1,-46), Position=UDim2.new(0,0,0,46),
    BackgroundColor3=Theme.BgMain, BorderSizePixel=0 }, Main)
new("Frame", { Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,0,0,0), BackgroundColor3=Theme.BgElement }, Sidebar)
local sidebarLayout = Instance.new("UIListLayout", { Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=Sidebar })
Instance.new("UIPadding", { PaddingTop=UDim.new(0,12), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), Parent=Sidebar })

local Content = new("Frame", { Size=UDim2.new(1,-150,1,-46), Position=UDim2.new(0,150,0,46), BackgroundTransparency=1 }, Main)
local Pages, TabButtons = {}, {}

local function makeTab(name, icon, order)
    local btn = new("TextButton", { Size=UDim2.new(1,0,0,38), BackgroundColor3=Theme.BgMain,
        BackgroundTransparency=1, BorderSizePixel=0, Text="  "..icon.."   "..name,
        Font=Theme.FontBold, TextSize=13, TextColor3=Theme.TextSub, TextXAlignment=Enum.TextXAlignment.Left,
        AutoButtonColor=false, LayoutOrder=order }, Sidebar)
    addCorner(btn, 8)
    
    local page = new("ScrollingFrame", { Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=2, ScrollBarImageColor3=Theme.Accent,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Visible=false }, Content)
    Instance.new("UIPadding", { PaddingTop=UDim.new(0,12), PaddingBottom=UDim.new(0,12), PaddingLeft=UDim.new(0,16), PaddingRight=UDim.new(0,16), Parent=page })
    Instance.new("UIListLayout", { Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder, Parent=page })
    
    Pages[name] = page
    TabButtons[name] = btn
    
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(TabButtons) do
            local active = (tName == name)
            TweenService:Create(tBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = active and Theme.Accent or Theme.BgMain,
                BackgroundTransparency = active and 0 or 1
            }):Play()
            tBtn.TextColor3 = active and Theme.TextMain or Theme.TextSub
            Pages[tName].Visible = active
        end
    end)
    return page
end

--==== TAB 1: HOME ====
local HomePage = makeTab("Home", "⌂", 1)
local cardWelcome = UI.Card(HomePage, "Welcome to TracHub", "★")
UI.Label(cardWelcome, "Premium Client-Side Utility Suite.", Theme.TextMain)
UI.Row(cardWelcome, "Version", "v1.2.0")
UI.Row(cardWelcome, "Executor", Capabilities.Executor)
UI.Row(cardWelcome, "Clipboard", Capabilities.SetClipboard and "Supported" or "Unavailable")

local cardStatus = UI.Card(HomePage, "Session Info", "ⓘ")
UI.Row(cardStatus, "Username", LocalPlayer.Name)
UI.Row(cardStatus, "PlaceId", tostring(game.PlaceId))
UI.Row(cardStatus, "JobId", game.JobId ~= "" and game.JobId or "Private Server")

--==== TAB 2: PLAYER ====
local PlayerPage = makeTab("Player", "👤", 2)
local cardStats = UI.Card(PlayerPage, "Character Statistics", "📊")
local healthRow = UI.Row(cardStats, "Health", "100 / 100")
local speedRow = UI.Row(cardStats, "WalkSpeed", "16.0")
local jumpRow = UI.Row(cardStats, "JumpPower", "50.0")

local function getHum() 
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid") or nil 
end

local function refreshStats()
    local h = getHum()
    if h then
        healthRow.Text = string.format("%d / %d", h.Health, h.MaxHealth)
        speedRow.Text = string.format("%.1f", h.WalkSpeed)
        jumpRow.Text = string.format("%.1f", h.JumpPower)
    end
end
trackConn(LocalPlayer.CharacterAdded:Connect(function() task.wait(1); refreshStats() end))
UI.Button(cardStats, "Refresh Data", refreshStats, false, false)

local cardMods = UI.Card(PlayerPage, "Local Modifications", "⚙")
UI.Label(cardMods, "Server may revert these if anti-cheat is active.", Theme.Danger)
local wsS = UI.Slider(cardMods, "WalkSpeed", 16, 200, 16, function(v) local h=getHum(); if h then h.WalkSpeed = v end end)
local jpS = UI.Slider(cardMods, "JumpPower", 50, 200, 50, function(v) local h=getHum(); if h then h.JumpPower = v; h.UseJumpPower = true end end)

UI.Button(cardMods, "Reset Character", function() local h=getHum(); if h then h.Health=0 end end, true)

--==== TAB 3: MOVEMENT ====
local MovePage = makeTab("Movement", "🏃", 3)
local cardFly = UI.Card(MovePage, "Fly Controller", "✈")
UI.Label(cardFly, "WASD/Joystick to move. Space/Shift to go up/down.", Theme.TextSub)

local flyState = { Active=false, BV=nil, Conn=nil, Speed=60 }
local function stopFly()
    if flyState.Conn then flyState.Conn:Disconnect() end
    if flyState.BV then flyState.BV:Destroy() end
    flyState.Active = false
    local h = getHum(); if h then h.PlatformStand = false end
end

UI.Toggle(cardFly, "Enable Fly (Client)", false, function(on)
    if on then
        local c = LocalPlayer.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyState.Active = true
        local h = getHum(); if h then h.PlatformStand = true end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bv.Parent = hrp; flyState.BV = bv
        flyState.Conn = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            bv.Velocity = move * flyState.Speed
        end)
    else 
        stopFly() 
    end
end)
UI.Slider(cardFly, "Fly Speed", 20, 300, 60, function(v) flyState.Speed = v end)
UI.Button(cardFly, "Emergency Stop", stopFly, true)

local cardNoclip = UI.Card(MovePage, "Noclip", "👻")
local noclipConn
UI.Toggle(cardNoclip, "Enable Noclip (Client)", false, function(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then
                for _,v in ipairs(c:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end)

--==== TAB 4: VISUAL ====
local VisualPage = makeTab("Visual", "👁", 4)
local cardVis = UI.Card(VisualPage, "Lighting & Camera", "☀")

local origLight = { Ambient=Lighting.Ambient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime }
UI.Toggle(cardVis, "Fullbright (Local)", false, function(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
    else
        for k,v in pairs(origLight) do pcall(function() Lighting[k]=v end) end
    end
end)

local cam = Workspace.CurrentCamera
UI.Slider(cardVis, "Field of View (FOV)", 40, 120, cam.FieldOfView, function(v) if cam then cam.FieldOfView = v end end)
UI.Button(cardVis, "Restore Defaults", function()
    for k,v in pairs(origLight) do pcall(function() Lighting[k]=v end) end
    if cam then cam.FieldOfView = 70 end
end, false, true)

--==== TAB 5: UTILITY ====
local UtilPage = makeTab("Utility", "🛠", 5)
local cardPerf = UI.Card(UtilPage, "Performance", "📈")
local fpsRow = UI.Row(cardPerf, "FPS", "0")
local pingRow = UI.Row(cardPerf, "Ping", "0 ms")
local coordRow = UI.Row(cardPerf, "Position", "X, Y, Z")

local fpsCount, fpsLast = 0, tick()
trackConn(RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if tick() - fpsLast >= 1 then
        fpsRow.Text = tostring(fpsCount); fpsCount = 0; fpsLast = tick()
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local p = c.HumanoidRootPart.Position
            coordRow.Text = string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
        end
        pcall(function() pingRow.Text = string.format("%.0f ms", Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    end
end))

local cardUtilBtn = UI.Card(UtilPage, "Session Actions", "⚡")
UI.Button(cardUtilBtn, "Copy PlaceId", function()
    if Capabilities.SetClipboard then
        pcall(setclipboard, tostring(game.PlaceId))
        Notifications.Push("Utility", "PlaceId copied!", "success")
    else 
        Notifications.Push("Utility", "Clipboard unsupported", "error") 
    end
end)
UI.Button(cardUtilBtn, "Rejoin Server", function()
    if game.JobId ~= "" then
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    else
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end, false, true)

--==== TAB 6: SETTINGS ====
local SettingsPage = makeTab("Settings", "⚙", 6)
local cardSettings = UI.Card(SettingsPage, "UI Customization", "🎨")

local accentMap = {
    Purple = Color3.fromRGB(168, 85, 247),
    Cyan = Color3.fromRGB(6, 182, 212),
    Pink = Color3.fromRGB(236, 72, 153),
    Emerald = Color3.fromRGB(16, 185, 129),
    Orange = Color3.fromRGB(249, 115, 22),
    Red = Color3.fromRGB(239, 68, 68)
}

UI.Dropdown(cardSettings, "Accent Color", {"Purple", "Cyan", "Pink", "Emerald", "Orange", "Red"}, "Purple", function(opt)
    local c = accentMap[opt]
    if c then
        Theme.Accent = c
        -- Update UI parts dynamically
        addStroke(Main, Theme.Accent, 1.5, 0.7) -- Re-apply stroke
        logo.BackgroundColor3 = Theme.Accent
        FloatingBtn.BackgroundColor3 = Theme.Accent
        for _,tab in pairs(TabButtons) do
            if tab.BackgroundTransparency == 0 then tab.BackgroundColor3 = Theme.Accent end
        end
        Notifications.Push("Settings", "Accent changed to "..opt, "success")
    end
end)

UI.Slider(cardSettings, "UI Transparency", 0, 0.5, 0, function(v)
    Main.BackgroundTransparency = v
end)

local cardDanger = UI.Card(SettingsPage, "Danger Zone", "⚠")
UI.Button(cardDanger, "Unload TracHub", function()
    for _,v in ipairs(Cleanup.Instances) do pcall(function() v:Destroy() end) end
    for _,c in ipairs(Cleanup.Connections) do pcall(function() c:Disconnect() end) end
    if getgenv then getgenv().TracHub_Loaded = false end
    Notifications.Push("System", "TracHub Unloaded.", "error")
end, true)

--==== BOOT INIT ====
pcall(function()
    TabButtons["Home"].BackgroundColor3 = Theme.Accent
    TabButtons["Home"].BackgroundTransparency = 0
    TabButtons["Home"].TextColor3 = Theme.TextMain
    Pages["Home"].Visible = true
end)
task.delay(0.5, function() Notifications.Push("TracHub v1.2.0", "Loaded successfully. Enjoy!", "success") end)