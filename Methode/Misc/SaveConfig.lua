-- ConfigSystem.luaaaa
-- Auto Save/Load Configuration System for Quix GUI
-- FREE NOT FOR SALE

local HttpService = game:GetService("HttpService")

local ConfigSystem = {}
ConfigSystem.Version = "1.0"

-- ============================================
-- CONFIG SETTINGS
-- ============================================
local CONFIG_FOLDER = "QuixGUI_Configs"
local CONFIG_FILE = CONFIG_FOLDER .. "/Quix_config.json"

-- ============================================
-- DEFAULT CONFIG STRUCTURE
-- ============================================
local DefaultConfig = {
    -- Main Page - Auto Fishing
    InstantFishing = {
        Mode = "None", -- "Fast", "Perfect", "None"
        Enabled = false,
        FishingDelay = 1.30,
        CancelDelay = 0.19
    },
    
    -- Blatant Tester
    BlatantTester = {
        Enabled = false,
        CompleteDelay = 0.5,
        CancelDelay = 0.1
    },
    
    -- Blatant V1
    BlatantV1 = {
        Enabled = false,
        CompleteDelay = 0.05,
        CancelDelay = 0.1
    },
    
    -- Ultra Blatant (Blatant V2)
    UltraBlatant = {
        Enabled = false,
        CompleteDelay = 0.05,
        CancelDelay = 0.1
    },
    
    -- Fast Auto Fishing Perfect
    FastAutoPerfect = {
        Enabled = false,
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        TimeoutDelay = 0.8
    },
    
    -- Support Features
    Support = {
        NoFishingAnimation = false,
        LockPosition = false,
        AutoEquipRod = false,
        DisableCutscenes = false,
        DisableObtainedNotif = false,
        DisableSkinEffect = false,
        WalkOnWater = false,
        GoodPerfectionStable = false
    },
    
    -- Teleport
    Teleport = {
        SavedLocation = nil,
        LastEventSelected = nil,
        AutoTeleportEvent = false
    },
    
    -- Shop
    Shop = {
        AutoSellTimer = {
            Enabled = false,
            Interval = 5
        },
        AutoBuyWeather = {
            Enabled = false,
            SelectedWeathers = {}
        }
    },
    
    -- Webhook
    Webhook = {
        Enabled = false,
        URL = "",
        DiscordID = "",
        EnabledRarities = {}
    },
    
    -- Camera View
    CameraView = {
        UnlimitedZoom = false,
        Freecam = {
            Enabled = false,
            Speed = 50,
            Sensitivity = 0.3
        }
    },
    
    -- Settings
    Settings = {
        AntiAFK = false,
        FPSBooster = false,
        DisableRendering = false,
        FPSLimit = 60,
        HideStats = {
            Enabled = false,
            FakeName = "Guest",
            FakeLevel = "1"
        }
    }
}

local CurrentConfig = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Deep copy table
local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Merge tables (updates existing values, adds new ones)
local function MergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            MergeTables(target[k], v)
        else
            target[k] = v
        end
    end
end

-- ============================================
-- FOLDER MANAGEMENT
-- ============================================
local function EnsureFolderExists()
    if not isfolder(CONFIG_FOLDER) then
        print("📁 [ConfigSystem] Creating config folder:", CONFIG_FOLDER)
        makefolder(CONFIG_FOLDER)
        print("✅ [ConfigSystem] Folder created!")
    end
end

-- ============================================
-- SAVE CONFIG
-- ============================================
function ConfigSystem.Save()
    print("💾 [ConfigSystem] Saving configuration...")
    
    local success, err = pcall(function()
        EnsureFolderExists()
        
        local jsonData = HttpService:JSONEncode(CurrentConfig)
        writefile(CONFIG_FILE, jsonData)
    end)
    
    if success then
        print("✅ [ConfigSystem] Configuration saved successfully!")
        return true, "Config saved!"
    else
        warn("❌ [ConfigSystem] Save failed:", err)
        return false, "Save failed: " .. tostring(err)
    end
end

-- ============================================
-- LOAD CONFIG
-- ============================================
function ConfigSystem.Load()
    print("🔄 [ConfigSystem] Loading configuration...")
    
    EnsureFolderExists()
    
    -- Start with default config
    CurrentConfig = DeepCopy(DefaultConfig)
    
    if isfile(CONFIG_FILE) then
        print("📁 [ConfigSystem] Config file found!")
        
        local success, result = pcall(function()
            local jsonData = readfile(CONFIG_FILE)
            local loadedConfig = HttpService:JSONDecode(jsonData)
            
            -- Merge loaded config with defaults (preserves new settings)
            MergeTables(CurrentConfig, loadedConfig)
        end)
        
        if success then
            print("✅ [ConfigSystem] Configuration loaded successfully!")
            return true, CurrentConfig
        else
            warn("❌ [ConfigSystem] Load failed:", result)
            warn("⚠️ [ConfigSystem] Using default configuration")
            return false, CurrentConfig
        end
    else
        print("⚠️ [ConfigSystem] No saved config found, using defaults")
        return false, CurrentConfig
    end
end

-- ============================================
-- GET/SET FUNCTIONS
-- ============================================

-- Get entire config
function ConfigSystem.GetConfig()
    return CurrentConfig
end

-- Get specific value
function ConfigSystem.Get(path)
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local value = CurrentConfig
    for _, key in ipairs(keys) do
        if type(value) == "table" then
            value = value[key]
        else
            return nil
        end
    end
    
    return value
end

-- Set specific value
function ConfigSystem.Set(path, value)
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local target = CurrentConfig
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(target[key]) ~= "table" then
            target[key] = {}
        end
        target = target[key]
    end
    
    target[keys[#keys]] = value
end

-- ============================================
-- PRINT CONFIG STATUS
-- ============================================
function ConfigSystem.PrintStatus()
    print("=== Quix GUI CONFIG STATUS ===")
    print("📦 Version:", ConfigSystem.Version)
    print("📁 Folder:", CONFIG_FOLDER)
    print("📄 File:", CONFIG_FILE)
    print("✅ Config loaded:", isfile(CONFIG_FILE) and "YES" or "NO")
    print("==============================")
end

-- ============================================
-- RESET CONFIG
-- ============================================
function ConfigSystem.Reset()
    print("🔄 [ConfigSystem] Resetting to default configuration...")
    CurrentConfig = DeepCopy(DefaultConfig)
    
    local success, message = ConfigSystem.Save()
    if success then
        print("✅ [ConfigSystem] Configuration reset complete!")
    end
    
    return success, message
end

-- ============================================
-- DELETE CONFIG FILE
-- ============================================
function ConfigSystem.Delete()
    if isfile(CONFIG_FILE) then
        delfile(CONFIG_FILE)
        print("🗑️ [ConfigSystem] Config file deleted!")
        return true
    else
        print("⚠️ [ConfigSystem] No config file to delete")
        return false
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================
print("🚀 [ConfigSystem] Module loaded!")
ConfigSystem.Load()

return ConfigSystem
