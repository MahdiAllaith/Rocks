--strict
--@author: 
--@date: 
--[[@description:
	A Service hybrid handler for all client input manager for (UI, Motion, Interaction) services.
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local ObbyFolder = workspace:WaitForChild("Area").Obby

local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)
local Notification_Service = require(script["Notification-Service"])


-----------------------------
-- Events --
-----------------------------
local StartGrandChallageEvent = ReplicatedStorage.Events.Obby.StartGrandChallenge
local OnObbyNewLevelEvent = ReplicatedStorage.Events.Obby.OnObbyNewLevel
local OnObbyFail = ReplicatedStorage.Events.Obby.OnObbyFail

local NotificationEvent = ReplicatedStorage.Events.Player.Notification
local GainNotificationEvent = ReplicatedStorage.Events.Player.GainNotification

-----------------------------
-- TYPES --
-----------------------------


-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

local blueColor = Color3.fromHex("0088ff")
local whiteColor = Color3.new(1, 1, 1)


-- CONSTANTS --
local LOCAL_PLAYER = game.Players.LocalPlayer

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function setAllObbyPlatformsOnStart()
	-- Get all particle emitters with the tag "Obby_PE_Color"
	local obbyParticleEmitters = CollectionService:GetTagged("Obby_PE_Color")

	local blueColor = Color3.fromHex("0088ff")
	local whiteColor = Color3.new(1, 1, 1) -- White color

	for _, particleEmitter in ipairs(obbyParticleEmitters) do
		if particleEmitter:IsA("ParticleEmitter") then
			-- Check if it uses a single Color property
			if particleEmitter.Color == ColorSequence.new(blueColor) then
				particleEmitter.Color = ColorSequence.new(whiteColor)
			else
				-- Handle ColorSequence with multiple keypoints
				local currentSequence = particleEmitter.Color
				local newKeypoints = {}

				for i, keypoint in ipairs(currentSequence.Keypoints) do
					if keypoint.Value == blueColor then
						-- Replace blue with white
						table.insert(newKeypoints, ColorSequenceKeypoint.new(keypoint.Time, whiteColor))
					else
						-- Keep the original keypoint
						table.insert(newKeypoints, keypoint)
					end
				end

				particleEmitter.Color = ColorSequence.new(newKeypoints)
			end
		end
	end

	-- Get all parts with the tag "Obby_Level_logo"
	local obbyLevelLogos = CollectionService:GetTagged("Obby_Level_Logo")

	for _, logo in ipairs(obbyLevelLogos) do
		if logo:IsA("BasePart") then
			logo.Color = whiteColor
		end
	end
end

local function resetAllObbyPlatformsToDefault()
	-- Restore ParticleEmitters
	for _, particleEmitter in ipairs(CollectionService:GetTagged("Obby_PE_Color")) do
		if particleEmitter:IsA("ParticleEmitter") then
			local seq = particleEmitter.Color
			local newKeypoints = {}

			for _, keypoint in ipairs(seq.Keypoints) do
				local color = keypoint.Value
				if color == whiteColor then
					color = blueColor
				end
				table.insert(newKeypoints, ColorSequenceKeypoint.new(keypoint.Time, color))
			end

			particleEmitter.Color = ColorSequence.new(newKeypoints)
		end
	end

	-- Restore 3D Spawn Logos
	for _, logo in ipairs(CollectionService:GetTagged("Obby_Level_Logo")) do
		if logo:IsA("BasePart") then
			logo.Color = Color3.new(0, 0, 0)
		end
	end
end

local function setObbyLevelActive(levelNumber: number)
	local levelFolder = ObbyFolder:FindFirstChild("Level" .. levelNumber)
	if not levelFolder then
		warn("[Obby] Level folder not found:", levelNumber)
		return
	end

	for _, obj in ipairs(levelFolder:GetDescendants()) do
		-- Particle Emitters (platforms)
		if obj:IsA("ParticleEmitter") and CollectionService:HasTag(obj, "Obby_PE_Color") then
			local newKeypoints = {}

			for _, kp in ipairs(obj.Color.Keypoints) do
				table.insert(
					newKeypoints,
					ColorSequenceKeypoint.new(kp.Time, blueColor)
				)
			end

			obj.Color = ColorSequence.new(newKeypoints)

			-- Level logo
		elseif obj:IsA("BasePart") and CollectionService:HasTag(obj, "Obby_Level_Logo") then
			obj.Color = Color3.new(0, 0, 0)
		end
	end
end

local function setObbyNewLevelVFX()
	local VFX_Part = script:WaitForChild("ReachNewObbyLevelVFX"):Clone()
	VFX_Part.Parent = workspace

	local RootPart = LOCAL_PLAYER.Character:WaitForChild("HumanoidRootPart")
	VFX_Part.CFrame = RootPart.CFrame

	-- Collect all ParticleEmitters under attachments
	local emitters = {}
	for _, descendant in ipairs(VFX_Part:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			table.insert(emitters, {
				emitter = descendant,
				originalRate = descendant.Rate
			})
			descendant.Enabled = true
		end
	end

	-- Play sound
	local sound = FunctionUtils.Game.playSound({
		SoundId = "rbxassetid://128215992860444",
		Volume = 0.5,
		RollOffMode = Enum.RollOffMode.InverseTapered,
		MinDistance = 10,
		MaxDistance = 10,
		Looped = false
	}, RootPart)

	-- After 0.5s, tween emitter rates to 0
	task.delay(0.5, function()
		local remainingTime = math.max((sound.TimeLength > 0 and sound.TimeLength or 2) - 0.5, 0)

		for _, data in ipairs(emitters) do
			local tween = TweenService:Create(
				data.emitter,
				TweenInfo.new(
					remainingTime,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				),
				{ Rate = 0 }
			)
			tween:Play()
		end
	end)

	-- Cleanup when sound ends
	sound.Ended:Once(function()
		VFX_Part:Destroy()
	end)
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function Module.StartGrandChallange()
	task.wait(0.5) -- wait for the intraction ui to disapper
	StartGrandChallageEvent:FireServer()
	setAllObbyPlatformsOnStart()
end

-----------------------------
-- MAIN --
-----------------------------
function Module.Init()
	OnObbyNewLevelEvent.OnClientEvent:Connect(function(level:number)
		if level ~= nil then
			setObbyLevelActive(level)
			setObbyNewLevelVFX()
		end
		
	end)
	
	OnObbyFail.OnClientEvent:Connect(function()
		resetAllObbyPlatformsToDefault()
	end)
	
	NotificationEvent.OnClientEvent:Connect(function(Text:string)
		Notification_Service.ShowTextNotification(Text)
	end)
	
	GainNotificationEvent.OnClientEvent:Connect(function(Xp:number, Coins:number)
		Notification_Service.ShowGainIndicator(Xp, Coins)
	end)
	
	return true
end

return Module
