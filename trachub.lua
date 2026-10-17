--[[
═══════════════════════════════════════════════════════════════════
  TracHub v1.0.0 — Premium Client-Side Utility Hub
  Author:  TracHub Project
  License: MIT
  Target:  Luau environments with ScreenGui access
           (Roblox client, Delta executor, compatible executors)
  
  ⚠  WARNING
  TracHub modifies client-side state only. It cannot override
  server-authoritative game rules. Use in experiences you own
  or where client-side modification is explicitly permitted.
═══════════════════════════════════════════════════════════════════
--]]

--==============================================================
-- SECTION 0 — GUARD
--==============================================================
local TRACHUB_VERSION = "1.0.0"
local TRACHUB_BUILD   = "20260101"

if getgenv and getgenv().TracHub_Loaded then
    warn("[TracHub] Already running.")
    return
end
if getgenv then getgenv().TracHub_Loaded = true end

--==============================================================
-- SECTION 1 — SERVICES & CAPABILITIES
--==============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local Stats            = game:GetService("Stats")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local CoreGui = nil
pcall(function() CoreGui = game:GetService("CoreGui") end)

local Capabilities = {
    SetClipboard     = (typeof(setclipboard) == "function"),
    WriteFile        = (typeof(writefile) == "function"),
    ReadFile         = (typeof(readfile) == "function"),
    IsFileExists     = (typeof(isfile) == "function"),
    Identify         = (typeof(identifyexecutor) == "function"),
    QueueTeleport    = (typeof(queue_on_teleport) == "function"),
    CanAccessCoreGui = CoreGui ~= nil,
}
local ExecutorName = "Unknown"
if Capabilities.Identify then
    pcall(function() ExecutorName = identifyexecutor() end)
end

--==============================================================
-- SECTION 2 — THEME
--==============================================================
local Theme = {
    Palette = {
        BgPrimary     = Color3.fromRGB(16, 16, 24),
        BgSecondary   = Color3.fromRGB(25, 25, 37),
        BgTertiary    = Color3.fromRGB(34, 34, 50),
        Accent        = Color3.fromRGB(168, 85, 247),
        TextPrimary   = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(161, 161, 170),
        Stroke        = Color3.fromRGB(56, 56, 76),
        Success       = Color3.fromRGB(74, 222, 128),
        Error         = Color3.fromRGB(248, 113, 113),
        Warning       = Color3.fromRGB(250, 204, 21),
    },
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontBlack = Enum.Font.GothamBlack,
}
local function C(k) return Theme.Palette[k] or Theme.Palette.TextPrimary end

--==============================================================
-- SECTION 3 — CONFIG
--==============================================================
local Config = { Path = "TracHub_config.json", Data = {
    ThemeAccent = { R = 168, G = 85, B = 247 },
    UIScale = 1.0,
    Transparency = 0.03,
    Notifications = true,
    Animations = true,
}}

function Config.Load()
    if not (Capabilities.ReadFile and Capabilities.IsFileExists) then return end
    local ok, exists = pcall(isfile, Config.Path)
    if not (ok and exists) then return end
    local ok2, raw = pcall(readfile, Config.Path)
    if not ok2 or not raw then return end
    local ok3, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok3 or type(decoded) ~= "table" then return end
    for k, v in pairs(decoded) do
        if Config.Data[k] ~= nil and type(Config.Data[k]) == type(v) then
            Config.Data[k] = v
        end
    end
    local a = Config.Data.ThemeAccent
    Theme.Palette.Accent = Color3.fromRGB(
        math.clamp(a.R or 168, 0, 255),
        math.clamp(a.G or 85, 0, 255),
        math.clamp(a.B or 247, 0, 255)
    )
end

function Config.Save()
    if not Capabilities.WriteFile then return false end
    local a = Theme.Palette.Accent
    Config.Data.ThemeAccent = {
        R = math.floor(a.R * 255 + 0.5),
        G = math.floor(a.G * 255 + 0.5),
        B = math.floor(a.B * 255 + 0.5),
    }
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, Config.Data)
    if not ok then return false end
    return pcall(writefile, Config.Path, enc)
end

Config.Load()

