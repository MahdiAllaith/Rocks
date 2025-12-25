--local Players = game:GetService("Players")
--local LocalPlayer = Players.LocalPlayer
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local RunService = game:GetService("RunService")

--local setPlayersRockEvent = ReplicatedStorage:WaitForChild("Events").RockHandler.SetPlayersRock_Event 
--local ClientsHandlers = ReplicatedStorage:WaitForChild("Modifiers").ClientsHandlers

---- Folder containing modules
--local ModulesFolder = script.Parent

---- Track loaded modules and player connections
--local loadedModules = {}
--local playerConnections = {}

---- Debounce table for SetPlayersRock per player
--local lastRockEventTime = {}

---- Utility to remove & cleanup a module for a player
--local function removeModuleForPlayer(player)
--	if player == LocalPlayer then return end

--	local moduleToRemove = ModulesFolder:FindFirstChild(player.Name)
--	if moduleToRemove then
--		-- Cleanup instance if needed
--		local moduleInstance = loadedModules[moduleToRemove]
--		if type(moduleInstance) == "table" and typeof(moduleInstance.Cleanup) == "function" then
--			pcall(function()
--				moduleInstance:Cleanup()
--			end)
--		end

--		-- Remove tracking cache
--		loadedModules[moduleToRemove] = nil

--		-- Destroy the module script
--		moduleToRemove:Destroy()
--		print("Removed existing module for:", player.Name)
--	end
--end

