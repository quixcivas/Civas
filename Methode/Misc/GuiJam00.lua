-- QuixGUI_v4.2.0.lua - FIXED MODULE LOADING (Part 1/6)
-- Core Setup, Services, Advanced Loading System
-- FREE NOT FOR SALE

repeat task.wait() until game:IsLoaded()

-- ============================================
-- SERVICES & CORE VARIABLES
-- ============================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer

repeat task.wait() until localPlayer:FindFirstChild("PlayerGui")

-- Detect platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do 
        inst[k] = v 
    end
    return inst
end

local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = "rbxassetid://111416780887356"
        })
    end)
end

-- ============================================
-- ADVANCED MODULE LOADING SYSTEM WITH RETRY
-- ============================================
local Modules = {}
local ModuleStatus = {}
local totalModules = 0
local loadedModules = 0
local failedModules = {}
local DEBUG_MODE = true -- Set true untuk debug

-- Critical modules yang WAJIB terload
local CRITICAL_MODULES = {
    "HideStats",
    "Webhook",
    "Notify"
}

-- Send initial loading notification
SendNotification("🎣 Quix Script", "Initializing Security Loader...", 3)
print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔄 Quix GUI v4.2.0 - LOADING")
print("━━━━━━━━━━━━━━━━━━━━━━")

-- Load Security Loader
local SecurityLoader
local loaderSuccess, loaderError = pcall(function()
    SecurityLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/akmiliadevi/Tugas_Kuliah/refs/heads/main/SecurityLoader.lua"))()
end)

if not loaderSuccess or not SecurityLoader then
    local errorMsg = loaderError and tostring(loaderError) or "Unknown error"
    SendNotification("❌ CRITICAL ERROR", "SecurityLoader failed!", 10)
    warn("❌ CRITICAL: SecurityLoader failed to load - " .. errorMsg)
    warn("❌ Script cannot continue without SecurityLoader")
    return
end

print("✅ SecurityLoader loaded successfully")
SendNotification("✅ Security OK", "Loading modules...", 2)

-- Module list - MATCHED WITH SecurityLoader (35 modules)
local ModuleList = {
    -- Critical modules first
    "Notify", "HideStats", "Webhook",
    -- Fishing modules
    "instant", "instant2", "blatantv1", "UltraBlatant", "blatantv2", "blatantv2fix",
    "GoodPerfectionStable",
    -- Support features
    "NoFishingAnimation", "LockPosition", "AutoEquipRod", "DisableCutscenes",
    "DisableExtras", "AutoTotem3X", "SkinAnimation", "WalkOnWater",
    -- Teleport
    "TeleportModule", "TeleportToPlayer", "SavedLocation", "EventTeleportDynamic",
    -- Quest
    "AutoQuestModule", "AutoTemple", "TempleDataReader",
    -- Shop
    "AutoSell", "AutoSellTimer", "MerchantSystem", "RemoteBuyer", "AutoBuyWeather",
    -- Camera & Settings
    "FreecamModule", "UnlimitedZoomModule", "AntiAFK", "UnlockFPS", "FPSBooster"
}

totalModules = #ModuleList

-- Validate module list count
if totalModules == 0 then
    warn("❌ CRITICAL: Module list is empty!")
    SendNotification("❌ Error", "Module list is empty!", 10)
    return
end

print(string.format("📋 Module list validated: %d modules to load", totalModules))

-- ============================================
-- SYNCHRONOUS MODULE LOADING WITH RETRY
-- ============================================
local MAX_RETRIES = 3
local RETRY_DELAY = 1

local function LoadModuleWithRetry(moduleName, retryCount)
    retryCount = retryCount or 0
    
    local success, result = pcall(function()
        return SecurityLoader.LoadModule(moduleName)
    end)
    
    if success and result then
        Modules[moduleName] = result
        ModuleStatus[moduleName] = "✅ Loaded"
        loadedModules = loadedModules + 1
        
        if DEBUG_MODE then
            print(string.format("✅ [%d/%d] %s loaded", loadedModules, totalModules, moduleName))
        end
        
        return true
    else
        if retryCount < MAX_RETRIES then
            warn(string.format("⚠️ Retry %d/%d for %s", retryCount + 1, MAX_RETRIES, moduleName))
            task.wait(RETRY_DELAY)
            return LoadModuleWithRetry(moduleName, retryCount + 1)
        else
            Modules[moduleName] = nil
            ModuleStatus[moduleName] = "❌ Failed"
            table.insert(failedModules, moduleName)
            
            warn(string.format("❌ FAILED: %s (after %d retries)", moduleName, MAX_RETRIES))
            return false
        end
    end
end

local function LoadAllModules()
    print("\n📦 Starting module loading sequence...")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    local startTime = tick()
    
    -- Load modules synchronously
    for index, moduleName in ipairs(ModuleList) do
        local isCritical = table.find(CRITICAL_MODULES, moduleName) ~= nil
        local moduleLabel = isCritical and "[CRITICAL]" or "[OPTIONAL]"
        
        print(string.format("\n🔄 Loading %s %s...", moduleLabel, moduleName))
        
        local success = LoadModuleWithRetry(moduleName)
        
        if not success and isCritical then
            SendNotification("❌ CRITICAL ERROR", 
                string.format("%s failed to load!", moduleName), 
                10)
            error(string.format("CRITICAL MODULE FAILED: %s", moduleName))
            return false
        end
        
        -- Update progress notification every 5 modules
        if index % 5 == 0 then
            local percent = math.floor((loadedModules / totalModules) * 100)
            SendNotification("📦 Loading Modules", 
                string.format("%d/%d loaded (%d%%)", loadedModules, totalModules, percent), 
                2)
        end
    end
    
    local loadTime = math.floor((tick() - startTime) * 100) / 100
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━")
    print("✨ MODULE LOADING COMPLETE")
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print(string.format("📦 Loaded: %d/%d modules", loadedModules, totalModules))
    print(string.format("⏱️ Time: %.2f seconds", loadTime))
    
    if #failedModules > 0 then
        print("\n⚠️ FAILED MODULES:")
        for _, name in ipairs(failedModules) do
            print("   ❌ " .. name)
        end
    end
    
    if DEBUG_MODE then
        print("\n━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 DETAILED MODULE STATUS:")
        for name, status in pairs(ModuleStatus) do
            print(string.format("   %s %s", status, name))
        end
    end
    
    print("━━━━━━━━━━━━━━━━━━━━━━\n")
    
    -- Final validation
    local allCriticalLoaded = true
    for _, criticalModule in ipairs(CRITICAL_MODULES) do
        if not Modules[criticalModule] then
            allCriticalLoaded = false
            warn(string.format("❌ CRITICAL MODULE MISSING: %s", criticalModule))
        end
    end
    
    if not allCriticalLoaded then
        SendNotification("❌ CRITICAL ERROR", "Essential modules failed! Check console.", 10)
        return false
    end
    
    local percent = math.floor((loadedModules / totalModules) * 100)
    SendNotification("✨ Quix Ready!", 
        string.format("%d/%d modules loaded (%d%%)", loadedModules, totalModules, percent), 
        4)
    
    return true
end

-- Start loading and wait for completion
local loadSuccess = LoadAllModules()

if not loadSuccess then
    error("Module loading failed - Script halted")
    return
end

-- Safe module getter with fallback
local function GetModule(name)
    local module = Modules[name]
    if not module then
        if DEBUG_MODE then
            warn(string.format("⚠️ Module '%s' not available (may have failed to load)", name))
        end
    end
    return module
end

-- Verify critical modules one more time before GUI creation
print("\n🔍 Final verification of critical modules...")
local criticalModulesOK = true
for _, criticalModule in ipairs(CRITICAL_MODULES) do
    local module = GetModule(criticalModule)
    if module then
        print(string.format("   ✅ %s: VERIFIED", criticalModule))
    else
        print(string.format("   ❌ %s: MISSING", criticalModule))
        criticalModulesOK = false
    end
end

if not criticalModulesOK then
    warn("❌ Critical module verification failed - GUI will not load")
    SendNotification("❌ Critical Error", "Essential modules missing! Check console.", 10)
    return
end

print("\n✅ All critical modules verified - Proceeding to GUI creation...\n")

-- ============================================
-- COLOR PALETTE
-- ============================================
local colors = {
    primary = Color3.fromRGB(255, 140, 0),
    secondary = Color3.fromRGB(147, 112, 219),
    accent = Color3.fromRGB(186, 85, 211),
    galaxy1 = Color3.fromRGB(123, 104, 238),
    galaxy2 = Color3.fromRGB(72, 61, 139),
    success = Color3.fromRGB(34, 197, 94),
    warning = Color3.fromRGB(251, 191, 36),
    danger = Color3.fromRGB(239, 68, 68),
    
    bg1 = Color3.fromRGB(10, 10, 10),
    bg2 = Color3.fromRGB(18, 18, 18),
    bg3 = Color3.fromRGB(25, 25, 25),
    bg4 = Color3.fromRGB(35, 35, 35),
    
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 180),
    textDimmer = Color3.fromRGB(120, 120, 120),
    
    border = Color3.fromRGB(50, 50, 50),
    glow = Color3.fromRGB(138, 43, 226),
}

-- Window configuration
local windowSize = UDim2.new(0, 420, 0, 280)
local minWindowSize = Vector2.new(380, 250)
local maxWindowSize = Vector2.new(550, 400)
local sidebarWidth = 140

-- ⏸️ BAGIAN 1/6 SELESAI
-- Tunggu perintah "lanjut" untuk melanjutkan ke bagian 2/6

-- ============================================
-- BAGIAN 2/6: GUI Structure & Window Creation
-- ============================================

local gui = new("ScreenGui", {
    Name = "QuixGUI_Galaxy",
    Parent = localPlayer.PlayerGui,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 2147483647
})

local function bringToFront()
    gui.DisplayOrder = 2147483647
end

-- Main Window Container
local win = new("Frame", {
    Parent = gui,
    Size = windowSize,
    Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
    BackgroundColor3 = colors.bg1,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    ZIndex = 3
})
new("UICorner", {Parent = win, CornerRadius = UDim.new(0, 12)})
new("UIStroke", {
    Parent = win,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.9,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
})

-- Inner shadow effect
local innerShadow = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, -2, 1, -2),
    Position = UDim2.new(0, 1, 0, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 2
})
new("UICorner", {Parent = innerShadow, CornerRadius = UDim.new(0, 11)})
new("UIStroke", {
    Parent = innerShadow,
    Color = Color3.fromRGB(0, 0, 0),
    Thickness = 1,
    Transparency = 0.8
})

