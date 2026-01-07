local CharacterKitsClass = {}
CharacterKitsClass.__index = CharacterKitsClass

local Registry = require(script.Parent["Inventory-Class"]["ItemClassRegistry-Enum"])

local HealthClass = require(script.Parent["Health-Class"])
local StaminaClass = require(script.Parent["Stamina-Class"])
local AbilitiesClass = require(script.Parent["Abilities-Class"])

export type HealthClassType = typeof(HealthClass)
export type StaminaClassType = typeof(StaminaClass)
export type AbilitiesClassType = typeof(AbilitiesClass)

export type CharacterKitsClassType = typeof(setmetatable({} :: {
	HealthKit1: any,
	StaminaKit2: any,
	AgilityKit3: any,
}, CharacterKitsClass))

function CharacterKitsClass.Init(player: Player, DATA)
	local self = setmetatable({}, CharacterKitsClass)

	self.Player = player

	self.PlayerData = {DATA.CharacterKits.Health, DATA.CharacterKits.Stamina, DATA.CharacterKits.Abilities }

	self.HealthKit1 = nil -- Take only health kit
	self.StaminaKit2 = nil -- Take only stamina kit
	self.AgilityKit3 = nil -- Take only agitity kit

	return self
end


function CharacterKitsClass:SetKits(HealthClass: HealthClassType, StaminaClass: StaminaClassType, AbilitiesClass: AbilitiesClassType)
	if self.PlayerData then
		for _, kit in ipairs(self.PlayerData) do
			local AllKitsRegistry = Registry.ItemClassRegistry.Kits.All

			if AllKitsRegistry[kit] then
				local KitClass = AllKitsRegistry[kit].Init()

				if KitClass.TypeKit == "Health" then
					if KitClass.TypeHandle == "Increase" then
						HealthClass:IncreaseHealth(KitClass.HealthIncrease)
						self.HealthKit1 = KitClass
					else
						-- for example increase regen amount ext
					end
				elseif KitClass.TypeKit == "Stamina"  then
					if KitClass.TypeHandle == "Increase" then
						StaminaClass:IncreaseStamina(KitClass.StaminaIncrease)
						self.StaminaKit2 = KitClass
					else
						-- for example increase regen amount ext
					end
				elseif KitClass.TypeKit == "Abilities"  then
					AbilitiesClass:SetKitByPercentage(KitClass.WalkIncrease, KitClass.RunIncrease, KitClass.JumpIncrease)
					self.AgilityKit3 = KitClass
				end

				self:SetKitAttributes()
			else
				warn("Kit was not found")
			end
		end
	end
end

-- Modified EquipeNewKit function to auto-update attributes
function CharacterKitsClass:EquipeNewKit(NewKitObject: Registry.SingleAllKits, Class: HealthClassType? | StaminaClassType? | AbilitiesClassType?): Registry.SingleAllKits? | boolean
	local ReturnObject

	if not NewKitObject then
		return false
	end

	if NewKitObject.TypeKit == "Health" then
		if NewKitObject.TypeHandle == "Increase" then
			Class:ResetHealth()
			Class:IncreaseHealth(NewKitObject.HealthIncrease)

			if self.HealthKit1 then
				ReturnObject = self.HealthKit1
			else
				ReturnObject = true
			end

			self.HealthKit1 = NewKitObject
			-- Auto-update attributes
			self:UpdateSingleKitAttributes("Health")
		end
	elseif NewKitObject.TypeKit == "Stamina" then
		if NewKitObject.TypeHandle == "Increase" then
			Class:ResetStamina()
			Class:IncreaseStamina(NewKitObject.StaminaIncrease)

			if self.StaminaKit2 then
				ReturnObject = self.StaminaKit2
			else
				ReturnObject = true
			end

			self.StaminaKit2 = NewKitObject
			-- Auto-update attributes
			self:UpdateSingleKitAttributes("Stamina")
		end
	elseif NewKitObject.TypeKit == "Abilities" then
		Class:ResetToDefault()
		Class:SetKitByPercentage(NewKitObject.WalkIncrease, NewKitObject.RunIncrease, NewKitObject.JumpIncrease)

		if self.AgilityKit3 then
			ReturnObject = self.AgilityKit3
		else
			ReturnObject = true
		end

		self.AgilityKit3 = NewKitObject
		-- Auto-update attributes
		self:UpdateSingleKitAttributes("Abilities")
	else
		ReturnObject = false
	end

	return ReturnObject
end

