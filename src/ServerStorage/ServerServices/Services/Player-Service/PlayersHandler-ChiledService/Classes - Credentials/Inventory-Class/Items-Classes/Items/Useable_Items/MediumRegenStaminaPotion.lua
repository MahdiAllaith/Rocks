local RegenStaminaPotion2Class = {}
RegenStaminaPotion2Class.__index = RegenStaminaPotion2Class

local StaminaClass = require(script.Parent.Parent.Parent.Parent.Parent["Stamina-Class"])

export type RegenStaminaPotion2ClassType = typeof(setmetatable({} :: {
	NewRegenAmount: number,
	NewRatio: number,
	Duration: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, RegenStaminaPotion2Class))

-- Automatically inferred type
export type StaminaClassType = typeof(StaminaClass)

RegenStaminaPotion2Class.Name = "MediumRegenStaminaPotion"

function RegenStaminaPotion2Class.Init()
	local self = setmetatable({}, RegenStaminaPotion2Class)

	self.NewRegenAmount = 6
	self.NewRatio = 1 -- per second
	self.Duration = 15
	
	self.ItemType = "UseItem"

	self.Rarity = "Common"
	self.Description = ""

	return self
end

--[=[
	@param StaminaClass StaminaClassType The player's stamina object
	Use this potion to temporarily increase the player's stamina regeneration rate.
]=]
function RegenStaminaPotion2Class:Use(StaminaClass : StaminaClassType, playerMaxHealth : number)

	local self = setmetatable({}, RegenStaminaPotion2Class)
	StaminaClass:FasterRegen(self.NewRegenAmount,self.NewRatio,self.Duration)

	return self
end

return RegenStaminaPotion2Class
