-- ============================================
-- AUTO QUEST MODULE - FISH IT (WITH AUTO TELEPORT)
-- ============================================

local AutoQuestModule = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ============================================
-- LOCATION DATA
-- ============================================

AutoQuestModule.Locations = {
    Ghostfinn = {
        ["Treasure Room"] = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
        ["Sysiphus Statue"] = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
    },
    Element = {
        ["Ancient Jungle"] = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
        ["Sacred Temple"] = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
    }
}

-- ============================================
-- AUTO TELEPORT SETTINGS
-- ============================================

AutoQuestModule.AutoTeleportActive = false
AutoQuestModule.AutoTeleportQueue = {}
AutoQuestModule.LastTeleportTime = 0
AutoQuestModule.TeleportCooldown = 2 -- Detik antara teleport

-- Quest Data
AutoQuestModule.Quests = {
    DeepSeaQuest = {
        Name = "Deep Sea Quest",
        Reward = "Ghostfinn Rod",
        Completed = false,
        LocationSet = "Ghostfinn",
        Locations = {"Treasure Room", "Sysiphus Statue"},
        Tasks = {
            {Name = "Catch 300 Rare/Epic fish in Treasure Room", Current = 0, Required = 300, Location = "Treasure Room"},
            {Name = "Catch 3 Mythic fish at Sisyphus Statue", Current = 0, Required = 3, Location = "Sysiphus Statue"},
            {Name = "Catch 1 SECRET fish at Sisyphus Statue", Current = 0, Required = 1, Location = "Sysiphus Statue"},
            {Name = "Earn 1M Coins", Current = 0, Required = 1000000}
        }
    },
    ElementQuest = {
        Name = "Element Quest",
        Reward = "Element Rod",
        Completed = false,
        LocationSet = "Element",
        Locations = {"Ancient Jungle", "Sacred Temple"},
        Tasks = {
            {Name = "Own Ghostfinn Rod", Current = 0, Required = 1},
            {Name = "Catch 1 SECRET fish at Ancient Jungle", Current = 0, Required = 1, Location = "Ancient Jungle"},
            {Name = "Catch 1 SECRET fish at Sacred Temple", Current = 0, Required = 1, Location = "Sacred Temple"},
            {Name = "Create 3 Transcended Stones", Current = 0, Required = 3}
        }
    }
}

-- ============================================
-- TELEPORT FUNCTION
-- ============================================

function AutoQuestModule.TeleportToLocation(location)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local currentTime = tick()
    if currentTime - AutoQuestModule.LastTeleportTime < AutoQuestModule.TeleportCooldown then
        return false
    end
    
    if not location then
        return false
    end
    
    local offsetPos = location + Vector3.new(0, 3, 0)
    Player.Character.HumanoidRootPart.CFrame = CFrame.new(offsetPos)
    AutoQuestModule.LastTeleportTime = currentTime
    
    return true
end

-- ============================================
-- GET INCOMPLETE TASKS
-- ============================================

function AutoQuestModule.GetIncompleteTaskLocations(questName)
    local quest = AutoQuestModule.Quests[questName]
    if not quest then return {} end
    
    local incompleteLocations = {}
    
    for _, task in ipairs(quest.Tasks) do
        if task.Location and task.Current < task.Required then
            if not table.find(incompleteLocations, task.Location) then
                table.insert(incompleteLocations, task.Location)
            end
        end
    end
    
    return incompleteLocations
end

-- ============================================
-- AUTO TELEPORT LOGIC
-- ============================================

function AutoQuestModule.StartAutoTeleport(questName)
    if AutoQuestModule.AutoTeleportActive then
        return
    end
    
    local quest = AutoQuestModule.Quests[questName]
    if not quest then
        return
    end
    
    AutoQuestModule.AutoTeleportActive = true
    
    task.spawn(function()
        while AutoQuestModule.AutoTeleportActive do
            task.wait(1)
            
            if not AutoQuestModule.AutoTeleportActive then break end
            
            AutoQuestModule.DetectQuestCompletion()
            
            if quest.Completed then
                AutoQuestModule.AutoTeleportActive = false
                break
            end
            
            local incompleteLocations = AutoQuestModule.GetIncompleteTaskLocations(questName)
            
            if #incompleteLocations == 0 then
                AutoQuestModule.AutoTeleportActive = false
                break
            end
            
            local targetLocation = incompleteLocations[1]
            local locationSet = quest.LocationSet
            local coordinates = AutoQuestModule.Locations[locationSet][targetLocation]
            
            if coordinates then
                AutoQuestModule.TeleportToLocation(coordinates)
            end
            
            task.wait(5)
        end
    end)
end

