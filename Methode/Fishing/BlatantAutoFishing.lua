-- BlatantAutoFishing.lua
-- Mode Blatant: Ultra fast fishing based on working Instant2X

local BlatantAutoFishing = {}
BlatantAutoFishing.Enabled = false
BlatantAutoFishing.Settings = {
    FishingDelay = 0.01,      -- Delay setelah catch (blatant: 0.01s)
    CancelDelay = 0.01,       -- Delay cancel (blatant: 0.01s)
    HookDetectionDelay = 0.01, -- Delay deteksi hook (blatant: 0.01s)
    RequestMinigameDelay = 0.01, -- Delay request minigame (blatant: 0.01s)
    TimeoutDelay = 0.5,       -- Timeout fallback (blatant: 0.5s)
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Network events
local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")

-- Variables
local WaitingHook = false
local CurrentCycle = 0
local TotalFish = 0
local MinigameConnection = nil
local FishCaughtConnection = nil

local function log(msg)
    print("[Blatant] " .. msg)
end

-- Fungsi Cast
local function Cast()
    if not BlatantAutoFishing.Enabled or WaitingHook then return end
    
    CurrentCycle = CurrentCycle + 1
    
    pcall(function()
        -- 1. Charge fishing rod
        RF_ChargeFishingRod:InvokeServer({[22] = tick()})
        log("🎣 Cast #" .. CurrentCycle)
        
        -- 2. Delay minimal lalu request minigame
        task.wait(BlatantAutoFishing.Settings.RequestMinigameDelay)
        RF_RequestMinigame:InvokeServer(9, 0, tick())
        log("🎯 Minigame requested, waiting hook...")
        
        WaitingHook = true
        
        -- 3. Timeout fallback (jika hook tidak terdeteksi)
        task.delay(BlatantAutoFishing.Settings.TimeoutDelay, function()
            if WaitingHook and BlatantAutoFishing.Enabled then
                WaitingHook = false
                
                -- Force complete
                RE_FishingCompleted:FireServer()
                log("⏱️ Timeout - Force complete")
                
                task.wait(BlatantAutoFishing.Settings.CancelDelay)
                pcall(function() RF_CancelFishingInputs:InvokeServer() end)
                
                task.wait(BlatantAutoFishing.Settings.FishingDelay)
                if BlatantAutoFishing.Enabled then Cast() end
            end
        end)
    end)
end

-- Setup event listeners
local function setupListeners()
    -- Listen untuk MinigameChanged (hook detection)
    if MinigameConnection then MinigameConnection:Disconnect() end
    
    MinigameConnection = RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if not BlatantAutoFishing.Enabled then return end
        if not WaitingHook then return end
        
        -- Deteksi hook state
        if typeof(state) == "string" and string.find(string.lower(state), "hook") then
            WaitingHook = false
            
            -- Delay minimal untuk hook detection
            task.wait(BlatantAutoFishing.Settings.HookDetectionDelay)
            
            -- Complete fishing
            RE_FishingCompleted:FireServer()
            log("✅ Hook detected - Fish caught!")
            
            task.wait(BlatantAutoFishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(BlatantAutoFishing.Settings.FishingDelay)
            if BlatantAutoFishing.Enabled then Cast() end
        end
    end)
    
    -- Listen untuk FishCaught
    if FishCaughtConnection then FishCaughtConnection:Disconnect() end
    
    FishCaughtConnection = RE_FishCaught.OnClientEvent:Connect(function(fishName, data)
        if not BlatantAutoFishing.Enabled then return end
        
        WaitingHook = false
        TotalFish = TotalFish + 1
        
        log("🐟 Fish caught: " .. tostring(fishName) .. " | Total: " .. TotalFish)
        
        task.wait(BlatantAutoFishing.Settings.CancelDelay)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        
        task.wait(BlatantAutoFishing.Settings.FishingDelay)
        if BlatantAutoFishing.Enabled then Cast() end
    end)
end

-- Fungsi Start
function BlatantAutoFishing.Start()
    if BlatantAutoFishing.Enabled then
        warn("⚠️ Blatant Mode sudah aktif!")
        return
    end
    
    print("="..string.rep("=", 50))
    print("🔥 BLATANT MODE AKTIF!")
    print("="..string.rep("=", 50))
    print("⚡ Fishing Delay:", BlatantAutoFishing.Settings.FishingDelay, "s")
    print("⚡ Cancel Delay:", BlatantAutoFishing.Settings.CancelDelay, "s")
    print("⚡ Hook Detection Delay:", BlatantAutoFishing.Settings.HookDetectionDelay, "s")
    print("⚡ Request Minigame Delay:", BlatantAutoFishing.Settings.RequestMinigameDelay, "s")
    print("⚡ Timeout Delay:", BlatantAutoFishing.Settings.TimeoutDelay, "s")
    print("="..string.rep("=", 50))
    print("⚠️ WARNING: Ultra fast mode - HIGH BAN RISK!")
    print("="..string.rep("=", 50))
    
    BlatantAutoFishing.Enabled = true
    WaitingHook = false
    CurrentCycle = 0
    TotalFish = 0
    
    -- Setup listeners
    setupListeners()
    log("✅ Event listeners installed")
    
    -- Start fishing
    task.wait(0.5)
    Cast()
    
    log("✅ Blatant fishing started!")
end

-- Fungsi Stop
function BlatantAutoFishing.Stop()
    if not BlatantAutoFishing.Enabled then
        warn("⚠️ Blatant Mode sudah tidak aktif!")
        return
    end
    
    BlatantAutoFishing.Enabled = false
    WaitingHook = false
    
    -- Disconnect listeners
    if MinigameConnection then
        MinigameConnection:Disconnect()
        MinigameConnection = nil
    end
    
    if FishCaughtConnection then
        FishCaughtConnection:Disconnect()
        FishCaughtConnection = nil
    end
    
    -- Cancel current fishing
    pcall(function() RF_CancelFishingInputs:InvokeServer() end)
    
    log("🔴 Blatant Mode stopped | Total fish: " .. TotalFish)
end

-- Handle respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    if BlatantAutoFishing.Enabled then
        task.wait(2)
        
        log("🔄 Character respawned, restarting...")
        
        WaitingHook = false
        
        -- Reconnect listeners
        if MinigameConnection then MinigameConnection:Disconnect() end
        if FishCaughtConnection then FishCaughtConnection:Disconnect() end
        
        setupListeners()
        
        task.wait(1)
        Cast()
    end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        if BlatantAutoFishing.Enabled then
            BlatantAutoFishing.Stop()
        end
    end
end)

return BlatantAutoFishing
