-- FungsiKeaby/ShopFeatures/AutoSellTimer.lua
local AutoSellTimer = {
	Enabled = false,
	Interval = 5,
	Thread = nil
}

-- RAW Notification (langsung SetCore)
local function Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4
        })
    end)
end

function AutoSellTimer.Start(interval)
	if AutoSellTimer.Enabled then
		warn("⚠️ AutoSellTimer sudah aktif!")
		return
	end

	if interval and tonumber(interval) and tonumber(interval) >= 1 then
		AutoSellTimer.Interval = tonumber(interval)
	end

	local AutoSell = _G.AutoSell
	if not AutoSell then
		warn("❌ Modul AutoSell belum dimuat!")
		return
	end

	AutoSellTimer.Enabled = true
	print("✅ AutoSellTimer dimulai (" .. AutoSellTimer.Interval .. " detik)")
	Notify("Auto Sell Running", "Auto Sell Berjalan!", 4)

	AutoSellTimer.Thread = task.spawn(function()
		while AutoSellTimer.Enabled do
			task.wait(AutoSellTimer.Interval)
			if AutoSellTimer.Enabled and AutoSell and AutoSell.SellOnce then
				print("💸 Auto selling (interval " .. AutoSellTimer.Interval .. "s)")
				pcall(AutoSell.SellOnce)
			end
		end
	end)
end

function AutoSellTimer.Stop()
	if not AutoSellTimer.Enabled then
		warn("⚠️ AutoSellTimer belum aktif.")
		return
	end

	AutoSellTimer.Enabled = false
	print("🛑 AutoSellTimer dihentikan.")
	Notify("Auto Sell Stopped", "Auto Sell Berhenti!", 4)
end

function AutoSellTimer.SetInterval(seconds)
	if tonumber(seconds) and seconds >= 1 then
		AutoSellTimer.Interval = tonumber(seconds)
		print("⏰ Interval auto sell diatur ke " .. seconds .. " detik.")
	else
		warn("❌ Interval tidak valid, harus >= 1 detik.")
	end
end

function AutoSellTimer.GetStatus()
	print("\n📊 AUTO SELL TIMER STATUS:")
	print("✅ Enabled:", AutoSellTimer.Enabled)
	print("⏰ Interval:", AutoSellTimer.Interval .. " detik")
end

return AutoSellTimer

