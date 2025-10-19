--[[
    🔁 SERVER HOP AUTO LOOP (TÌM SERVER 8–15 NGƯỜI)
    ✅ Tìm server có số người chơi trong khoảng 8 đến 15.
    🔄 Tự động lặp lại cho đến khi tìm thấy server phù hợp.
    ⚙️ Yêu cầu Executor hỗ trợ request() và TeleportService.
]]

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ Cấu hình
local MIN_PLAYER_COUNT = 8     -- Số người tối thiểu
local MAX_PLAYER_COUNT = 18    -- Số người tối đa
local PLACE_ID = game.PlaceId
local MAX_PAGES = 100          -- Giới hạn số trang quét
local RETRY_DELAY = 1         -- Thời gian lặp lại (giây)

-- 🔍 Hàm lấy danh sách server
local function GetServers(placeId)
    local servers = {}
    local cursor = ""
    local pageCount = 0

    repeat
        pageCount += 1
        if pageCount > MAX_PAGES then break end

        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s", placeId, cursor)
        local success, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)

        if success and response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(servers, server)
                    end
                end
                cursor = data.nextPageCursor or ""
            else
                break
            end
        else
            break
        end
    until cursor == ""

    return servers
end

-- 🧭 Hàm tìm server có từ 8–15 người
local function FindAndHop()
    local allServers = GetServers(PLACE_ID)
    if #allServers == 0 then
        warn("❌ Không có server nào khả dụng.")
        return nil
    end

    local targetServer = nil

    for _, server in ipairs(allServers) do
        if server.playing >= MIN_PLAYER_COUNT and server.playing <= MAX_PLAYER_COUNT then
            targetServer = server
            break
        end
    end

    return targetServer
end

-- 🔁 Vòng lặp tự động
while task.wait(RETRY_DELAY) do
    local targetServer = FindAndHop()
    if targetServer then
        warn(string.format("🔄 Đang chuyển sang server có %d người...", targetServer.playing))
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServer.id, LocalPlayer)
        end)
        if ok then
            break
        else
            warn("⚠️ Lỗi teleport:", err)
        end
    else
        warn("⏳ Không tìm thấy server phù hợp, thử lại sau...")
    end
end