--==============================================================
-- SECTION 4 — CLEANUP
--==============================================================
local Cleanup = { Instances = {}, Connections = {}, Callbacks = {} }
function Cleanup.AddInstance(i) table.insert(Cleanup.Instances, i) end
function Cleanup.AddConnection(c) if c then table.insert(Cleanup.Connections, c) end end
function Cleanup.AddCallback(f) table.insert(Cleanup.Callbacks, f) end
function Cleanup.Run()
    for _, f in ipairs(Cleanup.Callbacks) do pcall(f) end
    for _, c in ipairs(Cleanup.Connections) do pcall(function() c:Disconnect() end) end
    for _, i in ipairs(Cleanup.Instances) do pcall(function() i:Destroy() end) end
    Cleanup.Instances, Cleanup.Connections, Cleanup.Callbacks = {}, {}, {}
    if getgenv then getgenv().TracHub_Loaded = false end
end

--==============================================================
-- SECTION 5 — BUILD HELPERS
--==============================================================
local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    Cleanup.AddInstance(i)
    return i
end
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c
end
local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C("Stroke"); s.Thickness = th or 1; s.Transparency = tr or 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end
local function pad(p, all)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, all); u.PaddingBottom = UDim.new(0, all)
    u.PaddingLeft = UDim.new(0, all); u.PaddingRight = UDim.new(0, all)
    u.Parent = p; return u
end

--==============================================================
-- SECTION 6 — NOTIFICATIONS
--==============================================================
local Notifications = { Container = nil, Active = 0, Max = 4 }
function Notifications.Init(parent)
    local c = new("Frame", {
        Name = "TracNotifications", BackgroundTransparency = 1,
        Size = UDim2.new(0, 280, 1, -80),
        Position = UDim2.new(1, -12, 0, 60), AnchorPoint = Vector2.new(1, 0),
        ZIndex = 900,
    }, parent)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.Parent = c
    Notifications.Container = c
end

function Notifications.Push(title, msg, kind, dur)
    if not Config.Data.Notifications or not Notifications.Container then return end
    if Notifications.Active >= Notifications.Max then return end
    Notifications.Active = Notifications.Active + 1
    dur = dur or 3.5

    local accent = C("Accent")
    if kind == "success" then accent = C("Success")
    elseif kind == "error" then accent = C("Error")
    elseif kind == "warn" then accent = C("Warning") end

    local card = new("Frame", {
        BackgroundColor3 = C("BgSecondary"), BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true, Position = UDim2.new(1, 40, 0, 0), ZIndex = 901,
    }, Notifications.Container)
    corner(card, 8); stroke(card, accent, 1, 0.5)
    pad(card, 10)

    new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 5, 0, 8) }, card)

    new("TextLabel", { BackgroundTransparency = 1, Text = title,
        Font = Theme.FontBold, TextSize = 13, TextColor3 = accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 14, 0, 0) }, card)

    new("TextLabel", { BackgroundTransparency = 1, Text = msg,
        Font = Theme.Font, TextSize = 12, TextColor3 = C("TextSecondary"),
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 14, 0, 20) }, card)

    if Config.Data.Animations then
        TweenService:Create(card, TweenInfo.new(0.25), { Position = UDim2.new(0,0,0,0) }):Play()
    else
        card.Position = UDim2.new(0, 0, 0, 0)
    end

    task.delay(dur, function()
        Notifications.Active = math.max(0, Notifications.Active - 1)
        if not card.Parent then return end
        if Config.Data.Animations then
            TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundTransparency = 1, Position = UDim2.new(1, 40, 0, 0)
            }):Play()
            task.delay(0.22, function() if card.Parent then card:Destroy() end end)
        else
            card:Destroy()
        end
    end)
end

--==============================================================
-- SECTION 7 — COMPONENTS
--==============================================================
local UI = {}

function UI.Card(parent, title, order)
    local card = new("Frame", {
        BackgroundColor3 = C("BgSecondary"), BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0, ZIndex = 13,
    }, parent)
    corner(card, 12); stroke(card, C("Stroke"), 1, 0.55)
    if order then card.LayoutOrder = order end
    local inner = new("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.fromOffset(12, 12), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 14,
    }, card)
    Instance.new("UIListLayout", { Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
    if title and title ~= "" then
        new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
            Text = string.upper(title), Font = Theme.FontBold, TextSize = 11,
            TextColor3 = C("Accent"), TextXAlignment = Enum.TextXAlignment.Left }, inner)
    end
    return inner
end

