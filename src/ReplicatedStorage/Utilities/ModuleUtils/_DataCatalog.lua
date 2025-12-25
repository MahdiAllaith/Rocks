--!strict
--@author: crusherfire
--@date: 4/22/25
--[[@description:
	For creating catalog data containers.
]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Cache = require("./_Cache")
local FunctionUtils = require("../FunctionUtils")
local t = FunctionUtils.t

-----------------------------
-- TYPES --
-----------------------------

export type DataCatalog<T> = {
	_data: { [string]: T },
	_entryCache: Cache.CacheType,
	_entryCount: number,

	-- SUPER hacky for functions w/comments but it works!
	GetEntries: ( typeof(
		-- Returns all entries. This table is frozen and cannot be modified.
		function(self: DataCatalog<T>): { [string]: T }
			return nil :: any
		end
		)
	),
	GetEnumNames: typeof(
		-- Returns all enum names as an array in the catalog.
		function(self: DataCatalog<T>): { string }
			return {}
		end
	),
	GetEntryByName: ( typeof(
		-- Grabs a guaranteed entry in the catalog based on the <code>enumName</code>.
		-- Throws an error if the <code>enumName</code> is invalid. If this behavior is not desired, index for the entry directly from <code>:GetEntires()</code>
		function(self: DataCatalog<T>, enumName: string): T
			return nil :: any
		end)
	),
	GetEntryByKeyValue: typeof(
		-- Looks for the entry in the catalog based on <code>key</code> and if the value at <code>key</code> matches <code>matchValue</code>.
		function(self: DataCatalog<T>, key: string, matchValue: any): T?
			return nil :: any
		end
	),
	GetEntriesByKeyValue: typeof(
		-- Looks for all entries in the catalog based on <code>key</code> and if the value at <code>key</code> matches <code>matchValue</code>.
		function(self: DataCatalog<T>, key: string, matchValue: any): { T }
			return nil :: any
		end
	),
	GetNameByEntry: typeof( 
		-- Looks for the entry in the catalog and returns its name if found.
		-- Results are cached.
		function(self: DataCatalog<T>, entry: any): string?
			return
		end
	),
	GetSorted: typeof(
		-- Returns an array of all values and keys in the catalog sorted by <code>comparator</code>
		-- These results are cached with the same comparator!
		function(self: DataCatalog<T>, comparator: (a: T, b: T) -> (boolean)): ( { T }, { string } )
			return nil :: any, nil :: any
		end
	),
	GetEntryCount: typeof(
		--[[
			Returns the number of entries present in the DataCatalog.
			Result is cached.
		]]
		function(self: DataCatalog<T>): number
			return 0
		end
	)
}

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local MT = {}
MT.__index = MT

local sortedCatalogCache = FunctionUtils.Table.weakCache("k")

-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- CLASS FUNCTIONS --
-----------------------------

-- Freezes the data table and stores it.
function Module.new<T>(data: { [string]: T }): DataCatalog<T>
	local self = setmetatable({}, MT) :: any
	
	self._data = if table.isfrozen(data) then data else table.freeze(data)
	self._entryCache = Cache.new()
	self._entryCount = 0
	for _, _ in data do
		self._entryCount += 1
	end
	
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

-----------------------------
-- SETTERS --
-----------------------------

-----------------------------
-- GETTERS --
-----------------------------

-- Returns all entries. This table is frozen and cannot be modified.
function MT.GetEntries(self: DataCatalog<any>): any
	return self._data
end

function MT.GetEnumNames(self: DataCatalog<any>): { string }
	local _, names = FunctionUtils.Table.toArrayCached(self._data)
	return names
end

-- Grabs a guaranteed entry in the catalog based on the <code>enumName</code>.
-- Throws an error if the <code>enumName</code> is invalid. If this behavior is not desired, index for the entry directly from <code>:GetEntires()</code>
function MT.GetEntryByName(self: DataCatalog<any>, enumName: string): any
	local result = self._data[enumName]
	if not result then
		error(`invalid enumName: {enumName}`, 2)
	end
	return result
end

-- Looks for the entry in the catalog based on <code>key</code> and if the value at <code>key</code> matches <code>matchValue</code>.
function MT.GetEntryByKeyValue(self: DataCatalog<any>, key: string, matchValue: any): any?
	for name, entry: any in pairs(self._data) do
		if entry[key] == matchValue then
			return entry
		end
	end
	return
end

-- Looks for all entries in the catalog based on <code>key</code> and if the value at <code>key</code> matches <code>matchValue</code>.
function MT.GetEntriesByKeyValue(self: DataCatalog<any>, key: string, matchValue: any): any?
	local result = {}
	for name, entry in pairs(self._data) do
		if entry[key] == matchValue then
			table.insert(result, entry)
		end
	end
	return result
end

-- Looks for the entry in the catalog and returns its name if found.
-- Results are cached.
function MT.GetNameByEntry(self: DataCatalog<any>, entry: any): string?
	local result = self._entryCache:Get(entry)
	if result then
		return if result == true then nil else result
	end
	for name, _entry in pairs(self._data) do
		if _entry == entry then
			result = name
			break
		end
	end
	self._entryCache:Set(entry, result or true)
	return result
end

function MT.GetSorted(self: DataCatalog<any>, comparator: (any, any) -> (boolean)): ( { any }, { string } )
	assert(typeof(comparator) == "function", "Expected comparator to be a function")

	local data = self._data
	local cacheForData = sortedCatalogCache[data]
	if not cacheForData then
		cacheForData = FunctionUtils.Table.weakCache("k")
		sortedCatalogCache[data] = cacheForData
	end

	local cached = cacheForData[comparator]
	if cached then
		-- Return cloned arrays to avoid external mutation
		return table.clone(cached.Values), table.clone(cached.Keys)
	end

	local values, keys = FunctionUtils.Table.toArrayCached(data)

	local indexed = table.create(#values)
	for i = 1, #values do
		indexed[i] = {
			Key = keys[i],
			Value = values[i],
		}
	end

	table.sort(indexed, function(a, b)
		return comparator(a.Value, b.Value)
	end)

	local sortedValues = table.create(#indexed)
	local sortedKeys = table.create(#indexed)
	for i = 1, #indexed do
		sortedValues[i] = indexed[i].Value
		sortedKeys[i] = indexed[i].Key
	end

	cacheForData[comparator] = {
		Values = sortedValues,
		Keys = sortedKeys,
	}

	return table.clone(sortedValues), table.clone(sortedKeys)
end

function MT.GetEntryCount(self: DataCatalog<any>): number
	return self._entryCount
end

-----------------------------
-- CLEANUP --
-----------------------------

-----------------------------
-- MAIN --
-----------------------------
return Module