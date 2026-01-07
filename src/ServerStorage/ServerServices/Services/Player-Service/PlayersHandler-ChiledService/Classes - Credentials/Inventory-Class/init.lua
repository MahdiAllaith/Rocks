--[=[
	@class InventoryClass
	@client
	Manages all inventory operations for a player. 
	Supports adding, removing, using items, and equipping kits/modifiers.
]=]

local InventoryClass = {}
InventoryClass.__index = InventoryClass

local Registry = require(script["ItemClassRegistry-Enum"])

local RockClass = require(script.Parent["StatsRock-Class"])
export type RockClassType = typeof(RockClass)

local CharacterKitsClass = require(script.Parent["CharacterKits-Class"])
export type CharacterKitsClassType = typeof(CharacterKitsClass)

local HealthClass = require(script.Parent["Health-Class"])
export type HealthClassType = typeof(HealthClass)
local StaminaClass = require(script.Parent["Stamina-Class"])
export type StaminaClassType = typeof(StaminaClass)
local AbilitiesClass = require(script.Parent["Abilities-Class"])
export type AbilitiesClassType = typeof(AbilitiesClass)

export type InventoryClassType = typeof(setmetatable({} :: {
	Inventory: { ItemData },
	InventoryLimit: number,
	--Registry: RegistryType, -- you can add this!
}, InventoryClass))


export type ItemData = {
	Name: string,
	Amount: number,
	ItemType: string,
	ItemClass: Registry.SingleAllClasses,
}

local FUtilies = require(game.ReplicatedStorage.Utilities.FunctionUtils)

local USE_ITEMS_STACKING_LIMIT = 25
local JUNK_STACKING_LIMIT = 500

function InventoryClass.Init(player: Player, DATA)
	local self = setmetatable({}, InventoryClass)
	self.Player = player
	-- must be set to database inventory table
	--self.InventoryDataBaseTable  = {
	--	{Name = "LargeRegenStaminaPotion", Amount = 100,ItemType= "UseItem"},
	--	{Name="FireRune", Amount = 2,ItemType= "RockModifire"},
	--	{Name="FireRock", Amount = 1, ItemType="RockModifire"},
	--	{Name="WeakLifeStone", Amount = 1, ItemType="Kit"},
	--	{Name="NormalAgilityStone", Amount = 1, ItemType="Kit"},
	--}

	self.InventoryDataBaseTable = DATA.Inventory.Items

	self.Inventory = {} :: {ItemData}
	self.InventoryLimit = 1000000 -- slots based, and can stack

	local SafeAddEvent = script.Parent.Parent.Safe_ReAdd_Item_To_Invetory
	SafeAddEvent.Event:Connect(function(Player: Player,ItemClass: Registry.SingleAllClasses, Amount: number)
		if Player == self.Player then
			self:AddItem(ItemClass, Amount)
		end
	end)

	local class

	for _, item in ipairs(self.InventoryDataBaseTable) do
		if item.ItemType == "UseItem" then
			class = Registry.ItemClassRegistry.Items.UseItems[item.Name].Init()
		elseif item.ItemType == "RockModifire" then
			class = Registry.ItemClassRegistry["Rock-Modyfires"].All[item.Name].Init()
		elseif item.ItemType == "Kit" then
			class = Registry.ItemClassRegistry.Kits.All[item.Name]:Init()
		elseif item.ItemType == "Junk" then

		end

		if class then
			local result = self:AddItem(class, item.Amount)
		else
			warn("Item class not found for: " .. item.Name)
		end
	end

	return self
end


--[=[
	@param ClassName string
	@return Registry.SingleAllClasses?

	Finds and returns an ItemClass object by its name.
	Useful for retrieving an item’s logic (e.g., HealthPotionClass).
]=]
function InventoryClass:GetAnyItemClass(ClassName : string)
	if ClassName then
		for _, item: ItemData in ipairs(self.Inventory) do
			if item.Name == ClassName then
				return item.ItemClass
			end
		end
	else
		warn("Passed name is nil")
		return nil
	end
end



