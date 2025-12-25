--optimized & used Version
local Module = {}

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicateTiltEvent = script:WaitForChild("ReplicateTilt-Event")

local TILT_TAG = "Tilt_Tag"

Utils = require(script["Tilt-Utils"])

local FUtilies = require(game.ReplicatedStorage.Utilities.FunctionUtils)
local MUtilies = require(game.ReplicatedStorage.Utilities.ModuleUtils)

-- Update attribute for passed motor6D hence notify client via attribute change in init function
function Module.SetTargetRotation(motor, rotationData)
    if RunService:IsServer() then
        -- rotationData expected as Vector3 (or compressed buffer)
        local rotationVector
        if FUtilies.t.buffer(rotationData) then
            rotationVector = Utils.bufferVectorDecomp(rotationData)
        else
            rotationVector = rotationData
        end

        if typeof(rotationVector) ~= "Vector3" then
            return warn("SetTargetRotation: bad rotation type", typeof(rotationVector))
        end

        if motor and motor:IsA("Motor6D") and motor.Name == "Neck" then
            motor:SetAttribute("TargetC0Rot", rotationVector)
        end
    else
        -- Client: send compressed vector (or raw Vector3) to server
        replicateTiltEvent:FireServer(motor, rotationData)
    end
end

function Module.Init()

	if RunService:IsServer() then
		-- SERVER-SIDE: Handle client requests and update attributes
		replicateTiltEvent.OnServerEvent:Connect(function(player, motor, rotationData)
			if not motor:IsA("Motor6D") or motor.Name ~= "Neck" then 
				return warn("Bad Motor6D") 
			end

			if not motor:HasTag(TILT_TAG) then
				return warn("Motor ineligible for tilt")
			end

			-- Handle buffer data
			local rotationVector
			if FUtilies.t.buffer(rotationData) then
				rotationVector = Utils.bufferVectorDecomp(rotationData)
			else
				return warn("Bad rotation data type:", typeof(rotationData))
			end

			if not Utils.IsOwnMotor6D(player, motor) then 
				return warn("Does not own motor")
			end

			-- Update the attribute (this replicates to all clients)
			Module.SetTargetRotation(motor, Utils.bufferVectorComp(rotationVector))
		end)

		-- Tag neck motor6D when characters spawn
		local function onCharacterAdded(character)
			local neck = character:FindFirstChild("Neck", true)
			if neck and neck:IsA("Motor6D") then
				CollectionService:AddTag(neck, TILT_TAG)
			else
				warn("Neck is missing or not Motor6D for", character.Name)
			end
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(onCharacterAdded)
			if player.Character then 
				task.spawn(onCharacterAdded, player.Character) 
			end
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(onPlayerAdded, player)
		end

	else
		-- CLIENT: handle local and other players
		local player = Players.LocalPlayer
		local Spring = MUtilies.Spring

		local localConnections = {}

		local function cleanupLocal()
			for _, conn in pairs(localConnections) do
				if typeof(conn) == "RBXScriptConnection" then
					conn:Disconnect()
				end
			end
			table.clear(localConnections)
		end

		local function setupLocalCharacter(character)
			cleanupLocal()
			local humanoid = character:WaitForChild("Humanoid")
			local hrp = character:WaitForChild("HumanoidRootPart")
			local neck = character:FindFirstChild("Neck", true)
			if not neck or not neck:IsA("Motor6D") then
				warn("Local: no neck found")
				return
			end

			local YOffset = neck.C0.Y
			local yawSpring = Spring.new(0, 1, 12)
			local pitchSpring = Spring.new(0, 1, 12)

			local function wrapToPi(a)
				return (a + math.pi) % (2*math.pi) - math.pi
			end

			local UPDATE_RATE = 1/20
			local lastUpdate = 0
			local lastSentRotation = Vector3.new(0,0,0)
			local ROTATION_THRESHOLD = 0.05

			local function onTargetChanged()
				local newTarget = neck:GetAttribute("TargetC0Rot")
				if newTarget and typeof(newTarget) == "Vector3" then
					yawSpring.Target = newTarget.Y
					pitchSpring.Target = newTarget.X
				end
			end

			table.insert(localConnections, neck:GetAttributeChangedSignal("TargetC0Rot"):Connect(onTargetChanged))
			onTargetChanged()

			local function updateHead()
				if not neck.Parent then
					cleanupLocal()
					return
				end

				local camera = workspace.CurrentCamera
				if not camera then return end
				
				local head = character:FindFirstChild("Head")
				if not head or not head:IsA("BasePart") then
					return
				end

				local dirWorld = (camera.CFrame.Position - head.Position)
				if dirWorld.Magnitude == 0 then return end
				local dirLocal = hrp.CFrame:VectorToObjectSpace(dirWorld.Unit)

				local angleY = math.atan2(dirLocal.X, dirLocal.Z)
				local yaw = dirLocal.Z >= 0 and angleY or -wrapToPi(angleY + math.pi)
				local pitch = math.asin(-math.clamp(dirLocal.Y, -1, 1))

				yaw = math.clamp(yaw, -math.pi/2, math.pi/2)
				pitch = math.clamp(pitch, -math.pi/2, math.pi/2)

				yawSpring.Target = yaw
				pitchSpring.Target = pitch

				neck.C0 = CFrame.new(0, YOffset, 0)
					* CFrame.Angles(0, yawSpring.Position, 0)
					* CFrame.Angles(pitchSpring.Position, 0, 0)

				local rotationVector = Vector3.new(pitchSpring.Position, yawSpring.Position, 0)
				local now = tick()
				if now - lastUpdate >= UPDATE_RATE then
					if (rotationVector - lastSentRotation).Magnitude >= ROTATION_THRESHOLD then
						Module.SetTargetRotation(neck, Utils.bufferVectorComp(rotationVector))
						lastSentRotation = rotationVector
					end
					lastUpdate = now
				end
			end

			table.insert(localConnections, RunService.RenderStepped:Connect(updateHead))
			table.insert(localConnections, neck.Destroying:Connect(cleanupLocal))
			table.insert(localConnections, character.AncestryChanged:Connect(function(_, parent)
				if not parent then cleanupLocal() end
			end))
		end

		local function setupOtherCharacter(character)
			local humanoid = character:WaitForChild("Humanoid")
			local neck = character:FindFirstChild("Neck", true)
			if not neck or not neck:IsA("Motor6D") then return end

			local YOffset = neck.C0.Y
			local yawSpring = Spring.new(0,1,12)
			local pitchSpring = Spring.new(0,1,12)

			local function onTargetChanged()
				local newTarget = neck:GetAttribute("TargetC0Rot")
				if newTarget and typeof(newTarget) == "Vector3" then
					yawSpring.Target = newTarget.Y
					pitchSpring.Target = newTarget.X
				end
			end

			neck:GetAttributeChangedSignal("TargetC0Rot"):Connect(onTargetChanged)
			onTargetChanged()

			RunService.RenderStepped:Connect(function()
				if not neck.Parent then return end
				neck.C0 = CFrame.new(0, YOffset, 0) 
					* CFrame.Angles(0, yawSpring.Position, 0) 
					* CFrame.Angles(pitchSpring.Position, 0, 0)
			end)
		end

		-- Setup local player
		if player.Character then
			task.spawn(setupLocalCharacter, player.Character)
		end
		player.CharacterAdded:Connect(setupLocalCharacter)

		-- Setup other players
		local function setupOtherPlayer(otherPlayer)
			if otherPlayer == player then return end
			local function onCharacterAdded(character)
				setupOtherCharacter(character)
			end
			otherPlayer.CharacterAdded:Connect(onCharacterAdded)
			if otherPlayer.Character then
				task.spawn(onCharacterAdded, otherPlayer.Character)
			end
		end

		Players.PlayerAdded:Connect(setupOtherPlayer)
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			task.spawn(setupOtherPlayer, otherPlayer)
		end
	end

	return true
