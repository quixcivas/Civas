local WebhookModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function getHTTPRequest()
    -- Coba berbagai metode request berdasarkan executor
    local requestFunctions = {
        -- Metode standar
        request,
        http_request,
        -- Syn/Synapse
        (syn and syn.request),
        -- Fluxus
        (fluxus and fluxus.request),
        -- Script-Ware
        (http and http.request),
        -- Solara (khusus)
        (solara and solara.request),
        -- Fallback lainnya
        (game and game.HttpGet and function(opts)
            if opts.Method == "GET" then
                return {Body = game:HttpGet(opts.Url)}
            end
        end)
    }
    
    for _, func in ipairs(requestFunctions) do
        if func and type(func) == "function" then
            return func
        end
    end
    
    return nil
end

local httpRequest = getHTTPRequest()

WebhookModule.Config = {
    WebhookURL = "",
    DiscordUserID = "",
    DebugMode = false,
    EnabledRarities = {},
    UseSimpleMode = false -- Mode sederhana tanpa thumbnail API
}

local Items, Variants

-- Safe module loading
local function loadGameModules()
    local success, err = pcall(function()
        Items = require(ReplicatedStorage:WaitForChild("Items"))
        Variants = require(ReplicatedStorage:WaitForChild("Variants"))
    end)
    
    return success
end

local TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}

local TIER_COLORS = {
    [1] = 9807270,
    [2] = 3066993,
    [3] = 3447003,
    [4] = 10181046,
    [5] = 15844367,
    [6] = 16711680,
    [7] = 1752220
}

local isRunning = false
local eventConnection = nil

local function getPlayerDisplayName()
    return LocalPlayer.DisplayName or LocalPlayer.Name
end

local function getDiscordImageUrl(assetId)
    if not assetId then return nil end
    
    local thumbnailUrl = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
        tostring(assetId)
    )
    
    local rbxcdnUrl = string.format(
        "https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png",
        tostring(assetId)
    )
    
    -- Coba Thumbnail API dulu (jika httpRequest tersedia)
    if httpRequest then
        local success, result = pcall(function()
            local response = httpRequest({
                Url = thumbnailUrl,
                Method = "GET"
            })
            
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    return data.data[1].imageUrl
                end
            end
        end)
        
        if success and result then
            return result
        end
    end
    
    -- Fallback ke rbxcdn
    return rbxcdnUrl
end

local function getFishImageUrl(fish)
    local assetId = nil
    
    if fish.Data.Icon then
        assetId = tostring(fish.Data.Icon):match("%d+")
    elseif fish.Data.ImageId then
        assetId = tostring(fish.Data.ImageId)
    elseif fish.Data.Image then
        assetId = tostring(fish.Data.Image):match("%d+")
    end
    
    if assetId then
        local discordUrl = getDiscordImageUrl(assetId)
        if discordUrl then
            return discordUrl
        end
    end
    
    return "https://i.imgur.com/8yZqFqM.png"
end

local function getFish(itemId)
    if not Items then return nil end
    
    for _, f in pairs(Items) do
        if f.Data and f.Data.Id == itemId then
            return f
        end
    end
end

local function getVariant(id)
    if not id or not Variants then return nil end
    
    local idStr = tostring(id)
    
    for _, v in pairs(Variants) do
        if v.Data then
            if tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr then
                return v
            end
        end
    end
    
    return nil
end

