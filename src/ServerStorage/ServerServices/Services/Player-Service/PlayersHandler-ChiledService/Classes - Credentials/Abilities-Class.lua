local AbilitiesClass = {}
AbilitiesClass.__index = AbilitiesClass

local ResetMotionValuesEvent = game.ReplicatedStorage.Events.Motion.ResetMotionValues

export type AbilitiesClassType = typeof(setmetatable({} :: {
	WalkSpeed :number,
	MaxSlopeAngel :number,
	JumpHeight :number,
	DefaultMaxSlopeAngle : number,
	DefaultWalkSpeed : number,
	DefaultRunSpeed : number,
	DefaultJumpPower : number,
	DefaultHipHeight : number,
}, AbilitiesClass))

function AbilitiesClass.Init(player: Player, DATA)
	local self = setmetatable({}, AbilitiesClass)
	
	self.Player = player
	
	self.WalkSpeed = 16
	self.RunSpeed = 21
	self.JumpPower = 20.001
	
	self.DefaultMaxSlopeAngle = 89
	self.DefaultWalkSpeed = 16
	self.DefaultRunSpeed = 21
	self.DefaultJumpPower = 20.001
	self.DefaultHipHeight = 1.998
		
	player:SetAttribute("CurrentWalkSpeed", self.WalkSpeed)
	player:SetAttribute("CurrentRunSpeed", self.RunSpeed)
	player:SetAttribute("CurrentJumpPower", self.RunSpeed)

	return self
end

--function AbilitiesClass:GetAbilities(player : Player)
--	if player == self.Palyer then
--		return {
--			WalkSpeed = self.WalkSpeed,
--			RunSpeed = self.RunSpeed,
--			JumpHeight = self.JumpHeight
--		}
--	else
--		return warn("Not the current player")
--	end
--end

-- Setter functions
function AbilitiesClass:SetWalkSpeed(value: number)
	self.WalkSpeed = value
end

function AbilitiesClass:SetRunSpeed(value: number)
	self.RunSpeed = value
end

function AbilitiesClass:SetJumpHeight(value: number)
	self.JumpHeight = value
end

-- Timed setter for WalkSpeed
function AbilitiesClass:SetWalkSpeedFor(value: number, duration: number)
	self.WalkSpeed = value
	task.delay(duration, function()
		self.WalkSpeed = self.DefaultWalkSpeed
	end)
end

-- Timed setter for RunSpeed
function AbilitiesClass:SetRunSpeedFor(value: number, duration: number)
	self.RunSpeed = value
	task.delay(duration, function()
		self.RunSpeed = self.DefaultRunSpeed
	end)
end

-- Timed setter for JumpHeight
function AbilitiesClass:SetJumpHeightFor(value: number, duration: number)
	self.JumpHeight = value
	task.delay(duration, function()
		self.JumpHeight = self.DefaultJumpHeight
	end)
end

-- Disable all player movement (walk, run, jump)
function AbilitiesClass:DisableMovement()
	-- If movement is already disabled, do nothing
	if self._SavedMovementState then
		return
	end
	
	self._SavedMovementState = {
		WalkSpeed = self.WalkSpeed,
		RunSpeed = self.RunSpeed,
		JumpPower = self.JumpPower
	}
	

	self.WalkSpeed = 0
	self.RunSpeed = 0
	self.JumpPower = 0

	self.Player:SetAttribute("CurrentWalkSpeed", 0)
	self.Player:SetAttribute("CurrentRunSpeed", 0)
	self.Player:SetAttribute("CurrentJumpPower", 0)

	-- Notify client to reset physics/motion states if needed
	ResetMotionValuesEvent:FireClient(self.Player)
end

-- Re-enable player movement (restore previous values)
function AbilitiesClass:EnableMovement()
	if self._SavedMovementState then
		self.WalkSpeed = self._SavedMovementState.WalkSpeed
		self.RunSpeed = self._SavedMovementState.RunSpeed
		self.JumpPower = self._SavedMovementState.JumpPower
		
		self._SavedMovementState = nil
	else
		-- Fall back to defaults if nothing was saved
		self.WalkSpeed = self.DefaultWalkSpeed
		self.RunSpeed = self.DefaultRunSpeed
		self.JumpPower = self.DefaultJumpPower
	end

	self.Player:SetAttribute("CurrentWalkSpeed", self.WalkSpeed)
	self.Player:SetAttribute("CurrentRunSpeed", self.RunSpeed)
	self.Player:SetAttribute("CurrentJumpPower", self.JumpPower)

	ResetMotionValuesEvent:FireClient(self.Player)
end




function AbilitiesClass:SetKitByPercentage(PerWalkSpeed: number, PerRunSpeed: number, PerJumpPower: number)
	if PerWalkSpeed then
		self.WalkSpeed = self.DefaultWalkSpeed * (1 + PerWalkSpeed / 100)
		self.Player:SetAttribute("CurrentWalkSpeed", self.WalkSpeed)
	end
	if PerRunSpeed then
		self.RunSpeed = self.DefaultRunSpeed * (1 + PerRunSpeed / 100)
		self.Player:SetAttribute("CurrentRunSpeed", self.RunSpeed)
	end
	if PerJumpPower then
		self.JumpPower = self.DefaultJumpPower * (1 + PerJumpPower / 100)
		self.Player:SetAttribute("CurrentJumpPower", self.JumpPower)
	end
	
	ResetMotionValuesEvent:FireClient(self.Player)
	
end

function AbilitiesClass:ResetToDefault()
	self.WalkSpeed = self.DefaultWalkSpeed
	self.RunSpeed = self.DefaultRunSpeed
	self.JumpPower = self.DefaultJumpPower

	self.Player:SetAttribute("CurrentWalkSpeed", self.WalkSpeed)
	self.Player:SetAttribute("CurrentRunSpeed", self.RunSpeed)
	self.Player:SetAttribute("CurrentJumpPower", self.JumpPower)
	
	ResetMotionValuesEvent:FireClient(self.Player)
end


return AbilitiesClass