end

return Module





-- old code
--local Module = {}

--local RunService = game:GetService("RunService")
--local CollectionService = game:GetService("CollectionService")
--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local replicateTilt = script:WaitForChild("ReplicateTilt-Event")
--local TILT_TAG = "Tilt_Tag"

---- Utility
--local function IsOwnMotor6D(player, motor)
--	if not player.Character then return false end
--	return motor:IsDescendantOf(player.Character)
--end

--local function IsBadCFrame(cf)
--	if typeof(cf) ~= "CFrame" then return false end
--	for _, v in ipairs({cf:GetComponents()}) do
--		if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
--			return false
--		end
--	end
--	return true
--end

---- Replication API
--function Module.SetTargetRotation(motor, c0)
--	if RunService:IsServer() then
--		local rot = Vector3.new(c0:ToOrientation())
--		if motor.Name == "Neck" then
--			motor:SetAttribute("TargetC0Rot", rot)
--		end
--	else
--		replicateTilt:FireServer(motor, c0)
--	end
--end

---- Tag observing
--local function observeTag(tagName, onAdded, onRemoved)
--	CollectionService:GetInstanceAddedSignal(tagName):Connect(onAdded)
--	CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(inst)
--		if onRemoved then onRemoved(inst) end
--	end)

--	for _, inst in ipairs(CollectionService:GetTagged(tagName)) do
--		onAdded(inst)
--	end
--end

