-- Anti-AFK + Chống Teleport - Bản đơn giản
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ====== ANTI-AFK ======
print("🛡️ Anti-AFK đang chạy...")

local function AntiAFK()
    if not character or not character.PrimaryPart then return end
    
    -- Di chuyển nhẹ
    local pos = character.PrimaryPart.Position
    character.PrimaryPart.CFrame = CFrame.new(pos + Vector3.new(1, 0, 0))
    task.wait(0.1)
    character.PrimaryPart.CFrame = CFrame.new(pos)
end

-- Chạy Anti-AFK mỗi 50 giây
task.spawn(function()
    while true do
        task.wait(50)
        pcall(function()
            -- Gửi sự kiện giả
            VirtualInputManager:SendKeyEvent(true, "W", false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, "W", false, game)
            
            AntiAFK()
        end)
    end
end)

-- ====== CHỐNG TELEPORT ======
print("🛡️ Chống Teleport đang chạy...")

-- Cách 1: Ngăn chặn teleport bằng cách kiểm tra vị trí
local lastPosition = nil
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if character and character.PrimaryPart then
                local currentPos = character.PrimaryPart.Position
                if lastPosition then
                    -- Nếu dịch chuyển quá xa trong 0.5s => teleport
                    local distance = (currentPos - lastPosition).Magnitude
                    if distance > 100 then -- Ngưỡng teleport
                        print("🔄 Phát hiện teleport! Đang quay lại...")
                        character.PrimaryPart.CFrame = CFrame.new(lastPosition)
                    end
                end
                lastPosition = currentPos
            end
        end)
    end
end)

-- Cách 2: Hook TeleportService (đơn giản hơn)
pcall(function()
    local oldTeleport = TeleportService.Teleport
    TeleportService.Teleport = function(placeId, playerToTeleport)
        if placeId == game.PlaceId then
            print("✅ Đã chặn teleport cùng map!")
            return nil
        end
        return oldTeleport(placeId, playerToTeleport)
    end
end)

-- Cách 3: Chặn teleport async
pcall(function()
    if TeleportService.TeleportAsync then
        local oldAsync = TeleportService.TeleportAsync
        TeleportService.TeleportAsync = function(placeIds, players)
            if type(placeIds) == "table" then
                for _, id in pairs(placeIds) do
                    if id == game.PlaceId then
                        print("✅ Đã chặn teleport async!")
                        return nil
                    end
                end
            end
            return oldAsync(placeIds, players)
        end
    end
end)

-- ====== KHỞI ĐỘNG ======
print("========================================")
print("✅ SCRIPT ĐÃ CHẠY THÀNH CÔNG!")
print("========================================")

-- Giữ script chạy
while task.wait(60) do
    -- Không làm gì, chỉ giữ script sống
end
