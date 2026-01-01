-- TRIPLE SKIN ANIMATION SWITCHER V2
-- File: SkinAnimation.lua
-- Upload ke: https://raw.githubusercontent.com/habibihidayat/project-k/refs/heads/main/FungsiKeaby/SkinAnimation.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local SKINS = {
    ["Eclipse"] = {
        ["EquipIdle"] = {
            id = "rbxassetid://103641983335689",
            speed = 1.0,
            priority = Enum.AnimationPriority.Core,
            looped = true,
        },
        ["RodThrow"] = {
            id = "rbxassetid://82600073500966",
            speed = 1.4,
            priority = Enum.AnimationPriority.Action,
            looped = false,
        },
        ["FishCaught"] = {
            id = "rbxassetid://107940819382815",
            speed = 1.0,
            priority = Enum.AnimationPriority.Action4,
            looped = false,
        },
        ["ReelingIdle"] = {
            id = "rbxassetid://115229621326605",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["ReelStart"] = {
            id = "rbxassetid://115229621326605",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = false,
        },
        ["ReelIntermission"] = {
            id = "rbxassetid://115229621326605",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["StartRodCharge"] = {
            id = "rbxassetid://115229621326605",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
    },
    ["HolyTrident"] = {
        ["EquipIdle"] = {
            id = "rbxassetid://83219020397849",
            speed = 1.0,
            priority = Enum.AnimationPriority.Core,
            looped = true,
        },
        ["RodThrow"] = {
            id = "rbxassetid://114917462794864",
            speed = 1.3,
            priority = Enum.AnimationPriority.Action,
            looped = false,
        },
        ["FishCaught"] = {
            id = "rbxassetid://128167068291703",
            speed = 1.2,
            priority = Enum.AnimationPriority.Action4,
            looped = false,
        },
        ["ReelingIdle"] = {
            id = "rbxassetid://126831815839724",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["ReelStart"] = {
            id = "rbxassetid://126831815839724",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["ReelIntermission"] = {
            id = "rbxassetid://126831815839724",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["StartRodCharge"] = {
            id = "rbxassetid://83219020397849",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
    },
    ["SoulScythe"] = {
        ["EquipIdle"] = {
            id = "rbxassetid://84686809448947",
            speed = 1.0,
            priority = Enum.AnimationPriority.Core,
            looped = true,
        },
        ["RodThrow"] = {
            id = "rbxassetid://104946400643250",
            speed = 1.0,
            priority = Enum.AnimationPriority.Action,
            looped = false,
        },
        ["FishCaught"] = {
            id = "rbxassetid://82259219343456",
            speed = 1.2,
            priority = Enum.AnimationPriority.Action4,
            looped = false,
        },
        ["ReelingIdle"] = {
            id = "rbxassetid://95453600470089",
            speed = 1.0,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["ReelStart"] = {
            id = "rbxassetid://137684649541594",
            speed = 1.2,
            priority = Enum.AnimationPriority.Idle,
            looped = false,
        },
        ["ReelIntermission"] = {
            id = "rbxassetid://139621583239992",
            speed = 1.2,
            priority = Enum.AnimationPriority.Idle,
            looped = true,
        },
        ["StartRodCharge"] = {
            id = "rbxassetid://117668204114399",
            speed = 1.4,
            priority = Enum.AnimationPriority.Idle,
            looped = false,
        },
    },
}

local ANIM_ID_MAP = {
    ["96586569072385"] = "EquipIdle",
    ["139622307103608"] = "StartRodCharge",
    ["92624107165273"] = "RodThrow",
    ["136614469321844"] = "ReelStart",
    ["134965425664034"] = "ReelingIdle",
    ["114959536562596"] = "ReelIntermission",
    ["117319000848286"] = "FishCaught",
    ["137429009359442"] = "StartRodCharge",
}

local currentSkin = "Eclipse"
local isEnabled = false
local connections = {}
local replacedTracks = {}
local preloadedAnimations = {}

local function getAnimType(animId)
    local numeric = animId:match("(%d+)")
    return numeric and ANIM_ID_MAP[numeric]
end

local function getCurrentSkinConfig()
    return SKINS[currentSkin]
end

local function getAnimator()
    local char = LP.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    return humanoid:FindFirstChildOfClass("Animator")
end

local function getHumanoid()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function preloadSkinAnimations()
    local humanoid = getHumanoid()
    if not humanoid then return false end
    
    local skinConfig = getCurrentSkinConfig()
    preloadedAnimations = {}
    
    for animName, config in pairs(skinConfig) do
        local anim = Instance.new("Animation")
        anim.AnimationId = config.id
        anim.Name = currentSkin .. "_" .. animName
        
        local success, track = pcall(function()
            return humanoid:LoadAnimation(anim)
        end)
        
        if success and track then
            track.Priority = config.priority
            track.Looped = config.looped
            
            preloadedAnimations[animName] = {
                track = track,
                config = config,
                animation = anim,
            }
        end
    end
    
    return true
end

local function replaceTrackImproved(originalTrack)
    if not originalTrack or not originalTrack.Animation then 
        return false
    end
    
    local animId = originalTrack.Animation.AnimationId
    local animType = getAnimType(animId)
    
    if not animType then 
        return false
    end
    
    local trackKey = tostring(originalTrack)
    if replacedTracks[trackKey] then 
        return false
    end
    
    local preloaded = preloadedAnimations[animType]
    if not preloaded then 
        return false
    end
    
    local config = preloaded.config
    local newTrack = preloaded.track
    
    local wasPlaying = originalTrack.IsPlaying
    local timePos = originalTrack.TimePosition
    local weight = originalTrack.WeightCurrent
    
    if wasPlaying then
        originalTrack:Stop(0)
    end
    
    task.wait(0.02)
    
    if wasPlaying then
        newTrack:Play(0, weight, config.speed)
        pcall(function()
            newTrack.TimePosition = timePos
        end)
    end
    
    replacedTracks[trackKey] = true
    
    local cleanupConn
    cleanupConn = newTrack.Ended:Connect(function()
        replacedTracks[trackKey] = nil
        if cleanupConn then
            cleanupConn:Disconnect()
        end
    end)
    
    return true
end

local function monitorAnimations()
    local animator = getAnimator()
    if not animator then return end
    
    local tracks = animator:GetPlayingAnimationTracks()
    
    for _, track in ipairs(tracks) do
        pcall(function()
            replaceTrackImproved(track)
        end)
    end
end

local function setupAnimatorHook()
    local animator = getAnimator()
    if not animator then return end
    
    local conn = animator.AnimationPlayed:Connect(function(track)
        if not isEnabled then return end
        task.wait(0.01)
        pcall(function()
            replaceTrackImproved(track)
        end)
    end)
    
    table.insert(connections, conn)
end

local function detectRodEquip()
    local char = LP.Character
    if not char then return end
    
    local conn = char.ChildAdded:Connect(function(child)
        if not isEnabled then return end
        if child:IsA("Tool") and child.Name:find("Rod") then
            task.wait(0.5)
            replacedTracks = {}
            monitorAnimations()
        end
    end)
    
    table.insert(connections, conn)
end

local function SwitchSkin(skinName)
    if not SKINS[skinName] then
        return false
    end
    
    currentSkin = skinName
    replacedTracks = {}
    
    for _, data in pairs(preloadedAnimations) do
        pcall(function()
            if data.track then
                data.track:Stop()
            end
            if data.animation then
                data.animation:Destroy()
            end
        end)
    end
    
    preloadSkinAnimations()
    
    if isEnabled then
        task.wait(0.1)
        monitorAnimations()
    end
    
    return true
end

local function Enable()
    if isEnabled then
        return false
    end
    
    isEnabled = true
    replacedTracks = {}
    
    preloadSkinAnimations()
    setupAnimatorHook()
    detectRodEquip()
    
    local monitorConn = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        if tick() % 0.1 < 0.016 then
            pcall(monitorAnimations)
        end
    end)
    table.insert(connections, monitorConn)
    
    local respawnConn = LP.CharacterAdded:Connect(function()
        if not isEnabled then return end
        task.wait(2)
        replacedTracks = {}
        preloadSkinAnimations()
        setupAnimatorHook()
        detectRodEquip()
    end)
    table.insert(connections, respawnConn)
    
    task.wait(0.5)
    monitorAnimations()
    
    return true
end

local function Disable()
    if not isEnabled then
        return false
    end
    
    isEnabled = false
    replacedTracks = {}
    
    for _, data in pairs(preloadedAnimations) do
        pcall(function()
            if data.track then
                data.track:Stop()
            end
            if data.animation then
                data.animation:Destroy()
            end
        end)
    end
    preloadedAnimations = {}
    
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    
    return true
end

-- Return module
return {
    Enable = Enable,
    Disable = Disable,
    SwitchSkin = SwitchSkin,
    IsEnabled = function() return isEnabled end,
    GetCurrentSkin = function() return currentSkin end,
}