---- Main init
--function Module.Init()
--	if RunService:IsServer() then
--		-- Server: Validate and replicate tilt intent from clients
--		replicateTilt.OnServerEvent:Connect(function(player, motor, c0)
--			if not motor:IsA("Motor6D") or motor.Name ~= "Neck" then 
--				return warn("Bad Motor6D") 
--			end
--			if not CollectionService:HasTag(motor, TILT_TAG) then
--				return warn("Motor ineligible for tilt")
--			end
--			if not IsBadCFrame(c0) then
--				return warn("Bad CFrame") 
--			end
--			if not IsOwnMotor6D(player, motor) then 
--				return warn("Does not own motor")
--			end
--			Module.SetTargetRotation(motor, c0)
--		end)

--		-- Tag Neck motors
--		local function onCharacterAdded(character)
--			local neck = character:FindFirstChild("Neck", true)
--			if neck and neck:IsA("Motor6D") then
--				CollectionService:AddTag(neck, TILT_TAG)
--			else
--				warn("Neck missing or not Motor6D")
--			end
--		end

--		local function onPlayerAdded(player)
--			player.CharacterAdded:Connect(onCharacterAdded)
--			if player.Character then task.spawn(onCharacterAdded, player.Character) end
--		end

--		Players.PlayerAdded:Connect(onPlayerAdded)
--		for _, player in ipairs(Players:GetPlayers()) do
--			task.spawn(onPlayerAdded, player)
--		end

--	else
--		-- Client: Smoothly apply tilt based on `TargetC0Rot` attribute
--		local player = Players.LocalPlayer
--		local Spring = require(ReplicatedStorage.Services["Spring-Service"])
--		local CFNew, CFAng = CFrame.new, CFrame.Angles

--		observeTag(TILT_TAG, function(neck : Motor6D)
--			local character = neck:FindFirstAncestorOfClass("Model")
--			if not character then return end
--			local humanoid = character:FindFirstChildOfClass("Humanoid")
--			local hrp = character:FindFirstChild("HumanoidRootPart")
--			if not humanoid or not hrp then return end

--			local YOffset = neck.C0.Y
--			local yawSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)
--			local pitchSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)

--			-- Listen to TargetC0Rot attribute changes
--			local function updateFromAttribute()
--				local target = neck:GetAttribute("TargetC0Rot")
--				if typeof(target) == "Vector3" then
--					local x, y, z = target.X, target.Y, target.Z
--					pitchSpring:SetGoal(x)
--					yawSpring:SetGoal(y)
--				end
--			end

--			neck:GetAttributeChangedSignal("TargetC0Rot"):Connect(updateFromAttribute)
--			updateFromAttribute()

--			-- Smoothly update C0
--			RunService.Heartbeat:Connect(function(dt)
--				local pitch = pitchSpring and pitchSpring.Position or 0
--				local yaw = yawSpring and yawSpring.Position or 0

--				local newC0
--				if humanoid.RigType == Enum.HumanoidRigType.R15 then
--					newC0 = CFNew(0, YOffset, 0) * CFAng(0, yaw, 0) * CFAng(pitch, 0, 0)
--				elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
--					newC0 = CFNew(0, YOffset, 0) * CFAng(3 * math.pi/2, 0, math.pi) * CFAng(0, 0, yaw) * CFAng(-pitch, 0, 0)
--				end

--				if newC0 then
--					neck.C0 = newC0
--				end
--			end)
--		end)
--	end
--end

