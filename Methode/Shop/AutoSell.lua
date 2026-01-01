-- FungsiKeaby/ShopFeatures/AutoSell.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoSell = {}

local function findSellRemotes()
	local sellRemotes = {}
	local keywords = { "sell", "vendor", "trade", "shop", "merchant", "salvage", "exchange", "deposit", "convert" }

	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local name = string.lower(obj.Name)
			for _, key in ipairs(keywords) do
				if string.find(name, key) then
					table.insert(sellRemotes, obj)
					if string.find(name, "sellall") then
						print("🎯 Found SellAll Remote:", obj:GetFullName())
						return obj
					end
				end
			end
		end
	end
	return sellRemotes[1]
end

function AutoSell.SellOnce()
	print("💸 Attempting to sell all fish...")

	local remote = findSellRemotes()
	if not remote then
		warn("❌ Sell remote not found!")
		return
	end

	pcall(function()
		if remote:IsA("RemoteEvent") then
			remote:FireServer("all")
			print("✅ Sold via RemoteEvent:", remote.Name)
		elseif remote:IsA("RemoteFunction") then
			remote:InvokeServer("all")
			print("✅ Sold via RemoteFunction:", remote.Name)
		else
			warn("⚠️ Invalid remote type for selling")
		end
	end)
end

_G.AutoSell = AutoSell
return AutoSell
