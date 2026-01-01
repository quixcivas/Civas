-- Hide Stats Identifier Module untuk Fisch Roblox
-- Standalone version untuk dipanggil via loadstring

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HideStatsModule = {}

-- Settings
local HideStatsEnabled = false
local FakeName = "Bagi Sikrit bang"
local FakeLevel = "1"
local ScriptName = "-Quix-"

-- Variable untuk menyimpan original text
local OriginalTexts = {}
local ActiveGradientThreads = {}

-- Warna untuk efek shimmer/berkilau Orange-Putih
local ShimmerColors = {
    Color3.fromRGB(255, 140, 0),   -- Dark Orange
    Color3.fromRGB(255, 180, 50),  -- Orange
    Color3.fromRGB(255, 220, 150), -- Light Orange
    Color3.fromRGB(255, 255, 255), -- Putih (kilau)
    Color3.fromRGB(255, 220, 150), -- Light Orange
    Color3.fromRGB(255, 180, 50),  -- Orange
    Color3.fromRGB(255, 140, 0),   -- Dark Orange
}

-- Fungsi untuk membuat UIGradient shimmer effect yang bergerak
local function createMovingGradient(label)
    if not label or not label:IsA("TextLabel") then return end
    
    -- Hapus gradient lama jika ada
    local oldGradient = label:FindFirstChild("ShimmerGradient")
    if oldGradient then oldGradient:Destroy() end
    
    -- Buat UIGradient baru
    local gradient = Instance.new("UIGradient")
    gradient.Name = "ShimmerGradient"
    gradient.Parent = label
    
    -- Setup ColorSequence untuk efek shimmer/berkilau
    local colorKeypoints = {}
    
    local basePattern = {
        {0.00, Color3.fromRGB(255, 140, 0)},
        {0.10, Color3.fromRGB(255, 160, 30)},
        {0.20, Color3.fromRGB(255, 200, 100)},
        {0.30, Color3.fromRGB(255, 255, 255)},
        {0.40, Color3.fromRGB(255, 200, 100)},
        {0.50, Color3.fromRGB(255, 160, 30)},
        {0.60, Color3.fromRGB(255, 140, 0)},
        {0.70, Color3.fromRGB(255, 160, 30)},
        {0.80, Color3.fromRGB(255, 200, 100)},
        {0.90, Color3.fromRGB(255, 255, 255)},
        {1.00, Color3.fromRGB(255, 140, 0)},
    }
    
    for _, data in ipairs(basePattern) do
        table.insert(colorKeypoints, ColorSequenceKeypoint.new(data[1], data[2]))
    end
    
    gradient.Color = ColorSequence.new(colorKeypoints)
    
    -- Mulai animasi shimmer dari kiri ke kanan
    local threadId = tostring(label)
    ActiveGradientThreads[threadId] = true
    
    spawn(function()
        local offset = 0
        while label and label.Parent and ActiveGradientThreads[threadId] do
            offset = offset + 0.015
            if offset >= 1 then
                offset = 0
            end
            
            gradient.Offset = Vector2.new(offset, 0)
            wait(0.02)
        end
    end)
    
    return gradient
end

-- Fungsi untuk membuat clone TextLabel untuk script name
local function createScriptNameLabel(nameLabel, billboard)
    if not nameLabel or not billboard then return end
    
    local existingFrame = billboard:FindFirstChild("QuixFrame")
    if existingFrame then 
        return existingFrame
    end
    
    local nameFrame = nameLabel.Parent
    if not nameFrame or not nameFrame:IsA("Frame") then return end
    
    local originalNamePos = nameFrame.Position
    nameFrame.Position = UDim2.new(
        originalNamePos.X.Scale,
        originalNamePos.X.Offset,
        originalNamePos.Y.Scale + 0.25,
        originalNamePos.Y.Offset
    )
    
    local QuixFrame = Instance.new("Frame")
    QuixFrame.Name = "QuixFrame"
    QuixFrame.Size = nameFrame.Size
    QuixFrame.Position = originalNamePos
    QuixFrame.BackgroundTransparency = 1
    QuixFrame.Parent = billboard
    
    local scriptLabel = nameLabel:Clone()
    scriptLabel.Name = "QuixLabel"
    scriptLabel.Text = ScriptName
    scriptLabel.TextScaled = true
    scriptLabel.Font = Enum.Font.GothamBold
    scriptLabel.TextStrokeTransparency = 0.5
    scriptLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    scriptLabel.Parent = QuixFrame
    
    createMovingGradient(scriptLabel)
    
    return QuixFrame
