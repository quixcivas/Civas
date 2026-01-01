-- Quix Panel - Ping & FPS Monitor
-- Script untuk monitoring ping dan FPS real-time

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Module untuk dipanggil dari GUI utama
local MonitorModule = {}

-- Variables untuk FPS calculation
local lastFrameTime = tick()
local fpsHistory = {}
local maxFPSHistory = 20
local updateConnection
local pingUpdateConnection

-- Fungsi untuk membuat GUI
local function createMonitorGUI()
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "QuixPanelMonitor"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    
    -- Container Frame dengan background rounded
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 200, 0, 70) -- Ukuran lebih kecil untuk mobile
    container.Position = UDim2.new(0, 100, 0, 300) -- Posisi tengah kiri
    container.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    container.BackgroundTransparency = 0.2 -- Transparant
    container.BorderSizePixel = 0
    container.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = container
    
    -- Stroke untuk border dengan orange accent
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(255, 140, 50)
    containerStroke.Thickness = 1.5
    containerStroke.Transparency = 0.5
    containerStroke.Parent = container
    
    -- Header dengan logo dan nama
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    -- Logo Icon dengan corner rounded
    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Name = "LogoIcon"
    logoIcon.Size = UDim2.new(0, 24, 0, 24)
    logoIcon.Position = UDim2.new(0, 8, 0, 5)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = "rbxassetid://118176705805619" -- Logo Quix
    logoIcon.ScaleType = Enum.ScaleType.Fit
    logoIcon.Parent = header
    
    -- Corner untuk logo agar melengkung
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoIcon
    
    -- Title Label dengan warna orange
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 36, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Quix PANEL"
    titleLabel.TextColor3 = Color3.fromRGB(255, 140, 50) -- Orange
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    -- Separator Line
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, -16, 0, 1)
    separator.Position = UDim2.new(0, 8, 0, 35)
    separator.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
    separator.BackgroundTransparency = 0.7
    separator.BorderSizePixel = 0
    separator.Parent = container
    
    -- Content Container untuk Ping dan FPS (Horizontal)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -42)
    content.Position = UDim2.new(0, 8, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = container
    
    -- Ping Display (Kiri)
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(0.5, -6, 1, 0)
    pingLabel.Position = UDim2.new(0, 0, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0 ms"
    pingLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    pingLabel.TextSize = 13
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Center
    pingLabel.Parent = content
    
    -- Separator vertical antara Ping dan FPS
    local verticalSeparator = Instance.new("Frame")
    verticalSeparator.Name = "VerticalSeparator"
    verticalSeparator.Size = UDim2.new(0, 1, 0.7, 0)
    verticalSeparator.Position = UDim2.new(0.5, 0, 0.15, 0)
    verticalSeparator.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
    verticalSeparator.BackgroundTransparency = 0.7
    verticalSeparator.BorderSizePixel = 0
    verticalSeparator.Parent = content
    
    -- FPS Display (Kanan)
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(0.5, -6, 1, 0)
    fpsLabel.Position = UDim2.new(0.5, 6, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    fpsLabel.TextSize = 13
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Center
    fpsLabel.Parent = content
    
    -- Make draggable
    local dragging = false
    local dragInput, dragStart, startPos
    local UserInputService = game:GetService("UserInputService")
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = container.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    container.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            container.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    screenGui.Parent = playerGui
    
    return {
        ScreenGui = screenGui,
        Container = container,
        PingLabel = pingLabel,
        FPSLabel = fpsLabel,
        LogoIcon = logoIcon
    }
end

-- Fungsi untuk mendapatkan ping
local function getPing()
    local ping = 0
    pcall(function()
        local networkStats = Stats:FindFirstChild("Network")
        if networkStats then
            local serverStatsItem = networkStats:FindFirstChild("ServerStatsItem")
            if serverStatsItem then
                local pingStr = serverStatsItem["Data Ping"]:GetValueString()
                ping = tonumber(pingStr:match("%d+")) or 0
            end
        end
        
        if ping == 0 then
            ping = math.floor(player:GetNetworkPing() * 1000)
        end
    end)
    return ping
end

-- Fungsi untuk mendapatkan FPS real-time
local function getFPS()
    local currentTime = tick()
    local deltaTime = currentTime - lastFrameTime
    lastFrameTime = currentTime
    
    local currentFPS = 0
    if deltaTime > 0 then
        currentFPS = 1 / deltaTime
    end
    
    table.insert(fpsHistory, currentFPS)
    
    if #fpsHistory > maxFPSHistory then
        table.remove(fpsHistory, 1)
    end
    
    local sum = 0
    for _, fps in ipairs(fpsHistory) do
        sum = sum + fps
    end
    
    local averageFPS = sum / #fpsHistory
    return math.floor(math.clamp(averageFPS, 0, 240))
end

-- Fungsi untuk update warna berdasarkan nilai
local function updatePingColor(pingLabel, value)
    local ping = tonumber(value)
    if ping <= 50 then
        pingLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    elseif ping <= 100 then
        pingLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif ping <= 150 then
        pingLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
    else
        pingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function updateFPSColor(fpsLabel, value)
    local fps = tonumber(value)
    if fps >= 55 then
        fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    elseif fps >= 40 then
        fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif fps >= 25 then
        fpsLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
    else
        fpsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Fungsi untuk show panel
function MonitorModule:Show()
    if self.GUI then
        self.GUI.ScreenGui.Enabled = true
        return
    end
    
    print("🚀 Starting Quix Panel Monitor...")
    
    self.GUI = createMonitorGUI()
    
    -- Update loop untuk FPS (real-time)
    updateConnection = RunService.RenderStepped:Connect(function()
        if not self.GUI or not self.GUI.ScreenGui or not self.GUI.ScreenGui.Parent then
            if updateConnection then
                updateConnection:Disconnect()
            end
            return
        end
        
        local fps = getFPS()
        self.GUI.FPSLabel.Text = "FPS: " .. tostring(fps)
        updateFPSColor(self.GUI.FPSLabel, fps)
    end)
    
    -- Update ping dengan interval (setiap 0.5 detik)
    local lastPingUpdate = 0
    pingUpdateConnection = RunService.Heartbeat:Connect(function()
        if not self.GUI or not self.GUI.ScreenGui or not self.GUI.ScreenGui.Parent then
            if pingUpdateConnection then
                pingUpdateConnection:Disconnect()
            end
            return
        end
        
        local currentTime = tick()
        if currentTime - lastPingUpdate >= 0.5 then
            local ping = getPing()
            self.GUI.PingLabel.Text = "Ping: " .. ping .. " ms"
            updatePingColor(self.GUI.PingLabel, ping)
            lastPingUpdate = currentTime
        end
    end)
    
    print("✅ Quix Panel Monitor loaded!")
end

-- Fungsi untuk hide panel
function MonitorModule:Hide()
    if self.GUI and self.GUI.ScreenGui then
        self.GUI.ScreenGui.Enabled = false
    end
end

-- Fungsi untuk toggle panel
function MonitorModule:Toggle()
    if self.GUI and self.GUI.ScreenGui then
        self.GUI.ScreenGui.Enabled = not self.GUI.ScreenGui.Enabled
    else
        self:Show()
    end
end

-- Fungsi untuk destroy panel
function MonitorModule:Destroy()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    if pingUpdateConnection then
        pingUpdateConnection:Disconnect()
        pingUpdateConnection = nil
    end
    
    if self.GUI and self.GUI.ScreenGui then
        self.GUI.ScreenGui:Destroy()
        self.GUI = nil
    end
    
    fpsHistory = {}
    print("✅ Quix Monitor destroyed")
end

-- Fungsi untuk set custom logo
function MonitorModule:SetLogo(imageId)
    if self.GUI and self.GUI.LogoIcon then
        self.GUI.LogoIcon.Image = imageId
    end
end

-- Fungsi untuk set posisi
function MonitorModule:SetPosition(x, y)
    if self.GUI and self.GUI.Container then
        self.GUI.Container.Position = UDim2.new(0, x, 0, y)
    end
end

return MonitorModule
