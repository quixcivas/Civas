-- 💤 FungsiKeaby/Misc/AntiAFK.lua
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AntiAFK = {
    Enabled = false,
    Connection = nil
}

function AntiAFK.Start()
    if AntiAFK.Enabled then return end
    AntiAFK.Enabled = true
    print("🟢 Anti-AFK diaktifkan")

    AntiAFK.Connection = localPlayer.Idled:Connect(function()
        if AntiAFK.Enabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            print("💤 [AntiAFK] Mencegah kick karena idle...")
        end
    end)
end

function AntiAFK.Stop()
    if not AntiAFK.Enabled then return end
    AntiAFK.Enabled = false
    print("🔴 Anti-AFK dimatikan")

    if AntiAFK.Connection then
        AntiAFK.Connection:Disconnect()
        AntiAFK.Connection = nil
    end
end

return AntiAFK
