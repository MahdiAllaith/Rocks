--!strict
--@author: crusherfire
--@date: 11/8/24
--[[@description:
	Binds a class to a collection service tag.
]]
-----------------------------
-- SERVICES --
-----------------------------
local CollectionService = game:GetService("CollectionService")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Trove = require(script.Parent._Trove)
local Signal = require(script.Parent._Signal)

-----------------------------
-- TYPES --
-----------------------------
-- This is for all of the properties of an object made from this class for type annotation purposes.
type self = {
	Signals: {
		ObjectAdded: Signal.SignalType<(instance: Instance, obj: any) -> (), (Instance, any)>, -- Fired when a new object is created
		ObjectRemoving: Signal.SignalType<(instance: Instance, obj: any) -> (), (Instance, any)> -- Fired right before an object is destroyed
	},
	
	_trove: Trove.TroveType,
	_bindTrove: Trove.TroveType,
	_tag: string,
	_class: any,
	_constructor: string,
	_objects: { [Instance]: any },
	
	_addedSignal: RBXScriptSignal,
	_removedSignal: RBXScriptSignal
}

-----------------------------
-- VARIABLES --
-----------------------------
local Binder = {}
local MT = {}
MT.__index = MT
export type Binder = typeof(setmetatable({} :: self, MT))


-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

local function doConstruction(self: Binder, instance: Instance)
	local object = self._class[self._constructor](instance)
	self._objects[instance] = self._trove:Add(object)
	self.Signals.ObjectAdded:Fire(instance, object)
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Creates a new binder for the given tag.
-- The provided <code>class</code must have a constructor & and a destroy method for the objects.
-- <strong>constructor</strong>: Define the constructor in the given <code>class</code> if it's not <code>.new()</code>.
function Binder.new(tag: string, class: any, constructor: string?): Binder
	assert(typeof(class) == "table", "Expected class!")
	local constructor = constructor or "new"
	assert(class[constructor], "Class does not contain a constructor!")
	
	local myTrove = Trove.new()
	local self = {
		_trove = myTrove,
		_bindTrove = myTrove:Construct(Signal),
		Signals = {
			ObjectAdded = myTrove:Construct(Signal),
			ObjectRemoving = myTrove:Construct(Signal)
		},
		_tag = tag,
		_class = class,
		_constructor = constructor,
		_objects = {},
		_addedSignal = CollectionService:GetInstanceAddedSignal(tag),
		_removedSignal = CollectionService:GetInstanceAddedSignal(tag)
	}
	
	return setmetatable(self, MT)
end

function Binder:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")

	return getmetatable(object).__index == MT
end

-- Begins listening to the CollectionService & initializes all current instances in the game with the Binder's tag.
-- <strong>canCreate</strong>: An optional predicate function for filtering out certain instances from being passed to the class when first initializing.
-- This is useful when, for example, you only want to initialize the instance when it's parented to a certain service.
function MT.Bind(self: Binder, canCreate: ((instance: Instance) -> (boolean))?)
	self._bindTrove:Connect(self._addedSignal, function(instance)
		doConstruction(self, instance)
	end)
	self._bindTrove:Connect(self._removedSignal, function(instance)
		local object = self._objects[instance] :: any
		if not object.Destroy then
			warn(`Object: {object} does not contain a destroy method!`)
		end
		self._objects[instance] = nil
		self._trove:Remove(object)
	end)
	
	for _, instance in CollectionService:GetTagged(self._tag) do
		if canCreate and not canCreate(instance) then
			continue
		end
		if self._objects[instance] then
			-- Already initialized
			continue
		end
		task.spawn(doConstruction, self, instance)
	end
end

-- Stops listening to the CollectionService.
function MT.Unbind(self: Binder)
	self._bindTrove:Clean()
end

function MT.GetAllObjects(self: Binder): { [Instance]: any }
	return self._objects
end

-- Cleans up all connections and destroys all objects created by the binder.
function MT.Destroy(self: Binder)
	self._trove:Clean()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

-----------------------------
-- MAIN --
-----------------------------
return Binder