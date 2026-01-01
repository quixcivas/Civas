-- Auto Fish Module untuk Roblox
-- Module ini dapat diintegrasikan dengan GUI eksternal

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module Table
local GoodPerfectionStable = {}
GoodPerfectionStable.Enabled = false

-- Fungsi untuk menghapus UIGradient
local function removeUIGradient()
    local success, err = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then
            return false
        end
        
        local fishing = playerGui:FindFirstChild("Fishing")
        if not fishing then
            return false
        end
        
        local main = fishing:FindFirstChild("Main")
        if not main then
            return false
        end
        
        local display = main:FindFirstChild("Display")
        if not display then
            return false
        end
        
        local animationBG = display:FindFirstChild("AnimationBG")
        if not animationBG then
            return false
        end
        
        local uiGradient = animationBG:FindFirstChild("UIGradient")
        
        if uiGradient then
            uiGradient:Destroy()
            return true
        else
            return true -- Return true karena tujuan tercapai (tidak ada gradient)
        end
    end)
    
    if not success then
        return false
    end
    
    return true
end

-- Fungsi untuk mengaktifkan auto fishing in-game
local function enableAutoFishing(state)
    local success, result = pcall(function()
        -- Path lengkap sesuai dengan yang Anda berikan
        local packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not packages then
            warn("Packages tidak ditemukan")
            return false
        end
        
        local index = packages:WaitForChild("_Index", 5)
        if not index then
            warn("_Index tidak ditemukan")
            return false
        end
        
        local sleitnick = index:WaitForChild("sleitnick_net@0.2.0", 5)
        if not sleitnick then
            warn("sleitnick_net@0.2.0 tidak ditemukan")
            return false
        end
        
        local net = sleitnick:WaitForChild("net", 5)
        if not net then
            warn("net tidak ditemukan")
            return false
        end
        
        -- Nama remote adalah "RF/UpdateAutoFishingState" (dengan slash)
        local updateAutoFishing = net:WaitForChild("RF/UpdateAutoFishingState", 5)
        if not updateAutoFishing then
            warn("RF/UpdateAutoFishingState tidak ditemukan")
            return false
        end
        
        if updateAutoFishing:IsA("RemoteFunction") then
            local invokeResult = updateAutoFishing:InvokeServer(state)
            print("Auto Fishing", state and "diaktifkan" or "dinonaktifkan", "- Result:", invokeResult)
            return true
        else
            warn("RF/UpdateAutoFishingState bukan RemoteFunction")
            return false
        end
    end)
    
    if not success then
        warn("Error saat mengaktifkan auto fishing:", result)
        return false
    end
    
    return result
end

-- Fungsi Start - Dipanggil saat toggle ON
function GoodPerfectionStable.Start()
    print("=== Memulai Auto Fish ===")
    GoodPerfectionStable.Enabled = true
    
    -- Tunggu sebentar untuk memastikan game sudah siap
    task.wait(0.3)
    
    -- Hapus UIGradient
    print("Menghapus UIGradient...")
    local gradientRemoved = removeUIGradient()
    print("UIGradient removed:", gradientRemoved)
    
    -- Tunggu sebentar sebelum mengaktifkan auto
    task.wait(0.5)
    
    -- Aktifkan auto fishing in-game
    print("Mengaktifkan Auto Fishing...")
    local autoEnabled = enableAutoFishing(true)
    print("Auto Fishing enabled:", autoEnabled)
    
    if autoEnabled then
        print("✓ Auto Fish berhasil diaktifkan!")
    else
        warn("✗ Auto Fish gagal diaktifkan!")
    end
    
    return autoEnabled
end

-- Fungsi Stop - Dipanggil saat toggle OFF
function GoodPerfectionStable.Stop()
    print("=== Menghentikan Auto Fish ===")
    GoodPerfectionStable.Enabled = false
    
    -- Nonaktifkan auto fishing in-game
    local success = enableAutoFishing(false)
    
    if success then
        print("✓ Auto Fish berhasil dinonaktifkan!")
    else
        warn("✗ Auto Fish gagal dinonaktifkan!")
    end
    
    return success
end

-- Fungsi untuk check status
function GoodPerfectionStable.IsEnabled()
    return GoodPerfectionStable.Enabled
end

-- Export module
return GoodPerfectionStable
