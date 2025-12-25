--!strict
--@author: crusherfire
--@date: 6/17/25
--[[@description:
	An object that creates wind-like streams around the player's character.
	
	Improved & type annotation version of onses' WindService:
	https://devforum.roblox.com/t/wind-effect-customizable-module/1024867
]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local FunctionUtils = require("../FunctionUtils")
local Trove = require("../ModuleUtils/_Trove")
local Future = require("../ModuleUtils/_Future")
local t = FunctionUtils.t

-----------------------------
-- TYPES --
-----------------------------
-- For all of the properties/fields of an object made from this class.
type fields = {
	_trove: Trove.TroveType,
	_userData: { [any]: any },
	_startTrove: Trove.TroveType,
	
	_container: any,
	_randomized: boolean,
	_velocity: Vector3,
	_matchGlobalWind: boolean,
	_maxCount: number,
	_lifetimeInSeconds: number,
	_frequency: number,
	_amplitude: number,
	_cameraRange: number,
	_spawnDelay: number,
	_color: ColorSequence,
	_widthScale: NumberSequence,
	
	_activeWind: { { Part: WindPart, CreationTimestamp: number } },
	_active: boolean,
	
	_count: number
}

type WindPart = typeof(script.Wind)

export type WindLineCreatorParams = {
	Container: Instance?, -- where wind instances are stored
	Randomized: boolean?, -- false by default
	Velocity: Vector3?, -- direction & speed of the wind (if randomzied, the random range will be within Velocity)
	MatchGlobalWind: boolean?, -- false by default
	MaxCount: number?, -- how many wind lines should exist at any given point (default is 5)
	LifetimeInSeconds: number?, -- how long the wind lines live for (default is 2 seconds)
	Frequency: number?, -- for sine wave (default is 0.25)
	Amplitude: number?, -- for sine wave (default is 0.05)
	CameraRange: number?, -- up to how far away wind is generated around the player's camera (default is 50 studs)
	SpawnDelay: number?, -- delay between creating wind objects (default is 0)
	Color: ColorSequence?, -- change the color of the wind lines
	WidthScale: NumberSequence?, -- change the WidthScale of the wind trail
}

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local MT = {}
MT.__index = MT
export type WindLineCreator = typeof(setmetatable({} :: fields, MT))

local rng = Random.new(tick())

-- CONSTANTS --
local CAMERA = workspace.CurrentCamera

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-- Returns a future that resolves once the fade is complete.
local function fadeWind(trail: Trail): Future.Future<>
	return Future.new(function(trail: Trail)
		local thread = coroutine.running()
		local start = workspace:GetServerTimeNow()
		local fadeDuration = 2
		local connection
		connection = RunService.PreRender:Connect(function(dt)
			local elapsed = workspace:GetServerTimeNow() - start
			local alpha = math.clamp(elapsed / fadeDuration, 0, 1)
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, alpha),
				NumberSequenceKeypoint.new(0.6, alpha),
				NumberSequenceKeypoint.new(1, 1),
			})
			if alpha >= 1 then
				connection:Disconnect()
				task.spawn(thread)
			end
		end)
		coroutine.yield()
	end, trail)
end

-----------------------------
-- CLASS FUNCTIONS --
-----------------------------

