--!strict
--!native
--Properties do not update in realtime here
--i.e. You can't change explosion properties at any time beyond the initial function execution
local LightningBolt = require("./_LightningBolt")
local LightningSparks = require("./_LightningSparks")
local rng = Random.new()

local function RandomVectorOffsetBetween(vector: Vector3, minAngle: number, maxAngle: number): Vector3 -- returns uniformly-distributed random unit vector no more than maxAngle radians away from v and no less than minAngle radians
	return (
		CFrame.new(Vector3.zero, vector)
		* CFrame.Angles(0, 0, rng:NextNumber(0, 2*math.pi))
		* CFrame.Angles(math.acos(rng:NextNumber(math.cos(maxAngle), math.cos(minAngle))), 0, 0)
	).LookVector
end

local particles = {
	ExplosionBrightspot = script:WaitForChild("ExplosionBrightspot"):Clone(),
	GlareEmitter = script:WaitForChild("GlareEmitter"):Clone(),
	PlasmaEmitter = script:WaitForChild("PlasmaEmitter"):Clone()
}
local ActiveExplosions = {}

local LightningExplosion = {}
LightningExplosion.__type = "LightningExplosion"
LightningExplosion.__index = LightningExplosion

export type LightningExplosion = typeof(setmetatable({} :: {
	Size: number,
	NumBolts: number,
	BoltPartCount: number,
	Color: (Color3 | ColorSequence),
	BoltColor: (Color3 | ColorSequence),
	UpVector: Vector3,
	Bolts: {LightningBolt.LightningBolt},
	Attachment: Attachment,
	Part: Part,
	StartT: number,
}, LightningExplosion))

local function newExplosionBolt(Explosion: LightningExplosion)
	local A1, A2 = {}, {}

	A1.WorldPosition, A1.WorldAxis = Explosion.Attachment.WorldPosition, RandomVectorOffsetBetween(Explosion.UpVector, math.rad(65), math.rad(80))
	A2.WorldPosition, A2.WorldAxis = Explosion.Attachment.WorldPosition + A1.WorldAxis*rng:NextNumber(20, 40)*1.4*Explosion.Size, RandomVectorOffsetBetween(-Explosion.UpVector, math.rad(70), math.rad(110))
	--local curve0, curve1 = rng:NextNumber(0, 10)*size, rng:NextNumber(0, 10)*size
	local NewBolt = LightningBolt.new(A1, A2, Explosion.BoltPartCount)
	NewBolt.AnimationSpeed = 0
	NewBolt.Thickness = 1 --*size
	NewBolt.Color = Explosion.BoltColor
	NewBolt.PulseLength = 0.8
	NewBolt.ColorOffsetSpeed = 20
	NewBolt.Frequency = 2
	NewBolt.MinRadius, NewBolt.MaxRadius = 0, 4*Explosion.Size
	NewBolt.FadeLength = 0.4
	NewBolt.PulseSpeed = 5
	NewBolt.MinThicknessMultiplier, NewBolt.MaxThicknessMultiplier = 0.7, 1

	local NewSparks = LightningSparks.new(NewBolt, 5)
	NewSparks.MinDistance, NewSparks.MaxDistance = 7.5, 10
	NewBolt.Velocity = (A2.WorldPosition - A1.WorldPosition).Unit*0.1*Explosion.Size
	--NewBolt.v0, NewBolt.v1 = rng:NextNumber(0, 5)*size, rng:NextNumber(0, 5)*size

	table.insert(Explosion.Bolts, NewBolt)
end

local expPart = Instance.new("Part")
expPart.Name = "LightningExplosion"
expPart.Anchored = true
expPart.CanCollide = false
expPart.Locked = true
expPart.CastShadow = false
expPart.Transparency = 1
expPart.Size = Vector3.one * 0.001
expPart.Parent = script

