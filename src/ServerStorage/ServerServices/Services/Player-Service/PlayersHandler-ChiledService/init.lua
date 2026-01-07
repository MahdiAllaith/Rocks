local ServiceHandler = {}

local InitializerModule = require(script["Initializer-Service"])
local ClassesTypes = require(script["ClassesType-Enum"])


local ServerCurrentplayer: {[Player] : ClassesTypes.PlayerRecord} = {}

function ServiceHandler:newPlayer(player: Player, playerData)
	if player then
		if playerData then
			-- initialize player classes and return
			local InitializedClasses = InitializerModule.InitializePlayer(player, playerData)
			-- Add player to table
			
			ServerCurrentplayer[player] = {
				Classes = InitializedClasses,
				PlayerData = playerData
			}
			
			-- must be done and not in class becasue set function requier other classes and can not requier them as it will be reqursive reqier error.
			local playerClasses : ClassesTypes.ClassMap = self.getCredentails(player)
			playerClasses.CharacterKitsClass:SetKits(playerClasses.HealthClass, playerClasses.StaminaClass, playerClasses.AbilitiesClass)
			
		else
			warn("Player Data is nil")
		end
	else
		warn("Player Not Found")
	end
end

function ServiceHandler.removePlayer(player: Player)
	if ServerCurrentplayer[player] ~= nil  then
		ServerCurrentplayer[player] = nil
		warn(player.Name .. " left the game")
	else
		warn("Player Not Initialized")
	end
end

function ServiceHandler.getCredentails(player:Player) : ClassesTypes.ClassMap
	if player then
		local PlayerData = ServerCurrentplayer[player]
		if PlayerData then
			return PlayerData.Classes
		else
			warn("No data found for player:", player.Name)
		end
	else
		warn("Player is nil")
	end
end

-- Old code its shit, i dont do it like this any more but could and it will be faster.

function ServiceHandler.getAbilities(player:Player) :any
	if player then
		local PlayerData = ServerCurrentplayer[player]
		if PlayerData then
			return PlayerData.Classes.AbilitiesClass:GetAbilities()
		else
			warn("No Class found for player:", player.Name)
		end
	else
		warn("Player is nil")
	end
end

--local function getInventory(player:Player) : ClassesTypes.ClassMap?
--	if player then
--		local PlayerData = ServerCurrentplayer[player]
--		if PlayerData then
--			return PlayerData.Classes
--		else
--			warn("No data found for player:", player.Name)
--		end
--	else
--		warn("Player is nil")
--	end
--end

--local GetAbilitiesEvent = game.ReplicatedStorage.Services["Motion-Service"]["GetAbilities-Event"]

--GetAbilitiesEvent.OnServerInvoke = function(player)
--	return getAbilities(player)
--end

return ServiceHandler
