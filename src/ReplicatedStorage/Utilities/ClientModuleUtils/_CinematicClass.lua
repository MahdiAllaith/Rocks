--!strict
--@author: crusherfire
--@date: 4/17/25
--[[@description:
	For creating cool Bezier curve cinematics for the camera.
	You can control the duration, easing style, and easing direction for the cinematic!
]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local ModuleUtils = require("../ModuleUtils")
local FunctionUtils = require("../FunctionUtils")
local t = FunctionUtils.t

-----------------------------
-- TYPES --
-----------------------------
-- For all of the properties/fields of an object made from this class.
type fields = {
	_trove: ModuleUtils.TroveType,
	_userData: { [any]: any },
	_cinematic: Model,
	_startArgs: StartArgsStrict,
	_parts: { BasePart },
	_active: boolean,
	_t: number,

	Signals: {
		Started: ModuleUtils.GenericSignal,
		Ended: ModuleUtils.SignalType<(completed: boolean) -> (), (boolean)>
	},

	_rotQuats: { ModuleUtils.Quaternion },
	_workQuats: { ModuleUtils.Quaternion },

	_posControls: { Vector3 },
	_posWork: { Vector3 },

	_posSamples: { Vector3 },
	_quatSamples: { ModuleUtils.Quaternion },
	_sampleCount: number,

	_renderBindings: { string },
}

type EasingFunc = (number) -> (number)

export type StartArgs = {
	EasingStyle: EasingFunc?,
	EasingDirection: ( (number, EasingFunc) -> (number) )?,

	Duration: number?
}

export type CinematicStartArgs = StartArgs

-- this is goofy
type StartArgsStrict = {
	EasingStyle: EasingFunc,
	EasingDirection: ( (number, EasingFunc) -> (number) ),

	Duration: number
}

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local MT = {}
MT.__index = MT
export type Cinematic = typeof(setmetatable({} :: fields, MT))

-- CONSTANTS --
local DEFAULT_DURATION = 5
local SAMPLE_RATE = 60 -- 60fps

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

local function getDefaultStartArgs(): StartArgsStrict
	return {
		EasingStyle = FunctionUtils.Math.EasingStyle.Linear,
		EasingDirection = FunctionUtils.Math.EasingDirection.In,
		Duration = DEFAULT_DURATION
	}
end

@native
local function deCasteljauQuat(orig: { ModuleUtils.Quaternion }, work: { ModuleUtils.Quaternion }, t: number): ModuleUtils.Quaternion
	local n = #orig
	table.move(orig, 1, n, 1, work)
	for level = 1, n - 1 do
		for i = 1, n - level do
			work[i] = work[i]:Slerp(work[i + 1], t)
		end
	end
	return work[1]
end

@native
local function deCasteljauPos(orig: { Vector3 }, work: { Vector3 }, t: number): Vector3
	local n = #orig
	table.move(orig, 1, n, 1, work)
	for level = 1, n - 1 do
		for i = 1, n - level do
			work[i] = work[i]:Lerp(work[i + 1], t)
		end
	end
	return work[1]
end

-----------------------------
-- CLASS FUNCTIONS --
-----------------------------

--[[
	Creates a new cinematic object.
	<strong>cinematic</strong>: should be an instance containing parts named with integer values starting at '1'.
]]
function Module.new(cinematic: any): Cinematic
	assert(cinematic:FindFirstChild("1"), "model missing starting part '1'")
	local parts = {}
	for _, part in ipairs(cinematic:GetChildren()) do
		assert(part:IsA("BasePart") and tonumber(part.Name), "invalid part/name in cinematic model")
		table.insert(parts, part)
	end
	assert(#parts >= 2, "expected at least 2 parts")
	table.sort(parts, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	local self = setmetatable({} :: fields, MT) :: Cinematic
	self._trove = ModuleUtils.Trove.new()
	self._userData = {}
	self._renderBindings = {}

	self.Signals = {
		Started = self._trove:Construct(ModuleUtils.Signal),
		Ended = self._trove:Construct(ModuleUtils.Signal),
	}

	self._cinematic = cinematic
	self._parts = parts
	self._active = false
	self._t = 0
	self._startArgs = getDefaultStartArgs()

	-- buffers for rotation
	self._rotQuats = {} -- control points
	self._workQuats= {}
	-- buffers for position
	self._posControls = {}
	self._posWork = {}

	self._posSamples = {}
	self._quatSamples = {}
	self._sampleCount = 0

	return self
end

function Module:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")
	local mt = getmetatable(object)
	return mt ~= nil and mt.__index == MT
end

-----------------------------
-- METHODS --
-----------------------------

--[[
	Starts the cinematic. For the camera to start moving, you must <code>:BindToRenderStep()</code>.
	<strong>Duration</strong>: Time in seconds over which to interpolate along the curve.
	<strong>EasingStyle</strong>: Should be an easing style function that takes in a number and returns a number.
	<strong>EasingDirection</strong>: Should be an easing direction function that takes in a number & easing style function and returns a number.
]]
function MT.Start(self: Cinematic, startArgs: CinematicStartArgs?)
	self._startArgs = if startArgs then FunctionUtils.Table.reconcile(startArgs, self._startArgs) else self._startArgs
	assert(self._startArgs.Duration > 0, "Duration must be greater than 0")
	self.Signals.Started:FireDefer()

	-- Initialize rotation quaternions & positions
	for i, part in ipairs(self._parts) do
		local q = ModuleUtils.Quaternion.fromOrientation(part.CFrame:ToOrientation())
		self._rotQuats[i] = q
		self._workQuats[i] = q
		self._posControls[i] = part.Position
		self._posWork[i] = part.Position
	end

	local duration   = self._startArgs.Duration
	local size = math.ceil(duration * SAMPLE_RATE) + 1

	self._sampleCount = size
	self._posSamples = {}  -- size S
	self._quatSamples = {}  -- size S

	for i = 1, size do
		local t = (i - 1) / (size - 1)  -- from 0 to 1
		-- direct De Casteljau on positions:
		local p = deCasteljauPos(self._posControls, self._posWork, t)
		-- quaternion Bezier:
		local q = deCasteljauQuat(self._rotQuats, self._workQuats, t)
		self._posSamples[i]  = p
		self._quatSamples[i] = q
	end

	self._active = true
	self._t = 0
end

--[[
	Calculates the current cinematic CFrame.
	This should be called every frame.
	Returns CFrame and done flag.
]]
function MT.Update(self: Cinematic, dt: number): (CFrame, boolean)
	if not self._active then
		return CFrame.identity, true
	end

	local args = self._startArgs
	self._t = math.clamp(self._t + dt/args.Duration, 0, 1)
	local tRaw = self._t
	local tEased = args.EasingDirection(tRaw, args.EasingStyle)

	-- Map eased time into pre-sampled array
	local rawIndex = tEased * (self._sampleCount - 1) + 1
	rawIndex = math.clamp(rawIndex, 1, self._sampleCount)
	local i0 = math.floor(rawIndex)
	local i1 = math.min(i0 + 1, self._sampleCount)
	local frac = rawIndex - i0

	local p0 = self._posSamples[i0]
	local p1 = self._posSamples[i1]
	local pos = p0:Lerp(p1, frac)

	local q0 = self._quatSamples[i0]
	local q1 = self._quatSamples[i1]
	local quat = q0:Slerp(q1, frac)

	local cf = quat:ToCFrame(pos)

	local done = (tRaw >= 1)
	if done then
		self:_Stop(true)
	end

	return cf, done
end

--[[
	Binds the cinematic to RenderStep.
	Callback receives (position, rotation, done)
]]
function MT.BindToRenderStep(self: Cinematic, name: string, priority: number, callback: (cf: CFrame, done: boolean) -> ())
	RunService:BindToRenderStep(name, priority, function(dt)
		callback(self:Update(dt))
	end)
	table.insert(self._renderBindings, name)
end

--[[
	Ends the cinematic and unbinds from RenderStep.
]]
function MT.Stop(self: Cinematic)
	self:_Stop(false)
end

function MT._Stop(self: Cinematic, completed: boolean)
	if not self._active then
		return
	end
	self.Signals.Ended:FireDefer(completed)
	self._active = false
	for _, name in ipairs(self._renderBindings) do
		RunService:UnbindFromRenderStep(name)
	end
	table.clear(self._renderBindings)
end

-----------------------------
-- SETTERS --
-----------------------------

-----------------------------
-- GETTERS --
-----------------------------

function MT.GetTrove(self: Cinematic): ModuleUtils.TroveType
	return self._trove
end

function MT.GetUserData(self: Cinematic): { [any]: any }
	return self._userData
end

--[[
	Returns the cinematic model.
]]
function MT.GetModel(self: Cinematic): any
	return self._cinematic
end

function MT.IsActive(self: Cinematic): boolean
	return self._active
end

-----------------------------
-- CLEANUP --
-----------------------------

function MT.Destroy(self: Cinematic)
	self:Stop()
	self._trove:Clean()
end

-----------------------------
-- MAIN --
-----------------------------
return Module