function LightningExplosion.new(Position: Vector3, Size: number?, NumBolts: number?, BoltPartCount: number?, Color: (Color3 | ColorSequence)?, BoltColor: (Color3 | ColorSequence)?, UpVector: Vector3?)
	local self = {}
	local color: (Color3 | ColorSequence) = Color or ColorSequence.new(Color3.new(math.random(), math.random(), math.random()), Color3.new(math.random(), math.random(), math.random()))
	self.Size = Size and math.clamp(Size, 0, 1) or 1 --Value between 0 and 1 (1 for largest)
	self.NumBolts = NumBolts or 14 --Number of lightning bolts shot out from explosion
	self.BoltPartCount = BoltPartCount or 10
	self.Color = color --Can be a Color3 or ColorSequence
	self.BoltColor = BoltColor or (if typeof(color)=="Color3" then color else color.Keypoints[1].Value:Lerp(color.Keypoints[2].Value, 0.5)) --Can be a Color3 or ColorSequence
	self.UpVector = UpVector or Vector3.yAxis --Can be used to "rotate" the explosion
	
	local parent = workspace.CurrentCamera
	local size = math.clamp(self.Size, 0, 1)
	local color = self.Color
	
	local part = expPart:Clone()
	local attach = Instance.new("Attachment", part)
	part.Name = "LightningExplosion"
	part.Anchored = true
	part.CanCollide = false
	part.Locked = true
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.001
	part.CFrame = CFrame.new(Position + (Vector3.yAxis*0.5), Position + (Vector3.yAxis*0.5) + self.UpVector)*CFrame.new(Vector3.zero, Vector3.yAxis):Inverse()
	part.Parent = parent
	
	attach.CFrame = CFrame.identity
	attach.Parent = part
	
	self.Bolts = {}
	self.Attachment = attach
	self.Part = part
	self.StartT = workspace.DistributedGameTime
	self.RefIndex = #ActiveExplosions + 1

	setmetatable(self, LightningExplosion)
	
	local partEmit1 = particles.ExplosionBrightspot:Clone()
	local partEmit2 = particles.GlareEmitter:Clone()
	local partEmit3 = particles.PlasmaEmitter:Clone()
	
	partEmit2.Size = NumberSequence.new(30*size)
	partEmit3.Size = NumberSequence.new(18*size)
	partEmit3.Speed = NumberRange.new(100*size)
	
	partEmit1.Parent = attach
	partEmit2.Parent = attach
	partEmit3.Parent = attach
	
	if typeof(color) == "Color3" then
		partEmit2.Color, partEmit3.Color = ColorSequence.new(color), ColorSequence.new(color)
		local cH, cS, cV = color:ToHSV()
		partEmit1.Color = ColorSequence.new(Color3.fromHSV(cH, 0.5, cV))
	else --ColorSequence
		partEmit2.Color, partEmit3.Color = color, color
		local keypoints = color.Keypoints 
		for i = 1, #keypoints do
			local cH, cS, cV = keypoints[i].Value:ToHSV()
			keypoints[i] = ColorSequenceKeypoint.new(keypoints[i].Time, Color3.fromHSV(cH, 0.5, cV))
		end
		partEmit1.Color = ColorSequence.new(keypoints)
	end
	
	partEmit1.Enabled, partEmit2.Enabled, partEmit3.Enabled = true, true, true
	
	for _ = 1, self.NumBolts do
		task.spawn(newExplosionBolt, self)
	end

	ActiveExplosions[self.RefIndex] = self
	return self
end

