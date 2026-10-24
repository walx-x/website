
--[[
    ╔══════════════════════════════════════════════════════════╗
    ║  SAKURA.UI  v3.0  —  layout a card, tema chiaro + glow   ║
    ╚══════════════════════════════════════════════════════════╝
    LocalScript / esecuzione client. Un solo file, nessuna dipendenza.

    Tab: Home · Visuals · World · Keybinds · Settings
    Scorciatoie di default: RightShift mostra/nasconde · Ctrl+←/→ cambia tab · Ctrl+F cerca
    (tutte cambiabili dal tab Keybinds)
]]

local BRAND   = "SAKURA"      -- cambia qui il nome
local BRAND_S = ".UI"
local VERSION = "3.0.0"

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local StatsService     = game:GetService("Stats")

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.__SakuraUnload then pcall(env.__SakuraUnload) end

local player = Players.LocalPlayer
local BASE_W, BASE_H = 860, 540
local SIDEBAR_W, TOPBAR_H, TABS_Y = 172, 84, 116

local running = true
local conns = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    conns[#conns + 1] = c
    return c
end

-- ═════════════════════════ TEMA (più chiaro) ═════════════════════════
local THEMES = {
    {name = "Sakura", a = Color3.fromRGB(255, 108, 172), b = Color3.fromRGB(255, 176, 214)},
    {name = "Lilla",  a = Color3.fromRGB(184, 146, 255), b = Color3.fromRGB(224, 204, 255)},
    {name = "Ciano",  a = Color3.fromRGB(80, 208, 255),  b = Color3.fromRGB(176, 238, 255)},
    {name = "Menta",  a = Color3.fromRGB(70, 232, 176),  b = Color3.fromRGB(176, 250, 220)},
    {name = "Pesca",  a = Color3.fromRGB(255, 150, 100), b = Color3.fromRGB(255, 212, 170)},
}
local C = {
    bg    = Color3.fromRGB(36, 22, 44),
    bg2   = Color3.fromRGB(84, 34, 88),
    panel = Color3.fromRGB(52, 34, 62),
    elev  = Color3.fromRGB(70, 46, 82),
    elev2 = Color3.fromRGB(100, 68, 114),
    line  = Color3.fromRGB(168, 112, 182),
    text  = Color3.fromRGB(255, 249, 253),
    muted = Color3.fromRGB(222, 198, 230),
    dim   = Color3.fromRGB(170, 144, 182),
    good  = Color3.fromRGB(120, 240, 170),
    warn  = Color3.fromRGB(255, 212, 110),
    bad   = Color3.fromRGB(255, 112, 130),
    a     = THEMES[1].a,
    b     = THEMES[1].b,
}

-- ═════════════════════════ UTILITÀ ═════════════════════════
local FONT_B = Enum.Font.GothamBold
local FONT_M = Enum.Font.GothamMedium
local FONT_R = Enum.Font.Gotham
local CENTER = Enum.TextXAlignment.Center
local RIGHT  = Enum.TextXAlignment.Right

local function T(o, time, props, style, dir)
    local tween = TweenService:Create(
        o,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end
local function tw(o, instant, props, time, style)
    if instant then
        for k, v in pairs(props) do o[k] = v end
    else
        T(o, time or 0.25, props, style)
    end
end
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, color, th, tr)
    return new("UIStroke", {
        Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end
local function pad(o, l, t, r, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, o)
end
local function text(parent, str, size, font, color, props)
    local l = new("TextLabel", {
        BackgroundTransparency = 1, Text = str, TextSize = size, Font = font,
        TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, BorderSizePixel = 0,
    }, parent)
    if props then for k, v in pairs(props) do l[k] = v end end
    return l
end
local function hex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local refreshers = {}
local function themed(fn)
    fn(true)
    refreshers[#refreshers + 1] = fn
end
local function applyTheme(a, b)
    C.a, C.b = a, b
    for _, fn in ipairs(refreshers) do pcall(fn, false) end
end

-- alone luminoso morbido (9-slice): la parte piena è (size - 48px), il resto sfuma
local GLOW_IMG, GLOW_SLICE = "rbxassetid://5028857084", Rect.new(24, 24, 276, 276)
local function glow(parent, props, useB)
    local g = new("ImageLabel", {
        BackgroundTransparency = 1, Image = GLOW_IMG, ImageColor3 = C.a,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = GLOW_SLICE,
        ZIndex = 0, ImageTransparency = 1,
    }, parent)
    for k, v in pairs(props or {}) do g[k] = v end
    themed(function() g.ImageColor3 = useB and C.b or C.a end)
    return g
end
-- contorno luminoso sul testo
local function textGlow(label, thickness, transparency)
    local s = new("UIStroke", {Color = C.a, Thickness = thickness or 2, Transparency = transparency or 0.6}, label)
    themed(function() s.Color = C.a end)
    return s
end

local Flags, Setters, Defaults, NoSave = {}, {}, {}, {cfgName = true}
local searchIndex, cards = {}, {}
local notify = function() end
local listeningKey = false

local function safe(cb, ...)
    if not cb then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then notify("Errore", tostring(err), "error") end
    end)
end

-- ═════════════════════════ GUI BASE ═════════════════════════
local parentGui = (typeof(gethui) == "function" and gethui()) or player:WaitForChild("PlayerGui")
for _, p in ipairs({parentGui, player:FindFirstChild("PlayerGui")}) do
    if p then
        local old = p:FindFirstChild("SakuraUI")
        if old then old:Destroy() end
    end
end

local gui = new("ScreenGui", {
    Name = "SakuraUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
gui.Parent = parentGui

local function viewport()
    local s = gui.AbsoluteSize
    if s.X < 100 then
        local cam = workspace.CurrentCamera
        s = cam and cam.ViewportSize or Vector2.new(1280, 720)
    end
    return s
end

local dim = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 8, 34),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
}, gui)
local blur = new("BlurEffect", {Name = "SakuraBlur", Size = 0}, Lighting)

local root = new("Frame", {
    Name = "Root", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60),
    Size = UDim2.fromOffset(BASE_W, BASE_H), BackgroundTransparency = 1, Visible = false,
}, gui)
local rootScale = new("UIScale", {Scale = 1}, root)

-- alone rosa attorno alla finestra
local halo = glow(root, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 110, 1, 110), ImageTransparency = 1,
})

local win = new("CanvasGroup", {
    Name = "Window", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0, GroupTransparency = 1, Active = true, ZIndex = 1,
}, root)
corner(win, 18)
local animScale = new("UIScale", {Scale = 0.9}, win)
local bgGrad = new("UIGradient", {Rotation = 120}, win)
themed(function() bgGrad.Color = ColorSequence.new(C.bg, C.bg2:Lerp(C.a, 0.12)) end)

local glow1 = glow(win, {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(520, 380), ImageTransparency = 0.72,
    ZIndex = 1,
})
local glow2 = glow(win, {
    AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(440, 320), ImageTransparency = 0.8,
    ZIndex = 1,
}, true)

local petalLayer = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2,
}, win)

local edge = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100,
}, win)
corner(edge, 18)
local edgeStroke = stroke(edge, Color3.new(1, 1, 1), 2, 0.1)
local edgeGrad = new("UIGradient", {Rotation = 0}, edgeStroke)
themed(function()
    edgeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.a),
        ColorSequenceKeypoint.new(0.5, C.b),
        ColorSequenceKeypoint.new(1, C.a),
    })
end)

-- ripple + pulsante "pill" luminoso (servono rootScale/animScale)
local function ripple(parent, pos)
    local k = rootScale.Scale * animScale.Scale
    local rel = pos - parent.AbsolutePosition
    local r = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.6, BorderSizePixel = 0, Size = UDim2.fromOffset(0, 0), ZIndex = 5,
        Position = UDim2.fromOffset(rel.X / k, rel.Y / k),
    }, parent)
    corner(r, 300)
    T(r, 0.6, {Size = UDim2.fromOffset(260, 260), BackgroundTransparency = 1})
    task.delay(0.65, function() r:Destroy() end)
end

local ctrlHover = 0
local function trackHover(o)
    bind(o.MouseEnter, function() ctrlHover += 1 end)
    bind(o.MouseLeave, function() ctrlHover = math.max(0, ctrlHover - 1) end)
end

local function pill(parent, label, props, callback)
    local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(130, 38)}, parent)
    for k, v in pairs(props or {}) do holder[k] = v end
    local g = glow(holder, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 44, 1, 44), ImageTransparency = 0.45,
    })
    local b = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Text = label,
        TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = FONT_B, AutoButtonColor = false,
        ClipsDescendants = true, ZIndex = 2,
    }, holder)
    corner(b, 19)
    local gr = new("UIGradient", {Rotation = 0}, b)
    themed(function() gr.Color = ColorSequence.new(C.a, C.b:Lerp(C.a, 0.3)) end)
    local sc = new("UIScale", {}, b)
    bind(b.MouseEnter, function() T(g, 0.2, {ImageTransparency = 0.12}); T(sc, 0.25, {Scale = 1.06}, Enum.EasingStyle.Back) end)
    bind(b.MouseLeave, function() T(g, 0.25, {ImageTransparency = 0.45}); T(sc, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
    bind(b.MouseButton1Down, function(x, y) ripple(b, Vector2.new(x, y)); T(sc, 0.1, {Scale = 0.95}) end)
    bind(b.MouseButton1Up, function() T(sc, 0.3, {Scale = 1.06}, Enum.EasingStyle.Back) end)
    bind(b.MouseButton1Click, function() safe(callback) end)
    return holder
end

-- ═════════════════════════ SIDEBAR ═════════════════════════
local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, 0), BackgroundColor3 = C.panel,
    BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 10,
}, win)
new("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
    Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, sidebar)

