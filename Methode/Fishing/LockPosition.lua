-- LockPosition.lua
local RunService = game:GetService("RunService")

local LockPosition = {}
LockPosition.Enabled = false
LockPosition.LockedPos = nil
LockPosition.Connection = nil

-- Aktifkan Lock Position
function LockPosition.Start()
    if LockPosition.Enabled then return end
    LockPosition.Enabled = true

    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    LockPosition.LockedPos = hrp.CFrame

    -- Loop untuk menjaga posisi
    LockPosition.Connection = RunService.Heartbeat:Connect(function()
        if not LockPosition.Enabled then return end

        local c = player.Character
        if not c then return end
        
        local hrp2 = c:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end

        -- Selalu kembalikan ke posisi yang dikunci
        hrp2.CFrame = LockPosition.LockedPos
    end)

    print("Lock Position: Activated")
end

-- Nonaktifkan Lock Position
function LockPosition.Stop()
    LockPosition.Enabled = false

    if LockPosition.Connection then
        LockPosition.Connection:Disconnect()
        LockPosition.Connection = nil
    end

    print("Lock Position: Deactivated")
end

return LockPosition