--return Module


--local Module = {}

--local RunService = game:GetService("RunService")
--local CollectionService = game:GetService("CollectionService")
--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local replicateTilt = script:WaitForChild("ReplicateTilt-Event")
--local TILT_TAG = "Tilt_Tag"

--function IsOwnMotor6D(player, motor)
--	if not player.Character then return false end
--	return motor:IsDescendantOf(player.Character)
--end

--function IsBadCFrame(cf)
--	if typeof(cf) ~= "CFrame" then return true end -- Fixed: should return true if bad
--	for _, v in ipairs({cf:GetComponents()}) do
--		if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
--			return true -- Fixed: should return true if bad
--		end
--	end
--	return false -- Fixed: return false if good
--end

--function Module.SetTargetRotation(motor, rotationVector)
--	if RunService:IsServer() then
--		-- Server: Update the attribute for replication
--		if motor.Name == "Neck" then
--			motor:SetAttribute("TargetC0Rot", rotationVector)
--		end
--	else
--		-- Client: Send to server (now sends Vector3 instead of CFrame)
--		replicateTilt:FireServer(motor, rotationVector)
--	end
--end

--local function observeTag(tagName, onAdded, onRemoved)
--	-- Connect added signal
--	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
--		onAdded(instance)
--	end)

--	-- Connect removed signal
--	CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
--		if onRemoved then
--			onRemoved(instance)
--		end
--	end)

--	-- Handle already-tagged instances
--	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
--		onAdded(instance)
--	end
--end

--function Module.Init()
--	if RunService:IsServer() then
--		-- SERVER-SIDE: Handle client requests and update attributes
--		replicateTilt.OnServerEvent:Connect(function(player, motor, rotationVector) -- Now receives Vector3

--			if not motor:IsA("Motor6D") or motor.Name ~= "Neck" then 
--				return warn("Bad Motor6D") 
--			end

--			if not motor:HasTag(TILT_TAG) then -- Fixed: using CollectionService correctly
--				return warn("Motor ineligible for tilt")
--			end

--			-- Validate Vector3 instead of CFrame
--			if typeof(rotationVector) ~= "Vector3" then
--				return warn("Bad rotation vector")
--			end

--			-- Clamp rotation values to prevent extreme rotations
--			local clampedRotation = Vector3.new(
--				math.clamp(rotationVector.X, -math.pi/2, math.pi/2), -- Pitch
--				math.clamp(rotationVector.Y, -math.pi/2, math.pi/2), -- Yaw  
--				math.clamp(rotationVector.Z, -math.pi/4, math.pi/4)  -- Roll
--			)

--			if not IsOwnMotor6D(player, motor) then 
--				return warn("Does not own motor")
--			end

--			-- Update the attribute (this replicates to all clients)
--			Module.SetTargetRotation(motor, clampedRotation)
--		end)

--		-- Tag neck motors when characters spawn
--		local function onCharacterAdded(character)
--			local neck = character:FindFirstChild("Neck", true)
--			if neck and neck:IsA("Motor6D") then
--				CollectionService:AddTag(neck, TILT_TAG)
--			else
--				warn("Neck is missing or not Motor6D for", character.Name)
--			end
--		end

--		local function onPlayerAdded(player)
--			player.CharacterAdded:Connect(onCharacterAdded)
--			if player.Character then 
--				task.spawn(onCharacterAdded, player.Character) 
--			end
--		end

--		Players.PlayerAdded:Connect(onPlayerAdded)
--		for _, player in ipairs(Players:GetPlayers()) do
--			task.spawn(onPlayerAdded, player)
--		end

--	else
--		-- CLIENT-SIDE: Calculate tilt and smooth interpolation
--		local player = Players.LocalPlayer
--		local Spring = require(ReplicatedStorage.Services["Spring-Service"])

--		local function setupCharacter(character)
--			local humanoid = character:WaitForChild("Humanoid")
--			local hrp = character:WaitForChild("HumanoidRootPart")
--			local neck = character:FindFirstChild("Neck", true)

--			if not neck or not neck:IsA("Motor6D") then 
--				warn("No valid neck found for", character.Name)
--				return 
--			end

--			local YOffset = neck.C0.Y
--			local CFNew, CFAng, asin = CFrame.new, CFrame.Angles, math.asin
--			local yawSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)
--			local pitchSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)
--			local rollSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)