local logoArea = new("Frame", {
    Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, ZIndex = 11,
}, sidebar)
local logoGlow = glow(logoArea, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 36),
    Size = UDim2.fromOffset(110, 110), ImageTransparency = 0.45, ZIndex = 11,
})
local logoCircle = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 36),
    Size = UDim2.fromOffset(46, 46), BackgroundColor3 = C.panel, BackgroundTransparency = 0.2,
    BorderSizePixel = 0, ZIndex = 12,
}, logoArea)
corner(logoCircle, 23)
local logoStroke = stroke(logoCircle, C.a, 2, 0)
themed(function() logoStroke.Color = C.a end)
text(logoCircle, "🌸", 24, FONT_M, C.text, {Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER, ZIndex = 13})

-- ricerca
local searchFrame = new("Frame", {
    Position = UDim2.fromOffset(12, 74), Size = UDim2.new(1, -24, 0, 30),
    BackgroundColor3 = C.elev, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 12,
}, sidebar)
corner(searchFrame, 10)
local searchStroke = stroke(searchFrame, C.line, 1, 0.45)
trackHover(searchFrame)
text(searchFrame, "🔍", 12, FONT_M, C.muted, {
    Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(22, 30), TextXAlignment = CENTER, ZIndex = 13})
local searchBox = new("TextBox", {
    Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -36, 1, 0), BackgroundTransparency = 1,
    Text = "", PlaceholderText = "Cerca…", PlaceholderColor3 = C.dim, TextColor3 = C.text,
    TextSize = 12, Font = FONT_R, TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false, ZIndex = 13,
}, searchFrame)
bind(searchBox.Focused, function() T(searchStroke, 0.2, {Color = C.a, Transparency = 0, Thickness = 1.6}) end)
bind(searchBox.FocusLost, function() T(searchStroke, 0.2, {Color = C.line, Transparency = 0.45, Thickness = 1}) end)

-- indicatore tab con alone
local indGlow = glow(sidebar, {
    Position = UDim2.fromOffset(-12, TABS_Y - 24), Size = UDim2.new(1, 24, 0, 88),
    ImageTransparency = 0.45, ZIndex = 10,
})
local indicator = new("Frame", {
    Position = UDim2.fromOffset(12, TABS_Y), Size = UDim2.new(1, -24, 0, 40),
    BackgroundColor3 = C.a, BackgroundTransparency = 0.68, BorderSizePixel = 0, ZIndex = 11,
}, sidebar)
corner(indicator, 11)
local indStroke = stroke(indicator, C.a, 1.6, 0.05)
local indBar = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.fromOffset(3, 20), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
}, indicator)
corner(indBar, 2)
themed(function(i)
    tw(indicator, i, {BackgroundColor3 = C.a})
    tw(indStroke, i, {Color = C.a})
end)

local tabsHolder = new("Frame", {
    Position = UDim2.fromOffset(12, TABS_Y), Size = UDim2.new(1, -24, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 12,
}, sidebar)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabsHolder)

local profile = new("Frame", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12),
    Size = UDim2.new(1, -24, 0, 54), BackgroundColor3 = C.elev, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 12,
}, sidebar)
corner(profile, 12)
stroke(profile, C.line, 1, 0.45)
local avatar = new("ImageLabel", {
    Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = C.elev2, BorderSizePixel = 0, ZIndex = 13,
}, profile)
corner(avatar, 18)
text(profile, player.DisplayName, 12, FONT_B, C.text, {
    Position = UDim2.fromOffset(54, 9), Size = UDim2.new(1, -62, 0, 18),
    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13})
local footFps = text(profile, "— fps", 11, FONT_R, C.muted, {
    Position = UDim2.fromOffset(54, 28), Size = UDim2.new(1, -62, 0, 16), ZIndex = 13})
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and avatar.Parent then avatar.Image = img end
end)

-- ═════════════════════════ HEADER (luna + skyline) ═════════════════════════
local bar = new("Frame", {
    Position = UDim2.fromOffset(SIDEBAR_W, 0), Size = UDim2.new(1, -SIDEBAR_W, 0, TOPBAR_H),
    BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10,
}, win)
new("Frame", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BackgroundTransparency = 0.5,
    BorderSizePixel = 0, ZIndex = 11,
}, bar)

local moonGlow = glow(bar, {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -260, 0, 34),
    Size = UDim2.fromOffset(190, 190), ImageTransparency = 0.35, ZIndex = 11,
})
local moon = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -260, 0, 34),
    Size = UDim2.fromOffset(70, 70), BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0, ZIndex = 12,
}, bar)
corner(moon, 35)
local moonGrad = new("UIGradient", {Rotation = 90}, moon)
themed(function() moonGrad.Color = ColorSequence.new(C.b, C.a) end)

local sky = new("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
    Size = UDim2.fromOffset(330, 62), BackgroundTransparency = 1, ZIndex = 13,
}, bar)
do
    local rng = Random.new(11)
    local x = 0
    while x < 330 do
        local w = rng:NextInteger(9, 22)
        local h = rng:NextInteger(12, 54)
        new("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, 0), Size = UDim2.fromOffset(w, h),
            BackgroundColor3 = Color3.fromRGB(28, 12, 38), BackgroundTransparency = 0.1, BorderSizePixel = 0,
        }, sky)
        if rng:NextNumber() > 0.7 then
            new("Frame", {
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, x + w / 2, 1, -h),
                Size = UDim2.fromOffset(2, rng:NextInteger(6, 14)), BackgroundColor3 = Color3.fromRGB(28, 12, 38),
                BorderSizePixel = 0,
            }, sky)
        end
        x += w + rng:NextInteger(0, 2)
    end
end
local skyFade = new("Frame", {
    Size = UDim2.new(0, 120, 1, 0), BackgroundColor3 = Color3.fromRGB(36, 22, 44),
    BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 14,
}, sky)
new("UIGradient", {Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 1)})}, skyFade)
skyFade:Destroy()

local titleLbl = text(bar, "", 30, FONT_B, C.text, {
    Position = UDim2.fromOffset(22, 12), Size = UDim2.fromOffset(300, 38), RichText = true, ZIndex = 15})
themed(function()
    titleLbl.Text = BRAND .. '<font color="' .. hex(C.a) .. '">' .. BRAND_S .. "</font>"
end)
textGlow(titleLbl, 2.5, 0.72)
text(bar, "NEXT GENERATION INTERFACE", 10, FONT_M, C.muted, {
    Position = UDim2.fromOffset(24, 52), Size = UDim2.fromOffset(300, 14), ZIndex = 15})

local ready = new("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0, 31),
    Size = UDim2.fromOffset(88, 28), BackgroundColor3 = C.panel, BackgroundTransparency = 0.2,
    BorderSizePixel = 0, ZIndex = 15,
}, bar)
corner(ready, 14)
local readyStroke = stroke(ready, C.a, 1.4, 0.15)
themed(function() readyStroke.Color = C.a end)
local readyDot = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = C.good, BorderSizePixel = 0, ZIndex = 16,
}, ready)
corner(readyDot, 4)
glow(readyDot, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(40, 40), ImageTransparency = 0.5, ZIndex = 15}).ImageColor3 = C.good
text(ready, "READY", 11, FONT_B, C.text, {
    Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -30, 1, 0), ZIndex = 16})

local function winBtn(label, fromRight, hoverColor)
    local b = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -fromRight, 0, 31),
        Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.elev, BackgroundTransparency = 1,
        Text = label, TextColor3 = C.muted, TextSize = 15, Font = FONT_B,
        AutoButtonColor = false, ZIndex = 16,
    }, bar)
    corner(b, 8)
    trackHover(b)
    bind(b.MouseEnter, function() T(b, 0.15, {BackgroundTransparency = 0.2, TextColor3 = hoverColor or C.text}) end)
    bind(b.MouseLeave, function() T(b, 0.2, {BackgroundTransparency = 1, TextColor3 = C.muted}) end)
    return b
end
local btnCollapse = winBtn("–", 54)
local btnClose = winBtn("✕", 18, C.bad)

-- ═════════════════════════ CONTENUTO ═════════════════════════
local content = new("Frame", {
    Position = UDim2.fromOffset(SIDEBAR_W, TOPBAR_H),
    Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H),
    BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 5,
}, win)

-- ═════════════════════════ TAB + COMPONENTI ═════════════════════════
local Tab = {}
Tab.__index = Tab
local tabs = {}
local current
local selectTab

local function makeTab(name, icon, desc)
    local tab = setmetatable({name = name, order = 2}, Tab)
    tab.index = #tabs + 1
    tabs[tab.index] = tab

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, LayoutOrder = tab.index, ZIndex = 13,
    }, tabsHolder)
    tab.iconLbl = text(btn, icon, 17, FONT_M, C.text, {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(24, 40),
        TextXAlignment = CENTER, TextTransparency = 0.3, ZIndex = 14})
    tab.nameLbl = text(btn, name, 14, FONT_M, C.muted, {
        Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -52, 1, 0), ZIndex = 14})
    bind(btn.MouseEnter, function()
        if current ~= tab then T(tab.nameLbl, 0.15, {TextColor3 = C.text}); T(tab.iconLbl, 0.15, {TextTransparency = 0}) end
    end)
    bind(btn.MouseLeave, function()
        if current ~= tab then T(tab.nameLbl, 0.2, {TextColor3 = C.muted}); T(tab.iconLbl, 0.2, {TextTransparency = 0.3}) end
    end)
    bind(btn.MouseButton1Click, function() selectTab(tab) end)

    tab.group = new("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        GroupTransparency = 1, Visible = false,
    }, content)
    tab.scroller = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.a, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, tab.group)
    themed(function() tab.scroller.ScrollBarImageColor3 = C.a end)
    pad(tab.scroller, 20, 18, 20, 22)
    new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, tab.scroller)
    return tab
end

