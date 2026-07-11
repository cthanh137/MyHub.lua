local HopServerCode 
-- ============================================================
--   HOP SERVER - GITHUB VERSION
-- ============================================================

local function HopServer()
    local placeId, jobId = game.PlaceId, game.JobId
    local servers, cursor, pages = {}, "", 0
    
    -- Thông báo
    local function notify(title, icon, content)
        pcall(function()
            if Luna and Luna.Notification then
                Luna:Notification({
                    Title = title,
                    Icon = icon,
                    ImageSource = "Material",
                    Content = content
                })
            end
        end)
    end
    
    notify("Hop Server", "search", "Finding new server...")
    
    repeat
        local url = "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=200&cursor=" .. cursor
        local suc, res = pcall(function() 
            return game:GetService("HttpService"):JSONDecode(game:HttpGet(url)) 
        end)
        
        if suc and res and res.data then
            for _, sv in pairs(res.data) do
                if sv.id and sv.id ~= jobId and sv.playing and sv.playing > 0 then
                    table.insert(servers, sv)
                end
            end
            cursor = res.nextPageCursor or ""
            pages = pages + 1
        else
            break
        end
        task.wait(0.1)
    until cursor == "" or #servers >= 30 or pages >= 5
    
    if #servers > 0 then
        local sv = servers[math.random(1, #servers)]
        task.wait(0.5)
        pcall(function() 
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, sv.id, game:GetService("Players").LocalPlayer) 
        end)
        notify("Hop Server", "check", "Found new server!")
    else
        task.wait(0.5)
        pcall(function() 
            game:GetService("TeleportService"):Teleport(placeId, game:GetService("Players").LocalPlayer) 
        end)
        notify("Hop Server", "warning", "No server found, rejoining current.")
    end
end


HopServer()
