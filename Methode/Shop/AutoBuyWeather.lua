-- AutoBuyWeather.lua (MODULE VERSION)

local AutoBuyWeather = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetPackage = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
local RFPurchaseWeatherEvent = NetPackage.net["RF/PurchaseWeatherEvent"]

-- STATE
local isRunning = false
local selected = {}

AutoBuyWeather.AllWeathers = {
    "Cloudy",
    "Storm",
    "Wind",
    "Snow",
    "Radiant",
    "Shark Hunt"
}

-- Set cuaca terpilih
function AutoBuyWeather.SetSelected(list)
    selected = list
end

-- Start auto maintain
function AutoBuyWeather.Start()
    if isRunning then return end
    isRunning = true

    task.spawn(function()
        while isRunning do
            for _, weather in ipairs(selected) do
                if not isRunning then break end
                pcall(function()
                    RFPurchaseWeatherEvent:InvokeServer(weather)
                end)
                task.wait(2)
            end
            task.wait(15)
        end
    end)
end

-- Stop auto maintain
function AutoBuyWeather.Stop()
    isRunning = false
end

-- Getter untuk GUI status
function AutoBuyWeather.GetStatus()
    return {
        Running = isRunning,
        Selected = selected
    }
end

return AutoBuyWeather