---- Function to create module for a player (won't duplicate if exists)
--local function createModuleForPlayer(player)
--	if player == LocalPlayer then return end

--	-- Check if module already exists
--	local existingModule = ModulesFolder:FindFirstChild(player.Name)
--	if existingModule then
--		print("Module already exists for:", player.Name)
--		return
--	end

--	-- Create new module
--	local success, err = pcall(function()
--		local ClientsModule = ClientsHandlers:Clone()
--		ClientsModule.Name = player.Name
--		ClientsModule.Parent = ModulesFolder
--		print("Created module for:", player.Name)
--	end)

--	if not success then
--		warn("Failed to create module for", player.Name, ":", err)
--	end
--end

---- Function to (re)load all modules except for the one with LocalPlayer's name
--local function loadModules()
--	for _, module in pairs(ModulesFolder:GetChildren()) do
--		if module:IsA("ModuleScript") and module.Name ~= LocalPlayer.Name and not loadedModules[module] then
--			local success, result = pcall(function()
--				return require(module)
--			end)

--			if success then
--				loadedModules[module] = result
--				print("Loaded module for:", module.Name)

--				-- Call Init() if it exists
--				if typeof(result) == "table" and typeof(result.Init) == "function" then
--					local initSuccess, initErr = pcall(function()
--						result.Init()
--					end)

--					if not initSuccess then
--						warn("Failed to initialize module for", module.Name, ":", initErr)
--					end
--				end
--			else
--				warn("Failed to require module for", module.Name, ":", result)
--			end
--		end
--	end
--end

---- Function to setup character tracking for a player
--local function setupPlayerTracking(player)
--	if player == LocalPlayer then return end

--	-- Disconnect existing connection if any
--	if playerConnections[player] then
--		playerConnections[player]:Disconnect()
--	end

--	-- Connect to CharacterAdded
--	playerConnections[player] = player.CharacterAdded:Connect(function()
--		print(player.Name, "character added - creating module")
--		createModuleForPlayer(player)

--		-- Small delay then try to load modules
--		task.wait(0.2)
--		loadModules()
--	end)

--	-- If player already has a character, create module immediately
--	if player.Character then
--		createModuleForPlayer(player)
--	end
--end

---- Handle SetPlayersRock event: replace existing module, with debounce
--setPlayersRockEvent.OnClientEvent:Connect(function(player)
--	if player == LocalPlayer then return end

--	local now = tick()
--	local last = lastRockEventTime[player]
--	if last and now - last < 1 then
--		-- debounced, ignore
--		return
--	end
--	lastRockEventTime[player] = now

--	print("SetPlayersRock fired for:", player.Name)

--	-- Remove old module so it gets recreated
--	removeModuleForPlayer(player)
--	setupPlayerTracking(player)

--	-- Give a small grace before loading to let creation propagate
--	task.defer(function()
--		task.wait(0.2)
--		loadModules()
--	end)
--end)

---- Setup tracking for players already in game
--local function setupExistingPlayers()
--	for _, player in pairs(Players:GetPlayers()) do
--		if player ~= LocalPlayer then
--			setupPlayerTracking(player)
--		end
--	end
--end

---- Handle new players joining
--Players.PlayerAdded:Connect(function(player)
--	if player == LocalPlayer then return end

--	print("Player joined:", player.Name)
--	setupPlayerTracking(player)
--end)

---- Handle player leaving
--Players.PlayerRemoving:Connect(function(leavingPlayer)
--	if leavingPlayer == LocalPlayer then return end

--	print("Player leaving:", leavingPlayer.Name)

--	-- Disconnect tracking
--	if playerConnections[leavingPlayer] then
--		playerConnections[leavingPlayer]:Disconnect()
--		playerConnections[leavingPlayer] = nil
--	end

--	-- Clean up module
--	local moduleToRemove = ModulesFolder:FindFirstChild(leavingPlayer.Name)
--	if moduleToRemove then
--		local moduleInstance = loadedModules[moduleToRemove]
--		if type(moduleInstance) == "table" and typeof(moduleInstance.Cleanup) == "function" then
--			pcall(function()
--				moduleInstance:Cleanup()
--			end)
--		end

--		loadedModules[moduleToRemove] = nil
--		moduleToRemove:Destroy()
--		print("Cleaned up module for:", leavingPlayer.Name)
--	end
--end)

---- Handle new modules added manually (backup system)
--ModulesFolder.ChildAdded:Connect(function(child)
--	if child:IsA("ModuleScript") and child.Name ~= LocalPlayer.Name then
--		print("New module detected:", child.Name)
--		task.wait(0.1)
--		loadModules()
--	end
--end)

---- Initial setup
--task.wait(0.5)
--setupExistingPlayers()
--loadModules()

---- Periodic check to ensure all players have modules (backup system)
--local function periodicCheck()
--	for _, player in pairs(Players:GetPlayers()) do
--		if player ~= LocalPlayer and player.Character then
--			local module = ModulesFolder:FindFirstChild(player.Name)
--			if not module then
--				print("Missing module detected for:", player.Name, "- creating...")
--				createModuleForPlayer(player)
--			end
--		end
--	end
--	loadModules()
--end

---- Run periodic check every 5 seconds
--spawn(function()
--	while true do
--		wait(300)
--		periodicCheck()
--	end
--end)


--local Players = game:GetService("Players")
--local LocalPlayer = Players.LocalPlayer
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local setPlayersRockEvent = ReplicatedStorage:WaitForChild("Events").RockHandler.SetPlayersRock_Event 
--local ClientsHandlers = ReplicatedStorage:WaitForChild("Modifiers").ClientsHandlers
--local ModulesFolder = script.Parent

---- Core tracking tables
--local loadedModules = {}
--local playerConnections = {}
--local lastRockEventTime = {}

---- Main function to handle module creation/recreation
--local function handlePlayerModule(player, forceRecreate)
--	if player == LocalPlayer then return end

--	local existingModule = ModulesFolder:FindFirstChild(player.Name)
--	local moduleInstance = existingModule and loadedModules[existingModule]

--	-- Check if we need to create/recreate the module
--	local shouldCreate = not existingModule or not moduleInstance or forceRecreate

--	if not shouldCreate then
--		print("Module already exists and loaded for:", player.Name)
--		return
--	end

--	-- Clean up existing module if it exists AND is loaded
--	if existingModule and moduleInstance then
--		if type(moduleInstance) == "table" then
--			-- Call Cleanup function if it exists
--			if typeof(moduleInstance.Cleanup) == "function" then
--				pcall(moduleInstance.Cleanup, moduleInstance)
--			end
--			-- Call DestroyConnection function if it exists
--			if typeof(moduleInstance.DestroyConnection) == "function" then
--				pcall(moduleInstance.DestroyConnection, moduleInstance)
--			end
--		end
--		loadedModules[existingModule] = nil
--		existingModule:Destroy()
--		print("Removed existing module for:", player.Name)
--	elseif existingModule then
--		-- Module exists but not loaded, just destroy it
--		loadedModules[existingModule] = nil
--		existingModule:Destroy()
--		print("Removed unloaded module for:", player.Name)
--	end

--	-- Create new module
--	local success, err = pcall(function()
--		local newModule = ClientsHandlers:Clone()
--		newModule.Name = player.Name
--		newModule.Parent = ModulesFolder

--		-- Load the module immediately
--		local moduleResult = require(newModule)
--		loadedModules[newModule] = moduleResult

--		-- Initialize if Init function exists
--		if type(moduleResult) == "table" and typeof(moduleResult.Init) == "function" then
--			moduleResult.Init()
--		end

--		print("Created and loaded module for:", player.Name)
--	end)

--	if not success then
--		warn("Failed to create module for", player.Name, ":", err)
--	end
--end

---- Setup player tracking and module creation
--local function setupPlayer(player)
--	if player == LocalPlayer then return end

--	-- Disconnect existing connection
--	if playerConnections[player] then
--		playerConnections[player]:Disconnect()
--	end

--	-- Connect to character events
--	playerConnections[player] = player.CharacterAdded:Connect(function()
--		print(player.Name, "character added")
--		task.wait(0.1) -- Small delay for stability
--		handlePlayerModule(player, false)
--	end)

--	-- Handle existing character
--	if player.Character then
--		handlePlayerModule(player, false)
--	end
--end

---- Cleanup when player leaves
--local function cleanupPlayer(player)
--	if player == LocalPlayer then return end

--	-- Disconnect connections
--	if playerConnections[player] then
--		playerConnections[player]:Disconnect()
--		playerConnections[player] = nil
--	end

--	-- Clean up module
--	local module = ModulesFolder:FindFirstChild(player.Name)
--	if module then
--		local moduleInstance = loadedModules[module]
--		if moduleInstance and type(moduleInstance) == "table" and typeof(moduleInstance.Cleanup) == "function" then
--			pcall(moduleInstance.Cleanup, moduleInstance)
--		end
--		loadedModules[module] = nil
--		module:Destroy()
--		print("Cleaned up module for:", player.Name)
--	end

--	-- Clear debounce
--	lastRockEventTime[player] = nil
--end

---- Event Connections
--setPlayersRockEvent.OnClientEvent:Connect(function(player)
--	if player == LocalPlayer then return end

--	-- Debounce check
--	local now = tick()
--	if lastRockEventTime[player] and now - lastRockEventTime[player] < 1 then
--		return
--	end
--	lastRockEventTime[player] = now

--	print("SetPlayersRock fired for:", player.Name)

--	-- Force recreate the module
--	handlePlayerModule(player, true)
--end)

--Players.PlayerAdded:Connect(function(player)
--	print("Player joined:", player.Name)
--	setupPlayer(player)
--end)

--Players.PlayerRemoving:Connect(cleanupPlayer)

---- Handle manually added modules (backup)
--ModulesFolder.ChildAdded:Connect(function(child)
--	if child:IsA("ModuleScript") and child.Name ~= LocalPlayer.Name then
--		local player = Players:FindFirstChild(child.Name)
--		if player then
--			print("Manual module detected for:", child.Name)
--			task.wait(0.1)
--			handlePlayerModule(player, false)
--		end
--	end
--end)

---- Initialize existing players
--task.wait(0.5)
--for _, player in pairs(Players:GetPlayers()) do
--	setupPlayer(player)
--end

---- Periodic maintenance (reduced frequency)
--task.spawn(function()
--	while true do
--		task.wait(300) -- 5 minutes

--		for _, player in pairs(Players:GetPlayers()) do
--			if player ~= LocalPlayer and player.Character then
--				local module = ModulesFolder:FindFirstChild(player.Name)
--				local isLoaded = module and loadedModules[module]

--				if not isLoaded then
--					print("Missing/unloaded module detected for:", player.Name)
--					handlePlayerModule(player, false)
--				end
--			end
--		end
--	end
--end)

-- Services and References
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local setPlayersRockEvent = ReplicatedStorage:WaitForChild("Events").RockHandler.SetPlayersRock_Event 
local ClientsHandlers = ReplicatedStorage:WaitForChild("Modifiers").ClientsHandlers
local ModulesFolder = script.Parent

-- State
local loadedModules = {}
local initializedModules = {}
local playerConnections = {}
local lastRockEventTime = {}
local playersWaitingForRock = {} -- Track players who joined but haven't fired rock event yet

-- Function 1: Create module for player (without initializing handler)
local function createPlayerModule(player)
	if player == LocalPlayer then return end

	local existingModule = ModulesFolder:FindFirstChild(player.Name)
	if existingModule then
		print("Module already exists for:", player.Name)
		return true
	end

	local success, err = pcall(function()
		local newModule = ClientsHandlers:Clone()
		newModule.Name = player.Name
		newModule.Parent = ModulesFolder

		local moduleResult = require(newModule)
		loadedModules[newModule] = moduleResult

		print("Created module for:", player.Name)
	end)

	if not success then
		warn("Failed to create module for", player.Name, ":", err)
		return false
	end

	return true
end

-- Function 2: Handle rock event - initialize handler for existing or new players
local function handleRockEvent(player, playerModifiers)
	if player == LocalPlayer then return end

	-- Debounce check
	local now = tick()
	if lastRockEventTime[player] and now - lastRockEventTime[player] < 1 then
		return
	end
	lastRockEventTime[player] = now

	print("SetPlayersRock fired for:", player.Name)
	if playerModifiers then
		print("Modifiers received:", playerModifiers.Name, playerModifiers.Type, playerModifiers.Rock)
	end

	-- Check if this is a new player firing rock event for everyone
	local isNewPlayer = playersWaitingForRock[player]
	if isNewPlayer then
		print("New player", player.Name, "fired rock event - initializing handler for them")
		playersWaitingForRock[player] = nil -- Remove from waiting list
	else
		print("Existing player", player.Name, "fired rock event - reinitializing handler")
	end

	-- Wait for player module to exist and be loaded
	local playerModule = nil
	local moduleInstance = nil
	local timeout = 0

	while timeout < 50 do -- 5 second timeout
		playerModule = ModulesFolder:FindFirstChild(player.Name)
		if playerModule then
			moduleInstance = loadedModules[playerModule]
			if moduleInstance then
				break
			end
		end
		task.wait(0.1)
		timeout = timeout + 1
	end

	if not playerModule or not moduleInstance then
		warn("Failed to find loaded module for:", player.Name, "- recreating")
		-- Try to recreate the module
		createPlayerModule(player)
		task.wait(0.2)
		playerModule = ModulesFolder:FindFirstChild(player.Name)
		moduleInstance = playerModule and loadedModules[playerModule]
	end

	if not playerModule or not moduleInstance then
		warn("Still failed to find module for:", player.Name)
		return
	end

	-- Cleanup previous initialization if this is a re-initialization
	if initializedModules[playerModule] and type(moduleInstance) == "table" then
		if typeof(moduleInstance.Cleanup) == "function" then
			pcall(moduleInstance.Cleanup, moduleInstance)
		end
		if typeof(moduleInstance.DestroyConnection) == "function" then
			pcall(moduleInstance.DestroyConnection, moduleInstance)
		end
		initializedModules[playerModule] = nil
		print("Cleaned up previous initialization for:", player.Name)
	end

	-- Initialize handler with playerModifiers data
	if type(moduleInstance) == "table" and typeof(moduleInstance.Init) == "function" then
		local success, err = pcall(moduleInstance.Init, player ,playerModifiers)
		if success then
			initializedModules[playerModule] = true -- Mark as initialized
			print("Initialized handler for:", player.Name, "with modifiers")
		else
			warn("Failed to initialize handler for", player.Name, ":", err)
		end
	else
		print("No Init function found for:", player.Name)
	end
end

-- Function 3: Setup player tracking and create module immediately
local function setupPlayer(player)
	if player == LocalPlayer then return end

	-- Disconnect existing connection
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
	end

	-- Setup character tracking
	playerConnections[player] = player.CharacterAdded:Connect(function()
		print(player.Name, "character added")
		task.wait(0.1)
		createPlayerModule(player)

		-- Auto-initialize handler after module creation for character spawn
		task.spawn(function()
			task.wait(0.2) -- Give time for module to load
			print("Auto-firing rock event for character spawn:", player.Name)
			handleRockEvent(player, nil) -- No modifiers for auto-spawn
		end)
	end)

	-- Create module immediately if player has character
	if player.Character then
		task.wait(0.1)
		createPlayerModule(player)

		-- Auto-initialize handler for existing character
		task.spawn(function()
			task.wait(0.2)
			print("Auto-firing rock event for existing character:", player.Name)
			handleRockEvent(player, nil) -- No modifiers for existing character
		end)
	end

	-- Mark player as waiting for rock event (for new joiners)
	playersWaitingForRock[player] = true

	print("Setup player:", player.Name, "- waiting for rock event")
end

-- Function 4: Cleanup player completely
local function cleanupPlayer(player)
	if player == LocalPlayer then return end

	-- Disconnect connections
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end

	-- Remove module and cleanup if initialized
	local existingModule = ModulesFolder:FindFirstChild(player.Name)
	if existingModule then
		local moduleInstance = loadedModules[existingModule]
		-- Only call cleanup functions if module was initialized
		if moduleInstance and type(moduleInstance) == "table" and initializedModules[existingModule] then
			if typeof(moduleInstance.Cleanup) == "function" then
				pcall(moduleInstance.Cleanup, moduleInstance)
			end
			if typeof(moduleInstance.DestroyConnection) == "function" then
				pcall(moduleInstance.DestroyConnection, moduleInstance)
			end
		end
		loadedModules[existingModule] = nil
		initializedModules[existingModule] = nil
		existingModule:Destroy()
		print("Removed module for:", player.Name)
	end

	-- Clear tracking
	playersWaitingForRock[player] = nil
	lastRockEventTime[player] = nil
	print("Cleaned up player:", player.Name)
end

-- Event Connections - Now properly handles two parameters
setPlayersRockEvent.OnClientEvent:Connect(function(player, playerModifiers)
	handleRockEvent(player, playerModifiers)
end)

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- Initialize existing players when script starts
task.wait(0.5)
for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		setupPlayer(player)
		-- For existing players, simulate rock event after a short delay to initialize handlers
		task.spawn(function()
			task.wait(1) -- Give time for module creation
			print("Auto-firing rock event for existing player:", player.Name)
			handleRockEvent(player, nil) -- No modifiers for existing players on startup
		end)
	end
end

-- Enhanced maintenance - ensure all players have modules and check for missing handlers
task.spawn(function()
	while true do
		task.wait(30) -- Check every 30 seconds

		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local module = ModulesFolder:FindFirstChild(player.Name)
				local isLoaded = module and loadedModules[module]
				local isInitialized = module and initializedModules[module]

				-- Recreate module if missing
				if not module or not isLoaded then
					print("Missing/unloaded module detected for:", player.Name, "- recreating")
					createPlayerModule(player)
				end

				-- Log status for debugging
				if module and isLoaded and not isInitialized and not playersWaitingForRock[player] then
					print("Player", player.Name, "has module but no handler - may need rock event")
				end
			end
		end
	end
end)

--print("Hybrid Player Module Manager initialized")
--print("- Modules created on player join")
--print("- Handlers initialized on rock events with modifier data")
--print("- Supports both new players joining and existing players")