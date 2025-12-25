local parent = script.Parent
local BlueStaminaImage = parent.StaminaCanvas.ImageLabel
local whiteStaminaImage = parent.WhiteStaminaCanvas.ImageLabel

local TweenService = game:GetService("TweenService")

local SetNewMaxStaminaEvent = game.ReplicatedStorage.Events.Player.SetNewMaxStamina

local player = game.Players.LocalPlayer

local FULL_Stamina_X = 0
local ZERO_Stamina_X = -0.76

-- Function to update stamina bar
local function UpdateStaminaBar()
	local Stamina = player:GetAttribute("Stamina")
	local MaxStamina = player:GetAttribute("MaxStamina")
	if not Stamina or not MaxStamina or MaxStamina == 0 then return end

	local StaminaRatio = Stamina / MaxStamina
	local xPos = ZERO_Stamina_X + (FULL_Stamina_X - ZERO_Stamina_X) * StaminaRatio
	local newPosition = UDim2.new(0, 0, xPos, 0)

	-- Instant update for blue bar
	BlueStaminaImage.Position = newPosition

	-- Delayed smooth update for white bar
	delay(0.2, function()
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(whiteStaminaImage, tweenInfo, {Position = newPosition})
		tween:Play()
	end)
end

-- Listen to changes
player:GetAttributeChangedSignal("Stamina"):Connect(UpdateStaminaBar)
SetNewMaxStaminaEvent.OnClientEvent:Connect(UpdateStaminaBar)


-- Run once at start
UpdateStaminaBar()