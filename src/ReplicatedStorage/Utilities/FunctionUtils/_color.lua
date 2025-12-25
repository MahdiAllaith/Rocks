--!strict
--@author: crusherfire
--@date: 5/26/25
--[[@description:

]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local t = require("./_t")

-----------------------------
-- TYPES --
-----------------------------

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

-- CONSTANTS --

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Offsets the value in the HSV of the color. Values are represented as 0-255.
function Module.offsetValue(color: Color3, value: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v + (value/255))
end

-- Multiplies the value in the HSV of the color.
function Module.multiplyValue(color: Color3, multiplier: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v * multiplier)
end

-----------------------------
-- MAIN --
-----------------------------
return Module