function UI.Label(parent, text, color, order)
    local l = new("TextLabel", { BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Text = text, Font = Theme.Font, TextSize = 12,
        TextColor3 = color or C("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, parent)
    if order then l.LayoutOrder = order end
    return l
end

function UI.Row(parent, label, value, order)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1 }, parent)
    if order then row.LayoutOrder = order end
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0),
        Text = label, Font = Theme.Font, TextSize = 12,
        TextColor3 = C("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left }, row)
    local v = new("TextLabel", { BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
        Text = tostring(value), Font = Theme.FontBold, TextSize = 12,
        TextColor3 = C("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Right }, row)
    return v
end

function UI.Button(parent, label, onClick, opts, order)
    opts = opts or {}
    local bg = C("BgTertiary")
    if opts.danger then bg = C("Error") elseif opts.primary then bg = C("Accent") end
    local b = new("TextButton", {
        BackgroundColor3 = bg, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36), Text = label,
        Font = Theme.FontBold, TextSize = 12, TextColor3 = C("TextPrimary"),
        AutoButtonColor = false,
    }, parent)
    corner(b, 8)
    if order then b.LayoutOrder = order end
    if opts.disabled then
        b.BackgroundTransparency = 0.6; b.TextTransparency = 0.5
        return b
    end
    b.MouseEnter:Connect(function()
        if Config.Data.Animations then
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if Config.Data.Animations then
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
        end
    end)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(onClick)
        if not ok then Notifications.Push("Error", tostring(err), "error") end
    end)
    return b
end

function UI.Toggle(parent, label, default, onChange, order)
    local state = { Value = default or false }
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1 }, parent)
    if order then row.LayoutOrder = order end
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0),
        Text = label, Font = Theme.Font, TextSize = 12, TextColor3 = C("TextPrimary"),
        TextXAlignment = Enum.TextXAlignment.Left }, row)
    local track = new("Frame", {
        Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = default and C("Accent") or C("BgTertiary"),
        BorderSizePixel = 0 }, row)
    corner(track, 11)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = default and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = C("TextPrimary"), BorderSizePixel = 0 }, track)
    corner(knob, 8)
    local hit = new("TextButton", { BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), Text = "" }, track)

    local function apply(v)
        state.Value = v
        local tc = v and C("Accent") or C("BgTertiary")
        local tp = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
        if Config.Data.Animations then
            TweenService:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = tc }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), { Position = tp }):Play()
        else
            track.BackgroundColor3 = tc; knob.Position = tp
        end
    end
    hit.MouseButton1Click:Connect(function()
        apply(not state.Value)
        if onChange then
            local ok, err = pcall(onChange, state.Value)
            if not ok then Notifications.Push("Error", tostring(err), "error") end
        end
    end)
    state.Set = apply
    return state
end

function UI.Slider(parent, label, minV, maxV, default, onChange, order)
    local state = { Value = default or minV }
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1 }, parent)
    if order then row.LayoutOrder = order end
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 0, 16),
        Text = label, Font = Theme.Font, TextSize = 12,
        TextColor3 = C("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left }, row)
    local vlbl = new("TextLabel", { BackgroundTransparency = 1,
        Size = UDim2.new(0.3, 0, 0, 16), Position = UDim2.new(0.7, 0, 0, 0),
        Text = string.format("%.2f", default or minV), Font = Theme.FontBold,
        TextSize = 12, TextColor3 = C("Accent"), TextXAlignment = Enum.TextXAlignment.Right }, row)
    local track = new("Frame", { Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30), BackgroundColor3 = C("BgTertiary"),
        BorderSizePixel = 0 }, row)
    corner(track, 3)
    local fill = new("Frame", {
        Size = UDim2.fromScale(((default or minV) - minV) / (maxV - minV), 1),
        BackgroundColor3 = C("Accent"), BorderSizePixel = 0 }, track)
    corner(fill, 3)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(((default or minV) - minV) / (maxV - minV), 0, 0.5, 0),
        BackgroundColor3 = C("TextPrimary"), BorderSizePixel = 0 }, track)
    corner(knob, 7); stroke(knob, C("Accent"), 2, 0)
    local hit = new("TextButton", { Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1, Text = "" }, track)

    local function setVal(v)
        v = math.clamp(v, minV, maxV)
        state.Value = v
        vlbl.Text = string.format("%.2f", v)
        local rel = (v - minV) / (maxV - minV)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        if onChange then
            local ok, err = pcall(onChange, v)
            if not ok then Notifications.Push("Error", tostring(err), "error") end
        end
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X)
                / math.max(track.AbsoluteSize.X, 1), 0, 1)
            setVal(minV + (maxV - minV) * rel)
            local mc, ec
            mc = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch then
                    local r2 = math.clamp((inp.Position.X - track.AbsolutePosition.X)
                        / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    setVal(minV + (maxV - minV) * r2)
                end
            end)
            ec = UserInputService.InputEnded:Connect(function(inp)
                if inp == input then mc:Disconnect(); ec:Disconnect() end
            end)
        end
    end)
    state.Set = setVal
    return state
