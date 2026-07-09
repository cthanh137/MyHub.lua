-- // ZyronX UI Library (Remastered PRO) - Optimized & Anti-Teleport Load
-- // Theme: Cyber-Dark Neon

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = { WhitelistedUsers = {} }

-- // Colors Palette
local AccentColor = Color3.fromRGB(170, 120, 255)
local BG_Main = Color3.fromRGB(13, 13, 15)
local BG_Card = Color3.fromRGB(18, 18, 22)
local BG_Hover = Color3.fromRGB(28, 28, 35)
local Text_Main = Color3.fromRGB(255, 255, 255)
local Text_Sub = Color3.fromRGB(170, 170, 180)

-- // File System Mock
local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function() end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() end

-- // Utility: Create Instance
local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties or {}) do instance[k] = v end
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox") and properties.TextSize then
        instance.TextScaled = true
        local constraint = Instance.new("UITextSizeConstraint", instance)
        constraint.MaxTextSize = properties.TextSize
        constraint.MinTextSize = 6
    end
    return instance
end

-- // Utility: Build search index
local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            if desc.Text ~= "" then table.insert(parts, desc.Text:lower()) end
        end
    end
    return table.concat(parts, " ")
end

-- // Utility: Smooth Tweening
local function Tween(instance, properties, duration)
    duration = duration or 0.25
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- // Utility: Micro-Interaction Bounce
local function AddBounce(button, scaleFactor)
    scaleFactor = scaleFactor or 0.96
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Tween(scaleObj, {Scale = scaleFactor}, 0.15) end
    end)
    button.InputEnded:Connect(function() Tween(scaleObj, {Scale = 1}, 0.15) end)
end

-- // Utility: Draggable
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
            Tween(object, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08)
        end
    end)
end

local GlobalNotifContainer
function Library:Notify(options)
    if not GlobalNotifContainer then return end
    local title = options.Title or "Notification"
    local desc = options.Description or "Updated."
    local duration = options.Duration or 3

    local Notif = Create("Frame", {Parent = GlobalNotifContainer, BackgroundColor3 = Color3.fromRGB(20, 20, 25), Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, ClipsDescendants = true})
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)})
    local str = Create("UIStroke", {Parent = Notif, Color = AccentColor, Thickness = 1, Transparency = 1})

    local TitleText = Create("TextLabel", {Parent = Notif, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Text_Main, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})
    local DescText = Create("TextLabel", {Parent = Notif, Text = desc, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Text_Sub, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 28), Size = UDim2.new(1, -20, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})

    Tween(Notif, {BackgroundTransparency = 0}, 0.3)
    Tween(str, {Transparency = 0}, 0.3)
    Tween(TitleText, {TextTransparency = 0}, 0.3)
    Tween(DescText, {TextTransparency = 0}, 0.3)

    task.delay(duration, function()
        Tween(Notif, {BackgroundTransparency = 1}, 0.4); Tween(str, {Transparency = 1}, 0.4)
        Tween(TitleText, {TextTransparency = 1}, 0.4); Tween(DescText, {TextTransparency = 1}, 0.4)
        task.wait(0.4); Notif:Destroy()
    end)
end

