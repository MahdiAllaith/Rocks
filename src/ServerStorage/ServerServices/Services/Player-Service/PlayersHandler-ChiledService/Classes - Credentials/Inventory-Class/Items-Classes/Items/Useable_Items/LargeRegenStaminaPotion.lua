local RegenStaminaPotion3Class = {}
RegenStaminaPotion3Class.__index = RegenStaminaPotion3Class

local StaminaClass = require(script.Parent.Parent.Parent.Parent.Parent["Stamina-Class"])

export type RegenStaminaPotion3ClassType = typeof(setmetatable({} :: {
	NewRegenAmount: number,
	NewRatio: number,
	Duration: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, RegenStaminaPotion3Class))

-- Automatically inferred type
export type StaminaClassType = typeof(StaminaClass)

RegenStaminaPotion3Class.Name = "LargeRegenStaminaPotion"

function RegenStaminaPotion3Class.Init()
	local self = setmetatable({}, RegenStaminaPotion3Class)

	self.NewRegenAmount = 10
	self.NewRatio = 0.8 -- per second
	self.Duration = 20
	
	self.ItemType = "UseItem"

	self.Rarity = "Rare"
	self.Description = ""

	return self
end

--[=[
	@param StaminaClass StaminaClassType The player's stamina object
	Use this potion to temporarily increase the player's stamina regeneration rate.
]=]
function RegenStaminaPotion3Class:Use(StaminaClass : StaminaClassType, playerMaxHealth : number)

	local self = setmetatable({}, RegenStaminaPotion3Class)
	StaminaClass:FasterRegen(self.NewRegenAmount,self.NewRatio,self.Duration)

	return self
end

return RegenStaminaPotion3Class
