--!strict
--!native
--[[
	Procedural Lightning Effect Module. By Quasiduck
	License: https://github.com/SamyBlue/Lightning-Beams/blob/main/LICENSE
	See README for guide on how to use or scroll down to see all properties in LightningBolt.new
	All properties update in real-time except PartCount which requires a new LightningBolt to change
	i.e. You can change a property at any time after a LightningBolt instance is created and it will still update the look of the bolt
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require("../../ModuleUtils/_Signal")

local cachedProperties = setmetatable({}, { __mode = "k" })

-- Tolerance values for detecting significant changes.
local SIZE_TOLERANCE = 0.05
local TRANSPARENCY_TOLERANCE = 0.05
local COLOR_TOLERANCE = 0.1

local PARTS_IN_CACHE = 10000 -- Default was 5000, recommended higher if using sparks.
local RunService = game:GetService("RunService")
local parent = workspace:FindFirstChildOfClass("Terrain")
local rng = Random.new()
local math = math
local Vector3 = Vector3
local CFrame = CFrame

--*Part Cache Setup
--New parts automatically get added to cache if more parts are requested for use where a warning is thrown

local BoltPart = Instance.new("Part") --Template primitive that will make up the entire bolt
BoltPart.TopSurface, BoltPart.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
BoltPart.Anchored, BoltPart.CanCollide = true, false
BoltPart.Locked, BoltPart.CastShadow = true, false
BoltPart.CanTouch, BoltPart.CanQuery = false, false
BoltPart.Shape = Enum.PartType.Cylinder
BoltPart.Name = "BoltPart"
BoltPart.Material = Enum.Material.Neon
BoltPart.Color = Color3.new(1, 1, 1)
BoltPart.Transparency = 1
BoltPart.CastShadow = false

local PartCache = require("../../ModuleUtils/_PartCache")
local LightningCache = PartCache.new(BoltPart, PARTS_IN_CACHE, parent)

local function CubicBezier(PercentAlongBolt, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3): Vector3
	PercentAlongBolt = tonumber(PercentAlongBolt) or 0
	return p0 * (1 - PercentAlongBolt) ^ 3
		+ p1 * 3 * PercentAlongBolt * (1 - PercentAlongBolt) ^ 2
		+ p2 * 3 * (1 - PercentAlongBolt) * PercentAlongBolt ^ 2
		+ p3 * PercentAlongBolt ^ 3
end

local function DiscretePulse(PercentAlongBolt, TimePassed, s, k, f, min, max): number
	PercentAlongBolt = tonumber(PercentAlongBolt) or 0
	TimePassed = tonumber(TimePassed) or 0
	s = tonumber(s) or 1
	k = tonumber(k) or 1000000
	f = tonumber(f) or 0.5
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	-- Ensure the lower bound is not greater than the upper bound.
	local lowerBound = math.min(min, max)
	local upperBound = math.max(min, max)
	return math.clamp(k / (2 * f) - math.abs((PercentAlongBolt - TimePassed * s + 0.5 * k) / f), lowerBound, upperBound)
end

local function ExtrudeCenter(PercentAlongBolt): number
	PercentAlongBolt = tonumber(PercentAlongBolt) or 0
	return math.exp(-5000 * (PercentAlongBolt - 0.5) ^ 10)
end

local function NoiseBetween(x: number, y: number?, z: number?, min, max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return min + (max - min) * (math.noise(x, y, z) + 0.5)
end

local xInverse = CFrame.new(Vector3.zero, Vector3.xAxis):Inverse()
local offsetAngle = math.cos(math.pi*0.5) --math.cos(math.rad(90))

local ActiveBranches : {LightningBolt} = {} --Contains all LightningBolt instances
local LightningBolt = {} --Define new class
LightningBolt.__type = "LightningBolt"
LightningBolt.__index = LightningBolt

--Small tip: You don't need to use actual Roblox Attachments below. You can also create "fake" ones as follows:
--[[
	local A1, A2 = {}, {}
	A1.WorldPosition, A1.WorldAxis = chosenPos1, chosenAxis1
	A2.WorldPosition, A2.WorldAxis = chosenPos2, chosenAxis2
	local NewBolt = LightningBolt.new(A1, A2, 40)
--]]
export type FakeAttachment = {
	WorldPosition: Vector3,
	WorldAxis: Vector3,
}
export type LightningBolt = typeof(setmetatable({} :: {
	Enabled: boolean,
	Attachment0: Attachment | FakeAttachment,
	Attachment1: Attachment | FakeAttachment,
	CurveSize0: number,
	CurveSize1: number,
	MinRadius: number,
	MaxRadius: number,
	Frequency: number,
	AnimationSpeed: number,
	Thickness: number,
	MinThicknessMultiplier: number,
	MaxThicknessMultiplier: number,
	MinTransparency: number,
	MaxTransparency: number,
	PulseSpeed: number,
	PulseLength: number,
	FadeLength: number,
	ContractFrom: number,
	Color: ColorSequence | Color3,
	ColorOffsetSpeed: number,
	SpaceCurveFunction: (...any) -> Vector3,
	OpacityProfileFunction: (...any) -> number,
	RadialProfileFunction: (...any) -> number,
	Velocity: Vector3?,
	Destroying: Signal.GenericSignal,
	Destroyed: boolean,
	_Parts: {BasePart},
	_PartsHidden: boolean,
	_DisabledTransparency: number,
	_StartT: number,
	_RanNum: number,
	_RefIndex: number,
}, LightningBolt))

function LightningBolt.new(Attachment0: Attachment | FakeAttachment, Attachment1: Attachment | FakeAttachment, PartCount): LightningBolt
	PartCount = tonumber(PartCount) or 30
	local self = setmetatable({
		-- Bolt Appearance Properties
		Enabled = true, -- Hides bolt without removing any parts when false
		Attachment0 = Attachment0, Attachment1 = Attachment1, -- Bolt originates from Attachment0 and ends at Attachment1
		CurveSize0 = 0, CurveSize1 = 0, -- Works similarly to roblox beams. See https://dk135eecbplh9.cloudfront.net/assets/blt160ad3fdeadd4ff2/BeamCurve1.png
		MinRadius = 0, MaxRadius = 2.4, -- Governs the amplitude of fluctuations throughout the bolt
		Frequency = 1, -- Governs the frequency of fluctuations throughout the bolt. Lower this to remove jittery-looking lightning
		AnimationSpeed = 7, -- Governs how fast the bolt oscillates (i.e. how fast the fluctuating wave travels along bolt)
		Thickness = 1, -- The thickness of the bolt
		MinThicknessMultiplier = 0.2, MaxThicknessMultiplier = 1, -- Multiplies Thickness value by a fluctuating random value between MinThicknessMultiplier and MaxThicknessMultiplier along the Bolt

		-- Bolt Kinetic Properties
		--[[
			Allows for fading in (or out) of the bolt with time. Can also create a "projectile" bolt
			Recommend setting AnimationSpeed to 0 if used as projectile (for better aesthetics)
			Works by passing a "wave" function which travels from left to right where the wave height represents opacity (opacity being 1 - Transparency)
			See https://www.desmos.com/calculator/hg5h4fpfim to help customise the shape of the wave with the below properties
		--]]
		MinTransparency = 0, MaxTransparency = 1,
		PulseSpeed = 2, -- Bolt arrives at Attachment1 1/PulseSpeed seconds later
		PulseLength  = 1000000,
		FadeLength = 0.2,
		ContractFrom = 0.5, -- Parts shorten or grow once their Transparency exceeds this value. Set to a value above 1 to turn effect off. See https://imgur.com/OChA441

		-- Bolt Color Properties
		Color = Color3.new(1, 1, 1), -- Can be a Color3 or ColorSequence
		ColorOffsetSpeed = 3, -- Sets speed at which ColorSequence travels along Bolt

		-- Advanced Properties
		--[[
			Allows you to pass a custom space curve for the bolt to be defined along
			Constraints: 
				-First input passed must be a parameter representing PercentAlongBolt between values 0 and 1
			Example: self.SpaceCurveFunction = VivianiCurve(PercentAlongBolt)
		--]]
		SpaceCurveFunction = CubicBezier,

		--[[
			Allows you to pass a custom opacity profile which controls the opacity along the bolt
			Constraints: 
				-First input passed must be a parameter representing PercentAlongBolt between values 0 and 1
				-Second input passed must be a parameter representing TimePassed since instantiation 
			Example: self.OpacityProfileFunction = MovingSineWave(PercentAlongBolt, TimePassed)
			Note: You may want to set self.ContractFrom to a value above 1 if you pass a custom opacity profile as contraction was designed to work with DiscretePulse
		--]]
		OpacityProfileFunction = DiscretePulse,

		--[[
			Allows you to pass a custom radial profile which controls the radius of control points along the bolt
			Constraints: 
				-First input passed must be a parameter representing PercentAlongBolt between values 0 and 1
		--]]
		RadialProfileFunction = ExtrudeCenter,

		-- Private variables, should not be changed manually.
		Destroying = Signal.new(), -- fake .Destroying Signal
		Destroyed = false, -- true if :Destroy() is called on it.
		_Parts = table.create(tonumber(PartCount) or 30), -- The BoltParts which make up the Bolt
		_PartsHidden = false,
		_DisabledTransparency = 1,
		_StartT = os.clock(),
		_RanNum = rng:NextNumber(0, 100),
		_RefIndex = #ActiveBranches + 1,
	}, LightningBolt)

	for i = 1, PartCount do
		self._Parts[i] = LightningCache:GetPart()
	end
	ActiveBranches[self._RefIndex] = self
	return self
end

function LightningBolt:Destroy()
	if getmetatable(self) ~= LightningBolt then return end -- make sure it works lol
	self = self :: LightningBolt

	ActiveBranches[self._RefIndex] = nil
	--task.synchronize()
	for i = 1, #self._Parts do
		LightningCache:ReturnPart(self._Parts[i])
	end

	self.Destroying:Fire()
	self.Destroyed = true
	self = nil :: any
end

--Calls Destroy() after TimeLength seconds where a dissipating effect takes place in the meantime
function LightningBolt:DestroyDissipate(TimeLength, Strength)
	if getmetatable(self) ~= LightningBolt then return end -- make sure it works lol
	self = self :: LightningBolt

	TimeLength = tonumber(TimeLength) or 0.2
	Strength = tonumber(Strength) or 0.5
	local DissipateStartT = os.clock()
	local start, mid, goal = self.MinTransparency, self.ContractFrom, self.ContractFrom
		+ 1 / (#self._Parts * self.FadeLength)
	local StartRadius = self.MaxRadius
	local StartMinThick = self.MinThicknessMultiplier
	local DissipateLoop: RBXScriptConnection?
	
	--task.synchronize()
	DissipateLoop = RunService.Heartbeat:Connect(function()
		local TimeSinceDissipate = os.clock() - DissipateStartT
		self.MinThicknessMultiplier = StartMinThick + (-2 - StartMinThick) * TimeSinceDissipate / TimeLength

		if TimeSinceDissipate < TimeLength * 0.4 then
			local interp = (TimeSinceDissipate / (TimeLength * 0.4))
			self.MinTransparency = start + (mid - start) * interp
		elseif TimeSinceDissipate < TimeLength then
			local interp = ((TimeSinceDissipate - TimeLength * 0.4) / (TimeLength * 0.6))
			self.MinTransparency = mid + (goal - mid) * interp
			self.MaxRadius = StartRadius * (1 + Strength * interp)
			self.MinRadius = self.MinRadius + (self.MaxRadius - self.MinRadius) * interp
		else
			-- Destroy Bolt
			local TimePassed = os.clock() - self._StartT
			local Lifetime = (self.PulseLength + 1) / self.PulseSpeed

			--task.synchronize()
			if TimePassed < Lifetime then --prevents Destroy()ing twice
				self:Destroy()
			end

			-- Disconnect Loop
			if DissipateLoop then
				DissipateLoop:Disconnect()
				DissipateLoop = nil
			end
		end
	end)
	--task.desynchronize()
end

function LightningBolt:_UpdateGeometry(BPart: BasePart, PercentAlongBolt: number, TimePassed: number, ThicknessNoiseMultiplier: number, PrevPoint: Vector3, NextPoint: Vector3): (CFrame?)
	debug.profilebegin("UPDATE_GEOMETRY")
	self = self :: LightningBolt

	-- Compute opacity for this particular section
	local MinOpa, MaxOpa = 1 - self.MaxTransparency, 1 - self.MinTransparency
	local Opacity = self.OpacityProfileFunction(PercentAlongBolt, TimePassed, self.PulseSpeed, self.PulseLength, self.FadeLength, MinOpa, MaxOpa)

	-- Compute thickness for this particular section
	local Thickness = (tonumber(self.Thickness) or 1) * ThicknessNoiseMultiplier * Opacity
	Opacity = Thickness > 0 and Opacity or 0

	-- Compute + update sizing and orientation of this section
	local contractf = 1 - self.ContractFrom
	local PartsN = #self._Parts
	local posDifference = NextPoint - PrevPoint

	local newSize, newTransparency, newCFrame

	if Opacity > contractf then
		newSize = Vector3.new(posDifference.Magnitude, Thickness, Thickness)
		newCFrame = CFrame.new((PrevPoint + NextPoint) * 0.5, NextPoint) * xInverse
		newTransparency = 1 - Opacity
	elseif Opacity > contractf - 1 / (PartsN * self.FadeLength) then
		local interp = (1 - (Opacity - (contractf - 1 / (PartsN * self.FadeLength))) * PartsN * self.FadeLength)
			* (PercentAlongBolt < TimePassed * self.PulseSpeed - 0.5 * self.PulseLength and 1 or -1)
		newSize = Vector3.new((1 - math.abs(interp)) * posDifference.Magnitude, Thickness, Thickness)
		newCFrame = CFrame.new(PrevPoint + posDifference * (math.max(0, interp) + 0.5 * (1 - math.abs(interp))), NextPoint) * xInverse
		newTransparency = 1 - Opacity
	else
		newTransparency = 1
	end

	-- Get or create the cached properties for this part.
	local cache = cachedProperties[BPart]
	if not cache then
		cache = {}
		cachedProperties[BPart] = cache
	end

	-- Update Size only if significantly different.
	if newSize then
		-- Use the cached size instead of doing BPart.Size (a namecall) every frame.
		if not cache.Size or (cache.Size - newSize).Magnitude > SIZE_TOLERANCE then
			BPart.Size = newSize
			cache.Size = newSize
		end
	end

	-- Update Transparency only if significantly different.
	if cache.Transparency == nil then
		cache.Transparency = BPart.Transparency
	end
	if math.abs(cache.Transparency - newTransparency) > TRANSPARENCY_TOLERANCE then
		BPart.Transparency = newTransparency
		cache.Transparency = newTransparency
	end
	
	debug.profileend()
	return newCFrame
end

local function colorDifference(a: Color3, b: Color3): number
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B)
end

function LightningBolt:_UpdateColor(BPart, PercentAlongBolt, TimePassed): ()
	self = self :: LightningBolt

	local col: Color3 = self.Color
	if typeof(col) == "ColorSequence" then
		local t1 = (self._RanNum + PercentAlongBolt - TimePassed * self.ColorOffsetSpeed) % 1
		local keypoints = self.Color.Keypoints
		for i = 1, #keypoints - 1 do
			if keypoints[i].Time < t1 and t1 < keypoints[i + 1].Time then
				col = keypoints[i].Value:Lerp(
					keypoints[i + 1].Value,
					(t1 - keypoints[i].Time) / (keypoints[i + 1].Time - keypoints[i].Time)
				)
				break
			end
		end
	end

	-- Get or create the cache for Color.
	local cache = cachedProperties[BPart]
	if not cache then
		cache = {}
		cachedProperties[BPart] = cache
	end

	if not cache.Color then
		cache.Color = BPart.Color
	end

	if colorDifference(cache.Color, col) > COLOR_TOLERANCE then
		BPart.Color = col
		cache.Color = col
	end
end

function LightningBolt:_Disable()
	if getmetatable(self) ~= LightningBolt then return end
	self = self :: LightningBolt

	self.Enabled = false
	--task.synchronize() -- property changes aren't allowed in parallel
	for _, BPart in self._Parts do
		BPart.Transparency = self._DisabledTransparency
	end
end

local bulkParts = {}
local bulkCFrames = {}
RunService.Heartbeat:Connect(function()
	for _, ThisBranch in ActiveBranches do
		if ThisBranch.Enabled ~= true then
			if not ThisBranch._PartsHidden then
				ThisBranch._PartsHidden = true
				ThisBranch:_Disable()
			end
			continue
		end

		ThisBranch._PartsHidden = false

		-- Extract important variables
		local MinRadius, MaxRadius = ThisBranch.MinRadius, ThisBranch.MaxRadius
		local Parts = ThisBranch._Parts
		local PartsN = #Parts
		local RanNum = ThisBranch._RanNum
		local spd = ThisBranch.AnimationSpeed
		local freq = ThisBranch.Frequency
		local MinThick, MaxThick = ThisBranch.MinThicknessMultiplier, ThisBranch.MaxThicknessMultiplier
		local TimePassed = os.clock() - ThisBranch._StartT
		local SpaceCurveFunction, RadialProfileFunction =
			ThisBranch.SpaceCurveFunction, ThisBranch.RadialProfileFunction
		local Lifetime = (ThisBranch.PulseLength + 1) / ThisBranch.PulseSpeed

		-- Extract control points
		local a0, a1, CurveSize0, CurveSize1 =
			ThisBranch.Attachment0, ThisBranch.Attachment1, ThisBranch.CurveSize0, ThisBranch.CurveSize1
		local p0, p1, p2, p3 = a0.WorldPosition, a0.WorldPosition
			+ a0.WorldAxis * CurveSize0, a1.WorldPosition
		- a1.WorldAxis * CurveSize1, a1.WorldPosition

		-- Initialise iterative scheme for generating points along space curve
		local init = SpaceCurveFunction(0, p0, p1, p2, p3)
		local PrevPoint, bezier0 = init, init

		-- Update
		if TimePassed >= Lifetime then pcall(ThisBranch.Destroy, ThisBranch) continue end
		
		local parts = {}
		local cframes = {}
		
		for i, BPart in Parts do
			local PercentAlongBolt = i / PartsN

			--Compute noisy inputs
			local input, input2 = -TimePassed*spd + freq*10*PercentAlongBolt - 0.2 + RanNum*4, 5*((-TimePassed*spd*0.01)/10 + freq*PercentAlongBolt) + RanNum*4

			local noise0 = NoiseBetween(5*input, 1.5, input2, 0, 0.2*math.pi)
				+ NoiseBetween(0.5*input, 1.5, 0.1*input2, 0, 1.8*math.pi)
			local noise1 = NoiseBetween(3.4, input2, input, MinRadius, MaxRadius)
				* RadialProfileFunction(PercentAlongBolt)
			local thicknessNoise = NoiseBetween(2.3, input2, input, MinThick, MaxThick)

			--Find next point along space curve
			local bezier1 = SpaceCurveFunction(PercentAlongBolt, p0, p1, p2, p3)

			--Find next point along bolt
			local NextPoint = i ~= PartsN
				and (CFrame.new(bezier0, bezier1) * CFrame.Angles(0, 0, noise0) * CFrame.Angles(
					math.acos(math.clamp(NoiseBetween(input2, input, 2.7, offsetAngle, 1), -1, 1)),
					0,
					0
					) * CFrame.new(0, 0, -noise1)).Position
				or bezier1
			
			local cframe = ThisBranch:_UpdateGeometry(BPart, PercentAlongBolt, TimePassed, thicknessNoise, PrevPoint, NextPoint)
			ThisBranch:_UpdateColor(BPart, PercentAlongBolt, TimePassed)
			if cframe then
				table.insert(bulkParts, BPart)
				table.insert(bulkCFrames, cframe)
			end
			PrevPoint, bezier0 = NextPoint, bezier1
		end
	end
	
	if #bulkParts > 0 then
		workspace:BulkMoveTo(bulkParts, bulkCFrames, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(bulkParts)
		table.clear(bulkCFrames)
	end
end)

return LightningBolt