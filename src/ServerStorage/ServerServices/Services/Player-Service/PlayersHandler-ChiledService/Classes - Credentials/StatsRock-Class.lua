local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatsRockClass = {}
StatsRockClass.__index = StatsRockClass

local Registry = require(script.Parent["Inventory-Class"]["ItemClassRegistry-Enum"])

local SetPlayerRockEvent = game.ReplicatedStorage.Events.RockHandler.SetPlayersRock_Event
local RestRockEvent = game.ReplicatedStorage.Events.RockHandler.ResetRock_Event
local DefaultRockHandle = game.ReplicatedStorage.Modifiers.Rocks_Models.Default.DefaultRock

local SafeAddEvent = script.Parent.Parent.Safe_ReAdd_Item_To_Invetory

local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)

local HealthClass = require(script.Parent["Health-Class"])
export type HealthClassType = typeof(HealthClass)

export type DamageFunctionType = (TheHealthClass: HealthClassType) -> nil
export type StatsRockClassType = typeof(setmetatable({} :: {
	Damage: number,
	ThrowDestince: number,
	CoolDown: number,
	Mod1_Shape_and_Damage : Registry.SingleRockModModels,
	Mod2_Handler : Registry.SingleRockModHandlers,
	Mod3_Buffers : Registry.SingleRockModBuffers,
	RockType: string,
	DamageFunction: DamageFunctionType
}, StatsRockClass))

function StatsRockClass.Init(player: Player, DATA)
	local self = setmetatable({}, StatsRockClass)

	self.Player = player

	--local playerDummyData = {Model = "FireRock", Handler = "", Buffer = ""}

	self.Mod1_Shape_and_Damage = nil
	self.Mod2_Handler = nil
	self.Mod3_Buffers = nil 

	self.RockType = nil

	self.ThrowDestince = 40 -- default throw destince  
	self.CoolDown = 1 -- second

	self.Damage = 110 -- default damage
	--self.DamageType = nil -- three types of damage : "Hit", "Bleed", "Hit&Bleed"

	self.FireDamage = 0 -- for every tick
	self.IceDamage = 0 -- for every tick
	self.DarkMagicDamage = 0 -- for every tick
	self.LuminiteDamage = 0 -- for every tick

	self.DamageFunction = nil

	self:SetRockClasses(DATA.RockStats)

	warn(self.DamageFunction)

	-- after initializing all modifiers 
	self.Player:SetAttribute("RockCoolDown", self.CoolDown)
	self.Player:SetAttribute("ThrowDestince", self.ThrowDestince)

	SetPlayerRockEvent:FireAllClients(self.Player, {Name = self.Mod2_Handler and self.Mod2_Handler.Name , Type = self.RockType, Rock = self.Mod1_Shape_and_Damage and self.Mod1_Shape_and_Damage.Name} or nil)

	return self
end

