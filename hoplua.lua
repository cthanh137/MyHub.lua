-- ====== SCRIPT HOP SERVER NÂNG CAO ======
-- Có thể tùy chỉnh số người chơi mong muốn

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- ====== CẤU HÌNH ======
local CONFIG = {
    HISTORY_FILE = "server_history.txt",
    HISTORY_EXPIRE_TIME = 900, -- 15 phút
    PREFER_PLAYERS = 3,        -- Số người chơi lý tưởng (0 = bất kỳ)
    MIN_PLAYERS = 1,           -- Số người chơi tối thiểu
    MAX_RETRIES = 3,
    DEBUG_MODE = true
}

-- ====== LOGGING ======
local function Log(message, type)
    if not CONFIG.DEBUG_MODE and type ~= "error" then return end
    local prefix = {
        info = "ℹ️",
        success = "✅",
        error = "❌",
        warning = "⚠️",
        progress = "🔄",
        found = "🎯"
    }
    print((prefix[type] or "📌") .. " " .. message)
end

-- ====== QUẢN LÝ LỊCH SỬ ======
local function GetServerHistory()
    if readfile and isfile and isfile(CONFIG.HISTORY_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG.HISTORY_FILE))
        end)
        if success and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function SaveServerToHistory(jobId)
    if writefile then
        local history = GetServerHistory()
        history[jobId] = os.time()
        
        local cleanHistory = {}
        for id, timestamp in pairs(history) do
            if os.time() - timestamp < CONFIG.HISTORY_EXPIRE_TIME then
                cleanHistory[id] = timestamp
            end
        end
        
        local encodedData = HttpService:JSONEncode(cleanHistory)
        pcall(function()
            writefile(CONFIG.HISTORY_FILE, encodedData)
        end)
    end
end

-- ====== LẤY DANH SÁCH SERVER ======
local function GetServerList()
    local currentId = game.JobId
    local history = GetServerHistory()
    local availableServers = {}
    local cursor = ""
    
    for page = 1, 10 do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=50&cursor=" .. cursor
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if not success or not result or not result.data then
            break
        end
        
        for _, server in ipairs(result.data) do
            -- Lọc server
            if server.id ~= currentId 
               and not history[server.id]
               and server.playing >= CONFIG.MIN_PLAYERS
               and server.playing < server.maxPlayers then
                
                table.insert(availableServers, {
                    id = server.id,
                    players = server.playing,
                    maxPlayers = server.maxPlayers,
                    ping = server.ping or 0,
                    region = server.region or "Unknown"
                })
            end
        end
        
        if result.nextPageCursor and result.nextPageCursor ~= "" then
            cursor = result.nextPageCursor
        else
            break
        end
    end
    
    return availableServers
end

-- ====== CHỌN SERVER TỐT NHẤT ======
local function SelectBestServer(servers)
    if #servers == 0 then return nil end
    
    -- Sắp xếp theo số người chơi gần với PREFER_PLAYERS nhất
    table.sort(servers, function(a, b)
        local diffA = math.abs(a.players - CONFIG.PREFER_PLAYERS)
        local diffB = math.abs(b.players - CONFIG.PREFER_PLAYERS)
        return diffA < diffB
    end)
    
    return servers[1]
end

-- ====== HOP SERVER CHÍNH ======
local function HopToDifferentServer()
    Log("Đang tìm kiếm server mới...", "info")
    Log("Server hiện tại: " .. game.JobId, "info")
    
    -- Lưu server hiện tại
    SaveServerToHistory(game.JobId)
    task.wait(0.5)
    
    local attempts = 0
    local allServers = {}
    
    while attempts < CONFIG.MAX_RETRIES do
        attempts = attempts + 1
        Log("Lần thử " .. attempts .. "/" .. CONFIG.MAX_RETRIES, "progress")
        
        allServers = GetServerList()
        
        if #allServers > 0 then
            break
        end
        
        if attempts < CONFIG.MAX_RETRIES then
            Log("Chưa tìm thấy server, thử lại sau 2s...", "warning")
            task.wait(2)
        end
    end
    
    -- Xử lý kết quả
    if #allServers > 0 then
        Log("Đã tìm thấy " .. #allServers .. " server khả dụng", "success")
        
        -- In danh sách server
        if CONFIG.DEBUG_MODE then
            Log("Danh sách server:", "info")
            for i, server in ipairs(allServers) do
                print(string.format("  %d. %s (%d/%d người) - %s", 
                    i, server.id, server.players, server.maxPlayers, server.region))
            end
        end
        
        local targetServer = SelectBestServer(allServers)
        if targetServer then
            Log("Chọn server: " .. targetServer.id .. " (" .. targetServer.players .. "/" .. targetServer.maxPlayers .. " người)", "found")
            Log("Đang kết nối...", "progress")
            
            task.wait(0.3)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
            end)
            
            return true
        end
    end
    
    -- Không tìm thấy server -> teleport ngẫu nhiên
    Log("Không tìm thấy server phù hợp!", "error")
    Log("Teleport ngẫu nhiên...", "warning")
    task.wait(0.5)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end)
    
    return false
end

-- ====== KHỞI CHẠY ======


if not game:IsLoaded() then
    Log("Đợi game load...", "progress")
    game.Loaded:Wait()
end

task.wait(1)

-- Bắt đầu
local success = HopToDifferentServer()

if success then
    Log("Đã thực hiện hop server!", "success")
else
    Log("Hop server thất bại!", "error")
end
