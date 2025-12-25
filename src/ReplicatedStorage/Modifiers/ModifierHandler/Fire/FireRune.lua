----local player = game.Players.LocalPlayer

----return function(tool: Tool?, RockModel: Part, Type: string)
----	local ThePlayers = game.Players

----	local INITIATE = game.ReplicatedStorage.Events.Action.INITIATE
----	local CLIENTS = game.ReplicatedStorage.Events.Action.CLIENTS

----	local debris = game:GetService("Debris")
----	local workspace = game.Workspace

----	local PVP = game.ReplicatedStorage.Events.Action.PVP
----	local PVE = game.ReplicatedStorage.Events.Action.PVE

----	local MUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
----	local FUtils = require(game.ReplicatedStorage.Utilities.FunctionUtils)

----	local service = require(game.ReplicatedStorage:WaitForChild("ServicesLoader"))

----	local MotionService = service:GetService("Motion-Service") 

----	local FireVFX = game.ReplicatedStorage.Modifiers.VFX.Fire
----	local SoundService = game.SoundService

----	local animation = Instance.new("Animation")
----	animation.AnimationId = "rbxassetid://122718518239290"

----	local function simulateThrow(originPlayer, startCFrame, endCFrame, RockModel: Part)

----		local direction = (endCFrame.Position - startCFrame.Position)
----		local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

----		local clone = RockModel:Clone()
----		clone.Name = "ThrownRock"
----		clone.Trail.Enabled = true
----		clone.CFrame = startCFrame
----		clone.Anchored = false
----		clone.CanCollide = true
----		clone.AssemblyLinearVelocity = Vector3.zero
----		clone.AssemblyAngularVelocity = Vector3.zero

----		local ThrowSound = FUtils.Sound.New("rbxassetid://89087318649358", 10, 100, Enum.RollOffMode.InverseTapered,false, workspace)
----		ThrowSound:Play()

----		clone.Parent = workspace.Projectiles
----		clone.Position = startCFrame.Position

----		local IgniteSound = FUtils.Sound.New("rbxassetid://99670330619227", 2, 60, Enum.RollOffMode.InverseTapered,false, clone, 1)
----		IgniteSound:Play()
----		clone:ApplyImpulse(force * clone.AssemblyMass)

----		local ImpulseVFX = FireVFX.Impulse.FireRock:Clone()
----		ImpulseVFX.ATFire.Parent = clone

----		local StartFireSound = FUtils.Sound.New("rbxassetid://139997313955540", 2, 30, Enum.RollOffMode.InverseTapered,false, clone, 0.75)
----		StartFireSound:Play()

----		local AirSound
----		local hasHit = false
----		task.spawn(function()
----			if hasHit then
----				AirSound:Destroy()
----				return
----			end

----			AirSound = FUtils.Sound.New("rbxassetid://135277364114134", 15, 150, Enum.RollOffMode.InverseTapered,true, clone, 0.65)
----			AirSound:Play()
----		end)


----		local Trove = MUtils.Trove.new()

----		debris:AddItem(clone, 5)
----		task.delay(5,function()
----			Trove:Clean()
----		end)

----		local function handlePlayerHit(hitPlayer, humanoid)
----			if AirSound then
----				AirSound:Destroy()
----			else
----				hasHit = true
----			end

----			print("Hit player: " .. hitPlayer.Name)
----			PVP:FireServer(hitPlayer, player)
			
----			local OnFirePlayerVFX = FireVFX.Damage.Fire:Clone()
----			local flames = OnFirePlayerVFX:FindFirstChild("Flames")
----			if flames then
----				flames.Parent = humanoid
----				flames:Emit(math.round(1))
----			else
----				warn("🔥 'Flames' not found inside Fire VFX clone.")
----			end


----			local HitSound = FUtils.Sound.New("rbxassetid://117961720345961", 2, 10000, Enum.RollOffMode.Inverse,false, humanoid)
----			HitSound:Play()

----			task.delay(0.3, function()
----				local FireSound = FUtils.Sound.New("rbxassetid://71667432052016", 2, 100, Enum.RollOffMode.InverseTapered,true, humanoid, 0.25)
----				FireSound:Play()

----				wait(5)
----				FireSound:Destroy()
----				humanoid.Flames:Destroy()
----			end)