function StatsRockClass:EquipeModifier(newModifierObject: Registry.SingleAllRockModifiersClass): Registry.SingleAllRockModifiersClass? | boolean
	if not newModifierObject then
		return false
	end

	local oldClass = nil
	local category = newModifierObject.ModifierCategory -- "Models", "Handlers", "Buffers"

	if not category then
		warn("[StatsRockClass:EquipeModifier] Missing ModifierCategory on:", newModifierObject.Name)
		return false
	end

	if category == "Model" then
		if self.Mod2_Handler == nil then
			self.Mod1_Shape_and_Damage = newModifierObject
			if self.Mod1_Shape_and_Damage ~= nil then
				oldClass = self.Mod1_Shape_and_Damage
			end
		elseif self.Mod2_Handler ~= nil and self.RockType == newModifierObject.Type then
			oldClass = self.Mod1_Shape_and_Damage
			self.Mod1_Shape_and_Damage = newModifierObject
		else
			return false
		end

	elseif category == "Handler" then
		if self.Mod1_Shape_and_Damage == nil then
			if self.Mod2_Handler == nil then
				self.Mod2_Handler = newModifierObject
			else
				oldClass = self.Mod2_Handler
				self.Mod2_Handler = newModifierObject
			end

		elseif self.Mod1_Shape_and_Damage ~= nil and self.RockType == newModifierObject.Type then
			if self.Mod2_Handler then
				oldClass = self.Mod2_Handler
			end

			self.Mod2_Handler = newModifierObject
		else
			return false
		end

	elseif category == "Buffer" then
		if self.Mod2_Handler == nil then
			self.Mod3_Buffers = newModifierObject
		else
			oldClass = self.Mod3_Buffers
			self.Mod3_Buffers = newModifierObject
		end
	else
		warn("[StatsRockClass:EquipeModifier] Invalid category: " .. tostring(category))
		return false
	end

	self:RefreshModifiers()

	local collectionService = game:GetService("CollectionService")
	collectionService:AddTag(self.Player, "RestingTool")
	task.wait(0.1) -- must yield briefly for tag update
	collectionService:RemoveTag(self.Player, "RestingTool")

	RestRockEvent:FireClient(self.Player, {
		Name = self.Mod2_Handler and self.Mod2_Handler.Name,
		Type = self.RockType,
		Rock = self.Mod1_Shape_and_Damage and self.Mod1_Shape_and_Damage.Name
	} or nil)

	return oldClass or true
end



function StatsRockClass:UnequipeModifierByType(modifierType: string): Registry.SingleAllRockModifiersClass? | boolean
	if not modifierType or modifierType == "" then
		return false
	end

	local oldClass = nil
	modifierType = string.lower(modifierType)

	-- Model (Shape & Damage)
	if modifierType == "model" and self.Mod1_Shape_and_Damage then
		oldClass = self.Mod1_Shape_and_Damage
		self.Mod1_Shape_and_Damage = nil

		-- Handler
	elseif modifierType == "handler" and self.Mod2_Handler then
		oldClass = self.Mod2_Handler
		self.Mod2_Handler = nil

		local collectionService = game:GetService("CollectionService")
		collectionService:AddTag(self.Player, "RestingTool")
		task.wait(0.1)
		collectionService:RemoveTag(self.Player, "RestingTool")

		RestRockEvent:FireClient(self.Player, {
			Name = "",
			Type = self.RockType,
			Rock = self.Mod1_Shape_and_Damage and self.Mod1_Shape_and_Damage.Name
		})

		-- Buffer
	elseif modifierType == "buffer" and self.Mod3_Buffers then
		oldClass = self.Mod3_Buffers
		self.Mod3_Buffers = nil
	else
		return false -- no slot found for that type
	end

	-- Refresh stats
	self:RefreshModifiers()

	return oldClass
end



