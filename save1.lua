local httpService = game:GetService("HttpService")

local InterfaceManager = {} do
    InterfaceManager.Folder = "FluentSettings"

    InterfaceManager.Settings = {
        Theme = "Darker",
        Acrylic = true,
        Transparency = true,
        MenuKeybind = "P"
    }

    -- ⭐ Thêm hàm split cho string
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

    function InterfaceManager:BuildFolderTree()
        local paths = {}
        local parts = splitString(self.Folder, "/") -- ⭐ Sửa ở đây
        
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

        -- ⭐ SỬA LẠI PHẦN KEYBIND
        local MenuKeybind = section:AddKeybind("MenuKeybind", {
            Title = "Minimize Bind",
            Default = Settings.MenuKeybind,
            Mode = "Toggle",
            Callback = function(Value)
                if Value then
                    -- Khi nhấn phím, toggle minimize
                    if Library.Window then
                        if Library.Window.Frame.Visible then
                            Library.Window:Minimize()
                        else
                            -- Nếu đã ẩn thì hiện lại
                            if Library.Window.Show then
                                Library.Window:Show()
                            else
                                Library.Window.Frame.Visible = true
                            end
                        end
                    end
                end
            end,
            ChangedCallback = function(New)
                Settings.MenuKeybind = New
                InterfaceManager:SaveSettings()
                -- Cập nhật MinimizeKeybind cho Library
                Library.MinimizeKeybind = New
            end
        })

        -- Set giá trị ban đầu
        MenuKeybind:SetValue(Settings.MenuKeybind)

        -- ⭐ Gán đúng cách
        Library.MinimizeKeybind = MenuKeybind.Value
    end
end

return InterfaceManager