function InventoryClass:GetItemTypeByNameAndIndex(itemName: string, itemIndex: number): (string?, string?)
	if not itemName then
		warn("[GetItemTypeByNameAndIndex] Item name is nil")
		return nil, nil
	end

	local entry: ItemData?

	-- 1️⃣ Try by index first
	if itemIndex and self.Inventory[itemIndex] then
		if self.Inventory[itemIndex].Name == itemName then
			entry = self.Inventory[itemIndex]
		else
			warn(("[GetItemTypeByNameAndIndex] Index %d exists but name mismatch. Expected '%s', got '%s'")
				:format(itemIndex, itemName, self.Inventory[itemIndex].Name))
		end
	end

	-- 2️⃣ Fallback: search by name
	if not entry then
		for _, invEntry: ItemData in ipairs(self.Inventory) do
			if invEntry.Name == itemName then
				entry = invEntry
				break
			end
		end
	end

	-- 3️⃣ If still nothing → bail
	if not entry then
		warn(("[GetItemTypeByNameAndIndex] No item found with name '%s' or at index %s")
			:format(itemName, tostring(itemIndex)))
		return nil, nil
	end

	-- 4️⃣ Normalize ItemType
	local itemType = entry.ItemType
	if not itemType or itemType == "Other" then
		if entry.ItemClass.ItemType then
			itemType = entry.ItemClass.ItemType
		elseif typeof(entry.ItemClass.Use) == "function" then
			itemType = "UseItem"
		else
			itemType = "Unknown"
		end
	end

	-- 5️⃣ Special cases: RockModifier & Kit
	if itemType == "RockModifire" then
		return itemType, entry.ItemClass.ModifierCategory or "Unknown"
	elseif itemType == "Kit" then
		return itemType, entry.ItemClass.TypeKit or "Unknown"
	end

	-- 6️⃣ Other items
	return itemType, nil
end

-- Find and remove one instance of an item by name
function InventoryClass:ConsumeItemByName(itemName: string): Registry.SingleAllClasses?
	for i, entry in ipairs(self.Inventory) do
		if entry.Name == itemName then
			-- Hold onto class before removal
			local itemClass = entry.ItemClass

			if entry.Amount > 1 then
				entry.Amount -= 1
			else
				table.remove(self.Inventory, i)
			end

			self:UpdateInventoryVisual()
			return itemClass
		end
	end

	warn("[InventoryClass:ConsumeItemByName] Item not found: " .. tostring(itemName))
	return nil
end


function InventoryClass:EquipeRockModifier(PlayerRockClass: RockClassType, itemName: string)
	if not PlayerRockClass or not itemName then return end

	-- Try to get & consume one stack
	local newModifier = self:ConsumeItemByName(itemName)
	if not newModifier then
		warn("Cannot equip rock modifier, item not in inventory: " .. itemName)
		return
	end

	local Return = PlayerRockClass:EquipeModifier(newModifier)

	if type(Return) == "table" then
		-- Put old one back in inventory
		self:AddItem(Return, 1)
	elseif Return == true then
		print("Successfully equipped rock modifier:", itemName)
	else
		print("Error equipping modifier:", Return)
	end
end


-- Pass "Model", "Handler", or "Buffer" instead of modifierName
function InventoryClass:UnEquipeRockModifier(PlayerRockClass: RockClassType, modifierType: string)
	if PlayerRockClass and modifierType then
		local Return = PlayerRockClass:UnequipeModifierByType(modifierType)
		if type(Return) == "table" then -- returned the old modifier class
			self:AddItem(Return, 1) -- put it back in inventory
		elseif Return == false then
			warn("Modifier type not found on player rock:", modifierType)
		end
	end
end


function InventoryClass:EquipeCharacterKit(PlayerCharacterKitsClass: CharacterKitsClassType, itemName: string, Class: HealthClassType? | StaminaClassType? | AbilitiesClassType?)
	if not PlayerCharacterKitsClass or not itemName then return end

	local newKit = self:ConsumeItemByName(itemName)
	if not newKit then
		warn("Cannot equip kit, item not in inventory: " .. itemName)
		return
	end

	local Return = PlayerCharacterKitsClass:EquipeNewKit(newKit, Class)

	if type(Return) == "table" then
		self:AddItem(Return, 1) -- Put old kit back
	elseif Return == true then
		print("Successfully equipped kit:", itemName)
	else
		print("Error equipping kit:", Return)
	end
end



function InventoryClass:UnEquipeCharacterKit(PlayerCharacterKitsClass: CharacterKitsClassType, kitType: string, Class : HealthClassType? | StaminaClassType? | AbilitiesClassType?)
	if PlayerCharacterKitsClass and kitType then
		local Return = PlayerCharacterKitsClass:UnEquipeKitByType(kitType, Class)
		if typeof(Return) == "table" then
			self:AddItem(Return, 1)
		elseif Return == true then
			print("Successfully unequipped kit")
		else
			print("Error: something went wrong")
		end
	end
end

