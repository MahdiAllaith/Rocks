local MainItemFolder = script.Parent:WaitForChild("Items-Classes")

-- === Require Useable Items Classes ===
local SmallHealthPotion = require(MainItemFolder.Items.Useable_Items.SmallHealthPotion)
local MediumHealthPotion = require(MainItemFolder.Items.Useable_Items.MediumHealthPotion)
local LargeHealthPotion = require(MainItemFolder.Items.Useable_Items.LargeHealthPotion)

local SmallRegenStaminaPotion = require(MainItemFolder.Items.Useable_Items.SmallRegenStaminaPotion)
local MediumRegenStaminaPotion = require(MainItemFolder.Items.Useable_Items.MediumRegenStaminaPotion)
local LargeRegenStaminaPotion = require(MainItemFolder.Items.Useable_Items.LargeRegenStaminaPotion)

-- === Require junk Items Classes ===



-- === Require Kit For Health ===
local A_WeakLifeStoneClass = require(MainItemFolder.Kits["A_WeakLifeStone-Health"])
local A_NormalLifeStoneClass = require(MainItemFolder.Kits["A_NormalLifeStone-Health"])

-- === Require Kit For Stamina ===
local A_WeakEnergyStoneClass = require(MainItemFolder.Kits["A_WeakEnergyStone-Stamina"])
local A_NormalEnergyStoneClass = require(MainItemFolder.Kits["A_NormalEnergyStone-Stamina"])

-- === Require Kit For Abilities ===
local A_WeakAgilityStoneClass = require(MainItemFolder.Kits["A_WeakAgilityStone-Abilities"])
local A_NormalAgilityStoneClass = require(MainItemFolder.Kits["A_NormalAgilityStone-Abilities"])









-- === Require Rock Modifiers Buffers ===
local AR_FireSpriteClass = require(MainItemFolder["Rock-Modyfires"].Buffers.AR_FireSprite)


-- === Require Rock Modifiers Handlers ===
local AR_FireRuneClass = require(MainItemFolder["Rock-Modyfires"].Handlers.AR_FireRune)


-- === Require Rock Modifiers Models ===
local AR_FireRockClass = require(MainItemFolder["Rock-Modyfires"].Models.AR_FireRock)








-- === Export Types for Items ===
export type SmallHealthPotionType = typeof(SmallHealthPotion)
export type MediumHealthPotionType = typeof(SmallHealthPotion)
export type LargeHealthPotionType = typeof(SmallHealthPotion)

export type SmallRegenStaminaPotionType = typeof(SmallRegenStaminaPotion)
export type MediumRegenStaminaPotionType = typeof(MediumRegenStaminaPotion)
export type LargeRegenStaminaPotionType = typeof(LargeRegenStaminaPotion)






-- === Export Types for health kit ===
export type A_WeakLifeStoneType = typeof(A_WeakLifeStoneClass)
export type A_NormalLifeStoneType = typeof(A_NormalLifeStoneClass)


-- === Export Types for stamina kit ===
export type A_WeakEnergyStoneType = typeof(A_WeakEnergyStoneClass)
export type A_NormalEnergyStoneType = typeof(A_NormalEnergyStoneClass)


-- === Export Types for abilities kit ===
export type A_WeakAgilityStoneType = typeof(A_WeakAgilityStoneClass)
export type A_NormalAgilityStoneType = typeof(A_NormalAgilityStoneClass)








-- === Export Types for Rock Modifiers Buffers ===
export type AR_FireSpriteClassType = typeof(AR_FireSpriteClass)

-- === Export Types for Rock Modifiers Handlers ===
export type AR_FireRuneClassType = typeof(AR_FireRuneClass)

-- === Export Types for Rock Modifiers Models ===
export type AR_FireRockClassType = typeof(AR_FireRockClass)






-- === Single Union Type All Character Kits ===
export type SingleAllKits = A_WeakLifeStoneType
| A_NormalLifeStoneType
| A_WeakEnergyStoneType
| A_NormalEnergyStoneType
| A_WeakAgilityStoneType
| A_NormalAgilityStoneType


-- === Single Union Types For Rock Modifiers Buffers ===
export type SingleRockModBuffers = AR_FireSpriteClassType


-- === Single Union Types For Rock Modifiers Handlers ===
export type SingleRockModHandlers = AR_FireRuneClassType


-- === Single Union Types For Rock Modifiers Models ===
export type SingleRockModModels = AR_FireRockClassType





-- === Unified Union of All Items (like SingleItemClass) ===
export type SingleAllClasses = SmallHealthPotionType | MediumHealthPotionType | LargeHealthPotionType
| SmallRegenStaminaPotionType | MediumRegenStaminaPotionType | MediumRegenStaminaPotionType
| AR_FireSpriteClassType
| AR_FireRuneClassType
| AR_FireRockClassType
| A_WeakLifeStoneType
| A_NormalLifeStoneType
| A_WeakEnergyStoneType
| A_NormalEnergyStoneType
| A_WeakAgilityStoneType
| A_NormalAgilityStoneType