-- Sidebar
local sidebar = new("Frame", {
    Parent = win,
    Size = UDim2.new(0, sidebarWidth, 1, -45),
    Position = UDim2.new(0, 0, 0, 45),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 4
})
new("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0, 12)})
new("UIStroke", {
    Parent = sidebar,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.95
})

-- Script Header
local scriptHeader = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, 0, 0, 45),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0,
    ZIndex = 5
})
new("UICorner", {Parent = scriptHeader, CornerRadius = UDim.new(0, 12)})

-- Gradient overlay
local gradient = new("UIGradient", {
    Parent = scriptHeader,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(72, 61, 139))
    },
    Rotation = 45,
    Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.97),
        NumberSequenceKeypoint.new(1, 0.99)
    }
})

-- Drag Handle
local headerDragHandle = new("Frame", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 40, 0, 3),
    Position = UDim2.new(0.5, -20, 0, 8),
    BackgroundColor3 = colors.primary,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = headerDragHandle, CornerRadius = UDim.new(1, 0)})
new("UIStroke", {
    Parent = headerDragHandle,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.85
})

-- Title with glow
local titleLabel = new("TextLabel", {
    Parent = scriptHeader,
    Text = "Quix",
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = colors.primary,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextStrokeTransparency = 0.9,
    TextStrokeColor3 = colors.primary,
    ZIndex = 6
})

-- Title glow effect
local titleGlow = new("TextLabel", {
    Parent = scriptHeader,
    Text = "Quix",
    Size = titleLabel.Size,
    Position = titleLabel.Position,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = colors.primary,
    TextTransparency = 0.7,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5
})

-- Animated glow pulse
task.spawn(function()
    while true do
        TweenService:Create(titleGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.4
        }):Play()
        task.wait(2)
        TweenService:Create(titleGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.7
        }):Play()
        task.wait(2)
    end
end)

-- Separator
local separator = new("Frame", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 2, 0, 25),
    Position = UDim2.new(0, 95, 0.5, -12.5),
    BackgroundColor3 = colors.primary,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = separator, CornerRadius = UDim.new(1, 0)})
new("UIStroke", {
    Parent = separator,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.7
})

local subtitleLabel = new("TextLabel", {
    Parent = scriptHeader,
    Text = "Free Not For Sale",
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(0, 105, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = colors.textDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTransparency = 0.3,
    ZIndex = 6
})

-- Minimize button
local btnMinHeader = new("TextButton", {
    Parent = scriptHeader,
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = colors.bg4,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Text = "─",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = colors.textDim,
    TextTransparency = 0.3,
    AutoButtonColor = false,
    ZIndex = 7
})
new("UICorner", {Parent = btnMinHeader, CornerRadius = UDim.new(0, 8)})

local btnStroke = new("UIStroke", {
    Parent = btnMinHeader,
    Color = colors.primary,
    Thickness = 0,
    Transparency = 0.8
})

btnMinHeader.MouseEnter:Connect(function()
    TweenService:Create(btnMinHeader, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = colors.galaxy1,
        BackgroundTransparency = 0.2,
        TextColor3 = colors.text,
        TextTransparency = 0,
        Size = UDim2.new(0, 32, 0, 32)
    }):Play()
    TweenService:Create(btnStroke, TweenInfo.new(0.25), {
        Thickness = 1.5,
        Transparency = 0.4
    }):Play()
end)

btnMinHeader.MouseLeave:Connect(function()
    TweenService:Create(btnMinHeader, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.5,
        TextColor3 = colors.textDim,
        TextTransparency = 0.3,
        Size = UDim2.new(0, 30, 0, 30)
    }):Play()
    TweenService:Create(btnStroke, TweenInfo.new(0.25), {
        Thickness = 0,
        Transparency = 0.8
    }):Play()
end)

-- Navigation Container
local navContainer = new("ScrollingFrame", {
    Parent = sidebar,
    Size = UDim2.new(1, -8, 1, -12),
    Position = UDim2.new(0, 4, 0, 6),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = colors.primary,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ClipsDescendants = true,
    ZIndex = 5
})
new("UIListLayout", {
    Parent = navContainer,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- Content Area
local contentBg = new("Frame", {
    Parent = win,
    Size = UDim2.new(1, -(sidebarWidth + 10), 1, -52),
    Position = UDim2.new(0, sidebarWidth + 5, 0, 47),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 4
})
new("UICorner", {Parent = contentBg, CornerRadius = UDim.new(0, 12)})
new("UIStroke", {
    Parent = contentBg,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.95
})

-- Top Bar
local topBar = new("Frame", {
    Parent = contentBg,
    Size = UDim2.new(1, -8, 0, 32),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 5
})
new("UICorner", {Parent = topBar, CornerRadius = UDim.new(0, 10)})
new("UIStroke", {
    Parent = topBar,
    Color = colors.primary,
    Thickness = 1,
    Transparency = 0.95
})

local pageTitle = new("TextLabel", {
    Parent = topBar,
    Text = "Main Dashboard",
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BackgroundTransparency = 1,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
})

-- Resize Handle
local resizing = false
local resizeHandle = new("TextButton", {
    Parent = win,
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(1, -18, 1, -18),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "⋰",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.textDim,
    TextTransparency = 0.4,
    AutoButtonColor = false,
    ZIndex = 100
})
new("UICorner", {Parent = resizeHandle, CornerRadius = UDim.new(0, 6)})

local resizeStroke = new("UIStroke", {
    Parent = resizeHandle,
    Color = colors.primary,
    Thickness = 0,
    Transparency = 0.8
})

resizeHandle.MouseEnter:Connect(function()
    TweenService:Create(resizeHandle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0.3,
        TextTransparency = 0,
        Size = UDim2.new(0, 20, 0, 20)
    }):Play()
    TweenService:Create(resizeStroke, TweenInfo.new(0.25), {
        Thickness = 1.5,
        Transparency = 0.5
    }):Play()
end)

resizeHandle.MouseLeave:Connect(function()
    if not resizing then
        TweenService:Create(resizeHandle, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 0.6,
            TextTransparency = 0.4,
            Size = UDim2.new(0, 18, 0, 18)
        }):Play()
        TweenService:Create(resizeStroke, TweenInfo.new(0.25), {
            Thickness = 0,
            Transparency = 0.8
        }):Play()
    end
end)

-- Pages
local pages = {}
local currentPage = "Main"
local navButtons = {}

local function createPage(name)
    local page = new("ScrollingFrame", {
        Parent = contentBg,
        Size = UDim2.new(1, -16, 1, -44),
        Position = UDim2.new(0, 8, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.primary,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 5
    })
    new("UIListLayout", {
        Parent = page,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    new("UIPadding", {
        Parent = page,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4)
    })
    pages[name] = page
    return page
end

-- Create all pages
local mainPage = createPage("Main")
local teleportPage = createPage("Teleport")
local questPage = createPage("Quest")
local shopPage = createPage("Shop")
local webhookPage = createPage("Webhook")
local cameraViewPage = createPage("CameraView")
local settingsPage = createPage("Settings")
local infoPage = createPage("Info")
mainPage.Visible = true

-- ⏸️ BAGIAN 2/6 SELESAI
-- Tunggu perintah "lanjut" untuk melanjutkan ke bagian 3/6

-- ============================================
-- BAGIAN 3/6: Navigation & UI Components
-- ============================================

-- Navigation Button Creation
local function createNavButton(text, icon, page, order)
    local btn = new("TextButton", {
        Parent = navContainer,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = page == currentPage and colors.bg3 or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = page == currentPage and 0.7 or 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 6
    })
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 9)})
    
    local indicator = new("Frame", {
        Parent = btn,
        Size = UDim2.new(0, 3, 0, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3 = colors.primary,
        BorderSizePixel = 0,
        Visible = page == currentPage,
        ZIndex = 7
    })
    new("UICorner", {Parent = indicator, CornerRadius = UDim.new(1, 0)})
    new("UIStroke", {
        Parent = indicator,
        Color = colors.primary,
        Thickness = 2,
        Transparency = 0.7
    })
    
    local iconLabel = new("TextLabel", {
        Parent = btn,
        Text = icon,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = page == currentPage and colors.primary or colors.textDim,
        TextTransparency = page == currentPage and 0 or 0.3,
        ZIndex = 7
    })
    
    local textLabel = new("TextLabel", {
        Parent = btn,
        Text = text,
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = page == currentPage and colors.text or colors.textDim,
        TextTransparency = page == currentPage and 0.1 or 0.4,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    })
    
    btn.MouseEnter:Connect(function()
        if page ~= currentPage then
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 0.8
            }):Play()
            TweenService:Create(iconLabel, TweenInfo.new(0.3), {
                TextTransparency = 0,
                TextColor3 = colors.primary
            }):Play()
            TweenService:Create(textLabel, TweenInfo.new(0.3), {
                TextTransparency = 0.2
            }):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if page ~= currentPage then
            TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(iconLabel, TweenInfo.new(0.3), {
                TextTransparency = 0.3,
                TextColor3 = colors.textDim
            }):Play()
            TweenService:Create(textLabel, TweenInfo.new(0.3), {
                TextTransparency = 0.4
            }):Play()
        end
    end)
    
    navButtons[page] = {btn = btn, icon = iconLabel, text = textLabel, indicator = indicator}
    return btn
end

-- Page Switching Function
local function switchPage(pageName, pageTitle_text)
    if currentPage == pageName then return end
    for _, page in pairs(pages) do page.Visible = false end
    
    for name, btnData in pairs(navButtons) do
        local isActive = name == pageName
        TweenService:Create(btnData.btn, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            BackgroundColor3 = isActive and colors.bg3 or Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = isActive and 0.7 or 1
        }):Play()
        btnData.indicator.Visible = isActive
        TweenService:Create(btnData.icon, TweenInfo.new(0.3), {
            TextColor3 = isActive and colors.primary or colors.textDim,
            TextTransparency = isActive and 0 or 0.3
        }):Play()
        TweenService:Create(btnData.text, TweenInfo.new(0.3), {
            TextColor3 = isActive and colors.text or colors.textDim,
            TextTransparency = isActive and 0.1 or 0.4
        }):Play()
    end
    
    pages[pageName].Visible = true
    pageTitle.Text = pageTitle_text
    currentPage = pageName
end

-- Create Navigation Buttons
local btnMain = createNavButton("Dashboard", "🏠", "Main", 1)
local btnTeleport = createNavButton("Teleport", "🌍", "Teleport", 2)
local btnQuest = createNavButton("Quest", "📜", "Quest", 3)
local btnShop = createNavButton("Shop", "🛒", "Shop", 4)
local btnWebhook = createNavButton("Webhook", "🔗", "Webhook", 5)
local btnCameraView = createNavButton("Camera View", "📷", "CameraView", 6)
local btnSettings = createNavButton("Settings", "⚙️", "Settings", 7)
local btnInfo = createNavButton("About", "ℹ️", "Info", 8)

