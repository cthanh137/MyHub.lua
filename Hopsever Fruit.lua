--[[
    ⚡ INTELLIGENT SERVER HOP (NO PLAYER LIMIT)
    ✅ Nhảy sang server bất kỳ còn chỗ trống
    ✅ Không giới hạn số người (chỉ cần chưa full)
    ✅ Lưu server đã thử để tránh quay lại
    ✅ Tự retry nếu request lỗi
]]

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    Players.LocalPlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ⚙️ CONFIG
local PLACE_ID = game.PlaceId
local MAX_PAGES = 100
local RETRY_DELAY = 0.01
local MAX_RETRIES = 10

-- 🧠 Lấy danh sách server đã thử
local triedServers = TeleportService:GetTeleportSetting("TriedServersList")
if typeof(triedServers) ~= "table" then
    triedServers = {}
end

-- Đánh dấu server hiện tại là đã thử
triedServers[game.JobId] = true
TeleportService:SetTeleportSetting("TriedServersList", triedServers)

-- 🔍 Hàm request an toàn có retry
local function SafeRequest(url)
    for i = 1, MAX_RETRIES do
        local success, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if success and response and response.StatusCode == 200 then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if ok and data and data.data then
                return data
            end
        end
        task.wait(RETRY_DELAY * i)
    end
    return nil
end

-- 🔎 Lấy danh sách server
local function GetServers(placeId)
    local servers = {}
    local cursor = ""
    local pageCount = 0

    repeat
        pageCount += 1
        if pageCount > MAX_PAGES then break end

        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=50&cursor=%s",
            placeId,
            HttpService:UrlEncode(cursor)
        )

        local data = SafeRequest(url)
        if not data then break end

        for _, server in ipairs(data.data) do
            if not triedServers[server.id] and server.playing < server.maxPlayers then
                table.insert(servers, server)
            end
        end

        cursor = data.nextPageCursor or ""
        task.wait(RETRY_DELAY)
    until cursor == ""

    return servers
end

-- 🎯 Tìm server ngẫu nhiên còn slot
local function FindServer()
    local allServers = GetServers(PLACE_ID)
    if #allServers == 0 then
        warn("❌ Không còn server khả dụng. Reset danh sách...")
        triedServers = {}
        triedServers[game.JobId] = true
        TeleportService:SetTeleportSetting("TriedServersList", triedServers)
        return nil
    end

    return allServers[math.random(1, #allServers)]
end

-- 🔁 Auto hop
while task.wait(RETRY_DELAY) do
    local targetServer = FindServer()
    if targetServer then
        warn(string.format("🔄 Chuyển sang server [%s] - %d/%d người", targetServer.id:sub(1,8), targetServer.playing, targetServer.maxPlayers))
        
        triedServers[targetServer.id] = true
        TeleportService:SetTeleportSetting("TriedServersList", triedServers)

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServer.id, LocalPlayer)
        end)
        if ok then break else warn("⚠️ Teleport lỗi:", err) end
    else
        warn("⏳ Không có server phù hợp, thử lại...")
        task.wait(2)
    end
end
