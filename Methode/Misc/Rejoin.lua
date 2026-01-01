-- Standalone Rejoin Script - GUI Compatible (BUTTON ONLY)
-- NO EXTERNAL DEPENDENCIES - SELF CONTAINED

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RejoinModule = {}
RejoinModule.Version = "1.0.0"

-- Fungsi untuk rejoin ke server yang sama
function RejoinModule.RejoinSameServer()
    local jobId = game.JobId
    local placeId = game.PlaceId
    
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("🔄 REJOINING SAME SERVER")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("📍 PlaceId:", placeId)
    print("🆔 JobId:", jobId)
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)
    
    if success then
        print("✅ Rejoin request sent!")
        return true
    else
        warn("❌ Rejoin failed:", err)
        return false, err
    end
end

-- Fungsi untuk rejoin ke server random (baru)
function RejoinModule.Execute()
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("🔄 REJOIN SCRIPT STARTED")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    local placeId = game.PlaceId
    
    print("📍 PlaceId:", placeId)
    print("🌐 Teleporting to new server...")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    -- Teleport ke server baru
    local success, err = pcall(function()
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
    
    if success then
        print("✅ Rejoin request sent!")
        return true
    else
        warn("❌ Rejoin failed:", err)
        return false, err
    end
end

-- Alias untuk kemudahan
RejoinModule.Rejoin = RejoinModule.Execute
RejoinModule.NewServer = RejoinModule.Execute
RejoinModule.SameServer = RejoinModule.RejoinSameServer

print("✓ RejoinModule loaded successfully v" .. RejoinModule.Version)

return RejoinModule