-- Connect Navigation Buttons
btnMain.MouseButton1Click:Connect(function() switchPage("Main", "Main Dashboard") end)
btnTeleport.MouseButton1Click:Connect(function() switchPage("Teleport", "Teleport System") end)
btnQuest.MouseButton1Click:Connect(function() switchPage("Quest", "Auto Quest") end)
btnShop.MouseButton1Click:Connect(function() switchPage("Shop", "Shop Features") end)
btnWebhook.MouseButton1Click:Connect(function() switchPage("Webhook", "Webhook Page") end)
btnCameraView.MouseButton1Click:Connect(function() switchPage("CameraView", "Camera View Settings") end)
btnSettings.MouseButton1Click:Connect(function() switchPage("Settings", "Settings") end)
btnInfo.MouseButton1Click:Connect(function() switchPage("Info", "About Quix") end)

-- ============================================
-- UI COMPONENT FUNCTIONS
-- ============================================

-- Category Component
local function makeCategory(parent, title, icon)
    local categoryFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        ZIndex = 6
    })
    new("UICorner", {Parent = categoryFrame, CornerRadius = UDim.new(0, 6)})
    
    local categoryStroke = new("UIStroke", {
        Parent = categoryFrame,
        Color = colors.border,
        Thickness = 0,
        Transparency = 0.8
    })
    
    local header = new("TextButton", {
        Parent = categoryFrame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        ZIndex = 7
    })
    
    local titleLabel = new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 8
    })
    
    local contentContainer = new("Frame", {
        Parent = categoryFrame,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 38),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        ZIndex = 7
    })
    new("UIListLayout", {Parent = contentContainer, Padding = UDim.new(0, 6)})
    new("UIPadding", {Parent = contentContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        contentContainer.Visible = isOpen
        TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = isOpen and 180 or 0}):Play()
        TweenService:Create(categoryFrame, TweenInfo.new(0.25), {
            BackgroundTransparency = isOpen and 0.4 or 0.6
        }):Play()
        TweenService:Create(categoryStroke, TweenInfo.new(0.25), {Thickness = isOpen and 1 or 0}):Play()
    end)
    
    return contentContainer
end

-- Toggle Component
local function makeToggle(parent, label, callback)
    local frame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 7
    })
    
    local labelText = new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.68, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextWrapped = true,
        ZIndex = 8
    })
    
    local toggleBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = colors.bg4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(1, 0)})
    
    local toggleCircle = new("Frame", {
        Parent = toggleBg,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = colors.textDim,
        BorderSizePixel = 0,
        ZIndex = 9
    })
    new("UICorner", {Parent = toggleCircle, CornerRadius = UDim.new(1, 0)})
    
    local btn = new("TextButton", {
        Parent = toggleBg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10
    })
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(toggleBg, TweenInfo.new(0.25), {BackgroundColor3 = on and colors.primary or colors.bg4}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = on and colors.text or colors.textDim
        }):Play()
        pcall(callback, on)
    end)
end

-- Input Component (Horizontal)
local function makeInput(parent, label, defaultValue, callback)
    local frame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 7
    })
    
    local lbl = new("TextLabel", {
        Parent = frame,
        Text = label,
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 8
    })
    
    local inputBg = new("Frame", {
        Parent = frame,
        Size = UDim2.new(0.42, 0, 0, 28),
        Position = UDim2.new(0.58, 0, 0.5, -14),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = inputBg, CornerRadius = UDim.new(0, 6)})
    
    local inputStroke = new("UIStroke", {
        Parent = inputBg,
        Color = colors.border,
        Thickness = 1,
        Transparency = 0.7
    })
    
    local inputBox = new("TextBox", {
        Parent = inputBg,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue),
        PlaceholderText = "0.00",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        PlaceholderColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 9
    })
    
    inputBox.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = colors.primary,
            Thickness = 1.5,
            Transparency = 0.3
        }):Play()
    end)
    
    inputBox.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = colors.border,
            Thickness = 1,
            Transparency = 0.7
        }):Play()
        
        local value = tonumber(inputBox.Text)
        if value then
            pcall(callback, value)
        else
            inputBox.Text = tostring(defaultValue)
        end
    end)
end

-- Button Component
local function makeButton(parent, label, callback)
    local btnFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = colors.primary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = btnFrame, CornerRadius = UDim.new(0, 6)})
    
    local btnStroke = new("UIStroke", {
        Parent = btnFrame,
        Color = colors.primary,
        Thickness = 0,
        Transparency = 0.7
    })
    
    local button = new("TextButton", {
        Parent = btnFrame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        ZIndex = 9
    })
    
    button.MouseEnter:Connect(function()
        TweenService:Create(btnFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(1, 0, 0, 35)
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.2), {Thickness = 1.5}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(btnFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3,
            Size = UDim2.new(1, 0, 0, 32)
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.2), {Thickness = 0}):Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 30)}):Play()
        task.wait(0.1)
        TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 32)}):Play()
        pcall(callback)
    end)
    
    return btnFrame
end

-- ⏸️ BAGIAN 3/6 SELESAI
-- Tunggu perintah "lanjut" untuk melanjutkan ke bagian 4/6

-- ============================================
-- BAGIAN 4/6: Dropdown Component & Main Page Features
-- ============================================

