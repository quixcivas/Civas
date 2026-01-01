-- ⚠️ BLATANT V2 AUTO FISHING - CLEAN VERSION
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

-- Module table
local BlatantV2 = {}
BlatantV2.Active = false

-- Settings
BlatantV2.Settings = {
    ChargeDelay = 0.007,
    CompleteDelay = 0.001,
    CancelDelay = 0.001
}

----------------------------------------------------------------
-- CORE FISHING FUNCTIONS
----------------------------------------------------------------

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

local function ultraSpamLoop()
    while BlatantV2.Active do
        local startTime = tick()
        
        safeFire(function()
            RF_ChargeFishingRod:InvokeServer({[1] = startTime})
        end)
        
        task.wait(BlatantV2.Settings.ChargeDelay)
        
        local releaseTime = tick()
        safeFire(function()
            RF_RequestMinigame:InvokeServer(1, 0, releaseTime)
        end)
        
        task.wait(BlatantV2.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        task.wait(BlatantV2.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end
end

RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV2.Active then return end
    
    task.spawn(function()
        task.wait(BlatantV2.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        task.wait(BlatantV2.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end)
end)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

-- Update Settings function
function BlatantV2.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay ~= nil then
        BlatantV2.Settings.CompleteDelay = completeDelay
    end
    
    if cancelDelay ~= nil then
        BlatantV2.Settings.CancelDelay = cancelDelay
    end
end

-- Start function
function BlatantV2.Start()
    if BlatantV2.Active then 
        return
    end
    
    BlatantV2.Active = true
    task.spawn(ultraSpamLoop)
end

-- Stop function
function BlatantV2.Stop()
    if not BlatantV2.Active then 
        return
    end
    
    BlatantV2.Active = false
    
    safeFire(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    
    safeFire(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
end

return BlatantV2