function StatsRockClass:SetRockClasses(Data: {Model: string?, Handler: string?, Buffer: string?})
	local Clone

	if Data.Model == nil or Data.Model == "" then -- Sets default rock
		local function GiveTool()
			local backpack = self.Player:WaitForChild("Backpack").Tool
			Clone = DefaultRockHandle:Clone()
			Clone.Name = "Handle"
			Clone.Parent = backpack
		end

		if self.Player.Character then
			GiveTool()
		end

		self.Player.CharacterAdded:Connect(function()
			GiveTool()
		end)

		self.Mod1_Shape_and_Damage = nil
	else
		for AllClasses, Class in pairs(Registry.ItemClassRegistry["Rock-Modyfires"].Models) do
			if Data.Model == Class.Name then
				self.Mod1_Shape_and_Damage = Class.Init()

				self.RockType = self.Mod1_Shape_and_Damage.Type
				self.Damage = self.Mod1_Shape_and_Damage.RockDamage

				local OriginalModel = self.Mod1_Shape_and_Damage.Model

				local function GiveTool()
					if not OriginalModel then
						warn("Original model not found")
						return
					end

					local Backpack = self.Player:WaitForChild("Backpack", 5)
					if not Backpack then
						warn("Backpack not found for player")
						return
					end

					local Tool = Backpack:FindFirstChild("Tool")
					if not Tool then
						warn("Tool not found in Backpack")
						return
					end

					-- Clone fresh each time
					local Clone = OriginalModel:Clone()
					Clone.Name = "Handle"
					Clone.Parent = Tool
				end

				if self.Player.Character then
					GiveTool()
				end

				self.Player.CharacterAdded:Connect(function()
					GiveTool()
				end)
			end
		end
	end

	if Data.Handler and Data.Handler ~= "" then
		-- loops throw registry export types to find the correct handler by class name
		for AllClasses, Class in pairs(Registry.ItemClassRegistry["Rock-Modyfires"].Handlers) do
			if Data.Handler == Class.Name then

				self.Mod2_Handler = Class.Init()

				if not self.RockType or self.RockType == self.Mod2_Handler.Type then

					if not self.RockType then
						self.RockType = self.Mod2_Handler.Type
					end

					self.ThrowDestince = self.Mod2_Handler.NewThrowDestince

					self:SetSpecialDamage(self.RockType, self.Mod2_Handler)
					self:SetDamageFunction(self.Mod2_Handler.DamageType, self.Mod2_Handler)

					-- just to remove the attachement and trail from the rock model as it will be added to all models
					-- so all module can work with the default rock handler code, as it requires the trail object
					if self.Mod1_Shape_and_Damage  then
						if Clone then
							for _, child in pairs(Clone:GetChildren()) do
								child:Destroy()
							end
						end
					end

					warn(self.Mod2_Handler)
					warn("asdasdasdasd")

				else -- this if type does not match
					SafeAddEvent.Event:Fire(self.Player, self.Mod2_Handler, 1) -- Saves the modifier in the player inventory
					-- Should have event for notification to client must add later
					self.Mod2_Handler = nil
					warn("Rock model type must equal the handler type")
				end
			end
		end
	else
		-- sets the default damage handler
		self:SetDamageFunction()
	end

	-- for sure will work on it later need alot of work becasue gamplay might change or require more extended buffes
	if Data.Handler and Data.Handler ~= "" then
		for AllClasses, Class in pairs(Registry.ItemClassRegistry["Rock-Modyfires"].Buffers) do
			if Data.Buffer == Class.Name then

				self.Mod3_Buffers = Class.Init()

				local SetOtherModifiers = function()
					local ThrowDistanceModifier = self.Mod3_Buffers.ThrowDistanceModifier
					local DamageMultiplier = self.Mod3_Buffers.DamageMultiplier

					if ThrowDistanceModifier ~= 0 then
						self.ThrowDistance *= (1 + ThrowDistanceModifier)
					end
					if DamageMultiplier ~= 0 then
						self.BaseDamage *= (1 + DamageMultiplier)
					end
				end

				if self.Mod3_Buffers.EffectType == "Fire" then
					local SpacileDamage = self.Mod3_Buffers.FireModifier
					self.FireDamage *= (1 + SpacileDamage)
					SetOtherModifiers()
				elseif self.Mod3_Buffers.EffectType == "Ice" then
					local SpacileDamage = self.Mod3_Buffers.IceModifier
					self.FireDamage *= (1 + SpacileDamage)
					SetOtherModifiers()
				elseif self.Mod3_Buffers.EffectType == "DarkMagic" then
					local SpacileDamage = self.Mod3_Buffers.DarkMagicModifier
					self.FireDamage *= (1 + SpacileDamage)
					SetOtherModifiers()
				elseif self.Mod3_Buffers.EffectType == "Luminite" then
					local SpacileDamage = self.Mod3_Buffers.LuminiteModifier
					self.FireDamage *= (1 + SpacileDamage)
					SetOtherModifiers()
				end
			end
		end
	end

	self:SetRockStats() -- sets the new rock stats attributes
	self:SetModifierData() -- sets the new rock modifiers stats attributes

