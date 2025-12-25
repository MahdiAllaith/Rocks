local parent = script.Parent
local redHelthImage = parent.HealthCanvas.ImageLabel
local whiteHelthImage = parent.WhiteHealthCanvas.ImageLabel

local TweenService = game:GetService("TweenService")

local SetNewMaxHealthEvent = game.ReplicatedStorage.Events.Player.SetNewMaxHealth

local player = game.Players.LocalPlayer

local FULL_HEALTH_X = 0
local ZERO_HEALTH_X = -0.79


local function UpdateStaminaBar()
	local Health = player:GetAttribute("Health")
	local MaxHealth = player:GetAttribute("MaxHealth")
	if not Health or not MaxHealth or MaxHealth == 0 then return end

	local healthRatio = Health / MaxHealth
	local xPos = ZERO_HEALTH_X + (FULL_HEALTH_X - ZERO_HEALTH_X) * healthRatio
	local newPosition = UDim2.new(0, 0, xPos, 0)

	redHelthImage.Position = newPosition

	delay(0.2, function()
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(whiteHelthImage, tweenInfo, {Position = newPosition})
		tween:Play()
	end)
end

player:GetAttributeChangedSignal("Health"):Connect(UpdateStaminaBar)
SetNewMaxHealthEvent.OnClientEvent:Connect(UpdateStaminaBar)

UpdateStaminaBar()