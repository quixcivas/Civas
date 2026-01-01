-- AutoSellSystem.lua
-- COMBINED: Sell All, Auto Sell Timer, Auto Sell By Count
-- Clean module version - no GUI, no logs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ===== FIND SELL REMOTE =====
local function findSellRemote()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if not packages then return nil end
	
	local index = packages:FindFirstChild("_Index")
	if not index then return nil end
	
	local sleitnick = index:FindFirstChild("sleitnick_net@0.2.0")
	if not sleitnick then return nil end
	
	local net = sleitnick:FindFirstChild("net")
	if not net then return nil end
	
	local sellRemote = net:FindFirstChild("RF/SellAllItems")
	if sellRemote then return sellRemote end
	
	local rf = net:FindFirstChild("RF")
	if rf then
		sellRemote = rf:FindFirstChild("SellAllItems")
		if sellRemote then return sellRemote end
	end
	
	for _, child in ipairs(net:GetDescendants()) do
		if child.Name == "SellAllItems" or child.Name == "RF/SellAllItems" then
			return child
		end
	end
	
	return nil
end

local SellRemote = findSellRemote()

-- ===== BAG PARSER (for Auto Sell By Count) =====
local function parseNumber(text)
	if not text or text == "" then return 0 end
	local cleaned = tostring(text):gsub("%D", "")
	if cleaned == "" then return 0 end
	return tonumber(cleaned) or 0
end

local function getBagCount()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return 0, 0 end

	local inv = gui:FindFirstChild("Inventory")
	if not inv then return 0, 0 end

	local label = inv:FindFirstChild("Main")
		and inv.Main:FindFirstChild("Top")
		and inv.Main.Top:FindFirstChild("Options")
		and inv.Main.Top.Options:FindFirstChild("Fish")
		and inv.Main.Top.Options.Fish:FindFirstChild("Label")
		and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")

	if not label or not label:IsA("TextLabel") then return 0, 0 end

	local curText, maxText = label.Text:match("(.+)%/(.+)")
	if not curText or not maxText then return 0, 0 end

	return parseNumber(curText), parseNumber(maxText)
end

-- ===== MAIN MODULE =====
local AutoSellSystem = {
	Remote = SellRemote,
	
	-- Sell All Stats
	_totalSells = 0,
	_lastSellTime = 0,
	
	-- Timer Mode
	Timer = {
		Enabled = false,
		Interval = 5,
		Thread = nil,
		_sellCount = 0
	},
	
	-- Count Mode
	Count = {
		Enabled = false,
		Target = 235,
		CheckDelay = 1.5,
		_lastSell = 0,
		_thread = nil
	}
}

-- ===== CORE SELL FUNCTION =====
local function executeSell()
	if not SellRemote then return false end
	
	local success, result = pcall(function()
		return SellRemote:InvokeServer()
	end)
	
	if success then
		AutoSellSystem._totalSells = AutoSellSystem._totalSells + 1
		AutoSellSystem._lastSellTime = tick()
		return true
	end
	
	return false
end

-- ===== SELL ALL (MANUAL) =====
function AutoSellSystem.SellOnce()
	if not SellRemote then return false end
	if tick() - AutoSellSystem._lastSellTime < 0.5 then return false end
	return executeSell()
end

-- ===== TIMER MODE =====
function AutoSellSystem.Timer.Start(interval)
	if AutoSellSystem.Timer.Enabled then return false end
	if not SellRemote then return false end
	
	if interval and tonumber(interval) and tonumber(interval) >= 1 then
		AutoSellSystem.Timer.Interval = tonumber(interval)
	end
	
	AutoSellSystem.Timer.Enabled = true
	AutoSellSystem.Timer._sellCount = 0
	
	AutoSellSystem.Timer.Thread = task.spawn(function()
		while AutoSellSystem.Timer.Enabled do
			task.wait(AutoSellSystem.Timer.Interval)
			
			if not AutoSellSystem.Timer.Enabled then break end
			
			if executeSell() then
				AutoSellSystem.Timer._sellCount = AutoSellSystem.Timer._sellCount + 1
			end
		end
	end)
	
	return true
end

function AutoSellSystem.Timer.Stop()
	if not AutoSellSystem.Timer.Enabled then return false end
	AutoSellSystem.Timer.Enabled = false
	return true
end

function AutoSellSystem.Timer.SetInterval(seconds)
	if tonumber(seconds) and seconds >= 1 then
		AutoSellSystem.Timer.Interval = tonumber(seconds)
		return true
	end
	return false
end

function AutoSellSystem.Timer.GetStatus()
	return {
		enabled = AutoSellSystem.Timer.Enabled,
		interval = AutoSellSystem.Timer.Interval,
		sellCount = AutoSellSystem.Timer._sellCount
	}
end

-- ===== COUNT MODE =====
function AutoSellSystem.Count.Start(target)
	if AutoSellSystem.Count.Enabled then return false end
	if not SellRemote then return false end
	
	if target and tonumber(target) and tonumber(target) > 0 then
		AutoSellSystem.Count.Target = tonumber(target)
	end
	
	AutoSellSystem.Count.Enabled = true
	
	AutoSellSystem.Count._thread = task.spawn(function()
		while AutoSellSystem.Count.Enabled do
			task.wait(AutoSellSystem.Count.CheckDelay)
			
			if not AutoSellSystem.Count.Enabled then break end
			
			local current, max = getBagCount()
			
			if AutoSellSystem.Count.Target > 0 and current >= AutoSellSystem.Count.Target then
				if tick() - AutoSellSystem.Count._lastSell < 3 then
					continue
				end
				
				AutoSellSystem.Count._lastSell = tick()
				executeSell()
				task.wait(2)
			end
		end
	end)
	
	return true
end

function AutoSellSystem.Count.Stop()
	if not AutoSellSystem.Count.Enabled then return false end
	AutoSellSystem.Count.Enabled = false
	return true
end

function AutoSellSystem.Count.SetTarget(count)
	if tonumber(count) and tonumber(count) > 0 then
		AutoSellSystem.Count.Target = tonumber(count)
		return true
	end
	return false
end

function AutoSellSystem.Count.GetStatus()
	local cur, max = getBagCount()
	return {
		enabled = AutoSellSystem.Count.Enabled,
		target = AutoSellSystem.Count.Target,
		current = cur,
		max = max
	}
end

-- ===== UTILITY =====
function AutoSellSystem.GetStats()
	return {
		totalSells = AutoSellSystem._totalSells,
		lastSellTime = AutoSellSystem._lastSellTime,
		remoteFound = SellRemote ~= nil,
		timerStatus = AutoSellSystem.Timer.GetStatus(),
		countStatus = AutoSellSystem.Count.GetStatus()
	}
end

function AutoSellSystem.ResetStats()
	AutoSellSystem._totalSells = 0
	AutoSellSystem._lastSellTime = 0
	AutoSellSystem.Timer._sellCount = 0
end

_G.AutoSellSystem = AutoSellSystem
return AutoSellSystem
