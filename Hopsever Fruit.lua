local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ Cấu hình đúng theo yêu cầu
local MIN_PLAYER_COUNT = 1
local MAX_PLAYER_COUNT = 18
local PLACE_ID = game.PlaceId
local MAX_PAGES = 200
local RETRY_DELAY = 0.1 -- tăng delay để tránh spam request

local triedServers = {} -- lưu server đã thử

-- 🔍 Lấy danh sách server
local function GetServers(placeId)
    local servers = {}
    local cursor = ""
    local pageCount = 0

    repeat
        pageCount += 1
        if pageCount > MAX_PAGES then break end

        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=120&cursor=%s", placeId, cursor)
        local success, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)

        if success and response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    -- Chỉ lấy server chưa thử và trong giới hạn 8–15 người
                    if not triedServers[server.id] and server.playing >= MIN_PLAYER_COUNT and server.playing <= MAX_PLAYER_COUNT then
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

-- 🧭 Tìm và teleport server
local function FindAndHop()
    local allServers = GetServers(PLACE_ID)
    if #allServers == 0 then
        warn("❌ Không có server nào khả dụng.")
        return nil
    end

    -- Chọn server ngẫu nhiên trong danh sách để tránh thử lại server trước đó
    local server = allServers[math.random(1, #allServers)]
    return server
end

-- 🔁 Vòng lặp auto hop
while task.wait(RETRY_DELAY) do
    local targetServer = FindAndHop()
    if targetServer then
        triedServers[targetServer.id] = true -- đánh dấu đã thử
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
