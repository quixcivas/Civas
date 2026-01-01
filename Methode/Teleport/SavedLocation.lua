-- SaveLocation.lua
local SaveLocation = {}

local savedPos = nil

-- RAW Notification (langsung SetCore)
local function Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4
        })
    end)
end

-- Simpan posisi
function SaveLocation.Save()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    savedPos = hrp.Position

    Notify("Saved Location", "Lokasi tersimpan!", 4)
end

-- Teleport ke lokasi tersimpan
function SaveLocation.Teleport()
    if not savedPos then
        Notify("Error", "Belum ada lokasi yang disimpan!", 4)
        return false
    end
    
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    hrp.CFrame = CFrame.new(savedPos)

    Notify("Teleported", "Teleport berhasil!", 4)
    return true
end

-- Reset lokasi tersimpan
function SaveLocation.Reset()
    savedPos = nil
    Notify("Location Reset", "Lokasi tersimpan dihapus!", 4)
end

return SaveLocation
