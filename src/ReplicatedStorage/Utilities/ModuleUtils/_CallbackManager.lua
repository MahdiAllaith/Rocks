--!strict
--@author: crusherfire
--@date: 11/20/24
--[[@description:
	A manager for collecting callbacks and firing events when new callbacks are added or removed.
	Similar to the PredicateManager except these callbacks are not required to return booleans and nothing is evaluated.
]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Trove = require(script.Parent._Trove)
local Signal = require(script.Parent._Signal)
local Logger = require(script.Parent._Logger)

-----------------------------
-- TYPES --
-----------------------------
type Callback = (...any) -> ()

type fields = {
	_trove: Trove.TroveType,
	Signals: {
		CallbackAdded: Signal.SignalType<() -> (), ()>,
		CallbackRemoved: Signal.SignalType<() -> (), ()>
	},
	_callbacks: { [string]: Callback }
}

-----------------------------
-- VARIABLES --
-----------------------------
local CallbackManager = {}
local MT = {}
MT.__index = MT
export type CallbackManager = typeof(setmetatable({} :: fields, MT))

local logger = Logger.new(script.Name)

-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Creates a new callback manager.
function CallbackManager.new(): CallbackManager
	local self = setmetatable({} :: fields, MT)
	
	self._trove = Trove.new()
	self.Signals = {
		CallbackAdded = self._trove:Construct(Signal),
		CallbackRemoved = self._trove:Construct(Signal)
	}
	self._callbacks = {}

	return self
end

function CallbackManager:BelongsToClass(object: any)
	logger:assert(typeof(object) == "table", "Expected table for object!", true)

	return getmetatable(object).__index == MT
end

function MT.AddCallback(self: CallbackManager, identifier: any, callback: Callback)
	if self._callbacks[identifier] then
		logger:warn(`Overriding callback with identifier: {identifier}`, true)
	end
	self._callbacks[identifier] = callback
	self.Signals.CallbackAdded:Fire()
end

function MT.RemoveCallback(self: CallbackManager, identifier: any)
	self._callbacks[identifier] = nil
	self.Signals.CallbackRemoved:Fire()
end

-- Calls all the callbacks with the given arguments.
function MT.Call(self: CallbackManager, ...: any?)
	for _, callback in pairs(self._callbacks) do
		task.spawn(callback, ...)
	end
end

function MT.Destroy(self: CallbackManager)
	self._trove:Clean()
end

-----------------------------
-- MAIN --
-----------------------------
return CallbackManager