end

function UI.Dropdown(parent, label, options, default, onChange, order)
    local state = { Value = default or options[1] }
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1 }, parent)
    if order then row.LayoutOrder = order end
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
        Text = label, Font = Theme.Font, TextSize = 12,
        TextColor3 = C("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left }, row)
    local btn = new("TextButton", {
        Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C("BgTertiary"), BorderSizePixel = 0,
        Text = state.Value .. "  ▾", Font = Theme.Font, TextSize = 12,
        TextColor3 = C("TextPrimary"), AutoButtonColor = false }, row)
    corner(btn, 6)
    local list
    local function close() if list then list:Destroy(); list = nil end end
    btn.MouseButton1Click:Connect(function()
        if list then close(); return end
        list = new("Frame", { Size = UDim2.new(1, 0, 0, #options * 28),
            Position = UDim2.new(0, 0, 1, 4), BackgroundColor3 = C("BgSecondary"),
            BorderSizePixel = 0, ZIndex = 100 }, btn)
        corner(list, 6); stroke(list, C("Stroke"), 1, 0.2)
        for i, opt in ipairs(options) do
            local o = new("TextButton", { Size = UDim2.new(1, 0, 0, 28),
                Position = UDim2.new(0, 0, 0, (i - 1) * 28),
                BackgroundColor3 = C("BgSecondary"), BorderSizePixel = 0,
                Text = opt, Font = Theme.Font, TextSize = 12,
                TextColor3 = C("TextPrimary"), AutoButtonColor = true,
                ZIndex = 101 }, list)
            o.MouseButton1Click:Connect(function()
                state.Value = opt
                btn.Text = opt .. "  ▾"
                close()
                if onChange then
                    local ok, err = pcall(onChange, opt)
                    if not ok then Notifications.Push("Error", tostring(err), "error") end
                end
            end)
        end
    end)
    return state
end

--==============================================================
-- SECTION 8 — GUI ROOT + WINDOW
--==============================================================
if PlayerGui:FindFirstChild("TracHubUI") then
    PlayerGui.TracHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TracHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if Capabilities.CanAccessCoreGui then
    local ok = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok then ScreenGui.Parent = PlayerGui end
else
    ScreenGui.Parent = PlayerGui
end
Cleanup.AddInstance(ScreenGui)

Notifications.Init(ScreenGui)

-- Loading screen
local loader = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = C("BgPrimary"),
    BorderSizePixel = 0, ZIndex = 1000 }, ScreenGui)
new("TextLabel", { BackgroundTransparency = 1,
    Size = UDim2.fromOffset(240, 60), Position = UDim2.fromScale(0.5, 0.45),
    AnchorPoint = Vector2.new(0.5, 0.5), Text = "TracHub",
    Font = Theme.FontBlack, TextSize = 44, TextColor3 = C("Accent") }, loader)
new("TextLabel", { BackgroundTransparency = 1,
    Size = UDim2.fromOffset(240, 20), Position = UDim2.fromScale(0.5, 0.55),
    AnchorPoint = Vector2.new(0.5, 0.5), Text = "Premium Utility Suite",
    Font = Theme.Font, TextSize = 12, TextColor3 = C("TextSecondary") }, loader)
local bar = new("Frame", { Size = UDim2.fromOffset(200, 4),
    Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C("BgTertiary"), BorderSizePixel = 0 }, loader)
corner(bar, 2)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = C("Accent"), BorderSizePixel = 0 }, bar)
corner(fill, 2)
task.spawn(function()
    for i = 1, 20 do
        TweenService:Create(fill, TweenInfo.new(0.03), { Size = UDim2.fromScale(i / 20, 1) }):Play()
        task.wait(0.025)
    end
    task.wait(0.15)
    TweenService:Create(loader, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    task.wait(0.3)
    loader:Destroy()
end)

-- Main window
local Main = new("Frame", {
    Name = "Main", Size = UDim2.fromOffset(640, 420),
    Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C("BgPrimary"), BackgroundTransparency = Config.Data.Transparency,
    BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 10 }, ScreenGui)
corner(Main, 14); stroke(Main, C("Stroke"), 1, 0.4)

-- Responsive: shrink on small screens
local function applyResponsive()
    local vp = Workspace.CurrentCamera.ViewportSize
    local scale = math.clamp(math.min(vp.X / 700, vp.Y / 480), 0.7, 1)
    Main.Size = UDim2.fromOffset(640 * scale, 420 * scale)
end
applyResponsive()
Cleanup.AddConnection(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive))

