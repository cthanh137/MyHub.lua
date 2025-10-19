--[[  
    🔁 SERVER HOP VÔ HẠN + LOG DISCORD
    ✅ Tự động tìm server ngẫu nhiên và teleport liên tục.
    🧠 Gửi log Discord khi join thành công.
    ⚙️ Yêu cầu executor có request() và TeleportService.
--]]

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 🔗 Webhook Discord của bạn
local WEBHOOK_URL = "https://discord.com/api/webhooks/1429493470531424407/97lyF_Xu50SPQ8DXiXTc5B-vEhZD2UwehBqnC37VMlR2ZVX7mR3e18iwZsZ2TV0LViQP"

-- 🕒 Hàm lấy thời gian hiện tại định dạng đẹp
local function GetTimestamp()
    local now = os.date("!*t")
    return string.format("%02d/%02d/%04d %02d:%02d:%02d UTC", now.day, now.month, now.year, now.hour, now.min, now.sec)
end

-- 📤 Gửi log Discord khi join thành công
local function SendDiscordLog(jobId)
    local data = {
        ["username"] = "Server Hop Logger",
        ["embeds"] = {{
            ["title"] = "✅ Đã Teleport Thành Công!",
            ["description"] = string.format("**Người chơi:** %s\n**Job ID:** %s\n**Place ID:** %s\n**Thời gian:** %s",
                LocalPlayer.Name, jobId, game.PlaceId, GetTimestamp()),
            ["color"] = 65280
        }}
    }

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- 🚀 Hàm tìm server ngẫu nhiên
local function FindNewServer()
    local PlaceId = game.PlaceId
    local Cursor = ""
    local Api = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

    while true do
        local response = request({Url = Api .. (Cursor ~= "" and "&cursor=" .. Cursor or ""), Method = "GET"})
        local data = HttpService:JSONDecode(response.Body)

        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                return server.id
            end
        end

        if data.nextPageCursor then
            Cursor = data.nextPageCursor
        else
            break
        end
    end
end

-- 🔁 Loop vô hạn
task.spawn(function()
    while task.wait(0.5) do -- 30 giây đổi server 1 lần (tùy chỉnh)
        local newServer = FindNewServer()
        if newServer then
            print("🔁 Teleport tới server mới:", newServer)
            SendDiscordLog(newServer)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
            end)
            task.wait(1)
        else
            warn("⚠️ Không tìm thấy server phù hợp, thử lại sau...")
        end
    end
end)

-- ✅ Gửi log khi mới load vào
task.defer(function()
    task.wait(0.1)
    SendDiscordLog(game.JobId)
end)