function AutoQuestModule.StopAutoTeleport()
    if not AutoQuestModule.AutoTeleportActive then
        return
    end
    
    AutoQuestModule.AutoTeleportActive = false
end

function AutoQuestModule.ToggleAutoTeleport(questName)
    if AutoQuestModule.AutoTeleportActive then
        AutoQuestModule.StopAutoTeleport()
    else
        AutoQuestModule.StartAutoTeleport(questName)
    end
end

-- ============================================
-- MAIN DETECTION FUNCTION
-- ============================================

function AutoQuestModule.DetectQuestCompletion()
    local currentRod = Player:GetAttribute("FishingRod")
    
    if currentRod then
        if currentRod:find("Ghostfinn") then
            AutoQuestModule.Quests.DeepSeaQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.DeepSeaQuest.Tasks) do
                task.Current = task.Required
            end
            AutoQuestModule.Quests.ElementQuest.Tasks[1].Current = 1
        end
        
        if currentRod:find("Element") then
            AutoQuestModule.Quests.ElementQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.ElementQuest.Tasks) do
                task.Current = task.Required
            end
            AutoQuestModule.Quests.DeepSeaQuest.Completed = true
            for i, task in ipairs(AutoQuestModule.Quests.DeepSeaQuest.Tasks) do
                task.Current = task.Required
            end
        end
    end
    
    return true
end

-- ============================================
-- GET QUEST INFO
-- ============================================

function AutoQuestModule.GetQuestInfo(questName)
    AutoQuestModule.DetectQuestCompletion()
    
    local quest = AutoQuestModule.Quests[questName]
    if not quest then return "Quest not found" end
    
    local info = quest.Name .. "\n"
    info = info .. "━━━━━━━━━━━━━━━━━━━━━━\n\n"
    
    for i, task in ipairs(quest.Tasks) do
        local status = task.Current >= task.Required and "✅" or "⏳"
        local progress = task.Current .. "/" .. task.Required
        local percentage = math.floor((task.Current / task.Required) * 100)
        
        info = info .. status .. " " .. task.Name .. "\n"
        info = info .. "   " .. progress .. " (" .. percentage .. "%)\n"
    end
    
    return info
end

-- ============================================
-- MANUAL UPDATE (BACKUP)
-- ============================================

function AutoQuestModule.SetTaskProgress(questName, taskIndex, current)
    local quest = AutoQuestModule.Quests[questName]
    if not quest or not quest.Tasks[taskIndex] then return false end
    
    quest.Tasks[taskIndex].Current = math.min(current, quest.Tasks[taskIndex].Required)
    
    local allCompleted = true
    for _, task in ipairs(quest.Tasks) do
        if task.Current < task.Required then
            allCompleted = false
            break
        end
    end
    quest.Completed = allCompleted
    
    return true
end

-- ============================================
-- MONITOR ATTRIBUTE CHANGES
-- ============================================

function AutoQuestModule.StartMonitoring()
    Player:GetAttributeChangedSignal("FishingRod"):Connect(function()
        local rod = Player:GetAttribute("FishingRod")
        AutoQuestModule.DetectQuestCompletion()
    end)
end

-- ============================================
-- DEBUG FUNCTIONS
-- ============================================

function AutoQuestModule.DebugPrintAll()
    print("\n╔════════════════════════════════════════╗")
    print("║       FISH IT QUEST STATUS             ║")
    print("╚════════════════════════════════════════╝\n")
    
    print(AutoQuestModule.GetQuestInfo("DeepSeaQuest"))
    print("\n")
    print(AutoQuestModule.GetQuestInfo("ElementQuest"))
    
    print("\n╚════════════════════════════════════════╝")
end

function AutoQuestModule.DebugCheckRod()
    local currentRod = Player:GetAttribute("FishingRod")
    print("\n🎣 CURRENT ROD CHECK:")
    print("   Rod: " .. tostring(currentRod))
    
    if currentRod then
        if currentRod:find("Ghostfinn") then
            print("   ✅ Has Ghostfinn Rod")
        end
        if currentRod:find("Element") then
            print("   ✅ Has Element Rod")
        end
    end
    print("")
end

-- ============================================
-- ALIASES
-- ============================================

AutoQuestModule.ScanQuestProgress = AutoQuestModule.DetectQuestCompletion
AutoQuestModule.ScanPlayerData = AutoQuestModule.DetectQuestCompletion
AutoQuestModule.DebugCheckItems = AutoQuestModule.DebugCheckRod
AutoQuestModule.SmartDetect = AutoQuestModule.DetectQuestCompletion

-- ============================================
-- AUTO INIT
-- ============================================

task.spawn(function()
    task.wait(2)
    AutoQuestModule.DetectQuestCompletion()
    AutoQuestModule.StartMonitoring()
end)

return AutoQuestModule
