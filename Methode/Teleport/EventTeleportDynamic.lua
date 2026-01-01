-- EventTeleportDynamic.lua (ULTRA OPTIMIZED - ZERO STUTTERING - NO SPAM)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local module = {}

-- =======================
-- Event coordinate database
-- =======================
module.Events = {
    ["Shark Hunt"] = {
        Vector3.new(1.64999, -1.3500, 2095.72),
        Vector3.new(1369.94, -1.3500, 930.125),
        Vector3.new(-1585.5, -1.3500, 1242.87),
        Vector3.new(-1896.8, -1.3500, 2634.37),
    },

    ["Worm Hunt"] = {
        Vector3.new(2190.85, -1.3999, 97.5749),
        Vector3.new(-2450.6, -1.3999, 139.731),
        Vector3.new(-267.47, -1.3999, 5188.53),
    },

    ["Megalodon Hunt"] = {
        Vector3.new(-1076.3, -1.3999, 1676.19),
        Vector3.new(-1191.8, -1.3999, 3597.30),
        Vector3.new(412.700, -1.3999, 4134.39),
    },

    ["Ghost Shark Hunt"] = {
        Vector3.new(489.558, -1.3500, 25.4060),
        Vector3.new(-1358.2, -1.3500, 4100.55),
        Vector3.new(627.859, -1.3500, 3798.08),
    },

    ["Treasure Hunt"] = nil,
}

-- =======================
-- Config
-- =======================
module.SearchRadius = 25
module.TeleportCheckInterval = 5.0
module.HeightOffset = 15
module.SafeZoneRadius = 50
module.UseSmartReteleport = true
module.RequireEventActive = true
module.WaitForEventTimeout = 300
module.DebugMode = false  -- ✅ Set true untuk enable logging

-- ✅ FILTER SETTINGS
module.EventObjectMinSize = 5
module.EventObjectNames = {
    "MainBody", "Shark", "Worm", "Megalodon", "Ghost"
}
module.UseNameFilter = false

-- =======================
-- Internal state
-- =======================
local running = false
local currentEventName = nil
local lastTeleportPosition = nil
local eventIsActive = false
local cachedEventPosition = nil
local workspaceChildAddedConn = nil
local workspaceChildRemovedConn = nil

-- ✅ DEBOUNCING
local lastEventCheckTime = 0
local EVENT_CHECK_COOLDOWN = 2

-- ✅ TRACKED OBJECTS
local trackedEventObjects = {}

-- ✅ LOGGING UTILITY
local function log(message)
    if module.DebugMode then
        print("[EventTP]", message)
    end
end

-- ================
-- Utilities
-- ================
local function safeCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function applyHeightOffset(pos)
    if not pos then return nil end
    return Vector3.new(pos.X, pos.Y + module.HeightOffset, pos.Z)
end

local function isInSafeZone()
    if not module.UseSmartReteleport or not lastTeleportPosition then
        return false
    end
    
    local hrp = getHRP()
    if not hrp then return false end
    
    return (hrp.Position - lastTeleportPosition).Magnitude <= module.SafeZoneRadius
end

-- ✅ FILTER: Check if object is valid
local function isValidEventObject(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    
    local size = part.Size
    if size.Magnitude < module.EventObjectMinSize then
        return false
    end
    
    if module.UseNameFilter then
        local isValidName = false
        for _, validName in ipairs(module.EventObjectNames) do
            if string.find(part.Name, validName) then
                isValidName = true
                break
            end
        end
        if not isValidName then
            return false
        end
    end
    
    return true
end

-- ✅ OPTIMIZED: Spatial query ONLY
local function findNearbyObjectFast(centerPos, radius)
    if not Workspace.GetPartBoundsInBox then
        return nil
    end
    
    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInBox(
            CFrame.new(centerPos), 
            Vector3.new(radius*2, radius*2, radius*2)
        )
    end)
    
    if not ok or not parts then return nil end
    
    local bestPart = nil
    local bestDist = math.huge
    
    for _, p in ipairs(parts) do
        if isValidEventObject(p) then
            local d = (p.Position - centerPos).Magnitude
            if d <= radius and d < bestDist then
                bestDist = d
                bestPart = p
            end
        end
    end
    
    return bestPart
end