end

function StatsRockClass:RefreshModifiers()
	-- Reset to safe defaults before reapplying	
	self.RockType = nil
	self.Damage = 20
	self.ThrowDestince = 40 
	self.CoolDown = 1 
	self.FireDamage = 0
	self.IceDamage = 0
	self.DarkMagicDamage = 0
	self.LuminiteDamage = 0
	self.DamageFunction = nil

	-- Handle model (Mod1)
	local Clone
	if self.Mod1_Shape_and_Damage == nil then
		-- default rock handle
		local DefaultRockHandle = game.ReplicatedStorage.Modifiers.Rocks_Models.Default.DefaultRock
		Clone = DefaultRockHandle:Clone()
		self.RockType = nil
		self.Mod1_Shape_and_Damage = nil
	else
		self.RockType = self.Mod1_Shape_and_Damage.Type
		self.Damage = self.Mod1_Shape_and_Damage.RockDamage
		Clone = self.Mod1_Shape_and_Damage.Model:Clone()

		-- If you have to strip existing attachments/trail for handler later, that logic can stay in handler application
	end


	-- Find the tool (check backpack first, then character) with pcall protection
	local backpackTool : Tool
	local success, error = pcall(function()
		backpackTool = self.Player:WaitForChild("Backpack"):FindFirstChild("Tool")

		-- If tool not in backpack, check if it's equipped in character
		if not backpackTool then
			local character = self.Player.Character
			if character then
				backpackTool = character:FindFirstChild("Tool")
				-- If tool is in character, move it back to backpack
				if backpackTool and backpackTool:IsA("Tool") then
					backpackTool.Parent = self.Player:WaitForChild("Backpack")
				end
			end
		end
	end)

	-- If pcall failed or tool still not found, wait and try again
	if not success or not backpackTool then
		warn("Tool not found in backpack or character, waiting...")
		wait(0.1)
		-- Try again after waiting
		pcall(function()
			backpackTool = self.Player:WaitForChild("Backpack"):FindFirstChild("Tool")
			if not backpackTool then
				local character = self.Player.Character
				if character then
					backpackTool = character:FindFirstChild("Tool")
					if backpackTool and backpackTool:IsA("Tool") then
						backpackTool.Parent = self.Player:WaitForChild("Backpack")
					end
				end
			end
		end)
	end

	--warn(self.Mod1_Shape_and_Damage)

	-- Handle the tool's Handle (with pcall protection)
	if backpackTool then
		pcall(function()
			if Clone then
				if backpackTool:FindFirstChild("Handle") then
					backpackTool.Handle:Destroy()
				end
				-- Add the new handle
				Clone.Name = "Handle"
				Clone.Parent = backpackTool
			end

		end)
	end



	-- (Re)apply handler (Mod2)
	if self.Mod2_Handler and (not self.RockType or self.RockType == self.Mod2_Handler.Type) then

		self.ThrowDestince = self.Mod2_Handler.NewThrowDestince

		if not self.RockType then
			self.RockType = self.Mod2_Handler.Type
		end

		self:SetSpecialDamage(self.RockType, self.Mod2_Handler)
		self:SetDamageFunction(self.Mod2_Handler.DamageType, self.Mod2_Handler)

		-- If the model (Clone) might have leftover visuals that handlers expect removed:
		if self.Mod1_Shape_and_Damage then
			if Clone then
				for _, child in pairs(Clone:GetChildren()) do
					child:Destroy()
				end
			end
		end

	else
		-- incompatible handler: clear it if mismatched
		if self.Mod2_Handler and self.RockType and self.Mod2_Handler.Type ~= self.RockType then
			SafeAddEvent.Event:Fire(self.Player, self.Mod2_Handler, 1) -- Saves the modifier in the player inventory
			-- Should have event for notification to client must add later
			self.Mod2_Handler = nil
			warn("Rock model type must equal the handler type")
		end

		if not self.Mod2_Handler  then
			self:SetDamageFunction()
		end

	end

	-- Apply buffers (Mod3)
	if self.Mod3_Buffers then
		local function SetOtherModifiers()
			local ThrowDistanceModifier = self.Mod3_Buffers.ThrowDistanceModifier or 0
			local DamageMultiplier = self.Mod3_Buffers.DamageMultiplier or 0

			if ThrowDistanceModifier ~= 0 and self.ThrowDistance then
				self.ThrowDistance *= (1 + ThrowDistanceModifier)
			end

			if DamageMultiplier ~= 0 and self.BaseDamage then
				self.BaseDamage *= (1 + DamageMultiplier)
			end
		end

		if self.Mod3_Buffers.EffectType == "Fire" then
			local SpacileDamage = self.Mod3_Buffers.FireModifier
			self.FireDamage *= (1 + SpacileDamage)
			SetOtherModifiers()
		elseif self.Mod3_Buffers.EffectType == "Ice" then
			local SpacileDamage = self.Mod3_Buffers.IceModifier
			self.FireDamage *= (1 + SpacileDamage)
			SetOtherModifiers()
		elseif self.Mod3_Buffers.EffectType == "DarkMagic" then
			local SpacileDamage = self.Mod3_Buffers.DarkMagicModifier
			self.FireDamage *= (1 + SpacileDamage)
			SetOtherModifiers()
		elseif self.Mod3_Buffers.EffectType == "Luminite" then
			local SpacileDamage = self.Mod3_Buffers.LuminiteModifier
			self.FireDamage *= (1 + SpacileDamage)
			SetOtherModifiers()
		end
	end

	-- Update attributes on player
	if self.Player then
		self.Player:SetAttribute("RockCoolDown", self.CoolDown)
		self.Player:SetAttribute("ThrowDestince", self.ThrowDestince)
	end

	--warn(self.Mod2_Handler, self.RockType)
	self:SetRockStats() -- sets the new rock stats attributes
	self:SetModifierData() -- sets the new rock modifiers stats attributes
	SetPlayerRockEvent:FireAllClients(self.Player, {Name = self.Mod2_Handler and self.Mod2_Handler.Name , Type = self.RockType, Rock = self.Mod1_Shape_and_Damage and self.Mod1_Shape_and_Damage.Name} or nil)
	warn(self)