-- Title bar
local TitleBar = new("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C("BgSecondary"), BorderSizePixel = 0, ZIndex = 11 }, Main)
corner(TitleBar, 14)
new("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(16, 16),
    BackgroundColor3 = C("Accent"), BorderSizePixel = 0, ZIndex = 12 }, TitleBar)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0),
    Size = UDim2.fromOffset(120, 42), Text = "TracHub",
    Font = Theme.FontBold, TextSize = 15, TextColor3 = C("TextPrimary"),
    TextXAlignment = Enum.TextXAlignment.Left }, TitleBar)
new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(110, 0),
    Size = UDim2.fromOffset(60, 42), Text = "v" .. TRACHUB_VERSION,
    Font = Theme.Font, TextSize = 11, TextColor3 = C("TextSecondary"),
    TextXAlignment = Enum.TextXAlignment.Left }, TitleBar)

local btnRow = new("Frame", { Size = UDim2.fromOffset(90, 42),
    Position = UDim2.new(1, -90, 0, 0), BackgroundTransparency = 1 }, TitleBar)
local function titleBtn(txt, xOff, col)
    local b = new("TextButton", { Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, xOff, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C("BgTertiary"), BorderSizePixel = 0, Text = txt,
        Font = Theme.FontBold, TextSize = 15,
        TextColor3 = col or C("TextSecondary"), AutoButtonColor = true }, btnRow)
    corner(b, 6); return b
end
local closeBtn = titleBtn("✕", -8, C("Error"))
local minBtn   = titleBtn("—", -42, C("TextSecondary"))

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Cleanup.AddConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

-- Sidebar + Content
local Sidebar = new("Frame", { Name = "Sidebar", Size = UDim2.new(0, 140, 1, -42),
    Position = UDim2.new(0, 0, 0, 42), BackgroundColor3 = C("BgSecondary"),
    BorderSizePixel = 0, ZIndex = 11 }, Main)
local Content = new("Frame", { Name = "Content", Size = UDim2.new(1, -140, 1, -42),
    Position = UDim2.new(0, 140, 0, 42), BackgroundTransparency = 1, ZIndex = 11 }, Main)

-- Floating button
local Floating = new("TextButton", {
    Name = "Floating", Size = UDim2.fromOffset(50, 50),
    Position = UDim2.new(1, -70, 0, 70),
    BackgroundColor3 = C("Accent"), BorderSizePixel = 0,
    Text = "T", Font = Theme.FontBlack, TextSize = 22,
    TextColor3 = C("TextPrimary"), Visible = false, ZIndex = 500 }, ScreenGui)
corner(Floating, 25)
stroke(Floating, C("TextPrimary"), 1.5, 0.7)
Floating.MouseButton1Click:Connect(function()
    Main.Visible = true
    Floating.Visible = false
    if Config.Data.Animations then
        Main.Size = UDim2.fromOffset(Main.AbsoluteSize.X * 0.9, Main.AbsoluteSize.Y * 0.9)
        TweenService:Create(Main, TweenInfo.new(0.2), {
            Size = UDim2.fromOffset(640, 420)
        }):Play()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false; Floating.Visible = true
end)
minBtn.MouseButton1Click:Connect(function()
    Main.Visible = false; Floating.Visible = true
end)

--==============================================================
-- SECTION 9 — NAVIGATION
--==============================================================
local Pages, Tabs, CurrentTab = {}, {}, nil

local function selectTab(name)
    if CurrentTab == name then return end
    CurrentTab = name
    for tabName, tabObj in pairs(Tabs) do
        local active = (tabName == name)
        TweenService:Create(tabObj, TweenInfo.new(0.15), {
            BackgroundColor3 = active and C("Accent") or C("BgSecondary"),
            BackgroundTransparency = active and 0 or 1,
        }):Play()
        tabObj.TextColor3 = active and C("TextPrimary") or C("TextSecondary")
    end
    for pName, pFrame in pairs(Pages) do
        pFrame.Visible = (pName == name)
    end
end

