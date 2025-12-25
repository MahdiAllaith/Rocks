local FireSpriteClass = {}
FireSpriteClass.__index = FireSpriteClass

FireSpriteClass.Name = "FireSprite"

export type FireSpriteClassType = typeof(setmetatable({} :: {
	ModifierCategory: string,
	EffectType: string,
	FireModifier: number,
	ThrowDistanceModifier: number,
	DamageMultiplier: number,
	ItemType: string,
	Rarity: string,
	Description: string
}, FireSpriteClass))

function FireSpriteClass.Init()
	local self = setmetatable({}, FireSpriteClass)
	
	self.ModifierCategory = "Buffer"
	self.EffectType = "Fire"
	
	self.FireModifier = 0.1 -- %10 increase in fire damage
	self.ThrowDistanceModifier = 0.05 -- 5% more distance
	self.DamageMultiplier = 0
	
	self.ItemType = "RockModifire"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

return FireSpriteClass
