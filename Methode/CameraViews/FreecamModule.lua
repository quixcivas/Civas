-- ============================================
-- FREECAM MODULE - UNIVERSAL PC & MOBILE
-- ============================================
-- File: FreecamModule.lua

local FreecamModule = {}

-- Services
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Variables
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

local freecam = false
local camPos = Vector3.new()
local camRot = Vector3.new()
local speed = 50
local sensitivity = 0.3
local hiddenGuis = {}

-- Mobile detection
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- Mobile joystick variables
local mobileJoystickInput = Vector3.new(0, 0, 0)
local joystickConnections = {}
local dynamicThumbstick = nil
local thumbstickCenter = Vector2.new(0, 0)
local thumbstickRadius = 60

-- Touch input for camera rotation
local cameraTouch = nil
local cameraTouchStartPos = nil
local joystickTouch = nil

-- Connections
local renderConnection = nil
local inputChangedConnection = nil
local inputEndedConnection = nil
local inputBeganConnection = nil

-- Character references
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function LockCharacter(state)
    if not Humanoid then return end
    
    if state then
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        Humanoid.AutoRotate = false
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = true
        end
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
        Humanoid.AutoRotate = true
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = false
        end
    end
end

local function HideAllGuis()
    hiddenGuis = {}
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            if mainGuiName and gui.Name == mainGuiName then
                continue
            end
            
            local guiName = gui.Name:lower()
            if guiName:find("main") or guiName:find("hub") or guiName:find("menu") or guiName:find("ui") then
                continue
            end
            
            table.insert(hiddenGuis, gui)
            gui.Enabled = false
        end
    end
end

local function ShowAllGuis()
    for _, gui in pairs(hiddenGuis) do
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
    
    hiddenGuis = {}
end

local function GetMovement()
    local move = Vector3.zero
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, -1) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then 
        move = move + Vector3.new(0, 1, 0) 
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) then 
        move = move + Vector3.new(0, -1, 0) 
    end
    
    if isMobile then
        move = move + mobileJoystickInput
    end
    
    return move
end

-- ============================================
-- MOBILE JOYSTICK DETECTION
-- ============================================

local function DetectDynamicThumbstick()
    if not isMobile then return end
    
    local function searchForThumbstick(parent, depth)
        depth = depth or 0
        if depth > 10 then return end
        
        for _, child in pairs(parent:GetChildren()) do
            local name = child.Name:lower()
            if name:find("thumbstick") or name:find("joystick") then
                if child:IsA("Frame") then
                    return child
                end
            end
            local result = searchForThumbstick(child, depth + 1)
            if result then return result end
        end
        return nil
    end
    
    pcall(function()
        dynamicThumbstick = searchForThumbstick(PlayerGui)
        
        if dynamicThumbstick then
            print("✅ DynamicThumbstick terdeteksi: " .. dynamicThumbstick.Name)
            
            -- Hitung center dan radius thumbstick
            local pos = dynamicThumbstick.AbsolutePosition
            local size = dynamicThumbstick.AbsoluteSize
            thumbstickCenter = pos + (size / 2)
            thumbstickRadius = math.min(size.X, size.Y) / 2
            
            print("📍 Thumbstick Center: " .. tostring(thumbstickCenter))
            print("📏 Thumbstick Radius: " .. thumbstickRadius)
        end
    end)
end

local function IsPositionInThumbstick(pos)
    if not dynamicThumbstick then return false end
    
    -- Fallback: check absolute position dari thumbstick frame
    local thumbPos = dynamicThumbstick.AbsolutePosition
    local thumbSize = dynamicThumbstick.AbsoluteSize
    
    -- Check apakah pos berada dalam bounding box thumbstick
    local isWithinX = pos.X >= thumbPos.X - 50 and pos.X <= (thumbPos.X + thumbSize.X + 50)
    local isWithinY = pos.Y >= thumbPos.Y - 50 and pos.Y <= (thumbPos.Y + thumbSize.Y + 50)
    
    return isWithinX and isWithinY
end

local function GetJoystickInput(touchPos)
    if not dynamicThumbstick then return Vector3.new(0, 0, 0) end
    
    -- Convert to Vector2
    local touchPos2D = Vector2.new(touchPos.X, touchPos.Y)
    local delta = touchPos2D - thumbstickCenter
    local magnitude = delta.Magnitude
    
    if magnitude < 5 then
        return Vector3.new(0, 0, 0)
    end
    
    -- Normalize joystick input
    local maxDist = thumbstickRadius
    local normalized = delta / maxDist
    
    -- Clamp nilai
    normalized = Vector2.new(
        math.max(-1, math.min(1, normalized.X)),
        math.max(-1, math.min(1, normalized.Y))
    )
    
    -- Convert to movement direction (X = strafe, Z = forward)
    return Vector3.new(normalized.X, 0, normalized.Y)
end

-- ============================================
-- MAIN FREECAM FUNCTIONS
-- ============================================

