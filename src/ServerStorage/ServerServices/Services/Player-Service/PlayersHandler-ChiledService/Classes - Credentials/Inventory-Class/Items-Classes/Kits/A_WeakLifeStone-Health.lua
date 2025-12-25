local A_WeakLifeStoneClass = {}
A_WeakLifeStoneClass.__index = A_WeakLifeStoneClass

--local HealthClass = require(script.Parent.Parent.Parent.Parent["Health-Class"])
--export type HealthClassType = HealthClass.HealthClassType

A_WeakLifeStoneClass.Name = "WeakLifeStone"

export type A_WeakLifeStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	TypeHandle: string,
	HealthIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, A_WeakLifeStoneClass))

local ADD_Health_INCREASE = 100

function A_WeakLifeStoneClass.Init()
	local self = setmetatable({}, A_WeakLifeStoneClass)
	
	self.TypeKit = "Health"
	self.TypeHandle = "Increase"
	self.HealthIncrease = 100
	
	self.ItemType = "Kit"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

return A_WeakLifeStoneClass