--			local isLocalPlayer = (character == player.Character)
--			local heartbeatConnection
--			local targetRotation = Vector3.new(0, 0, 0)

--			-- Handle when this neck gets the tilt tag
--			observeTag(TILT_TAG, function(taggedNeck)
--				if taggedNeck ~= neck then return end

--				-- Listen for attribute changes (from server)
--				local function onTargetChanged()
--					local newTarget = neck:GetAttribute("TargetC0Rot")
--					if newTarget and typeof(newTarget) == "Vector3" then
--						targetRotation = newTarget
--						-- Update spring goals
--						yawSpring:SetGoal(targetRotation.Y)
--						pitchSpring:SetGoal(targetRotation.X)
--						rollSpring:SetGoal(targetRotation.Z)
--					end
--				end

--				neck:GetAttributeChangedSignal("TargetC0Rot"):Connect(onTargetChanged)
--				onTargetChanged() -- Initial call

--				-- For local player: calculate and send tilt to server
--				if isLocalPlayer then
--					local lastUpdateTime = 0
--					local UPDATE_RATE = 1/15 -- Reduced to 15 FPS for less network load
--					local lastSentRotation = Vector3.new(0, 0, 0)
--					local ROTATION_THRESHOLD = 0.05 -- Only send if change is significant

--					RunService.Heartbeat:Connect(function()
--						local currentTime = tick()
--						if currentTime - lastUpdateTime >= UPDATE_RATE then
--							local cam = workspace.CurrentCamera
--							if cam then
--								local camDir = hrp.CFrame:ToObjectSpace(cam.CFrame).LookVector
--								local yaw = -asin(math.clamp(camDir.X, -1, 1))
--								local pitch = asin(math.clamp(camDir.Y, -1, 1))

--								-- OPTIMIZATION 1: Send only Vector3 rotation (12 bytes vs 24+ bytes for CFrame)
--								local newRotation = Vector3.new(pitch, yaw, 0)

--								-- OPTIMIZATION 2: Delta compression - only send if change is significant
--								local rotationDelta = (newRotation - lastSentRotation).Magnitude
--								if rotationDelta >= ROTATION_THRESHOLD then
--									-- Send just the rotation Vector3 instead of full CFrame
--									Module.SetTargetRotation(neck, newRotation)
--									lastSentRotation = newRotation
--									lastUpdateTime = currentTime
--								end
--							end
--						end
--					end)
--				end

--				-- Smooth interpolation for all clients
--				heartbeatConnection = RunService.Heartbeat:Connect(function()
--					if not neck.Parent then
--						heartbeatConnection:Disconnect()
--						return
--					end

--					local yaw = yawSpring.Offset
--					local pitch = pitchSpring.Offset
--					local roll = rollSpring.Offset

--					local newC0
--					if humanoid.RigType == Enum.HumanoidRigType.R15 then
--						newC0 = CFNew(0, YOffset, 0) * CFAng(0, yaw, 0) * CFAng(pitch, 0, 0)
--					elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
--						newC0 = CFNew(0, YOffset, 0) * CFAng(3 * math.pi/2, 0, math.pi) * CFAng(0, 0, yaw) * CFAng(-pitch, 0, 0)
--					end

--					if newC0 then
--						neck.C0 = newC0
--					end
--				end)
--			end)
--		end

--		-- Setup for current character and future characters
--		if player.Character then
--			setupCharacter(player.Character)
--		end

--		player.CharacterAdded:Connect(setupCharacter)

--		-- Setup for other players' characters (so we can see their head tilts)
--		local function setupOtherPlayer(otherPlayer)
--			if otherPlayer == player then return end

--			local function onOtherCharacterAdded(character)
--				setupCharacter(character)
--			end

--			otherPlayer.CharacterAdded:Connect(onOtherCharacterAdded)
--			if otherPlayer.Character then
--				task.spawn(onOtherCharacterAdded, otherPlayer.Character)
--			end
--		end

--		Players.PlayerAdded:Connect(setupOtherPlayer)
--		for _, otherPlayer in ipairs(Players:GetPlayers()) do
--			task.spawn(setupOtherPlayer, otherPlayer)
--		end
--	end
--end

--return Module


--local Module = {}