function Tab:_row(h, name, wrap)
    self.order += 1
    local holder, row
    if wrap then
        holder = new("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = self.order}, self.scroller)
        row = new("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.panel, BackgroundTransparency = 0.25,
            BorderSizePixel = 0, ZIndex = 2}, holder)
    else
        row = new("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.panel, BackgroundTransparency = 0.25,
            BorderSizePixel = 0, LayoutOrder = self.order}, self.scroller)
        holder = row
    end
    corner(row, 11)
    local st = stroke(row, C.line, 1, 0.5)
    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, row)
    if not wrap then
        bind(hit.MouseEnter, function()
            T(row, 0.15, {BackgroundTransparency = 0.05})
            T(st, 0.15, {Transparency = 0.05, Color = C.a})
        end)
        bind(hit.MouseLeave, function()
            T(row, 0.2, {BackgroundTransparency = 0.25})
            T(st, 0.2, {Transparency = 0.5, Color = C.line})
        end)
    end
    local owner = self.owner or self
    if name then
        searchIndex[#searchIndex + 1] = {row = holder, name = name:lower(), tab = owner}
    end
    if self.cardRef then table.insert(self.cardRef.rows, holder) end
    return row, hit, st, holder
end

function Tab:_title(row, name, desc, rightPad, h, icon)
    rightPad = rightPad or 16
    local H = h or row.Size.Y.Offset
    local x = 16
    if icon then
        x = 58
        local ib = new("Frame", {
            Position = UDim2.fromOffset(12, (H - 34) / 2), Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = C.a, BackgroundTransparency = 0.82, BorderSizePixel = 0}, row)
        corner(ib, 10)
        local s = stroke(ib, C.a, 1.2, 0.3)
        themed(function() ib.BackgroundColor3 = C.a; s.Color = C.a end)
        text(ib, icon, 16, FONT_M, C.text, {Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER})
    end
    if desc then
        text(row, name, 14, FONT_M, C.text, {
            Position = UDim2.fromOffset(x, (H - 34) / 2), Size = UDim2.new(1, -(rightPad + x), 0, 18)})
        text(row, desc, 11, FONT_R, C.muted, {
            Position = UDim2.fromOffset(x, (H - 34) / 2 + 18), Size = UDim2.new(1, -(rightPad + x), 0, 16),
            TextTruncate = Enum.TextTruncate.AtEnd})
    else
        text(row, name, 14, FONT_M, C.text, {
            Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -(rightPad + x), 0, H)})
    end
end

function Tab:Frame(h)
    self.order += 1
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = self.order}, self.scroller)
    searchIndex[#searchIndex + 1] = {row = f, name = "", section = true, tab = self.owner or self}
    return f
end

function Tab:Columns(ratio)
    ratio = ratio or 0.5
    self.order += 1
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self.order}, self.scroller)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top}, f)
    local owner = self.owner or self
    local function col(w, order)
        local c = new("Frame", {
            Size = UDim2.new(w, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = order}, f)
        new("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, c)
        return setmetatable({scroller = c, order = 0, owner = owner}, Tab)
    end
    return col(ratio, 1), col(1 - ratio, 2)
end

function Tab:Card(o)
    self.order += 1
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.elev, BackgroundTransparency = 0.18, BorderSizePixel = 0,
        LayoutOrder = self.order}, self.scroller)
    corner(f, 15)
    local st = stroke(f, C.a, 1.4, 0.35)
    themed(function(i) tw(st, i, {Color = C.a}) end)
    new("UIGradient", {Rotation = 90, Color = ColorSequence.new(
        Color3.new(1, 1, 1), Color3.fromRGB(206, 184, 218))}, f)
    pad(f, 14, 12, 14, 14)
    new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, f)

    local hd = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 0}, f)
    local ib = new("Frame", {
        Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.a, BackgroundTransparency = 0.8,
        BorderSizePixel = 0}, hd)
    corner(ib, 10)
    local ibs = stroke(ib, C.a, 1.3, 0.2)
    themed(function() ib.BackgroundColor3 = C.a; ibs.Color = C.a end)
    text(ib, o.Icon or "✿", 16, FONT_M, C.text, {Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER})
    text(hd, o.Title, 15, FONT_B, C.text, {
        Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -150, 1, 0)})
    if o.Tag then
        local tag = text(hd, "● " .. o.Tag, 11, FONT_M, C.a, {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(110, 20), TextXAlignment = RIGHT})
        themed(function() tag.TextColor3 = C.a end)
    end
    local body = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = 1}, f)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    local ref = {frame = f, rows = {}}
    cards[#cards + 1] = ref
    return setmetatable({scroller = body, order = 0, owner = self.owner or self, cardRef = ref}, Tab)
end

function Tab:Label(str)
    self.order += 1
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.panel, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        LayoutOrder = self.order}, self.scroller)
    corner(f, 11)
    pad(f, 14, 10, 14, 10)
    local l = text(f, str, 12, FONT_R, C.muted, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, RichText = true})
    searchIndex[#searchIndex + 1] = {row = f, name = str:lower(), tab = self.owner or self}
    if self.cardRef then table.insert(self.cardRef.rows, f) end
    return {Set = function(s) l.Text = s end}
end

function Tab:Toggle(o)
    local flag = o.Flag or o.Name
    local row, hit = self:_row(o.Desc and 58 or 48, o.Name .. " " .. (o.Desc or ""))
    self:_title(row, o.Name, o.Desc, 90, nil, o.Icon)
    local g = glow(row, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -37, 0.5, 0),
        Size = UDim2.fromOffset(94, 74), ImageTransparency = 1})
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), BackgroundColor3 = C.elev2, BorderSizePixel = 0,
    }, row)
    corner(track, 11)
    local fillOn = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0}, track)
    corner(fillOn, 11)
    local fg = new("UIGradient", {}, fillOn)
    themed(function() fg.Color = ColorSequence.new(C.a, C.b) end)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 3}, track)
    corner(knob, 8)

    local state = o.Default == true
    local function render(instant)
        tw(fillOn, instant, {BackgroundTransparency = state and 0 or 1}, 0.25)
        tw(g, instant, {ImageTransparency = state and 0.3 or 1}, 0.3)
        tw(knob, instant, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)},
            0.35, Enum.EasingStyle.Back)
    end
    render(true)
    refreshers[#refreshers + 1] = render

    local function set(v, silent)
        state = v and true or false
        Flags[flag] = state
        render(false)
        if not silent then safe(o.Callback, state) end
    end
    Flags[flag] = state
    Defaults[flag] = state
    Setters[flag] = set
    bind(hit.MouseButton1Down, function() T(knob, 0.1, {Size = UDim2.fromOffset(21, 16)}) end)
    bind(hit.MouseButton1Up, function() T(knob, 0.25, {Size = UDim2.fromOffset(16, 16)}, Enum.EasingStyle.Back) end)
    bind(hit.MouseButton1Click, function() set(not state) end)
    return {Set = set, Get = function() return state end}
end

function Tab:Slider(o)
    local flag = o.Flag or o.Name
    local step = o.Step or 1
    local dec = o.Decimals or ((step % 1 ~= 0) and 2 or 0)
    local row = self:_row(o.Desc and 80 or 66, o.Name .. " " .. (o.Desc or ""))
    self:_title(row, o.Name, o.Desc, 100, o.Desc and 54 or 46, o.Icon)
    local valueLbl = text(row, "", 13, FONT_B, C.a, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, o.Desc and 12 or 14),
        Size = UDim2.fromOffset(90, 18), TextXAlignment = RIGHT})
    themed(function() valueLbl.TextColor3 = C.a end)
    textGlow(valueLbl, 1.5, 0.75)

    local hitTrack = new("TextButton", {
        Position = UDim2.new(0, 16, 1, -26), Size = UDim2.new(1, -32, 0, 18),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, row)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.elev2, BorderSizePixel = 0, ZIndex = 1,
    }, hitTrack)
    corner(track, 3)
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, track)
    corner(fill, 3)
    local fg = new("UIGradient", {}, fill)
    themed(function() fg.Color = ColorSequence.new(C.a, C.b) end)
    local kg = glow(hitTrack, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(60, 60), ImageTransparency = 0.35, ZIndex = 1})
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 3,
    }, hitTrack)
    corner(knob, 7)
    local ks = stroke(knob, C.a, 2.5, 0)
    themed(function() ks.Color = C.a end)

    local value = o.Default or o.Min
    local function snap(v)
        v = math.clamp(v, o.Min, o.Max)
        v = o.Min + math.floor((v - o.Min) / step + 0.5) * step
        return math.clamp(math.floor(v * 1000 + 0.5) / 1000, o.Min, o.Max)
    end
    local function render(instant)
        local a = (value - o.Min) / (o.Max - o.Min)
        tw(fill, instant, {Size = UDim2.fromScale(a, 1)}, 0.08, Enum.EasingStyle.Linear)
        tw(knob, instant, {Position = UDim2.fromScale(a, 0.5)}, 0.08, Enum.EasingStyle.Linear)
        tw(kg, instant, {Position = UDim2.fromScale(a, 0.5)}, 0.08, Enum.EasingStyle.Linear)
        valueLbl.Text = string.format("%." .. dec .. "f", value) .. (o.Suffix or "")
    end
    local function set(v, silent)
        v = snap(v)
        value = v
        Flags[flag] = v
        render(false)
        if not silent then safe(o.Callback, v) end
    end
    value = snap(value)
    Flags[flag] = value
    Defaults[flag] = value
    Setters[flag] = set
    render(true)

    local dragging = false
    local function fromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        set(o.Min + a * (o.Max - o.Min))
    end
    bind(hitTrack.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            T(knob, 0.15, {Size = UDim2.fromOffset(19, 19)}, Enum.EasingStyle.Back)
            T(kg, 0.15, {ImageTransparency = 0.05})
            fromX(input.Position.X)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            T(knob, 0.25, {Size = UDim2.fromOffset(14, 14)}, Enum.EasingStyle.Back)
            T(kg, 0.3, {ImageTransparency = 0.35})
        end
    end)
    return {Set = set, Get = function() return value end}
end