end

-- Fungsi untuk menghapus semua script name labels
local function removeAllScriptNames()
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead then return end
    
    local QuixFrame = overhead:FindFirstChild("QuixFrame")
    if QuixFrame then
        for threadId, _ in pairs(ActiveGradientThreads) do
            ActiveGradientThreads[threadId] = nil
        end
        
        local nameLabel = overhead:FindFirstChild("Header", true)
        if nameLabel then
            local nameFrame = nameLabel.Parent
            if nameFrame and nameFrame:IsA("Frame") then
                local currentPos = nameFrame.Position
                nameFrame.Position = UDim2.new(
                    currentPos.X.Scale,
                    currentPos.X.Offset,
                    currentPos.Y.Scale - 0.25,
                    currentPos.Y.Offset
                )
            end
        end
        
        QuixFrame:Destroy()
    end
end

-- Fungsi untuk mengubah nama dan level di overhead display
local function updateStats()
    if not HideStatsEnabled then 
        removeAllScriptNames()
        return 
    end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local overhead = hrp:FindFirstChild("Overhead")
    if not overhead or not overhead:IsA("BillboardGui") then return end
    
    for _, obj in pairs(overhead:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local fullPath = obj:GetFullName()
            
            if not OriginalTexts[fullPath] then
                OriginalTexts[fullPath] = obj.Text
            end
            
            local originalText = OriginalTexts[fullPath]
            
            if originalText and originalText ~= "" then
                if obj.Name == "Header" then
                    if not overhead:FindFirstChild("QuixFrame") then
                        createScriptNameLabel(obj, overhead)
                    end
                    obj.Text = FakeName
                elseif string.find(string.lower(originalText), "lvl") then
                    obj.Text = string.gsub(originalText, "%d+", FakeLevel)
                end
            end
        end
    end
end

-- Auto-update loop
local updateLoop
local function startUpdateLoop()
    if updateLoop then return end
    updateLoop = true
    spawn(function()
        while updateLoop and wait(0.2) do
            if HideStatsEnabled then
                updateStats()
            end
        end
    end)
end

-- PUBLIC FUNCTIONS
function HideStatsModule.Enable()
    HideStatsEnabled = true
    startUpdateLoop()
    updateStats()
end

function HideStatsModule.Disable()
    HideStatsEnabled = false
    
    -- Restore original texts
    for path, originalText in pairs(OriginalTexts) do
        local obj = game
        for part in string.gmatch(path, "[^.]+") do
            obj = obj:FindFirstChild(part)
            if not obj then break end
        end
        if obj and obj:IsA("TextLabel") then
            obj.Text = originalText
        end
    end
    
    removeAllScriptNames()
end

function HideStatsModule.SetFakeName(name)
    FakeName = name or "Guest"
    if HideStatsEnabled then
        updateStats()
    end
end

function HideStatsModule.SetFakeLevel(level)
    FakeLevel = tostring(level or "1")
    if HideStatsEnabled then
        updateStats()
    end
end

function HideStatsModule.IsEnabled()
    return HideStatsEnabled
end

function HideStatsModule.GetSettings()
    return {
        enabled = HideStatsEnabled,
        fakeName = FakeName,
        fakeLevel = FakeLevel
    }
end

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(character)
    OriginalTexts = {}
    ActiveGradientThreads = {}
    wait(1)
    if HideStatsEnabled then
        updateStats()
    end
end)

-- Monitor untuk GUI baru
if LocalPlayer.Character then
    LocalPlayer.Character.DescendantAdded:Connect(function(descendant)
        if HideStatsEnabled and descendant:IsA("BillboardGui") then
            wait(0.1)
            updateStats()
        end
    end)
end

-- Initial setup
if LocalPlayer.Character then
    wait(1)
    if HideStatsEnabled then
        updateStats()
    end
end

return HideStatsModule
