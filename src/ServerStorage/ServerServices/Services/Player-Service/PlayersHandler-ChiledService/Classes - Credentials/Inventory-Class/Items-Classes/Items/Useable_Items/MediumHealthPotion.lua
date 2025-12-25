local HealthPotion2Class = {}
HealthPotion2Class.__index = HealthPotion2Class

local HealthClass = require(script.Parent.Parent.Parent.Parent.Parent["Health-Class"])

export type HealthPotion2ClassType = typeof(setmetatable({} :: {
	POTION_HEAL_AMOUNT: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, HealthPotion2Class))

-- Automatically inferred type
export type HealthClassType = typeof(HealthClass)

HealthPotion2Class.Name = "MediumHealthPotion"

function HealthPotion2Class.Init()
	local self = setmetatable({}, HealthPotion2Class)

	self.POTION_HEAL_AMOUNT = 0.2 -- %20 increase in Player Health
	
	self.ItemType = "UseItem"

	self.Rarity = "Common"
	self.Description = ""

	return self
end

--[=[
	@param TheHealthClass HealthClassType

	Use this potion to heal the player based on a percentage of their maximum health.
]=]
function HealthPotion2Class:Use(TheHealthClass : HealthClassType)
	local self = setmetatable({}, HealthPotion2Class)

	local healAmount = TheHealthClass.MaxHealth * self.POTION_HEAL_AMOUNT
	TheHealthClass:Add(healAmount)

	return self
end

return HealthPotion2Class