function Tab:Button(o)
    local h = o.Desc and 58 or 48
    local row, hit, st, holder = self:_row(h, o.Name .. " " .. (o.Desc or ""), true)
    local color = o.Danger and C.bad or C.a
    local g = glow(holder, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 44, 1, 44), ImageTransparency = o.Primary and 0.5 or 0.88})
    if o.Danger then g.ImageColor3 = C.bad end
    row.ClipsDescendants = true
    local baseT, hoverT
    if o.Primary then
        row.BackgroundColor3 = Color3.new(1, 1, 1)
        baseT, hoverT = 0, 0
        local gr = new("UIGradient", {Rotation = 0}, row)
        themed(function() gr.Color = ColorSequence.new(C.a, C.b:Lerp(C.a, 0.3)) end)
        st.Transparency = 1
    else
        row.BackgroundColor3 = color
        baseT, hoverT = 0.82, 0.6
        themed(function() row.BackgroundColor3 = o.Danger and C.bad or C.a; st.Color = o.Danger and C.bad or C.a end)
        st.Transparency = 0.3
        st.Thickness = 1.3
    end
    row.BackgroundTransparency = baseT
    self:_title(row, o.Name, o.Desc, 40, h, o.Icon)
    local chev = text(row, "›", 24, FONT_B, o.Primary and Color3.new(1, 1, 1) or C.text, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, -2),
        Size = UDim2.fromOffset(16, 26), TextXAlignment = CENTER})
    bind(hit.MouseEnter, function()
        T(row, 0.15, {BackgroundTransparency = hoverT})
        T(g, 0.2, {ImageTransparency = o.Primary and 0.12 or 0.45})
        T(st, 0.15, {Transparency = o.Primary and 1 or 0})
    end)
    bind(hit.MouseLeave, function()
        T(row, 0.2, {BackgroundTransparency = baseT})
        T(g, 0.25, {ImageTransparency = o.Primary and 0.5 or 0.88})
        T(st, 0.2, {Transparency = o.Primary and 1 or 0.3})
    end)
    bind(hit.MouseButton1Down, function(x, y)
        ripple(row, Vector2.new(x, y))
        T(chev, 0.1, {Position = UDim2.new(1, -10, 0.5, -2)})
    end)
    bind(hit.MouseButton1Up, function()
        T(chev, 0.3, {Position = UDim2.new(1, -16, 0.5, -2)}, Enum.EasingStyle.Back)
    end)
    bind(hit.MouseButton1Click, function() safe(o.Callback) end)
end

function Tab:Dropdown(o)
    local flag = o.Flag or o.Name
    local H, n = 48, #o.Options
    local row, hit = self:_row(H, o.Name)
    row.ClipsDescendants = true
    hit.Size = UDim2.new(1, 0, 0, H)
    self:_title(row, o.Name, nil, 190, H, o.Icon)
    local valueLbl = text(row, "", 13, FONT_M, C.a, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -38, 0, 0),
        Size = UDim2.fromOffset(140, H), TextXAlignment = RIGHT})
    themed(function() valueLbl.TextColor3 = C.a end)
    local chev = text(row, "▾", 14, FONT_B, C.muted, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, H / 2),
        Size = UDim2.fromOffset(16, 16), TextXAlignment = CENTER})
    local list = new("Frame", {
        Position = UDim2.new(0, 8, 0, H + 2), Size = UDim2.new(1, -16, 0, n * 30),
        BackgroundTransparency = 1}, row)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

    local value = o.Default or o.Options[1]
    local buttons = {}
    local function refreshOpts(instant)
        valueLbl.Text = tostring(value)
        for name, b in pairs(buttons) do
            tw(b, instant, {TextColor3 = (name == value) and C.a or C.muted}, 0.2)
        end
    end
    local function set(v, silent)
        value = v
        if not o.NoFlag then Flags[flag] = v end
        refreshOpts(false)
        if not silent then safe(o.Callback, v) end
    end
    for i, name in ipairs(o.Options) do
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.elev2, BackgroundTransparency = 1,
            Text = name, TextColor3 = C.muted, TextSize = 13, Font = FONT_M,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i,
        }, list)
        corner(b, 8)
        pad(b, 12, 0, 0, 0)
        buttons[name] = b
        bind(b.MouseEnter, function() T(b, 0.12, {BackgroundTransparency = 0.4}) end)
        bind(b.MouseLeave, function() T(b, 0.18, {BackgroundTransparency = 1}) end)
        bind(b.MouseButton1Click, function()
            set(name)
            row:SetAttribute("open", false)
            T(row, 0.3, {Size = UDim2.new(1, 0, 0, H)})
            T(chev, 0.3, {Rotation = 0})
        end)
    end
    refreshOpts(true)
    refreshers[#refreshers + 1] = refreshOpts
    if not o.NoFlag then
        Flags[flag] = value
        Defaults[flag] = value
        Setters[flag] = set
    end
    bind(hit.MouseButton1Click, function()
        local open = not row:GetAttribute("open")
        row:SetAttribute("open", open)
        T(row, 0.35, {Size = UDim2.new(1, 0, 0, open and (H + n * 30 + 10) or H)})
        T(chev, 0.3, {Rotation = open and 180 or 0})
    end)
    return {Set = set, Get = function() return value end}
end

function Tab:Keybind(o)
    local flag = o.Flag or o.Name
    local row, hit = self:_row(48, o.Name)
    self:_title(row, o.Name, nil, 140, 48, o.Icon)
    local box = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(116, 28), BackgroundColor3 = C.elev2, BorderSizePixel = 0,
    }, row)
    corner(box, 9)
    local bs = stroke(box, C.line, 1, 0.3)
    local lbl = text(box, "", 12, FONT_B, C.a, {Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER})
    themed(function() lbl.TextColor3 = C.a end)
    local value = o.Default
    local listening = false
    local function render() lbl.Text = listening and "premi un tasto…" or string.upper(value) end
    local function set(v, silent)
        value = v
        Flags[flag] = v
        render()
        if not silent then safe(o.Callback, v) end
    end
    Flags[flag] = value
    Defaults[flag] = value
    Setters[flag] = set
    render()
    bind(hit.MouseButton1Click, function()
        listening = true
        listeningKey = true
        render()
        T(bs, 0.2, {Color = C.a, Transparency = 0, Thickness = 1.6})
    end)
    bind(UserInputService.InputBegan, function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            task.defer(function() listeningKey = false end)
            if input.KeyCode ~= Enum.KeyCode.Escape then set(input.KeyCode.Name) else render() end
            T(bs, 0.2, {Color = C.line, Transparency = 0.3, Thickness = 1})
        end
    end)
end

