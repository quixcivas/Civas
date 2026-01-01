-- Remote Merchant System (Standalone Version)
-- Bisa dijalankan via raw link (loadstring + HttpGet)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Merchant UI di PlayerGui
local MerchantUI = PlayerGui:WaitForChild("Merchant")

-- ==== FUNCTIONS ====

local function OpenMerchant()
    if MerchantUI then
        MerchantUI.Enabled = true
    end
end

local function CloseMerchant()
    if MerchantUI then
        MerchantUI.Enabled = false
    end
end

return {
    Open = OpenMerchant,
    Close = CloseMerchant
}
