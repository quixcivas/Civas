-- DisableExtras.lua
local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")

local activeSmallNotif = false
local activeSkinEffect = false

-- =========================
-- Small Notification
-- =========================
local function disableNotifications()
    if not player or not player:FindFirstChild("PlayerGui") then return end
    local gui = player.PlayerGui
    local existing = gui:FindFirstChild("Small Notification")
    if existing then
        existing:Destroy()
    end
end

-- =========================
-- Skin Effect Dive
-- =========================
local function disableDiveEffects()
    for _, child in pairs(VFXFolder:GetChildren()) do
        if child.Name:match("Dive$") then
            child:Destroy()
        end
    end
end

-- =========================
-- Start / Stop Small Notification
-- =========================
function module.StartSmallNotification()
    if activeSmallNotif then return end
    activeSmallNotif = true

    -- Loop setiap frame
    RunService.Heartbeat:Connect(function()
        if activeSmallNotif then
            disableNotifications()
        end
    end)

    -- Deteksi GUI baru
    player.PlayerGui.ChildAdded:Connect(function(child)
        if activeSmallNotif and child.Name == "Small Notification" then
            child:Destroy()
        end
    end)
end

function module.StopSmallNotification()
    activeSmallNotif = false
end

-- =========================
-- Start / Stop Skin Effect
-- =========================
function module.StartSkinEffect()
    if activeSkinEffect then return end
    activeSkinEffect = true

    -- Hapus efek yang sudah ada
    disableDiveEffects()

    -- Loop setiap frame
    RunService.Heartbeat:Connect(function()
        if activeSkinEffect then
            disableDiveEffects()
        end
    end)

    -- Pantau child baru di VFX
    VFXFolder.ChildAdded:Connect(function(child)
        if activeSkinEffect and child.Name:match("Dive$") then
            child:Destroy()
        end
    end)
end

function module.StopSkinEffect()
    activeSkinEffect = false
end

return module
