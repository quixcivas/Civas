-- ============================================
-- AUTO FAVORITE SYSTEM (MEMORY SAFE) - FIXED
-- ============================================

local AutoFavorite = {}

-- Tier mapping
local TIER_MAP = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythic"] = 6,
    ["SECRET"] = 7
}

-- State variables
local AUTO_FAVORITE_TIERS = {}
local AUTO_FAVORITE_VARIANTS = {}
local AUTO_FAVORITE_ENABLED = false

-- Connection management
local activeConnections = {}

-- Get required services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get favorite event
local FavoriteEvent = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
    :WaitForChild("RE/FavoriteItem")

-- Get notification event
local NotificationEvent = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
    :WaitForChild("RE/ObtainedNewFishNotification")

-- Get fish data helper (cached)
local itemsModule = require(ReplicatedStorage:WaitForChild("Items"))

-- Cache untuk fish data (prevent repeated lookups)
local fishDataCache = {}

local function getFishData(itemId)
    -- Check cache first
    if fishDataCache[itemId] then
        return fishDataCache[itemId]
    end
    
    -- Lookup and cache
    for _, fish in pairs(itemsModule) do
        if fish.Data and fish.Data.Id == itemId then
            fishDataCache[itemId] = fish
            return fish
        end
    end
    
    return nil
end

-- ============================================
-- PUBLIC FUNCTIONS FOR GUI
-- ============================================

function AutoFavorite.GetAllTiers()
    return {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}
end

function AutoFavorite.GetAllVariants()
    return {
        "Galaxy",
        "Corrupt",
        "Gemstone",
        "Fairy Dust",
        "Midnight",
        "Color Burn",
        "Holographic",
        "Lightning",
        "Radioactive",
        "Ghost",
        "Gold",
        "Frozen",
        "1x1x1x1",
        "Stone",
        "Sandy",
        "Noob",
        "Moon Fragment",
        "Festive",
        "Albino",
        "Arctic Frost",
        "Disco"
    }
end

function AutoFavorite.EnableTiers(selectedTiers)
    for _, tierName in ipairs(selectedTiers) do
        local tier = TIER_MAP[tierName]
        if tier then
            AUTO_FAVORITE_TIERS[tier] = true
        end
    end
end

function AutoFavorite.ClearTiers()
    table.clear(AUTO_FAVORITE_TIERS)
end

function AutoFavorite.EnableVariants(selectedVariants)
    for _, variantName in ipairs(selectedVariants) do
        AUTO_FAVORITE_VARIANTS[variantName] = true
    end
end

function AutoFavorite.ClearVariants()
    table.clear(AUTO_FAVORITE_VARIANTS)
end

-- ============================================
-- CONNECTION MANAGEMENT
-- ============================================

local function disconnectAll()
    for _, conn in pairs(activeConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(activeConnections)
end

-- ✅ FIXED: Ubah dari colon (:) ke dot (.) syntax
function AutoFavorite.Start()
    -- Disconnect existing connections first
    disconnectAll()
    
    AUTO_FAVORITE_ENABLED = true
    
    -- Create new connection
    local connection = NotificationEvent.OnClientEvent:Connect(function(itemId, metadata, extraData)
        if not AUTO_FAVORITE_ENABLED then 
            return 
        end
        
        -- Early exit checks
        if not extraData or not extraData.InventoryItem then
            return
        end
        
        local inventoryItem = extraData.InventoryItem
        local uuid = inventoryItem.UUID
        
        if not uuid or inventoryItem.Favorited then 
            return 
        end

        local shouldFavorite = false

        -- Check Tier
        if next(AUTO_FAVORITE_TIERS) then
            local fishData = getFishData(itemId)
            if fishData and fishData.Data and fishData.Data.Tier then
                if AUTO_FAVORITE_TIERS[fishData.Data.Tier] then
                    shouldFavorite = true
                end
            end
        end

        -- Check Variant (only if not already marked for favorite)
        if not shouldFavorite and next(AUTO_FAVORITE_VARIANTS) then
            local variantId = metadata and metadata.VariantId
            if variantId and variantId ~= "None" and AUTO_FAVORITE_VARIANTS[variantId] then
                shouldFavorite = true
            end
        end

        -- Execute Favorite
        if shouldFavorite then
            task.delay(0.35, function()
                pcall(function()
                    FavoriteEvent:FireServer(uuid)
                end)
            end)
        end
    end)
    
    -- Store connection
    table.insert(activeConnections, connection)
end

-- ✅ FIXED: Ubah dari colon (:) ke dot (.) syntax
function AutoFavorite.Stop()
    AUTO_FAVORITE_ENABLED = false
    disconnectAll()
end

-- ============================================
-- CLEANUP ON MODULE UNLOAD
-- ============================================

local function cleanup()
    disconnectAll()
    table.clear(AUTO_FAVORITE_TIERS)
    table.clear(AUTO_FAVORITE_VARIANTS)
    table.clear(fishDataCache)
    AUTO_FAVORITE_ENABLED = false
end

-- Register cleanup
if game then
    game:BindToClose(cleanup)
end

return AutoFavorite
