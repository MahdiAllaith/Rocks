local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeathService = {}

local Players = game.Players
local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)
local handler = require(game.ServerStorage.ServerServices.Services["Player-Service"]).getPlayerHandler()

local playerTroves = {}

function DeathService.Init()

	Players.PlayerAdded:Connect(function(player)
		local Trove = ModuleUtils.Trove.new()
		playerTroves[player] = Trove

		-- Ensure Health attribute exists
		if player:GetAttribute("Health") == nil then
			local found = false
			local startTime = tick()

			repeat
				task.wait(0.1)
				if player:GetAttribute("Health") ~= nil then
					found = true
					break
				end
			until tick() - startTime > 5

			if not found then
				warn(`Player {player.Name} does not have attribute "Health" after waiting 5 seconds.`)
			end
		end

		-- When player's Health attribute changes
		local conn = player:GetAttributeChangedSignal("Health"):Connect(function()
			local currentHealth = player:GetAttribute("Health")
			if currentHealth and currentHealth <= 0 then
				local character = player.Character
				if character and character:FindFirstChildOfClass("Humanoid") then
					local humanoid = character:FindFirstChildOfClass("Humanoid")

					local PlayerClasses = handler.getCredentails(player)

					-- Kill humanoid (starts Roblox death + respawn timer)
					humanoid.Health = 0
					
					task.wait()
					local conn
					conn = player.CharacterAdded:Connect(function()
						PlayerClasses.HealthClass.DeathSignal:Fire()
						conn:Disconnect()
					end)

				end
			end
		end)
		Trove:Add(conn)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local trove = playerTroves[player]
		if trove then
			trove:Clean()
			playerTroves[player] = nil
		end
	end)

	return true
end

return DeathService
