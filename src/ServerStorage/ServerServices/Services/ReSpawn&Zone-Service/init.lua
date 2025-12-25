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

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Zone = require(ReplicatedStorage.Utilities.ModuleUtils._Zone)
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)
local RespawnZoomOutCameraEvent = ReplicatedStorage.Events.Motion.RespawnZoomOutCamera

local PlayerService = require(ServerStorage.ServerServices.Services["Player-Service"])

local SpawnPartsFolder = workspace:WaitForChild("SpawnParts")
local MapZonesDetectorsFolder = workspace:WaitForChild("MapZonesDetectors")

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}
local PlayersCurrentLocation: { [Player]: string } = {}

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
-- PRIVATE FUNCTIONS --
-----------------------------

-- Handles the special void death zone behavior
local function bindZone_VoidDeath()
	local zone = Zone.fromParts({ Z_VoidDeath })

	zone:ListenTo("Player", "Entered", function(player)
		print(player.Name .. " entered VoidDeathZone")

		local Character = player.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then return end

		player:SetAttribute("IsInVoidDeath", true)
		Humanoid.Health = 0
	end)

	zone:BindToHeartbeat()
end

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

local function bindZone_ObbyTeleport()
	local zoneParts = Z_ObbyTeleport:GetChildren()
	if #zoneParts == 0 then return end

	local zone = Zone.fromParts(zoneParts)

	zone:ListenTo("Player", "Entered", function(player: Player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local Humanoid = character and character:FindFirstChild("Humanoid")
		if not (character and root and Humanoid) then return end
		
		PlayerService.getPlayerHandler().getCredentails(player).AbilitiesClass:DisableMovement()

		RespawnZoomOutCameraEvent:FireClient(player, true)
		forcePlayerFallStraight(player, 1, -2)

		local onSpawnVFX = script.OnSpawnVFX
		local highlight = onSpawnVFX.Highlight:Clone()
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 1
		highlight.Parent = character

		local vfxPart = Instance.new("Part")
		vfxPart.Anchored = true
		vfxPart.CanCollide = false
		vfxPart.CanQuery = false
		vfxPart.CanTouch = false
		vfxPart.Transparency = 1
		vfxPart.Size = Vector3.new(3, 3, 3)
		vfxPart.Orientation = Vector3.new(0, 0, 90)
		vfxPart.Name = "TeleportVFXPart"
		vfxPart.Parent = workspace

		local conn
		conn = RunService.Heartbeat:Connect(function()
			vfxPart.Position = root.Position + Vector3.new(0, -5, 0)
		end)

		local vfx1 = onSpawnVFX.Line1:Clone()
		local vfx2 = onSpawnVFX.Line2:Clone()
		vfx1.Rate, vfx2.Rate = 0, 0
		vfx1.TimeScale, vfx2.TimeScale = 0.3, 0.3
		vfx1.Parent, vfx2.Parent = vfxPart, vfxPart

		local fadeInTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local hlTween = TweenService:Create(highlight, fadeInTweenInfo, {
			FillTransparency = 0,
			OutlineTransparency = 0,
		})
		hlTween:Play()

		local vfxTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(vfx1, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()
		TweenService:Create(vfx2, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()

		task.delay(0.6, function()
			local fadeOutTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part.Transparency = 1
				elseif part:IsA("Accessory") then
					local handle = part:FindFirstChild("Handle")
					if handle then handle.Transparency = 1 end
				end
			end

			TweenService:Create(vfx1, fadeOutTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()
			TweenService:Create(vfx2, fadeOutTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()

			task.delay(0.2, function()
				local targetPosition = S_MountHolloCave_OnRespawn.Position + Vector3.new(0, 15, 0)
				character:MoveTo(targetPosition)
				root.Anchored = true

				vfx1.Rate, vfx2.Rate = 0, 0
				vfx1.TimeScale, vfx2.TimeScale = 0.3, 0.3

				TweenService:Create(vfx1, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()
				TweenService:Create(vfx2, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()

				task.delay(0.2, function()
					root.Anchored = false
					forcePlayerFallStraight(player, 0.5, -1.5)

					local fadeInCharacterTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							local targetTransparency = part.Name == "HumanoidRootPart" and 1 or 0
							TweenService:Create(part, fadeInCharacterTweenInfo, { Transparency = targetTransparency }):Play()
						elseif part:IsA("Decal") then
							TweenService:Create(part, fadeInCharacterTweenInfo, { Transparency = 0 }):Play()
						elseif part:IsA("Accessory") then
							local handle = part:FindFirstChild("Handle")
							if handle then
								TweenService:Create(handle, fadeInCharacterTweenInfo, { Transparency = 0 }):Play()
							end
						end
					end
				end)

				task.delay(0.5, function()
					RespawnZoomOutCameraEvent:FireClient(player, false)

					local destFadeOutTween = TweenService:Create(highlight, fadeOutTweenInfo, {
						FillTransparency = 1,
						OutlineTransparency = 1,
					})
					destFadeOutTween:Play()

					TweenService:Create(vfx1, fadeOutTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()
					TweenService:Create(vfx2, fadeOutTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()

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
end

local function applyDeathVFX(player, Char)
	local onRespawnVFX = script:WaitForChild("OnSpawnVFX")

	for _, part in ipairs(Char:GetDescendants()) do
		if not part:IsA("BasePart") then continue end

		local Vfx1_Clone = onRespawnVFX.Line1:Clone()
		local Vfx2_Clone = onRespawnVFX.Line2:Clone()
		local HighlightClone = onRespawnVFX.Highlight:Clone()
		HighlightClone.Parent = part

		FunctionUtils.Game.spawn(function()
			local highlightTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(HighlightClone, highlightTweenInfo, {
				FillTransparency = 1,
				OutlineTransparency = 1,
			}):Play()

			task.delay(0.5, function()
				local vfxPart = Instance.new("Part")
				vfxPart.Anchored = true
				vfxPart.CanCollide = false
				vfxPart.CanQuery = false
				vfxPart.CanTouch = false
				vfxPart.Transparency = 1
				vfxPart.Size = Vector3.new(3, 3, 3)
				vfxPart.Position = part.Position
				vfxPart.Orientation = Vector3.new(0, 0, 90)
				vfxPart.Name = "DeathVFXPart"
				vfxPart.Parent = workspace

				local conn
				conn = RunService.Heartbeat:Connect(function()
					if part and part.Parent then
						vfxPart.Position = part.Position
					end
				end)

				local emitters = {}
				Vfx1_Clone.TimeScale = 0.1
				Vfx2_Clone.TimeScale = 0.1
				Vfx1_Clone.Parent = vfxPart
				Vfx2_Clone.Parent = vfxPart

				Vfx1_Clone:Emit(1)
				Vfx2_Clone:Emit(1)

				table.insert(emitters, Vfx1_Clone)
				table.insert(emitters, Vfx2_Clone)

				for _, emitter in ipairs(emitters) do
					TweenService:Create(emitter, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						TimeScale = 1,
					}):Play()
				end

				task.delay(1, function()
					local fadeTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					TweenService:Create(part, fadeTweenInfo, { Transparency = 1 }):Play()

					if part.Name == "Head" then
						for _, decal in ipairs(part:GetDescendants()) do
							if decal:IsA("Decal") or decal:IsA("Texture") then
								TweenService:Create(decal, fadeTweenInfo, { Transparency = 1 }):Play()
							end
						end
					end

					for _, emitter in ipairs(emitters) do
						TweenService:Create(emitter, fadeTweenInfo, { Rate = 0 }):Play()
					end

					task.delay(1.01, function()
						if vfxPart then vfxPart:Destroy() end
						if conn then conn:Disconnect() end
					end)
				end)
			end)
		end)
	end
end

local function SpawnPlayer(player, Character)
	if not Character then return end

	local root = Character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	local humanoid = Character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local onSpawnVFX = script.OnSpawnVFX
	local highlight = onSpawnVFX.Highlight:Clone()
	highlight.FillTransparency = 0
	highlight.OutlineTransparency = 0
	highlight.Parent = Character

	local vfxPart = Instance.new("Part")
	vfxPart.Anchored = true
	vfxPart.CanCollide = false
	vfxPart.CanQuery = false
	vfxPart.CanTouch = false
	vfxPart.Transparency = 1
	vfxPart.Size = Vector3.new(3, 3, 3)
	vfxPart.Orientation = Vector3.new(0, 0, 90)
	vfxPart.Name = "SpawnVFXPart"
	vfxPart.Parent = workspace

	local conn
	conn = RunService.Heartbeat:Connect(function()
		vfxPart.Position = root.Position + Vector3.new(0, -1, 0)
	end)

	local vfx1 = onSpawnVFX.Line1:Clone()
	local vfx2 = onSpawnVFX.Line2:Clone()
	vfx1.Rate, vfx2.Rate = 100, 100
	vfx1.TimeScale, vfx2.TimeScale = 0.1, 0.1
	vfx1.Parent, vfx2.Parent = vfxPart, vfxPart
	vfx1:Emit(1)
	vfx2:Emit(1)

	local vfxTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(vfx1, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()
	TweenService:Create(vfx2, vfxTweenInfo, { Rate = 300, TimeScale = 1 }):Play()

	local fadeInTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(highlight, fadeInTweenInfo, {
		FillTransparency = 0,
		OutlineTransparency = 0,
	}):Play()

	task.delay(1, function()
		local hlTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(highlight, hlTweenInfo, {
			FillTransparency = 1,
			OutlineTransparency = 1,
		}):Play()

		local fadeTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(vfx1, fadeTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()
		TweenService:Create(vfx2, fadeTweenInfo, { Rate = 0, TimeScale = 0.3 }):Play()

		task.delay(1, function()
			if vfxPart then vfxPart:Destroy() end
			if conn then conn:Disconnect() end
		end)
	end)
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

		SpawnPlayer(player, Char)

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