end


-- function to get the special damage as diffrent class have diffrent damage types
function StatsRockClass:SetSpecialDamage(RockType:string, Class:Registry.SingleRockModHandlers)
	if RockType == "Fire" then
		self.FireDamage = Class.FireDamage
	elseif RockType == "Ice" then
		self.IceDamage = Class.IceDamage
	elseif RockType == "DarkMagic" then
		self.DarkMagicDamage = Class.DarkMagicDamage
	elseif RockType == "Luminite" then
		self.LuminiteDamage = Class.LuminiteDamage
	end
end

function StatsRockClass:GetDamageType()
	if self.RockType == "Fire" then
		return self.FireDamage
	elseif self.RockType == "Ice" then
		return self.IceDamage 
	elseif self.RockType == "DarkMagic" then
		return self.DarkMagicDamage 
	elseif self.RockType == "Luminite" then
		return self.LuminiteDamage 
	end
end

function StatsRockClass:SetDamageFunction(DamageType: string?, Class: Registry.SingleRockModHandlers?)
	if DamageType == "Bleed" then
		local bleedDuration = Class.DamageDuration
		local bleedTick = Class.DamageTakenBySecounds
		local damagePerTick = self:GetDamageType()

		local defaultDamageFunction: DamageFunctionType = function(TheHealthClass: HealthClassType)
			TheHealthClass:BloodDeBuffe(bleedDuration, bleedTick, damagePerTick)
		end

		self.DamageFunction = defaultDamageFunction

	elseif DamageType == "Hit&Bleed" then
		local bleedDuration = Class.DamageDuration
		local bleedTick = Class.DamageTakenBySecounds
		local damagePerTick = self:GetDamageType()
		local instantDamage = self.Damage

		local defaultDamageFunction: DamageFunctionType = function(TheHealthClass: HealthClassType)
			TheHealthClass:Deduct(instantDamage)

			task.delay(bleedTick,function()
				TheHealthClass:BloodDeBuffe(bleedDuration, bleedTick, damagePerTick)
			end)
		end

		self.DamageFunction = defaultDamageFunction

	else -- Default Damage Function
		local instantDamage = self.Damage

		local defaultDamageFunction: DamageFunctionType = function(TheHealthClass: HealthClassType)
			TheHealthClass:Deduct(instantDamage)
		end

		self.DamageFunction = defaultDamageFunction
	end
