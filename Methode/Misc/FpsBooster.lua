-- ==============================================================
--                ⭐ FPS BOOSTER MODULE (OPTIMIZED) ⭐
--                    Ready untuk GUI Integration
-- ==============================================================

local FPSBooster = {}
FPSBooster.Enabled = false

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Storage untuk restore
local originalStates = {
    reflectance = {},
    transparency = {},
    lighting = {},
    effects = {},
    waterProperties = {}
}

-- Connection untuk new objects
local newObjectConnection = nil

-- Fungsi untuk optimize single object
local function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    
    pcall(function()
        -- Optimize BasePart (Bangunan, model, dll)
        if obj:IsA("BasePart") then
            -- Simpan original states (JANGAN UBAH WARNA & MATERIAL)
            if not originalStates.reflectance[obj] then
                originalStates.reflectance[obj] = obj.Reflectance
            end
            
            -- Hapus reflections & shadows saja
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        
        -- Matikan Decals & Textures
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if not originalStates.transparency[obj] then
                originalStates.transparency[obj] = obj.Transparency
            end
            obj.Transparency = 1 -- Invisible
        end
        
        -- Matikan SurfaceAppearance (texture PBR)
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
        
        -- Matikan ParticleEmitter (debu, asap, dll)
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false
        end
        
        -- Matikan Trail effects
        if obj:IsA("Trail") then
            obj.Enabled = false
        end
        
        -- Matikan Beam effects
        if obj:IsA("Beam") then
            obj.Enabled = false
        end
        
        -- Matikan Fire, Smoke, Sparkles
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

-- Fungsi untuk restore single object
local function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            if originalStates.reflectance[obj] then
                obj.Reflectance = originalStates.reflectance[obj]
                obj.CastShadow = true
            end
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if originalStates.transparency[obj] then
                obj.Transparency = originalStates.transparency[obj]
            end
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = true
        end
        
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = true
        end
    end)
end

-- ============================================
-- MAIN ENABLE FUNCTION
-- ============================================
function FPSBooster.Enable()
    if FPSBooster.Enabled then
        return false, "Already enabled"
    end
    
    FPSBooster.Enabled = true
    
    -----------------------------------------
    -- 1. Optimize semua existing objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end
    
    -----------------------------------------
    -- 2. MATIKAN ANIMASI AIR (Terrain Water)
    -----------------------------------------
    if Terrain then
        pcall(function()
            -- Simpan water properties
            originalStates.waterProperties = {
                WaterReflectance = Terrain.WaterReflectance,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed
            }
            
            -- Matikan animasi air (WARNA TETAP DEFAULT)
            Terrain.WaterWaveSize = 0 -- NO WAVES
            Terrain.WaterWaveSpeed = 0 -- NO ANIMATION
            Terrain.WaterReflectance = 0 -- NO REFLECTION
        end)
    end
    
    -----------------------------------------
    -- 3. Optimize Lighting (Hapus Shadows & Fog)
    -----------------------------------------
    originalStates.lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
    }
    
    Lighting.GlobalShadows = false -- NO SHADOWS
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000 -- NO FOG
    
    -----------------------------------------
    -- 4. Matikan Post-Processing Effects
    -----------------------------------------
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end
    
    -----------------------------------------
    -- 5. Set Render Quality ke MINIMUM
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -----------------------------------------
    -- 6. Hook new objects yang spawn
    -----------------------------------------
    newObjectConnection = workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then
            task.wait(0.1) -- Delay kecil
            optimizeObject(obj)
        end
    end)
    
    return true, "FPS Booster enabled"
end

-- ============================================
-- MAIN DISABLE FUNCTION
-- ============================================
function FPSBooster.Disable()
    if not FPSBooster.Enabled then
        return false, "Already disabled"
    end
    
    FPSBooster.Enabled = false
    
    -----------------------------------------
    -- 1. Restore semua objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        restoreObject(obj)
    end
    
    -----------------------------------------
    -- 2. Restore Terrain Water
    -----------------------------------------
    if Terrain and originalStates.waterProperties then
        pcall(function()
            Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
            Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
            Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
        end)
    end
    
    -----------------------------------------
    -- 3. Restore Lighting
    -----------------------------------------
    if originalStates.lighting.GlobalShadows ~= nil then
        Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
        Lighting.FogEnd = originalStates.lighting.FogEnd
        Lighting.FogStart = originalStates.lighting.FogStart
    end
    
    -----------------------------------------
    -- 4. Restore Post-Processing
    -----------------------------------------
    for effect, state in pairs(originalStates.effects) do
        if effect and effect.Parent then
            effect.Enabled = state
        end
    end
    
    -----------------------------------------
    -- 5. Restore Render Quality
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    
    -----------------------------------------
    -- 6. Disconnect hook
    -----------------------------------------
    if newObjectConnection then
        newObjectConnection:Disconnect()
        newObjectConnection = nil
    end
    
    -- Clear original states
    originalStates = {
        reflectance = {},
        transparency = {},
        lighting = {},
        effects = {},
        waterProperties = {}
    }
    
    return true, "FPS Booster disabled"
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function FPSBooster.IsEnabled()
    return FPSBooster.Enabled
end

return FPSBooster
