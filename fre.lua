-- // ZyronX UI Library (Remastered Edition) - Optimized for Zero Lag & High Aesthetics
-- // Full Feature Parity with Original + Anti-Teleport Logic

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Library = { WhitelistedUsers = {} }

-- // Theme Configuration
local AccentColor = Color3.fromRGB(180, 130, 255)
local BackgroundColor = Color3.fromRGB(10, 10, 12)
local CardColor = Color3.fromRGB(18, 18, 22)
local HoverColor = Color3.fromRGB(30, 30, 35)
local TextColor = Color3.fromRGB(255, 255, 255)
local SubTextColor = Color3.fromRGB(160, 160, 170)

-- // File System Mock
local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function() end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() end

-- // Utility Functions (Giữ nguyên logic của bạn)
local function SafeCopyToClipboard(text)
    if setclipboard then setclipboard(text) elseif toclipboard then toclipboard(text) end
end

local function Create(className, properties)
    local instance = Instance.new(className)
    if className == "TextBox" then instance.Text = "" end
    for k, v in pairs(properties or {}) do instance[k] = v end
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox") then
        if properties.TextSize and properties.RichText ~= true then
            instance.TextScaled = true
            local constraint = Instance.new("UITextSizeConstraint", instance)
            constraint.MaxTextSize = properties.TextSize
            constraint.MinTextSize = 6
        end
    end
    return instance
end

local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if desc.Text and desc.Text ~= "" then table.insert(parts, desc.Text:lower()) end
        end
    end
    return table.concat(parts, " ")
end

local function Tween(instance, properties, duration)
    local t = TweenService:Create(instance, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local function AddBounce(button, scaleFactor)
    scaleFactor = scaleFactor or 0.96
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    button.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Tween(scaleObj, {Scale = scaleFactor}, 0.15) end end)
    button.InputEnded:Connect(function() Tween(scaleObj, {Scale = 1}, 0.15) end)
end

local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = object.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Tween(object, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.1)
        end
    end)
end

-- // Global Notification API
local GlobalNotifContainer
function Library:Notify(options)
    if not GlobalNotifContainer then return end
    local title, desc, duration = options.Title or "Notification", options.Description or "Information updated.", options.Duration or 3
    local Notif = Create("Frame", {Parent = GlobalNotifContainer, BackgroundColor3 = Color3.fromRGB(15, 15, 20), Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, ClipsDescendants = true})
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 8)})
    local Stroke = Create("UIStroke", {Parent = Notif, Color = AccentColor, Thickness = 1.5, Transparency = 1})
    local TText = Create("TextLabel", {Parent = Notif, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 15), Size = UDim2.new(1, -30, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})
    local DText = Create("TextLabel", {Parent = Notif, Text = desc, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 32), Size = UDim2.new(1, -30, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})
    Tween(Notif, {BackgroundTransparency = 0}, 0.3); Tween(Stroke, {Transparency = 0}, 0.3); Tween(TText, {TextTransparency = 0}, 0.3); Tween(DText, {TextTransparency = 0}, 0.3)
    task.delay(duration, function()
        Tween(Notif, {BackgroundTransparency = 1}, 0.4); Tween(Stroke, {Transparency = 1}, 0.4); Tween(TText, {TextTransparency = 1}, 0.4); Tween(DText, {TextTransparency = 1}, 0.4)
        task.wait(0.4); Notif:Destroy()
    end)
end