-- Old add item function
--[[----[=[
--	@param item Registry.SingleAllClasses
--	@param amount number
--	@return { success: boolean, leftover: ItemData? }

--	Adds an item to the inventory.
--	- Stacks items up to STACKING_LIMIT.
--	- Creates new stacks if space allows.
--	- Returns leftover items if inventory is full.
--]=]
--function InventoryClass:AddItem(item: Registry.SingleAllClasses, amount: number): {
--	success: boolean,
--	leftover: ItemData?
--	}

--	if typeof(item) ~= "table" then
--		warn("[InventoryClass:AddItem] Invalid item (not a table):", item)
--		return { success = false, leftover = nil }
--	end

--	if  type(amount) ~= "number" or amount <= 0 then
--		warn("[InventoryClass:AddItem] Invalid amount:", amount)
--		return { success = false, leftover = nil }
--	end

--	if not item.Name or not FUtilies.t.string(item.Name) then
--		warn("[InventoryClass:AddItem] Item is missing a valid Name:", item.Name)
--		return { success = false, leftover = nil }
--	end

--	local remaining = amount

--	-- Try stacking with existing entries
--	for _, entry in ipairs(self.Inventory) do
--		if entry.ItemClass == item and entry.Amount < STACKING_LIMIT then
--			local space = STACKING_LIMIT - entry.Amount
--			local toAdd = math.min(space, remaining)
--			entry.Amount += toAdd
--			remaining -= toAdd
--			if remaining <= 0 then
--				return { success = true, leftover = nil }
--			end
--		end
--	end

--	-- Try adding new stacks if needed or allowed
--	while remaining > 0 do
--		if #self.Inventory >= self.InventoryLimit then
--			warn("[InventoryClass:AddItem] Inventory is full. Remaining:", remaining)
--			break
--		end

--		local toAdd = math.min(STACKING_LIMIT, remaining)
--		table.insert(self.Inventory, {
--			Name = item.Name,
--			Amount = toAdd,
--			ItemClass = item,
--		})
--		remaining -= toAdd
--	end

--	if remaining > 0 then
--		warn("[InventoryClass:AddItem] Not all items could be added. Leftover:", remaining)
--		return {
--			success = false,
--			leftover = {
--				Name = item.Name,
--				Amount = remaining,
--				ItemClass = item,
--			} :: ItemData
--		}
--	end

--	return { success = true, leftover = nil }
--end]]


--[=[
	@param item Registry.SingleAllClasses
	@param amount number
	@return { success: boolean, leftover: ItemData? }

	Adds an item to the inventory.
	- UseItems stack up to 25 max
	- Junk items stack up to 500 max  
	- Other items (RockModifiers, Kits) only stack to 1
	- Creates new stacks if space allows.
	- Returns leftover items if inventory is full.
]=]
function InventoryClass:AddItem(item: Registry.SingleAllClasses, amount: number): {
	success: boolean,
	leftover: ItemData?
	}

	if typeof(item) ~= "table" then
		warn("[InventoryClass:AddItem] Invalid item (not a table):", item)
		return { success = false, leftover = nil }
	end

	if  type(amount) ~= "number" or amount <= 0 then
		warn("[InventoryClass:AddItem] Invalid amount:", amount)
		return { success = false, leftover = nil }
	end

	if not item.Name or not FUtilies.t.string(item.Name) then
		warn("[InventoryClass:AddItem] Item is missing a valid Name:", item.Name)
		return { success = false, leftover = nil }
	end

	-- Determine stacking limit based on item type
	local stackingLimit = 1 -- Default for RockModifiers, Kits, etc.

	-- Check if item has ItemType property to determine stacking limit
	if item.ItemType then
		if item.ItemType == "UseItem" then
			stackingLimit = USE_ITEMS_STACKING_LIMIT -- 25
		elseif item.ItemType == "Junk" then
			stackingLimit = JUNK_STACKING_LIMIT -- 500
		end
	else
		-- Fallback: try to determine from registry path or item class type
		-- This is a backup method if ItemType isn't available on the item
		if typeof(item.Use) == "function" then
			stackingLimit = USE_ITEMS_STACKING_LIMIT -- 25 (UseItems have Use function)
		end
	end

	local remaining = amount

	-- Try stacking with existing entries
	for _, entry in ipairs(self.Inventory) do
		if entry.ItemClass == item and entry.Amount < stackingLimit then
			local space = stackingLimit - entry.Amount
			local toAdd = math.min(space, remaining)
			entry.Amount += toAdd
			remaining -= toAdd
			if remaining <= 0 then
				return { success = true, leftover = nil }
			end
		end
	end

	-- Try adding new stacks if needed or allowed
	while remaining > 0 do
		if #self.Inventory >= self.InventoryLimit then
			warn("[InventoryClass:AddItem] Inventory is full. Remaining:", remaining)
			break
		end

		local toAdd = math.min(stackingLimit, remaining)

		-- Determine ItemType for the inventory entry
		local itemType = "Other" -- Default
		if item.ItemType then
			itemType = item.ItemType
		elseif typeof(item.Use) == "function" then
			itemType = "UseItem"
		end

		table.insert(self.Inventory, {
			Name = item.Name,
			Amount = toAdd,
			ItemType = itemType,
			ItemClass = item,
		})
		remaining -= toAdd
	end

	if remaining > 0 then
		warn("[InventoryClass:AddItem] Not all items could be added. Leftover:", remaining)
		return {
			success = false,
			leftover = {
				Name = item.Name,
				Amount = remaining,
				ItemType = item.ItemType or "Other",
				ItemClass = item,
			} :: ItemData
		}
	end

	self:UpdateInventoryVisual()

	return { success = true, leftover = nil }
