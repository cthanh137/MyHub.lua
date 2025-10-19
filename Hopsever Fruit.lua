--[[  
    🚀 PERFECT SERVER HOP V7 — SMART FRUIT LOGGER + AUTO HOP ON DETECT
    ✅ Nếu phát hiện fruit: gửi Discord + ngay lập tức hop tiếp (không đứng im).
    ✅ Nếu không có fruit: tìm server khác, teleport liên tục.
    ✅ Không trùng server, retry tức thì nếu lỗi request.
    ✅ Gửi log Discord khi phát hiện fruit và khi teleport thành công.
    ⚙️ Dùng được với Synapse, Krnl, Fluxus, v.v. (yêu cầu request()/syn.request())
--]]

-----------------------------------------------------
-- Dịch vụ & cấu hình
-----------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

-- Webhook
local FRUIT_WEBHOOK = "https://discord.com/api/webhooks/1420703163027292222/uVVi0t2O3HYkb6Q8DXXVO6ZjsF1ilojAkss_M07rT46l2z0OFIYB_eurzTAA1Z9886Am"
local HOP_WEBHOOK   = "https://discord.com/api/webhooks/1429493470531424407/97lyF_Xu50SPQ8DXiXTc5B-vEhZD2UwehBqnC37VMlR2ZVX7mR3e18iwZsZ2TV0LViQP"

-- Target fruits
local TARGET_FRUITS = {
    ["Gas Fruit"]=true, ["Flare Fruit"]=true, ["Sand Fruit"]=true, ["Rare Box"]=true,
    ["Chilly Fruit"]=true, ["Rumble Fruit"]=true, ["Magma Fruit"]=true, ["Phoenix Fruit"]=true,
    ["Quake Fruit"]=true, ["Ultra Rare Box"]=true, ["String Fruit"]=true, ["Dark Fruit"]=true,
    ["Light Fruit"]=true, ["Candy Fruit"]=true, ["Hollow Fruit"]=true, ["Vampire Fruit"]=true
}

-- Behavior tuning
local PLACE_ID     = game.PlaceId
local MAX_PAGES    = 10
local RETRY_DELAY  = 0.05         -- nhỏ, retry nhanh để giảm khả năng fail
local HOP_COOLDOWN = 0.1          -- nghỉ chút trước khi teleport (an toàn)
local MIN_SECONDS_BETWEEN_WEBHOOKS = 1.0
local lastWebhookTick = 0

-----------------------------------------------------
-- Helper functions
-----------------------------------------------------
local function Timestamp()
    local t = os.date("!*t")
    return string.format("%02d/%02d/%04d %02d:%02d:%02d UTC", t.day, t.month, t.year, t.hour, t.min, t.sec)
end

local function safe_request_get(url)
    while true do
        local ok, res = pcall(function()
            return request and request({Url = url, Method = "GET"}) or (syn and syn.request and syn.request({Url = url, Method = "GET"}))
        end)
        if ok and res and res.StatusCode == 200 then
            local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if success and data and data.data then
                return data
            end
        end
        task.wait(RETRY_DELAY)
    end
end