-- Modified UnEquipeKit function to auto-update attributes
function CharacterKitsClass:UnEquipeKitByType(kitType: string, Class: HealthClassType? | StaminaClassType? | AbilitiesClassType?): Registry.SingleAllKits? | boolean
	if not kitType then
		return false
	end

	local ReturnObject
	kitType = string.lower(kitType)

	if kitType == "health" then
		if self.HealthKit1 then
			if Class then Class:ResetHealth() end
			ReturnObject = self.HealthKit1
			self.HealthKit1 = nil
			self:UpdateSingleKitAttributes("Health")
		else
			ReturnObject = false
		end

	elseif kitType == "stamina" then
		if self.StaminaKit2 then
			if Class then Class:ResetStamina() end
			ReturnObject = self.StaminaKit2
			self.StaminaKit2 = nil
			self:UpdateSingleKitAttributes("Stamina")
		else
			ReturnObject = false
		end

	elseif kitType == "abilities" then
		if self.AgilityKit3 then
			if Class then Class:ResetToDefault() end
			ReturnObject = self.AgilityKit3
			self.AgilityKit3 = nil
			self:UpdateSingleKitAttributes("Abilities")
		else
			ReturnObject = false
		end

	else
		ReturnObject = false
	end

	return ReturnObject
end


function CharacterKitsClass:SetKitAttributes()
	if not self.Player.Character then
		self.Player.CharacterAdded:Wait()
	end

	local Backpack = self.Player:WaitForChild("Backpack")
	local ActiveCharacterKits = Backpack:WaitForChild("ActiveCharacterKits")

	local kitSlots = {
		{kit = self.HealthKit1, folderName = "Health"},
		{kit = self.StaminaKit2, folderName = "Stamina"},
		{kit = self.AgilityKit3, folderName = "Abilities"} -- fixed typo Abilitie → Abilities
	}

	for _, slot in ipairs(kitSlots) do
		local destination = ActiveCharacterKits:WaitForChild(slot.folderName)

		if slot.kit then
			-- Save the kit's name
			if slot.kit.Name then
				destination:SetAttribute("Name", slot.kit.Name)
			end

			-- Set attributes from kit
			for propertyName, propertyValue in pairs(slot.kit) do
				if type(propertyValue) ~= "function" and propertyName ~= "__index" then
					destination:SetAttribute(propertyName, propertyValue)
				end
			end
		else
			-- Clear everything if no kit
			for attributeName, _ in pairs(destination:GetAttributes()) do
				destination:SetAttribute(attributeName, nil)
			end
		end
	end
end

function CharacterKitsClass:UpdateSingleKitAttributes(kitType: string)
	if not self.Player.Character then
		self.Player.CharacterAdded:Wait()
	end

	local Backpack = self.Player:WaitForChild("Backpack")
	local ActiveCharacterKits = Backpack:WaitForChild("ActiveCharacterKits")

	local kitMapping = {
		Health = {kit = self.HealthKit1, folderName = "Health"},
		Stamina = {kit = self.StaminaKit2, folderName = "Stamina"},
		Abilities = {kit = self.AgilityKit3, folderName = "Abilities"}
	}

	local targetKit = kitMapping[kitType]
	if not targetKit then
		warn("Invalid kit type: " .. tostring(kitType))
		return
	end

	warn(targetKit)

	local destination = ActiveCharacterKits:WaitForChild(targetKit.folderName)

	if targetKit.kit then
		-- Save the kit's name
		if targetKit.kit.Name then
			destination:SetAttribute("Name", targetKit.kit.Name)
		end

		for propertyName, propertyValue in pairs(targetKit.kit) do
			if type(propertyValue) ~= "function" and propertyName ~= "__index" then
				destination:SetAttribute(propertyName, propertyValue)
			end
		end
	else
		for attributeName, _ in pairs(destination:GetAttributes()) do
			destination:SetAttribute(attributeName, nil)
		end
	end
end

function CharacterKitsClass:ClearAllKitAttributes()
	if not self.Player.Character then
		self.Player.CharacterAdded:Wait()
	end

	local Backpack = self.Player:WaitForChild("Backpack")
	local ActiveCharacterKits = Backpack:WaitForChild("ActiveCharacterKits")

	local folderNames = {"Health", "Stamina", "Abilities"}

	for _, folderName in ipairs(folderNames) do
		local destination = ActiveCharacterKits:WaitForChild(folderName)
		for attributeName, _ in pairs(destination:GetAttributes()) do
			destination:SetAttribute(attributeName, nil)
		end
	end
end


return CharacterKitsClass
