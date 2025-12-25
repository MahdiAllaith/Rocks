--local CLIENTS = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local Game = require(ReplicatedStorage.Utilities.FunctionUtils._game)


local LocalPlayer = game.Players.LocalPlayer 

local function GetsPlayerRock(RockName: string, RockType: string)
	local ModelsTypesFolder

	warn(RockName .. RockType)

	if RockType == "Fire" then
		ModelsTypesFolder = game.ReplicatedStorage.Modifiers.Rocks_Models.Fire
	elseif RockType == "Luminite" then
		ModelsTypesFolder = game.ReplicatedStorage.Modifiers.Rocks_Models.Luminite
	elseif RockType == "Ice" then
		ModelsTypesFolder = game.ReplicatedStorage.Modifiers.Rocks_Models.Ice
	elseif RockType == "DarkMagic" then
		ModelsTypesFolder = game.ReplicatedStorage.Modifiers.Rocks_Models.DarkMagic
	end

	local module = ModelsTypesFolder:FindFirstChild(RockName):Clone()
	if module then
		warn(module.Name)
		return module
	else
		warn("not foud clone")
		return nil
	end

end

local Connection

function CLIENTS.Init(player :Player ,playerModifiers)
	local PlayerName = script.Name
	local FindPlayer = game.Players:FindFirstChild(PlayerName)
	local SimFunction
	local RockModel

	local MentForHandler = player

	local initiateHandler = function(playerModifiers)
		warn(playerModifiers)
		if FindPlayer then
			if playerModifiers then
				if playerModifiers.Rock == nil then
					RockModel = game.ReplicatedStorage.Modifiers.Rocks_Models.Default.DefaultRock:Clone()
				else
					warn(playerModifiers.Rock, playerModifiers.Type)
					RockModel = GetsPlayerRock(playerModifiers.Rock, playerModifiers.Type)
				end
			end

			SimFunction = ModifierHandler.GetRock(playerModifiers, nil, RockModel, "Clients")
			warn(SimFunction)
		else
			warn("Player was not found or left the game:", PlayerName)
			return
		end

		Connection = CLIENTSEvent.OnClientEvent:Connect(function(originPlayer, startCFrame, endCFrame)
			if originPlayer == LocalPlayer then return end
			if MentForHandler == originPlayer then
				warn(originPlayer, startCFrame, endCFrame,RockModel)
				-- a throttle to prevent multiple calls per frame
				Game.throttleDefer(originPlayer, function()
					SimFunction(nil, RockModel, "Clients")(originPlayer, startCFrame, endCFrame, RockModel)
				end)

			end
		end)
	end

	if playerModifiers then
		initiateHandler(playerModifiers)
	else
		--recall the player modifier for checking if nil
		local PlayerModifiers = RockModifiers:InvokeServer(FindPlayer)

		warn(PlayerModifiers)

		initiateHandler(PlayerModifiers)
	end



end

function CLIENTS.DestroyConnection()
	Connection:Disconnect()
end

return CLIENTS