----			debris:AddItem(OnFirePlayerVFX)

----			local character = hitPlayer.Character
----			if character then
----				local highlight = character:FindFirstChild("Highlight")
----				if not highlight then
----					local NewHighlight = Instance.new("Highlight")
----					NewHighlight.OutlineColor = Color3.fromRGB(161, 23, 23)
----					NewHighlight.FillTransparency = 1
----					NewHighlight.OutlineTransparency = 1
----					NewHighlight.Parent = character	
----					highlight = NewHighlight
----				end

----				task.spawn(function()
----					for i = 1, 2 do
----						for t = 0, 1, 0.1 do
----							highlight.OutlineTransparency = 1 - t
----							task.wait(0.02)
----						end
----						for t = 0, 1, 0.1 do
----							highlight.OutlineTransparency = t
----							task.wait(0.02)
----						end
----					end
----				end)
----			end
----		end

----		local function playImpactEffect(originPos)
----			local rayOrigin = originPos
----			local rayDirection = Vector3.new(0, -10, 0)
----			local raycastParams = RaycastParams.new()
----			raycastParams.FilterDescendantsInstances = {clone}
----			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
----			raycastParams.IgnoreWater = true

----			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
----			local surfacePos = rayResult and rayResult.Position or originPos - Vector3.new(0, clone.Size.Y / 2, 0)

----			if clone:FindFirstChild("ATFire") then
----				clone.ATFire:Destroy()
----			end

----			clone.Anchored = true

----			local VFXBoom = FireVFX.Ground.FireExplotion:Clone()
----			VFXBoom.Position = surfacePos
----			VFXBoom.Parent = workspace

----			local VFXPart = FireVFX.Ground.Crack_Dissolve_3:Clone()
----			VFXPart.Position = surfacePos
----			VFXPart.Attachment.Realistic:Emit(math.round(1))
----			VFXPart.Attachment.Realistic.TimeScale = 0
----			VFXPart.Parent = workspace

----			task.delay(0.5, function()
----				VFXPart.Attachment.Realistic.TimeScale = 0.2
----			end)

----			local ImpactSound = FUtils.Sound.New("rbxassetid://113278096530098", 40, 400, Enum.RollOffMode.InverseTapered, false, VFXBoom)
----			ImpactSound:Play()

----			local FireSound = FUtils.Sound.New("rbxassetid://112024119410457", 2, 80, Enum.RollOffMode.InverseTapered, true, VFXBoom)
----			FireSound:Play()

----			debris:AddItem(VFXPart, 4)

----			-- Ground hit area damage
----			local groundZone = Instance.new("Part")
----			groundZone.Anchored = true
----			groundZone.CanCollide = false
----			groundZone.Size = Vector3.new(6, 1, 6)
----			groundZone.CFrame = CFrame.new(surfacePos + Vector3.new(0, 0.5, 0))
----			groundZone.Transparency = 1
----			groundZone.Name = "GroundHitZone"
----			groundZone.Parent = workspace

----			local conn
----			conn = groundZone.Touched:Connect(function(part)
----				local char = part:FindFirstAncestorOfClass("Model")
----				if char then
----					local hum = char:FindFirstChildOfClass("Humanoid")
----					local hitPlayer = ThePlayers:GetPlayerFromCharacter(char)
					
----					if Type == "Player" then
----						if hitPlayer and hitPlayer ~= originPlayer then
----							handlePlayerHit(hitPlayer, hum)
----						elseif hitPlayer ~= originPlayer then -- NPC hit
----							warn("zombie")
----						end
----					elseif Type == "Clients" then
----						if hitPlayer and hitPlayer == player then  -- Use consistent player reference
----							handlePlayerHit(hitPlayer, hum)
----						end
----					end

----				end
----			end)

----			task.delay(3, function()
----				for _, descendant in ipairs(VFXBoom:GetDescendants()) do
----					if descendant:IsA("ParticleEmitter") then
----						descendant.Lifetime = NumberRange.new(0)
----					end
----				end

----				for i = 1, 10 do
----					FireSound.Volume = 2 * (1 - i / 10)
----					task.wait(0.1)
----				end
----				FireSound:Stop()
----				FireSound:Destroy()
----				conn:Disconnect()
----				groundZone:Destroy()
----			end)