end


--[=[
	@param item Registry.SingleAllUseItemClasses
	@return (() -> ())?

	Uses a consumable item (like a potion).
	- Reduces its amount by 1 (or removes it if 0 left).
	- Returns the item’s Use function so it can be executed.
]=]
function InventoryClass:UseItem(item: Registry.SingleAllUseItemClasses)
	if typeof(item) ~= "table" then
		return nil
	end

	for i, entry in ipairs(self.Inventory) do
		if entry.ItemClass == item then
			if entry.Amount > 1 then
				entry.Amount -= 1
			else
				table.remove(self.Inventory, i)
			end
			print(self.Inventory)

			self:UpdateInventoryVisual()
			return item.Use
		end
	end

	return nil
end


--[=[
	@param item Registry.SingleAllClasses
	@param amount number
	@return { success: boolean, removed: number }

	Removes a certain amount of an item from the inventory.
	- If amount == -1, removes the entire stack.
	- Returns how many items were successfully removed.
]=]
function InventoryClass:RemoveItem(item: Registry.SingleAllClasses, amount: number): {
	success: boolean,
	removed: number
	}
	if typeof(item) ~= "table" then
		warn("[InventoryClass:RemoveItem] Invalid item:", item)
		return { success = false, removed = 0 }
	end

	if type(amount) ~= "number" or (amount <= 0 and amount ~= -1) then
		warn("[InventoryClass:RemoveItem] Invalid amount:", amount)
		return { success = false, removed = 0 }
	end

	for i = #self.Inventory, 1, -1 do
		local entry = self.Inventory[i]
		if entry.ItemClass == item then
			-- If amount = -1 → remove entire stack
			if amount == -1 then
				local removedAmount = entry.Amount
				table.remove(self.Inventory, i)
				return { success = true, removed = removedAmount }
			end

			-- Normal removal
			if entry.Amount > amount then
				entry.Amount -= amount
				return { success = true, removed = amount }
			else
				local removedAmount = entry.Amount
				table.remove(self.Inventory, i)
				amount -= removedAmount
				if amount <= 0 then
					return { success = true, removed = removedAmount }
				end
			end
		end
	end

	self:UpdateInventoryVisual()

	-- Couldn’t remove full amount
	return { success = false, removed = 0 }
end


--[=[
	Clears the entire inventory for the player.
	Useful for debugging, resets, or full wipes.
]=]
function InventoryClass:ClearInventory()
	self.Inventory = {}
	self:UpdateInventoryVisual()
	print("[InventoryClass:ClearInventory] Inventory cleared for player:", self.Player)
end

