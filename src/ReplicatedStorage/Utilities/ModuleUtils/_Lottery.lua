--!strict
--@author: crusherfire
--@date: 5/12/25
--[[@description:
	Random lottery pulling of identifiers with weights.
]]
-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------

-----------------------------
-- TYPES --
-----------------------------
-- For all of the properties/fields of an object made from this class.
type fields = {
	_tickets: { LotteryTicket }
}

export type LotteryTicket = {
	EnumName: string?, -- DEPRECATED
	Identifier: any,
	Weight: number,
	[string]: any -- if you wish to store anything else associated with the ticket
}

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local MT = {}
MT.__index = MT
export type Lottery = typeof(setmetatable({} :: fields, MT))

-- Use a shared RNG seeded by current time
local rng = Random.new(tick())

-----------------------------
-- CLASS FUNCTIONS --
-----------------------------

function Module.new(tickets: { LotteryTicket }?): Lottery
	local self = setmetatable({} :: fields, MT) :: Lottery
	if tickets then
		for _, ticket in tickets do
			if ticket.EnumName then
				warn(`EnumName for LotteryTicket is deprecated`, debug.traceback())
				ticket.Identifier = ticket.EnumName
			end
		end
	end
	self._tickets = tickets or {}
	return self
end

function Module:BelongsToClass(object: any)
	assert(typeof(object) == "table", "Expected table for object!")
	return getmetatable(object) == MT
end

-----------------------------
-- METHODS --
-----------------------------

-- Adds a lottery ticket with an associated positive weight to the pool.
function MT.AddTicket(self: Lottery, identifier: any, weight: number)
	assert(typeof(weight) == "number" and weight > 0, "Lottery:AddTicket expected weight to be a positive number")
	table.insert(self._tickets, { EnumName = identifier, Identifier = identifier, Weight = weight })
end

-- Draws a random ticket based on weights, without removing it from the pool.
-- Returns the drawn ticket.
function MT.DrawTicket(self: Lottery): LotteryTicket
	assert(#self._tickets > 0, "Lottery:DrawTicket called on empty ticket pool")

	local totalWeight = 0
	for _, ticket in ipairs(self._tickets) do
		totalWeight += ticket.Weight
	end

	local pick = rng:NextInteger(0, totalWeight)
	local cumulative = 0

	for _, ticket in ipairs(self._tickets) do
		cumulative += ticket.Weight
		if pick <= cumulative then
			return ticket
		end
	end

	-- Fallback
	return self._tickets[#self._tickets]
end

function MT.GetTickets(self: Lottery): { LotteryTicket }
	return self._tickets
end

-----------------------------
-- CLEANUP / MAIN --
-----------------------------
return Module
