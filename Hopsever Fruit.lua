local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Api = "https://games.roblox.com/v1/games/"

local _place,_id = game.PlaceId, game.JobId
local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=10"

-- Danh sách trái hiếm
local KNOWN_FRUITS = {
    ["Magma Fruit"]=true, ["Rumble Fruit"]=true, ["Phoenix Fruit"]=true,
 ["Quake Fruit"]=true, ["Ultra Rare Box"]=true,["Dark"]=true,
    ["UltraRare Box"]=true, 
}

-- Kiểm tra tool có phải fruit không
local function isFruit(tool)
    return tool and tool:IsA("Tool") and KNOWN_FRUITS[tool.Name]
end

-- Lấy danh sách trái từ player
local function getPlayerFruits(player)
    local fruits = {}
    if player and player:FindFirstChild("Backpack") then
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if isFruit(tool) then
                table.insert(fruits, tool.Name)
            end
        end
    end
    if player and player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if isFruit(tool) then
                table.insert(fruits, tool.Name)
            end
        end
    end
    return fruits
end

-- ESP cho player giữ trái
local function addFruitESP(player, fruitName)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if player.Character:FindFirstChild("FruitESP") then
        player.Character.FruitESP:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0,250,0,60)
    billboard.StudsOffset = Vector3.new(0,5,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = player.Character

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel = 0
    bg.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(20,20,20)
    stroke.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = bg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,0.33,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "👤 " .. player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.TextStrokeTransparency = 0.1
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = bg

    local fruitLabel = Instance.new("TextLabel")
    fruitLabel.Size = UDim2.new(1,0,0.33,0)
    fruitLabel.Position = UDim2.new(0,0,0.33,0)
    fruitLabel.BackgroundTransparency = 1
    fruitLabel.Text = "🍏 Trái: " .. fruitName
    fruitLabel.TextColor3 = Color3.fromRGB(255,200,0)
    fruitLabel.TextStrokeTransparency = 0.2
    fruitLabel.TextScaled = true
    fruitLabel.Font = Enum.Font.GothamBold
    fruitLabel.Parent = bg

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1,0,0.34,0)
    distLabel.Position = UDim2.new(0,0,0.66,0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(0,255,128)
    distLabel.TextStrokeTransparency = 0.2
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.GothamBold
    distLabel.Parent = bg

    task.spawn(function()
        while billboard.Parent == player.Character do
            task.wait(0.5)
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - game.Workspace.CurrentCamera.CFrame.Position).Magnitude
                distLabel.Text = string.format("📏 %.0f m", dist)
            else
                break
            end
        end
    end)
end

-- ESP cho trái rơi
local function addDroppedFruitESP(fruit)
    if not fruit:IsA("Tool") or not fruit:FindFirstChild("Handle") then return end
    if fruit:FindFirstChild("FruitESP") then fruit.FruitESP:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitESP"
    billboard.Adornee = fruit.Handle
    billboard.Size = UDim2.new(0,220,0,50)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = fruit

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel = 0
    bg.Parent = billboard

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(20,20,20)
    stroke.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = bg

    local pos = fruit.Handle.Position

    local fruitLabel = Instance.new("TextLabel")
    fruitLabel.Size = UDim2.new(1,0,0.5,0)
    fruitLabel.BackgroundTransparency = 1
    fruitLabel.Text = "🍏 " .. fruit.Name
    fruitLabel.TextColor3 = Color3.fromRGB(255,255,0)
    fruitLabel.TextStrokeTransparency = 0.2
    fruitLabel.TextScaled = true
    fruitLabel.Font = Enum.Font.GothamBold
    fruitLabel.Parent = bg

    local posLabel = Instance.new("TextLabel")
    posLabel.Size = UDim2.new(1,0,0.5,0)
    posLabel.Position = UDim2.new(0,0,0.5,0)
    posLabel.BackgroundTransparency = 1
    posLabel.Text = string.format("📍 (%.1f, %.1f, %.1f)", pos.X,pos.Y,pos.Z)
    posLabel.TextColor3 = Color3.fromRGB(0,200,255)
    posLabel.TextStrokeTransparency = 0.2
    posLabel.TextScaled = true
    posLabel.Font = Enum.Font.GothamBold
    posLabel.Parent = bg
end

-- Xóa ESP
local function removeFruitESP(player)
    if player.Character and player.Character:FindFirstChild("FruitESP") then
        player.Character.FruitESP:Destroy()
    end
end

-- UI trạng thái server
local function createServerUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerFruitStatus"
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = UDim2.new(0.5, -140, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255,255,255)
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "StatusText"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = "Đang kiểm tra..."
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextStrokeTransparency = 0.5
    label.Parent = frame

    return label, stroke
end

local serverLabel, frameStroke = createServerUI()

-- Lấy danh sách server
local function ListServers(cursor)
    local raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
    return Http:JSONDecode(raw)
end

-- Hop server
local function HopServer()
    local Servers = ListServers()
    if Servers and Servers.data and #Servers.data > 0 then
        for _, server in ipairs(Servers.data) do
            if server.id ~= _id and server.playing < server.maxPlayers then
                TPS:TeleportToPlaceInstance(_place, server.id, LocalPlayer)
                return
            end
        end
    end
end

-- Kiểm tra server có trái
local function CheckServerFruits()
    local hasFruit = false
    for _, pl in ipairs(Players:GetPlayers()) do
        local fruits = getPlayerFruits(pl)
        if #fruits > 0 then
            hasFruit = true
            addFruitESP(pl, table.concat(fruits,", "))
        else
            removeFruitESP(pl)
        end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if isFruit(obj) then
            hasFruit = true
            addDroppedFruitESP(obj)
        end
    end
    return hasFruit
end

-- Loop kiểm tra + update UI
task.spawn(function()
    while task.wait(2) do
        local hasFruit = CheckServerFruits()
        if hasFruit then
            serverLabel.Text = "🟢 Server có trái hiếm"
            serverLabel.TextColor3 = Color3.fromRGB(0,255,128)
            frameStroke.Color = Color3.fromRGB(0,255,128)
        else
            serverLabel.Text = "🔴 Server không có trái"
            serverLabel.TextColor3 = Color3.fromRGB(255,80,80)
            frameStroke.Color = Color3.fromRGB(255,80,80)
            HopServer()
            task.wait(1)
        end
    end
end)
