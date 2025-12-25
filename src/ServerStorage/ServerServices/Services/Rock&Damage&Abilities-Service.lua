local DamageService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerService = require(ServerStorage.ServerServices.Services["Player-Service"])


local PVP = ReplicatedStorage.Events.Action.PVP
local PVE = ReplicatedStorage.Events.Action.PVE
local INITIATE = ReplicatedStorage.Events.Action.INITIATE
local CLIENTS = ReplicatedStorage.Events.Action.CLIENTS
local RockModifiersEvent = ReplicatedStorage.Events.RockHandler.RockRemoteFunction

local DisableMovment = ReplicatedStorage.Events.Motion.DisableMovment
local EnableMovment = ReplicatedStorage.Events.Motion.EnableMovment

local handler = require(game.ServerStorage.ServerServices.Services["Player-Service"]).getPlayerHandler()


local PlayersCoolDownCounter = {}

function DamageService.Init()
	local DEBOUNCE = {}
	local pendingHits = {}
	
	local movementDebounce = {}
	
	DisableMovment.OnServerEvent:Connect(function(player: Player)
		-- Prevent multiple triggers within a short window
		if movementDebounce[player] then return end
		movementDebounce[player] = true

		local abilities = PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass
		if abilities then
			abilities:DisableMovement()
		end

		-- Release debounce after a short delay (optional)
		task.delay(0.5, function()
			movementDebounce[player] = nil
		end)
	end)


	EnableMovment.OnServerEvent:Connect(function(player: Player)
		if movementDebounce[player] then return end
		movementDebounce[player] = true

		local abilities = PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass
		if abilities then
			abilities:EnableMovement()
		end

		task.delay(0.5, function()
			movementDebounce[player] = nil
		end)
	end)

	RockModifiersEvent.OnServerInvoke = function(player) 
		local playersCredentails = handler.getCredentails(player)

		warn(playersCredentails)

		if playersCredentails then
			local RockClass = playersCredentails.StatsRockClass

			--warn({Name = RockClass.Mod2_Handler and RockClass.Mod2_Handler.Name , Type = RockClass.RockType, Rock = RockClass.Mod1_Shape_and_Damage and RockClass.Mod1_Shape_and_Damage.Name} )
			return {Name = RockClass.Mod2_Handler and RockClass.Mod2_Handler.Name , Type = RockClass.RockType, Rock = RockClass.Mod1_Shape_and_Damage and RockClass.Mod1_Shape_and_Damage.Name} or nil

			--return {Name = RockClass.Mod2_Handler, Type = RockClass.RockType} or nil
		else
			warn("No class found for player", player)
			return nil
		end
	end

	-- INITIATE handler (unchanged)
	INITIATE.OnServerEvent:Connect(function(player, startCFrame, endCFrame)

		local debounceTime = 0.05
		local now = tick()
		local lastTime = DEBOUNCE[player]
		if lastTime and (now - lastTime) < debounceTime then
			warn(player.Name .. " tried to spam INITIATE too quickly!")
			return
		end
		DEBOUNCE[player] = now
		CLIENTS:FireAllClients(player, startCFrame, endCFrame)
	end)

	-- Generate unique key for hit pair
	local function createHitKey(attacker, victim)
		return attacker.UserId .. "_hits_" .. victim.UserId
	end

	-- Clean up expired pending hits
	local function cleanupExpiredHits()
		local now = tick()
		for key, hitData in pairs(pendingHits) do
			if now - hitData.timestamp > 2.5 then -- 1 second timeout
				pendingHits[key] = nil
				print("⏰ Hit verification expired:", hitData.attacker.Name, "->", hitData.victim.Name)
			end
		end
	end

	-- Process confirmed hit
	local function processHit(attacker, victim)
		print("⚔️ Processing hit:", attacker.Name, "->", victim.Name)

		-- Get player stats
		local attackerStats = handler.getCredentails(attacker)
		local victimStats = handler.getCredentails(victim)

		-- Validate attacker damage
		local AttackerDamageFunction = nil
		if attackerStats and attackerStats.StatsRockClass then
			AttackerDamageFunction = attackerStats.StatsRockClass.DamageFunction
		else
			warn("❌ StatsRockClass not found for attacker:", attacker.Name)
			return false
		end

		-- Validate victim health
		if victimStats and victimStats.HealthClass then
			AttackerDamageFunction(victimStats.HealthClass)
			print("✅ Damage applied to", victim.Name)
			return true
		else
			warn("❌ HealthClass not found for victim:", victim.Name)
			return false
		end
	end

	-- Main PVP handler
	PVP.OnServerEvent:Connect(function(player, hitPlayer, initiaterPlayer)
		local RockCoolDown = player:GetAttribute("RockCoolDown") or 1 -- default cooldown if missing
		local now = tick()

		if not PlayersCoolDownCounter[player] then
			PlayersCoolDownCounter[player] = now
		else
			-- Check cooldown
			local elapsed = now - PlayersCoolDownCounter[player]
			if elapsed < RockCoolDown then
				warn("❌ Cooldown not finished for", player.Name, "(", RockCoolDown - elapsed, "seconds remaining )")
				return
			end
		end

		-- Passed cooldown, update timestamp
		PlayersCoolDownCounter[player] = now

		-- Input validation
		if not hitPlayer or not initiaterPlayer then
			warn("❌ PVP event missing required arguments from", player.Name)
			return
		end

		-- Clean up old hits first
		cleanupExpiredHits()

		-- Determine roles based on who is calling
		local attacker, victim
		if player == initiaterPlayer then
			-- Attacker is confirming the hit
			attacker = initiaterPlayer
			victim = hitPlayer
		elseif player == hitPlayer then
			-- Victim is confirming the hit
			attacker = initiaterPlayer
			victim = hitPlayer
		else
			warn("❌ Invalid PVP call from", player.Name, "- player must be either initiater or hit target")
			return
		end

		local hitKey = createHitKey(attacker, victim)
		local existingHit = pendingHits[hitKey]

		if existingHit then
			-- Both players have confirmed - process the hit
			pendingHits[hitKey] = nil

			-- Verify the confirmation is from the expected player
			if (player == attacker and existingHit.needsAttackerConfirm) or
				(player == victim and existingHit.needsVictimConfirm) then

				print("✅ Hit confirmed by both players:", attacker.Name, "->", victim.Name)
				processHit(attacker, victim)
			else
				warn("❌ Unexpected confirmation from", player.Name, "for hit", hitKey)
			end
		else
			-- First confirmation - store it
			local needsAttackerConfirm = (player ~= attacker)
			local needsVictimConfirm = (player ~= victim)

			pendingHits[hitKey] = {
				attacker = attacker,
				victim = victim,
				timestamp = tick(),
				needsAttackerConfirm = needsAttackerConfirm,
				needsVictimConfirm = needsVictimConfirm
			}

			local confirmedBy = (player == attacker) and "attacker" or "victim"
			print("📝 Hit registered by", confirmedBy .. ":", attacker.Name, "->", victim.Name, "- awaiting other player confirmation")
		end
	end)

	-- PVE handler (placeholder)
	PVE.OnServerEvent:Connect(function(player, NPCName)
		-- TODO: Implement PVE logic
		print("🤖 PVE hit from", player.Name, "to", NPCName)
	end)

	-- Cleanup task to prevent memory leaks
	task.spawn(function()
		while true do
			task.wait(2) -- Clean up every 2 seconds
			cleanupExpiredHits()
		end
	end)

	game.Players.PlayerRemoving:Connect(function(player)
		if PlayersCoolDownCounter[player] then
			PlayersCoolDownCounter[player] = nil
		end
	end)

	return true
end


return DamageService


--PVP.OnServerEvent:Connect(function(player, HitPlayer : Player)
--	if HitPlayer then
--		local PlayerClasses = handler.getCredentails(player)
--		local HitPlayerClasses = handler.getCredentails(HitPlayer)

--		local playerRockDamage = nil

--		if PlayerClasses and PlayerClasses.StatsRockClass then

--			playerRockDamage = PlayerClasses.StatsRockClass.Damage
--		else
--			warn("not found")
--		end


--		if HitPlayerClasses and HitPlayerClasses.HealthClass then


--			HitPlayerClasses.HealthClass:Deduct(playerRockDamage)
--		else
--			warn("Missing health class ", player)
--		end
--	end
--end)