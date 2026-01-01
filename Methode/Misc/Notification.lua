-- Notification.lua
-- Simple notification (bottom-right) for exploit environments.

local Notify = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Parent ke PlayerGui AGAR TIDAK TERBLOCK EXECUTOR
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LynxNotifications"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Holder kanan bawah
local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Parent = ScreenGui
Holder.AnchorPoint = Vector2.new(1, 1)
Holder.Position = UDim2.new(1, -20, 1, -20) -- kanan bawah
Holder.Size = UDim2.new(0, 300, 1, -40)
Holder.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", Holder)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

-- Fungsi utama
function Notify.Send(title, message, duration)
    duration = duration or 3

    -- Frame notifikasi
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 65)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BackgroundTransparency = 0.15
    Frame.BorderSize = 0
    Frame.Parent = Holder
    Frame.ClipsDescendants = true
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.LayoutOrder = os.clock()

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 12)

    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = Frame
    TitleLabel.Size = UDim2.new(1, -20, 0, 18)
    TitleLabel.Position = UDim2.new(0, 10, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Text = title

    -- Message
    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Parent = Frame
    MsgLabel.Size = UDim2.new(1, -20, 0, 35)
    MsgLabel.Position = UDim2.new(0, 10, 0, 30)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Font = Enum.Font.Gotham
    MsgLabel.TextSize = 14
    MsgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    MsgLabel.TextWrapped = true
    MsgLabel.Text = message

    -- Fade In
    Frame.BackgroundTransparency = 1
    TitleLabel.TextTransparency = 1
    MsgLabel.TextTransparency = 1

    TweenService:Create(Frame, TweenInfo.new(0.25), {BackgroundTransparency = 0.15}):Play()
    TweenService:Create(TitleLabel, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
    TweenService:Create(MsgLabel, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        -- Fade Out
        TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(MsgLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.3)
        Frame:Destroy()
    end)
end

return Notify
