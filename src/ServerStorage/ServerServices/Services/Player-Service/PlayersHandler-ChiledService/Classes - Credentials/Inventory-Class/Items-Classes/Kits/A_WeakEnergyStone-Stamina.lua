local A_WeakEnergyStoneClass = {}
A_WeakEnergyStoneClass.__index = A_WeakEnergyStoneClass

A_WeakEnergyStoneClass.Name = "WeakEnergyStone"

export type A_WeakEnergyStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	TypeHandle: string,
	StaminaIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, A_WeakEnergyStoneClass))

function A_WeakEnergyStoneClass.Init()
	local self = setmetatable({}, A_WeakEnergyStoneClass)

	self.TypeKit = "Stamina"
	self.TypeHandle = "Increase"
	self.StaminaIncrease = 50
	
	self.ItemType = "Kit"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

return A_WeakEnergyStoneClass


