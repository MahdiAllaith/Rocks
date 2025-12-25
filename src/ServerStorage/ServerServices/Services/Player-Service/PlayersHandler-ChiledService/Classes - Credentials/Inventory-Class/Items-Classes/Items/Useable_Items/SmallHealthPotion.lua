local HealthPotion1Class = {}
HealthPotion1Class.__index = HealthPotion1Class

local HealthClass = require(script.Parent.Parent.Parent.Parent.Parent["Health-Class"])

export type HealthPotion1ClassType = typeof(setmetatable({} :: {
	POTION_HEAL_AMOUNT: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, HealthPotion1Class))

-- Automatically inferred type
export type HealthClassType = typeof(HealthClass)

HealthPotion1Class.Name = "SmallHealthPotion"

function HealthPotion1Class.Init()
	local self = setmetatable({}, HealthPotion1Class)
	
	self.POTION_HEAL_AMOUNT = 0.1 -- %10 increase in Player Health
	
	self.ItemType = "UseItem"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

--[=[
	@param TheHealthClass HealthClassType

	Use this potion to heal the player based on a percentage of their maximum health.
]=]
function HealthPotion1Class:Use(TheHealthClass : HealthClassType)
	
	local healAmount = TheHealthClass.MaxHealth * self.POTION_HEAL_AMOUNT
	TheHealthClass:Add(healAmount)

end

return HealthPotion1Class
