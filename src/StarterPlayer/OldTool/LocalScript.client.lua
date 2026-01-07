-- All your original setup...
local tool = script.Parent
local ThePlayers = game.Players
local player = ThePlayers.LocalPlayer

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

local FireVFX = game.ReplicatedStorage.Modifiers.VFX.Fire
local SoundService = game.SoundService

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://98729838273046"

local function simulateThrow(startCFrame, endCFrame, name)
	local handleTemplate = tool:FindFirstChild("Handle")
	if not handleTemplate then return end

	local direction = (endCFrame.Position - startCFrame.Position)
	local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

	local clone = handleTemplate:Clone()
	clone.Name = name or "ThrownRock"
	clone.CFrame = startCFrame
	clone.Anchored = false
	clone.CanCollide = true
	clone.AssemblyLinearVelocity = Vector3.zero
	clone.AssemblyAngularVelocity = Vector3.zero

	local ThrowSound = FUtils.Sound.New("rbxassetid://89087318649358", 10, 100, Enum.RollOffMode.InverseTapered,false, workspace)
	ThrowSound:Play()

	clone.Parent = workspace.Projectiles
	clone.Position = startCFrame.Position

	local IgniteSound = FUtils.Sound.New("rbxassetid://99670330619227", 2, 60, Enum.RollOffMode.InverseTapered,false, clone, 1)
	IgniteSound:Play()
	clone:ApplyImpulse(force * clone.AssemblyMass)

	local ImpulseVFX = FireVFX.Impulse.FireRock:Clone()
	ImpulseVFX.ATFire.Parent = clone

	local StartFireSound = FUtils.Sound.New("rbxassetid://139997313955540", 2, 30, Enum.RollOffMode.InverseTapered,false, clone, 0.75)
	StartFireSound:Play()

	local AirSound
	local hasHit = false
	task.spawn(function()
		if hasHit then
			AirSound:Destroy()
			return
		end

		AirSound = FUtils.Sound.New("rbxassetid://135277364114134", 15, 150, Enum.RollOffMode.InverseTapered,true, clone, 0.65)
		AirSound:Play()
	end)

	local Trove = MUtils.Trove.new()

	debris:AddItem(clone, 5)
	task.spawn(function()
		wait(5)
		Trove:Clean()
	end)

	local function handlePlayerHit(hitPlayer, humanoid)
		if AirSound then
			AirSound:Destroy()
		else
			hasHit = true
		end

		print("Hit player: " .. hitPlayer.Name)
		PVP:FireServer(hitPlayer, player)

		local OnFirePlayerVFX = FireVFX.Damage.Fire:Clone()
		OnFirePlayerVFX.Flames.Parent = humanoid
		OnFirePlayerVFX.Flames:Emit(math.round(1))

		local HitSound = FUtils.Sound.New("rbxassetid://117961720345961", 2, 10000, Enum.RollOffMode.Inverse,false, humanoid)
		HitSound:Play()

		task.delay(0.3, function()
			local FireSound = FUtils.Sound.New("rbxassetid://71667432052016", 2, 100, Enum.RollOffMode.InverseTapered,true, humanoid)
			FireSound:Play()

			wait(5)
			FireSound:Destroy()
			humanoid.Flames:Destroy()
		end)

		debris:AddItem(OnFirePlayerVFX)

		local character = hitPlayer.Character
		if character then
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
	end

	local function playImpactEffect(originPos)
		local rayOrigin = originPos
		local rayDirection = Vector3.new(0, -10, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {clone}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.IgnoreWater = true

		local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		local surfacePos = rayResult and rayResult.Position or originPos - Vector3.new(0, clone.Size.Y / 2, 0)

		if clone:FindFirstChild("ATFire") then
			clone.ATFire:Destroy()
		end

		clone.Anchored = true

		local VFXBoom = FireVFX.Ground.FireExplotion:Clone()
		VFXBoom.Position = surfacePos
		VFXBoom.Parent = workspace

		local VFXPart = FireVFX.Ground.Crack_Dissolve_3:Clone()
		VFXPart.Position = surfacePos
		VFXPart.Attachment.Realistic:Emit(math.round(1))
		VFXPart.Attachment.Realistic.TimeScale = 0
		VFXPart.Parent = workspace

		task.delay(0.5, function()
			VFXPart.Attachment.Realistic.TimeScale = 0.2
		end)

		local ImpactSound = FUtils.Sound.New("rbxassetid://113278096530098", 40, 400, Enum.RollOffMode.InverseTapered, false, VFXBoom)
		ImpactSound:Play()

		local FireSound = FUtils.Sound.New("rbxassetid://112024119410457", 2, 80, Enum.RollOffMode.InverseTapered, true, VFXBoom)
		FireSound:Play()

		debris:AddItem(VFXPart, 4)

		-- Ground hit area damage
		local groundZone = Instance.new("Part")
		groundZone.Anchored = true
		groundZone.CanCollide = false
		groundZone.Size = Vector3.new(6, 1, 6)
		groundZone.CFrame = CFrame.new(surfacePos + Vector3.new(0, 0.5, 0))
		groundZone.Transparency = 1
		groundZone.Name = "GroundHitZone"
		groundZone.Parent = workspace

		local conn
		conn = groundZone.Touched:Connect(function(part)
			local char = part:FindFirstAncestorOfClass("Model")
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local hitPlayer = ThePlayers:GetPlayerFromCharacter(char)
				if hum and hitPlayer and hitPlayer ~= player then
					handlePlayerHit(hitPlayer, hum)
				end
			end
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
			conn:Disconnect()
			groundZone:Destroy()
		end)

		debris:AddItem(groundZone, 1.5)
	end

	local conn
	conn = clone.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local hitPlayer = ThePlayers:GetPlayerFromCharacter(character)
				if hitPlayer and hitPlayer ~= player then
					handlePlayerHit(hitPlayer, humanoid)
					clone:Destroy()
					return
				elseif hitPlayer ~= player then
					warn("zombie")
				end
			end
		end

		local hitTags = hit:GetTags()
		if hitTags then
			for _, tag in ipairs(hitTags) do
				if tag == "Ground" then
					if AirSound then AirSound:Destroy() else hasHit = true end
					playImpactEffect(clone.Position)
					break
				else
					if AirSound then AirSound:Destroy() else hasHit = true end
				end
			end
		end

		Trove:Add(conn)
	end)

	local lastActivated
	local Activated

	tool.Activated:Connect(function()
		Activated = tick()
		local RockCoolDown = player:GetAttribute("RockCoolDown") 
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
				local startCFrame = character:FindFirstChild("RightHand") and character.RightHand.CFrame
				local track = humanoid:LoadAnimation(animation)
				track:Play()
				track:GetMarkerReachedSignal("Throwable"):Connect(function()

					local targetPos = startCFrame.Position + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)

					local endCFrame = CFrame.new(targetPos)

					simulateThrow(startCFrame, endCFrame, "LocalThrow")
					INITIATE:FireServer(startCFrame, endCFrame)
				end)
			end

		else
			print("On cooldown! Please wait.")
		end

	end)

end














