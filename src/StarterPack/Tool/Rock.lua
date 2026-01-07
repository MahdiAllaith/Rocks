local ModifierHandler = require(game.ReplicatedStorage.Modifiers.ModifierHandler)
local RockModifiers = game.ReplicatedStorage.Events.RockHandler.RockRemoteFunction
local ResetRockEvent = game.ReplicatedStorage.Events.RockHandler.ResetRock_Event

local tool = script.Parent
local Rock = {}

local currentHandler

function Rock.Init()
	wait(1)
	local PlayerModifiers = RockModifiers:InvokeServer()
	warn(PlayerModifiers)
	currentHandler = ModifierHandler.GetRock(PlayerModifiers, tool, tool:WaitForChild("Handle"), "Player")
end

ResetRockEvent.OnClientEvent:Connect(function(newMods)
	warn(newMods)
	currentHandler = ModifierHandler.GetRock(newMods, tool, tool:WaitForChild("Handle", 5), "Player")
end)

return Rock
