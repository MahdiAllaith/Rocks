local StaminaClass = {}
StaminaClass.__index = StaminaClass

local SetNewMaxStaminaEvent = game.ReplicatedStorage.Events.Player.SetNewMaxStamina

export type StaminaClassType = typeof(setmetatable({} :: {
	MaxStamina: number,
	Stamina: number,
}, StaminaClass))

function StaminaClass.Init(player: Player, DATA)
	local self = setmetatable({}, StaminaClass)
	
	self.Player = player
	
	self.DEFAULT_MAX_STAMINA = 100

	self.MaxStamina = 100
	self.Stamina = 100

	self.AutoRegenStamin = true
	self.RegenAmount = 2
	self.RegenRatio= 1 -- every 1 second 

	self.Player:SetAttribute("MaxStamina", self.MaxStamina)
	self.Player:SetAttribute("Stamina", self.Stamina)

	local isRegenning = false

	self.Player:GetAttributeChangedSignal("Stamina"):Connect(function()
		if not self.AutoRegenStamin or isRegenning then return end

		if self.Stamina < self.MaxStamina then
			isRegenning = true
			task.delay(self.RegenRatio,function()
				self.Stamina += self.RegenAmount

				if self.Stamina > self.MaxStamina then
					self.Stamina = self.MaxStamina
				end
				-- update Stamina for client ui to respoonse
				self.Player:SetAttribute("Stamina", self.Stamina)
				isRegenning = false
			end)
		end
	end)

	return self
end

function StaminaClass:Deduct(amount: number)
	self.Stamina -= amount
	self.Player:SetAttribute("Stamina", self.Stamina)
end

function StaminaClass:FasterRegen(NewRegenAmount:number, NewRatio:number, Duration: number)
	local DefaultRatio = self.RegenRatio
	local DefaultRegenAmount = self.RegenAmount

	self.RegenRatio = NewRatio
	self.RegenAmount = NewRegenAmount

	task.spawn(function()
		task.wait(Duration)
		self.RegenRatio = DefaultRatio
		self.RegenAmount = DefaultRegenAmount
	end)
end

function StaminaClass:DisableAutoStaminaRegen()
	self.AutoRegenStamin = false
end

function StaminaClass:EnableAutoStaminaRegen()
	self.AutoRegenStamin = true
end

function StaminaClass:IncreaseStamina(AddAmount:number)
	if self.Stamina == self.MaxStamina then
		self.MaxStamina += AddAmount
		self.Stamina = self.MaxStamina
		self.Player:SetAttribute("Stamina", self.Stamina)
	else
		self.MaxStamina += AddAmount
	end
	
	self.Player:SetAttribute("MaxStamina", self.MaxStamina)
	SetNewMaxStaminaEvent:FireClient(self.Player)
end

function StaminaClass:ResetStamina()
	local oldMax = self.MaxStamina
	self.MaxStamina = self.DEFAULT_MAX_STAMINA

	-- Scale down stamina proportionally if it exceeds new max
	if self.Stamina > self.MaxStamina then
		local percent = self.Stamina / oldMax
		self.Stamina = math.floor(self.MaxStamina * percent)
		self.Player:SetAttribute("Stamina", self.Stamina)
	end

	self.Player:SetAttribute("MaxStamina", self.MaxStamina)
	SetNewMaxStaminaEvent:FireClient(self.Player)
end

return StaminaClass
