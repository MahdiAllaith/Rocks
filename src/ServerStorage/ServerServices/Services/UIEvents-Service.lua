--strict
--@author: IronBeliever
--@date: 
--[[@description:
	A Service hybrid handler for all client input manager for (UI, Motion, Interaction) services.
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local EquipeItemEvent = ReplicatedStorage.Events.UI.EquipItem
local UnEquipeItemEvent = ReplicatedStorage.Events.UI.UnEquipItem


local Player_Service = require(ServerStorage.ServerServices.Services["Player-Service"])

-----------------------------
-- TYPES --
-----------------------------


-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}


-- CONSTANTS --


-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-----------------------------
-- MAIN --
-----------------------------
function Module.Init()
	-- Handle if equip item event is fired
	EquipeItemEvent.OnServerInvoke = function(player:Player ,ItemName:string , ItemIndex:number)
		-- I added index of item in data table but dont have the functions handle it 
		-- yet, but latter its better and more faster if with index, fix in polish phase

		local PlayerClasses = Player_Service.getPlayerHandler().getCredentails(player)
		local ItemType, ClidType = PlayerClasses.InventoryClass:GetItemTypeByNameAndIndex(ItemName, ItemIndex)
		
		if ItemType == "RockModifire" then
			-- must add a return success message in EquipeRockModifier function to confurm equiped
			-- for know only ?? message
			PlayerClasses.InventoryClass:EquipeRockModifier(PlayerClasses.StatsRockClass,ItemName)
			return "Success www ??"
		elseif ItemType == "Kit" then
			local PassedCalss
			if ClidType == "Health" then
				PassedCalss = PlayerClasses.HealthClass
			elseif ClidType == "Stamina" then
				PassedCalss = PlayerClasses.StaminaClass
			elseif ClidType == "Abilities" then
				PassedCalss = PlayerClasses.AbilitiesClass
			end
			
			PlayerClasses.InventoryClass:EquipeCharacterKit(PlayerClasses.CharacterKitsClass,ItemName,PassedCalss)
			return "Success ??"
		else
			return "Passed item cannot be equiped"
		end
	
	end
	
	UnEquipeItemEvent.OnServerInvoke = function(player:Player ,ItemType:string)
		local PlayerClasses = Player_Service.getPlayerHandler().getCredentails(player)
		if ItemType == "Buffer" or ItemType == "Handler" or ItemType == "Model" then
			PlayerClasses.InventoryClass:UnEquipeRockModifier(PlayerClasses.StatsRockClass, ItemType)
		elseif ItemType == "Health" then
			PlayerClasses.InventoryClass:UnEquipeCharacterKit(PlayerClasses.CharacterKitsClass,ItemType ,PlayerClasses.HealthClass)
		elseif ItemType == "Stamina" then
			PlayerClasses.InventoryClass:UnEquipeCharacterKit(PlayerClasses.CharacterKitsClass,ItemType ,PlayerClasses.StaminaClass)
		elseif ItemType == "Abilities" then
			PlayerClasses.InventoryClass:UnEquipeCharacterKit(PlayerClasses.CharacterKitsClass,ItemType ,PlayerClasses.AbilitiesClass)
		end
		
		return "HA haa ha ha, it works"
	end
	
	return true
end


return Module