local function send(fish, meta, extra)
    -- Validasi webhook URL
    if not WebhookModule.Config.WebhookURL or WebhookModule.Config.WebhookURL == "" then
        return
    end
    
    -- Validasi HTTP request function
    if not httpRequest then
        return
    end
    
    local tier = TIER_NAMES[fish.Data.Tier] or "Unknown"
    local color = TIER_COLORS[fish.Data.Tier] or 3447003
    
    -- FILTER RARITY
    if WebhookModule.Config.EnabledRarities and #WebhookModule.Config.EnabledRarities > 0 then
        local isEnabled = false
        
        for _, enabledTier in ipairs(WebhookModule.Config.EnabledRarities) do
            if enabledTier == tier then
                isEnabled = true
                break
            end
        end
        
        if not isEnabled then
            return
        end
    end
    
    local mutationText = "None"
    local finalPrice = fish.SellPrice or 0
    local variantId = nil
    
    if extra then
        variantId = extra.Variant or extra.Mutation or extra.VariantId or extra.MutationId
    end
    
    if not variantId and meta then
        variantId = meta.Variant or meta.Mutation or meta.VariantId or meta.MutationId
    end
    
    local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)
    if isShiny then
        mutationText = "Shiny"
        finalPrice = finalPrice * 2
    end
    
    if variantId then
        local v = getVariant(variantId)
        if v then
            mutationText = v.Data.Name .. " (" .. v.SellMultiplier .. "x)"
            finalPrice = finalPrice * v.SellMultiplier
        else
            mutationText = variantId
        end
    end
    
    local imageUrl = getFishImageUrl(fish)
    local playerDisplayName = getPlayerDisplayName()
    local mention = WebhookModule.Config.DiscordUserID ~= "" and "<@" .. WebhookModule.Config.DiscordUserID .. "> " or ""
    
    local congratsMsg = string.format(
        "%s **%s** You have obtained a new **%s** fish!",
        mention,
        playerDisplayName,
        tier
    )
    
    local fields = {
        {
            name = "Fish Name :",
            value = "> " .. fish.Data.Name,
            inline = false
        },
        {
            name = "Fish Tier :",
            value = "> " .. tier,
            inline = false
        },
        {
            name = "Weight :",
            value = string.format("> %.2f Kg", meta.Weight or 0),
            inline = false
        },
        {
            name = "Mutation :",
            value = "> " .. mutationText,
            inline = false
        },
        {
            name = "Sell Price :",
            value = "> $" .. math.floor(finalPrice),
            inline = false
        }
    }
    
    local payload = {
        embeds = {{
            author = {
                name = "Lynxx Webhook | Fish Caught"
            },
            description = congratsMsg,
            color = color,
            fields = fields,
            image = {
                url = imageUrl
            },
            footer = {
                text = "Lynxx Webhook • " .. os.date("%m/%d/%Y %H:%M"),
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = WebhookModule.Config.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function WebhookModule:SetWebhookURL(url)
    self.Config.WebhookURL = url
end

function WebhookModule:SetDiscordUserID(id)
    self.Config.DiscordUserID = id
end

function WebhookModule:SetDebugMode(enabled)
    self.Config.DebugMode = enabled
end

function WebhookModule:SetEnabledRarities(rarities)
    self.Config.EnabledRarities = rarities
end

function WebhookModule:SetSimpleMode(enabled)
    self.Config.UseSimpleMode = enabled
end

function WebhookModule:GetTierNames()
    return TIER_NAMES
end

function WebhookModule:Start()
    if isRunning then
        return false
    end
    
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" then
        return false
    end
    
    if not httpRequest then
        return false
    end
    
    -- Load game modules
    if not loadGameModules() then
        return false
    end
    
    local success, Event = pcall(function()
        return ReplicatedStorage.Packages
            ._Index["sleitnick_net@0.2.0"]
            .net["RE/ObtainedNewFishNotification"]
    end)
    
    if not success or not Event then
        return false
    end
    
    eventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
        local fish = getFish(itemId)
        if fish then
            task.spawn(function()
                send(fish, metadata, extraData)
            end)
        end
    end)
    
    isRunning = true
    return true
end

function WebhookModule:Stop()
    if not isRunning then
        return false
    end
    
    if eventConnection then
        eventConnection:Disconnect()
        eventConnection = nil
    end
    
    isRunning = false
    return true
end

function WebhookModule:IsRunning()
    return isRunning
end

function WebhookModule:GetConfig()
    return self.Config
end

-- Check if executor supports webhook
function WebhookModule:IsSupported()
    return httpRequest ~= nil
end

return WebhookModule
