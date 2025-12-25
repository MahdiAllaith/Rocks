local PlayerService = {}

local Players = game.Players
local Handler = require(script["PlayersHandler-ChiledService"])

function PlayerService.Init()
	-- Handle player join
	Players.PlayerAdded:Connect(function(player)
		-- Get fucntion to return table data
		-- local playerData = faterh(player)
		local FetchedData = "mahdi"
		
		
		Handler:newPlayer(player, FetchedData)
	end)

	-- Handle player leave
	Players.PlayerRemoving:Connect(function(player)
		
		Handler.removePlayer(player)
		
		-- and should call update function
	end)
	
	
	-- Handle Auto update
	
	
	return true
end

function PlayerService.getPlayerHandler()
	return Handler
end

return PlayerService
