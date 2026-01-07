local FireRuneClass = {}
FireRuneClass.__index = FireRuneClass
FireRuneClass.Name = "FireRune"

export type FireRuneClassType = typeof(setmetatable({} :: {
	ModifierCategory: string,
	Type: string,
	DamageType: number,
	FireDamage: number,
	DamageDuration: number,
	FireDuration: number,
	DamageTakenBySecounds: number,
	NewThrowDestince: number,
	ItemType: string,
	Rarity: string,
	Description: string
}, FireRuneClass))

function FireRuneClass.Init()
	local self = setmetatable({}, FireRuneClass)
	
	self.ModifierCategory = "Handler"
	
	self.Type = "Fire"
	self.DamageType = "Hit&Bleed" -- three types of damage : "Hit", "Bleed", "Hit&Bleed"
	self.FireDamage = 5 -- damage per second -- must also be the same name as in StatsRockClass variables
	self.DamageDuration = 5 -- seconds
	self.DamageTakenBySecounds = 1 -- player Get damaged per one second
	self.NewThrowDestince = 50
	
	self.IamgeID = "124692060751675"
	
	self.ItemType = "RockModifire"
	
	self.Rarity = "Uncommon"
	self.Description = "Fire Ball, dealing 5 fire damage per second for 5 seconds."
	return self
end

return FireRuneClass