function Tab:Textbox(o)
    local flag = o.Flag or o.Name
    local row = self:_row(48, o.Name)
    self:_title(row, o.Name, nil, 190, 48, o.Icon)
    local box = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(160, 28), BackgroundColor3 = C.elev2, BorderSizePixel = 0,
    }, row)
    corner(box, 9)
    local bs = stroke(box, C.line, 1, 0.3)
    local tb = new("TextBox", {
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
        Text = o.Default or "", PlaceholderText = o.Placeholder or "", PlaceholderColor3 = C.dim,
        TextColor3 = C.text, TextSize = 12, Font = FONT_R, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, box)
    Flags[flag] = tb.Text
    Defaults[flag] = tb.Text
    Setters[flag] = function(v) tb.Text = tostring(v) end
    bind(tb:GetPropertyChangedSignal("Text"), function() Flags[flag] = tb.Text end)
    bind(tb.Focused, function() T(bs, 0.2, {Color = C.a, Transparency = 0, Thickness = 1.6}) end)
    bind(tb.FocusLost, function()
        T(bs, 0.2, {Color = C.line, Transparency = 0.3, Thickness = 1})
        safe(o.Callback, tb.Text)
    end)
end

-- ═════════════════════════ SELEZIONE TAB + RICERCA ═════════════════════════
selectTab = function(tab, instant)
    if current == tab then return end
    local prev = current
    current = tab
    for _, t in ipairs(tabs) do
        local sel = t == tab
        tw(t.nameLbl, instant, {TextColor3 = sel and C.text or C.muted}, 0.2)
        tw(t.iconLbl, instant, {TextTransparency = sel and 0 or 0.3}, 0.2)
    end
    local y = TABS_Y + (tab.index - 1) * 46
    tw(indicator, instant, {Position = UDim2.fromOffset(12, y)}, 0.45, Enum.EasingStyle.Back)
    tw(indGlow, instant, {Position = UDim2.fromOffset(-12, y - 24)}, 0.45, Enum.EasingStyle.Back)
    if prev then
        T(prev.group, 0.12, {GroupTransparency = 1})
        task.delay(0.14, function()
            if current ~= prev then prev.group.Visible = false end
        end)
    end
    tab.scroller.CanvasPosition = Vector2.zero
    tab.group.Visible = true
    if instant then
        tab.group.GroupTransparency = 0
        tab.group.Position = UDim2.new()
    else
        tab.group.GroupTransparency = 1
        tab.group.Position = UDim2.fromOffset(0, 16)
        T(tab.group, 0.4, {GroupTransparency = 0, Position = UDim2.new()})
    end
end

local function applySearch()
    local q = searchBox.Text:lower():match("^%s*(.-)%s*$") or ""
    local counts = {}
    for _, e in ipairs(searchIndex) do
        if e.section then
            e.row.Visible = (q == "")
        else
            local ok = q == "" or e.name:find(q, 1, true) ~= nil
            e.row.Visible = ok
            if ok then counts[e.tab] = (counts[e.tab] or 0) + 1 end
        end
    end
    for _, c in ipairs(cards) do
        local any = false
        for _, r in ipairs(c.rows) do
            if r.Visible then any = true break end
        end
        c.frame.Visible = (q == "") or any
    end
    if q ~= "" and current and (counts[current] or 0) == 0 then
        for _, t in ipairs(tabs) do
            if (counts[t] or 0) > 0 then selectTab(t) break end
        end
    end
end
bind(searchBox:GetPropertyChangedSignal("Text"), applySearch)
bind(searchBox.FocusLost, function(enter, input)
    if input and input.KeyCode == Enum.KeyCode.Escape then searchBox.Text = "" end
end)

-- ═════════════════════════ NOTIFICHE ═════════════════════════
local notifHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 330, 1, -40), BackgroundTransparency = 1, ZIndex = 200,
}, gui)
new("UIListLayout", {
    VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, notifHolder)
local notifCount = 0

notify = function(title, msg, kind, dur)
    if not running then return end
    kind = kind or "info"
    dur = dur or 3.8
    local colors = {info = C.a, success = C.good, warn = C.warn, error = C.bad}
    local icons = {info = "🌸", success = "✅", warn = "⚠️", error = "⛔"}
    local color = colors[kind] or C.a
    notifCount += 1
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = notifCount}, notifHolder)
    local card = new("Frame", {
        Position = UDim2.fromOffset(350, 0), Size = UDim2.new(1, -4, 0, 66),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, ClipsDescendants = true}, wrap)
    corner(card, 13)
    stroke(card, color, 1.5, 0.15)
    local cg = new("ImageLabel", {
        BackgroundTransparency = 1, Image = GLOW_IMG, ImageColor3 = color, ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = GLOW_SLICE,
        Position = UDim2.fromOffset(-30, -30), Size = UDim2.fromOffset(120, 120)}, card)
    new("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0}, card)
    text(card, icons[kind] or "🌸", 20, FONT_M, C.text, {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(30, 66), TextXAlignment = CENTER})
    text(card, title, 13, FONT_B, C.text, {
        Position = UDim2.fromOffset(52, 12), Size = UDim2.new(1, -64, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd})
    text(card, msg or "", 12, FONT_R, C.muted, {
        Position = UDim2.fromOffset(52, 32), Size = UDim2.new(1, -64, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd})
    local prog = new("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0}, card)
    T(wrap, 0.25, {Size = UDim2.new(1, 0, 0, 66)})
    T(card, 0.55, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Back)
    T(prog, dur, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
    local closed = false
    local function close()
        if closed then return end
        closed = true
        local t = T(card, 0.3, {Position = UDim2.fromOffset(350, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            local t2 = T(wrap, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
            t2.Completed:Connect(function() wrap:Destroy() end)
        end)
    end
    local click = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ""}, card)
    click.MouseButton1Click:Connect(close)
    task.delay(dur, close)
end

-- ═════════════════════════ PETALI ═════════════════════════
local MAXP = 40
local petals = {}
for i = 1, MAXP do
    local depth = 0.5 + math.random() * 0.9
    local size = math.floor(7 + depth * 7)
    local obj = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
        Size = UDim2.fromOffset(size, math.floor(size * 1.5)),
        BackgroundColor3 = C.b, BackgroundTransparency = 0.12 + (1.5 - depth) * 0.28,
        ZIndex = 2, Visible = false}, petalLayer)
    corner(obj, size)
    petals[i] = {
        obj = obj, x = math.random(), y = math.random(), depth = depth, mix = math.random(),
        speed = 0.04 + math.random() * 0.05, rot = math.random() * 360,
        rotSpeed = (math.random() - 0.5) * 70, phase = math.random() * 6.28,
        freq = 0.6 + math.random(), amp = 10 + math.random() * 18,
        fs = 1.5 + math.random() * 2.5, fl = math.random() * 6.28, base = obj.Size,
    }
end
themed(function()
    for _, p in ipairs(petals) do p.obj.BackgroundColor3 = C.b:Lerp(C.a, p.mix * 0.6) end
end)
local function refreshPetals()
    local n = (Flags.petals and Flags.petalCount) or 0
    for i, p in ipairs(petals) do p.obj.Visible = i <= n end
end

-- ═════════════════════════ FINESTRA ═════════════════════════
local function fitScale()
    local vp = viewport()
    local auto = math.clamp(math.min(vp.X / (BASE_W + 60), vp.Y / (BASE_H + 60)), 0.5, 1.2)
    rootScale.Scale = auto * (Flags.uiScale or 1)
end
bind(gui:GetPropertyChangedSignal("AbsoluteSize"), fitScale)
fitScale()

local posX, posY = 0, math.max(10, (viewport().Y - BASE_H * rootScale.Scale) / 2)
local tgtX, tgtY = posX, posY
root.Position = UDim2.new(0.5, posX, 0, posY)

local dragging, dragStart, startAbs, startTarget = false, nil, nil, nil
local function makeDrag(frame)
    bind(frame.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if ctrlHover > 0 then return end
        dragging = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        startAbs = root.AbsolutePosition
        startTarget = Vector2.new(tgtX, tgtY)
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                c:Disconnect()
            end
        end)
    end)
end
makeDrag(bar)
makeDrag(logoArea)
bind(UserInputService.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
    local vp, sz = viewport(), root.AbsoluteSize
    local na = startAbs + delta
    local cx = math.clamp(na.X, 90 - sz.X, vp.X - 90)
    local cy = math.clamp(na.Y, 0, vp.Y - 70)
    tgtX = startTarget.X + (cx - startAbs.X)
    tgtY = startTarget.Y + (cy - startAbs.Y)
end)

local uiVisible, visTok = false, 0
local function refreshBlur()
    local amt = (uiVisible and Flags.blurOn) and (Flags.blurAmt or 14) or 0
    if blur then T(blur, 0.35, {Size = amt}) end
end
local function setVisible(v)
    if not running and v then return end
    uiVisible = v
    visTok += 1
    local tok = visTok
    if v then
        root.Visible = true
        dim.Visible = true
        T(dim, 0.3, {BackgroundTransparency = 0.78})
        T(win, 0.35, {GroupTransparency = 0})
        T(animScale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
        T(halo, 0.5, {ImageTransparency = 0.55})
    else
        T(dim, 0.22, {BackgroundTransparency = 1})
        T(win, 0.2, {GroupTransparency = 1})
        T(halo, 0.2, {ImageTransparency = 1})
        local t = T(animScale, 0.24, {Scale = 0.93}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            if tok == visTok and not uiVisible then
                root.Visible = false
                dim.Visible = false
            end
        end)
    end
    refreshBlur()
end

local collapsed = false
bind(btnCollapse.MouseButton1Click, function()
    collapsed = not collapsed
    T(root, 0.45, {Size = UDim2.fromOffset(BASE_W, collapsed and TOPBAR_H or BASE_H)})
    btnCollapse.Text = collapsed and "+" or "–"
end)
bind(btnClose.MouseButton1Click, function()
    setVisible(false)
    notify("Interfaccia nascosta", "Premi " .. string.upper(Flags.toggleKey or "RightShift") .. " per riaprirla", "info")
end)

-- ═════════════════════════ EFFETTI VISIVI (logica) ═════════════════════════
local cam0 = workspace.CurrentCamera
local orig = {
    fov = cam0 and cam0.FieldOfView or 70,
    clock = Lighting.ClockTime, bright = Lighting.Brightness, expo = Lighting.ExposureCompensation,
    fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart, fogColor = Lighting.FogColor,
    amb = Lighting.Ambient, outAmb = Lighting.OutdoorAmbient,
}
local fxBloom = new("BloomEffect", {Name = "SakuraBloom", Enabled = false}, Lighting)
local fxCC = new("ColorCorrectionEffect", {Name = "SakuraCC", Enabled = false}, Lighting)
local fxRays = new("SunRaysEffect", {Name = "SakuraRays", Enabled = false}, Lighting)

local TINTS = {
    Neutro = Color3.fromRGB(255, 255, 255), Rosa = Color3.fromRGB(255, 225, 238),
    Caldo = Color3.fromRGB(255, 226, 190), Freddo = Color3.fromRGB(210, 230, 255),
    Lilla = Color3.fromRGB(235, 220, 255),
}
local AMBS = {
    Rosa = Color3.fromRGB(150, 100, 125), Lilla = Color3.fromRGB(120, 100, 165),
    Blu = Color3.fromRGB(90, 115, 165), Dorato = Color3.fromRGB(165, 135, 80),
}
local FOGS = {
    Bianca = Color3.fromRGB(225, 225, 235), Rosa = Color3.fromRGB(255, 200, 220),
    Blu = Color3.fromRGB(150, 175, 215), Grigia = Color3.fromRGB(130, 130, 140),
}
local prevOn = {}
local function edgeApply(key, on, apply, restore)
    if on then apply() elseif prevOn[key] then restore() end
    prevOn[key] = on and true or false
end
local function applyVisuals()
    if not running then return end
    local F = Flags
    local cam = workspace.CurrentCamera
    edgeApply("fov", F.fovOn, function() if cam then cam.FieldOfView = F.fov end end,
        function() if cam then cam.FieldOfView = orig.fov end end)
    edgeApply("time", F.timeOn, function() Lighting.ClockTime = F.time end,
        function() Lighting.ClockTime = orig.clock end)
    edgeApply("light", F.lightOn, function()
        Lighting.Brightness = F.bright
        Lighting.ExposureCompensation = F.expo
    end, function()
        Lighting.Brightness = orig.bright
        Lighting.ExposureCompensation = orig.expo
    end)
    edgeApply("fog", F.fogOn, function()
        Lighting.FogEnd = F.fogDist
        Lighting.FogStart = F.fogDist * 0.15
        Lighting.FogColor = FOGS[F.fogColor] or orig.fogColor
    end, function()
        Lighting.FogEnd, Lighting.FogStart, Lighting.FogColor = orig.fogEnd, orig.fogStart, orig.fogColor
    end)
    edgeApply("amb", AMBS[F.amb] ~= nil, function()
        Lighting.Ambient = AMBS[F.amb]
        Lighting.OutdoorAmbient = AMBS[F.amb]
    end, function()
        Lighting.Ambient, Lighting.OutdoorAmbient = orig.amb, orig.outAmb
    end)
    fxBloom.Enabled = F.bloomOn and true or false
    if F.bloomOn then fxBloom.Intensity, fxBloom.Size, fxBloom.Threshold = F.bloomInt, F.bloomSize, F.bloomThr end
    fxCC.Enabled = F.ccOn and true or false
    if F.ccOn then
        fxCC.Saturation, fxCC.Contrast, fxCC.Brightness = F.sat, F.contrast, F.ccBright
        fxCC.TintColor = TINTS[F.tint] or TINTS.Neutro
    end
    fxRays.Enabled = F.raysOn and true or false
    if F.raysOn then fxRays.Intensity, fxRays.Spread = F.raysInt, F.raysSpread end
end
local function restoreVisuals()
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = orig.fov end
        Lighting.ClockTime, Lighting.Brightness = orig.clock, orig.bright
        Lighting.ExposureCompensation = orig.expo
        Lighting.FogEnd, Lighting.FogStart, Lighting.FogColor = orig.fogEnd, orig.fogStart, orig.fogColor
        Lighting.Ambient, Lighting.OutdoorAmbient = orig.amb, orig.outAmb
        fxBloom:Destroy(); fxCC:Destroy(); fxRays:Destroy()
    end)
end
local bulk = false
local function visCb() if not bulk then applyVisuals() end end

-- ═════════════════════════ PAGINE ═════════════════════════
local home     = makeTab("Home", "🏠", "")
local visuals  = makeTab("Visuals", "👁", "")
local world    = makeTab("World", "🌅", "")
local keybinds = makeTab("Keybinds", "⌨️", "")
local settings = makeTab("Settings", "⚙️", "")

local PRESET_NAMES = {"Originale", "Sakura Dream", "Noir", "Vivid", "Nebbia fredda", "Golden Hour", "Pastello"}
local PRESETS = {
    ["Originale"] = {},
    ["Sakura Dream"] = {bloomOn = true, bloomInt = 0.6, bloomSize = 28, bloomThr = 0.85, ccOn = true,
        sat = 0.25, contrast = 0.08, ccBright = 0.02, tint = "Rosa", raysOn = true, raysInt = 0.08, amb = "Rosa"},
    ["Noir"] = {ccOn = true, sat = -1, contrast = 0.3, ccBright = -0.02, tint = "Neutro"},
    ["Vivid"] = {ccOn = true, sat = 0.7, contrast = 0.15, bloomOn = true, bloomInt = 0.3, bloomSize = 20, bloomThr = 0.95},
    ["Nebbia fredda"] = {ccOn = true, sat = -0.15, contrast = 0.05, tint = "Freddo", fogOn = true, fogDist = 700, fogColor = "Blu"},
    ["Golden Hour"] = {timeOn = true, time = 17.3, ccOn = true, sat = 0.2, contrast = 0.1, tint = "Caldo",
        bloomOn = true, bloomInt = 0.5, bloomSize = 30, bloomThr = 0.8, raysOn = true, raysInt = 0.15, amb = "Dorato"},
    ["Pastello"] = {ccOn = true, sat = -0.1, contrast = -0.05, ccBright = 0.06, tint = "Rosa",
        bloomOn = true, bloomInt = 0.8, bloomSize = 34, bloomThr = 0.75},
}
local VISUAL_FLAGS = {"fovOn", "fov", "timeOn", "time", "lightOn", "bright", "expo", "fogOn", "fogDist",
    "fogColor", "amb", "bloomOn", "bloomInt", "bloomSize", "bloomThr", "ccOn", "sat", "contrast",
    "ccBright", "tint", "raysOn", "raysInt", "raysSpread"}
local function applyPreset(name)
    local p = PRESETS[name]
    if not p then return end
    bulk = true
    for _, k in ipairs(VISUAL_FLAGS) do
        if Setters[k] and Defaults[k] ~= nil then Settersk end
    end
    for k, v in pairs(p) do if Setters[k] then Settersk end end
    bulk = false
    applyVisuals()
end
env.__SakuraPreset = function(name)
    applyPreset(name)
    notify("Preset applicato", name, "success")
end

local statLabels = {}
local orbit, heroFlowerGlow, heroRingGrad, quoteFill

-- ───────── HOME ─────────
do
    local L, R = home:Columns(0.62)

    -- hero
    L.order += 1
    local hero = new("Frame", {
        Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.1, BorderSizePixel = 0, LayoutOrder = L.order, ClipsDescendants = true,
    }, L.scroller)
    searchIndex[#searchIndex + 1] = {row = hero, name = "", section = true, tab = home}
    corner(hero, 16)
    local hst = stroke(hero, C.a, 1.6, 0.2)
    themed(function(i) tw(hst, i, {Color = C.a}) end)
    local hg = new("UIGradient", {Rotation = 15}, hero)
    themed(function() hg.Color = ColorSequence.new(C.panel, C.panel:Lerp(C.a, 0.5)) end)

    local chip = new("Frame", {
        Position = UDim2.fromOffset(22, 20), Size = UDim2.fromOffset(118, 24),
        BackgroundTransparency = 1, BorderSizePixel = 0}, hero)
    corner(chip, 12)
    local cs = stroke(chip, C.a, 1.3, 0.1)
    local chipTxt = text(chip, "BENTORNATO", 10, FONT_B, C.a, {Size = UDim2.fromScale(1, 1), TextXAlignment = CENTER})
    themed(function() cs.Color = C.a; chipTxt.TextColor3 = C.a end)

    local big = text(hero, "", 44, FONT_B, C.text, {
        Position = UDim2.fromOffset(22, 52), Size = UDim2.new(0.6, 0, 0, 54), RichText = true})
    themed(function() big.Text = "Sakura" .. '<font color="' .. hex(C.a) .. '">.ui</font>' end)
    textGlow(big, 3, 0.7)
    text(hero, "Un'esperienza più pulita e fluida.", 14, FONT_M, C.b, {
        Position = UDim2.fromOffset(24, 110), Size = UDim2.new(0.62, 0, 0, 20)})
    pill(hero, "Esplora  →", {Position = UDim2.fromOffset(24, 142), Size = UDim2.fromOffset(136, 38)},
        function() selectTab(visuals) end)

    -- fiore con anello e scintille
    heroFlowerGlow = glow(hero, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -125, 0.5, 0),
        Size = UDim2.fromOffset(230, 230), ImageTransparency = 0.45})
    local ring = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -125, 0.5, 0),
        Size = UDim2.fromOffset(148, 148), BackgroundTransparency = 1}, hero)
    corner(ring, 74)
    local rs = stroke(ring, C.b, 2, 0)
    heroRingGrad = new("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0)})}, rs)
    themed(function() rs.Color = C.b end)
    local flower = text(hero, "🌸", 92, FONT_M, C.text, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -125, 0.5, 0),
        Size = UDim2.fromOffset(110, 110), TextXAlignment = CENTER})
    local orbitBase = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -125, 0.5, 0),
        Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1, Rotation = -18}, hero)
    orbit = {}
    for i = 1, 5 do
        local s = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(i % 2 == 0 and 5 or 7, i % 2 == 0 and 5 or 7),
            BackgroundColor3 = C.b, BorderSizePixel = 0}, orbitBase)
        corner(s, 4)
        glow(s, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(46, 46), ImageTransparency = 0.4})
        orbit[i] = {obj = s, a = (i / 5) * math.pi * 2, speed = 0.7 + i * 0.12}
    end

    -- info rapide
    local ci = R:Card({Title = "Info rapide", Icon = "ℹ️", Tag = "live"})
    local function infoRow(icon, label, value, color)
        local row = ci:_row(46, label)
        ci:_title(row, label, nil, 150, 46, icon)
        return text(row, value, 13, FONT_B, color or C.text, {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(130, 20), TextXAlignment = RIGHT})
    end
    infoRow("🖥", "Interfaccia", BRAND:sub(1, 1) .. BRAND:sub(2):lower() .. BRAND_S:lower())
    infoRow("⚙️", "Versione", VERSION)
    infoRow("✅", "Stato", "● Pronto", C.good)
    local qf = ci:Frame(44)
    text(qf, "“Più stile, più fluidità.”", 12, FONT_M, C.b, {
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, 0, 0, 22)})
    local qTrack = new("Frame", {
        Position = UDim2.new(0, 2, 0, 30), Size = UDim2.new(1, -4, 0, 4),
        BackgroundColor3 = C.elev2, BorderSizePixel = 0}, qf)
    corner(qTrack, 2)
    quoteFill = new("Frame", {
        Size = UDim2.new(0.38, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, qTrack)
    corner(quoteFill, 2)
    local qg = new("UIGradient", {}, quoteFill)
    themed(function() qg.Color = ColorSequence.new(C.a, C.b) end)
    glow(quoteFill, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 30, 0, 40), ImageTransparency = 0.5})

    -- riga 2
    local L2, R2 = home:Columns(0.5)
    local perf = L2:Card({Title = "Performance", Icon = "📈", Tag = "live"})
    local grid = perf:Frame(128)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 60), CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    local function tile(title, order)
        local f = new("Frame", {
            BackgroundColor3 = C.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = order}, grid)
        corner(f, 11)
        stroke(f, C.line, 1, 0.5)
        text(f, title:upper(), 10, FONT_B, C.muted, {
            Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 14)})
        return text(f, "–", 20, FONT_B, C.text, {
            Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24, 0, 28)})
    end
    statLabels.fps = tile("FPS", 1)
    statLabels.ping = tile("Ping", 2)
    statLabels.players = tile("Giocatori", 3)
    statLabels.mem = tile("Memoria", 4)
    textGlow(statLabels.fps, 1.5, 0.8)

    local gf = perf:Frame(92)
    statLabels.uptime = text(gf, "sessione 00:00", 10, FONT_M, C.muted, {
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -4, 0, 14)})
    local plot = new("Frame", {
        Position = UDim2.fromOffset(2, 20), Size = UDim2.new(1, -4, 1, -22), BackgroundTransparency = 1}, gf)
    local N = 40
    statLabels.bars, statLabels.hist = {}, {}
    for i = 1, N do
        statLabels.hist[i] = 0
        local b = new("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / N, 1, 1, 0),
            Size = UDim2.new(1 / N, -2, 0.04, 0), BackgroundColor3 = C.a, BorderSizePixel = 0}, plot)
        corner(b, 2)
        statLabels.bars[i] = b
    end
    themed(function() for _, b in ipairs(statLabels.bars) do b.BackgroundColor3 = C.a end end)

    local qp = R2:Card({Title = "Preset rapidi", Icon = "🎨", Tag = "visuals"})
    qp:Button({Name = "Sakura Dream", Desc = "Bloom morbido e tinta rosa", Icon = "🌸", Primary = true,
        Callback = function() env.__SakuraPreset("Sakura Dream") end})
    qp:Button({Name = "Golden Hour", Desc = "Luce calda del tramonto", Icon = "🌇",
        Callback = function() env.__SakuraPreset("Golden Hour") end})
    qp:Button({Name = "Pastello", Desc = "Colori dolci e luminosi", Icon = "🍡",
        Callback = function() env.__SakuraPreset("Pastello") end})
    qp:Button({Name = "Test notifica", Icon = "🔔", Callback = function()
        notify("Tutto ok", "Le notifiche funzionano correttamente.", "success")
    end})
