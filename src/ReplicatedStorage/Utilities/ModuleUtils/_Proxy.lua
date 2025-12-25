--!strict
--@author: crusherfire
--@date: 11/7/24
--[[@description:
	
]]
-----------------------------
-- SERVICES --
-----------------------------

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Signal = require(script.Parent._Signal)

-----------------------------
-- TYPES --
-----------------------------
-- This is for all of the properties of an object made from this class for type annotation purposes.
type fields<T = { [any]: any }> = {
	Signals: {
		Indexed: Signal.SignalType<(index: any) -> (), (any)>,
		NewIndex: Signal.SignalType<(index: any, value: any) -> (), (any, any)>
	},
	_proxy: proxyTable<T>,
	
	-- Returns the proxy for indexing.
	Get: (self: Proxy<T>) -> (T),
	
	-- Returns the original table used for the proxy.
	GetOrig: (self: Proxy<T>) -> (T),
	
	Destroy: (self: Proxy<T>) -> ()
}

-----------------------------
-- VARIABLES --
-----------------------------
local Proxy = {}
local MT = {
	__newindex = function()
		error("Attempted to add/modify field in Proxy", 2)
	end,
}
MT.__index = MT
local ProxyMT = {}

export type Proxy<T> = typeof(setmetatable({} :: fields<T>, MT))

type proxyTable<T = { [any]: any }> = typeof(setmetatable({} :: {
	__ref: Proxy<T>,
	__t: T
}, ProxyMT))

-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Creates a proxy for the given table.
-- Any accesses or new indexes are observed and corresponding events are fired.
function Proxy.new<T>(t: T): Proxy<T>
	assert(typeof(t) == "table", "Expected table value")
	local self = {}

	self.Signals = {
		Indexed = Signal.new(),
		NewIndex = Signal.new()
	}
	self._proxy = setmetatable({
		__ref = self,
		__t = t
	}, ProxyMT)
	
	return setmetatable(self, MT) :: any
end

function Proxy:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")

	return getmetatable(object).__index == MT
end

-- Returns the proxy for indexing.
function MT:Get()
	return self._proxy
end

-- Returns the original table.
function MT:GetOrig()
	return rawget(self._proxy, "__t")
end

function MT:Destroy()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

function ProxyMT.__index(proxyTable: any, key: any)
	local origTable = rawget(proxyTable, "__t")
	local result = origTable[key]
	local proxyObj = rawget(proxyTable, "__ref") :: Proxy<any>
	proxyObj.Signals.Indexed:Fire(key)
	return result
end

function ProxyMT.__newindex(proxyTable: any, key: any, value: any)
	local origTable = rawget(proxyTable, "__t")
	local proxyObj = rawget(proxyTable, "__ref") :: Proxy<any>
	origTable[key] = value
	proxyObj.Signals.NewIndex:Fire(key, value)
end

-----------------------------
-- MAIN --
-----------------------------
return Proxy