-- ⚡ QuangTri Hub - Buy / Drop / Drink (Tối giản, không lỗi, UI gọn)
if getgenv().QuangTriHub then getgenv().QuangTriHub:Destroy() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")

-- ⚙ Config
getgenv().AutoBuy, getgenv().AutoDrop, getgenv().AutoDrink = false,false,false
getgenv().DROP_DELAY = 0.05
getgenv().DRINK_DELAY = 0.03
local BuyAmount, Bought, SelectedDrink = 10,0,"Cider+"
local DrinkTypes = {"Cider+", "Lemonade+", "Juice+", "Smoothie+"}

-- 🖥 UI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "QuangTriHub"
getgenv().QuangTriHub = gui

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 280, 0, 300)
main.Position = UDim2.new(0.35, 0, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Active, main.Draggable = true, true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "⚡ QuangTri Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255,255,255)

-- 📦 Auto Buy UI
local buyLabel = Instance.new("TextLabel", main)
buyLabel.Text = "Auto Buy Drinks:"
buyLabel.Size = UDim2.new(1,0,0,20)
buyLabel.Position = UDim2.new(0,0,0.12,0)
buyLabel.BackgroundTransparency = 1
buyLabel.TextColor3 = Color3.fromRGB(200,200,200)
buyLabel.Font = Enum.Font.Gotham
buyLabel.TextSize = 14

local drinkButtons = {}
for i, name in ipairs(DrinkTypes) do
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0.45,0,0,26)
    btn.Position = UDim2.new((i%2==1) and 0.05 or 0.5,0,0.18+(math.floor((i-1)/2)*0.1),0)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        SelectedDrink = name
        for _,b in ipairs(drinkButtons) do b.BackgroundColor3 = Color3.fromRGB(50,50,50) end
        btn.BackgroundColor3 = Color3.fromRGB(100,170,60)
    end)
    table.insert(drinkButtons, btn)
end
drinkButtons[1].BackgroundColor3 = Color3.fromRGB(100,170,60)

local amountBox = Instance.new("TextBox", main)
amountBox.Size = UDim2.new(0.9,0,0,26)
amountBox.Position = UDim2.new(0.05,0,0.38,0)
amountBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
amountBox.Text = tostring(BuyAmount)
amountBox.PlaceholderText = "Nhập số lượng..."
amountBox.Font = Enum.Font.Gotham
amountBox.TextSize = 13
amountBox.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0,6)
amountBox.FocusLost:Connect(function(enter)
    if enter and tonumber(amountBox.Text) then
        BuyAmount = tonumber(amountBox.Text)
        Bought = 0
    end
end)

local toggleBuy = Instance.new("TextButton", main)
toggleBuy.Size = UDim2.new(0.9,0,0,28)
toggleBuy.Position = UDim2.new(0.05,0,0.48,0)
toggleBuy.Text = "▶ Start Auto Buy"
toggleBuy.Font = Enum.Font.GothamBold
toggleBuy.TextSize = 14
toggleBuy.BackgroundColor3 = Color3.fromRGB(0,170,100)
toggleBuy.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleBuy).CornerRadius = UDim.new(0,6)

-- tìm Remote
local function findRemote()
    local m = workspace:FindFirstChild("Merchants")
    local b = m and m:FindFirstChild("BetterDrinkMerchant")
    local c = b and b:FindFirstChild("Clickable")
    local s = c and c:FindFirstChild("ShopDrinksPlus")
    local clk = s and s:FindFirstChild("Clicked")
    return clk and clk:FindFirstChild("Retum")
end
local remote; task.spawn(function() while not remote do remote=findRemote() task.wait(1) end end)

toggleBuy.MouseButton1Click:Connect(function()
    getgenv().AutoBuy = not getgenv().AutoBuy
    Bought = 0
    toggleBuy.Text = getgenv().AutoBuy and "⏹ Stop Auto Buy" or "▶ Start Auto Buy"
    toggleBuy.BackgroundColor3 = getgenv().AutoBuy and Color3.fromRGB(200,50,50) or Color3.fromRGB(0,170,100)
end)

task.spawn(function()
    while true do
        if getgenv().AutoBuy and remote and Bought < BuyAmount then
            pcall(function() remote:FireServer(SelectedDrink) end)
            Bought += 1
        end
        task.wait(0.05)
    end
end)

-- 🗑 Auto Drop
local toggleDrop = Instance.new("TextButton", main)
toggleDrop.Size = UDim2.new(0.9,0,0,28)
toggleDrop.Position = UDim2.new(0.05,0,0.63,0)
toggleDrop.Text = "▶ Auto Drop"
toggleDrop.Font = Enum.Font.GothamBold
toggleDrop.TextSize = 14
toggleDrop.BackgroundColor3 = Color3.fromRGB(0,170,100)
toggleDrop.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleDrop).CornerRadius = UDim.new(0,6)

local function autoDropLoop()
    while getgenv().AutoDrop do
        local backpack, char = LocalPlayer.Backpack, LocalPlayer.Character
        if backpack and char then
            for _, tool in ipairs(backpack:GetChildren()) do
                if not getgenv().AutoDrop then break end
                if tool:IsA("Tool") then
                    char.Humanoid:EquipTool(tool)
                    task.wait(0.01)
                    if tool.Parent == char then
                        VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                        task.wait(0.01)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
                        task.wait(getgenv().DROP_DELAY)
                    end
                end
            end
        end
        task.wait()
    end
end
toggleDrop.MouseButton1Click:Connect(function()
    getgenv().AutoDrop = not getgenv().AutoDrop
    toggleDrop.Text = getgenv().AutoDrop and "⏹ Stop Drop" or "▶ Auto Drop"
    toggleDrop.BackgroundColor3 = getgenv().AutoDrop and Color3.fromRGB(200,50,50) or Color3.fromRGB(0,170,100)
    if getgenv().AutoDrop then task.spawn(autoDropLoop) end
end)

-- 🍹 Auto Drink (liên tục tất cả item)
local toggleDrink = Instance.new("TextButton", main)
toggleDrink.Size = UDim2.new(0.9,0,0,28)
toggleDrink.Position = UDim2.new(0.05,0,0.78,0)
toggleDrink.Text = "▶ Auto Drink"
toggleDrink.Font = Enum.Font.GothamBold
toggleDrink.TextSize = 14
toggleDrink.BackgroundColor3 = Color3.fromRGB(0,170,100)
toggleDrink.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleDrink).CornerRadius = UDim.new(0,6)

local function autoDrinkLoop()
    while getgenv().AutoDrink do
        local backpack, char = LocalPlayer.Backpack, LocalPlayer.Character
        if backpack and char and char:FindFirstChild("Humanoid") then
            for _, tool in ipairs(backpack:GetChildren()) do
                if not getgenv().AutoDrink then break end
                if tool:IsA("Tool") then
                    char.Humanoid:EquipTool(tool)
                    task.wait(0.001)
                    if tool.Parent == char then
                        tool:Activate()
                        task.wait(getgenv().DRINK_DELAY)
                    end
                end
            end
        end
    end
end
toggleDrink.MouseButton1Click:Connect(function()
    getgenv().AutoDrink = not getgenv().AutoDrink
    toggleDrink.Text = getgenv().AutoDrink and "⏹ Stop Drink" or "▶ Auto Drink"
    toggleDrink.BackgroundColor3 = getgenv().AutoDrink and Color3.fromRGB(200,50,50) or Color3.fromRGB(0,170,100)
    if getgenv().AutoDrink then task.spawn(autoDrinkLoop) end
end)
