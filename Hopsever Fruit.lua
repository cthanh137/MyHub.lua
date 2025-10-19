local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Đảm bảo đã lấy được LocalPlayer
if not LocalPlayer then
    Players.LocalPlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ⚙️ Cấu hình
local MIN_PLAYER_COUNT = 10
local MAX_PLAYER_COUNT = 18
local PLACE_ID = game.PlaceId
local MAX_PAGES = 50
local RETRY_DELAY = 2 -- Tăng delay một chút để an toàn hơn

-- Lấy danh sách server đã thử từ session trước
local triedServers = TeleportService:GetTeleportSetting("TriedServersList")

-- Nếu không có danh sách (lần chạy đầu) hoặc data hỏng, tạo bảng mới
if typeof(triedServers) ~= "table" then
    triedServers = {}
end

-- Thêm server HIỆN TẠI vào danh sách đã thử để tránh bị lặp lại chính nó
triedServers[game.JobId] = true
-- Lưu lại ngay lập tức
TeleportService:SetTeleportSetting("TriedServersList", triedServers)

-- 🔍 Lấy danh sách server
local function GetServers(placeId)
    local servers = {}
    local cursor = ""
    local pageCount = 0

    repeat
        pageCount += 1
        if pageCount > MAX_PAGES then break end

        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=50&cursor=%s", placeId, cursor)
        
        -- Giả định rằng 'request' là một hàm global hoạt động (ví dụ: trong một môi trường đặc biệt)
        -- Trong LocalScript chuẩn, bạn sẽ cần dùng RemoteFunction để gọi lên server
        local success, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)

        if success and response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    -- ⭐️ THAY ĐỔI QUAN TRỌNG:
                    -- 1. not triedServers[server.id]: Server chưa từng thử
                    -- 2. server.playing >= MIN_PLAYER_COUNT: Đủ người tối thiểu
                    -- 3. server.playing <= MAX_PLAYER_COUNT: Không quá đông
                    -- 4. server.playing < server.maxPlayers: CHẮC CHẮN CÒN CHỖ TRỐNG (tránh lỗi full 18/18)
                    if not triedServers[server.id] and
                       server.playing >= MIN_PLAYER_COUNT and
                       server.playing <= MAX_PLAYER_COUNT and
                       server.playing < server.maxPlayers then
                        
                        table.insert(servers, server)
                    end
                end
                cursor = data.nextPageCursor or ""
            else
                break
            end
        else
            warn("⚠️ Lỗi khi lấy danh sách server:", response and response.Body)
            break
        end
    until cursor == ""

    return servers
end

-- 🧭 Tìm server
local function FindServer()
    local allServers = GetServers(PLACE_ID)
    if #allServers == 0 then
        warn("❌ Không có server nào khả dụng hoặc đã thử tất cả. Đang reset danh sách...")
        -- Reset danh sách và thêm lại server hiện tại
        triedServers = {}
        triedServers[game.JobId] = true
        TeleportService:SetTeleportSetting("TriedServersList", triedServers) -- Lưu danh sách đã reset
        return nil
    end

    -- Chọn server ngẫu nhiên trong danh sách hợp lệ
    local server = allServers[math.random(1, #allServers)]
    return server
end

-- 🔁 Vòng lặp auto hop (sẽ chạy lại mỗi khi vào server mới)
while task.wait(RETRY_DELAY) do
    local targetServer = FindServer()
    
    if targetServer then
        warn(string.format("🔄 Chuẩn bị chuyển sang server [ID: %s] có %d/%d người...", targetServer.id:sub(1, 8), targetServer.playing, targetServer.maxPlayers))

        -- ⭐️ ĐÁNH DẤU SERVER SẮP VÀO LÀ "ĐÃ THỬ" TRƯỚC KHI TELEPORT
        triedServers[targetServer.id] = true
        -- LƯU DANH SÁCH NÀY CHO LẦN CHẠY SCRIPT TIẾP THEO (SAU KHI TELEPORT XONG)
        TeleportService:SetTeleportSetting("TriedServersList", triedServers)

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServer.id, LocalPlayer)
        end)
        
        if ok then
            -- Teleport đã được BẮT ĐẦU. Script sẽ dừng ở đây.
            -- Khi vào server mới, script sẽ chạy lại từ đầu và đọc 'TriedServersList' đã lưu.
            break 
        else
            -- Lỗi teleport (ví dụ: server vừa đầy ngay trước khi teleport)
            -- 'triedServers' đã lưu ID này, nên vòng lặp tiếp theo sẽ không chọn lại nó
            warn("⚠️ Lỗi teleport (server có thể đã đầy):", err)
        end
    else
        -- FindServer() trả về nil (do đã reset hoặc đang chờ)
        warn("⏳ Không tìm thấy server phù hợp, thử lại sau...")
    end
end
