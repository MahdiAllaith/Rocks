local A_NormalAgilityStoneClass = {}
A_NormalAgilityStoneClass.__index = A_NormalAgilityStoneClass

A_NormalAgilityStoneClass.Name = "NormalAgilityStone"

export type A_NormalAgilityStoneClassType = typeof(setmetatable({} :: {
	TypeKit: string,
	WalkIncrease: number,
	RunIncrease: number,
	JumpIncrease: number,
	ItemType: string,
	Rarity: string,
	Description: string
}, A_NormalAgilityStoneClass))

function A_NormalAgilityStoneClass.Init()
	local self = setmetatable({}, A_NormalAgilityStoneClass)

	self.TypeKit = "Abilities"
	self.WalkIncrease = 15 -- % increase
	self.RunIncrease = 15 -- % increase
	self.JumpIncrease = 10 -- % increase
	
	self.ItemType = "Kit"
	
	self.Rarity = "Common"
	self.Description = "Increases walk speed by 15%  and jump power by 10%"

	return self
end

return A_NormalAgilityStoneClass


