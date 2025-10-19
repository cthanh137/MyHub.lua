--[[  
    🚀 PERFECT SERVER HOP V5 (0% FAIL, NO DUPLICATE, DISCORD LOG)
    ✅ Tự động hop mượt, retry liên tục nếu request lỗi.
    ✅ Không vào lại server cũ, không bị stuck, không chờ delay.
    ✅ Gửi log Discord mỗi khi teleport thành công.
    ⚙️ Dùng được với Synapse, Solara, Krnl, Fluxus, v.v.
--]]

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- 🔗 Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1429493470531424407/97lyF_Xu50SPQ8DXiXTc5B-vEhZD2UwehBqnC37VMlR2ZVX7mR3e18iwZsZ2TV0LViQP"

-- ⚙️ Config
local PLACE_ID = game.PlaceId
local MAX_PAGES = 2000
local RETRY_DELAY = 0.01 -- cực nhỏ, hop siêu nhanh

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
			"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=200&cursor=%s",
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
