--[[
    🔁 SERVER HOP AUTO LOOP (TÌM SERVER 2 NGƯỜI / DƯỚI 4 NGƯỜI)
    ✅ Ưu tiên server có đúng 2 người, nếu không có thì tìm ≤4 người.
    🔄 Tự động lặp lại sau 10 giây đến khi tìm thấy server phù hợp.
    ⚙️ Yêu cầu Executor hỗ trợ request() và TeleportService.
]]

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ Cấu hình
local TARGET_PLAYER_COUNT = 10 -- Ưu tiên đúng 2 người
local FALLBACK_MAX_PLAYERS = 15 -- Tối đa fallback
local PLACE_ID = game.PlaceId
local MAX_PAGES = 150 -- Số trang quét tối đa
local RETRY_DELAY = 0.01 -- thời gian chờ giữa mỗi lần quét (giây)

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


local function FindAndHop()
    local allServers = GetServers(PLACE_ID)
    if #allServers == 0 then
        warn("❌ Không có server nào khả dụng.")
        return nil
    end

    local targetServer = nil


    for _, server in ipairs(allServers) do
        if server.playing == TARGET_PLAYER_COUNT then
            targetServer = server
            break
        end
    end

   
    if not targetServer then
        for _, server in ipairs(allServers) do
            if server.playing <= FALLBACK_MAX_PLAYERS then
                targetServer = server
                break
            end
        end
    end

    return targetServer
end

while task.wait(RETRY_DELAY) do
    local targetServer = FindAndHop()

    if targetServer then
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServer.id, LocalPlayer)
        end)
        if ok then
    
            break 
        else
  
        end
    else
  
    end
end
