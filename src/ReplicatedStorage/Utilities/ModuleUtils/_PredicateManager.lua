--!strict
--@author: crusherfire
--@date: 11/20/24
--[[@description:
	A manager for collecting predicates and firing events when new predicates are added or removed.
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
-- For all of the properties/fields of an object made from this class.
type Predicate = (...any) -> (boolean, string?)

type fields = {
	_trove: Trove.TroveType,
	Signals: {
		PredicateAdded: Signal.SignalType<() -> (), ()>,
		PredicateRemoved: Signal.SignalType<() -> (), ()>
	},
	_defaultEvaluation: boolean,
	_predicates: { [string]: Predicate }
}

-----------------------------
-- VARIABLES --
-----------------------------
local PredicateManager = {}
local MT = {}
MT.__index = MT
export type PredicateManager = typeof(setmetatable({} :: fields, MT))

local logger = Logger.new(script.Name)

-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- <strong>defaultEvaluation</strong>: What the manager should return from :Evaluate() by default if there are no predicates. Default is true.
function PredicateManager.new(defaultEvaluation: boolean?): PredicateManager
	local self = setmetatable({} :: fields, MT)
	
	self._trove = Trove.new()
	self.Signals = {
		PredicateAdded = self._trove:Construct(Signal),
		PredicateRemoved = self._trove:Construct(Signal)
	}
	self._defaultEvaluation = if defaultEvaluation ~= nil then defaultEvaluation else true
	self._predicates = {}

	return self
end

function PredicateManager:BelongsToClass(object: any)
	logger:assert(typeof(object) == "table", "Expected table for object!", true)

	return getmetatable(object).__index == MT
end

function MT.AddPredicate(self: PredicateManager, identifier: any, isAble: Predicate)
	if self._predicates[identifier] then
		logger:warn(`Overriding predicate with identifier: {identifier}`, true)
	end
	self._predicates[identifier] = isAble
	self.Signals.PredicateAdded:Fire()
end

function MT.RemovePredicate(self: PredicateManager, identifier: any)
	self._predicates[identifier] = nil
	self.Signals.PredicateRemoved:Fire()
end

-- Evaluates all predicates. If any predicates return false, this will return false.
-- If there are no predicates, this will return the default value supplied to the constructor (true).
-- If there are predicates and all passed, this will return true.
function MT.Evaluate(self: PredicateManager, ...: any?): (boolean, string?)
	local gotPredicate = false
	for _, predicate in pairs(self._predicates) do
		gotPredicate = true
		local success, msg = predicate(...)
		if not success then
			return false, msg
		end
	end
	return if gotPredicate then true else self._defaultEvaluation
end

function MT.Destroy(self: PredicateManager)
	self._trove:Clean()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

-----------------------------
-- MAIN --
-----------------------------
return PredicateManager