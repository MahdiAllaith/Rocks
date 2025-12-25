--@author: 
--@date: 
--[[@description:
	
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)

-----------------------------
-- DEPENDENCIES --
-----------------------------
local SetIntractionUI_Event = ReplicatedStorage.Events.UI.Client_SetIntractionUI

-----------------------------
-- TYPES --
-----------------------------


-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

local PromptSignals = {} -- Stores each NPC's re-enable signal
Module.PromptSignals = PromptSignals  -- make it public

-- CONSTANTS --
local LOCAL_PLAYER = game.Players.LocalPlayer
local NPCFolder = workspace:WaitForChild("NPC's")
local IntractionsDataFolder = ReplicatedStorage:WaitForChild("IntractionsData")

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function addPromptToNPC(npc: Model)
	local promptParent = npc:WaitForChild("HumanoidRootPart")

	if not promptParent then
		warn("No BasePart found inside NPC:", npc.Name)
		return
	end

	-- Create or reuse proximity prompt
	local prompt = promptParent:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Interact"
		prompt.ObjectText = npc.Name
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 12
		prompt.Parent = promptParent
	end

	-- Create the re-enable signal for this NPC
	local reEnablePromptSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	PromptSignals[npc.Name] = reEnablePromptSignal

	-- When UI tells us to re-enable this NPC's prompt
	reEnablePromptSignal:Connect(function()
		prompt.Enabled = true
	end)

	-- Trigger bindable event
	prompt.Triggered:Connect(function()
		prompt.Enabled = false
		
		-- Load interaction data
		local dataModule = IntractionsDataFolder:FindFirstChild(npc.Name)
		if not dataModule then
			warn("No Interaction module found for:", npc.Name)
			return
		end

		local dataTable = require(dataModule)
		SetIntractionUI_Event:Fire(dataTable, npc.Name)
	end)
end

for _, npc in ipairs(NPCFolder:GetChildren()) do
	if npc:IsA("Model") then
		addPromptToNPC(npc)
	end
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------



return Module