function FreecamModule.Start()
    if freecam then return end
    
    freecam = true
    
    local currentCF = Camera.CFrame
    camPos = currentCF.Position
    local x, y, z = currentCF:ToEulerAnglesYXZ()
    camRot = Vector3.new(x, y, z)
    
    LockCharacter(true)
    HideAllGuis()
    Camera.CameraType = Enum.CameraType.Scriptable
    
    task.wait()
    
    if not isMobile then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    else
        DetectDynamicThumbstick()
    end
    
    -- Mobile input handling
    if isMobile then
        inputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                
                -- Gunakan pcall untuk avoid error dari script game lain
                local isInThumbstick = false
                pcall(function()
                    isInThumbstick = IsPositionInThumbstick(pos)
                end)
                
                if isInThumbstick then
                    joystickTouch = input
                else
                    -- Camera touch di area lain
                    cameraTouch = input
                    cameraTouchStartPos = input.Position
                end
            end
        end)
        
        inputChangedConnection = UIS.InputChanged:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                -- Handle joystick touch
                if input == joystickTouch then
                    pcall(function()
                        mobileJoystickInput = GetJoystickInput(input.Position)
                    end)
                end
                
                -- Handle camera touch
                if input == cameraTouch and cameraTouch then
                    local delta = input.Position - cameraTouchStartPos
                    
                    if delta.Magnitude > 0 then
                        camRot = camRot + Vector3.new(
                            -delta.Y * sensitivity * 0.003,
                            -delta.X * sensitivity * 0.003,
                            0
                        )
                        
                        cameraTouchStartPos = input.Position
                    end
                end
            end
        end)
        
        inputEndedConnection = UIS.InputEnded:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                if input == joystickTouch then
                    joystickTouch = nil
                    mobileJoystickInput = Vector3.new(0, 0, 0)
                end
                
                if input == cameraTouch then
                    cameraTouch = nil
                    cameraTouchStartPos = nil
                end
            end
        end)
    end
    
    renderConnection = RunService.RenderStepped:Connect(function(dt)
        if not freecam then return end
        
        if not isMobile then
            local mouseDelta = UIS:GetMouseDelta()
            
            if mouseDelta.Magnitude > 0 then
                camRot = camRot + Vector3.new(
                    -mouseDelta.Y * sensitivity * 0.01,
                    -mouseDelta.X * sensitivity * 0.01,
                    0
                )
            end
        end
        
        local rotationCF = CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, camRot.Z)
        
        local moveInput = GetMovement()
        if moveInput.Magnitude > 0 then
            moveInput = moveInput.Unit
            
            local moveCF = CFrame.new(camPos) * rotationCF
            local velocity = (moveCF.LookVector * moveInput.Z) +
                             (moveCF.RightVector * moveInput.X) +
                             (moveCF.UpVector * moveInput.Y)
            
            camPos = camPos + velocity * speed * dt
        end
        
        Camera.CFrame = CFrame.new(camPos) * rotationCF
    end)
    
    return true
end

function FreecamModule.Stop()
    if not freecam then return end
    
    freecam = false
    
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
        inputChangedConnection = nil
    end
    
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
        inputEndedConnection = nil
    end
    
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end
    
    for _, conn in pairs(joystickConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    joystickConnections = {}
    
    LockCharacter(false)
    ShowAllGuis()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = Humanoid
    
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    
    cameraTouch = nil
    cameraTouchStartPos = nil
    joystickTouch = nil
    mobileJoystickInput = Vector3.new(0, 0, 0)
    
    return true
end

function FreecamModule.Toggle()
    if freecam then
        return FreecamModule.Stop()
    else
        return FreecamModule.Start()
    end
end

function FreecamModule.IsActive()
    return freecam
end

function FreecamModule.SetSpeed(newSpeed)
    speed = math.max(1, newSpeed)
end

function FreecamModule.SetSensitivity(newSensitivity)
    sensitivity = math.max(0.01, math.min(5, newSensitivity))
end

function FreecamModule.GetSpeed()
    return speed
end

function FreecamModule.GetSensitivity()
    return sensitivity
end

-- ============================================
-- SET MAIN GUI NAME
-- ============================================
local mainGuiName = nil

function FreecamModule.SetMainGuiName(guiName)
    mainGuiName = guiName
    print("✅ Main GUI set to: " .. guiName)
end

function FreecamModule.GetMainGuiName()
    return mainGuiName
end

-- ============================================
-- F3 KEYBIND - PC ONLY (MASTER SWITCH LOGIC)
-- ============================================
local f3KeybindActive = false

function FreecamModule.EnableF3Keybind(enable)
    f3KeybindActive = enable
    
    -- Jika toggle GUI dimatikan, matikan freecam juga
    if not enable and freecam then
        FreecamModule.Stop()
        print("🔴 Freecam disabled (Toggle GUI OFF)")
    end
    
    if not isMobile then
        local status = f3KeybindActive and "ENABLED (Press F3 to activate)" or "DISABLED"
        print("⚙️ F3 Keybind: " .. status)
    end
end

function FreecamModule.IsF3KeybindActive()
    return f3KeybindActive
end

-- F3 Input Handler (PC Only)
if not isMobile then
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Cek apakah F3 ditekan DAN toggle GUI aktif
        if input.KeyCode == Enum.KeyCode.F3 and f3KeybindActive then
            FreecamModule.Toggle()
            
            if freecam then
                print("🎥 Freecam ACTIVATED via F3")
            else
                print("🔴 Freecam DEACTIVATED via F3")
            end
        end
    end)
end


return FreecamModule

