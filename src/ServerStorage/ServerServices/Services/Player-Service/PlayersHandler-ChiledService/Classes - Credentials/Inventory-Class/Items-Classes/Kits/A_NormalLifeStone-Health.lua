local A_NormalLifeStoneClass = {}
A_NormalLifeStoneClass.__index = A_NormalLifeStoneClass

--local HealthClass = require(script.Parent.Parent.Parent.Parent["Health-Class"])
--export type HealthClassType = HealthClass.HealthClassType

A_NormalLifeStoneClass.Name = "NormalLifeStone"

export type A_NormalLifeStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	TypeHandle: string,
	HealthIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, A_NormalLifeStoneClass))

local ADD_Health_INCREASE = 100

function A_NormalLifeStoneClass.Init()
	local self = setmetatable({}, A_NormalLifeStoneClass)
	
	self.TypeKit = "Health"
	self.TypeHandle = "Increase"
	self.HealthIncrease = 150
	
	self.ItemType = "Kit"
	
	self.Rarity = "Common"
	self.Description = ""

	return self
end

return A_NormalLifeStoneClass
