--local CLIENTS = {}

--local ModifierHandler = require(game.ReplicatedStorage.Modifiers.ModifierHandler)
--local RockModifiers = game.ReplicatedStorage.Events.RockHandler.RockRemoteFunction
--local CLIENTSEvent = game.ReplicatedStorage.Events.Action.CLIENTS

--local LoaclPlayer = game.Players.LocalPlayer 

--function CLIENTS.Init()
--	local PlayerName = script.Name
--	local FindPlayer = game.Players:FindFirstChild(PlayerName)
--	local playerRock

--	if FindPlayer then
--		local PlayerModifiers = RockModifiers:InvokeServer(FindPlayer)
--		if PlayerModifiers then
--			if PlayerModifiers.mod1 == nil then
--				playerRock = game.ReplicatedStorage.Modifiers["Rocks Models"].Default.Handle:Clone()
--			end

--		end

--		local SimFunction = ModifierHandler.BuildRock(PlayerModifiers, nil, playerRock , "Clients")
--	else
--		warn("Player was not found or left the game:", PlayerName)
--		return
--	end

--	CLIENTSEvent.OnClientEvent:Connect(function(originPlayer, startCFrame, endCFrame)
--		if originPlayer == LoaclPlayer then return end  -- Use consistent player reference
--		SimFunction(originPlayer, startCFrame, endCFrame, "Clients")
--	end)
--end



--return CLIENTS
local CLIENTS = {}

local ModifierHandler = require(game.ReplicatedStorage.Modifiers.ModifierHandler)
local RockModifiers = game.ReplicatedStorage.Events.RockHandler.RockRemoteFunction
local CLIENTSEvent = game.ReplicatedStorage.Events.Action.CLIENTS

local LocalPlayer = game.Players.LocalPlayer 

function CLIENTS.Init()
	local PlayerName = script.Name
	local FindPlayer = game.Players:FindFirstChild(PlayerName)
	local SimFunction
	local RockModel
	
	
	if FindPlayer then
		local PlayerModifiers = RockModifiers:InvokeServer(FindPlayer)
		
		
		if PlayerModifiers then
			if PlayerModifiers.Mod1 == nil then
				RockModel = game.ReplicatedStorage.Modifiers["Rocks Models"].Default.Handle:Clone()
			end
		end

		SimFunction = ModifierHandler.BuildRock(PlayerModifiers, nil, RockModel, "Clients")
	else
		warn("Player was not found or left the game:", PlayerName)
		return
	end
	
	CLIENTSEvent.OnClientEvent:Connect(function(originPlayer, startCFrame, endCFrame)
		warn("client")
		if originPlayer == LocalPlayer then return end
		SimFunction(nil, RockModel, "Clients")
	end)
	
end

return CLIENTS