end

-- ───────── VISUALS ─────────
do
    local top = visuals:Card({Title = "Preset", Icon = "✨", Tag = "1-click"})
    top:Dropdown({Name = "Preset visivo", Icon = "🎨", Options = PRESET_NAMES, Default = "Originale", NoFlag = true,
        Callback = function(v) env.__SakuraPreset(v) end})

    local L, R = visuals:Columns(0.5)
    local cam = L:Card({Title = "Camera", Icon = "🎥", Tag = "view"})
    cam:Toggle({Name = "FOV personalizzato", Desc = "Forza il campo visivo", Icon = "👁", Flag = "fovOn", Callback = visCb})
    cam:Slider({Name = "Campo visivo", Icon = "🔭", Flag = "fov", Min = 40, Max = 120, Default = 80, Step = 1, Suffix = "°", Callback = visCb})

    local bl = L:Card({Title = "Bloom", Icon = "💫", Tag = "glow"})
    bl:Toggle({Name = "Bloom", Desc = "Bagliore sulle zone luminose", Icon = "✨", Flag = "bloomOn", Callback = visCb})
    bl:Slider({Name = "Intensità", Flag = "bloomInt", Icon = "🔆", Min = 0, Max = 2, Default = 0.4, Step = 0.05, Callback = visCb})
    bl:Slider({Name = "Dimensione", Flag = "bloomSize", Icon = "⭕", Min = 0, Max = 56, Default = 24, Step = 1, Callback = visCb})
    bl:Slider({Name = "Soglia", Flag = "bloomThr", Icon = "🎚", Min = 0, Max = 2, Default = 0.9, Step = 0.05, Callback = visCb})

    local co = R:Card({Title = "Colore", Icon = "🎨", Tag = "grading"})
    co:Toggle({Name = "Color correction", Icon = "🌈", Flag = "ccOn", Callback = visCb})
    co:Slider({Name = "Saturazione", Icon = "💧", Flag = "sat", Min = -1, Max = 2, Default = 0, Step = 0.05, Callback = visCb})
    co:Slider({Name = "Contrasto", Icon = "◐", Flag = "contrast", Min = -1, Max = 1, Default = 0, Step = 0.05, Callback = visCb})
    co:Slider({Name = "Luminosità", Icon = "☀️", Flag = "ccBright", Min = -0.5, Max = 0.5, Default = 0, Step = 0.01, Callback = visCb})
    co:Dropdown({Name = "Tinta", Icon = "🖌", Flag = "tint", Options = {"Neutro", "Rosa", "Caldo", "Freddo", "Lilla"},
        Default = "Neutro", Callback = visCb})

    local ra = R:Card({Title = "Raggi di luce", Icon = "🌤", Tag = "rays"})
    ra:Toggle({Name = "Sun rays", Icon = "☀️", Flag = "raysOn", Callback = visCb})
    ra:Slider({Name = "Intensità", Flag = "raysInt", Icon = "🔆", Min = 0, Max = 1, Default = 0.1, Step = 0.01, Callback = visCb})
    ra:Slider({Name = "Diffusione", Flag = "raysSpread", Icon = "📡", Min = 0, Max = 1, Default = 0.5, Step = 0.05, Callback = visCb})
