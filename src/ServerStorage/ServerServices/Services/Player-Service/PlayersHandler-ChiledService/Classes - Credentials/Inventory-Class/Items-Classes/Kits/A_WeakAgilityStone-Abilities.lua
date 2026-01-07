local A_WeakAgilityStoneClass = {}
A_WeakAgilityStoneClass.__index = A_WeakAgilityStoneClass

A_WeakAgilityStoneClass.Name = "WeakAgilityStone"

export type A_WeakAgilityStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	WalkIncrease: number,
	RunIncrease: number,
	JumpIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string
}, A_WeakAgilityStoneClass))

function A_WeakAgilityStoneClass.Init()
	local self = setmetatable({}, A_WeakAgilityStoneClass)

	self.TypeKit = "Abilities"
	self.WalkIncrease = 5 -- % increase
	self.RunIncrease = 5 -- % increase
	self.JumpIncrease = 5 -- % increase
	
	self.ItemType = "Kit"
	
	
	self.Rarity = "Uncommon"
	self.Description = "Increases walk speed by 5% and jump power by 5%"

	return self
end

return A_WeakAgilityStoneClass