-- ✅ ASYNC scanning with yielding
local function scanEventCoordsAsync(eventName)
    local coords = module.Events[eventName]
    if not coords or #coords == 0 then return nil end
    
    for i, coord in ipairs(coords) do
        local part = findNearbyObjectFast(coord, module.SearchRadius)
        
        if part then
            local pos = applyHeightOffset(part.Position)
            cachedEventPosition = pos
            trackedEventObjects[part] = true
            return pos
        end
        
        if i % 2 == 0 then
            task.wait()
        end
    end
    
    return nil
end

-- ✅ SMART EVENT LISTENERS with debouncing
local function setupEventListeners(eventName)
    local coords = module.Events[eventName]
    if not coords then return end
    
    -- ✅ DEBOUNCED ChildAdded
    workspaceChildAddedConn = Workspace.ChildAdded:Connect(function(child)
        if not running then return end
        
        local now = tick()
        if now - lastEventCheckTime < EVENT_CHECK_COOLDOWN then
            return
        end
        
        task.spawn(function()
            task.wait(0.5)
            
            -- Check parent first
            if child:IsA("BasePart") and isValidEventObject(child) then
                for _, coord in ipairs(coords) do
                    local dist = (child.Position - coord).Magnitude
                    if dist <= module.SearchRadius then
                        log("Event spawned: " .. child.Name)
                        cachedEventPosition = applyHeightOffset(child.Position)
                        eventIsActive = true
                        trackedEventObjects[child] = true
                        lastEventCheckTime = tick()
                        return
                    end
                end
            end
            
            -- Check descendants only if parent is nearby
            local shouldCheckDescendants = false
            for _, coord in ipairs(coords) do
                if child:IsA("Model") and child.PrimaryPart then
                    local dist = (child.PrimaryPart.Position - coord).Magnitude
                    if dist <= module.SearchRadius * 2 then
                        shouldCheckDescendants = true
                        break
                    end
                end
            end
            
            if shouldCheckDescendants then
                for _, desc in ipairs(child:GetDescendants()) do
                    if isValidEventObject(desc) then
                        for _, coord in ipairs(coords) do
                            local dist = (desc.Position - coord).Magnitude
                            if dist <= module.SearchRadius then
                                log("Event spawned: " .. desc.Name)
                                cachedEventPosition = applyHeightOffset(desc.Position)
                                eventIsActive = true
                                trackedEventObjects[desc] = true
                                lastEventCheckTime = tick()
                                return
                            end
                        end
                    end
                end
            end
        end)
    end)
    
    -- ✅ SMART ChildRemoved: Only process tracked objects
    workspaceChildRemovedConn = Workspace.ChildRemoved:Connect(function(child)
        if not running then return end
        
        local isTrackedObject = false
        
        if trackedEventObjects[child] then
            isTrackedObject = true
            trackedEventObjects[child] = nil
        else
            for _, desc in ipairs(child:GetDescendants()) do
                if trackedEventObjects[desc] then
                    isTrackedObject = true
                    trackedEventObjects[desc] = nil
                end
            end
        end
        
        if isTrackedObject then
            task.spawn(function()
                task.wait(2)
                
                local now = tick()
                if now - lastEventCheckTime < EVENT_CHECK_COOLDOWN then
                    return
                end
                
                local pos = scanEventCoordsAsync(eventName)
                if not pos then
                    log("Event ended")
                    eventIsActive = false
                    cachedEventPosition = nil
                end
                
                lastEventCheckTime = now
            end)
        end
    end)
end

local function cleanupEventListeners()
    if workspaceChildAddedConn then
        workspaceChildAddedConn:Disconnect()
        workspaceChildAddedConn = nil
    end
    if workspaceChildRemovedConn then
        workspaceChildRemovedConn:Disconnect()
        workspaceChildRemovedConn = nil
    end
    
    trackedEventObjects = {}
end

local function resolveActivePosition()
    if cachedEventPosition and eventIsActive then
        return cachedEventPosition, true
    end
    return nil, false
end

local function doTeleportToPos(pos)
    if not pos then return false end
    local char = safeCharacter()
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    pcall(function()
        if char.PrimaryPart then
            char:PivotTo(CFrame.new(pos))
        else
            hrp.CFrame = CFrame.new(pos)
        end
    end)
    
    lastTeleportPosition = pos
    return true
end

