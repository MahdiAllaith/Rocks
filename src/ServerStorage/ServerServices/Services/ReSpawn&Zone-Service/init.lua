
--[[
	@author:
	@date:
	@description:
	A Service hybrid handler for all client input manager for (UI, Motion, Interaction) services.
]]

-----------------------------
-- SERVICES --
-----------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Zone = require(ReplicatedStorage.Utilities.ModuleUtils._Zone)
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)

local PlayerService = require(ServerStorage.ServerServices.Services["Player-Service"])

local SpawnPartsFolder = workspace:WaitForChild("SpawnParts")
local MapZonesDetectorsFolder = workspace:WaitForChild("MapZonesDetectors")

-----------------------------
-- Events --
-----------------------------
local RespawnZoomOutCameraEvent = ReplicatedStorage.Events.Motion.RespawnZoomOutCamera
local IsPlayerInObby = ServerStorage.ServerBindableEvents.IsPlayerInObby
local PlayerLostAttempt = ServerStorage.ServerBindableEvents.PlayerLostAttempt
local PlayerReachedNewLevel = ServerStorage.ServerBindableEvents.PlayerReachedNewLevel
local OnObbyNewLevel = ReplicatedStorage.Events.Obby.OnObbyNewLevel
local OnObbyFail = ReplicatedStorage.Events.Obby.OnObbyFail


-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local PlayersCurrentLocation: { [Player]: string } = {}

local ObbyPlayerTeleportLocation: {
	[Player]: {
		Level: number,
		Spawn: BasePart
	}
} = {}
-- Respawn Location Parts
local S_CastleCenter = SpawnPartsFolder:WaitForChild("CastleCenter")
local S_HolloCave = SpawnPartsFolder:WaitForChild("HolloCave")
local S_MountHolloCenter_OnDeath = SpawnPartsFolder:WaitForChild("MountHolloCenter_OnDeath")
local S_MountHolloCave_OnRespawn = SpawnPartsFolder:WaitForChild("MountHolloCave_OnRespawn")
local S_ThroneHall = SpawnPartsFolder:WaitForChild("ThroneHall")
local S_CastleCenterCrowsRoad = SpawnPartsFolder:WaitForChild("CastleCenterCrowsRoad")

-- Zones Parts
local Z_CastleCenter = MapZonesDetectorsFolder:WaitForChild("CastleCenterZone")
local Z_CastleCenter2 = MapZonesDetectorsFolder:WaitForChild("CastleCenterZone2")
local Z_HolloCave = MapZonesDetectorsFolder:WaitForChild("HolloCaveZone")
local Z_MountHolloCave = MapZonesDetectorsFolder:WaitForChild("MountHolloCaveZone")
local Z_ThroneHall = MapZonesDetectorsFolder:WaitForChild("ThroneHallZone")
local Z_CastleCenterCrowsRoad = MapZonesDetectorsFolder:WaitForChild("CastleCenterCrowsRoadZone")
local Z_CastleCenterCrowsRoad2 = MapZonesDetectorsFolder:WaitForChild("CastleCenterCrowsRoadZone2")
local Z_VoidDeath = MapZonesDetectorsFolder:WaitForChild("VoidDeathZone")
local Z_ObbyTeleport = MapZonesDetectorsFolder:WaitForChild("ObbyTeleportZones")

local ObbyStartSpawn = workspace:WaitForChild("Area").Obby.Level1.LV1_Spawn

local ObbyLevelsFolder = workspace:WaitForChild("Area").Obby

-- Zone to SpawnPart Mapping
local ZoneSpawnMap = {
	CastleCenterZone = S_CastleCenter,
	HolloCaveZone = S_HolloCave,
	MountHolloCaveZone = S_MountHolloCave_OnRespawn,
	MountHolloCenterZone = S_MountHolloCenter_OnDeath,
	ThroneHallZone = S_ThroneHall,
	CastleCenterCrowsRoadZone = S_CastleCenterCrowsRoad,
}

-- Constants
local DEFAULT_ZONE_NAME = "MountHolloCaveZone"

-----------------------------
-- VFX UTILITY FUNCTIONS --
-----------------------------

-- Creates a VFX part that follows a target position
local function createVFXPart(name: string, initialPosition: Vector3): (Part, RBXScriptConnection)
	local vfxPart = Instance.new("Part")
	vfxPart.Anchored = true
	vfxPart.CanCollide = false
	vfxPart.CanQuery = false
	vfxPart.CanTouch = false
	vfxPart.Transparency = 1
	vfxPart.Size = Vector3.new(3, 3, 3)
	vfxPart.Orientation = Vector3.new(0, 0, 90)
	vfxPart.Name = name
	vfxPart.Position = initialPosition
	vfxPart.Parent = workspace

	return vfxPart