--[[
	Creates a new WindLineCreator.
	Will automatically return an already existing creator.
]]
function Module.new(params: WindLineCreatorParams): WindLineCreator
	local self = setmetatable({} :: fields, MT) :: WindLineCreator
	self._trove = Trove.new()
	self._userData = {}
	
	self._startTrove = self._trove:Construct(Trove)
	
	self._container = params.Container or CAMERA
	self._randomized = params.Randomized or false
	self._velocity = (params.Velocity or Vector3.xAxis) / 50
	self._matchGlobalWind = params.MatchGlobalWind or false
	self._maxCount = params.MaxCount or 5
	self._lifetimeInSeconds = params.LifetimeInSeconds or 2
	self._frequency = params.Frequency or 0.25
	self._amplitude = params.Amplitude or 0.05
	self._cameraRange = params.CameraRange or 50
	self._spawnDelay = params.SpawnDelay or 0
	self._color = params.Color or ColorSequence.new(Color3.new(1, 1, 1))
	self._widthScale = params.WidthScale or NumberSequence.new(1, 0)
	
	self._activeWind = {}
	self._active = false
	self._count = 0
	
	self._trove:Connect(RunService.PreRender, function()
		if not self._active then
			return
		end
		if self._velocity.Magnitude == 0 then
			return
		end
		debug.profilebegin("WIND_CREATOR_UPDATE")
		local parts = {}
		local cframes = {}

		for _, info in self._activeWind do
			local elapsedTime = workspace:GetServerTimeNow() - info.CreationTimestamp
			local maxVelocity = self._velocity
			local velocity =
				if self._randomized
				then Vector3.new(
					rng:NextNumber(-maxVelocity.X, maxVelocity.X),
					rng:NextNumber(-maxVelocity.Y, maxVelocity.Y),
					rng:NextNumber(-maxVelocity.Z, maxVelocity.Z)
				)
				else maxVelocity
			local zOffset = self:_CalculateSineWave(self._amplitude, elapsedTime, self._frequency, 0)
			local newCFrame = info.Part.CFrame * CFrame.new(0, 0, zOffset) + velocity

			table.insert(parts, info.Part)
			table.insert(cframes, newCFrame)
		end

		if #parts > 0 then
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
		debug.profileend()
	end)
	
	if self._matchGlobalWind then
		self._trove:Add(FunctionUtils.Observers.observeProperty(workspace, "GlobalWind", function(globalWind)
			self._velocity = globalWind / 50
			return
		end))
	end
	
	return self
end

function Module:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")

	return getmetatable(object) == MT
end

-----------------------------
-- METHODS --
-----------------------------

--[[
	Creates a new wind line, ignoring any max count limits.
	This is automatically called internally when the creator is started.
]]
function MT.CreateWind(self: WindLineCreator)
	local part = script.Wind:Clone()
	local trail = part.Trail
	trail.Color = self._color
	trail.WidthScale = self._widthScale
	part.Position = self:_GetRandomPosition()
	part.Parent = self._container
	self._count += 1
	local info = {
		Part = part,
		CreationTimestamp = workspace:GetServerTimeNow()
	}
	table.insert(self._activeWind, info)
	task.delay(self._lifetimeInSeconds, function(info, trail)
		fadeWind(trail):After(function()
			local i = table.find(self._activeWind, info)
			if i then
				table.remove(self._activeWind, i)
				self._count -= 1
			end
			info.Part:Destroy()
		end)
	end, info, trail)
end

--[[
	Begins a loop that spawns wind around the player's camera.
]]
function MT.Start(self: WindLineCreator)
	if self:IsActive() then
		return
	end
	self._active = true
	self._startTrove:Add(task.spawn(function()
		while true do
			if self._count < self._maxCount then
				self:CreateWind()
			end
			task.wait(self._spawnDelay)
		end
	end))
end

--[[
	Stops the loop that spawns wind around the player's camera. Any remaining wind will fade out.
]]
function MT.Stop(self: WindLineCreator)
	self._active = false
	self._startTrove:Clean()
end

-----------------------------
-- SETTERS --
-----------------------------

-----------------------------
-- GETTERS --
-----------------------------

function MT.GetTrove(self: WindLineCreator): Trove.TroveType
	return self._trove
end

function MT.GetUserData(self: WindLineCreator): { [any]: any }
	return self._userData
end

function MT.IsActive(self: WindLineCreator): boolean
	return self._active
end

function MT._GetRandomPosition(self: WindLineCreator): Vector3
	local cameraCFrame = CAMERA.CFrame
	return Vector3.new(
		cameraCFrame.Position.X + rng:NextInteger(-self._cameraRange, self._cameraRange),
		cameraCFrame.Position.Y + rng:NextInteger(-5, self._cameraRange / 1.5),
		cameraCFrame.Position.Z + rng:NextInteger(-self._cameraRange, self._cameraRange)
	)
end

@native
function MT._CalculateSineWave(self: WindLineCreator, amp: number, x: number, freq: number, phase: number): number
	return amp * math.sin((x / freq) + phase)
end

-----------------------------
-- CLEANUP --
-----------------------------

function MT.Destroy(self: WindLineCreator)
	self._trove:Clean()
end

-----------------------------
-- MAIN --
-----------------------------
return Module