--local RunService = game:GetService("RunService")
--local CollectionService = game:GetService("CollectionService")
--local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local replicateTilt = script:WaitForChild("ReplicateTilt-Event")
--local TILT_TAG = "Tilt_Tag"

--function IsOwnMotor6D(player, motor)
--	if not player.Character then return false end
--	return motor:IsDescendantOf(player.Character)
--end

--function IsBadCFrame(cf)
--	if typeof(cf) ~= "CFrame" then return true end -- Fixed: should return true if bad
--	for _, v in ipairs({cf:GetComponents()}) do
--		if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
--			return true -- Fixed: should return true if bad
--		end
--	end
--	return false -- Fixed: return false if good
--end

--function Module.SetTargetRotation(motor, rotationVector)
--	if RunService:IsServer() then
--		-- Server: Update the attribute for replication
--		if motor.Name == "Neck" then
--			motor:SetAttribute("TargetC0Rot", rotationVector)
--		end
--	else
--		-- Client: Send to server (now sends Vector3 instead of CFrame)
--		replicateTilt:FireServer(motor, rotationVector)
--	end
--end

--local function observeTag(tagName, onAdded, onRemoved)
--	-- Connect added signal
--	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
--		onAdded(instance)
--	end)

--	-- Connect removed signal
--	CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
--		if onRemoved then
--			onRemoved(instance)
--		end
--	end)

--	-- Handle already-tagged instances
--	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
--		onAdded(instance)
--	end
--end

--function Module.Init()
--	if RunService:IsServer() then
--		-- SERVER-SIDE: Handle client requests and update attributes
--		replicateTilt.OnServerEvent:Connect(function(player, motor, rotationVector) -- Now receives Vector3

--			if not motor:IsA("Motor6D") or motor.Name ~= "Neck" then 
--				return warn("Bad Motor6D") 
--			end

--			if not motor:HasTag(TILT_TAG) then -- Fixed: using CollectionService correctly
--				return warn("Motor ineligible for tilt")
--			end

--			-- Validate Vector3 instead of CFrame
--			if typeof(rotationVector) ~= "Vector3" then
--				return warn("Bad rotation vector")
--			end

--			-- Clamp rotation values to prevent extreme rotations
--			local clampedRotation = Vector3.new(
--				math.clamp(rotationVector.X, -math.pi/2, math.pi/2), -- Pitch
--				math.clamp(rotationVector.Y, -math.pi/2, math.pi/2), -- Yaw  
--				math.clamp(rotationVector.Z, -math.pi/4, math.pi/4)  -- Roll
--			)

--			if not IsOwnMotor6D(player, motor) then 
--				return warn("Does not own motor")
--			end

--			-- Update the attribute (this replicates to all clients)
--			Module.SetTargetRotation(motor, clampedRotation)
--		end)

--		-- Tag neck motors when characters spawn
--		local function onCharacterAdded(character)
--			local neck = character:FindFirstChild("Neck", true)
--			if neck and neck:IsA("Motor6D") then
--				CollectionService:AddTag(neck, TILT_TAG)
--			else
--				warn("Neck is missing or not Motor6D for", character.Name)
--			end
--		end

--		local function onPlayerAdded(player)
--			player.CharacterAdded:Connect(onCharacterAdded)
--			if player.Character then 
--				task.spawn(onCharacterAdded, player.Character) 
--			end
--		end

--		Players.PlayerAdded:Connect(onPlayerAdded)
--		for _, player in ipairs(Players:GetPlayers()) do
--			task.spawn(onPlayerAdded, player)
--		end

--	else
--		-- CLIENT-SIDE: Calculate tilt and smooth interpolation
--		local player = Players.LocalPlayer
--		local Spring = require(ReplicatedStorage.Services["Spring-Service"])

--		local function setupCharacter(character)
--			local humanoid = character:WaitForChild("Humanoid")
--			local hrp = character:WaitForChild("HumanoidRootPart")
--			local neck = character:FindFirstChild("Neck", true)

--			if not neck or not neck:IsA("Motor6D") then 
--				warn("No valid neck found for", character.Name)
--				return 
--			end

--			local YOffset = neck.C0.Y
--			local CFNew, CFAng, asin = CFrame.new, CFrame.Angles, math.asin
--			local yawSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)
--			local pitchSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)
--			local rollSpring = Spring.fromFrequency(1, 20, 1.5, 0, 0, 0)

