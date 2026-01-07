local RockDamage = script.Parent.RockDamageText
local ThrowDestince = script.Parent.ThrowDestinceText
local Type = script.Parent.TypeText
local CoolDown = script.Parent.CoolDownText

local player = game.Players.LocalPlayer
local Backpack = player:WaitForChild("Backpack", 10)

if not Backpack then
	warn("Backpack not found for player")
	RockDamage.Text = "0"
	ThrowDestince.Text = "0"
	Type.Text = "None"
	CoolDown.Text = "0"
	return
end

local RockFolder = Backpack:WaitForChild("ActiveRockModifiers", 10)

if not RockFolder then
	warn("ActiveRockModifiers folder not found in Backpack")
	RockDamage.Text = "0"
	ThrowDestince.Text = "0"
	Type.Text = "None"
	CoolDown.Text = "0"
	return
end

-- Function to safely get attribute with retries
local function getAttributeWithRetry(obj, attributeName, maxAttempts)
	for attempt = 1, maxAttempts do
		local value = obj:GetAttribute(attributeName)
		if value ~= nil then
			return value
		end
		if attempt < maxAttempts then
			task.wait(1)
		end
	end
	return nil
end

-- Get initial attributes with retry logic (5 attempts, 1 second between each)
local att_RockDamage = getAttributeWithRetry(RockFolder, "Damage", 5)
local att_ThrowDestince = getAttributeWithRetry(RockFolder, "ThrowDestince", 5)
local att_Type = getAttributeWithRetry(RockFolder, "RockType", 5)
local att_CoolDown = getAttributeWithRetry(RockFolder, "CoolDown", 5)

-- Set initial text values with fallbacks
RockDamage.Text = tostring(att_RockDamage or 0)
ThrowDestince.Text = tostring(att_ThrowDestince or 0)
Type.Text = tostring(att_Type or "None")
CoolDown.Text = tostring(att_CoolDown or 0)

-- Bind to attribute changes with safe value retrieval
RockFolder:GetAttributeChangedSignal("Damage"):Connect(function()
	local value = RockFolder:GetAttribute("Damage")
	if value then
		RockDamage.Text = tostring(value)
	end
end)

RockFolder:GetAttributeChangedSignal("ThrowDestince"):Connect(function()
	local value = RockFolder:GetAttribute("ThrowDestince")
	if value then
		ThrowDestince.Text = tostring(value)
	end
end)

RockFolder:GetAttributeChangedSignal("RockType"):Connect(function()
	local value = RockFolder:GetAttribute("RockType")
	if value then
		Type.Text = tostring(value)
	end
end)

RockFolder:GetAttributeChangedSignal("CoolDown"):Connect(function()
	local value = RockFolder:GetAttribute("CoolDown")
	if value then
		CoolDown.Text = tostring(value)
	end
end)