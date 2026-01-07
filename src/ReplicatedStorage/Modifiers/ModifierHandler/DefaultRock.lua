local player = game.Players.LocalPlayer

return function(tool: Tool?, RockModel: Part, Type: string)
	local ThePlayers = game.Players

	local INITIATE = game.ReplicatedStorage.Events.Action.INITIATE
	local CLIENTS = game.ReplicatedStorage.Events.Action.CLIENTS

	local debris = game:GetService("Debris")
	local workspace = game.Workspace

	local PVP = game.ReplicatedStorage.Events.Action.PVP
	local PVE = game.ReplicatedStorage.Events.Action.PVE

	local MUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
	local FUtils = require(game.ReplicatedStorage.Utilities.FunctionUtils)

	local service = require(game.ReplicatedStorage:WaitForChild("ServicesLoader"))

	local MotionService = service:GetService("Motion-Service") 

	local DefaultVFX = game.ReplicatedStorage.Modifiers.VFX.Default
	local SoundService = game.SoundService

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://122718518239290"

	local function simulateThrow(originPlayer, startCFrame, endCFrame, RockModel: Part)

		local direction = (endCFrame.Position - startCFrame.Position)
		local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

		local clone = RockModel:Clone()
		clone.Name = "ThrownRock"
		clone.Trail.Enabled = true
		clone.CFrame = startCFrame
		clone.Anchored = false
		clone.CanCollide = true
		clone.AssemblyLinearVelocity = Vector3.zero
		clone.AssemblyAngularVelocity = Vector3.zero

		local ThrowSound = FUtils.Game.playSound({
			SoundId = "rbxassetid://89087318649358",
			Volume = 0.5,  -- default if not provided
			RollOffMode = Enum.RollOffMode.InverseTapered,
			MinDistance = 10,
			MaxDistance = 100,
			Looped = false
		}, workspace)

		clone.Parent = workspace.Projectiles
		clone.Position = startCFrame.Position
		clone:ApplyImpulse(force * clone.AssemblyMass)

		local AirSound
		local hasHit = false
		task.delay(1, function()
			if hasHit then
				if AirSound then
					AirSound:Destroy()
				end
				return
			end
			AirSound = FUtils.Game.playSound({
				SoundId = "rbxassetid://111682574009278",
				Volume = 0.5,
				RollOffMode = Enum.RollOffMode.InverseTapered,
				MinDistance = 1,
				MaxDistance = 60,
				Looped = true
			}, clone)
		end)

		local Trove = MUtils.Trove.new()

		debris:AddItem(clone, 5)
		task.spawn(function()
			wait(5)
			Trove:Clean()
		end)

		local bounceCount = 0
		local lastTouchTime = 0
		local impactVolumes = {0.5, 0.4, 0.35, 0.3}
		local VFXPart

		local function playImpactEffect(position, volume)
			VFXPart = DefaultVFX.Ground.Smoke:Clone()
			VFXPart.Position = position
			VFXPart.Parent = workspace

			VFXPart.Smoke:Emit(math.round(3,8))

			local ImpactSound = FUtils.Game.playSound({
				SoundId = "rbxassetid://92907683028956",
				Volume = volume,
				RollOffMode = Enum.RollOffMode.InverseTapered,
				MinDistance = 10,
				MaxDistance = 250,
				Looped = false
			}, VFXPart)

			debris:AddItem(VFXPart, 0.8)
		end

		local conn
		conn = clone.Touched:Connect(function(hit)
			local now = tick()

			-- Check if hit a player
			local character = hit:FindFirstAncestorOfClass("Model")
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local hitPlayer = ThePlayers:GetPlayerFromCharacter(character)

					local function finish()
						if AirSound then
							AirSound:Destroy()
						else
							hasHit = true
						end

						print("Hit player: " .. hitPlayer.Name)
						PVP:FireServer(hitPlayer, originPlayer)

						local DamageVFX = DefaultVFX.Damage["Punch-02"]:Clone()
						DamageVFX.Position = clone.Position
						DamageVFX.Parent = workspace
						DamageVFX.Main.Hit1:Emit(math.round(1.5,2))

						local random = math.random(1,3)
						local HitSoundID
						if random == 1 then
							HitSoundID ="rbxassetid://120414258530130"
						elseif random == 2 then
							HitSoundID= "rbxassetid://118203522088820"
						elseif random == 3 then
							HitSoundID = "rbxassetid://120016698469358"
						end

						local HitSound = FUtils.Game.playSound({
							SoundId = HitSoundID,
							Volume = 0.5,
							RollOffMode = Enum.RollOffMode.InverseTapered,
							MinDistance = 2,
							MaxDistance = 10000,
							Looped = false
						}, workspace)
						
						debris:AddItem(DamageVFX,0.5)
						
						-- Knockback force
						if humanoid and humanoid.RootPart then
							local hrp = humanoid.RootPart
							local knockbackDirection = (hrp.Position - clone.Position).Unit
							local bodyVelocity = Instance.new("BodyVelocity")
							bodyVelocity.Velocity = knockbackDirection * 100 -- adjust strength
							bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
							bodyVelocity.P = 1250
							bodyVelocity.Parent = hrp

							game:GetService("Debris"):AddItem(bodyVelocity, 0.2) -- remove after 0.2 sec
						end
						
						local highlight = character:FindFirstChild("Highlight")
						if not highlight then
							local NewHighlight = Instance.new("Highlight")
							NewHighlight.OutlineColor = Color3.fromRGB(161, 23, 23)
							NewHighlight.FillTransparency = 1
							NewHighlight.OutlineTransparency = 1
							NewHighlight.Parent = character	
							highlight = NewHighlight
						end

						task.spawn(function()
							for i = 1, 2 do
								for t = 0, 1, 0.1 do
									highlight.OutlineTransparency = 1 - t
									task.wait(0.02)
								end
								for t = 0, 1, 0.1 do
									highlight.OutlineTransparency = t
									task.wait(0.02)
								end
							end
						end)

						-- Clean up after hitting a player
						Trove:Clean()
					end

					-- Fixed logic: Player type hits other players, Clients type hits the local player
					if Type == "Player" then
						if hitPlayer and hitPlayer ~= originPlayer then
							finish()
						elseif hitPlayer ~= originPlayer then -- NPC hit
							warn("zombie")
						end
					elseif Type == "Clients" then
						if hitPlayer and hitPlayer == player then  -- Use consistent player reference
							finish()
						end
					end
				end
			end

			-- Check if hit Ground
			local hitTags = hit:GetTags()
			local foundGround = false
			if hitTags then
				for _, tag in ipairs(hitTags) do
					if tag == "Ground" then
						foundGround = true

						if AirSound then
							AirSound:Destroy()
						else
							hasHit = true
						end

						break
					else
						-- Must be changed later 
						if AirSound then
							AirSound:Destroy()
						else
							hasHit = true
						end
					end
				end
			end

			if foundGround then
				bounceCount += 1

				-- Always play first impact immediately
				if bounceCount == 1 then
					playImpactEffect(clone.Position, impactVolumes[1])
				else
					-- For subsequent bounces, check cooldown
					if (now - lastTouchTime) < 0.2 then
						-- Skip rapid rolling touches
						return
					end

					local volume = impactVolumes[math.clamp(bounceCount, 2, #impactVolumes)] or 0.3
					playImpactEffect(clone.Position, volume)
				end

				lastTouchTime = now

				if bounceCount >= 3 then
					clone.Anchored = true
					return
				end
			end
		end)

		Trove:Add(conn)
	end

	if Type == "Clients" then
		return simulateThrow
	end

	if Type == "Player" and tool then
		local lastActivated
		local Activated

		local ToolActivationSignle = tool.Activated:Connect(function()
			Activated = tick()
			local RockCoolDown = player:GetAttribute("RockCoolDown")  -- Use consistent player reference
			if not lastActivated or (Activated - lastActivated) > RockCoolDown then
				lastActivated = Activated

				local character = player.Character
				if not character then return end

				local camera = workspace.CurrentCamera
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if not rootPart or not camera then return end

				local cameraFacing = camera.CFrame.LookVector
				local throwDistance = player:GetAttribute("ThrowDestince")

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then				
					local track = humanoid:LoadAnimation(animation)
					track:Play()
					
					local startCFrame = character:FindFirstChild("RightHand") and character.RightHand.CFrame
					local targetPos = startCFrame.Position + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)
					local endCFrame = CFrame.new(targetPos)
					INITIATE:FireServer(startCFrame, endCFrame)
					
					track:GetMarkerReachedSignal("Throwable"):Connect(function()
						--local startCFrame = character:FindFirstChild("RightHand") and character.RightHand.CFrame
						--local targetPos = startCFrame.Position + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)
						--local endCFrame = CFrame.new(targetPos)
						simulateThrow(player, startCFrame, endCFrame, RockModel)  -- Use consistent player reference
						--INITIATE:FireServer(startCFrame, endCFrame)
					end)
				end
			else
				print("On cooldown! Please wait.")
			end
		end)

		local PlayerTags
		local HaveTag = false

		-- a clean up for the signle when resting by event
		local observer = FUtils.Observers.observeTag("RestingTool", function(player: Player)
			local SignlTrove = MUtils.Trove.new()

			local PlayerTags = player:GetTags()

			if PlayerTags then
				for _ , Tag in ipairs(PlayerTags) do
					if Tag == "RestingTool" then
						HaveTag = true
						if ToolActivationSignle then
							SignlTrove:Add(ToolActivationSignle)
						end
					end
				end
			end

			return function()
				if PlayerTags then
					if HaveTag then
						warn("Cleaned")
						SignlTrove:Clean()
						ToolActivationSignle = nil
					end
				end
			end
		end, {game.Players})

		-- clean the observer
		task.spawn(function()
			while true do
				wait(3)
				if not ToolActivationSignle then
					observer()
					return
				end
			end
		end)

	end
end


