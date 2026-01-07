local walkSpeed = script.Parent.WalkSpeedText
local jumpPower = script.Parent.JumpPowerText
local health = script.Parent.HealthText
local stamina = script.Parent.StaminaText
local runSpeed = script.Parent.RunSpeedText

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

-- Get initial attributes with retry logic (5 attempts, 1 second between each)
local att_walkSpeed = getAttributeWithRetry("CurrentWalkSpeed", 5)
local att_jumpPower = getAttributeWithRetry("CurrentJumpPower", 5)
local att_runSpeed = getAttributeWithRetry("CurrentRunSpeed", 5)
local att_health = getAttributeWithRetry("Health", 5)
local att_MaxHealth = getAttributeWithRetry("MaxHealth", 5)
local att_stamina = getAttributeWithRetry("Stamina", 5)
local att_MaxStamina = getAttributeWithRetry("MaxStamina", 5)

-- Set initial text values with fallbacks
walkSpeed.Text = tostring(att_walkSpeed or 0)
jumpPower.Text = tostring(att_jumpPower or 0)
runSpeed.Text = tostring(att_runSpeed or 0)
health.Text = tostring(att_health or 0) .. " / " .. tostring(att_MaxHealth or 0)
stamina.Text = tostring(att_stamina or 0) .. " / " .. tostring(att_MaxStamina or 0)

-- Bind to attribute changes with safe value retrieval
player:GetAttributeChangedSignal("CurrentWalkSpeed"):Connect(function()
	local value = player:GetAttribute("CurrentWalkSpeed")
	if value then
		walkSpeed.Text = tostring(value)
	end
end)

player:GetAttributeChangedSignal("CurrentJumpPower"):Connect(function()
	local value = player:GetAttribute("CurrentJumpPower")
	if value then
		jumpPower.Text = tostring(value)
	end
end)

player:GetAttributeChangedSignal("CurrentRunSpeed"):Connect(function()
	local value = player:GetAttribute("CurrentRunSpeed")
	if value then
		runSpeed.Text = tostring(value)
	end
end)

player:GetAttributeChangedSignal("Health"):Connect(function()
	local currentHealth = player:GetAttribute("Health")
	local maxHealth = player:GetAttribute("MaxHealth")
	if currentHealth and maxHealth then
		health.Text = tostring(currentHealth) .. " / " .. tostring(maxHealth)
	end
end)

player:GetAttributeChangedSignal("MaxHealth"):Connect(function()
	local currentHealth = player:GetAttribute("Health")
	local maxHealth = player:GetAttribute("MaxHealth")
	if currentHealth and maxHealth then
		health.Text = tostring(currentHealth) .. " / " .. tostring(maxHealth)
	end
end)

player:GetAttributeChangedSignal("Stamina"):Connect(function()
	local currentStamina = player:GetAttribute("Stamina")
	local maxStamina = player:GetAttribute("MaxStamina")
	if currentStamina and maxStamina then
		stamina.Text = tostring(currentStamina) .. " / " .. tostring(maxStamina)
	end
end)

player:GetAttributeChangedSignal("MaxStamina"):Connect(function()
	local currentStamina = player:GetAttribute("Stamina")
	local maxStamina = player:GetAttribute("MaxStamina")
	if currentStamina and maxStamina then
		stamina.Text = tostring(currentStamina) .. " / " .. tostring(maxStamina)
	end
end)