end

-- ───────── WORLD ─────────
do
    local L, R = world:Columns(0.5)
    local ti = L:Card({Title = "Orario", Icon = "🕒", Tag = "time"})
    ti:Toggle({Name = "Blocca orario", Desc = "Mantiene l'ora scelta", Icon = "🔒", Flag = "timeOn", Callback = visCb})
    ti:Slider({Name = "Ora del giorno", Icon = "🌗", Flag = "time", Min = 0, Max = 24, Default = 14, Step = 0.1, Suffix = " h", Callback = visCb})

    local li = L:Card({Title = "Illuminazione", Icon = "💡", Tag = "light"})
    li:Toggle({Name = "Modifica illuminazione", Icon = "💡", Flag = "lightOn", Callback = visCb})
    li:Slider({Name = "Luminosità", Flag = "bright", Icon = "☀️", Min = 0, Max = 6, Default = 2, Step = 0.1, Callback = visCb})
    li:Slider({Name = "Esposizione", Flag = "expo", Icon = "📷", Min = -3, Max = 3, Default = 0, Step = 0.1, Callback = visCb})
    li:Dropdown({Name = "Tinta ambiente", Icon = "🎨", Flag = "amb",
        Options = {"Originale", "Rosa", "Lilla", "Blu", "Dorato"}, Default = "Originale", Callback = visCb})

    local fo = R:Card({Title = "Nebbia", Icon = "🌫", Tag = "fog"})
    fo:Toggle({Name = "Nebbia", Icon = "🌫", Flag = "fogOn", Callback = visCb})
    fo:Slider({Name = "Distanza", Flag = "fogDist", Icon = "↔️", Min = 50, Max = 3000, Default = 800, Step = 10, Suffix = " st", Callback = visCb})
    fo:Dropdown({Name = "Colore nebbia", Icon = "🎨", Flag = "fogColor",
        Options = {"Bianca", "Rosa", "Blu", "Grigia"}, Default = "Bianca", Callback = visCb})

    local rs = R:Card({Title = "Ripristino", Icon = "↩️", Tag = "reset"})
    rs:Button({Name = "Ripristina ambiente", Desc = "Torna ai valori di quando hai avviato lo script", Icon = "↩️",
        Callback = function() applyPreset("Originale"); notify("Ambiente ripristinato", "Valori originali rimessi.", "success") end})
end

-- ───────── KEYBINDS ─────────
do
    local kb = keybinds:Card({Title = "Scorciatoie", Icon = "⌨️", Tag = "tastiera"})
    kb:Keybind({Name = "Mostra / nascondi", Icon = "👁", Flag = "toggleKey", Default = "RightShift"})
    kb:Keybind({Name = "Tab successivo (Ctrl +)", Icon = "➡️", Flag = "nextKey", Default = "Right"})
    kb:Keybind({Name = "Tab precedente (Ctrl +)", Icon = "⬅️", Flag = "prevKey", Default = "Left"})
    kb:Keybind({Name = "Cerca (Ctrl +)", Icon = "🔍", Flag = "searchKey", Default = "F"})
    keybinds:Label("Clicca su un tasto e premi quello nuovo. <b>Esc</b> annulla. Le scorciatoie di tab e ricerca funzionano tenendo premuto <b>Ctrl</b>.")
end

-- ───────── SETTINGS ─────────
local function setThemeByName(name, silent)
    for _, th in ipairs(THEMES) do
        if th.name == name then
            Flags.theme = name
            applyTheme(th.a, th.b)
            if not silent then notify("Tema " .. name, "Colori aggiornati in tempo reale.", "info", 2.2) end
            return
        end
    end
end

local CFG_DIR = "SakuraUI"
local function fsOk() return typeof(writefile) == "function" and typeof(readfile) == "function" end
local function cfgPath()
    local n = (tostring(Flags.cfgName or "default"):gsub("[^%w_%-]", ""))
    if n == "" then n = "default" end
    return CFG_DIR .. "/" .. n .. ".json"
