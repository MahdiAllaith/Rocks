local text = script.Parent
local player = game.Players.LocalPlayer

-- Function to safely get attribute with retries
local function getAttributeWithRetry(attributeName, maxAttempts)
	for attempt = 1, maxAttempts do
		local value = player:GetAttribute(attributeName)
		if value ~= nil then
			return value
		end
		if attempt < maxAttempts then
			task.wait(1)
		end
	end
	return nil
end

-- Try to get RocksAmount attribute (5 attempts, 1 second between each)
local amount = getAttributeWithRetry("RocksAmount", 5)

if amount then
	text.Text = tostring(amount)

	-- Listen for changes
	player:GetAttributeChangedSignal("RocksAmount"):Connect(function()
		local newAmount = player:GetAttribute("RocksAmount")
		if newAmount then
			text.Text = tostring(newAmount)
		end
	end)
else
	-- Fallback if attribute never found
	text.Text = "0"
	warn("RocksAmount attribute not found after 5 attempts")
end