local RegenStaminaPotion1Class = {}
RegenStaminaPotion1Class.__index = RegenStaminaPotion1Class

local StaminaClass = require(script.Parent.Parent.Parent.Parent.Parent["Stamina-Class"])

export type RegenStaminaPotion1ClassType = typeof(setmetatable({} :: {
	NewRegenAmount: number,
	NewRatio: number,
	Duration: number,
	ItemType: string,
	Rarity: string,
	Description: string,
}, RegenStaminaPotion1Class))

-- Automatically inferred type
export type StaminaClassType = typeof(StaminaClass)

RegenStaminaPotion1Class.Name = "SmallRegenStaminaPotion"

function RegenStaminaPotion1Class.Init()
	local self = setmetatable({}, RegenStaminaPotion1Class)

	self.NewRegenAmount = 4
	self.NewRatio = 1 -- per second
	self.Duration = 10
	
	self.ItemType = "UseItem"
	
	self.Rarity = "Uncommon"
	self.Description = ""

	return self
end

--[=[
	@param StaminaClass StaminaClassType The player's stamina object
	Use this potion to temporarily increase the player's stamina regeneration rate.
]=]
function RegenStaminaPotion1Class:Use(StaminaClass : StaminaClassType, playerMaxHealth : number)
	
	local self = setmetatable({}, RegenStaminaPotion1Class)
	StaminaClass:FasterRegen(self.NewRegenAmount,self.NewRatio,self.Duration)

	return self
end

return RegenStaminaPotion1Class
