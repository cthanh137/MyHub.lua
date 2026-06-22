if CoreGui:FindFirstChild("OpenUI") then
    CoreGui.OpenUI:Destroy()
end
local OpenUI = Instance.new("ScreenGui")
OpenUI.Name = "OpenUI"
OpenUI.Parent = CoreGui
OpenUI.ResetOnSpawn = false
local Shadow = Instance.new("TextLabel")
Shadow.Parent = OpenUI
Shadow.Size = UDim2.fromOffset(55,55)
Shadow.Position = UDim2.new(0.05,3,0.3,3)
Shadow.BackgroundTransparency = 1
Shadow.Text = "🐇"
Shadow.TextSize = 40
Shadow.TextColor3 = Color3.fromRGB(0,0,0)
Shadow.TextTransparency = 0.5
Shadow.ZIndex = 0

local Button = Instance.new("TextButton")
Button.Parent = OpenUI
Button.Size = UDim2.fromOffset(55,55)
Button.Position = UDim2.new(0.05,0,0.3,0)
Button.Text = "👑"
Button.TextSize = 40
Button.TextColor3 = Color3.new(1,1,1)
Button.BackgroundTransparency = 1
Button.BorderSizePixel = 0
Button.Active = true
Button.Draggable = true
Button.AutoButtonColor = true
Button.ZIndex = 1

Button:GetPropertyChangedSignal("Position"):Connect(function()
    Shadow.Position = Button.Position + UDim2.fromOffset(3,3)
end)

Button.MouseButton1Click:Connect(function()
    VIM:SendKeyEvent(true, Enum.KeyCode.P, false, game)
    task.wait()
    VIM:SendKeyEvent(false, Enum.KeyCode.P, false, game)
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