local changeHandlers: {[string]: (LightningExplosion, any, any) -> ()} = {
	["Size"] = function(Explosion, oldValue, newValue)
		newValue = tonumber(newValue)
		if not newValue then return end
		if math.clamp(newValue, 0, 1) ~= newValue then
			newValue = math.clamp(newValue, 0, 1)
			Explosion.Size = newValue
			return
		end
		for _, NewBolt in Explosion.Bolts do
			NewBolt.MaxRadius = 4 * newValue
			local A1 = NewBolt.Attachment0
			local A2 = NewBolt.Attachment1 :: Attachment
			A2.WorldPosition = (A2.WorldPosition / oldValue) * newValue
		end
		
		local partEmit2 = Explosion.Attachment:FindFirstChild("GlareEmitter")
		local partEmit3 = Explosion.Attachment:FindFirstChild("PlasmaEmitter")
		if partEmit2 and partEmit2:IsA("ParticleEmitter") then partEmit2.Size = NumberSequence.new(30*newValue) end
		if partEmit3 and partEmit3:IsA("ParticleEmitter") then
			partEmit3.Size = NumberSequence.new(18*newValue)
			partEmit3.Speed = NumberRange.new(100*newValue)
		end
	end,
	
	["NumBolts"] = function(Explosion, oldValue, newValue)
		newValue = tonumber(newValue)
		if not newValue or math.round(newValue - oldValue)==0 then return end
		local diff = math.round(newValue - oldValue)
		if diff < 0 then diff = -diff end
		if math.round(newValue) == 0 then
			for _, v in Explosion.Bolts do
				v:Destroy()
			end
			table.clear(Explosion.Bolts)
		end
		if newValue > oldValue then
			for _ = 1, diff do
				task.spawn(newExplosionBolt, Explosion)
			end
		else
			local boltcount = #Explosion.Bolts
			for i = 0, diff-1 do
				local ind = boltcount - i
				Explosion.Bolts[ind]:Destroy()
				table.remove(Explosion.Bolts, ind)
			end
		end
	end,
	
	["BoltColor"] = function(Explosion, oldValue, newValue)
		if typeof(newValue)~="Color3" and typeof(newValue)~="ColorSequence" then return end
		for _, v in Explosion.Bolts do
			v.Color = newValue
		end
	end,
	
	["Color"] = function(Explosion, oldValue, newValue)
		local partEmit1 = Explosion.Attachment:FindFirstChild("ExplosionBrightspot")
		local partEmit2 = Explosion.Attachment:FindFirstChild("GlareEmitter"):Clone()
		local partEmit3 = Explosion.Attachment:FindFirstChild("PlasmaEmitter"):Clone()
		
		if typeof(newValue) == "Color3" then
			local sequence = ColorSequence.new(newValue)
			if partEmit2 and partEmit2:IsA("ParticleEmitter") then partEmit2.Color = sequence end
			if partEmit3 and partEmit3:IsA("ParticleEmitter") then partEmit3.Color = sequence end
			local cH, cS, cV = newValue:ToHSV()
			if partEmit1 and partEmit1:IsA("ParticleEmitter") then partEmit1.Color = ColorSequence.new(Color3.fromHSV(cH, 0.5, cV)) end
		else -- ColorSequence
			if partEmit2 and partEmit2:IsA("ParticleEmitter") then partEmit2.Color = newValue end
			if partEmit3 and partEmit3:IsA("ParticleEmitter") then partEmit3.Color = newValue end
			local keypoints = newValue.Keypoints 
			for i = 1, #keypoints do
				local cH, cS, cV = keypoints[i].Value:ToHSV()
				keypoints[i] = ColorSequenceKeypoint.new(keypoints[i].Time, Color3.fromHSV(cH, 0.5, cV))
			end
			if partEmit1 and partEmit1:IsA("ParticleEmitter") then partEmit1.Color = ColorSequence.new(keypoints) end
		end
	end,
}

function LightningExplosion:__newindex(index, value)
	if getmetatable(self)~=LightningExplosion or value==nil then return end
	if changeHandlers[index] then
		local oldValue = rawget(self :: any, index) -- dies from cringe
		rawset(self :: any, index, value) -- aughhhhhh
		task.spawn(changeHandlers[index] :: any, self, oldValue, value)
	end
end

function LightningExplosion:Destroy()
	ActiveExplosions[self.RefIndex] = nil
	pcall(game.Destroy, self.Part) -- ye this is a thing you can do
	
	table.clear(self.Bolts)
end

setmetatable(ActiveExplosions, {__newindex = function(self, index, value)
	if type(value)=="table" and getmetatable(value)~=nil and getmetatable(value).__index == LightningExplosion then
		task.delay(0.2, function()
			for _, v in value.Attachment:GetDescendants() do
				if not v:IsA("ParticleEmitter") then continue end
				v.Enabled = false
			end
			task.wait(0.5)
			value:Destroy()
		end)
	end
end,})

return LightningExplosion