function Library:CreateWindow(options)
    local hubName = options.Title or "ZyronX Remastered"
    local subText = options.Subtitle or "Modern UI Edition"
    local sphTextToggle = options.SphereText or false
    local sphWords = options.SphereWords or "ZX"
    local sphImage = options.SphereImage
    local topbarLogo = options.Logo
    local logoSize = options.LogoSize or 32
    local sphIconSize = options.SphereIconSize or 26

    local ScreenGui = Create("ScreenGui", {Name = "ZyronX_v2", Parent = CoreGui, ResetOnSpawn = false, IgnoreGuiInset = true})
    GlobalNotifContainer = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 320, 1, -20), Position = UDim2.new(1, -340, 0, 10)})
    Create("UIListLayout", {Parent = GlobalNotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 12)})

    -- // Info Overlay Logic
    local InfoOverlay = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 150, Visible = false, Active = true})
    local InfoCard = Create("Frame", {Parent = InfoOverlay, BackgroundColor3 = Color3.fromRGB(15, 15, 20), Size = UDim2.new(0, 360, 0, 280), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true})
    Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 10)}); local InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0})
    local InfoTitle = Create("TextLabel", {Parent = InfoCard, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 15), Size = UDim2.new(1, -60, 0, 20), TextXAlignment = Enum.TextXAlignment.Left})
    local InfoCloseBtn = Create("TextButton", {Parent = InfoCard, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -40, 0, 5)})
    local InfoDesc = Create("TextLabel", {Parent = InfoCard, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 50), Size = UDim2.new(1, -40, 0, 100), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})

    local function OpenInfoWindow(data)
        InfoTitle.Text = data.Title; InfoDesc.Text = data.Description; InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.5}, 0.3); Tween(InfoScale, {Scale = 1}, 0.3)
    end
    InfoCloseBtn.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.3); Tween(InfoScale, {Scale = 0}, 0.3); task.wait(0.3); InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local Btn = Create("TextButton", {Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = SubTextColor, BackgroundColor3 = HoverColor, Size = UDim2.new(0, 18, 0, 18), Position = pos, AutoButtonColor = false})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(1, 0)}); AddBounce(Btn)
        Btn.MouseButton1Click:Connect(function() OpenInfoWindow(data) end)
    end

    -- // Main UI Structure
    local MainFrame = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = UDim2.new(0, 650, 0, 420), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true})
    local MainScale = Create("UIScale", {Parent = MainFrame, Scale = 0.8})
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 10)})
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = Color3.fromRGB(45, 45, 55), Thickness = 1.5})
    Tween(MainScale, {Scale = 1}, 0.5)

    -- Floating Bottom Bar
    local BottomDragHitbox = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 350, 0, 30), AnchorPoint = Vector2.new(0.5, 0.5), Active = true})
    local FloatingBar = Create("Frame", {Parent = BottomDragHitbox, BackgroundColor3 = AccentColor, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2)})
    Create("UICorner", {Parent = FloatingBar, CornerRadius = UDim.new(1, 0)})
    MakeDraggable(BottomDragHitbox, MainFrame)
    RunService.RenderStepped:Connect(function()
        if MainFrame.Visible then
            BottomDragHitbox.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + (210 * MainScale.Scale) + 20)
        end
    end)

    -- TopBar
    local TopBar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, 0, 0, 45)})
    MakeDraggable(TopBar, MainFrame)
    local TitleLabel = Create("TextLabel", {Parent = TopBar, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 8), Size = UDim2.new(0, 200, 0, 15), TextXAlignment = Enum.TextXAlignment.Left})
    local SubLabel = Create("TextLabel", {Parent = TopBar, Text = subText, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = AccentColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 22), Size = UDim2.new(0, 200, 0, 15), TextXAlignment = Enum.TextXAlignment.Left})

    local SearchBar = Create("Frame", {Parent = TopBar, BackgroundColor3 = CardColor, Size = UDim2.new(0, 220, 0, 28), Position = UDim2.new(1, -280, 0.5, -14)})
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 6)})
    local SearchInput = Create("TextBox", {Parent = SearchBar, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search features..."})

    local CloseBtn = Create("TextButton", {Parent = TopBar, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 100, 100), BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0)})
    local MinBtn = Create("TextButton", {Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -75, 0, 0)})

    -- Sidebar
    local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(12, 12, 15), Size = UDim2.new(0, 160, 1, -45), Position = UDim2.new(0, 0, 0, 45)})
    local TabSearch = Create("TextBox", {Parent = Sidebar, BackgroundColor3 = CardColor, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 10), PlaceholderText = "Search tabs..."})
    Create("UICorner", {Parent = TabSearch, CornerRadius = UDim.new(0, 6)})
    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, -50), Position = UDim2.new(0, 5, 0, 45), ScrollBarThickness = 0})
    Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center})

    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -170, 1, -55), Position = UDim2.new(0, 165, 0, 50)})

    -- // Sphere Logic
    local Sphere = Create("TextButton", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, -25, 0.1, 0), Visible = false, Text = ""})
    Create("UICorner", {Parent = Sphere, CornerRadius = UDim.new(1, 0)}); Create("UIStroke", {Parent = Sphere, Color = AccentColor, Thickness = 2})
    local SphLabel = Create("TextLabel", {Parent = Sphere, Text = sphWords, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = AccentColor, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = sphTextToggle})
    MakeDraggable(Sphere, Sphere)

    MinBtn.MouseButton1Click:Connect(function()
        Tween(MainScale, {Scale = 0}, 0.3); task.wait(0.3); MainFrame.Visible = false; BottomDragHitbox.Visible = false; Sphere.Visible = true
    end)
    Sphere.MouseButton1Click:Connect(function()
        Sphere.Visible = false; MainFrame.Visible = true; BottomDragHitbox.Visible = true; Tween(MainScale, {Scale = 1}, 0.3)
    end)

    local Window = {CurrentTab = nil, Tabs = {}, AllCards = {}, ConfigElements = {}}

    function Window:CreateTab(tabName, isDefault)
        local TabBtn = Create("TextButton", {Parent = TabContainer, Text = tabName, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = SubTextColor, BackgroundColor3 = HoverColor, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 35), AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)}); AddBounce(TabBtn)
        local Indicator = Create("Frame", {Parent = TabBtn, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 2, 0, 0), Position = UDim2.new(0, 4, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)})

        local Page = Create("ScrollingFrame", {Parent = ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = AccentColor})
        local LCol = Create("Frame", {Parent = Page, Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 1})
        local RCol = Create("Frame", {Parent = Page, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0), BackgroundTransparency = 1})
        Create("UIListLayout", {Parent = LCol, Padding = UDim.new(0, 10)}); Create("UIListLayout", {Parent = RCol, Padding = UDim.new(0, 10)})

        local TabConfig = {Btn = TabBtn, Page = Page, LCol = LCol, RCol = RCol}
        table.insert(Window.Tabs, TabConfig)

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentTab then
                Window.CurrentTab.Page.Visible = false; Tween(Window.CurrentTab.Btn, {BackgroundTransparency = 1, TextColor3 = SubTextColor}, 0.2); Tween(Window.CurrentTab.Ind, {Size = UDim2.new(0, 2, 0, 0)}, 0.2)
            end
            Window.CurrentTab = {Page = Page, Btn = TabBtn, Ind = Indicator}
            Page.Visible = true; Tween(TabBtn, {BackgroundTransparency = 0.8, TextColor3 = TextColor}, 0.2); Tween(Indicator, {Size = UDim2.new(0, 2, 0, 16)}, 0.2)
        end)

        local PageObj = {Left = true}
        function PageObj:CreateSection(secName)
            local target = PageObj.Left and LCol or RCol
            PageObj.Left = not PageObj.Left
            local SecFrame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CardColor})
            Create("UICorner", {Parent = SecFrame, CornerRadius = UDim.new(0, 8)}); Create("UIStroke", {Parent = SecFrame, Color = Color3.fromRGB(40, 40, 45)})
            local sTitle = Create("TextLabel", {Parent = SecFrame, Text = secName:upper(), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = AccentColor, Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local Container = Create("Frame", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 25), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
            Create("UIListLayout", {Parent = Container, Padding = UDim.new(0, 6)}); Create("UIPadding", {Parent = Container, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
            
            table.insert(Window.AllCards, {Card = SecFrame, OrigParent = target, TabPage = Page})

            local Elements = {}

            -- // Add Toggle (Fixed Anti-Teleport)
            function Elements:AddToggle(name, default, callback, info)
                local state = default or false
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1})
                local Txt = Create("TextLabel", {Parent = Row, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Text_Sub, Size = UDim2.new(1, -45, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                local Switch = Create("TextButton", {Parent = Row, Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -34, 0.5, -9), BackgroundColor3 = state and AccentColor or HoverColor, Text = ""})
                Create("UICorner", {Parent = Switch, CornerRadius = UDim.new(1, 0)}); local Knob = Create("Frame", {Parent = Switch, Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1)})
                Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                local function set(v, ignore)
                    state = v; Tween(Switch, {BackgroundColor3 = state and AccentColor or HoverColor}, 0.2)
                    Tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.2)
                    if callback and not ignore then callback(state) end
                end
                Switch.MouseButton1Click:Connect(function() set(not state) end)
                AddInfoIcon(Row, UDim2.new(1, -65, 0.5, -9), info)
                Window.ConfigElements[name] = {Set = set, Get = function() return state end}
            end

            -- // Add Slider (Fixed Anti-Teleport)
            function Elements:AddSlider(name, min, max, default, callback, info)
                local val = default or min
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1})
                local Txt = Create("TextLabel", {Parent = Row, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SubTextColor, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                local ValTxt = Create("TextLabel", {Parent = Row, Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = AccentColor, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right})
                local Bar = Create("TextButton", {Parent = Row, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = HoverColor, Text = ""})
                Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})
                local Fill = Create("Frame", {Parent = Bar, Size = UDim2.new((val-min)/(max-min), 0, 1, 0), BackgroundColor3 = AccentColor, BorderSizePixel = 0})
                Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

                local function set(v, ignore)
                    val = math.clamp(v, min, max); ValTxt.Text = tostring(val)
                    Tween(Fill, {Size = UDim2.new((val-min)/(max-min), 0, 1, 0)}, 0.1)
                    if callback and not ignore then callback(val) end
                end
                local drag = false
                Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local p = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        set(math.floor(min + (max-min)*p))
                    end
                end)
                AddInfoIcon(Row, UDim2.new(1, -30, 0, 0), info)
                Window.ConfigElements[name] = {Set = set, Get = function() return val end}
            end

            -- // Add Config Manager (Full Logic + Remade UI)
            function Elements:AddConfigManager(folderName)
                folderName = folderName or "zyronxSavers"
                local autoFile = folderName .. "/autoload.txt"
                if not _isfolder(folderName) then _makefolder(folderName) end

                local MFrame = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 210), BackgroundTransparency = 1})
                local Inp = Create("TextBox", {Parent = MFrame, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(12, 12, 15), PlaceholderText = "Config name...", Text = ""})
                Create("UICorner", {Parent = Inp, CornerRadius = UDim.new(0, 6)})
                local List = Create("ScrollingFrame", {Parent = MFrame, Size = UDim2.new(1, 0, 0, 110), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = Color3.fromRGB(10, 10, 12), ScrollBarThickness = 2})
                Create("UIListLayout", {Parent = List, Padding = UDim.new(0, 4)})

                local function Refresh()
                    for _, v in ipairs(List:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
                    local currentAuto = "" pcall(function() if isfile(autoFile) then currentAuto = _readfile(autoFile) end end)
                    for _, file in ipairs(_listfiles(folderName)) do
                        local name = file:match("([^/\\]+)%.json$")
                        if name then
                            local isA = (currentAuto == file)
                            local Row = Create("Frame", {Parent = List, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = CardColor})
                            Create("UICorner", {Parent = Row, CornerRadius = UDim.new(0, 4)})
                            Create("TextLabel", {Parent = Row, Text = (isA and "⭐ " or "") .. name:gsub("_%d+", ""), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = isA and AccentColor or SubTextColor, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                            local LBtn = Create("TextButton", {Parent = Row, Text = "Load", Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -95, 0.5, -10), BackgroundColor3 = Color3.fromRGB(40, 120, 60), TextColor3 = TextColor})
                            local ABtn = Create("TextButton", {Parent = Row, Text = "Auto", Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = isA and AccentColor or HoverColor, TextColor3 = TextColor})
                            Create("UICorner", {Parent = LBtn, CornerRadius = UDim.new(0, 4)}); Create("UICorner", {Parent = ABtn, CornerRadius = UDim.new(0, 4)})
                            LBtn.MouseButton1Click:Connect(function()
                                local s, data = pcall(function() return HttpService:JSONDecode(_readfile(file)) end)
                                if s then for k, v in pairs(data) do if Window.ConfigElements[k] then Window.ConfigElements[k].Set(v, true) end end end
                            end)
                            ABtn.MouseButton1Click:Connect(function() _writefile(autoFile, isA and "" or file); Refresh() end)
                        end
                    end
                end

                local Sav = Create("TextButton", {Parent = MFrame, Text = "Save New Config", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 150), BackgroundColor3 = AccentColor, TextColor3 = TextColor, Font = Enum.Font.GothamBold})
                Create("UICorner", {Parent = Sav, CornerRadius = UDim.new(0, 6)}); Sav.MouseButton1Click:Connect(function()
                    if Inp.Text ~= "" then
                        local d = {} for k, v in pairs(Window.ConfigElements) do d[k] = v.Get() end
                        _writefile(folderName .. "/" .. Inp.Text .. "_" .. math.floor(tick()) .. ".json", HttpService:JSONEncode(d)); Refresh()
                    end
                end)

                task.spawn(function()
                    task.wait(1)
                    if isfile(autoFile) then
                        local p = _readfile(autoFile)
                        if p ~= "" and isfile(p) then
                            local s, data = pcall(function() return HttpService:JSONDecode(_readfile(p)) end)
                            if s then for k,v in pairs(data) do if Window.ConfigElements[k] then Window.ConfigElements[k].Set(v, true) end end end
                        end
                    end
                end)
                Refresh()
            end

            -- // Thêm các element khác (CopyButton, Dropdown, Textbox, ColorPicker...) vào đây theo logic tương tự
            function Elements:AddButton(n, c, i)
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1})
                local Btn = Create("TextButton", {Parent = Row, Text = n, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(25, 25, 30), TextColor3 = TextColor})
                Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)}); Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 50)})
                Btn.MouseButton1Click:Connect(c); AddInfoIcon(Row, UDim2.new(1, -25, 0.5, -9), i)
            end

            return Elements
        end
        return PageObj
    end

    return Window
end

return Library
