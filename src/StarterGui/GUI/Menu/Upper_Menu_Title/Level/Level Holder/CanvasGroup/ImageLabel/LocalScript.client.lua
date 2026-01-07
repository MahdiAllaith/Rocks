local image = script.Parent
local player = game.Players.LocalPlayer

-- Function to update the XP bar position
local function updateXPBar()
	local currentXP = player:GetAttribute("CurentXP") or 0
	local nextLevelXP = player:GetAttribute("NextLevelRequiredXP") or 100

	-- Calculate the ratio (0 to 1)
	local ratio = currentXP / nextLevelXP

	-- Map ratio from [0, 1] to position scale [-1, -0.045]
	-- When ratio = 0 -> position = -1
	-- When ratio = 1 -> position = -0.045
	local startPos = -1
	local endPos = -0.045
	local positionX = startPos + (ratio * (endPos - startPos))

	-- Update the image position
	image.Position = UDim2.new(positionX, 0, image.Position.Y.Scale, image.Position.Y.Offset)
end

-- Initial update
updateXPBar()

-- Listen for XP changes
player:GetAttributeChangedSignal("CurentXP"):Connect(updateXPBar)

-- Listen for NextLevelXP changes (in case of level up)
player:GetAttributeChangedSignal("NextLevelRequiredXP"):Connect(updateXPBar)