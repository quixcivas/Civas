-- ⚡ ULTRA BLATANT AUTO FISHING MODULE - CLEAN VERSION
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Network initialization
local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
    
local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")

-- Module
local UltraBlatant = {}
UltraBlatant.Active = false

UltraBlatant.Settings = {
    CompleteDelay = 0.73,
    CancelDelay = 0.3,
    ReCastDelay = 0.001
}

-- State tracking
local FishingState = {
    lastCompleteTime = 0,
    completeCooldown = 0.4
}

----------------------------------------------------------------
-- CORE FUNCTIONS
----------------------------------------------------------------

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

local function protectedComplete()
    local now = tick()
    
    if now - FishingState.lastCompleteTime < FishingState.completeCooldown then
        return false
    end
    
    FishingState.lastCompleteTime = now
    safeFire(function()
        RE_FishingCompleted:FireServer()
    end)
    
    return true
end

local function performCast()
    local now = tick()
    
    safeFire(function()
        RF_ChargeFishingRod:InvokeServer({[1] = now})
    end)
    safeFire(function()
        RF_RequestMinigame:InvokeServer(1, 0, now)
    end)
end

local function fishingLoop()
    while UltraBlatant.Active do
        performCast()
        
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        if UltraBlatant.Active then
            protectedComplete()
        end
        
        task.wait(UltraBlatant.Settings.CancelDelay)
        
        if UltraBlatant.Active then
            safeFire(function()
                RF_CancelFishingInputs:InvokeServer()
            end)
        end
        
        task.wait(UltraBlatant.Settings.ReCastDelay)
    end
end

-- Backup listener
local lastEventTime = 0

RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not UltraBlatant.Active then return end
    
    local now = tick()
    
    if now - lastEventTime < 0.2 then
        return
    end
    lastEventTime = now
    
    if now - FishingState.lastCompleteTime < 0.3 then
        return
    end
    
    task.spawn(function()
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        if protectedComplete() then
            task.wait(UltraBlatant.Settings.CancelDelay)
            safeFire(function()
                RF_CancelFishingInputs:InvokeServer()
            end)
        end
    end)
end)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function UltraBlatant.UpdateSettings(completeDelay, cancelDelay, reCastDelay)
    if completeDelay ~= nil then
        UltraBlatant.Settings.CompleteDelay = completeDelay
    end
    
    if cancelDelay ~= nil then
        UltraBlatant.Settings.CancelDelay = cancelDelay
    end
    
    if reCastDelay ~= nil then
        UltraBlatant.Settings.ReCastDelay = reCastDelay
    end
end

function UltraBlatant.Start()
    if UltraBlatant.Active then 
        return
    end
    
    UltraBlatant.Active = true
    FishingState.lastCompleteTime = 0
    
    safeFire(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    task.spawn(fishingLoop)
end

function UltraBlatant.Stop()
    if not UltraBlatant.Active then 
        return
    end
    
    UltraBlatant.Active = false
    
    safeFire(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    
    safeFire(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
end

return UltraBlatant