end



function StatsRockClass:SetModifierData()
	-- Wait for character to spawn first (so StarterPack gets copied to Backpack)
	if not self.Player.Character then
		self.Player.CharacterAdded:Wait()
	end

	-- Use Backpack instead of PlayerScripts (server can access this)
	local Backpack = self.Player:WaitForChild("Backpack")
	local ActiveRockModifiers = Backpack:WaitForChild("ActiveRockModifiers")

	-- Handle Model modifier (Mod1_Shape_and_Damage)
	if self.Mod1_Shape_and_Damage ~= nil then
		local Destination = ActiveRockModifiers:WaitForChild("Model")

		-- Set model modifier attributes
		Destination:SetAttribute("Name", self.Mod1_Shape_and_Damage.Name or "")
		Destination:SetAttribute("Type", self.Mod1_Shape_and_Damage.Type or "")
		Destination:SetAttribute("RockDamage", self.Mod1_Shape_and_Damage.RockDamage or 0)

		-- Set any additional model-specific attributes if they exist
		Destination:SetAttribute("Description", self.Mod1_Shape_and_Damage.Description)
		Destination:SetAttribute("Rarity", self.Mod1_Shape_and_Damage.Rarity)
		Destination:SetAttribute("ItemType", self.Mod1_Shape_and_Damage.ItemType or "")

	else
		-- Clear all attributes if no modifier is equipped
		local Destination = ActiveRockModifiers:WaitForChild("Model")
		for attributeName, _ in pairs(Destination:GetAttributes()) do
			Destination:SetAttribute(attributeName, nil)
		end
	end

	-- Handle Handler modifier (Mod2_Handler)
	if self.Mod2_Handler ~= nil then
		local Destination = ActiveRockModifiers:WaitForChild("Handler")

		-- Set handler modifier attributes
		Destination:SetAttribute("Name", self.Mod2_Handler.Name or "")
		Destination:SetAttribute("Type", self.Mod2_Handler.Type or "")
		Destination:SetAttribute("NewThrowDestince", self.Mod2_Handler.NewThrowDestince or 0)
		Destination:SetAttribute("DamageType", self.Mod2_Handler.DamageType or "Hit")

		-- Set damage-specific attributes based on type
		if self.Mod2_Handler.FireDamage then
			Destination:SetAttribute("FireDamage", self.Mod2_Handler.FireDamage)
		end
		if self.Mod2_Handler.IceDamage then
			Destination:SetAttribute("IceDamage", self.Mod2_Handler.IceDamage)
		end
		if self.Mod2_Handler.DarkMagicDamage then
			Destination:SetAttribute("DarkMagicDamage", self.Mod2_Handler.DarkMagicDamage)
		end
		if self.Mod2_Handler.LuminiteDamage then
			Destination:SetAttribute("LuminiteDamage", self.Mod2_Handler.LuminiteDamage)
		end

		-- Set bleed-specific attributes if they exist
		if self.Mod2_Handler.DamageDuration then
			Destination:SetAttribute("DamageDuration", self.Mod2_Handler.DamageDuration)
		end
		if self.Mod2_Handler.DamageTakenBySecounds then
			Destination:SetAttribute("DamageTakenBySecounds", self.Mod2_Handler.DamageTakenBySecounds)
		end

		-- Set any additional handler-specific attributes
		Destination:SetAttribute("Description", self.Mod2_Handler.Description)
		Destination:SetAttribute("Rarity", self.Mod2_Handler.Rarity)
		Destination:SetAttribute("ItemType", self.Mod2_Handler.ItemType or "")
	else
		-- Clear all attributes if no handler is equipped
		local Destination = ActiveRockModifiers:WaitForChild("Handler")
		for attributeName, _ in pairs(Destination:GetAttributes()) do
			Destination:SetAttribute(attributeName, nil)
		end
	end

	-- Handle Buffer modifier (Mod3_Buffers)
	if self.Mod3_Buffers ~= nil then
		local Destination = ActiveRockModifiers:WaitForChild("Buffer")

		-- Set buffer modifier attributes
		Destination:SetAttribute("Name", self.Mod3_Buffers.Name or "")
		Destination:SetAttribute("EffectType", self.Mod3_Buffers.EffectType or "")
		Destination:SetAttribute("ThrowDistanceModifier", self.Mod3_Buffers.ThrowDistanceModifier or 0)
		Destination:SetAttribute("DamageMultiplier", self.Mod3_Buffers.DamageMultiplier or 0)

		-- Set effect-specific modifiers
		if self.Mod3_Buffers.FireModifier then
			Destination:SetAttribute("FireModifier", self.Mod3_Buffers.FireModifier)
		end
		if self.Mod3_Buffers.IceModifier then
			Destination:SetAttribute("IceModifier", self.Mod3_Buffers.IceModifier)
		end
		if self.Mod3_Buffers.DarkMagicModifier then
			Destination:SetAttribute("DarkMagicModifier", self.Mod3_Buffers.DarkMagicModifier)
		end
		if self.Mod3_Buffers.LuminiteModifier then
			Destination:SetAttribute("LuminiteModifier", self.Mod3_Buffers.LuminiteModifier)
		end

		-- Set any additional buffer-specific attributes
		Destination:SetAttribute("Description", self.Mod3_Buffers.Description)
		Destination:SetAttribute("Rarity", self.Mod3_Buffers.Rarity)
		Destination:SetAttribute("ItemType", self.Mod3_Buffers.ItemType or "")
	else
		-- Clear all attributes if no buffer is equipped
		local Destination = ActiveRockModifiers:WaitForChild("Buffer")
		for attributeName, _ in pairs(Destination:GetAttributes()) do
			Destination:SetAttribute(attributeName, nil)
		end
	end
end

function StatsRockClass:SetRockStats()
	-- Wait for character to spawn first (so StarterPack gets copied to Backpack)
	if not self.Player.Character then
		self.Player.CharacterAdded:Wait()
	end

	-- Use Backpack instead of PlayerScripts
	local Backpack = self.Player:WaitForChild("Backpack")
	local ActiveRockModifiers = Backpack:WaitForChild("ActiveRockModifiers")

	-- Set core rock statistics as attributes
	ActiveRockModifiers:SetAttribute("RockType", self.RockType or "")
	ActiveRockModifiers:SetAttribute("ThrowDestince", self.ThrowDestince or 80)
	ActiveRockModifiers:SetAttribute("CoolDown", self.CoolDown or 1)
	ActiveRockModifiers:SetAttribute("Damage", self.Damage or 20)
	ActiveRockModifiers:SetAttribute("FireDamage", self.FireDamage or 0)
	ActiveRockModifiers:SetAttribute("IceDamage", self.IceDamage or 0)
	ActiveRockModifiers:SetAttribute("DarkMagicDamage", self.DarkMagicDamage or 0)
	ActiveRockModifiers:SetAttribute("LuminiteDamage", self.LuminiteDamage or 0)
end




return StatsRockClass