-- Dropdown Component
local function makeDropdown(parent, title, icon, items, onSelect, uniqueId)
    local dropdownFrame = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.bg4,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 7,
        Name = uniqueId or "Dropdown"
    })
    new("UICorner", {Parent = dropdownFrame, CornerRadius = UDim.new(0, 6)})
    
    local dropStroke = new("UIStroke", {
        Parent = dropdownFrame,
        Color = colors.border,
        Thickness = 0,
        Transparency = 0.8
    })
    
    local header = new("TextButton", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 36),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 8
    })
    
    local iconLabel = new("TextLabel", {
        Parent = header,
        Text = icon,
        Size = UDim2.new(0, 24, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = colors.primary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local titleLabel = new("TextLabel", {
        Parent = header,
        Text = title,
        Size = UDim2.new(1, -70, 0, 14),
        Position = UDim2.new(0, 26, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local statusLabel = new("TextLabel", {
        Parent = header,
        Text = "None Selected",
        Size = UDim2.new(1, -70, 0, 12),
        Position = UDim2.new(0, 26, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local arrow = new("TextLabel", {
        Parent = header,
        Text = "▼",
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = colors.primary,
        ZIndex = 9
    })
    
    local listContainer = new("ScrollingFrame", {
        Parent = dropdownFrame,
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.new(0, 6, 0, 42),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = colors.primary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10
    })
    new("UIListLayout", {Parent = listContainer, Padding = UDim.new(0, 4)})
    new("UIPadding", {Parent = listContainer, PaddingBottom = UDim.new(0, 8)})
    
    local isOpen = false
    local selectedItem = nil
    
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listContainer.Visible = isOpen
        
        TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = isOpen and 180 or 0}):Play()
        TweenService:Create(dropdownFrame, TweenInfo.new(0.25), {
            BackgroundTransparency = isOpen and 0.35 or 0.5
        }):Play()
        TweenService:Create(dropStroke, TweenInfo.new(0.25), {Thickness = isOpen and 1 or 0}):Play()
        
        if isOpen then
            listContainer.Size = UDim2.new(1, -12, 0, math.min(#items * 28, 140))
        end
    end)
    
    for _, itemName in ipairs(items) do
        local itemBtn = new("TextButton", {
            Parent = listContainer,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = colors.bg4,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 11
        })
        new("UICorner", {Parent = itemBtn, CornerRadius = UDim.new(0, 5)})
        
        local itemStroke = new("UIStroke", {
            Parent = itemBtn,
            Color = colors.border,
            Thickness = 0,
            Transparency = 0.8
        })
        
        local btnLabel = new("TextLabel", {
            Parent = itemBtn,
            Text = itemName,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 8,
            TextColor3 = colors.textDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12
        })
        
        itemBtn.MouseEnter:Connect(function()
            if selectedItem ~= itemName then
                TweenService:Create(itemBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = colors.primary,
                    BackgroundTransparency = 0.3
                }):Play()
                TweenService:Create(btnLabel, TweenInfo.new(0.2), {TextColor3 = colors.text}):Play()
                TweenService:Create(itemStroke, TweenInfo.new(0.2), {Thickness = 1}):Play()
            end
        end)
        
        itemBtn.MouseLeave:Connect(function()
            if selectedItem ~= itemName then
                TweenService:Create(itemBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = colors.bg4,
                    BackgroundTransparency = 0.6
                }):Play()
                TweenService:Create(btnLabel, TweenInfo.new(0.2), {TextColor3 = colors.textDim}):Play()
                TweenService:Create(itemStroke, TweenInfo.new(0.2), {Thickness = 0}):Play()
            end
        end)
        
        itemBtn.MouseButton1Click:Connect(function()
            selectedItem = itemName
            statusLabel.Text = "✓ " .. itemName
            statusLabel.TextColor3 = colors.success
            pcall(onSelect, itemName)
            
            task.wait(0.1)
            isOpen = false
            listContainer.Visible = false
            TweenService:Create(arrow, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Rotation = 0}):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(0.25), {
                BackgroundTransparency = 0.5
            }):Play()
            TweenService:Create(dropStroke, TweenInfo.new(0.25), {Thickness = 0}):Play()
        end)
    end
    
    return dropdownFrame
end

-- ============================================
-- MAIN PAGE FEATURES
-- ============================================

-- Auto Fishing Category
local catAutoFishing = makeCategory(mainPage, "Auto Fishing", "🎣")
local currentInstantMode = "None"
local fishingDelayValue = 1.30
local cancelDelayValue = 0.19
local isInstantFishingEnabled = false

makeDropdown(catAutoFishing, "Instant Fishing Mode", "⚡", {"Fast", "Perfect"}, function(mode)
    currentInstantMode = mode
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    
    if instant then instant.Stop() end
    if instant2 then instant2.Stop() end
    
    if isInstantFishingEnabled then
        if mode == "Fast" and instant then
            instant.Settings.MaxWaitTime = fishingDelayValue
            instant.Settings.CancelDelay = cancelDelayValue
            instant.Start()
        elseif mode == "Perfect" and instant2 then
            instant2.Settings.MaxWaitTime = fishingDelayValue
            instant2.Settings.CancelDelay = cancelDelayValue
            instant2.Start()
        end
    else
        if instant then
            instant.Settings.MaxWaitTime = fishingDelayValue
            instant.Settings.CancelDelay = cancelDelayValue
        end
        if instant2 then
            instant2.Settings.MaxWaitTime = fishingDelayValue
            instant2.Settings.CancelDelay = cancelDelayValue
        end
    end
end, "InstantFishingMode")

makeToggle(catAutoFishing, "Enable Instant Fishing", function(on)
    isInstantFishingEnabled = on
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    
    if on then
        if currentInstantMode == "Fast" and instant then
            instant.Start()
        elseif currentInstantMode == "Perfect" and instant2 then
            instant2.Start()
        end
    else
        if instant then instant.Stop() end
        if instant2 then instant2.Stop() end
    end
end)

makeInput(catAutoFishing, "Fishing Delay", 1.30, function(v)
    fishingDelayValue = v
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    if instant then instant.Settings.MaxWaitTime = v end
    if instant2 then instant2.Settings.MaxWaitTime = v end
end)

makeInput(catAutoFishing, "Cancel Delay", 0.19, function(v)
    cancelDelayValue = v
    local instant = GetModule("instant")
    local instant2 = GetModule("instant2")
    if instant then instant.Settings.CancelDelay = v end
    if instant2 then instant2.Settings.CancelDelay = v end
end)

-- Blatant Tester Category
local catBlatantV2 = makeCategory(mainPage, "Blatant Tester", "🎯")

makeToggle(catBlatantV2, "Blatant Tester", function(on)
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then
        if on then blatantv2fix.Start() else blatantv2fix.Stop() end
    end
end)

makeInput(catBlatantV2, "Complete Delay", 0.5, function(v)
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then
        blatantv2fix.Settings.CompleteDelay = v
    end
end)

makeInput(catBlatantV2, "Cancel Delay", 0.1, function(v)
    local blatantv2fix = GetModule("blatantv2fix")
    if blatantv2fix then
        blatantv2fix.Settings.CancelDelay = v
    end
end)

-- Blatant V1 Category
local catBlatantV1 = makeCategory(mainPage, "Blatant V1", "💀")

makeToggle(catBlatantV1, "Blatant Mode", function(on)
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then
        if on then blatantv1.Start() else blatantv1.Stop() end
    end
end)

makeInput(catBlatantV1, "Complete Delay", 0.05, function(v)
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then blatantv1.Settings.CompleteDelay = v end
end)

makeInput(catBlatantV1, "Cancel Delay", 0.1, function(v)
    local blatantv1 = GetModule("blatantv1")
    if blatantv1 then blatantv1.Settings.CancelDelay = v end
end)

-- Ultra Blatant V2 Category
local catUltraBlatant = makeCategory(mainPage, "Blatant V2", "⚡")

makeToggle(catUltraBlatant, "Ultra Blatant Mode", function(on)
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then
        if on then UltraBlatant.Start() else UltraBlatant.Stop() end
    end
end)

makeInput(catUltraBlatant, "Complete Delay", 0.05, function(v)
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then UltraBlatant.UpdateSettings(v, nil, nil) end
end)

makeInput(catUltraBlatant, "Cancel Delay", 0.1, function(v)
    local UltraBlatant = GetModule("UltraBlatant")
    if UltraBlatant then UltraBlatant.UpdateSettings(nil, v, nil) end
end)

-- Fast Auto Fishing Perfect Category
local catBlatantV2Fast = makeCategory(mainPage, "Fast Auto Fishing Perfect", "🔥")

makeToggle(catBlatantV2Fast, "Blatant Features", function(on)
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then
        if on then blatantv2.Start() else blatantv2.Stop() end
    end
end)

makeInput(catBlatantV2Fast, "Fishing Delay", 0.05, function(v)
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.FishingDelay = v end
end)

makeInput(catBlatantV2Fast, "Cancel Delay", 0.01, function(v)
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.CancelDelay = v end
end)

makeInput(catBlatantV2Fast, "Timeout Delay", 0.8, function(v)
    local blatantv2 = GetModule("blatantv2")
    if blatantv2 then blatantv2.Settings.TimeoutDelay = v end
end)

-- Support Features Category
local catSupport = makeCategory(mainPage, "Support Features", "🛠️")

makeToggle(catSupport, "No Fishing Animation", function(on)
    local NoFishingAnimation = GetModule("NoFishingAnimation")
    if NoFishingAnimation then
        if on then NoFishingAnimation.StartWithDelay() else NoFishingAnimation.Stop() end
    end
end)

makeToggle(catSupport, "Lock Position", function(on)
    local LockPosition = GetModule("LockPosition")
    local Notify = GetModule("Notify")
    if LockPosition then
        if on then
            LockPosition.Start()
            if Notify then Notify.Send("Lock Position", "Posisi dikunci!", 4) end
        else
            LockPosition.Stop()
            if Notify then Notify.Send("Lock Position", "Posisi dilepas!", 4) end
        end
    end
end)

makeToggle(catSupport, "Auto Equip Rod", function(on)
    local AutoEquipRod = GetModule("AutoEquipRod")
    local Notify = GetModule("Notify")
    if AutoEquipRod then
        if on then
            AutoEquipRod.Start()
            if Notify then Notify.Send("Auto Equip Rod", "Rod auto equip aktif!", 4) end
        else
            AutoEquipRod.Stop()
            if Notify then Notify.Send("Auto Equip Rod", "Auto equip dimatikan!", 4) end
        end
    end
end)

makeToggle(catSupport, "Disable Cutscenes", function(on)
    local DisableCutscenes = GetModule("DisableCutscenes")
    local Notify = GetModule("Notify")
    if DisableCutscenes then
        if on then
            local success = DisableCutscenes.Start()
            if Notify then
                if success then
                    Notify.Send("Disable Cutscenes", "✓ Cutscenes dimatikan!", 4)
                else
                    Notify.Send("Disable Cutscenes", "⚠ Sudah aktif!", 3)
                end
            end
        else
            local success = DisableCutscenes.Stop()
            if Notify then
                if success then
                    Notify.Send("Disable Cutscenes", "✓ Cutscenes normal.", 4)
                else
                    Notify.Send("Disable Cutscenes", "⚠ Sudah nonaktif!", 3)
                end
            end
        end
    end
end)

makeToggle(catSupport, "Disable Obtained Fish Notification", function(on)
    local DisableExtras = GetModule("DisableExtras")
    local Notify = GetModule("Notify")
    if DisableExtras then
        if on then
            DisableExtras.StartSmallNotification()
            if Notify then Notify.Send("Disable Notification", "✓ Notifikasi dinonaktifkan!", 4) end
        else
            DisableExtras.StopSmallNotification()
            if Notify then Notify.Send("Disable Notification", "Notifikasi aktif kembali.", 3) end
        end
    end
end)

makeToggle(catSupport, "Disable Skin Effect", function(on)
    local DisableExtras = GetModule("DisableExtras")
    local Notify = GetModule("Notify")
    if DisableExtras then
        if on then
            DisableExtras.StartSkinEffect()
            if Notify then Notify.Send("Disable Skin Effect", "✓ Skin effect dihapus!", 4) end
        else
            DisableExtras.StopSkinEffect()
            if Notify then Notify.Send("Disable Skin Effect", "Skin effect aktif kembali.", 3) end
        end
    end
end)

makeToggle(catSupport, "Walk On Water", function(on)
    local WalkOnWater = GetModule("WalkOnWater")
    local Notify = GetModule("Notify")
    if WalkOnWater then
        if on then
            WalkOnWater.Start()
            if Notify then Notify.Send("Walk On Water", "✓ Berjalan di air aktif!", 4) end
        else
            WalkOnWater.Stop()
            if Notify then Notify.Send("Walk On Water", "Walk on water dimatikan.", 3) end
        end
    end
end)

makeToggle(catSupport, "Good/Perfection Stable Mode", function(on)
    local GoodPerfectionStable = GetModule("GoodPerfectionStable")
    local Notify = GetModule("Notify")
    if GoodPerfectionStable then
        if on then
            GoodPerfectionStable.Start()
            if Notify then Notify.Send("Good/Perfection Stable", "Fitur dihidupkan!", 4) end
        else
            GoodPerfectionStable.Stop()
            if Notify then Notify.Send("Good/Perfection Stable", "Fitur dimatikan!", 4) end
        end
    end
end)

-- Auto Totem Category
local catAutoTotem = makeCategory(mainPage, "Auto Spawn 3X Totem", "🛠️")

makeButton(catAutoTotem, "Auto Totem 3X", function()
    local AutoTotem3X = GetModule("AutoTotem3X")
    local Notify = GetModule("Notify")
    if AutoTotem3X then
        if AutoTotem3X.IsRunning() then
            local success, message = AutoTotem3X.Stop()
            if success and Notify then
                Notify.Send("Auto Totem 3X", "⏹ " .. message, 4)
            end
        else
            local success, message = AutoTotem3X.Start()
            if Notify then
                if success then
                    Notify.Send("Auto Totem 3X", "▶ " .. message, 4)
                else
                    Notify.Send("Auto Totem 3X", "⚠ " .. message, 3)
                end
            end
        end
    end
end)

-- Skin Animation Category
local catSkin = makeCategory(mainPage, "Skin Animation", "✨")

makeButton(catSkin, "⚔️ Eclipse Katana", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("Eclipse")
        if success then
            if Notify then Notify.Send("Skin Animation", "⚔️ Eclipse Katana diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then
                SkinAnimation.Enable()
            end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

makeButton(catSkin, "🔱 Holy Trident", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("HolyTrident")
        if success then
            if Notify then Notify.Send("Skin Animation", "🔱 Holy Trident diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then
                SkinAnimation.Enable()
            end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

makeButton(catSkin, "💀 Soul Scythe", function()
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        local success = SkinAnimation.SwitchSkin("SoulScythe")
        if success then
            if Notify then Notify.Send("Skin Animation", "💀 Soul Scythe diaktifkan!", 4) end
            if not SkinAnimation.IsEnabled() then
                SkinAnimation.Enable()
            end
        elseif Notify then
            Notify.Send("Skin Animation", "⚠ Gagal mengganti skin!", 3)
        end
    end
end)

makeToggle(catSkin, "Enable Skin Animation", function(on)
    local SkinAnimation = GetModule("SkinAnimation")
    local Notify = GetModule("Notify")
    if SkinAnimation then
        if on then
            local success = SkinAnimation.Enable()
            if Notify then
                if success then
                    local currentSkin = SkinAnimation.GetCurrentSkin()
                    local icon = currentSkin == "Eclipse" and "⚔️" or (currentSkin == "HolyTrident" and "🔱" or "💀")
                    Notify.Send("Skin Animation", "✓ " .. icon .. " " .. currentSkin .. " aktif!", 4)
                else
                    Notify.Send("Skin Animation", "⚠ Sudah aktif!", 3)
                end
            end
        else
            local success = SkinAnimation.Disable()
            if Notify then
                if success then
                    Notify.Send("Skin Animation", "✓ Skin Animation dimatikan!", 4)
                else
                    Notify.Send("Skin Animation", "⚠ Sudah nonaktif!", 3)
                end
            end
        end
    end
end)

-- ⏸️ BAGIAN 4/6 SELESAI
-- Tunggu perintah "lanjut" untuk melanjutkan ke bagian 5/6

-- ============================================
-- BAGIAN 5/6: Teleport, Quest, Shop, Webhook & HideStats Pages
-- ============================================

-- TELEPORT PAGE
local TeleportModule = GetModule("TeleportModule")
local TeleportToPlayer = GetModule("TeleportToPlayer")
local SavedLocation = GetModule("SavedLocation")
local EventTeleport = GetModule("EventTeleportDynamic")

-- Location Teleport
if TeleportModule then
    local locationItems = {}
    for name, _ in pairs(TeleportModule.Locations) do
        table.insert(locationItems, name)
    end
    table.sort(locationItems)
    
    makeDropdown(teleportPage, "Teleport to Location", "📍", locationItems, function(selectedLocation)
        TeleportModule.TeleportTo(selectedLocation)
    end, "LocationTeleport")
end

-- Player Teleport with Auto Refresh
local playerDropdown
local function updatePlayerList()
    local playerItems = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(playerItems, player.Name)
        end
    end
    table.sort(playerItems)
    
    if playerDropdown and playerDropdown.Parent then
        playerDropdown:Destroy()
    end
    
    if TeleportToPlayer then
        playerDropdown = makeDropdown(teleportPage, "Teleport to Player", "👤", playerItems, function(selectedPlayer)
            TeleportToPlayer.TeleportTo(selectedPlayer)
        end, "PlayerTeleport")
    end
end

updatePlayerList()

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    updatePlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
    task.wait(0.1)
    updatePlayerList()
end)

-- Saved Location Category
local catSaved = makeCategory(teleportPage, "Saved Location", "⭐")

makeButton(catSaved, "Save Current Location", function()
    if SavedLocation then
        SavedLocation.Save()
        SendNotification("Saved Location", "Lokasi berhasil disimpan.", 3)
    end
end)

makeButton(catSaved, "Teleport Saved Location", function()
    if SavedLocation then
        if SavedLocation.Teleport() then
            SendNotification("Teleported", "Berhasil teleport ke lokasi tersimpan.", 3)
        else
            SendNotification("Error", "Tidak ada lokasi yang disimpan!", 3)
        end
    end
end)

makeButton(catSaved, "Reset Saved Location", function()
    if SavedLocation then
        SavedLocation.Reset()
        SendNotification("Reset", "Lokasi tersimpan telah dihapus.", 3)
    end
end)

-- Event Teleport Category
local catTeleport = makeCategory(teleportPage, "Event Teleport", "🎯")
local selectedEventName = nil

if EventTeleport then
    local eventNames = EventTeleport.GetEventNames() or {"- No events -"}
    
    makeDropdown(catTeleport, "Pilih Event", "📌", eventNames, function(selected)
        selectedEventName = selected
        SendNotification("Event", "Event dipilih: " .. tostring(selected), 3)
    end, "EventTeleport")
    
    makeToggle(catTeleport, "Enable Auto Teleport", function(on)
        if on then
            if selectedEventName and EventTeleport.HasCoords(selectedEventName) then
                EventTeleport.Start(selectedEventName)
                SendNotification("Auto Teleport", "Mulai auto teleport ke " .. selectedEventName, 4)
            else
                SendNotification("Auto Teleport", "Pilih event yang memiliki koordinat dulu!", 3)
            end
        else
            EventTeleport.Stop()
            SendNotification("Auto Teleport", "Auto teleport dihentikan.", 3)
        end
    end)
    
    makeButton(catTeleport, "Teleport Now", function()
        if selectedEventName then
            local ok = EventTeleport.TeleportNow(selectedEventName)
            if ok then
                SendNotification("Teleport", "Teleported ke " .. selectedEventName, 3)
            else
                SendNotification("Teleport", "Teleport gagal!", 3)
            end
        else
            SendNotification("Teleport", "Event belum dipilih!", 3)
        end
    end)
end

-- QUEST PAGE
local AutoQuestModule = GetModule("AutoQuestModule")
local AutoTemple = GetModule("AutoTemple")
local TempleDataReader = GetModule("TempleDataReader")

-- Deep Sea Quest Category
local catDeepSea = makeCategory(questPage, "Deep Sea Quest (Ghostfinn Rod)")

local deepSeaProgressFrame = new("Frame", {
    Parent = catDeepSea,
    Size = UDim2.new(1, 0, 0, 160),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = deepSeaProgressFrame, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = deepSeaProgressFrame, Color = colors.border, Thickness = 1, Transparency = 0.7})

local deepSeaLabel = new("TextLabel", {
    Parent = deepSeaProgressFrame,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = AutoQuestModule and AutoQuestModule.GetQuestInfo("DeepSeaQuest") or "Loading...",
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

makeButton(catDeepSea, "Refresh Progress", function()
    if AutoQuestModule then
        deepSeaLabel.Text = AutoQuestModule.GetQuestInfo("DeepSeaQuest")
        SendNotification("Refresh", "Progress updated!", 2)
    end
end)

makeToggle(catDeepSea, "Auto Teleport", function(on)
    if AutoQuestModule then
        if on then
            AutoQuestModule.StartAutoTeleport("DeepSeaQuest")
            SendNotification("Auto Teleport", "Deep Sea Quest Auto Teleport AKTIF!", 2)
        else
            AutoQuestModule.StopAutoTeleport()
            SendNotification("Auto Teleport", "Deep Sea Quest Auto Teleport DIMATIKAN!", 2)
        end
        deepSeaLabel.Text = AutoQuestModule.GetQuestInfo("DeepSeaQuest")
    end
end)

-- Element Quest Category
local catElement = makeCategory(questPage, "Element Quest (Element Rod)")

local elementProgressFrame = new("Frame", {
    Parent = catElement,
    Size = UDim2.new(1, 0, 0, 160),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = elementProgressFrame, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = elementProgressFrame, Color = colors.border, Thickness = 1, Transparency = 0.7})

local elementLabel = new("TextLabel", {
    Parent = elementProgressFrame,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = AutoQuestModule and AutoQuestModule.GetQuestInfo("ElementQuest") or "Loading...",
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

makeButton(catElement, "Refresh Progress", function()
    if AutoQuestModule then
        elementLabel.Text = AutoQuestModule.GetQuestInfo("ElementQuest")
        SendNotification("Refresh", "Progress updated!", 2)
    end
end)

makeToggle(catElement, "Auto Teleport", function(on)
    if AutoQuestModule then
        if on then
            AutoQuestModule.StartAutoTeleport("ElementQuest")
            SendNotification("Auto Teleport", "Element Quest Auto Teleport AKTIF!", 2)
        else
            AutoQuestModule.StopAutoTeleport()
            SendNotification("Auto Teleport", "Element Quest Auto Teleport DIMATIKAN!", 2)
        end
        elementLabel.Text = AutoQuestModule.GetQuestInfo("ElementQuest")
    end
end)

-- Real-time Quest Updates
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            if deepSeaLabel and deepSeaLabel.Parent and AutoQuestModule then
                local questInfo = AutoQuestModule.GetQuestInfo("DeepSeaQuest")
                if questInfo then
                    deepSeaLabel.Text = questInfo
                end
            end
        end)
        pcall(function()
            if elementLabel and elementLabel.Parent and AutoQuestModule then
                local questInfo = AutoQuestModule.GetQuestInfo("ElementQuest")
                if questInfo then
                    elementLabel.Text = questInfo
                end
            end
        end)
    end
end)

-- Temple Quest Category
local catTemple = makeCategory(questPage, "Sacred Temple", "⛩️")

local templeProgressFrame = new("Frame", {
    Parent = catTemple,
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = templeProgressFrame, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = templeProgressFrame, Color = colors.border, Thickness = 1, Transparency = 0.7})

local templeLabel = new("TextLabel", {
    Parent = templeProgressFrame,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "Loading Temple Status...",
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

local function BuildTempleText(status)
    return "Sacred Temple Progress:\n\n" ..
           "- Crescent Artifact: " .. (status["Crescent Artifact"] and "✔️" or "❌") .. "\n" ..
           "- Arrow Artifact: " .. (status["Arrow Artifact"] and "✔️" or "❌") .. "\n" ..
           "- Diamond Artifact: " .. (status["Diamond Artifact"] and "✔️" or "❌") .. "\n" ..
           "- Hourglass Artifact: " .. (status["Hourglass Diamond Artifact"] and "✔️" or "❌")
end

if TempleDataReader then
    TempleDataReader.OnTempleUpdate(function(status)
        templeLabel.Text = BuildTempleText(status)
    end)
end

makeButton(catTemple, "Refresh Progress", function()
    if TempleDataReader then
        local status = TempleDataReader.GetTempleStatus()
        templeLabel.Text = BuildTempleText(status)
        SendNotification("Refresh", "Temple progress updated!", 2)
    end
end)

makeToggle(catTemple, "Auto Open Sacred Temple", function(on)
    if AutoTemple then
        if on then
            AutoTemple.Start()
            SendNotification("Temple", "Auto Sacred Temple AKTIF!", 2)
        else
            AutoTemple.Stop()
            SendNotification("Temple", "Auto Sacred Temple DIMATIKAN!", 2)
        end
        
        if TempleDataReader then
            templeLabel.Text = BuildTempleText(TempleDataReader.GetTempleStatus())
        end
    end
end)

-- SHOP PAGE
local AutoSell = GetModule("AutoSell")
local AutoSellTimer = GetModule("AutoSellTimer")
local MerchantSystem = GetModule("MerchantSystem")
local RemoteBuyer = GetModule("RemoteBuyer")
local AutoBuyWeather = GetModule("AutoBuyWeather")

-- Sell All Category
local catSell = makeCategory(shopPage, "Sell All", "💰")

makeButton(catSell, "Sell All Now", function()
    if AutoSell and AutoSell.SellOnce then
        AutoSell.SellOnce()
    end
end)

-- Auto Sell Timer Category
local catTimer = makeCategory(shopPage, "Auto Sell Timer", "⏰")

makeInput(catTimer, "Sell Interval (seconds)", 5, function(value)
    if AutoSellTimer then
        AutoSellTimer.SetInterval(value)
    end
end)

makeToggle(catTimer, "Auto Sell Timer", function(on)
    if AutoSellTimer then
        if on then
            AutoSellTimer.Start(AutoSellTimer.Interval)
        else
            AutoSellTimer.Stop()
        end
    end
end)

-- Auto Buy Weather Category
local catWeather = makeCategory(shopPage, "Auto Buy Weather", "🌦️")

if AutoBuyWeather then
    local weatherCheckboxContainer = new("Frame", {
        Parent = catWeather,
        Size = UDim2.new(1, 0, 0, 210),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    new("UICorner", {Parent = weatherCheckboxContainer, CornerRadius = UDim.new(0, 8)})
    new("UIStroke", {Parent = weatherCheckboxContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})
    
    local selectedWeathers = {}
    local checkboxes = {}
    
    local function createWeatherCheckbox(parent, weatherName, yPos)
        local checkboxRow = new("Frame", {
            Parent = parent,
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, yPos),
            BackgroundColor3 = colors.bg3,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 8
        })
        new("UICorner", {Parent = checkboxRow, CornerRadius = UDim.new(0, 6)})
        
        local checkbox = new("TextButton", {
            Parent = checkboxRow,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 8, 0, 3),
            BackgroundColor3 = colors.bg1,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 9
        })
        new("UICorner", {Parent = checkbox, CornerRadius = UDim.new(0, 4)})
        
        local checkmark = new("TextLabel", {
            Parent = checkbox,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✓",
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = colors.text,
            Visible = false,
            ZIndex = 10
        })
        
        local label = new("TextLabel", {
            Parent = checkboxRow,
            Size = UDim2.new(1, -45, 1, 0),
            Position = UDim2.new(0, 40, 0, 0),
            BackgroundTransparency = 1,
            Text = weatherName,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = colors.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9
        })
        
        local isSelected = false
        checkbox.MouseButton1Click:Connect(function()
            isSelected = not isSelected
            checkmark.Visible = isSelected
            
            if isSelected then
                table.insert(selectedWeathers, weatherName)
                TweenService:Create(checkbox, TweenInfo.new(0.25), {BackgroundColor3 = colors.primary}):Play()
            else
                local idx = table.find(selectedWeathers, weatherName)
                if idx then table.remove(selectedWeathers, idx) end
                TweenService:Create(checkbox, TweenInfo.new(0.25), {BackgroundColor3 = colors.bg1}):Play()
            end
            
            if AutoBuyWeather then
                AutoBuyWeather.SetSelected(selectedWeathers)
            end
        end)
        
        return {checkbox = checkbox, checkmark = checkmark, isSelected = function() return isSelected end}
    end
    
    for i, weather in ipairs(AutoBuyWeather.AllWeathers) do
        checkboxes[weather] = createWeatherCheckbox(weatherCheckboxContainer, weather, (i - 1) * 33 + 5)
    end
    
    makeToggle(catWeather, "Enable Auto Weather", function(on)
        if on then
            if #selectedWeathers == 0 then
                SendNotification("Auto Weather", "Pilih minimal 1 cuaca!", 3)
                return
            end
            AutoBuyWeather.Start()
        else
            AutoBuyWeather.Stop()
        end
    end)
end

-- Merchant Category
local catMerchant = makeCategory(shopPage, "Remote Merchant", "🛒")

makeButton(catMerchant, "Open Merchant", function()
    if MerchantSystem then
        MerchantSystem.Open()
        SendNotification("Merchant", "Merchant dibuka!", 3)
    end
end)

makeButton(catMerchant, "Close Merchant", function()
    if MerchantSystem then
        MerchantSystem.Close()
        SendNotification("Merchant", "Merchant ditutup!", 3)
    end
end)

-- Buy Rod Category
local catRod = makeCategory(shopPage, "Buy Rod", "🎣")

if RemoteBuyer then
    local RodData = {
        ["Chrome Rod"] = {id = 7, price = 437000},
        ["Lucky Rod"] = {id = 4, price = 15000},
        ["Starter Rod"] = {id = 1, price = 50},
        ["Carbon Rod"] = {id = 76, price = 750},
        ["Astral Rod"] = {id = 5, price = 1000000},
    }
    
    local RodList = {}
    local RodMap = {}
    for rodName, info in pairs(RodData) do
        local display = rodName .. " (" .. tostring(info.price) .. ")"
        table.insert(RodList, display)
        RodMap[display] = rodName
    end
    
    local SelectedRod = nil
    
    makeDropdown(catRod, "Select Rod", "🎣", RodList, function(displayName)
        SelectedRod = RodMap[displayName]
        SendNotification("Rod Selected", "Rod: " .. SelectedRod, 3)
    end, "RodDropdown")
    
    makeButton(catRod, "BUY SELECTED ROD", function()
        if SelectedRod then
            RemoteBuyer.BuyRod(RodData[SelectedRod].id)
            SendNotification("Buy Rod", "Membeli " .. SelectedRod .. "...", 3)
        else
            SendNotification("Buy Rod", "Pilih rod dulu!", 3)
        end
    end)
end

-- Buy Bait Category
local catBait = makeCategory(shopPage, "Buy Bait", "🪱")

if RemoteBuyer then
    local BaitData = {
        ["Chroma Bait"] = {id = 6, price = 290000},
        ["Luck Bait"] = {id = 2, price = 1000},
        ["Midnight Bait"] = {id = 3, price = 3000},
    }
    
    local BaitList = {}
    local BaitMap = {}
    for baitName, info in pairs(BaitData) do
        local display = baitName .. " (" .. tostring(info.price) .. ")"
        table.insert(BaitList, display)
        BaitMap[display] = baitName
    end
    
    local SelectedBait = nil
    
    makeDropdown(catBait, "Select Bait", "🪱", BaitList, function(displayName)
        SelectedBait = BaitMap[displayName]
        SendNotification("Bait Selected", "Bait: " .. SelectedBait, 3)
    end, "BaitDropdown")
    
    makeButton(catBait, "BUY SELECTED BAIT", function()
        if SelectedBait then
            RemoteBuyer.BuyBait(BaitData[SelectedBait].id)
            SendNotification("Buy Bait", "Membeli " .. SelectedBait .. "...", 3)
        else
            SendNotification("Buy Bait", "Pilih bait dulu!", 3)
        end
    end)
end

-- ⏸️ BAGIAN 5/6 SELESAI (PART 1)
-- Lanjutan Webhook & HideStats di update berikutnya...

-- ============================================
-- WEBHOOK PAGE - FIXED WITH PROPER MODULE LOADING
-- ============================================
local WebhookModule = GetModule("Webhook")

local catWebhook = makeCategory(webhookPage, "Discord Webhook Fish Caught", "🔔")

-- Info Container
local webhookInfoContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 85),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = webhookInfoContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = webhookInfoContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local webhookInfoText = new("TextLabel", {
    Parent = webhookInfoContainer,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "📌 WEBHOOK INFO\n━━━━━━━━━━━━━━━━━━━━━━\nKirim notifikasi Discord saat menangkap ikan!\nMasukkan Discord Webhook URL di bawah.",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

-- Webhook URL Input
local currentWebhookURL = ""
local webhookInputContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = webhookInputContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = webhookInputContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local webhookLabel = new("TextLabel", {
    Parent = webhookInputContainer,
    Size = UDim2.new(1, -20, 0, 22),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "Discord Webhook URL",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8
})

local webhookTextBox = new("TextBox", {
    Parent = webhookInputContainer,
    Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.new(0, 10, 0, 35),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    PlaceholderColor3 = colors.textDimmer,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 8
})
new("UICorner", {Parent = webhookTextBox, CornerRadius = UDim.new(0, 6)})
new("UIStroke", {Parent = webhookTextBox, Color = colors.border, Thickness = 1, Transparency = 0.9})
new("UIPadding", {Parent = webhookTextBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

webhookTextBox.FocusLost:Connect(function()
    currentWebhookURL = webhookTextBox.Text
    if WebhookModule and currentWebhookURL ~= "" then
        pcall(function()
            WebhookModule:SetWebhookURL(currentWebhookURL)
        end)
        SendNotification("Webhook", "Webhook URL tersimpan!", 2)
    end
end)

-- Discord User ID Input
local currentDiscordID = ""
local discordIDContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = discordIDContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = discordIDContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local discordIDLabel = new("TextLabel", {
    Parent = discordIDContainer,
    Size = UDim2.new(1, -20, 0, 22),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "Discord User ID (Optional - untuk mention)",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8
})

local discordIDTextBox = new("TextBox", {
    Parent = discordIDContainer,
    Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.new(0, 10, 0, 35),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "123456789012345678",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    PlaceholderColor3 = colors.textDimmer,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 8
})
new("UICorner", {Parent = discordIDTextBox, CornerRadius = UDim.new(0, 6)})
new("UIStroke", {Parent = discordIDTextBox, Color = colors.border, Thickness = 1, Transparency = 0.9})
new("UIPadding", {Parent = discordIDTextBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

discordIDTextBox.FocusLost:Connect(function()
    currentDiscordID = discordIDTextBox.Text
    if WebhookModule then
        pcall(function()
            WebhookModule:SetDiscordUserID(currentDiscordID)
        end)
        if currentDiscordID ~= "" then
            SendNotification("Webhook", "Discord ID tersimpan!", 2)
        end
    end
end)

-- Rarity Filter
local rarityInfoContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = rarityInfoContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = rarityInfoContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local rarityInfoText = new("TextLabel", {
    Parent = rarityInfoContainer,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "RARITY FILTER\n━━━━━━━━━━━━━━━━━━━━━━\nPilih rarity ikan yang akan dikirim ke Discord.\nKlik pada rarity untuk toggle ON/OFF.\nKosongkan untuk kirim semua rarity.",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

local AllRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}
local selectedRarities = {}

local checkboxContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 240),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = checkboxContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = checkboxContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local rarityColors = {
    Common = Color3.fromRGB(150, 150, 150),
    Uncommon = Color3.fromRGB(85, 255, 85),
    Rare = Color3.fromRGB(85, 170, 255),
    Epic = Color3.fromRGB(170, 85, 255),
    Legendary = Color3.fromRGB(255, 200, 85),
    Mythic = Color3.fromRGB(255, 85, 85),
    SECRET = Color3.fromRGB(85, 255, 220)
}

local function createRarityCheckbox(parent, rarityName, yPos)
    local checkboxRow = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 8
    })
    new("UICorner", {Parent = checkboxRow, CornerRadius = UDim.new(0, 6)})
    
    local checkbox = new("TextButton", {
        Parent = checkboxRow,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 8, 0, 3),
        BackgroundColor3 = colors.bg1,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 9
    })
    new("UICorner", {Parent = checkbox, CornerRadius = UDim.new(0, 4)})
    
    local checkboxStroke = new("UIStroke", {
        Parent = checkbox,
        Color = rarityColors[rarityName] or colors.primary,
        Thickness = 2,
        Transparency = 0.7
    })
    
    local checkmark = new("TextLabel", {
        Parent = checkbox,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "✓",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = colors.text,
        Visible = false,
        ZIndex = 10
    })
    
    local label = new("TextLabel", {
        Parent = checkboxRow,
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Text = rarityName,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextTransparency = 0.1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })
    
    local isSelected = false
    
    checkbox.MouseButton1Click:Connect(function()
        isSelected = not isSelected
        checkmark.Visible = isSelected
        
        if isSelected then
            if not table.find(selectedRarities, rarityName) then
                table.insert(selectedRarities, rarityName)
            end
            TweenService:Create(checkbox, TweenInfo.new(0.25), {
                BackgroundColor3 = rarityColors[rarityName],
                BackgroundTransparency = 0.2
            }):Play()
        else
            local idx = table.find(selectedRarities, rarityName)
            if idx then table.remove(selectedRarities, idx) end
            TweenService:Create(checkbox, TweenInfo.new(0.25), {
                BackgroundColor3 = colors.bg1,
                BackgroundTransparency = 0.4
            }):Play()
        end
        
        if WebhookModule then
            pcall(function()
                WebhookModule:SetEnabledRarities(selectedRarities)
            end)
        end
    end)
    
    return {checkbox = checkbox, checkmark = checkmark, isSelected = function() return isSelected end, setSelected = function(val)
        if isSelected ~= val then
            checkbox.MouseButton1Click:Fire()
        end
    end}
end

local checkboxes = {}
for i, rarityName in ipairs(AllRarities) do
    checkboxes[rarityName] = createRarityCheckbox(checkboxContainer, rarityName, (i - 1) * 33 + 5)
end

makeButton(catWebhook, "✓ Select All Rarities", function()
    for _, rarity in ipairs(AllRarities) do
        if checkboxes[rarity] and not checkboxes[rarity].isSelected() then
            checkboxes[rarity].setSelected(true)
        end
    end
    SendNotification("Rarity Filter", "All rarities selected!", 2)
end)

makeButton(catWebhook, "✗ Clear All Selections", function()
    for _, rarity in ipairs(AllRarities) do
        if checkboxes[rarity] and checkboxes[rarity].isSelected() then
            checkboxes[rarity].setSelected(false)
        end
    end
    SendNotification("Rarity Filter", "Filter cleared!", 2)
end)

makeButton(catWebhook, "⭐ Select High Rarity Only", function()
    local highRarities = {"Epic", "Legendary", "Mythic", "SECRET"}
    for _, rarity in ipairs(AllRarities) do
        if checkboxes[rarity] then
            local shouldSelect = table.find(highRarities, rarity) ~= nil
            if checkboxes[rarity].isSelected() ~= shouldSelect then
                checkboxes[rarity].setSelected(shouldSelect)
            end
        end
    end
    SendNotification("Rarity Filter", "High rarities selected!", 3)
end)

makeToggle(catWebhook, "Enable Webhook", function(on)
    if not WebhookModule then
        SendNotification("Error", "Webhook module tidak tersedia!", 3)
        return
    end
    
    if on then
        if currentWebhookURL == "" then
            SendNotification("Error", "Masukkan Webhook URL dulu!", 3)
            return
        end
        
        pcall(function()
            WebhookModule:SetWebhookURL(currentWebhookURL)
            if currentDiscordID ~= "" then
                WebhookModule:SetDiscordUserID(currentDiscordID)
            end
            WebhookModule:SetEnabledRarities(selectedRarities)
            WebhookModule:Start()
        end)
        
        local filterInfo = #selectedRarities > 0 
            and (" (Filter: " .. table.concat(selectedRarities, ", ") .. ")")
            or " (All rarities)"
        SendNotification("Webhook", "Webhook logging aktif!" .. filterInfo, 4)
    else
        pcall(function()
            WebhookModule:Stop()
        end)
        SendNotification("Webhook", "Webhook logging dinonaktifkan.", 3)
    end
end)

makeButton(catWebhook, "Test Webhook Connection", function()
    if currentWebhookURL == "" then
        SendNotification("Error", "Masukkan Webhook URL dulu!", 3)
        return
    end
    
    local HttpService = game:GetService("HttpService")
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    
    if requestFunc then
        local filterText = #selectedRarities > 0 
            and ("\n**Active Filter:** " .. table.concat(selectedRarities, ", "))
            or "\n**Filter:** All rarities enabled"
        
        local testPayload = {
            embeds = {{
                title = "🎣 Webhook Test Successful!",
                description = "Your Discord webhook is working correctly!\n\nQuix GUI is ready to send fish notifications." .. filterText,
                color = 3447003,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        local success = pcall(function()
            requestFunc({
                Url = currentWebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(testPayload)
            })
        end)
        
        if success then
            SendNotification("Success", "Test message sent! Check Discord.", 4)
        else
            SendNotification("Error", "Test failed!", 3)
        end
    else
        SendNotification("Error", "HTTP request tidak didukung!", 3)
    end
end)

-- Status Display
local statusContainer = new("Frame", {
    Parent = catWebhook,
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = statusContainer, CornerRadius = UDim.new(0, 8)})

local statusText = new("TextLabel", {
    Parent = statusContainer,
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "Status: Ready",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.warning,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8
})

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if WebhookModule and statusText and statusText.Parent then
                local isRunning = false
                pcall(function()
                    isRunning = WebhookModule:IsRunning()
                end)
                
                if isRunning then
                    statusText.TextColor3 = colors.success
                    local filterInfo = #selectedRarities > 0 
                        and (" | " .. #selectedRarities .. " rarities")
                        or " | All rarities"
                    statusText.Text = "Status: 🟢 Active & Monitoring" .. filterInfo
                else
                    statusText.TextColor3 = colors.warning
                    statusText.Text = "Status: 🟡 Ready (Not Active)"
                end
            elseif statusText and statusText.Parent then
                statusText.TextColor3 = colors.danger
                statusText.Text = "Status: 🔴 Module Not Loaded"
            end
        end)
    end
end)

-- ⏸️ BAGIAN 5/6 SELESAI
-- Tunggu perintah "lanjut" untuk melanjutkan ke bagian 6/6 (FINAL)

-- ============================================
-- BAGIAN 6/6: HideStats, Camera, Settings, Info Pages + Controls & Animations (FINAL)
-- ============================================

-- CAMERA VIEW PAGE
local FreecamModule = GetModule("FreecamModule")
local UnlimitedZoomModule = GetModule("UnlimitedZoomModule")

if FreecamModule then
    FreecamModule.SetMainGuiName("QuixGUI_Galaxy")
end

-- Unlimited Zoom Category
local catZoom = makeCategory(cameraViewPage, "Unlimited Zoom", "🔭")

makeToggle(catZoom, "Enable Unlimited Zoom", function(on)
    if UnlimitedZoomModule then
        if on then
            local success = UnlimitedZoomModule.Enable()
            if success then
                SendNotification("Zoom", "Unlimited Zoom aktif!", 4)
            end
        else
            UnlimitedZoomModule.Disable()
            SendNotification("Zoom", "Unlimited Zoom nonaktif.", 3)
        end
    end
end)

-- Freecam Category
local catFreecam = makeCategory(cameraViewPage, "Freecam Camera", "📷")

if not isMobile then
    local noteContainer = new("Frame", {
        Parent = catFreecam,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    new("UICorner", {Parent = noteContainer, CornerRadius = UDim.new(0, 8)})
    
    local noteText = new("TextLabel", {
        Parent = noteContainer,
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Text = "📌 FREECAM CONTROLS (PC)\n1. Toggle freecam on\n2. Press F3 to activate\n3. WASD - Move | Mouse - Rotate",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 8
    })
end

makeToggle(catFreecam, "Enable Freecam", function(on)
    if FreecamModule then
        if on then
            if not isMobile then
                FreecamModule.EnableF3Keybind(true)
                SendNotification("Freecam", "Freecam siap! Tekan F3.", 4)
            else
                FreecamModule.Start()
                SendNotification("Freecam", "Freecam aktif!", 4)
            end
        else
            FreecamModule.EnableF3Keybind(false)
            SendNotification("Freecam", "Freecam nonaktif.", 3)
        end
    end
end)

makeInput(catFreecam, "Movement Speed", 50, function(value)
    if FreecamModule then
        FreecamModule.SetSpeed(value)
    end
end)

makeInput(catFreecam, "Mouse Sensitivity", 0.3, function(value)
    if FreecamModule then
        FreecamModule.SetSensitivity(value)
    end
end)

-- SETTINGS PAGE
local AntiAFK = GetModule("AntiAFK")
local UnlockFPS = GetModule("UnlockFPS")
local FPSBooster = GetModule("FPSBooster")
local HideStats = GetModule("HideStats")

-- Anti-AFK Category
local catAFK = makeCategory(settingsPage, "Anti-AFK Protection", "🧍‍♂️")

makeToggle(catAFK, "Enable Anti-AFK", function(on)
    if AntiAFK then
        if on then AntiAFK.Start() else AntiAFK.Stop() end
    end
end)

-- Server Features Category
local catServer = makeCategory(settingsPage, "Server Features", "🔄")

makeButton(catServer, "Rejoin Server", function()
    local TeleportService = game:GetService("TeleportService")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
    SendNotification("Rejoin", "Teleporting to new server...", 3)
end)

-- FPS Booster Category
local catBoost = makeCategory(settingsPage, "FPS Booster", "⚡")

makeToggle(catBoost, "Enable FPS Booster", function(on)
    if FPSBooster then
        if on then
            FPSBooster.Enable()
            SendNotification("FPS Booster", "FPS Booster diaktifkan!", 3)
        else
            FPSBooster.Disable()
            SendNotification("FPS Booster", "FPS Booster dimatikan.", 3)
        end
    end
end)

-- FPS Unlocker Category
local catFPS = makeCategory(settingsPage, "FPS Unlocker", "🎞️")

makeDropdown(catFPS, "Select FPS Limit", "⚙️", {"60 FPS", "90 FPS", "120 FPS", "240 FPS"}, function(selected)
    local fpsValue = tonumber(selected:match("%d+"))
    if fpsValue and UnlockFPS then
        UnlockFPS.SetCap(fpsValue)
    end
end, "FPSDropdown")

-- ============================================
-- HIDE STATS CATEGORY - FIXED WITH PROPER MODULE LOADING
-- ============================================

local catHideStats = makeCategory(settingsPage, "Hide Stats Identifier", "👤")

-- INFO CONTAINER
local hideStatsInfoContainer = new("Frame", {
    Parent = catHideStats,
    Size = UDim2.new(1, 0, 0, 85),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = hideStatsInfoContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {
    Parent = hideStatsInfoContainer,
    Color = colors.border,
    Thickness = 1,
    Transparency = 0.95
})

local hideStatsInfoText = new("TextLabel", {
    Parent = hideStatsInfoContainer,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "📌 HIDE STATS INFO\n━━━━━━━━━━━━━━━━━━━━━━\nSembunyikan nama dan level asli Anda!\nMasukkan fake name & level di bawah.",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 8
})

-- FAKE NAME INPUT
local currentFakeName = "Guest"

local fakeNameContainer = new("Frame", {
    Parent = catHideStats,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = fakeNameContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = fakeNameContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local fakeNameLabel = new("TextLabel", {
    Parent = fakeNameContainer,
    Size = UDim2.new(1, -20, 0, 22),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "Fake Name",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8
})

local fakeNameTextBox = new("TextBox", {
    Parent = fakeNameContainer,
    Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.new(0, 10, 0, 35),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Enter fake name...",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    PlaceholderColor3 = colors.textDimmer,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 8
})
new("UICorner", {Parent = fakeNameTextBox, CornerRadius = UDim.new(0, 6)})
new("UIStroke", {Parent = fakeNameTextBox, Color = colors.border, Thickness = 1, Transparency = 0.9})
new("UIPadding", {Parent = fakeNameTextBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

fakeNameTextBox.FocusLost:Connect(function()
    local value = fakeNameTextBox.Text
    if value and value ~= "" then
        currentFakeName = value
        
        if HideStats then
            local success, err = pcall(function()
                HideStats.SetFakeName(value)
            end)
            
            if success then
                SendNotification("Hide Stats", "Fake name set: " .. value, 2)
                print("✅ Fake name updated:", value)
            else
                warn("❌ Failed to set fake name:", err)
                SendNotification("Error", "Gagal set fake name!", 2)
            end
        end
    end
end)

-- FAKE LEVEL INPUT
local currentFakeLevel = "1"

local fakeLevelContainer = new("Frame", {
    Parent = catHideStats,
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = colors.bg2,
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 7
})
new("UICorner", {Parent = fakeLevelContainer, CornerRadius = UDim.new(0, 8)})
new("UIStroke", {Parent = fakeLevelContainer, Color = colors.border, Thickness = 1, Transparency = 0.95})

local fakeLevelLabel = new("TextLabel", {
    Parent = fakeLevelContainer,
    Size = UDim2.new(1, -20, 0, 22),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "Fake Level",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 8
})

local fakeLevelTextBox = new("TextBox", {
    Parent = fakeLevelContainer,
    Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.new(0, 10, 0, 35),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Enter fake level...",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = colors.text,
    TextTransparency = 0.2,
    PlaceholderColor3 = colors.textDimmer,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 8
})
new("UICorner", {Parent = fakeLevelTextBox, CornerRadius = UDim.new(0, 6)})
new("UIStroke", {Parent = fakeLevelTextBox, Color = colors.border, Thickness = 1, Transparency = 0.9})
new("UIPadding", {Parent = fakeLevelTextBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

fakeLevelTextBox.FocusLost:Connect(function()
    local value = fakeLevelTextBox.Text
    if value and value ~= "" then
        currentFakeLevel = value
        
        if HideStats then
            local success, err = pcall(function()
                HideStats.SetFakeLevel(value)
            end)
            
            if success then
                SendNotification("Hide Stats", "Fake level set: " .. value, 2)
                print("✅ Fake level updated:", value)
            else
                warn("❌ Failed to set fake level:", err)
                SendNotification("Error", "Gagal set fake level!", 2)
            end
        end
    end
end)

-- TOGGLE ENABLE HIDE STATS
makeToggle(catHideStats, "⚡ Enable Hide Stats", function(on)
    if not HideStats then
        SendNotification("Error", "Hide Stats module tidak tersedia!", 3)
        warn("❌ HideStats module not loaded")
        return
    end
    
    if on then
        local success, err = pcall(function()
            -- Set fake name terlebih dahulu
            if currentFakeName ~= "" and currentFakeName ~= "Guest" then
                HideStats.SetFakeName(currentFakeName)
                print("🔧 Setting fake name:", currentFakeName)
            end
            
            -- Set fake level
            if currentFakeLevel ~= "" and currentFakeLevel ~= "1" then
                HideStats.SetFakeLevel(currentFakeLevel)
                print("🔧 Setting fake level:", currentFakeLevel)
            end
            
            -- Enable Hide Stats
            HideStats.Enable()
            print("🔧 Enabling Hide Stats...")
        end)
        
        if success then
            SendNotification("Hide Stats", "✓ Hide Stats aktif!\nName: " .. currentFakeName .. " | Level: " .. currentFakeLevel, 4)
            print("✅ Hide Stats enabled successfully!")
            print("   - Fake Name:", currentFakeName)
            print("   - Fake Level:", currentFakeLevel)
        else
            SendNotification("Error", "Gagal enable Hide Stats: " .. tostring(err), 3)
            warn("❌ Hide Stats enable failed:", err)
        end
    else
        local success, err = pcall(function()
            HideStats.Disable()
        end)
        
        if success then
            SendNotification("Hide Stats", "✓ Hide Stats dimatikan!", 3)
            print("⏹ Hide Stats disabled")
        else
            SendNotification("Error", "Gagal disable Hide Stats: " .. tostring(err), 3)
            warn("❌ Hide Stats disable failed:", err)
        end
    end
end)

-- INFO PAGE
local infoContainer = new("Frame", {
    Parent = infoPage,
    Size = UDim2.new(1, 0, 0, 200),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = infoContainer, CornerRadius = UDim.new(0, 8)})

local infoText = new("TextLabel", {
    Parent = infoContainer,
    Size = UDim2.new(1, -24, 0, 100),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "# Quix v4.2.0\nFree Not For Sale\n━━━━━━━━━━━━━━━━━━━━━━\nCreated by Beee\nRefined Edition 2024",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 7
})

local linkButton = new("TextButton", {
    Parent = infoContainer,
    Size = UDim2.new(1, -24, 0, 25),
    Position = UDim2.new(0, 12, 0, 115),
    BackgroundTransparency = 1,
    Text = "🔗 Discord: https://discord.gg/6Rpvm2gQ",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Color3.fromRGB(88, 101, 242),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 7
})

linkButton.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/6Rpvm2gQ")
    linkButton.Text = "✅ Link copied to clipboard!"
    task.wait(2)
    linkButton.Text = "🔗 Discord: https://discord.gg/6Rpvm2gQ"
end)

-- Module Status Display
local moduleStatusContainer = new("Frame", {
    Parent = infoPage,
    Size = UDim2.new(1, 0, 0, 150),
    BackgroundColor3 = colors.bg3,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 6
})
new("UICorner", {Parent = moduleStatusContainer, CornerRadius = UDim.new(0, 8)})

local moduleStatusText = new("TextLabel", {
    Parent = moduleStatusContainer,
    Size = UDim2.new(1, -24, 1, -24),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text = "Loading module status...",
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextColor3 = colors.text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 7
})

task.spawn(function()
    task.wait(0.5)
    pcall(function()
        if moduleStatusText and moduleStatusText.Parent then
            local statusText = "📦 MODULE STATUS (" .. loadedModules .. "/" .. totalModules .. " loaded)\n━━━━━━━━━━━━━━━━━━━━━━\n"
            
            -- Sort modules for better readability
            local sortedModules = {}
            for name, status in pairs(ModuleStatus) do
                table.insert(sortedModules, {name = name, status = status})
            end
            table.sort(sortedModules, function(a, b) return a.name < b.name end)
            
            for _, moduleInfo in ipairs(sortedModules) do
                statusText = statusText .. moduleInfo.status .. " " .. moduleInfo.name .. "\n"
            end
            
            moduleStatusText.Text = statusText
        end
    end)
end)

-- ============================================
-- MINIMIZE SYSTEM
-- ============================================
local minimized = false
local icon
local savedIconPos = UDim2.new(0, 20, 0, 100)

local function createMinimizedIcon()
    if icon then return end
    
    icon = new("ImageLabel", {
        Parent = gui,
        Size = UDim2.new(0, 50, 0, 50),
        Position = savedIconPos,
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Image = "rbxassetid://111416780887356",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 100
    })
    new("UICorner", {Parent = icon, CornerRadius = UDim.new(0, 10)})
    
    local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
    
    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragMoved, dragStart, startPos = true, false, input.Position, icon.Position
        end
    end)
    
    icon.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.sqrt(delta.X^2 + delta.Y^2) > 5 then dragMoved = true end
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            icon.Position = newPos
        end
    end)
    
    icon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                savedIconPos = icon.Position
                if not dragMoved then
                    bringToFront()
                    win.Visible = true
                    TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = windowSize,
                        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
                    }):Play()
                    if icon then icon:Destroy() icon = nil end
                    minimized = false
                end
            end
        end
    end)
end

btnMinHeader.MouseButton1Click:Connect(function()
    if not minimized then
        TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.35)
        win.Visible = false
        createMinimizedIcon()
        minimized = true
    end
end)

-- ============================================
-- DRAGGING SYSTEM
-- ============================================
local dragging, dragStart, startPos = false, nil, nil

scriptHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bringToFront()
        dragging, dragStart, startPos = true, input.Position, win.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ============================================
-- RESIZING SYSTEM
-- ============================================
local resizeStart, startSize = nil, nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing, resizeStart, startSize = true, input.Position, win.Size
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newWidth = math.clamp(startSize.X.Offset + delta.X, minWindowSize.X, maxWindowSize.X)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minWindowSize.Y, maxWindowSize.Y)
        win.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ============================================
-- OPENING ANIMATION
-- ============================================
task.spawn(function()
    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    win.BackgroundTransparency = 1
    
    task.wait(0.1)
    
    TweenService:Create(win, TweenInfo.new(0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        Size = windowSize
    }):Play()
    
    TweenService:Create(win, TweenInfo.new(0.5), {
        BackgroundTransparency = 0.25
    }):Play()
end)

-- ============================================
-- FINAL SUCCESS MESSAGE
-- ============================================
print("\n━━━━━━━━━━━━━━━━━━━━━━")
print("✨ Quix GUI v4.2.0 FIXED")
print("FREE NOT FOR SALE")
print("━━━━━━━━━━━━━━━━━━━━━━")
print("💎 Created by Quix Team")
print("📦 Modules: " .. loadedModules .. "/" .. totalModules .. " loaded")

-- Safe verification
local hideStatsOK = (HideStats ~= nil)
local webhookOK = (WebhookModule ~= nil)

print("✅ HideStats: " .. (hideStatsOK and "VERIFIED ✓" or "NOT LOADED ✗"))
print("✅ Webhook: " .. (webhookOK and "VERIFIED ✓" or "NOT LOADED ✗"))

if hideStatsOK and webhookOK then
    print("🎉 All critical systems operational!")
else
    print("⚠️  Some critical modules missing - check features")
end

print("━━━━━━━━━━━━━━━━━━━━━━\n")

SendNotification("🎉 Quix GUI Ready!", "All systems operational!", 3)
