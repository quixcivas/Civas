-- =====================================================
-- DISABLE 3D RENDERING MODULE (CLEAN VERSION)
-- For integration with Quix GUI v2.3
-- =====================================================

local DisableRendering = {}

-- =====================================================
-- SERVICES
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- CONFIGURATION
-- =====================================================
DisableRendering.Settings = {
    AutoPersist = true -- Keep active after respawn
}

-- =====================================================
-- STATE VARIABLES
-- =====================================================
local State = {
    RenderingDisabled = false,
    RenderConnection = nil
}

-- =====================================================
-- PUBLIC API FUNCTIONS
-- =====================================================

-- Start disable rendering
function DisableRendering.Start()
    if State.RenderingDisabled then
        return false, "Already disabled"
    end
    
    local success, err = pcall(function()
        -- Disable 3D rendering
        State.RenderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end)
        
        State.RenderingDisabled = true
    end)
    
    if not success then
        warn("[DisableRendering] Failed to start:", err)
        return false, "Failed to start"
    end
    
    return true, "Rendering disabled"
end

-- Stop disable rendering
function DisableRendering.Stop()
    if not State.RenderingDisabled then
        return false, "Already enabled"
    end
    
    local success, err = pcall(function()
        -- Disconnect render loop
        if State.RenderConnection then
            State.RenderConnection:Disconnect()
            State.RenderConnection = nil
        end
        
        -- Re-enable rendering
        RunService:Set3dRenderingEnabled(true)
        
        State.RenderingDisabled = false
    end)
    
    if not success then
        warn("[DisableRendering] Failed to stop:", err)
        return false, "Failed to stop"
    end
    
    return true, "Rendering enabled"
end

-- Toggle rendering
function DisableRendering.Toggle()
    if State.RenderingDisabled then
        return DisableRendering.Stop()
    else
        return DisableRendering.Start()
    end
end

-- Get current status
function DisableRendering.IsDisabled()
    return State.RenderingDisabled
end

-- =====================================================
-- AUTO-PERSIST ON RESPAWN
-- =====================================================
if DisableRendering.Settings.AutoPersist then
    LocalPlayer.CharacterAdded:Connect(function()
        if State.RenderingDisabled then
            task.wait(0.5)
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end
    end)
end

-- =====================================================
-- CLEANUP FUNCTION
-- =====================================================
function DisableRendering.Cleanup()
    -- Enable rendering if disabled
    if State.RenderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
    end
    
    -- Disconnect all connections
    if State.RenderConnection then
        State.RenderConnection:Disconnect()
    end
end

return DisableRendering
