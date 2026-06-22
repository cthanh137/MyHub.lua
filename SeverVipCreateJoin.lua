-- Tạo nút minimize cho FluentPlus
task.defer(function()
    -- Đợi Library và các thành phần cần thiết load
    repeat task.wait() until Library and Library.Window and Library.Window.Minimize and game:GetService("CoreGui")
    
    -- Tạo hoặc lấy ScreenGui
    local parentGui = Library.ScreenGui or Instance.new("ScreenGui", game:GetService("CoreGui"))
    parentGui.Name = "FluentPlus_Button"
    parentGui.IgnoreGuiInset = true
    parentGui.ResetOnSpawn = false
    
    -- Kiểm tra nút đã tồn tại chưa để tránh tạo trùng
    local existingButton = parentGui:FindFirstChild("FloatingMinimizeButton")
    if existingButton then
        existingButton:Destroy()
    end
    
    -- 🟣 Tạo nút bấm tròn
    local Button = Instance.new("TextButton")
    Button.Name = "FloatingMinimizeButton"
    Button.Size = UDim2.new(0, 50, 0, 50)
    Button.Position = UDim2.new(0, 10, 0.5, -25) -- Căn giữa theo chiều dọc, sát lề trái
    Button.BackgroundColor3 = Color3.fromRGB(90, 60, 180)
    Button.Text = "🔽" -- Sử dụng icon thay vì chữ "Hide Menu"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 20
    Button.ZIndex = 999
    Button.Draggable = true
    Button.Active = true
    Button.Parent = parentGui
    
    -- 🔵 Bo góc tròn hoàn hảo
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Button
    
    -- ✨ Thêm hiệu ứng bóng đổ
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1.2, 0, 1.2, 0)
    Shadow.Position = UDim2.new(-0.1, 0, -0.1, 0)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316044023" -- Shadow effect
    Shadow.ImageTransparency = 0.5
    Shadow.ZIndex = 998
    Shadow.Parent = Button
    
    -- 🎨 Hiệu ứng hover và click
    local TweenService = game:GetService("TweenService")
    
    -- Hover
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(120, 80, 220),
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(90, 60, 180),
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end)
    
    -- Click animation
    Button.MouseButton1Down:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 45, 0, 45)
        }):Play()
    end)
    
    Button.MouseButton1Up:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 50, 0, 50)
        }):Play()
    end)
    
    -- 🔄 Chức năng minimize với toggle
    local isMinimized = false
    
    Button.MouseButton1Click:Connect(function()
        pcall(function()
            if Library and Library.Window and Library.Window.Minimize then
                Library.Window:Minimize()
                isMinimized = not isMinimized
                
                -- Đổi icon khi minimize
                if isMinimized then
                    Button.Text = "▲"
                    TweenService:Create(Button, TweenInfo.new(0.3), {
                        BackgroundColor3 = Color3.fromRGB(60, 30, 120)
                    }):Play()
                else
                    Button.Text = "🔽"
                    TweenService:Create(Button, TweenInfo.new(0.3), {
                        BackgroundColor3 = Color3.fromRGB(90, 60, 180)
                    }):Play()
                end
            end
        end)
    end)
    
    -- 📌 Thêm tooltip khi hover
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 80, 0, 25)
    tooltip.Position = UDim2.new(0, 60, 0.5, -12)
    tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltip.BackgroundTransparency = 0.8
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Font = Enum.Font.GothamMedium
    tooltip.TextSize = 12
    tooltip.Text = "Minimize"
    tooltip.Visible = false
    tooltip.ZIndex = 1000
    tooltip.Parent = Button
    
    -- Bo góc cho tooltip
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 5)
    tooltipCorner.Parent = tooltip
    
    Button.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    Button.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    print("✅ FluentPlus Minimize Button đã được tạo thành công!")
end)
local httpService = game:GetService("HttpService")

local InterfaceManager = {} do
InterfaceManager.Folder = "FluentSettings"

    InterfaceManager.Settings = {

        Theme = "Darker",

        Acrylic = true,

        Transparency = true,

        MenuKeybind = "P"

    }
    function InterfaceManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

    function InterfaceManager:SetLibrary(library)
		self.Library = library
	end

    function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
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
    Default = Settings.MenuKeybind 
})

MenuKeybind:OnChanged(function()
    Settings.MenuKeybind = MenuKeybind.Value
    InterfaceManager:SaveSettings() -- Chỉ lưu cài đặt, KHÔNG thêm lệnh click chuột vào đây
end)

Library.MinimizeKeybind = MenuKeybind
    end
end

return InterfaceManager
