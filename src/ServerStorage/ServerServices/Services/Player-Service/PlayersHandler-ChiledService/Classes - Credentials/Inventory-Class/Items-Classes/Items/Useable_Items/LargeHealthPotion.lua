local HealthPotion3Class = {}
HealthPotion3Class.__index = HealthPotion3Class

local HealthClass = require(script.Parent.Parent.Parent.Parent.Parent["Health-Class"])

export type HealthPotion3ClassType = typeof(setmetatable({} :: {
	POTION_HEAL_AMOUNT: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, HealthPotion3Class))

-- Automatically inferred type
export type HealthClassType = typeof(HealthClass)

HealthPotion3Class.Name = "LargeHealthPotion"

function HealthPotion3Class.Init()
	local self = setmetatable({}, HealthPotion3Class)

	self.POTION_HEAL_AMOUNT = 0.3 -- %30 increase in Player Health
	
	self.ItemType = "UseItem"

	self.Rarity = "Rare"
	self.Description = ""

	return self
end

--[=[
	@param TheHealthClass HealthClassType

	Use this potion to heal the player based on a percentage of their maximum health.
]=]
function HealthPotion3Class:Use(TheHealthClass : HealthClassType)
	local self = setmetatable({}, HealthPotion3Class)

	local healAmount = TheHealthClass.MaxHealth * self.POTION_HEAL_AMOUNT
	TheHealthClass:Add(healAmount)
	

	return self
end

return HealthPotion3Class
