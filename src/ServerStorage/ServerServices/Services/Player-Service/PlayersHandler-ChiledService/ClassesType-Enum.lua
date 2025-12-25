local Types = {}

local HealthClass = require(script.Parent["Classes - Credentials"]["Health-Class"])
local StaminaClass = require(script.Parent["Classes - Credentials"]["Stamina-Class"])
local LevelClass = require(script.Parent["Classes - Credentials"]["Level-Class"])
local WalletClass = require(script.Parent["Classes - Credentials"]["Wallet-Class"])
local PlayerDataClass = require(script.Parent["Classes - Credentials"]["PlayerDATA-Class"])
local AbilitiesClass = require(script.Parent["Classes - Credentials"]["Abilities-Class"])
local CharacterKitsClass = require(script.Parent["Classes - Credentials"]["CharacterKits-Class"])
local InventoryClass = require(script.Parent["Classes - Credentials"]["Inventory-Class"])
local StatsRockClass = require(script.Parent["Classes - Credentials"]["StatsRock-Class"])
local De_BuffsClass = require(script.Parent["Classes - Credentials"]["De&Buffs-Class"])
local ProgressClass = require(script.Parent["Classes - Credentials"]["Progress-Class"])
local SettingsClass = require(script.Parent["Classes - Credentials"]["Settings-Class"])


export type HealthClassType = HealthClass.HealthClassType
export type StaminaClassType = StaminaClass.StaminaClassType
export type LevelClassType = LevelClass.LevelClassType
export type WalletClassType = WalletClass.WalletClassType
export type PlayerDataClassType = PlayerDataClass.PlayerDataClassType
export type AbilitiesClassType = AbilitiesClass.AbilitiesClassType
export type CharacterKitsClassType = CharacterKitsClass.CharacterKitsClassType
export type InventoryClassType = InventoryClass.InventoryClassType
export type StatsRockClassType = StatsRockClass.StatsRockClassType

-- not added yet
export type De_BuffsClassType = De_BuffsClass
export type ProgressClassType = ProgressClass
export type SettingsClassType = SettingsClass

export type ClassMap = {
	HealthClass: HealthClassType,
	StaminaClass: StaminaClassType,
	LevelClass: LevelClassType,
	WalletClass: WalletClassType,
	PlayerDataClass: PlayerDataClassType,
	AbilitiesClass: AbilitiesClassType,
	CharacterKitsClass: CharacterKitsClassType,
	InventoryClass: InventoryClassType,
	StatsRockClass: StatsRockClassType
	-- add other classes
}

export type PlayerRecord = {
	Classes: ClassMap,
	PlayerData: any -- make this a typed structure too later when making dataStor
}

return Types