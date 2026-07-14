-- ====== SCRIPT HOP SERVER SMART ======
-- Tự động tìm và hop đến server không full
-- Lưu lịch sử server đã đi qua để tránh hop lại

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- ====== CẤU HÌNH ======
local CONFIG = {
    HISTORY_FILE = "serversave.txt",    -- File lưu lịch sử
    MIN_PLAYERS = 1,                    -- Số người tối thiểu
    MAX_PLAYERS = 20,                   -- Số người tối đa muốn (0 =不限)
    PREFER_PLAYERS = 5,                 -- Số người lý tưởng
    MAX_RETRIES = 3,                    -- Số lần thử tối đa
    SAVE_HISTORY = true,                -- Bật/tắt lưu lịch sử
    DEBUG_MODE = true,
    AUTO_HOP = true                     -- Tự động hop hay chỉ hiển thị
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
        found = "🎯",
        skip = "⏭️",
        save = "💾",
        load = "📂"
    }
    print((prefix[type] or "📌") .. " " .. message)
end

-- ====== QUẢN LÝ LỊCH SỬ SERVER ======

-- Kiểm tra file tồn tại
local function FileExists(fileName)
    if not isfile then return false end
    local success, result = pcall(function()
        return isfile(fileName)
    end)
    return success and result
end