local function makeTab(name, icon, order)
    local btn = new("TextButton", {
        Size = UDim2.new(1, -16, 0, 34),
        Position = UDim2.new(0, 8, 0, 8 + (order - 1) * 38),
        BackgroundColor3 = C("BgSecondary"), BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = "  " .. (icon or "") .. "  " .. name,
        Font = Theme.Font, TextSize = 13, TextColor3 = C("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Sidebar)
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    Tabs[name] = btn

    local page = new("ScrollingFrame", {
        Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C("Accent"), CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, Content)
    pad(page, 12)
    Instance.new("UIListLayout", { Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    Pages[name] = page
    return page
end

--==============================================================
-- SECTION 10 — HOME TAB
--==============================================================
local HomePage = makeTab("Home", "⌂", 1)
local Home = UI.Card(HomePage, "Welcome", 1)
UI.Label(Home, "TracHub v" .. TRACHUB_VERSION .. " — Premium utility suite. All modifications are client-side only.", C("TextPrimary"))
UI.Row(Home, "Executor", ExecutorName)
UI.Row(Home, "Clipboard", Capabilities.SetClipboard and "Supported" or "Unavailable")
UI.Row(Home, "Persistent Config", Capabilities.WriteFile and "Supported" or "Session only")

local HomePlayer = UI.Card(HomePage, "Player", 2)
UI.Row(HomePlayer, "Username", LocalPlayer.Name)
UI.Row(HomePlayer, "Display", LocalPlayer.DisplayName)
UI.Row(HomePlayer, "User ID", tostring(LocalPlayer.UserId))

local HomeGame = UI.Card(HomePage, "Experience", 3)
UI.Row(HomeGame, "Place", game:GetService("MarketplaceService"):GetProductInfoAsync and "Loading..." or game.Name)
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId)
    if info and info.Name then
        HomeGame:FindFirstChildWhichIsA("Frame") -- will be replaced below
    end
end)
UI.Row(HomeGame, "PlaceId", tostring(game.PlaceId))
UI.Row(HomeGame, "JobId", (game.JobId ~= "" and game.JobId:sub(1, 8) .. "…") or "Private")
UI.Row(HomeGame, "Players", tostring(#Players:GetPlayers()))

-- Quick actions
local QuickCard = UI.Card(HomePage, "Quick Actions", 4)
UI.Button(QuickCard, "Open Visual Tab", function() selectTab("Visual") end, nil, 1)
UI.Button(QuickCard, "Open Utility Tab", function() selectTab("Utility") end, nil, 2)

--==============================================================
-- SECTION 11 — PLAYER TAB
--==============================================================
local PlayerPage = makeTab("Player", "●", 2)
local InfoCard = UI.Card(PlayerPage, "Character Info", 1)

local CharRows = {
    Health = UI.Row(InfoCard, "Health", "—"),
    WalkSpeed = UI.Row(InfoCard, "WalkSpeed", "—"),
    JumpPower = UI.Row(InfoCard, "JumpPower", "—"),
    State = UI.Row(InfoCard, "State", "—"),
}

local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function refreshChar()
    local hum = getHum()
    if not hum then
        CharRows.Health.Text = "No character"
        CharRows.WalkSpeed.Text = "—"
        CharRows.JumpPower.Text = "—"
        CharRows.State.Text = "Dead / Loading"
        return
    end
    CharRows.Health.Text = string.format("%d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
    CharRows.WalkSpeed.Text = string.format("%.1f", hum.WalkSpeed)
    CharRows.JumpPower.Text = string.format("%.1f", hum.JumpPower)
    CharRows.State.Text = tostring(hum:GetState())
end
refreshChar()

local CharConn
local function hookChar(char)
    if CharConn then CharConn:Disconnect() end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        CharConn = hum:GetPropertyChangedSignal("Health"):Connect(refreshChar)
        Cleanup.AddConnection(CharConn)
        refreshChar()
    end
end
if LocalPlayer.Character then hookChar(LocalPlayer.Character) end
Cleanup.AddConnection(LocalPlayer.CharacterAdded:Connect(hookChar))

UI.Button(InfoCard, "Refresh Info", refreshChar, nil, 5)

local ControlsCard = UI.Card(PlayerPage, "Local Controls", 2)
UI.Label(ControlsCard, "These modify your client only. Server may revert or flag changes.", C("Warning"))
local wsSlider = UI.Slider(ControlsCard, "WalkSpeed", 8, 200, 16, function(v)
    local hum = getHum(); if hum then hum.WalkSpeed = v end
end, 2)
local jpSlider = UI.Slider(ControlsCard, "JumpPower", 20, 200, 50, function(v)
    local hum = getHum(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end, 3)

UI.Button(ControlsCard, "Reset Character", function()
    local hum = getHum(); if hum then hum.Health = 0 end
end, { danger = true }, 4)
UI.Button(ControlsCard, "Restore Defaults", function()
    local hum = getHum()
    if hum then hum.WalkSpeed = 16; hum.UseJumpPower = true; hum.JumpPower = 50 end
    wsSlider.Set(16); jpSlider.Set(50)
end, nil, 5)

--==============================================================
-- SECTION 12 — MOVEMENT TAB
--==============================================================
local MovePage = makeTab("Movement", "↯", 3)
UI.Label(UI.Card(MovePage, "Warning", 1),
    "Movement controllers modify your local character only. Never use in games where modifying movement is prohibited by rules or anti-cheat.", C("Warning"))

local FlyCard = UI.Card(MovePage, "Fly Controller", 2)
local FlyState = { Active = false, Speed = 60, Conn = nil, BodyVelocity = nil }
local flySpeedSlider

local function stopFly()
    if FlyState.Conn then FlyState.Conn:Disconnect(); FlyState.Conn = nil end
    if FlyState.BodyVelocity then FlyState.BodyVelocity:Destroy(); FlyState.BodyVelocity = nil end
    FlyState.Active = false
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FlyState.Active = true
    local hum = getHum(); if hum then hum.PlatformStand = true end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Parent = hrp
    FlyState.BodyVelocity = bv
    FlyState.Conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
        bv.Velocity = move * FlyState.Speed
    end)
    Cleanup.AddConnection(FlyState.Conn)
    Cleanup.AddCallback(stopFly)
end

UI.Toggle(FlyCard, "Enable Fly (WASD+Space)", false, function(on)
    if on then startFly() else stopFly() end
end, 1)

flySpeedSlider = UI.Slider(FlyCard, "Fly Speed", 10, 300, 60, function(v)
    FlyState.Speed = v
end, 2)

local function platformStandOff()
    local hum = getHum(); if hum then hum.PlatformStand = false end
end
UI.Button(FlyCard, "Emergency Stop (disable fly)", function()
    stopFly()
    platformStandOff()
    Notifications.Push("Movement", "Fly disabled", "success")
end, { danger = true }, 3)

-- Noclip
local NoclipCard = UI.Card(MovePage, "Noclip Controller", 3)
local NoclipState = { Active = false, Conn = nil }
local function stopNoclip()
    if NoclipState.Conn then NoclipState.Conn:Disconnect(); NoclipState.Conn = nil end
    NoclipState.Active = false
end
local function startNoclip()
    NoclipState.Active = true
    NoclipState.Conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
    Cleanup.AddConnection(NoclipState.Conn)
    Cleanup.AddCallback(stopNoclip)
end
UI.Toggle(NoclipCard, "Enable Noclip", false, function(on)
    if on then startNoclip() else stopNoclip() end
end, 1)
UI.Button(NoclipCard, "Emergency Disable Noclip", function()
    stopNoclip(); Notifications.Push("Movement", "Noclip disabled", "success")
end, { danger = true }, 2)

--==============================================================
-- SECTION 13 — VISUAL TAB
--==============================================================
local VisualPage = makeTab("Visual", "◐", 4)
local VisCard = UI.Card(VisualPage, "Local Visual Settings", 1)
UI.Label(VisCard, "Changes below are applied to your local camera/lighting only.", C("TextSecondary"))

local origLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
}
local origFOV = Workspace.CurrentCamera.FieldOfView
local origZoom = LocalPlayer.CameraMaxZoomDistance

local FullbrightState = { Active = false }

UI.Toggle(VisCard, "Fullbright", false, function(on)
    FullbrightState.Active = on
    if on then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 1e5
    else
        for k, v in pairs(origLighting) do
            if pcall(function() Lighting[k] = v end) then end
        end
    end
end, 1)

UI.Slider(VisCard, "Field of View", 40, 120, origFOV, function(v)
    Workspace.CurrentCamera.FieldOfView = v
end, 2)

UI.Slider(VisCard, "Camera Min Zoom", 0.5, 50, LocalPlayer.CameraMinZoomDistance, function(v)
    LocalPlayer.CameraMinZoomDistance = v
end, 3)

UI.Slider(VisCard, "Camera Max Zoom", 10, 500, origZoom, function(v)
    LocalPlayer.CameraMaxZoomDistance = math.max(v, LocalPlayer.CameraMinZoomDistance)
end, 4)

UI.Button(VisCard, "Restore Default Visuals", function()
    for k, v in pairs(origLighting) do pcall(function() Lighting[k] = v end) end
    Workspace.CurrentCamera.FieldOfView = origFOV
    LocalPlayer.CameraMaxZoomDistance = origZoom
    Notifications.Push("Visual", "Defaults restored", "success")
end, { primary = true }, 5)

--==============================================================
-- SECTION 14 — UTILITY TAB
--==============================================================
local UtilPage = makeTab("Utility", "⚙", 5)
local PerfCard = UI.Card(UtilPage, "Performance", 1)

local FPSRow = UI.Row(PerfCard, "FPS", "—")
local PingRow = UI.Row(PerfCard, "Ping", "—")
local CoordRow = UI.Row(PerfCard, "Position", "—")
local PlaceRow = UI.Row(PerfCard, "PlaceId", tostring(game.PlaceId))
local JobRow = UI.Row(PerfCard, "JobId", game.JobId ~= "" and game.JobId or "Private")

local fpsFrames, fpsLast = 0, tick()
local fpsConn = RunService.RenderStepped:Connect(function()
    fpsFrames = fpsFrames + 1
    local now = tick()
    if now - fpsLast >= 1 then
        FPSRow.Text = tostring(fpsFrames)
        fpsFrames = 0; fpsLast = now
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart.Position
            CoordRow.Text = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        end
        pcall(function()
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            PingRow.Text = string.format("%.0f ms", ping)
        end)
    end
end)
Cleanup.AddConnection(fpsConn)

local ActionsCard = UI.Card(UtilPage, "Actions", 2)
UI.Button(ActionsCard, "Copy PlaceId", function()
    if Capabilities.SetClipboard then
        pcall(setclipboard, tostring(game.PlaceId))
        Notifications.Push("Utility", "PlaceId copied", "success")
    else
        Notifications.Push("Utility", "Clipboard unsupported on this executor", "warn")
    end
end, nil, 1)
UI.Button(ActionsCard, "Copy JobId", function()
    if game.JobId == "" then
        Notifications.Push("Utility", "JobId unavailable (private/singleplayer)", "warn"); return
    end
    if Capabilities.SetClipboard then
        pcall(setclipboard, game.JobId)
        Notifications.Push("Utility", "JobId copied", "success")
    else
        Notifications.Push("Utility", "Clipboard unsupported", "warn")
    end
end, nil, 2)
UI.Button(ActionsCard, "Rejoin Server", function()
    if game.JobId ~= "" then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    else
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end, { primary = true }, 3)

--==============================================================
-- SECTION 15 — SETTINGS TAB
--==============================================================
local SettingsPage = makeTab("Settings", "≡", 6)
local SetCard = UI.Card(SettingsPage, "Appearance", 1)
UI.Dropdown(SetCard, "Accent Color", { "Purple", "Blue", "Green", "Red", "Orange" }, "Purple", function(opt)
    local map = {
        Purple = Color3.fromRGB(168, 85, 247),
        Blue = Color3.fromRGB(59, 130, 246),
        Green = Color3.fromRGB(34, 197, 94),
        Red = Color3.fromRGB(239, 68, 68),
        Orange = Color3.fromRGB(249, 115, 22),
    }
    Theme.Palette.Accent = map[opt] or Theme.Palette.Accent
    Config.Save()
    Notifications.Push("Settings", "Accent changed. Reload UI to apply everywhere.", "info")
end, 1)

UI.Slider(SetCard, "UI Transparency", 0, 0.5, Config.Data.Transparency, function(v)
    Config.Data.Transparency = v
    Main.BackgroundTransparency = v
    Config.Save()
end, 2)

UI.Toggle(SetCard, "Animations", Config.Data.Animations, function(on)
    Config.Data.Animations = on; Config.Save()
end, 3)
UI.Toggle(SetCard, "Notifications", Config.Data.Notifications, function(on)
    Config.Data.Notifications = on; Config.Save()
end, 4)

local DangerCard = UI.Card(SettingsPage, "Danger Zone", 2)
UI.Button(DangerCard, "Reset Configuration", function()
    Config.Data.ThemeAccent = { R = 168, G = 85, B = 247 }
    Config.Data.Animations = true
    Config.Data.Notifications = true
    Config.Data.Transparency = 0.03
    Config.Save()
    Notifications.Push("Settings", "Config reset. Reload UI.", "success")
end, nil, 1)

UI.Button(DangerCard, "Unload TracHub", function()
    Cleanup.Run()
    if ScreenGui then ScreenGui:Destroy() end
end, { danger = true }, 2)

--==============================================================
-- SECTION 16 — BOOT
--==============================================================
selectTab("Home")
Notifications.Push("TracHub", "v" .. TRACHUB_VERSION .. " loaded. Executor: " .. ExecutorName, "success", 4)

-- Restore character-related state on respawn
Cleanup.AddConnection(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    refreshChar()
end))