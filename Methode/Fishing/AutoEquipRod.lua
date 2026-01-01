-- FISH IT - AUTO EQUIP ROD MODULE
-- Module for automatically equipping fishing rod

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- =====================================================
-- MODULE
-- =====================================================
local AutoEquipRod = {}
AutoEquipRod.Enabled = false
AutoEquipRod.CheckInterval = 0.5
AutoEquipRod.RodSlot = 1
AutoEquipRod.Connection = nil

-- =====================================================
-- REMOTE EVENT
-- =====================================================
local NetFolder = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local EquipToolRE = NetFolder:WaitForChild("RE/EquipToolFromHotbar")

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

local function IsHoldingRod()
    local tool = Character:FindFirstChildOfClass("Tool")
    
    if tool then
        local toolName = tool.Name:lower()
        if toolName:find("rod") or toolName:find("fishing") or toolName:find("pole") then
            return true
        end
    end
    
    return false
end

local function EquipRod()
    if not AutoEquipRod.Enabled then return end
    
    pcall(function()
        EquipToolRE:FireServer(AutoEquipRod.RodSlot)
    end)
end

local function CheckAndEquipRod()
    if not AutoEquipRod.Enabled then return end
    
    if not IsHoldingRod() then
        EquipRod()
    end
end

-- =====================================================
-- MODULE FUNCTIONS
-- =====================================================

function AutoEquipRod.Start()
    if AutoEquipRod.Connection then
        AutoEquipRod.Connection:Disconnect()
    end
    
    AutoEquipRod.Enabled = true
    local lastCheck = 0
    
    AutoEquipRod.Connection = RunService.Heartbeat:Connect(function()
        if not AutoEquipRod.Enabled then return end
        
        local currentTime = tick()
        if currentTime - lastCheck >= AutoEquipRod.CheckInterval then
            lastCheck = currentTime
            CheckAndEquipRod()
        end
    end)
end

function AutoEquipRod.Stop()
    AutoEquipRod.Enabled = false
    
    if AutoEquipRod.Connection then
        AutoEquipRod.Connection:Disconnect()
        AutoEquipRod.Connection = nil
    end
end

function AutoEquipRod.SetRodSlot(slot)
    if slot >= 1 and slot <= 9 then
        AutoEquipRod.RodSlot = slot
    end
end

function AutoEquipRod.IsHoldingRod()
    return IsHoldingRod()
end

-- =====================================================
-- CHARACTER RESPAWN HANDLING
-- =====================================================
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    
    if AutoEquipRod.Enabled then
        task.wait(2)
        CheckAndEquipRod()
    end
end)

return AutoEquipRod
