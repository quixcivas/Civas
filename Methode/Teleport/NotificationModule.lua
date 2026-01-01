local Notification = {}

function Notification.Send(title, text, duration)
    duration = duration or 4

    -- Gunakan pcall supaya tidak error di Delta / exploit lain
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

return Notification