end
local function refreshAll() fitScale(); refreshPetals(); refreshBlur(); applyVisuals() end
local function saveConfig()
    if not fsOk() then notify("Config", "Questo ambiente non supporta il salvataggio su file.", "warn") return end
    pcall(function() if typeof(isfolder) == "function" and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
    local data = {}
    for k, v in pairs(Flags) do if not NoSave[k] then data[k] = v end end
    local ok, err = pcall(function() writefile(cfgPath(), HttpService:JSONEncode(data)) end)
    if ok then notify("Config salvata", cfgPath(), "success") else notify("Errore salvataggio", tostring(err), "error") end
end
local function loadConfig()
    if not fsOk() then notify("Config", "Questo ambiente non supporta il caricamento da file.", "warn") return end
    local path = cfgPath()
    if typeof(isfile) == "function" and not isfile(path) then notify("Config non trovata", path, "warn") return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then notify("Errore lettura", "File non valido.", "error") return end
    bulk = true
    for k, v in pairs(data) do if Setters[k] and not NoSave[k] then pcall(Setters[k], v, true) end end
    bulk = false
    refreshAll()
    notify("Config caricata", path, "success")
end
local function resetDefaults()
    bulk = true
    for k, v in pairs(Defaults) do if Setters[k] and not NoSave[k] then pcall(Setters[k], v, true) end end
    bulk = false
    refreshAll()
    notify("Impostazioni ripristinate", "Valori predefiniti rimessi.", "success")
end
local unload

do
    local L, R = settings:Columns(0.5)
    local th = L:Card({Title = "Tema", Icon = "🎨", Tag = "colori"})
    local row = th:_row(80, "tema colore")
    text(row, "Colore accento", 14, FONT_M, C.text, {
        Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 18)})
    local rings = {}
    for i, t in ipairs(THEMES) do
        local b = new("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundColor3 = t.a, BorderSizePixel = 0,
            Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(16 + (i - 1) * 44, 38)}, row)
        corner(b, 15)
        glow(b, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(78, 78), ImageTransparency = 0.5}).ImageColor3 = t.a
        rings[t.name] = stroke(b, Color3.new(1, 1, 1), 2.5, 1)
        bind(b.MouseEnter, function() T(b, 0.2, {Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14 + (i - 1) * 44, 36)}, Enum.EasingStyle.Back) end)
        bind(b.MouseLeave, function() T(b, 0.2, {Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(16 + (i - 1) * 44, 38)}) end)
        bind(b.MouseButton1Click, function() setThemeByName(t.name) end)
    end
    Flags.theme, Defaults.theme = "Sakura", "Sakura"
    Setters.theme = function(v) setThemeByName(v, true) end
    themed(function(i)
        for name, ring in pairs(rings) do tw(ring, i, {Transparency = (name == Flags.theme) and 0 or 1}, 0.25) end
    end)

    local ui = L:Card({Title = "Interfaccia", Icon = "🖼", Tag = "ui"})
    ui:Slider({Name = "Scala interfaccia", Icon = "🔎", Flag = "uiScale", Min = 0.7, Max = 1.3, Default = 1, Step = 0.05, Suffix = "×", Callback = fitScale})
    ui:Toggle({Name = "Sfocatura sfondo", Icon = "🌫", Flag = "blurOn", Default = true, Callback = refreshBlur})
    ui:Slider({Name = "Intensità sfocatura", Icon = "💨", Flag = "blurAmt", Min = 0, Max = 30, Default = 14, Step = 1, Callback = refreshBlur})

    local sk = R:Card({Title = "Sakura", Icon = "🌸", Tag = "petali"})
    sk:Toggle({Name = "Petali animati", Icon = "🌸", Flag = "petals", Default = true, Callback = refreshPetals})
    sk:Slider({Name = "Numero petali", Icon = "🔢", Flag = "petalCount", Min = 0, Max = MAXP, Default = 24, Step = 1, Callback = refreshPetals})
    sk:Slider({Name = "Vento", Icon = "🍃", Flag = "wind", Min = 0, Max = 2, Default = 1, Step = 0.1})

    local cf = R:Card({Title = "Configurazione", Icon = "💾", Tag = "file"})
    cf:Textbox({Name = "Nome profilo", Icon = "📝", Flag = "cfgName", Default = "default", Placeholder = "nome file"})
    cf:Button({Name = "Salva configurazione", Icon = "💾", Primary = true, Callback = saveConfig})
    cf:Button({Name = "Carica configurazione", Icon = "📂", Callback = loadConfig})
    cf:Button({Name = "Ripristina predefiniti", Icon = "↩️", Callback = resetDefaults})
    cf:Button({Name = "Scarica interfaccia", Desc = "Rimuove la UI e ripristina gli effetti", Icon = "⏏️", Danger = true,
        Callback = function() unload() end})
end

-- ═════════════════════════ INPUT GLOBALE ═════════════════════════
local function cycleTab(dir)
    local idx = current and current.index or 1
    selectTab(tabs[((idx - 1 + dir) % #tabs) + 1])
end
bind(UserInputService.InputBegan, function(input, processed)
    if listeningKey then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if processed then return end
    local name = input.KeyCode.Name
    if name == (Flags.toggleKey or "RightShift") then
        setVisible(not uiVisible)
        return
    end
    if not uiVisible then return end
    local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    if not ctrl then return end
    if name == Flags.nextKey then cycleTab(1)
    elseif name == Flags.prevKey then cycleTab(-1)
    elseif name == Flags.searchKey then
        task.defer(function()
            searchBox:CaptureFocus()
            RunService.RenderStepped:Wait()
            searchBox.Text = ""
        end)
    end
end)

-- ═════════════════════════ LOOP PRINCIPALE ═════════════════════════
local elapsed, statAcc, frames, visTimer, uptime = 0, 0, 0, 0, 0
local mouseSmooth = Vector2.zero

bind(RunService.RenderStepped, function(rawDt)
    if not running then return end
    local dt = math.min(rawDt, 0.05)
    elapsed += dt
    uptime += rawDt

    if Flags.fovOn then
        local cam = workspace.CurrentCamera
        if cam and math.abs(cam.FieldOfView - Flags.fov) > 0.01 then cam.FieldOfView = Flags.fov end
    end
    visTimer += rawDt
    if visTimer >= 0.3 then visTimer = 0; applyVisuals() end

    statAcc += rawDt
    frames += 1
    if statAcc >= 0.25 then
        local fps = math.floor(frames / statAcc + 0.5)
        frames, statAcc = 0, 0
        footFps.Text = fps .. " fps"
        if statLabels.fps then
            statLabels.fps.Text = tostring(fps)
            statLabels.fps.TextColor3 = fps >= 55 and C.good or fps >= 30 and C.warn or C.bad
            local ok, ping = pcall(function() return player:GetNetworkPing() end)
            statLabels.ping.Text = ok and (math.floor(ping * 1000) .. " ms") or "–"
            statLabels.players.Text = tostring(#Players:GetPlayers())
            local okm, mem = pcall(function() return StatsService:GetTotalMemoryUsageMb() end)
            statLabels.mem.Text = okm and (math.floor(mem) .. " MB") or "–"
            statLabels.uptime.Text = string.format("sessione %02d:%02d", uptime // 60, uptime % 60)
            table.remove(statLabels.hist, 1)
            table.insert(statLabels.hist, fps)
            if uiVisible and current == home then
                local n = #statLabels.bars
                for i, b in ipairs(statLabels.bars) do
                    b.Size = UDim2.new(1 / n, -2, math.clamp(statLabels.hist[i] / 90, 0.04, 1), 0)
                end
            end
        end
    end

    if math.abs(tgtX - posX) > 0.05 or math.abs(tgtY - posY) > 0.05 then
        local a = 1 - math.exp(-18 * dt)
        posX += (tgtX - posX) * a
        posY += (tgtY - posY) * a
        root.Position = UDim2.new(0.5, posX, 0, posY)
    end

    if not uiVisible then return end

    edgeGrad.Rotation = (elapsed * 40) % 360
    glow1.Position = UDim2.fromScale(0.28 + 0.08 * math.sin(elapsed * 0.35), 0.3 + 0.08 * math.cos(elapsed * 0.27))
    glow2.Position = UDim2.fromScale(0.82 + 0.07 * math.cos(elapsed * 0.3), 0.85 + 0.06 * math.sin(elapsed * 0.4))
    readyDot.BackgroundTransparency = 0.5 * (0.5 + 0.5 * math.sin(elapsed * 3))
    moonGlow.ImageTransparency = 0.4 + 0.08 * math.sin(elapsed * 1.4)
    logoGlow.ImageTransparency = 0.5 + 0.1 * math.sin(elapsed * 2)

    if current == home and orbit then
        heroFlowerGlow.ImageTransparency = 0.45 + 0.1 * math.sin(elapsed * 2)
        heroRingGrad.Rotation = (elapsed * 70) % 360
        for _, s in ipairs(orbit) do
            s.a += s.speed * dt
            s.obj.Position = UDim2.fromOffset(math.cos(s.a) * 88, math.sin(s.a) * 34)
        end
        quoteFill.Position = UDim2.new(0.62 * (0.5 + 0.5 * math.sin(elapsed * 0.9)), 0, 0, 0)
    end

    if Flags.petals then
        local vp = viewport()
        local m = UserInputService:GetMouseLocation()
        local target = Vector2.new(vp.X > 0 and (m.X / vp.X - 0.5) or 0, vp.Y > 0 and (m.Y / vp.Y - 0.5) or 0)
        mouseSmooth = mouseSmooth:Lerp(target, 1 - math.exp(-4 * dt))
        local wind = (math.noise(elapsed * 0.12, 0.5) * 1.6 + math.sin(elapsed * 0.27) * 0.25) * (Flags.wind or 1)
        for i = 1, math.min(Flags.petalCount or 0, MAXP) do
            local p = petals[i]
            local o = p.obj
            p.y += p.speed * dt * (0.8 + p.depth * 0.35)
            p.x += wind * 0.02 * p.depth * dt
            p.rot = (p.rot + (p.rotSpeed + wind * 14) * dt) % 360
            if p.x > 1.05 then p.x = -0.05 elseif p.x < -0.05 then p.x = 1.05 end
            if p.y > 1.05 then
                p.y = -0.05
                p.x = math.random()
                p.phase = math.random() * 6.28
            end
            local drift = math.sin(elapsed * p.freq + p.phase) * p.amp
            o.Position = UDim2.new(p.x, drift - mouseSmooth.X * 18 * p.depth, p.y, -mouseSmooth.Y * 10 * p.depth)
            local flip = 0.55 + 0.45 * math.abs(math.cos(elapsed * p.fs + p.fl))
            o.Size = UDim2.fromOffset(p.base.X.Offset * flip, p.base.Y.Offset)
            o.Rotation = p.rot
        end
    end
end)

-- ═════════════════════════ UNLOAD + AVVIO ═════════════════════════
unload = function()
    if not running then return end
    setVisible(false)
    running = false
    restoreVisuals()
    for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
    table.clear(conns)
    if blur then T(blur, 0.3, {Size = 0}) end
    task.delay(0.5, function()
        if blur then blur:Destroy() end
        if gui then gui:Destroy() end
    end)
    env.__SakuraUnload = nil
    env.__SakuraPreset = nil
end
env.__SakuraUnload = unload
bind(gui.Destroying, function() if running then unload() end end)

refreshAll()
selectTab(home, true)
setVisible(true)
task.delay(0.6, function()
    notify("Sakura.ui v" .. VERSION, "Benvenuto! " .. string.upper(Flags.toggleKey) .. " per mostrare/nascondere.", "info", 4.5)
end)
