--!strict
--@author: crusherfire
--@date: 11/11/24
--[[@description:
	Creates a new logger object that can print, warn, assert, and error with a prefix given through the constructor.
	By default, prints do not occur on production servers unless specified through the constructor.
]]
-----------------------------
-- SERVICES --
-----------------------------
local RunService = game:GetService("RunService")

-----------------------------
-- DEPENDENCIES --
-----------------------------

-----------------------------
-- TYPES --
-----------------------------
-- This is for all of the properties of an object made from this class for type annotation purposes.
type self = {
	_prefix: string,
	_printsOnProduction: boolean,
}

-----------------------------
-- VARIABLES --
-----------------------------
local Logger = {}
local MT = {}
MT.__index = MT
export type LoggerType = typeof(setmetatable({} :: self, MT))

-- CONSTANTS --
local DEFAULT_LEVEL = 1

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Creates a new logger that will send console messages with the given <code>prefix</code>.
-- <strong>withBrackets</strong>: Should brackets be wrapped around the prefix? True by default.
-- <strong>printsOnProduction</strong>: Should :print() happen on production servers? False by default.
function Logger.new(prefix: string, withBrackets: boolean?, printsOnProduction: boolean?): LoggerType
	assert(typeof(prefix) == "string", "Expected string for prefix.")
	local self = setmetatable({} :: self, MT)
	
	local withBrackets = if typeof(withBrackets) ~= "nil" then withBrackets else true
	
	self._prefix = if withBrackets then `[{prefix}]:` else `{prefix}:`
	self._printsOnProduction = printsOnProduction or false
	
	return self
end

function Logger:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")

	return getmetatable(object).__index == MT
end

-- <strong>traceback</strong>: Should the full traceback be included?
function MT.print(self: LoggerType, msg: any, traceback: boolean?)
	if not RunService:IsStudio() and not self._printsOnProduction then
		return
	end
	print(self._prefix, msg, if traceback then `\n{debug.traceback()}` else "")
end

-- <strong>traceback</strong>: Should the full traceback be included?
function MT.warn(self: LoggerType, msg: any, traceback: boolean?)
	warn(self._prefix, msg, if traceback then `\n{debug.traceback()}` else "")
end

-- <strong>traceback</strong>: Should the full traceback be included?
function MT.assert(self: LoggerType, expression: any, err: any, traceback: boolean?)
	if not expression then
		self:error(err, traceback)
	end
end

-- An improved version over <code>assert()</code> to avoid string concatenation unless the expression is evaluated to false.
-- <strong>traceback</strong>: Should the full traceback be included?
-- <strong>toFormat</strong>: The string to be used in <code>string.format()</code>
-- <strong>...</strong>: Any strings to be formatted into <strong>toFormat</strong>
function MT.assertFormatted(self: LoggerType, expression: any, traceback: boolean?, toFormat: string, ...: string)
	if not expression then
		self:error(string.format(toFormat, ...), traceback)
	end
end

-- <strong>traceback</strong>: Should the full traceback be included?
function MT.assertWarn(self: LoggerType, expression: any, msg: any, traceback: boolean?)
	if not expression then
		self:warn(msg, traceback)
	end
end

-- <strong>traceback</strong>: Should the full traceback be included?
function MT.error(self: LoggerType, err: any, traceback: boolean?)
	error(`{self._prefix} {err}{if traceback then `\n{debug.traceback()}` else ""}`)
end

function MT.Destroy(self: LoggerType)
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

-----------------------------
-- MAIN --
-----------------------------
return Logger