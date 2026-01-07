local textlabel = script.Parent
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

-- Try to get Level attribute (5 attempts, 1 second between each)
local Level = getAttributeWithRetry("Level", 5)

if Level then
	textlabel.Text = tostring(Level)

	-- Listen for changes
	player:GetAttributeChangedSignal("Level"):Connect(function()
		local newLevel = player:GetAttribute("Level")
		if newLevel then
			textlabel.Text = tostring(newLevel)
		end
	end)
else
	-- Fallback if attribute never found
	textlabel.Text = "Level: N/A"
	warn("Level attribute not found after 5 attempts")
end