--			local isLocalPlayer = (character == player.Character)
--			local heartbeatConnection
--			local targetRotation = Vector3.new(0, 0, 0)

--			-- Handle when this neck gets the tilt tag
--			observeTag(TILT_TAG, function(taggedNeck)
--				if taggedNeck ~= neck then return end

--				-- Listen for attribute changes (from server)
--				local function onTargetChanged()
--					local newTarget = neck:GetAttribute("TargetC0Rot")
--					if newTarget and typeof(newTarget) == "Vector3" then
--						targetRotation = newTarget
--						-- Update spring goals
--						yawSpring:SetGoal(targetRotation.Y)
--						pitchSpring:SetGoal(targetRotation.X)
--						rollSpring:SetGoal(targetRotation.Z)
--					end
--				end

--				neck:GetAttributeChangedSignal("TargetC0Rot"):Connect(onTargetChanged)
--				onTargetChanged() -- Initial call

--				-- For local player: calculate and send tilt to server
--				if isLocalPlayer then
--					local lastUpdateTime = 0
--					local UPDATE_RATE = 1/15 -- Reduced to 15 FPS for less network load
--					local lastSentRotation = Vector3.new(0, 0, 0)
--					local ROTATION_THRESHOLD = 0.05 -- Only send if change is significant

--					RunService.Heartbeat:Connect(function()
--						local currentTime = tick()
--						if currentTime - lastUpdateTime >= UPDATE_RATE then
--							local cam = workspace.CurrentCamera
--							if cam then
--								local camDir = hrp.CFrame:ToObjectSpace(cam.CFrame).LookVector
--								local yaw = -asin(math.clamp(camDir.X, -1, 1))
--								local pitch = asin(math.clamp(camDir.Y, -1, 1))

--								-- OPTIMIZATION 1: Send only Vector3 rotation (12 bytes vs 24+ bytes for CFrame)
--								local newRotation = Vector3.new(pitch, yaw, 0)

--								-- OPTIMIZATION 2: Delta compression - only send if change is significant
--								local rotationDelta = (newRotation - lastSentRotation).Magnitude
--								if rotationDelta >= ROTATION_THRESHOLD then
--									-- Send just the rotation Vector3 instead of full CFrame
--									Module.SetTargetRotation(neck, newRotation)
--									lastSentRotation = newRotation
--									lastUpdateTime = currentTime
--								end
--							end
--						end
--					end)
--				end

--				-- Smooth interpolation for all clients
--				heartbeatConnection = RunService.Heartbeat:Connect(function()
--					if not neck.Parent then
--						heartbeatConnection:Disconnect()
--						return
--					end

--					local yaw = yawSpring.Offset
--					local pitch = pitchSpring.Offset
--					local roll = rollSpring.Offset

--					local newC0
--					if humanoid.RigType == Enum.HumanoidRigType.R15 then
--						newC0 = CFNew(0, YOffset, 0) * CFAng(0, yaw, 0) * CFAng(pitch, 0, 0)
--					elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
--						newC0 = CFNew(0, YOffset, 0) * CFAng(3 * math.pi/2, 0, math.pi) * CFAng(0, 0, yaw) * CFAng(-pitch, 0, 0)
--					end

--					if newC0 then
--						neck.C0 = newC0
--					end
--				end)
--			end)
--		end

--		-- Setup for current character and future characters
--		if player.Character then
--			setupCharacter(player.Character)
--		end

--		player.CharacterAdded:Connect(setupCharacter)

--		-- Setup for other players' characters (so we can see their head tilts)
--		local function setupOtherPlayer(otherPlayer)
--			if otherPlayer == player then return end

--			local function onOtherCharacterAdded(character)
--				setupCharacter(character)
--			end

--			otherPlayer.CharacterAdded:Connect(onOtherCharacterAdded)
--			if otherPlayer.Character then
--				task.spawn(onOtherCharacterAdded, otherPlayer.Character)
--			end
--		end

--		Players.PlayerAdded:Connect(setupOtherPlayer)
--		for _, otherPlayer in ipairs(Players:GetPlayers()) do
--			task.spawn(setupOtherPlayer, otherPlayer)
--		end
--	end
--end

--return Module


