local httpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local InterfaceManager = {} do
    InterfaceManager.Folder = "FluentSettings"
    InterfaceManager.Window = nil  -- sẽ được gán
    InterfaceManager.Library = nil

    InterfaceManager.Settings = {
        Theme = "Darker",
        Acrylic = true,
        Transparency = true,
        MenuKeybind = "P"
    }

    local function splitString(str, delimiter)
        local result = {}
        for match in (str..delimiter):gmatch("(.-)"..delimiter) do
            table.insert(result, match)
        end
        return result
    end

    function InterfaceManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function InterfaceManager:SetLibrary(library)
        self.Library = library
    end

    function InterfaceManager:SetWindow(window)
        self.Window = window
    end

    function InterfaceManager:BuildFolderTree()
        local paths = {}
        local parts = splitString(self.Folder, "/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end
        table.insert(paths, self.Folder)
        table.insert(paths, self.Folder .. "/settings")
        for i = 1, #paths do
            local str = paths[i]
            if not isfolder(str) then
                makefolder(str)
            end
        end
    end

    function InterfaceManager:SaveSettings()
        writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)
            if success then
                for i, v in next, decoded do
                    InterfaceManager.Settings[i] = v
                end
            end
        end
    end

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
        local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()

        local section = tab:AddSection("Interface")

        local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
            Title = "Theme",
            Description = "Changes the interface theme.",
            Values = Library.Themes,
            Default = Settings.Theme,
            Callback = function(Value)
                Library:SetTheme(Value)
                Settings.Theme = Value
                InterfaceManager:SaveSettings()
            end
        })
        InterfaceTheme:SetValue(Settings.Theme)

        if Library.UseAcrylic then
            section:AddToggle("AcrylicToggle", {
                Title = "Acrylic",
                Description = "The blurred background requires graphic quality 8+",
                Default = Settings.Acrylic,
                Callback = function(Value)
                    Library:ToggleAcrylic(Value)
                    Settings.Acrylic = Value
                    InterfaceManager:SaveSettings()
                end
            })
        end

        section:AddToggle("TransparentToggle", {
            Title = "Transparency",
            Description = "Makes the interface transparent.",
            Default = Settings.Transparency,
            Callback = function(Value)
                Library:ToggleTransparency(Value)
                Settings.Transparency = Value
                InterfaceManager:SaveSettings()
            end
        })

        local MenuKeybind = section:AddKeybind("MenuKeybind", {
            Title = "Minimize Bind",
            Default = Settings.MenuKeybind,
            Mode = "Toggle",
            Callback = function(Value)
                if Value and self.Window then
                    self.Window.Frame.Visible = not self.Window.Frame.Visible
                end
            end,
            ChangedCallback = function(New)
                Settings.MenuKeybind = New
                InterfaceManager:SaveSettings()
                Library.MinimizeKeybind = New
            end
        })
        MenuKeybind:SetValue(Settings.MenuKeybind)
        Library.MinimizeKeybind = MenuKeybind.Value
    end

    function InterfaceManager:CreateOpenButton()
        if not self.Window then
            warn("InterfaceManager: Window not set, cannot create open button.")
            return
        end

        -- Xóa nút cũ
        if CoreGui:FindFirstChild("OpenUI") then
            CoreGui.OpenUI:Destroy()
        end

        local OpenUI = Instance.new("ScreenGui")
        OpenUI.Name = "OpenUI"
        OpenUI.Parent = CoreGui
        OpenUI.ResetOnSpawn = false

        local Button = Instance.new("ImageButton")
        Button.Parent = OpenUI
        Button.Size = UDim2.fromOffset(55, 55)
        Button.Position = UDim2.new(0.02, 0, 0.3, 0)
        Button.Image = "rbxassetid://6768917255"
        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        Button.BorderSizePixel = 0
        Button.BackgroundTransparency = 0.1
        Button.ClipsDescendants = true
        Button.ZIndex = 2
        Button.AutoButtonColor = false
        Button.Active = true
        Button.Draggable = true

        local UICorner = Instance.new("UICorner")
        UICorner.Parent = Button
        UICorner.CornerRadius = UDim.new(1, 0)

        local Shadow = Instance.new("ImageLabel")
        Shadow.Parent = Button
        Shadow.Size = UDim2.fromScale(1, 1)
        Shadow.Position = UDim2.fromOffset(3, 3)
        Shadow.BackgroundTransparency = 1
        Shadow.Image = "rbxassetid://6768917255"
        Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Shadow.ImageTransparency = 0.5
        Shadow.ZIndex = 0

        local Glow = Instance.new("ImageLabel")
        Glow.Parent = Button
        Glow.Size = UDim2.fromScale(1.3, 1.3)
        Glow.Position = UDim2.new(-0.15, 0, -0.15, 0)
        Glow.BackgroundTransparency = 1
        Glow.Image = "rbxassetid://6768917255"
        Glow.ImageColor3 = Color3.fromRGB(100, 50, 255)
        Glow.ImageTransparency = 0.8
        Glow.ZIndex = 0

        -- Hover
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(60, 60)}):Play()
            TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(60, 60, 90)}):Play()
            TweenService:Create(Glow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.5}):Play()
        end)

        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(55, 55)}):Play()
            TweenService:Create(Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
            TweenService:Create(Glow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0.8}):Play()
        end)

        -- Click
        Button.MouseButton1Click:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(45, 45)}):Play()
            task.wait(0.1)
            TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(55, 55)}):Play()

            if self.Window then
                self.Window.Frame.Visible = not self.Window.Frame.Visible
            end
        end)

        -- Loop glow
        task.spawn(function()
            while true do
                TweenService:Create(Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.6}):Play()
                task.wait(2)
                TweenService:Create(Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.8}):Play()
                task.wait(2)
            end
        end)
    end
end

return InterfaceManager