function module.TeleportNow(eventName)
    if not eventName then return false end
    
    local pos, isActive = resolveActivePosition()
    
    if not pos then
        if module.RequireEventActive then
            log("Event not active")
        end
        return false
    end

    return doTeleportToPos(pos)
end

local function waitForEventActive(eventName, timeout)
    local startTime = tick()
    
    log("Waiting for event...")
    
    while tick() - startTime < timeout do
        local pos = scanEventCoordsAsync(eventName)
        
        if pos then
            log("Event detected!")
            eventIsActive = true
            cachedEventPosition = pos
            return pos
        end
        
        task.wait(3)
    end
    
    log("Timeout waiting for event")
    return nil
end

function module.Start(eventName)
    if running then return false end
    if not eventName then return false end
    if not module.Events[eventName] then return false end

    running = true
    currentEventName = eventName
    lastTeleportPosition = nil
    eventIsActive = false
    cachedEventPosition = nil
    lastEventCheckTime = 0
    trackedEventObjects = {}

    setupEventListeners(eventName)

    task.spawn(function()
        if module.RequireEventActive then
            local initialPos = waitForEventActive(currentEventName, module.WaitForEventTimeout)
            
            if not initialPos then
                log("Event did not start, stopping")
                module.Stop()
                return
            end
            
            doTeleportToPos(initialPos)
        end
        
        while running do
            if not isInSafeZone() then
                local pos, isActive = resolveActivePosition()
                
                if pos and isActive then
                    doTeleportToPos(pos)
                else
                    log("Re-scanning event position...")
                    local newPos = scanEventCoordsAsync(currentEventName)
                    if newPos then
                        cachedEventPosition = newPos
                        eventIsActive = true
                        doTeleportToPos(newPos)
                    else
                        eventIsActive = false
                        log("Event not found")
                    end
                end
            end

            task.wait(module.TeleportCheckInterval)
        end
    end)

    return true
end

function module.Stop()
    running = false
    currentEventName = nil
    lastTeleportPosition = nil
    eventIsActive = false
    cachedEventPosition = nil
    cleanupEventListeners()
    return true
end

function module.GetEventNames()
    local list = {}
    for name, _ in pairs(module.Events) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

function module.HasCoords(eventName)
    local v = module.Events[eventName]
    return v ~= nil and #v > 0
end

function module.SetHeightOffset(offset)
    module.HeightOffset = offset or 15
    log("Height offset: " .. module.HeightOffset)
end

function module.SetSafeZoneRadius(radius)
    module.SafeZoneRadius = radius or 50
    log("Safe zone radius: " .. module.SafeZoneRadius)
end

function module.SetSmartReteleport(enabled)
    module.UseSmartReteleport = enabled
    log("Smart re-teleport: " .. (enabled and "ON" or "OFF"))
end

function module.SetRequireEventActive(enabled)
    module.RequireEventActive = enabled
    log("Require event active: " .. (enabled and "ON" or "OFF"))
end

function module.SetWaitTimeout(seconds)
    module.WaitForEventTimeout = seconds or 300
    log("Wait timeout: " .. module.WaitForEventTimeout .. " sec")
end

function module.SetTeleportCheckInterval(seconds)
    module.TeleportCheckInterval = math.max(3, seconds or 5)
    log("Teleport check interval: " .. module.TeleportCheckInterval .. " sec")
end

function module.SetEventObjectMinSize(size)
    module.EventObjectMinSize = size or 5
    log("Min object size: " .. module.EventObjectMinSize)
end

function module.SetUseNameFilter(enabled)
    module.UseNameFilter = enabled
    log("Name filter: " .. (enabled and "ON" or "OFF"))
end

function module.SetDebugMode(enabled)
    module.DebugMode = enabled
    log("Debug mode: " .. (enabled and "ON" or "OFF"))
end

function module.IsEventActive()
    return eventIsActive
end

function module.RefreshEventPosition()
    if not running or not currentEventName then return false end
    
    log("Manually refreshing event position...")
    task.spawn(function()
        local pos = scanEventCoordsAsync(currentEventName)
        if pos then
            cachedEventPosition = pos
            eventIsActive = true
            log("Position refreshed")
        else
            eventIsActive = false
            cachedEventPosition = nil
            log("Event not found")
        end
    end)
    
    return true
end

return module