----			debris:AddItem(groundZone, 1.5)
----		end

----		local conn
----		conn = clone.Touched:Connect(function(hit)
----			local character = hit:FindFirstAncestorOfClass("Model")
----			if character then
----				local humanoid = character:FindFirstChildOfClass("Humanoid")
----				if humanoid then
----					local hitPlayer = ThePlayers:GetPlayerFromCharacter(character)
----					if hitPlayer and hitPlayer ~= player then
----						handlePlayerHit(hitPlayer, humanoid)
----						clone:Destroy()
----						return
----					elseif hitPlayer ~= player then
----						warn("zombie")
----					end
----				end
----			end

----			local hitTags = hit:GetTags()
----			if hitTags then
----				for _, tag in ipairs(hitTags) do
----					if tag == "Ground" then
----						if AirSound then AirSound:Destroy() else hasHit = true end
----						playImpactEffect(clone.Position)
----						break
----					else
----						if AirSound then AirSound:Destroy() else hasHit = true end
----					end
----				end
----			end
----		end)
		
----		Trove:Add(conn)
----	end

----	if Type == "Clients" then
----		return simulateThrow 
----	end

----	if Type == "Player" and tool then
----		local lastActivated
----		local Activated

----		tool.Activated:Connect(function()
----			Activated = tick()
----			local RockCoolDown = player:GetAttribute("RockCoolDown")  -- Use consistent player reference
----			if not lastActivated or (Activated - lastActivated) > RockCoolDown then
----				lastActivated = Activated

----				local character = player.Character
----				if not character then return end

----				local camera = workspace.CurrentCamera
----				local rootPart = character:FindFirstChild("HumanoidRootPart")
----				if not rootPart or not camera then return end

----				local cameraFacing = camera.CFrame.LookVector
----				local throwDistance = player:GetAttribute("ThrowDestince")

----				local humanoid = character:FindFirstChildOfClass("Humanoid")
----				if humanoid then				
----					local track = humanoid:LoadAnimation(animation)
----					track:Play()
----					track:GetMarkerReachedSignal("Throwable"):Connect(function()
----						local startCFrame = character:FindFirstChild("RightHand") and character.RightHand.CFrame
----						local targetPos = startCFrame.Position + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)
----						local endCFrame = CFrame.new(targetPos)
----						simulateThrow(player, startCFrame, endCFrame, RockModel)  -- Use consistent player reference
----						INITIATE:FireServer(startCFrame, endCFrame)
----					end)
----				end
----			else
----				print("On cooldown! Please wait.")
----			end
----		end)
----	end
----end

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

	local VFX = game.ReplicatedStorage.Modifiers.VFX.Fire.AR_FireRune
	local SoundService = game.SoundService

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://122718518239290"

	local function simulateThrow(originPlayer, startCFrame, endCFrame, RockModel: Part)

		local direction = (endCFrame.Position - startCFrame.Position)
		local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

		local clone = RockModel:Clone()
		clone.Name = "ThrownRock"
		clone.CFrame = startCFrame
		clone.Anchored = false
		clone.CanCollide = true
		clone.AssemblyLinearVelocity = Vector3.zero
		clone.AssemblyAngularVelocity = Vector3.zero

		local ThrowSound = FUtils.Game.playSound({
			SoundId = "rbxassetid://89087318649358",
			MinDistance = 10,
			MaxDistance = 100,
			RollOffMode = Enum.RollOffMode.InverseTapered,
			Volume = 0.5,
			Looped = false
		}, workspace)

		clone.Parent = workspace.Projectiles
		clone.Position = startCFrame.Position

		clone:ApplyImpulse(force * clone.AssemblyMass)

		local ImpulseVFX = VFX.Impulse.FireRock:Clone()
		ImpulseVFX.ATFire.Parent = clone

		local StartFireSound = FUtils.Game.playSound({
			SoundId = "rbxassetid://139997313955540",
			MinDistance = 2,
			MaxDistance = 30,
			RollOffMode = Enum.RollOffMode.InverseTapered,
			Volume = 0.75,
			Looped = false
		}, clone)

		local AirSound
		local hasHit = false
		--task.delay(0.1, function()
		--	if hasHit then
		--		if AirSound then
		--			AirSound:Destroy()
		--		end
		--		return
		--	end
		--	AirSound = FUtils.Sound.New("rbxassetid://135277364114134", 15, 150, Enum.RollOffMode.InverseTapered,true, clone, 0.65)
		--	AirSound:Play()
		--end)\
		
		if hasHit then
			if AirSound then
				AirSound:Destroy()
			end
			return
		end
		
		AirSound = FUtils.Game.playSound({
			SoundId = "rbxassetid://135277364114134",
			MinDistance = 15,
			MaxDistance = 150,
			RollOffMode = Enum.RollOffMode.InverseTapered,
			Volume = 0.65,
			Looped = true
		}, clone)

		local Trove = MUtils.Trove.new()
		
		debris:AddItem(clone, 5)
		task.spawn(function()
			wait(5)
			if Trove then
				Trove:Clean()
			end
		end)

		local VFXPart

		local function playImpactEffect(position)
			local rayOrigin = position
			local rayDirection = Vector3.new(0, -10, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {clone}
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			raycastParams.IgnoreWater = true

			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			local surfacePos = rayResult and rayResult.Position or position - Vector3.new(0, clone.Size.Y / 2, 0)

			if clone:FindFirstChild("ATFire") then
				clone.ATFire:Destroy()
			end

			clone.Anchored = true

			local VFXBoom = VFX.Ground.FireExplotion:Clone()
			VFXBoom.Position = surfacePos
			VFXBoom.Parent = workspace

			VFXPart = VFX.Ground.Crack_Dissolve_3:Clone()
			VFXPart.Position = surfacePos
			VFXPart.Attachment.Realistic:Emit(math.round(1))
			VFXPart.Attachment.Realistic.TimeScale = 0
			VFXPart.Parent = workspace

			task.delay(0.5, function()
				VFXPart.Attachment.Realistic.TimeScale = 0.2
			end)

			local ImpactSound = FUtils.Game.playSound({
				SoundId = "rbxassetid://113278096530098",
				MinDistance = 10,
				MaxDistance = 250,
				RollOffMode = Enum.RollOffMode.InverseTapered,
				Volume = 1,
				Looped = false
			}, VFXBoom)

			local FireSound = FUtils.Game.playSound({
				SoundId = "rbxassetid://112024119410457",
				MinDistance = 2,
				MaxDistance = 80,
				RollOffMode = Enum.RollOffMode.InverseTapered,
				Volume = 1,
				Looped = true
			}, VFXBoom)

			debris:AddItem(VFXPart, 4)

			-- Ground hit area damage
			local groundZone = Instance.new("Part")
			groundZone.Shape = Enum.PartType.Ball
			groundZone.CanCollide = false
			groundZone.Size = Vector3.new(15, 15, 15)
			groundZone.CFrame = CFrame.new(surfacePos + Vector3.new(0, 0.5, 0))
			groundZone.Transparency = 1
			groundZone.Name = "GroundHitZone"
			groundZone.Parent = workspace
			
			local ExplosionTrove = MUtils.Trove.new()
			local HitPlayers = {}
			local zoneConn

			zoneConn = groundZone.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				if not character then
					return
				end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local RootPart = character:FindFirstChild("HumanoidRootPart")

				if not humanoid then
					warn("humanoid not found")
					return
				end

				local hitPlayer = ThePlayers:GetPlayerFromCharacter(character)
				warn(hitPlayer)

				local shouldHit = false
				if Type == "Player" then
					if hitPlayer and hitPlayer ~= originPlayer then
						shouldHit = true
					end
				elseif Type == "Clients" then
					if hitPlayer and hitPlayer == player then
						shouldHit = true
					end
				end

				if not shouldHit or not hitPlayer then
					return
				end

				local playerId = hitPlayer.UserId
				if HitPlayers[playerId] then
					return
				end

				-- debounce immediately
				HitPlayers[playerId] = true

				-- encapsulate hit logic
				local function finishPlayerHit()
					-- clean up previous trove if provided
					if Trove then
						Trove:Clean()
					end

					if AirSound then
						AirSound:Destroy()
					else
						hasHit = true
					end

					print("Hit player: " .. hitPlayer.Name)
					PVP:FireServer(hitPlayer, originPlayer)

					local OnFirePlayerVFX = VFX.Damage.Fire:Clone()
					local flames = OnFirePlayerVFX:FindFirstChild("Flames")
					if flames and RootPart and not RootPart:FindFirstChild("Flames") then
						flames.Parent = RootPart
						flames:Emit(math.round(1))
					end

					local HitSound = FUtils.Game.playSound({
						SoundId = "rbxassetid://117961720345961",
						MinDistance = 2,
						MaxDistance = 10000,
						RollOffMode = Enum.RollOffMode.Inverse,
						Volume = 0.5,
						Looped = false
					}, humanoid)

					task.delay(0.3, function()
						
						local FireSound = FUtils.Game.playSound({
							SoundId = "rbxassetid://71667432052016",
							MinDistance = 2,
							MaxDistance = 100,
							RollOffMode = Enum.RollOffMode.InverseTapered,
							Volume = 0.25,
							Looped = true
						}, humanoid)

						wait(5)
						if flames then flames:Destroy() end
						if FireSound then FireSound:Destroy() end
					end)

					debris:AddItem(OnFirePlayerVFX)

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
				end

				finishPlayerHit()
			end)


			ExplosionTrove:Add(zoneConn)
			
			task.delay(0.4, function()
				ExplosionTrove:Clean()
				if groundZone and groundZone.Parent then
					groundZone:Destroy()
				end
				-- Clear the HitPlayers table (no need to call :Destroy() on a table)
				HitPlayers = nil
			end)

			task.delay(3, function()
				for _, descendant in ipairs(VFXBoom:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") then
						descendant.Lifetime = NumberRange.new(0)
					end
				end

				for i = 1, 10 do
					FireSound.Volume = 2 * (1 - i / 10)
					task.wait(0.1)
				end
				FireSound:Stop()
				FireSound:Destroy()
				zoneConn:Disconnect()
				groundZone:Destroy()
			end)

			debris:AddItem(groundZone, 1.5)
		end

		local conn
		conn = clone.Touched:Connect(function(hit)
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

						local OnFirePlayerVFX = VFX.Damage.Fire:Clone()
						local flames = OnFirePlayerVFX:FindFirstChild("Flames")
						if flames then
							flames.Parent = humanoid
							flames:Emit(math.round(1))
						else
							warn("🔥 'Flames' not found inside Fire VFX clone.")
						end

						local HitSound = FUtils.Sound.New("rbxassetid://117961720345961", 2, 10000, Enum.RollOffMode.Inverse,false, humanoid)
						HitSound:Play()

						task.delay(0.3, function()
							local FireSound = FUtils.Sound.New("rbxassetid://71667432052016", 2, 100, Enum.RollOffMode.InverseTapered,true, humanoid, 0.25)
							FireSound:Play()

							wait(5)
							FireSound:Destroy()
							humanoid.Flames:Destroy()
						end)

						debris:AddItem(OnFirePlayerVFX)

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
						clone:Destroy()
						Trove:Clean()
						return
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
				playImpactEffect(clone.Position)
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
					track:GetMarkerReachedSignal("Throwable"):Connect(function()
						local startCFrame = character:FindFirstChild("RightHand") and character.RightHand.CFrame
						local targetPos = startCFrame.Position + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)
						local endCFrame = CFrame.new(targetPos)
						simulateThrow(player, startCFrame, endCFrame, RockModel)  -- Use consistent player reference
						INITIATE:FireServer(startCFrame, endCFrame)
					end)
				end
			else
				print("On cooldown! Please wait.")
			end
		end)
		
		local observer = FUtils.Observers.observeTag("RestingTool", function(player: Player)
			local SignlTrove = MUtils.Trove.new()

			if ToolActivationSignle then
				SignlTrove:Add(ToolActivationSignle)
			end

			return function()
				SignlTrove:Clean()
				ToolActivationSignle = nil
			end
		end, {game.Players})

		-- clean the observer
		task.spawn(function()
			while true do
				wait(10)
				if not ToolActivationSignle then
					observer()
					return
				end
			end
		end)
	end
end