function InventoryClass:UpdateInventoryVisual()
	task.spawn(function()
		task.wait() -- just to be sure all is created and set
		if not self.Player.Character then
			self.Player.CharacterAdded:Wait()
		end

		local Backpack = self.Player:WaitForChild("Backpack")

		-- Ensure Inventory folder exists
		local InventoryFolder = Backpack:FindFirstChild("Inventory")
		if not InventoryFolder then
			InventoryFolder = Instance.new("Folder")
			InventoryFolder.Name = "Inventory"
			InventoryFolder.Parent = Backpack
		end

		-- Track folders that should remain
		local activeFolders = {}

		-- Stats counters
		local SlotsUsed = 0
		local TotalItems = 0
		local KitCount, ModifierCount, UseItemCount, JunkCount = 0, 0, 0, 0
		local KitAmount, ModifierAmount, UseItemAmount, JunkAmount = 0, 0, 0, 0

		-- New specific counters
		local RockHandlerModifierCount, RockModelModifierCount, RockBufferModifierCount = 0, 0, 0
		local CharacterHealthKitCount, CharacterStaminaKitCount, CharacterAbilitiesKitCount = 0, 0, 0

		-- Sync each stack in self.Inventory
		for index, entry in ipairs(self.Inventory) do
			SlotsUsed += 1
			TotalItems += entry.Amount

			-- ✅ Normalize ItemType (fallback safety)
			local itemType = entry.ItemType
			if not itemType or itemType == "Other" then
				if entry.ItemClass.ItemType then
					itemType = entry.ItemClass.ItemType
				elseif typeof(entry.ItemClass.Use) == "function" then
					itemType = "UseItem"
				else
					itemType = "Unknown"
				end
				entry.ItemType = itemType -- keep inventory in sync
			end

			-- Count categories
			if itemType == "Kit" then
				KitCount += 1
				KitAmount += entry.Amount

				-- Count specific kit types
				local typeKit = entry.ItemClass.TypeKit
				if typeKit == "Health" then
					CharacterHealthKitCount += 1
				elseif typeKit == "Stamina" then
					CharacterStaminaKitCount += 1
				elseif typeKit == "Abilities" then
					CharacterAbilitiesKitCount += 1
				end

			elseif itemType == "RockModifire" then
				ModifierCount += 1
				ModifierAmount += entry.Amount

				-- Count specific modifier types
				local modifierCategory = entry.ItemClass.ModifierCategory
				if modifierCategory == "Handler" then
					RockHandlerModifierCount += 1
				elseif modifierCategory == "Model" then
					RockModelModifierCount += 1
				elseif modifierCategory == "Buffer" then
					RockBufferModifierCount += 1
				end

			elseif itemType == "UseItem" then
				UseItemCount += 1
				UseItemAmount += entry.Amount
			elseif itemType == "Junk" then
				JunkCount += 1
				JunkAmount += entry.Amount
			end

			-- Folder name per stack
			local folderName = ("%s_%d"):format(entry.Name, index)
			activeFolders[folderName] = true

			-- Find or create folder
			local stackFolder = InventoryFolder:FindFirstChild(folderName)
			if not stackFolder then
				stackFolder = Instance.new("Folder")
				stackFolder.Name = folderName
				stackFolder.Parent = InventoryFolder
			end

			-- Core attributes
			stackFolder:SetAttribute("Name", entry.Name)
			stackFolder:SetAttribute("ItemType", entry.ItemType) -- use ItemType, not Type
			stackFolder:SetAttribute("Amount", entry.Amount)

			-- Update item class properties
			for propertyName, propertyValue in pairs(entry.ItemClass) do
				if type(propertyValue) ~= "function" and propertyName ~= "__index" and typeof(propertyValue) ~= "Instance" then
					-- Prevent overwriting our own keys
					if propertyName ~= "ItemType" and propertyName ~= "Name" and propertyName ~= "Amount" then
						stackFolder:SetAttribute(propertyName, propertyValue)
					end
				end
			end
		end

		-- Remove folders that no longer correspond to active stacks
		for _, child in ipairs(InventoryFolder:GetChildren()) do
			if child:IsA("Folder") and not activeFolders[child.Name] then
				child:Destroy()
			end
		end

		-- Global attributes
		InventoryFolder:SetAttribute("SlotsUsed", SlotsUsed)
		InventoryFolder:SetAttribute("TotalItems", TotalItems)

		InventoryFolder:SetAttribute("KitCount", KitCount)
		InventoryFolder:SetAttribute("KitAmount", KitAmount)

		InventoryFolder:SetAttribute("ModifierCount", ModifierCount)
		InventoryFolder:SetAttribute("ModifierAmount", ModifierAmount)

		InventoryFolder:SetAttribute("UseItemCount", UseItemCount)
		InventoryFolder:SetAttribute("UseItemAmount", UseItemAmount)

		InventoryFolder:SetAttribute("JunkCount", JunkCount)
		InventoryFolder:SetAttribute("JunkAmount", JunkAmount)

		-- New specific count attributes
		InventoryFolder:SetAttribute("RockHandlerModifierCount", RockHandlerModifierCount)
		InventoryFolder:SetAttribute("RockModelModifierCount", RockModelModifierCount)
		InventoryFolder:SetAttribute("RockBufferModifierCount", RockBufferModifierCount)
		InventoryFolder:SetAttribute("CharacterHealthKitCount", CharacterHealthKitCount)
		InventoryFolder:SetAttribute("CharacterStaminaKitCount", CharacterStaminaKitCount)
		InventoryFolder:SetAttribute("CharacterAbilitiesKitCount", CharacterAbilitiesKitCount)
	end)
end




return InventoryClass
