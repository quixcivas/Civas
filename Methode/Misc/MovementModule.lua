local MovementModule = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Settings
MovementModule.Settings = {
    SprintSpeed = 50,
    DefaultSpeed = 16,
    SprintEnabled = false,
    InfiniteJumpEnabled = false
}

-- Internal State
local connections = {}
local jumpConnection = nil
local sprintConnection = nil

local function cleanup()
    for _, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
end

local function maintainSprintSpeed()
    if sprintConnection then
        sprintConnection:Disconnect()
    end
    
    -- Loop yang terus memantau dan mempertahankan sprint speed
    sprintConnection = RunService.Heartbeat:Connect(function()
        if MovementModule.Settings.SprintEnabled and humanoid and humanoid.WalkSpeed ~= MovementModule.Settings.SprintSpeed then
            humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        end
    end)
end

function MovementModule.SetSprintSpeed(speed)
    MovementModule.Settings.SprintSpeed = math.clamp(speed, 16, 200)
    
    if MovementModule.Settings.SprintEnabled and humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
end

function MovementModule.EnableSprint()
    if MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = true
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
    
    -- Aktifkan loop pemantau sprint speed
    maintainSprintSpeed()
    
    return true
end

function MovementModule.DisableSprint()
    if not MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = false
    
    -- Matikan loop pemantau
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.DefaultSpeed
    end
    
    return true
end

function MovementModule.IsSprintEnabled()
    return MovementModule.Settings.SprintEnabled
end

function MovementModule.GetSprintSpeed()
    return MovementModule.Settings.SprintSpeed
end

local function enableInfiniteJump()
    if jumpConnection then
        jumpConnection:Disconnect()
    end
    
    jumpConnection = UserInputService.JumpRequest:Connect(function()
        if MovementModule.Settings.InfiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function MovementModule.EnableInfiniteJump()
    if MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = true
    enableInfiniteJump()
    
    return true
end

function MovementModule.DisableInfiniteJump()
    if not MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = false
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    return true
end

function MovementModule.IsInfiniteJumpEnabled()
    return MovementModule.Settings.InfiniteJumpEnabled
end

table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    
    -- Re-apply sprint if enabled
    if MovementModule.Settings.SprintEnabled then
        task.wait(0.1)
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        maintainSprintSpeed() -- Aktifkan kembali loop pemantau
    end
    
    -- Re-apply infinite jump if enabled
    if MovementModule.Settings.InfiniteJumpEnabled then
        enableInfiniteJump()
    end
end))

function MovementModule.Start()
    MovementModule.Settings.SprintEnabled = false
    MovementModule.Settings.InfiniteJumpEnabled = false
    enableInfiniteJump()
    return true
end

function MovementModule.Stop()
    MovementModule.DisableSprint()
    MovementModule.DisableInfiniteJump()
    cleanup()
    return true
end

-- Initialize
MovementModule.Start()

return MovementModule
