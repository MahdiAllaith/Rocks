--strict
--@author: 
--@date: 
--[[@description:
	A Service hybrid handler for all client input manager for (UI, Motion, Interaction) services.
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Player_Service = require(ServerStorage.ServerServices.Services["Player-Service"])
local ReSpawnService = require(ServerStorage.ServerServices.Services["ReSpawn&Zone-Service"])

-----------------------------
-- DEPENDENCIES --
-----------------------------
local StartGrandChallageEvent = ReplicatedStorage.Events.Obby.StartGrandChallenge
local NotificationEvent = ReplicatedStorage.Events.Player.Notification
local GainNotificationEvent = ReplicatedStorage.Events.Player.GainNotification

-----------------------------
-- Events --
-----------------------------
local IsPlayerInObby = ServerStorage.ServerBindableEvents.IsPlayerInObby
local PlayerLostAttempt = ServerStorage.ServerBindableEvents.PlayerLostAttempt
local PlayerReachedNewLevel = ServerStorage.ServerBindableEvents.PlayerReachedNewLevel

local OnObbyFail = ReplicatedStorage.Events.Obby.OnObbyFail

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

local ObbyPlayers = {}
-- CONSTANTS --
local DEFAULT_ATTEMPTS = 4

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function Module.IsPlayerInObby(player: Player)
	return ObbyPlayers[player] ~= nil
end

function Module.PlayerRechedNextLevel(player: Player)
	if not ObbyPlayers[player] then return end
	ObbyPlayers[player].ObbyLevel += 1
end


function Module.PlayerLostAttempt(player: Player)
	local data = ObbyPlayers[player]
	if not data then return false end

	data.AttemptsLeft -= 1

	if data.AttemptsLeft < 0 then
		ObbyPlayers[player] = nil
		
		return false
	end
	
	
	return true
end


-----------------------------
-- MAIN --
-----------------------------
function Module.Init()
	IsPlayerInObby.OnInvoke = function(player: Player)
		return Module.IsPlayerInObby(player)
	end
		

	PlayerLostAttempt.OnInvoke = function(player: Player)
		local hasAttempts = Module.PlayerLostAttempt(player)

		-- Only notify if player still has attempts left
		if hasAttempts then
			local attemptsLeft = ObbyPlayers[player] and ObbyPlayers[player].AttemptsLeft or 0
			NotificationEvent:FireClient(player, "You only have " .. attemptsLeft .. " attempts left")
		end

		return hasAttempts
	end

	PlayerReachedNewLevel.Event:Connect(function(player: Player)
		Module.PlayerRechedNextLevel(player)
		local playerClasses = Player_Service.getPlayerHandler().getCredentails(player)
		
		playerClasses.WalletClass:AddRocks(50)
		playerClasses.LevelClass:AddXp(400)
		
		GainNotificationEvent:FireClient(player, 400,50)
	end)
	
	StartGrandChallageEvent.OnServerEvent:Connect(function(player)
		if not ObbyPlayers[player] then
			ObbyPlayers[player] = {AttemptsLeft = DEFAULT_ATTEMPTS, ObbyLevel = 1, TimeElapsed = 0}
			warn(ObbyPlayers[player])
		end
		
		ReSpawnService.Teleport_To_Obby(player)
		
	end)
	
	
	return true
end

return Module
