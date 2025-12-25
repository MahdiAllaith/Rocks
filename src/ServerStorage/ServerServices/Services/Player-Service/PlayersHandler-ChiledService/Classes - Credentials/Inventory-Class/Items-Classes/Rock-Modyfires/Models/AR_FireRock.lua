local FireRockClass = {}
FireRockClass.__index = FireRockClass

FireRockClass.Name = "FireRock"

export type FireRockClassType = typeof(setmetatable({} :: {
	ModifierCategory: string,
	Type: string,
	Model: Part,
	RockDamage: number,
	ItemType: string,
	Rarity: string,
	Description: string
}, FireRockClass))

function FireRockClass.Init()
	local self = setmetatable({}, FireRockClass)
	
	local replic = game:GetService("ReplicatedStorage")
	local FireModules = replic:WaitForChild("Modifiers"):WaitForChild("Rocks_Models"):WaitForChild("Fire")
	
	self.ModifierCategory = "Model"
	
	self.Type = "Fire"
	self.Model = FireModules:WaitForChild("FireRock"):Clone()
	self.RockDamage = 25
	
	self.ItemType = "RockModifire"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

return FireRockClass