local function safe_request_post(webhook, payloadTable)
    -- rate local
    if tick() - lastWebhookTick < MIN_SECONDS_BETWEEN_WEBHOOKS then return false end
    lastWebhookTick = tick()
    local body = HttpService:JSONEncode(payloadTable)
    pcall(function()
        request({
            Url = webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end)
    return true
end

-----------------------------------------------------
-- Scan fruits (Backpack, Character, Workspace)
-- returns found table or empty table
-----------------------------------------------------
local function ScanFruits()
    local found = {}

    -- Players (Backpack + Character)
    for _, plr in ipairs(Players:GetPlayers()) do
        -- Backpack
        local bp = plr:FindFirstChild("Backpack")
        if bp then
            for _, it in ipairs(bp:GetChildren()) do
                if TARGET_FRUITS[it.Name] then
                    found[plr.Name] = found[plr.Name] or {}
                    table.insert(found[plr.Name], it.Name .. " (Backpack)")
                end
            end
        end
        -- Character tools
        if plr.Character then
            for _, it in ipairs(plr.Character:GetChildren()) do
                if it:IsA("Tool") and TARGET_FRUITS[it.Name] then
                    found[plr.Name] = found[plr.Name] or {}
                    table.insert(found[plr.Name], it.Name .. " (Character)")
                end
            end
        end
    end

    -- Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and TARGET_FRUITS[obj.Name] then
            local parent = obj.Parent
            local isPlayerModel = parent and parent:IsA("Model") and Players:FindFirstChild(parent.Name)
            if not isPlayerModel then
                found["Workspace"] = found["Workspace"] or {}
                local ok, full = pcall(function() return obj:GetFullName() end)
                table.insert(found["Workspace"], obj.Name .. " @ " .. (ok and full or tostring(obj.Parent and obj.Parent.Name or "Unknown")))
            else
                found[parent.Name] = found[parent.Name] or {}
                local ok, full = pcall(function() return obj:GetFullName() end)
                table.insert(found[parent.Name], obj.Name .. " (In Model) @ " .. (ok and full or tostring(parent.Name)))
            end
        end
    end

    return found
end

-----------------------------------------------------
-- Build embed(s)
-----------------------------------------------------
local function BuildFruitEmbed(foundTable)
    local fields = {}
    for name, items in pairs(foundTable) do
        table.insert(fields, { name = "👤 "..name, value = table.concat(items, ", "), inline = false })
    end
    local embed = {
        title = "📢 Phát hiện trái hiếm trong server!",
        color = 15158332,
        fields = fields,
        footer = { text = "🕒 "..Timestamp() }
    }
    return { username = "Fruit Scanner", embeds = { embed } }
end

local function BuildHopEmbed(jobId)
    local embed = {
        title = "✅ Teleport Thành Công!",
        description = string.format("**Người chơi:** %s\n**Job ID:** %s\n**Place ID:** %s\n**Thời gian:** %s", LocalPlayer.Name, tostring(jobId), tostring(PLACE_ID), Timestamp()),
        color = 65280
    }
    return { username = "Server Hop Logger", embeds = { embed } }
end

-----------------------------------------------------
-- Server hop util (no duplicate)
-----------------------------------------------------
local TriedServers = TeleportService:GetTeleportSetting("TriedServersList")
if typeof(TriedServers) ~= "table" then TriedServers = {} end
TriedServers[game.JobId] = true
TeleportService:SetTeleportSetting("TriedServersList", TriedServers)

local function FindServer()
    local cursor = ""
    for _ = 1, MAX_PAGES do
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&cursor=%s", PLACE_ID, cursor)
        local data = safe_request_get(url)
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

-----------------------------------------------------
-- Main flow:
-- 1) Scan fruits.
-- 2) If found: send fruit webhook, mark current server tried, then hop immediately.
-- 3) If not found: start hop loop to find server with (optionally) fruits.
-----------------------------------------------------
-----------------------------------------------------

-- Send a log that we just loaded this server
pcall(function()
    safe_request_post(HOP_WEBHOOK, BuildHopEmbed(game.JobId))
end)

-- Scan once immediately
local found = ScanFruits()
local foundAny = next(found) ~= nil

if foundAny then
    -- Send fruit embed (throttle local)
    local fruitPayload = BuildFruitEmbed(found)
    pcall(function() safe_request_post(FRUIT_WEBHOOK, fruitPayload) end)

    -- Mark current server as tried (so we won't re-enter it)
    TriedServers[game.JobId] = true
    TeleportService:SetTeleportSetting("TriedServersList", TriedServers)

    -- Optional: copy teleport command to clipboard for manual join (best-effort)
    pcall(function()
        local teleportCmd = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', PLACE_ID, game.JobId)
        if setclipboard then pcall(setclipboard, teleportCmd) end
        if toclipboard then pcall(toclipboard, teleportCmd) end
    end)

    -- After reporting, immediately hop to next server to continue scanning
    -- (we still send a hop log for this teleport below inside the loop)
end

-- Hop loop (always runs until teleport succeeds)
while true do
    local target = FindServer()
    if target then
        -- mark and send hop log
        TriedServers[target] = true
        TeleportService:SetTeleportSetting("TriedServersList", TriedServers)

        -- send hop webhook (best-effort, non-blocking)
        pcall(function() safe_request_post(HOP_WEBHOOK, BuildHopEmbed(target)) end)

        -- small safe wait then teleport
        task.wait(HOP_COOLDOWN)
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, target, LocalPlayer)
        end)
        if ok then
            -- if teleport succeeds, script will stop here on this client (the new server will run script anew)
            break
        else
            -- teleport failed (maybe just filled) -> continue searching (no duplicate)
            warn("Teleport error, continuing:", err)
            task.wait(RETRY_DELAY)
        end
    else
        -- no server found: reset tried list (so we can loop again)
        TriedServers = {}
        TriedServers[game.JobId] = true
        TeleportService:SetTeleportSetting("TriedServersList", TriedServers)
        task.wait(RETRY_DELAY)
    end
end
