--[[  
    🔁 SERVER HOP VÔ HẠN + LOG DISCORD (ANTI DUPLICATE)
    ✅ Không bao giờ vào lại server đã từng join.
    ✅ Tự động hop liên tục, có log Discord khi thành công.
    ⚙️ Yêu cầu executor có request() và TeleportService.
--]]

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 🔗 Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1429493470531424407/97lyF_Xu50SPQ8DXiXTc5B-vEhZD2UwehBqnC37VMlR2ZVX7mR3e18iwZsZ2TV0LViQP"

-- ⚙️ Cấu hình
local HOP_DELAY = 5 -- thời gian giữa mỗi lần hop (giây)

-- 🕒 Hàm định dạng thời gian
local function GetTimestamp()
    local now = os.date("!*t")
    return string.format("%02d/%02d/%04d %02d:%02d:%02d UTC", now.day, now.month, now.year, now.hour, now.min, now.sec)
end

-- 📤 Gửi log Discord
local function SendDiscordLog(jobId)
    local data = {
        ["username"] = "Server Hop Logger",
        ["embeds"] = {{
            ["title"] = "✅ Teleport Thành Công!",
            ["description"] = string.format(
                "**Người chơi:** %s\n**Job ID:** %s\n**Place ID:** %s\n**Thời gian:** %s",
                LocalPlayer.Name, jobId, game.PlaceId, GetTimestamp()
            ),
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

-- 🧠 Lấy danh sách server đã từng join
local TriedServers = TeleportService:GetTeleportSetting("TriedServersList")
if typeof(TriedServers) ~= "table" then
    TriedServers = {}
end

-- Đánh dấu server hiện tại là đã thử
TriedServers[game.JobId] = true
TeleportService:SetTeleportSetting("TriedServersList", TriedServers)

-- 🚀 Hàm tìm server mới chưa từng vào
local function FindNewServer()
    local PlaceId = game.PlaceId
    local Cursor = ""
    local Api = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

    while true do
        local ok, response = pcall(function()
            return request({Url = Api .. (Cursor ~= "" and "&cursor=" .. Cursor or ""), Method = "GET"})
        end)

        if not ok or not response or response.StatusCode ~= 200 then
            task.wait(1)
            continue
        end

        local success, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if success and data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and not TriedServers[server.id] then
                    return server.id
                end
            end
            if data.nextPageCursor then
                Cursor = data.nextPageCursor
            else
                break
            end
        else
            break
        end
    end
end

-- 🔁 Loop vô hạn
task.spawn(function()
    while task.wait(HOP_DELAY) do
        local newServer = FindNewServer()
        if newServer then
            print("🔁 Teleport tới server mới:", newServer)
            TriedServers[newServer] = true
            TeleportService:SetTeleportSetting("TriedServersList", TriedServers)
            SendDiscordLog(newServer)

            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, newServer, LocalPlayer)
            end)
            task.wait(2)
        else
            warn("⚠️ Không tìm thấy server mới, reset danh sách...")
            TriedServers = {}
            TriedServers[game.JobId] = true
            TeleportService:SetTeleportSetting("TriedServersList", TriedServers)
            task.wait(3)
        end
    end
end)

-- ✅ Gửi log khi vào game
task.defer(function()
    task.wait(1)
    SendDiscordLog(game.JobId)
end)
