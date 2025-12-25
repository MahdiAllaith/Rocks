local A_NormalEnergyStoneClass = {}
A_NormalEnergyStoneClass.__index = A_NormalEnergyStoneClass

A_NormalEnergyStoneClass.Name = "NormalEnergyStone"

export type A_NormalEnergyStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	TypeHandle: string,
	StaminaIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, A_NormalEnergyStoneClass))

function A_NormalEnergyStoneClass.Init()
	local self = setmetatable({}, A_NormalEnergyStoneClass)

	self.TypeKit = "Stamina"
	self.TypeHandle = "Increase"
	self.StaminaIncrease = 100
	
	self.ItemType = "Kit"
	
	self.Rarity = "Common"
	self.Description = ""

	return self
end

return A_NormalEnergyStoneClass


