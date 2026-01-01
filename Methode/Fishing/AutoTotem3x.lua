-- AUTO TOTEM 3X (CLEAN VERSION - FOR GUI INTEGRATION)
local AutoTotem3X = {}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Net = RS.Packages["_Index"]["sleitnick_net@0.2.0"].net
local RE_EquipToolFromHotbar = Net["RE/EquipToolFromHotbar"]

-- Settings
local HOTBAR_SLOT = 2
local CLICK_COUNT = 5
local CLICK_DELAY = 0.2
local TRIANGLE_RADIUS = 58
local CENTER_OFFSET = Vector3.new(0, 0, -7.25)

local isRunning = false

-- Teleport Function
local function tp(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
        task.wait(0.5)
    end
end

-- Equip Totem
local function equipTotem()
    pcall(function()
        RE_EquipToolFromHotbar:FireServer(HOTBAR_SLOT)
    end)
    task.wait(1.5)
end

-- Auto Click
local function autoClick()
    for i = 1, CLICK_COUNT do
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
        task.wait(CLICK_DELAY)
        
        local char = LP.Character
        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
        task.wait(CLICK_DELAY)
    end
end

-- Main Function
function AutoTotem3X.Start()
    if isRunning then
        return false
    end
    
    isRunning = true
    
    task.spawn(function()
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        
        local centerPos = root.Position
        local adjustedCenter = centerPos + CENTER_OFFSET
        
        -- Calculate 3 totem positions (Triangle pattern)
        local angles = {90, 210, 330}
        local totemPositions = {}
        
        for i, angleDeg in ipairs(angles) do
            local angleRad = math.rad(angleDeg)
            local offsetX = TRIANGLE_RADIUS * math.cos(angleRad)
            local offsetZ = TRIANGLE_RADIUS * math.sin(angleRad)
            table.insert(totemPositions, adjustedCenter + Vector3.new(offsetX, 0, offsetZ))
        end
        
        -- Place totems
        for i, pos in ipairs(totemPositions) do
            if not isRunning then break end
            
            tp(pos)
            equipTotem()
            autoClick()
            task.wait(2)
        end
        
        -- Return to start position
        tp(centerPos)
        task.wait(1)
        
        isRunning = false
    end)
    
    return true
end

function AutoTotem3X.Stop()
    isRunning = false
    return true
end

function AutoTotem3X.IsRunning()
    return isRunning
end

return AutoTotem3X