function Library:CreateWindow(options)
    local hubName = type(options) == "table" and options.Title or options or "ZyronX PRO"
    
    local ScreenGui = Create("ScreenGui", {
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Giao diện chính
    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = BG_Main,
        Size = UDim2.new(0, 620, 0, 400),
        Position = UDim2.new(0.5, -310, 0.5, -200),
        ClipsDescendants = true
    })
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = Color3.fromRGB(45, 45, 55), Thickness = 1.2})
    
    -- Topbar rực rỡ hơn
    local TopBar = Create("Frame", {Parent = MainFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(20, 20, 24)})
    Create("UICorner", {Parent = TopBar, CornerRadius = UDim.new(0, 8)})
    local TopStroke = Create("Frame", {Parent = TopBar, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = AccentColor, BackgroundTransparency = 0.5})
    
    local Title = Create("TextLabel", {Parent = TopBar, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Text_Main, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0, 200, 1, 0), TextXAlignment = Enum.TextXAlignment.Left})
    MakeDraggable(TopBar, MainFrame)

    -- Tìm kiếm
    local SearchBar = Create("Frame", {Parent = TopBar, BackgroundColor3 = BG_Card, Size = UDim2.new(0, 180, 0, 24), Position = UDim2.new(1, -260, 0.5, -12)})
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 6)})
    local SearchInput = Create("TextBox", {Parent = SearchBar, Text = "", PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Text_Main, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0)})

    -- Sidebar (Menu trái)
    local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(16, 16, 20), Size = UDim2.new(0, 150, 1, -40), Position = UDim2.new(0, 0, 0, 40)})
    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 0})
    Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center})

    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -160, 1, -50), Position = UDim2.new(0, 155, 0, 45)})

    -- Floating Bottom Bar (Sync với MainFrame)
    local BottomDrag = Create("Frame", {Parent = ScreenGui, Size = UDim2.new(0, 300, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1})
    local VisualBar = Create("Frame", {Parent = BottomDrag, Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = AccentColor})
    Create("UICorner", {Parent = VisualBar, CornerRadius = UDim.new(1, 0)})
    
    RunService.RenderStepped:Connect(function()
        if MainFrame.Visible then
            BottomDrag.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 215)
        end
    end)

    -- Nút đóng / thu nhỏ
    local CloseBtn = Create("TextButton", {Parent = TopBar, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 100, 100), BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0)})
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    GlobalNotifContainer = Create("Frame", {Parent = ScreenGui, Size = UDim2.new(0, 260, 1, -20), Position = UDim2.new(1, -270, 0, 10), BackgroundTransparency = 1})
    Create("UIListLayout", {Parent = GlobalNotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})

    local Window = {CurrentTab = nil, AllCards = {}, ConfigElements = {}}

    function Window:CreateTab(name)
        local TabBtn = Create("TextButton", {Parent = TabContainer, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = AccentColor, BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Text_Sub, AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        local Ind = Create("Frame", {Parent = TabBtn, Size = UDim2.new(0, 2, 0, 0), Position = UDim2.new(0, 4, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = AccentColor})

        local Page = Create("ScrollingFrame", {Parent = ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = AccentColor})
        local L_Col = Create("Frame", {Parent = Page, Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 1})
        local R_Col = Create("Frame", {Parent = Page, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0), BackgroundTransparency = 1})
        Create("UIListLayout", {Parent = L_Col, Padding = UDim.new(0, 10)})
        Create("UIListLayout", {Parent = R_Col, Padding = UDim.new(0, 10)})

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentTab then
                Window.CurrentTab.Page.Visible = false
                Tween(Window.CurrentTab.Btn, {BackgroundTransparency = 1, TextColor3 = Text_Sub}, 0.2)
                Tween(Window.CurrentTab.Ind, {Size = UDim2.new(0, 2, 0, 0)}, 0.2)
            end
            Window.CurrentTab = {Page = Page, Btn = TabBtn, Ind = Ind}
            Page.Visible = true
            Tween(TabBtn, {BackgroundTransparency = 0.9, TextColor3 = Text_Main}, 0.2)
            Tween(Ind, {Size = UDim2.new(0, 2, 0, 15)}, 0.2)
        end)

        local PageObj = {Left = true}
        function PageObj:CreateSection(sName)
            local target = PageObj.Left and L_Col or R_Col
            PageObj.Left = not PageObj.Left

            local Sec = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BG_Card})
            Create("UICorner", {Parent = Sec, CornerRadius = UDim.new(0, 6)})
            Create("UIStroke", {Parent = Sec, Color = Color3.fromRGB(40, 40, 45), Thickness = 0.8})
            
            local sTitle = Create("TextLabel", {Parent = Sec, Text = sName:upper(), Font = Enum.Font.GothamBlack, TextSize = 11, TextColor3 = AccentColor, Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local Container = Create("Frame", {Parent = Sec, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 25), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
            Create("UIListLayout", {Parent = Container, Padding = UDim.new(0, 6)})
            Create("UIPadding", {Parent = Container, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})

            table.insert(Window.AllCards, {Card = Sec, TabPage = Page, OrigParent = target})

            local Elements = {}

            -- // Add Toggle (Fixed Anti-Teleport)
            function Elements:AddToggle(name, default, callback)
                local state = default or false
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1})
                local Txt = Create("TextLabel", {Parent = Row, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Text_Sub, Size = UDim2.new(1, -45, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                
                local Switch = Create("TextButton", {Parent = Row, Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -34, 0.5, -9), BackgroundColor3 = state and AccentColor or BG_Hover, Text = ""})
                Create("UICorner", {Parent = Switch, CornerRadius = UDim.new(1, 0)})
                local Knob = Create("Frame", {Parent = Switch, Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1)})
                Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                local function set(v, ignore)
                    state = v
                    Tween(Switch, {BackgroundColor3 = state and AccentColor or BG_Hover}, 0.2)
                    Tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.2)
                    if callback and not ignore then callback(state) end
                end

                Switch.MouseButton1Click:Connect(function() set(not state) end)
                Window.ConfigElements[name] = {Set = set, Get = function() return state end}
            end

            -- // Add Slider (Fixed Anti-Teleport)
            function Elements:AddSlider(name, min, max, default, callback)
                local val = default or min
                local Row = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1})
                local Txt = Create("TextLabel", {Parent = Row, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Text_Sub, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
                local ValTxt = Create("TextLabel", {Parent = Row, Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = AccentColor, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right})
                
                local Bar = Create("TextButton", {Parent = Row, Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 22), BackgroundColor3 = BG_Hover, Text = ""})
                Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})
                local Fill = Create("Frame", {Parent = Bar, Size = UDim2.new((val-min)/(max-min), 0, 1, 0), BackgroundColor3 = AccentColor, BorderSizePixel = 0})
                Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

                local function set(v, ignore)
                    val = math.clamp(v, min, max)
                    ValTxt.Text = tostring(val)
                    Tween(Fill, {Size = UDim2.new((val-min)/(max-min), 0, 1, 0)}, 0.1)
                    if callback and not ignore then callback(val) end
                end

                local dragging = false
                Bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        set(math.floor(min + (max-min)*pos))
                    end
                end)
                Window.ConfigElements[name] = {Set = set, Get = function() return val end}
            end

            -- // Config Manager (Remastered)
            function Elements:AddConfigManager(folderName)
                folderName = folderName or "zyronxSavers"
                local autoFile = folderName .. "/autoload.txt"
                if not _isfolder(folderName) then _makefolder(folderName) end

                local M_Frame = Create("Frame", {Parent = Container, Size = UDim2.new(1, 0, 0, 200), BackgroundTransparency = 1})
                local Inp = Create("TextBox", {Parent = M_Frame, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = BG_Hover, PlaceholderText = "Config name...", Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Text_Main})
                Create("UICorner", {Parent = Inp, CornerRadius = UDim.new(0, 4)})

                local List = Create("ScrollingFrame", {Parent = M_Frame, Size = UDim2.new(1, 0, 0, 100), Position = UDim2.new(0, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(10, 10, 12), ScrollBarThickness = 2})
                Create("UIListLayout", {Parent = List, Padding = UDim.new(0, 4)})
                Create("UIPadding", {Parent = List, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

                local function Refresh()
                    for _, v in ipairs(List:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
                    local currentAuto = ""
                    pcall(function() if isfile(autoFile) then currentAuto = _readfile(autoFile) end end)

                    for _, file in ipairs(_listfiles(folderName)) do
                        local name = file:match("([^/\\]+)%.json$")
                        if name then
                            local isA = (currentAuto == file)
                            local Row = Create("Frame", {Parent = List, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = BG_Card})
                            Create("UICorner", {Parent = Row, CornerRadius = UDim.new(0, 4)})
                            local t = Create("TextLabel", {Parent = Row, Text = (isA and "⭐ " or "") .. name:gsub("_%d+", ""), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = isA and AccentColor or Text_Sub, BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 5, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                            
                            local L_Btn = Create("TextButton", {Parent = Row, Text = "Load", Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -75, 0.5, -9), BackgroundColor3 = Color3.fromRGB(40, 100, 50), TextColor3 = Text_Main, Font = Enum.Font.GothamBold, TextSize = 10})
                            local A_Btn = Create("TextButton", {Parent = Row, Text = "Auto", Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -38, 0.5, -9), BackgroundColor3 = isA and AccentColor or BG_Hover, TextColor3 = Text_Main, Font = Enum.Font.GothamBold, TextSize = 10})
                            Create("UICorner", {Parent = L_Btn, CornerRadius = UDim.new(0, 4)}); Create("UICorner", {Parent = A_Btn, CornerRadius = UDim.new(0, 4)})

                            L_Btn.MouseButton1Click:Connect(function()
                                local s, data = pcall(function() return HttpService:JSONDecode(_readfile(file)) end)
                                if s then
                                    for k, v in pairs(data) do
                                        if Window.ConfigElements[k] then Window.ConfigElements[k].Set(v, true) end
                                    end
                                    Library:Notify({Title = "Config", Description = "Loaded successfully!"})
                                end
                            end)

                            A_Btn.MouseButton1Click:Connect(function()
                                _writefile(autoFile, isA and "" or file)
                                Refresh()
                            end)
                        end
                    end
                end

                local Sav = Create("TextButton", {Parent = M_Frame, Text = "Save New Config", Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 138), BackgroundColor3 = AccentColor, TextColor3 = Text_Main, Font = Enum.Font.GothamBold})
                Create("UICorner", {Parent = Sav, CornerRadius = UDim.new(0, 4)})
                Sav.MouseButton1Click:Connect(function()
                    if Inp.Text ~= "" then
                        local d = {}
                        for k, v in pairs(Window.ConfigElements) do d[k] = v.Get() end
                        _writefile(folderName .. "/" .. Inp.Text .. "_" .. math.floor(tick()) .. ".json", HttpService:JSONEncode(d))
                        Refresh()
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

            return Elements
        end
        return PageObj
    end

    return Window
end

return Library