export type SingleAllRockModifiersClass = AR_FireSpriteClassType
| AR_FireRuneClassType
| AR_FireRockClassType

export type SingleAllUseItemClasses = SmallHealthPotionType | MediumHealthPotionType | LargeHealthPotionType
| SmallRegenStaminaPotionType | MediumRegenStaminaPotionType | MediumRegenStaminaPotionType


-- === Registry Type ===
export type Registry = {
	Kits: {
		Health:{
			A_WeakLifeStone: A_WeakLifeStoneType,
			A_NormalLifeStone: A_NormalLifeStoneType

		},
		Stamina:{
			A_WeakEnergyStone:A_WeakEnergyStoneType,
			A_NormalEnergyStone:A_NormalEnergyStoneType

		},
		Abilities:{
			A_WeakAgilityStone:A_WeakAgilityStoneType,
			A_NormalAgilityStone:A_NormalAgilityStoneType

		},
		All: {
			WeakLifeStone: A_WeakLifeStoneType,
			NormalLifeStone: A_NormalLifeStoneType,
			WeakEnergyStone:A_WeakEnergyStoneType,
			NormalEnergyStone:A_NormalEnergyStoneType,
			WeakAgilityStone:A_WeakAgilityStoneType,
			NormalAgilityStone:A_NormalAgilityStoneType,
		}
	},

	["Rock-Modyfires"]: {
		Buffers: {
			AR_FireSprite: AR_FireSpriteClassType,
		},
		Models: {
			AR_FireRock: AR_FireRockClassType,
		},
		Handlers: {
			AR_FireRune: AR_FireRuneClassType,
		},
		All: {
			FireSprite: AR_FireSpriteClassType,
			FireRock: AR_FireRockClassType,
			FireRune: AR_FireRuneClassType,
		}
	},

	Items: {
		UseItems: {
			SmallHealthPotion: SmallHealthPotionType,
			MediumHealthPotion: MediumHealthPotionType,
			LargeHealthPotion: LargeHealthPotionType,
			SmallRegenStaminaPotion: SmallRegenStaminaPotionType,
			MediumRegenStaminaPotion: MediumRegenStaminaPotionType,
			LargeRegenStaminaPotion: LargeRegenStaminaPotionType,
			
		},
		Junk: {

		},
	},
}

local ItemClassRegistry: Registry = {
	Kits = {
		Health = {
			A_WeakLifeStone = A_WeakLifeStoneClass,
			A_NormalLifeStone = A_NormalLifeStoneClass

		},
		Stamina = {
			A_WeakEnergyStone = A_WeakEnergyStoneClass,
			A_NormalEnergyStone = A_NormalEnergyStoneClass

		},
		Abilities = {
			A_WeakAgilityStone = A_WeakAgilityStoneClass,
			A_NormalAgilityStone = A_NormalAgilityStoneClass

		},
		All = {
			WeakLifeStone = A_WeakLifeStoneClass,
			NormalLifeStone = A_NormalLifeStoneClass,
			WeakEnergyStone = A_WeakEnergyStoneClass,
			NormalEnergyStone = A_NormalEnergyStoneClass,
			WeakAgilityStone = A_WeakAgilityStoneClass,
			NormalAgilityStone = A_NormalAgilityStoneClass,
		}
	},

	["Rock-Modyfires"] = {
		Buffers = {
			AR_FireSprite = AR_FireSpriteClass,
		},
		Models = {
			AR_FireRock = AR_FireRockClass,
		},
		Handlers = {
			AR_FireRune = AR_FireRuneClass,
		},
		All = {
			FireSprite = AR_FireSpriteClass,
			FireRune = AR_FireRuneClass,
			FireRock = AR_FireRockClass,
		},
	},

	Items = {
		UseItems = {
			SmallHealthPotion = SmallHealthPotion,
			MediumHealthPotion = MediumHealthPotion,
			LargeHealthPotion = LargeHealthPotion,
			SmallRegenStaminaPotion = SmallRegenStaminaPotion,
			MediumRegenStaminaPotion = MediumRegenStaminaPotion,
			LargeRegenStaminaPotion = LargeRegenStaminaPotion,
		},
		Junk = {

		},
		
	},
}

-- === Return Registry and Types (if needed externally) ===
return {
	ItemClassRegistry = ItemClassRegistry,
	SingleRockModBuffers = nil :: SingleRockModBuffers,
	SingleRockModHandlers = nil :: SingleRockModHandlers,
	SingleRockModModels = nil :: SingleRockModModels,
	SingleAllClasses = nil :: SingleAllClasses,
	SingleAllRockModifiersClass = nil :: SingleAllRockModifiersClass,
	SingleAllUseItemClasses = nil :: SingleAllUseItemClasses,
	SingleAllItemClasses = nil :: SingleAllItemClasses,
	SingleAllKits = nil :: SingleAllItemClasses,
}
