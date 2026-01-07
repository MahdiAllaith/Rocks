local PlayerService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Handler = require(script["PlayersHandler-ChiledService"])
local ProfileStore = require(script.ProfileStore)
local DataTemplate = require(script.DataTemplate)

-- =========================
-- PROFILE STORE
-- =========================

local function getStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local PlayerStore = ProfileStore.New(getStoreName(), DataTemplate)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

-- =========================
-- SAVE FUNCTION
-- =========================
local function SafeValue(obj)
	-- Converts values to something safe for DataStore
	if typeof(obj) == "Instance" then
		return obj.Name -- save only the name of the instance
	elseif type(obj) == "table" then
		local t = {}
		for k, v in pairs(obj) do
			t[k] = SafeValue(v) -- recursively safe
		end
		return t
	elseif type(obj) == "number" or type(obj) == "string" or type(obj) == "boolean" then
		return obj
	else
		return nil -- functions, userdata, threads cannot be saved
	end
end

local function SafeInventory(inventory)
	-- Converts inventory to safe format without ItemClass
	local safeInventory = {}
	for i, item in ipairs(inventory) do
		safeInventory[i] = {
			Name = item.Name,
			Amount = item.Amount,
			ItemType = item.ItemType
			-- ItemClass is intentionally excluded
		}
	end
	return safeInventory
end

local function CollectAndSave(player: Player)
	local profile = Profiles[player]
	if not profile then return end

	-- Get runtime handler
	local handler = PlayerService.getPlayerHandler()
	if not handler then return end

	local classes = handler.getCredentails(player)
	if not classes then return end

	local data = profile.Data

	-- =========================
	-- WALLET
	-- =========================
	warn("ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss")
	warn(classes)
	data.Wallet.RocksAmount = classes.WalletClass.RocksAmount
	data.Wallet.LuminiteAmount = classes.WalletClass.LuminiteAmount

	-- =========================
	-- LEVEL
	-- =========================
	data.Level.LevelNumber = classes.LevelClass.LevelNumber
	data.Level.CurrentXpAmount = classes.LevelClass.currentXpAmount
	data.Level.DoubleXp = classes.LevelClass.DoubleXp

	-- =========================
	-- INVENTORY
	-- =========================
	data.Inventory.Items = SafeInventory(classes.InventoryClass.Inventory)

	-- =========================
	-- CHARACTER KITS
	-- =========================
	data.CharacterKits.Health = classes.CharacterKitsClass.HealthKit1 and classes.CharacterKitsClass.HealthKit1.Name or ""
	data.CharacterKits.Stamina = classes.CharacterKitsClass.StaminaKit2 and classes.CharacterKitsClass.StaminaKit2.Name or ""
	data.CharacterKits.Abilities = classes.CharacterKitsClass.AgilityKit3 and classes.CharacterKitsClass.AgilityKit3.Name or ""

	-- =========================
	-- ROCK STATS
	-- =========================
	data.RockStats.Model = classes.StatsRockClass.Mod1_Shape_and_Damage and classes.StatsRockClass.Mod1_Shape_and_Damage.Name or ""
	data.RockStats.Handler = classes.StatsRockClass.Mod2_Handler and classes.StatsRockClass.Mod2_Handler.Name or ""
	data.RockStats.Buffer = classes.StatsRockClass.Mod3_Buffers and classes.StatsRockClass.Mod3_Buffers.Name or ""

	-- =========================
	-- SAVE
	-- =========================
	profile:Save()
end



local function SavePlayer(player: Player)
	local profile = Profiles[player]
	if profile then
		CollectAndSave(player)
	end
end

-- =========================
-- MAIN
-- =========================
function PlayerService.Init()

	Players.PlayerAdded:Connect(function(player)

		local profile = PlayerStore:StartSessionAsync(
			"Player_" .. player.UserId,
			{
				Cancel = function()
					return player.Parent ~= Players
				end,
			}
		)

		if not profile then
			player:Kick("Profile load failed")
			return
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Profile session ended")
		end)

		if player.Parent ~= Players then
			profile:EndSession()
			return
		end

		Profiles[player] = profile

		-- 🔹 FETCHED DATA → PASS INTO INISILIZATION PROSSES
		Handler:newPlayer(player, profile.Data)
	end)

	Players.PlayerRemoving:Connect(function(player)
		SavePlayer(player)

		local profile = Profiles[player]
		if profile then
			profile:EndSession()
		end

		Handler.removePlayer(player)
	end)

	-- =========================
	-- AUTOSAVE (10 MIN)
	-- =========================

	task.spawn(function()
		while true do
			task.wait(600)

			for player, profile in pairs(Profiles) do
				if profile then
					SavePlayer(player)
				end
			end
		end
	end)

	return true
end

function PlayerService.getPlayerHandler()
	return Handler
end

return PlayerService
