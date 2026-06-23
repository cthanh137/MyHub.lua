-- ==========================================================
-- ĐOẠN CODE CHẠY NGẦM ANTI-AFK (Dán vào script chính của bạn)
-- ==========================================================
task.spawn(function()
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    
    -- Đợi cho đến khi người chơi tải vào game hoàn toàn (tránh lỗi bị nil LocalPlayer)
    if not Players.LocalPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end
    local LocalPlayer = Players.LocalPlayer

    -- Bắt đầu lắng nghe sự kiện AFK ngầm
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            print("[Anti-AFK] Đã giả lập tương tác ngầm thành công!")
        end)
    end)
    
    print("[Hệ thống] Anti-AFK đã kích hoạt ngầm thành công!")
end)
-- ==========================================================
-- BẮT ĐẦU SCRIPT CHÍNH CỦA BẠN Ở ĐÂY
-- ==========================================================

-- (Dán tiếp đoạn code farm, script chính, hoặc các tính năng khác của bạn ở dưới này...)
