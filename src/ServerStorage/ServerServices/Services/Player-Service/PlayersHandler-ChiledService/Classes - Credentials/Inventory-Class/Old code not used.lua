-- ItemTypes.lua
local HealthPotionClass = require(script.Parent["Items-Classes"].Items.HealthPotion)
local StaminaFasterRegenPotionClass = require(script.Parent["Items-Classes"].Items.StaminaFasterRegenPotion)

-- Items Exports
export type HealthPotionClassType = typeof(HealthPotionClass)
export type StaminaFasterRegenPotionClassType = typeof(StaminaFasterRegenPotionClass)

-- Rock Modifiers Buffers
local AR_FireSpriteClass = require(script.Parent["Items-Classes"]["Rock-Modyfires"].Buffers.AR_FireSprite)

-- Rock Modifiers Handlers
local AR_FireRuneClass = require(script.Parent["Items-Classes"]["Rock-Modyfires"].Handlers.AR_FireRune)

-- Rock Modifiers Models
local AR_FireRockClass = require(script.Parent["Items-Classes"]["Rock-Modyfires"].Models.AR_FireRock)


-- Rock Modifiers Exports
export type AR_FireSpriteClassType = typeof(AR_FireSpriteClass)
export type AR_FireRuneClassType = typeof(AR_FireRuneClass)
export type AR_FireRockClassType = typeof(AR_FireRockClass)


export type SingleItemClass = 
	HealthPotionClassType 
| StaminaFasterRegenPotionClassType 
| FireRuneClassType

return {
	HealthPotionClassType = nil :: HealthPotionClassType,
	StaminaFasterRegenPotionClassType = nil :: StaminaFasterRegenPotionClassType,
	
}