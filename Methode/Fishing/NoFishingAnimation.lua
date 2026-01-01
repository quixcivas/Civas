-- NoFishingAnimation.lua
-- Auto freeze karakter di pose fishing dengan ZERO animasi
-- Ready untuk diintegrasikan ke GUI

local NoFishingAnimation = {}
NoFishingAnimation.Enabled = false
NoFishingAnimation.Connection = nil
NoFishingAnimation.SavedPose = {}
NoFishingAnimation.ReelingTrack = nil
NoFishingAnimation.AnimationBlocker = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Fungsi untuk find ReelingIdle animation
local function getOrCreateReelingAnimation()
    local success, result = pcall(function()
        local character = localPlayer.Character
        if not character then return nil end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- Cari animasi ReelingIdle yang sudah ada
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local name = track.Name
            if name:find("Reel") and name:find("Idle") then
                return track
            end
        end
        
        -- Cari di semua loaded animations
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Animation then
                if track.Name:find("Reel") then
                    return track
                end
            end
        end
        
        -- Jika tidak ada, coba cari di character tools
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, anim in pairs(tool:GetDescendants()) do
                    if anim:IsA("Animation") then
                        local name = anim.Name
                        if name:find("Reel") and name:find("Idle") then
                            local track = animator:LoadAnimation(anim)
                            return track
                        end
                    end
                end
            end
        end
        
        return nil
    end)
    
    if success then
        return result
    end
    return nil
end

-- Fungsi untuk capture pose dari Motor6D
local function capturePose()
    NoFishingAnimation.SavedPose = {}
    local count = 0
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        -- Simpan SEMUA Motor6D
        for _, descendant in pairs(character:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                NoFishingAnimation.SavedPose[descendant.Name] = {
                    Part = descendant,
                    C0 = descendant.C0,
                    C1 = descendant.C1,
                    Transform = descendant.Transform
                }
                count = count + 1
            end
        end
    end)
    
    return count > 0
end

-- Fungsi untuk STOP SEMUA animasi secara permanent
local function killAllAnimations()
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        
        -- STOP semua playing animations
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
        
        -- STOP semua humanoid animations
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
    end)
end

-- Fungsi untuk BLOCK animasi baru agar tidak play
local function blockNewAnimations()
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
    end
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end
        
        -- Hook semua animasi baru yang mau play
        NoFishingAnimation.AnimationBlocker = animator.AnimationPlayed:Connect(function(animTrack)
            if NoFishingAnimation.Enabled then
                animTrack:Stop(0)
                animTrack:Destroy()
            end
        end)
    end)
end

-- Fungsi untuk freeze pose
local function freezePose()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
    end
    
    NoFishingAnimation.Connection = RunService.RenderStepped:Connect(function()
        if not NoFishingAnimation.Enabled then return end
        
        pcall(function()
            local character = localPlayer.Character
            if not character then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            -- FORCE STOP semua animasi setiap frame
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
            
            -- APPLY SAVED POSE setiap frame
            for jointName, poseData in pairs(NoFishingAnimation.SavedPose) do
                local motor = character:FindFirstChild(jointName, true)
                if motor and motor:IsA("Motor6D") then
                    motor.C0 = poseData.C0
                    motor.C1 = poseData.C1
                end
            end
        end)
    end)
end

-- Fungsi Stop
local function stopFreeze()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
        NoFishingAnimation.Connection = nil
    end
    
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
        NoFishingAnimation.AnimationBlocker = nil
    end
    
    if NoFishingAnimation.ReelingTrack then
        NoFishingAnimation.ReelingTrack:Stop()
        NoFishingAnimation.ReelingTrack = nil
    end
    
    NoFishingAnimation.SavedPose = {}
end

-- ============================================
-- PUBLIC FUNCTIONS (untuk GUI)
-- ============================================

-- Fungsi Start (AUTO - tanpa perlu memancing dulu)
function NoFishingAnimation.Start()
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    local character = localPlayer.Character
    if not character then 
        return false, "Character not found"
    end
    
    -- 1. Cari atau buat ReelingIdle animation
    local reelingTrack = getOrCreateReelingAnimation()
    
    if reelingTrack then
        -- 2. Play animasi (pause setelah beberapa frame)
        reelingTrack:Play()
        reelingTrack:AdjustSpeed(0) -- Pause animasi di frame pertama
        
        NoFishingAnimation.ReelingTrack = reelingTrack
        
        -- 3. Tunggu animasi apply ke Motor6D
        task.wait(0.2)
        
        -- 4. Capture pose
        local success = capturePose()
        
        if success then
            -- 5. KILL semua animasi
            killAllAnimations()
            
            -- 6. Block animasi baru
            blockNewAnimations()
            
            -- 7. Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            return true, "Pose frozen successfully"
        else
            reelingTrack:Stop()
            return false, "Failed to capture pose"
        end
    else
        return false, "Reeling animation not found"
    end
end

-- Fungsi Start dengan delay (RECOMMENDED)
function NoFishingAnimation.StartWithDelay(delay, callback)
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    delay = delay or 2
    
    -- Jalankan di coroutine agar tidak blocking
    task.spawn(function()
        task.wait(delay)
        
        local success = capturePose()
        
        if success then
            -- KILL semua animasi
            killAllAnimations()
            
            -- Block animasi baru
            blockNewAnimations()
            
            -- Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            -- Callback jika ada
            if callback then
                callback(true, "Pose frozen successfully")
            end
        else
            -- Callback error
            if callback then
                callback(false, "Failed to capture pose")
            end
        end
    end)
    
    return true, "Starting with delay..."
end

-- Fungsi Stop
function NoFishingAnimation.Stop()
    if not NoFishingAnimation.Enabled then
        return false, "Already disabled"
    end
    
    NoFishingAnimation.Enabled = false
    stopFreeze()
    
    return true, "Pose unfrozen"
end

-- Fungsi untuk cek status
function NoFishingAnimation.IsEnabled()
    return NoFishingAnimation.Enabled
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Handle respawn
localPlayer.CharacterAdded:Connect(function(character)
    if NoFishingAnimation.Enabled then
        NoFishingAnimation.Enabled = false
        stopFreeze()
    end
end)

-- Cleanup
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        if NoFishingAnimation.Enabled then
            NoFishingAnimation.Stop()
        end
    end
end)

return NoFishingAnimation
