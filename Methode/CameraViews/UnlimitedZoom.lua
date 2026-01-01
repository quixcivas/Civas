-- ============================================
-- UNLIMITED ZOOM CAMERA MODULE
-- ============================================
-- Character can walk normally, camera can zoom unlimited

local UnlimitedZoomModule = {}

-- Services
local Players = game:GetService("Players")

-- Variables
local Player = Players.LocalPlayer

-- Save original zoom settings
local originalMinZoom = Player.CameraMinZoomDistance
local originalMaxZoom = Player.CameraMaxZoomDistance

-- State
local unlimitedZoomActive = false

-- ============================================
-- MAIN FUNCTIONS
-- ============================================

function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    
    unlimitedZoomActive = true
    
    -- Remove zoom limits (character can still move)
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 9999
    
    print("✅ Unlimited Zoom: ENABLED")
    print("📷 Scroll to zoom in/out without limits")
    print("🏃 Character can move normally")
    
    return true
end

function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    
    unlimitedZoomActive = false
    
    -- Restore original zoom limits
    Player.CameraMinZoomDistance = originalMinZoom
    Player.CameraMaxZoomDistance = originalMaxZoom
    
    print("🔴 Unlimited Zoom: DISABLED")
    print("📷 Zoom limits restored")
    
    return true
end

function UnlimitedZoomModule.IsActive()
    return unlimitedZoomActive
end


return UnlimitedZoomModule