-- Đọc lịch sử từ file
local function LoadHistory()
    if not FileExists(CONFIG.HISTORY_FILE) then
        Log("Chua co lich su hop server!", "info")
        return {}
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG.HISTORY_FILE))
    end)
    
    if success and type(data) == "table" then
        Log("Da doc lich su: " .. #data .. " server da di qua", "load")
        return data
    end
    
    return {}
end

-- Lưu lịch sử vào file
local function SaveHistory(history)
    if not CONFIG.SAVE_HISTORY then return end
    if not writefile then 
        Log("Khong ho tro writefile!", "warning")
        return 
    end
    
    local success, err = pcall(function()
        local encoded = HttpService:JSONEncode(history)
        writefile(CONFIG.HISTORY_FILE, encoded)
    end)
    
    if success then
        Log("Da luu lich su: " .. #history .. " server", "save")
    else
        Log("Loi luu file: " .. tostring(err), "error")
    end
end

-- Thêm server vào lịch sử
local function AddToHistory(history, jobId)
    if not history then history = {} end
    
    -- Kiểm tra đã tồn tại chưa
    for _, id in ipairs(history) do
        if id == jobId then
            return history
        end
    end
    
    -- Thêm mới
    table.insert(history, jobId)
    
    -- Giới hạn số lượng (giữ 100 server gần nhất)
    if #history > 100 then
        table.remove(history, 1)
    end
    
    return history
end

-- Kiểm tra server đã đi qua chưa
local function IsServerVisited(history, jobId)
    if not history then return false end
    for _, id in ipairs(history) do
        if id == jobId then
            return true
        end
    end
    return false
end

-- ====== LẤY DANH SÁCH SERVER ======
local function GetServerList(history)
    local currentId = game.JobId
    local availableServers = {}
    local cursor = ""
    local pageCount = 0
    local visitedCount = 0
    
    Log("Dang tim kiem server...", "progress")
    Log("Server hien tai: " .. currentId, "info")
    Log("Da di qua " .. #history .. " server", "info")
    
    while pageCount < 5 do
        pageCount = pageCount + 1
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100&cursor=" .. cursor
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if not success or not result or not result.data then
            break
        end
        
        for _, server in ipairs(result.data) do
            -- Kiểm tra điều kiện
            local isVisited = IsServerVisited(history, server.id)
            
            -- Bỏ qua server hiện tại và server đã đi qua
            if server.id ~= currentId 
               and not isVisited
               and server.playing >= CONFIG.MIN_PLAYERS
               and server.playing < server.maxPlayers then
                
                -- Kiểm tra số người chơi tối đa
                if CONFIG.MAX_PLAYERS > 0 and server.playing > CONFIG.MAX_PLAYERS then
                    -- Bỏ qua nếu quá đông
                else
                    table.insert(availableServers, {
                        id = server.id,
                        players = server.playing,
                        maxPlayers = server.maxPlayers,
                        ping = server.ping or 0,
                        region = server.region or "Unknown",
                        fps = server.fps or 60
                    })
                end
            elseif isVisited then
                visitedCount = visitedCount + 1
            end
        end
        
        if #availableServers >= 20 then
            break
        end
        
        if result.nextPageCursor and result.nextPageCursor ~= "" then
            cursor = result.nextPageCursor
        else
            break
        end
        
        task.wait(0.1)
    end
    
    if visitedCount > 0 then
        Log("Bo qua " .. visitedCount .. " server da di qua", "skip")
    end
    
    return availableServers
end

-- ====== CHỌN SERVER TỐT NHẤT ======
local function SelectBestServer(servers)
    if #servers == 0 then return nil end
    
    -- Sắp xếp theo tiêu chí
    table.sort(servers, function(a, b)
        -- Ưu tiên số người gần với PREFER_PLAYERS nhất
        local diffA = math.abs(a.players - CONFIG.PREFER_PLAYERS)
        local diffB = math.abs(b.players - CONFIG.PREFER_PLAYERS)
        
        if diffA ~= diffB then
            return diffA < diffB
        end
        
        -- Nếu bằng nhau, ưu tiên ping thấp
        return a.ping < b.ping
    end)
    
    return servers[1]
end

-- ====== HIỂN THỊ DANH SÁCH ======
local function DisplayServerList(servers)
    if #servers == 0 then
        print("")
        Log("KHONG TIM THAY SERVER MOI!", "error")
        print("==================================================")
        print("Ly do co the:")
        print("  • Tat ca server deu full")
        print("  • Tat ca server deu da di qua")
        print("  • Khong co server phu hop")
        print("==================================================")
        return
    end
    
    print("")
    Log("TIM THAY " .. #servers .. " SERVER MOI!", "found")
    print("-------------------------------------------------------")
    print(string.format(" %-3s | %-10s | %-8s | %-10s", 
        "STT", "Nguoi choi", "Ping", "Region"))
    print("-------------------------------------------------------")
    
    for i, server in ipairs(servers) do
        local shortId = string.sub(server.id, 1, 6) .. "..."
        local players = server.players .. "/" .. server.maxPlayers
        local ping = server.ping .. "ms"
        local region = server.region
        
        print(string.format(" %-3s | %-10s | %-8s | %-10s", 
            i, players, ping, region))
    end
    print("-------------------------------------------------------")
end

-- ====== HOP SERVER ======
local function HopToServer(targetServer)
    if not targetServer then return false end
    
    Log("Dang hop den server: " .. targetServer.id, "progress")
    Log("So nguoi choi: " .. targetServer.players .. "/" .. targetServer.maxPlayers, "info")
    Log("Ping: " .. targetServer.ping .. "ms", "info")
    Log("Region: " .. targetServer.region, "info")
    
    task.wait(0.5)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
    end)
    
    if not success then
        Log("Loi hop: " .. tostring(err), "error")
        return false
    end
    
    return true
end

-- ====== MAIN FUNCTION ======
local function SmartHop()
    print("")
    print("==================================================")
    print("        SMART HOP SERVER")
    print("==================================================")
    print("")
    
    -- Đợi game load
    if not game:IsLoaded() then
        Log("Cho game load...", "progress")
        game.Loaded:Wait()
    end
    
    task.wait(0.5)
    
    -- Load lịch sử
    local history = LoadHistory()
    local currentServer = game.JobId
    
    -- Thêm server hiện tại vào lịch sử nếu chưa có
    history = AddToHistory(history, currentServer)
    SaveHistory(history)
    
    local attempts = 0
    local allServers = {}
    
    while attempts < CONFIG.MAX_RETRIES do
        attempts = attempts + 1
        Log("Lan thu " .. attempts .. "/" .. CONFIG.MAX_RETRIES, "progress")
        
        allServers = GetServerList(history)
        
        if #allServers > 0 then
            break
        end
        
        if attempts < CONFIG.MAX_RETRIES then
            Log("Chua tim thay server moi, thu lai sau 2s...", "warning")
            task.wait(2)
        end
    end
    
    -- Hiển thị danh sách
    DisplayServerList(allServers)
    
    -- Chọn server tốt nhất
    local targetServer = SelectBestServer(allServers)
    
    if targetServer then
        print("")
        Log("SERVER TOT NHAT:", "found")
        print(string.format("   ID: %s", targetServer.id))
        print(string.format("   Nguoi choi: %d/%d", targetServer.players, targetServer.maxPlayers))
        print(string.format("   Ping: %sms", targetServer.ping))
        print(string.format("   Region: %s", targetServer.region))
        print("")
        
        if CONFIG.AUTO_HOP then
            -- Lưu server vào lịch sử trước khi hop
            history = AddToHistory(history, targetServer.id)
            SaveHistory(history)
            
            -- Thực hiện hop
            if HopToServer(targetServer) then
                Log("Hop thanh cong!", "success")
                return true
            else
                Log("Hop that bai!", "error")
                return false
            end
        else
            Log("Che do xem truoc - Khong tu dong hop", "info")
            print("De hop, copy JobId: " .. targetServer.id)
            print('TeleportService:TeleportToPlaceInstance(' .. game.PlaceId .. ', "' .. targetServer.id .. '", game.Players.LocalPlayer)')
            return true
        end
    else
        Log("Khong tim thay server phu hop!", "error")
        print("")
        print("Giai phap:")
        print("  1. Xoa file serversave.txt de reset lich su")
        print("  2. Doi cau hinh MIN_PLAYERS hoac MAX_PLAYERS")
        print("  3. Thu lai sau")
        return false
    end
end

-- ====== CHẠY SCRIPT ======
local success, err = pcall(SmartHop)
if not success then
    Log("LOI: " .. tostring(err), "error")
    print("")
    print("Stack trace:")
    print(err)
end
