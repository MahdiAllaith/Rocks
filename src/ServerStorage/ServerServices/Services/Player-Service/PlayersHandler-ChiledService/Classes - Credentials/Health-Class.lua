local HealthClass = {}
HealthClass.__index = HealthClass

local MUtilies = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local FUtils = require(game.ReplicatedStorage.Utilities.FunctionUtils)

local SetNewMaxHealthEvent = game.ReplicatedStorage.Events.Player.SetNewMaxHealth

export type HealthClassType = typeof(setmetatable({} :: {
	MaxHealth: number,
	Health: number,
	DeathSignal: RBXScriptSignal
}, HealthClass))


function HealthClass.Init(player: Player, DATA) 
	local self = setmetatable({}, HealthClass)
	
	self.Player = player
	
	local DeathSignal: MUtilies.Signal<any> = MUtilies.Signal.new()
	
	-- Will be accessed or seen
	self.DEFAULT_MAX_HEALTH = 100
	
	self.MaxHealth = 100
	self.Health = 100
	self.DeathSignal = DeathSignal
	
	DeathSignal:Connect(function()
		-- resets Health to max after death
		warn("player dead know resets health")
		self.Health = self.MaxHealth
		self.Player:SetAttribute("Health", self.MaxHealth)
	end)
	
	self.AutoHealthRegen = true -- by default enabled
	self.RegenRatio = 1 -- every one second
	self.RegenAmount = 2 -- 5% of max health

	-- counter for staking debuff handling
	self.BleedCount = 0

	self.Player:SetAttribute("MaxHealth", self.MaxHealth)
	self.Player:SetAttribute("Health", self.Health)
	
	self._isRegenning = false

	-- Regen loop function
	function self:_startRegenLoop()
		if self._isRegenning then
			return
		end
		self._isRegenning = true

		task.spawn(function()
			while true do
				-- stop conditions
				if not self.AutoHealthRegen then break end
				if self.Health >= self.MaxHealth then break end

				-- wait the ratio
				task.wait(self.RegenRatio)
				if not self.AutoHealthRegen then break end
				
				
				self.Health += self.RegenAmount

				if self.Health > self.MaxHealth then
					self.Health = self.MaxHealth
				end
				-- update health for client ui to respoonse
				self.Player:SetAttribute("Health", self.Health)
			end

			self._isRegenning = false
		end)
	end

	-- Watch for health changes to possibly kickstart regen if eligible
	self.Player:GetAttributeChangedSignal("Health"):Connect(function()
		local attrHealth = self.Player:GetAttribute("Health")
		if self.AutoHealthRegen and self.Health < self.MaxHealth then
			self:_startRegenLoop()
		end
	end)

	-- Kick off initial regen if needed
	if self.AutoHealthRegen and self.Health < self.MaxHealth then
		self:_startRegenLoop()
	end

	return self
end


--	local isRegenning = false
	

--	self.Player:GetAttributeChangedSignal("Health"):Connect(function()
--		if not self.AutoHealthRegen then return end
--		if self.Health < self.MaxHealth then
			
--			isRegenning = true
--			task.delay(self.RegenRatio,function()
--				self.Health += self.RegenAmount

--				if self.Health > self.MaxHealth then
--					self.Health = self.MaxHealth
--				end
--				-- update health for client ui to respoonse
--				self.Player:SetAttribute("Health", self.Health)
				
--				isRegenning = false
--			end)
--		end
--	end)

--	return self
--end

-- YOU DO THIS ONLY IF YOU WANT TO GET CLASS DATA WHEN USING THE DOT(.) OPREATOR
--function HealthClass.Deduct(self: ClassType)
--	self.Health -= amount
--end

function HealthClass:Add(amount: number)
	amount = math.abs(amount) -- always positive

	self.Health += amount

	if self.Health > self.MaxHealth then
		self.Health = self.MaxHealth
	end

	self.Player:SetAttribute("Health", self.Health)
end

function HealthClass:Deduct(amount: number)
	amount = math.abs(amount) -- always positive

	self.Health -= amount

	if self.Health < 0 then
		self.Health = 0
	end

	self.Player:SetAttribute("Health", self.Health)
end

function HealthClass:BloodDeBuffe(duration: number, tickDelay: number, perDelayDeduct: number)
	self.BleedCount += 1
	self.AutoHealthRegen = false

	task.spawn(function()
		local laps = 0
		while laps < duration and self.Health > 0 do
			--self.Health -= perDelayDeduct
			--if self.Health < 0 then
			--	self.Health = 0
			--end
			
			-- same logic as up
			self.Health = math.max(self.Health - perDelayDeduct, 0)

			self.Player:SetAttribute("Health", self.Health)

			task.wait(tickDelay)
			laps += tickDelay
		end
		-- When one bleeding effect ends, decrease counter
		self.BleedCount = math.max(self.BleedCount - 1, 0)

		-- If no more bleeding debuffs are active, re-enable AutoHealthRegen
		if self.BleedCount == 0 then
			self.AutoHealthRegen = true
			self:_startRegenLoop()
		end

	end)
end

function HealthClass:FasterRegen(NewRegenAmount:number, NewRatio:number, Duration: number)
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

function HealthClass:DisableAutoHealthRegen()
	self.AutoHealthRegen = false
end

function HealthClass:EnableAutoHealthRegen()
	self.AutoHealthRegen = true
end

function HealthClass:IncreaseHealth(AddAmount:number)	
	if self.Health == self.MaxHealth then
		self.MaxHealth += AddAmount
		self.Health = self.MaxHealth
		self.Player:SetAttribute("Health", self.Health)
	else
		self.MaxHealth += AddAmount
	end
	
	self.Player:SetAttribute("MaxHealth", self.MaxHealth)
	SetNewMaxHealthEvent:FireClient(self.Player)
end

function HealthClass:ResetHealth()
	local oldMax = self.MaxHealth
	self.MaxHealth = self.DEFAULT_MAX_HEALTH

	-- Scale down health proportionally if it exceeds new max
	if self.Health > self.MaxHealth then
		local percent = self.Health / oldMax
		self.Health = math.floor(self.MaxHealth * percent)
		self.Player:SetAttribute("Health", self.Health)
	end

	self.Player:SetAttribute("MaxHealth", self.MaxHealth)
	SetNewMaxHealthEvent:FireClient(self.Player)
end

function HealthClass:IncreaseHealthRegen(AddAmount:number)
	self.RegenAmount += AddAmount
end

function HealthClass:DeductHealthRegen(AddAmount:number)
	self.RegenAmount -= AddAmount
end

return HealthClass