end

-- Creates and configures VFX emitters
local function createVFXEmitters(parent: Instance, initialRate: number?, initialTimeScale: number?)
	local onSpawnVFX = script.OnSpawnVFX
	local vfx1 = onSpawnVFX.Line1:Clone()
	local vfx2 = onSpawnVFX.Line2:Clone()

	vfx1.Rate = initialRate or 0
	vfx2.Rate = initialRate or 0
	vfx1.TimeScale = initialTimeScale or 0.3
	vfx2.TimeScale = initialTimeScale or 0.3
	vfx1.Parent = parent
	vfx2.Parent = parent

	return vfx1, vfx2
end

-- Creates a highlight effect
local function createHighlight(parent: Instance, initialTransparency: number?)
	local onSpawnVFX = script.OnSpawnVFX
	local highlight = onSpawnVFX.Highlight:Clone()
	highlight.FillTransparency = initialTransparency or 1
	highlight.OutlineTransparency = initialTransparency or 1
	highlight.Parent = parent

	return highlight
end

-- Tweens VFX emitters with specified parameters
local function tweenVFXEmitters(vfx1: ParticleEmitter, vfx2: ParticleEmitter, duration: number, targetRate: number, targetTimeScale: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(vfx1, tweenInfo, { Rate = targetRate, TimeScale = targetTimeScale }):Play()
	TweenService:Create(vfx2, tweenInfo, { Rate = targetRate, TimeScale = targetTimeScale }):Play()
end

-- Tweens highlight transparency
local function tweenHighlight(highlight: Highlight, duration: number, fillTransparency: number, outlineTransparency: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return TweenService:Create(highlight, tweenInfo, {
		FillTransparency = fillTransparency,
		OutlineTransparency = outlineTransparency,
	})
end

-- Makes character parts transparent/visible
local function setCharacterTransparency(character: Model, transparency: number, duration: number?)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local targetTransparency = part.Name == "HumanoidRootPart" and 1 or transparency
			if duration then
				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(part, tweenInfo, { Transparency = targetTransparency }):Play()
			else
				part.Transparency = targetTransparency
			end
		elseif part:IsA("Decal") then
			if duration then
				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(part, tweenInfo, { Transparency = transparency }):Play()
			else
				part.Transparency = transparency
			end
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle then
				if duration then
					local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					TweenService:Create(handle, tweenInfo, { Transparency = transparency }):Play()
				else
					handle.Transparency = transparency
				end
			end
		end
	end
end

-- Main spawn VFX function - handles all spawn/respawn effects
local function playSpawnVFX(character: Model, positionOffset: Vector3?)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local offset = positionOffset or Vector3.new(0, -1, 0)

	-- Create highlight
	local highlight = createHighlight(character, 0)

	-- Create VFX part with position tracking
	local vfxPart = createVFXPart("SpawnVFXPart", root.Position + offset)
	local conn = RunService.Heartbeat:Connect(function()
		if root and root.Parent then
			vfxPart.Position = root.Position + offset
		end
	end)

	-- Create and configure emitters
	local vfx1, vfx2 = createVFXEmitters(vfxPart, 100, 0.1)
	vfx1:Emit(1)
	vfx2:Emit(1)

	-- Fade in VFX
	tweenVFXEmitters(vfx1, vfx2, 1, 300, 1)
	tweenHighlight(highlight, 1, 0, 0):Play()

	-- Fade out after delay
	task.delay(1, function()
		tweenHighlight(highlight, 1, 1, 1):Play()
		tweenVFXEmitters(vfx1, vfx2, 1, 0, 0.3)

		task.delay(1, function()
			if vfxPart then vfxPart:Destroy() end
			if conn then conn:Disconnect() end
		end)
	end)
end

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

local function forcePlayerFallStraight(player: Player, duration: number?, slowFactor: number?)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if root:FindFirstChild("FallForce") then root.FallForce:Destroy() end
	if root:FindFirstChild("FallAttachment") then root.FallAttachment:Destroy() end

	local att = Instance.new("Attachment")
	att.Name = "FallAttachment"
	att.Parent = root

	local vf = Instance.new("VectorForce")
	vf.Name = "FallForce"
	vf.Attachment0 = att
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.ApplyAtCenterOfMass = true
	vf.Parent = root

	local gravityForce = workspace.Gravity * root.AssemblyMass
	slowFactor = slowFactor or 1

	vf.Force = Vector3.new(0, -gravityForce * slowFactor, 0)

	if duration then
		task.delay(duration, function()
			if vf and vf.Parent then vf:Destroy() end
			if att and att.Parent then att:Destroy() end
		end)
	end

	return vf, att
end

-- Handles the special void death zone behavior
local function bindZone_VoidDeath()
	local zone = Zone.fromParts({ Z_VoidDeath })

	zone:ListenTo("Player", "Entered", function(player)
		print(player.Name .. " entered VoidDeathZone")

		local Character = player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then return end

		player:SetAttribute("IsInVoidDeath", true)
		forcePlayerFallStraight(player, 1, -2)
		Humanoid.Health = 0
	end)

	zone:BindToHeartbeat()
end

local function Teleport_Back_On_Obby_Fail(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local Humanoid = character and character:FindFirstChild("Humanoid")
	if not (character and root and Humanoid) then return end

	PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:DisableMovement()

	RespawnZoomOutCameraEvent:FireClient(player, true)
	forcePlayerFallStraight(player, 1, -2)

	-- Create highlight and VFX for teleport out
	local highlight = createHighlight(character, 1)

	local vfxPart = createVFXPart("TeleportVFXPart", root.Position + Vector3.new(0, -5, 0))
	local conn = RunService.Heartbeat:Connect(function()
		if root and root.Parent then
			vfxPart.Position = root.Position + Vector3.new(0, -5, 0)
		end
	end)

	local vfx1, vfx2 = createVFXEmitters(vfxPart, 0, 0.3)

	-- Fade in effects
	tweenHighlight(highlight, 0.4, 0, 0):Play()
	tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

	task.delay(0.6, function()
		-- Make character invisible
		setCharacterTransparency(character, 1)

		-- Fade out VFX
		tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

		task.delay(0.2, function()
			-- Teleport to destination
			character:MoveTo(ZoneSpawnMap.MountHolloCaveZone.Position + Vector3.new(0, 5, 0))
			root.Anchored = true

			-- Reset and play VFX at destination
			vfx1.Rate, vfx2.Rate = 0, 0
			vfx1.TimeScale, vfx2.TimeScale = 0.3, 0.3
			tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

			task.delay(0.2, function()
				root.Anchored = false

				-- Fade character back in
				setCharacterTransparency(character, 0, 0.5)
			end)

			task.delay(0.5, function()
				RespawnZoomOutCameraEvent:FireClient(player, false)

				-- Fade out all effects
				tweenHighlight(highlight, 0.2, 1, 1):Play()
				tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

				task.delay(0.5, function()
					PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:EnableMovement()
					if vfxPart then vfxPart:Destroy() end
					if conn then conn:Disconnect() end
				end)
			end)
		end)
	end)
end

local function bindZone_ObbyTeleport()
	local zoneParts = Z_ObbyTeleport:GetChildren()
	if #zoneParts == 0 then return end

	local zone = Zone.fromParts(zoneParts)

	zone:ListenTo("Player", "Entered", function(player: Player)
		-- Check if player is in obby via bindable event
		local inObby = IsPlayerInObby:Invoke(player)
		if not inObby then
			return
		end

		-- Check if player still has attempts via bindable event
		local stillHasAttempts = PlayerLostAttempt:Invoke(player)

		if stillHasAttempts == false then
			ObbyPlayerTeleportLocation[player] = nil
			Teleport_Back_On_Obby_Fail(player)
			
			OnObbyFail:FireClient(player)
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local Humanoid = character and character:FindFirstChild("Humanoid")
		if not (character and root and Humanoid) then return end

		PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:DisableMovement()

		RespawnZoomOutCameraEvent:FireClient(player, true)
		forcePlayerFallStraight(player, 1, -2)

		-- Create highlight and VFX for teleport out
		local highlight = createHighlight(character, 1)

		local vfxPart = createVFXPart("TeleportVFXPart", root.Position + Vector3.new(0, -5, 0))
		local conn = RunService.Heartbeat:Connect(function()
			if root and root.Parent then
				vfxPart.Position = root.Position + Vector3.new(0, -5, 0)
			end
		end)

		local vfx1, vfx2 = createVFXEmitters(vfxPart, 0, 0.3)

		-- Fade in effects
		tweenHighlight(highlight, 0.4, 0, 0):Play()
		tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

		task.delay(0.6, function()
			-- Make character invisible
			setCharacterTransparency(character, 1)

			-- Fade out VFX
			tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

			task.delay(0.2, function()
				local targetPosition
				-- Teleport to destination
				if ObbyPlayerTeleportLocation[player] then
					targetPosition = ObbyPlayerTeleportLocation[player].Spawn.Position + Vector3.new(0, 15, 0)
				else
					targetPosition = ObbyStartSpawn.Position + Vector3.new(0, 15, 0)
				end
				
				character:MoveTo(targetPosition)
				root.Anchored = true

				-- Reset and play VFX at destination
				vfx1.Rate, vfx2.Rate = 0, 0
				vfx1.TimeScale, vfx2.TimeScale = 0.3, 0.3
				tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

				task.delay(0.2, function()
					root.Anchored = false
					forcePlayerFallStraight(player, 0.5, -1.5)

					-- Fade character back in
					setCharacterTransparency(character, 0, 0.5)
				end)

				task.delay(0.5, function()
					RespawnZoomOutCameraEvent:FireClient(player, false)

					-- Fade out all effects
					tweenHighlight(highlight, 0.2, 1, 1):Play()
					tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

					task.delay(0.5, function()
						PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:EnableMovement()
						if vfxPart then vfxPart:Destroy() end
						if conn then conn:Disconnect() end
					end)
				end)
			end)
		end)
	end)

	zone:BindToHeartbeat()
end



local function bindZones_ObbyLevels()
	for _, obj in ipairs(ObbyLevelsFolder:GetDescendants()) do
		if not obj:IsA("BasePart") then continue end
		if not CollectionService:HasTag(obj, "O_Spawn") then continue end

		local level = tonumber(obj.Name:match("LV(%d+)_Spawn"))
		if not level then
			warn("[Obby] Invalid spawn name:", obj.Name)
			continue
		end

		local zone = Zone.fromParts({ obj })

		zone:ListenTo("Player", "Entered", function(player)
			warn("entered zone number " .. level .. " for " .. player.Name)
			-- Check via bindable event instead of Obby_Service
			if not IsPlayerInObby:Invoke(player) then
				return
			end

			local current = ObbyPlayerTeleportLocation[player]

			if not current then
				if level ~= 1 then return end

				ObbyPlayerTeleportLocation[player] = { Level = 1, Spawn = obj }
				PlayerReachedNewLevel:Fire(player)
				return
			end

			if level ~= current.Level + 1 then
				return
			end

			ObbyPlayerTeleportLocation[player] = { Level = level, Spawn = obj }
			PlayerReachedNewLevel:Fire(player)
			
			-- sets the client platforms color on reaching new level
			OnObbyNewLevel:FireClient(player, level)
			
		end)

		zone:BindToHeartbeat()
	end
end





local function teleportToSpawn(player: Player, zoneName: string?)
	local zonePart = ZoneSpawnMap[zoneName or DEFAULT_ZONE_NAME]
	if not zonePart or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	player.Character:MoveTo(zonePart.Position + Vector3.new(0, 3, 0))
end

local function bindZone(zoneName: string, parts: { BasePart })
	local zone = Zone.fromParts(parts)

	zone:ListenTo("Player", "Entered", function(player)
		PlayersCurrentLocation[player] = zoneName
		print(player.Name .. " entered " .. zoneName)
	end)

	zone:ListenTo("Player", "Exited", function(player)
		print(player.Name .. " left " .. zoneName)
	end)

	zone:BindToHeartbeat()
end

local function setupZones()
	local MultiPartZones = {
		CastleCenterZone = { Z_CastleCenter, Z_CastleCenter2 },
		CastleCenterCrowsRoadZone = { Z_CastleCenterCrowsRoad, Z_CastleCenterCrowsRoad2 },
		HolloCaveZone = { Z_HolloCave },
		MountHolloCaveZone = { Z_MountHolloCave },
		ThroneHallZone = { Z_ThroneHall },
	}

	for zoneName, parts in pairs(MultiPartZones) do
		bindZone(zoneName, parts)
	end

	bindZone_VoidDeath()
	bindZone_ObbyTeleport()
	bindZones_ObbyLevels()
end

local function applyDeathVFX(player, Char)
	local onRespawnVFX = script:WaitForChild("OnSpawnVFX")

	for _, part in ipairs(Char:GetDescendants()) do
		if not part:IsA("BasePart") then continue end

		local highlight = createHighlight(part)

		FunctionUtils.Game.spawn(function()
			-- Fade out highlight
			tweenHighlight(highlight, 1, 1, 1):Play()

			task.delay(0.5, function()
				-- Create VFX part for this body part
				local vfxPart = createVFXPart("DeathVFXPart", part.Position)

				local conn = RunService.Heartbeat:Connect(function()
					if part and part.Parent then
						vfxPart.Position = part.Position
					end
				end)

				-- Create emitters
				local vfx1, vfx2 = createVFXEmitters(vfxPart, 0, 0.1)
				vfx1:Emit(1)
				vfx2:Emit(1)

				-- Tween emitters to full speed
				tweenVFXEmitters(vfx1, vfx2, 1, 50, 1)

				task.delay(1, function()
					-- Fade out body part
					local fadeTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					TweenService:Create(part, fadeTweenInfo, { Transparency = 1 }):Play()

					-- Fade decals on head
					if part.Name == "Head" then
						for _, decal in ipairs(part:GetDescendants()) do
							if decal:IsA("Decal") or decal:IsA("Texture") then
								TweenService:Create(decal, fadeTweenInfo, { Transparency = 1 }):Play()
							end
						end
					end

					-- Fade out VFX
					tweenVFXEmitters(vfx1, vfx2, 1, 0, 0.3)

					task.delay(1.01, function()
						if vfxPart then vfxPart:Destroy() end
						if conn then conn:Disconnect() end
					end)
				end)
			end)
		end)
	end
end

local function SpawnPlayer(Character)
	if not Character then return end

	local root = Character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	local humanoid = Character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Use the unified spawn VFX function
	playSpawnVFX(Character)
end

local function onPlayerAdded(player: Player)
	PlayersCurrentLocation[player] = DEFAULT_ZONE_NAME

	player.CharacterAdded:Connect(function(Char)
		task.wait()

		if player:GetAttribute("IsInVoidDeath") then
			teleportToSpawn(player, "MountHolloCenterZone")
			player:SetAttribute("IsInVoidDeath", nil)
		else
			local zoneName = PlayersCurrentLocation[player] or DEFAULT_ZONE_NAME
			teleportToSpawn(player, zoneName)
		end

		SpawnPlayer(Char)

		local humanoid = Char:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				applyDeathVFX(player, Char)
			end)
		end
	end)

	player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			PlayersCurrentLocation[player] = nil
		end
	end)
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

function Module.Teleport_To_Obby(player:Player)
	-- if Destination nil, means player started obby so start platform destination
	
	ObbyPlayerTeleportLocation[player] = {
		Level = 1,
		Spawn = ObbyStartSpawn
	}

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local Humanoid = character and character:FindFirstChild("Humanoid")
	if not (character and root and Humanoid) then return end

	PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:DisableMovement()

	local vfxPart = createVFXPart("TeleportVFXPart", root.Position + Vector3.new(0, -5, 0))
	local conn = RunService.Heartbeat:Connect(function()
		if root and root.Parent then
			vfxPart.Position = root.Position + Vector3.new(0, -5, 0)
		end
	end)

	local vfx1, vfx2 = createVFXEmitters(vfxPart, 0, 0.3)

	-- Fade in effects
	tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

	task.delay(0.6, function()
		-- Make character invisible
		setCharacterTransparency(character, 1)

		-- Fade out VFX
		tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

		task.delay(0.2, function()
			-- Teleport to destination
			
			local targetPosition = ObbyStartSpawn.Position + Vector3.new(0, 15, 0)
			character:MoveTo(targetPosition)
			root.Anchored = true

			-- Reset and play VFX at destination
			vfx1.Rate, vfx2.Rate = 0, 0
			vfx1.TimeScale, vfx2.TimeScale = 0.3, 0.3
			tweenVFXEmitters(vfx1, vfx2, 0.6, 300, 1)

			task.delay(0.2, function()
				root.Anchored = false
				-- Fade character back in
				setCharacterTransparency(character, 0, 0.5)
			end)

			task.delay(0.5, function()

				-- Fade out all effects
				tweenVFXEmitters(vfx1, vfx2, 0.2, 0, 0.3)

				task.delay(0.5, function()
					PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:EnableMovement()
					if vfxPart then vfxPart:Destroy() end
					if conn then conn:Disconnect() end
				end)
			end)
		end)
	end)
end

-----------------------------
-- MAIN --
-----------------------------
function Module.Init()
	setupZones()

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		PlayersCurrentLocation[player] = nil
	end)

	print("[ZoneLocationService] Initialized successfully.")
	return true
end

return Module