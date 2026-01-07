local Motion = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResetMotionValuesEvent = ReplicatedStorage.Events.Motion.ResetMotionValues

local LOCAL_PLAYER = game.Players.LocalPlayer

local Character
local Humanoid
local RootPart
local RunningSound

local DeductStaminaEvent = ReplicatedStorage.Events.Motion.DeductStamina
local EndSprintEvent = ReplicatedStorage.Events.Motion.EndSprint
local StartSprintEvent = ReplicatedStorage.Events.Motion.StartSprint

-- Modules for camera effects
--require(script.CameraBob)
--require(script.CameraShack)

local character = require(ReplicatedStorage.Utilities.FunctionUtils._character)

export type OTS_ExportType = typeof(require(script.Parent["OTS-Camera-Service"]))

export type MotionFunctionsTable = {
	StartSprint: () -> (),
	StopSprint: () -> (),
	StartSlide: () -> (),
	SpearJump: () -> (),
	IsPlayerSliding: () -> boolean,
	StopSlideHold: () -> (),
	IsPlayerSpearJumping: () -> boolean,
	IsPlayerSilding: () -> boolean,
	IsPlayerMoving : () -> boolean,
}

local Assets = {
	SlideAnim = script:WaitForChild("Slide-Animation"),
	SpearJumpAnim = script:WaitForChild("SpearJump-Animation"),
}

local OTS_Module: OTS_ExportType = nil

local state = {
	RunHeld = false,
	IsRunning = false,
	IsSliding = false,
	IsSpearJumping = false,
	IsSlidePaused = false,
	SlideHeld = false,
	RunSpeed = 21, -- default  
	WalkSpeed = 16, -- default 
}

local runtime = {
	SlideAnimTrack = nil,
	SpearJumpTrack = nil,
	SlideForce = nil,
	SpearForce = nil,
	SlideDecayConn = nil,
	SpearDecayConn = nil,
	SlideMovementConn = nil,
	SpearLandConn = nil,
	MoveCharacter = nil
}

--function Motion:OnCharacterAdded(char)
--	Character = char
--	Humanoid = Character:WaitForChild("Humanoid")
--	RootPart = Character:WaitForChild("HumanoidRootPart")
--	RunningSound = RootPart:FindFirstChild("Running")

--	-- reset state
--	state.RunHeld = false
--	state.IsRunning = false
--	state.IsSliding = false
--	state.IsSpearJumping = false
--	state.IsSlidePaused = false
--	state.SlideHeld = false

--	-- disconnect previous runtime connections
--	if runtime.MoveCharacter then
--		runtime.MoveCharacter:Disconnect()
--		runtime.MoveCharacter = nil
--	end
--	if runtime.SlideMovementConn then
--		runtime.SlideMovementConn:Disconnect()
--		runtime.SlideMovementConn = nil
--	end
--	if runtime.SlideDecayConn then
--		runtime.SlideDecayConn:Disconnect()
--		runtime.SlideDecayConn = nil
--	end
--	if runtime.SpearDecayConn then
--		runtime.SpearDecayConn:Disconnect()
--		runtime.SpearDecayConn = nil
--	end
--	if runtime.SpearLandConn then
--		runtime.SpearLandConn:Disconnect()
--		runtime.SpearLandConn = nil
--	end

--	-- destroy animations / forces if they exist
--	if runtime.SlideAnimTrack then
--		runtime.SlideAnimTrack:Stop()
--		runtime.SlideAnimTrack:Destroy()
--		runtime.SlideAnimTrack = nil
--	end
--	if runtime.SlideForce then
--		runtime.SlideForce:Destroy()
--		runtime.SlideForce = nil
--	end
--	if runtime.SpearForce then
--		runtime.SpearForce:Destroy()
--		runtime.SpearForce = nil
--	end
--	if runtime.SpearJumpTrack then
--		runtime.SpearJumpTrack:Stop()
--		runtime.SpearJumpTrack:Destroy()
--		runtime.SpearJumpTrack = nil
--	end

--	--local function checkAutoSlide()
--	--	if not Humanoid then return end
--	--	local currentState = Humanoid:GetState()
--	--	local isAirborne = currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping
--	--	local isMoving = Humanoid.MoveDirection.Magnitude > 0.1

--	--	if isMoving and not isAirborne and not state.IsSliding and not state.IsSpearJumping then
--	--		StartSlide()
--	--	end
--	--end

--	--checkAutoSlide()
--end

function Motion:OnCharacterAdded(char)
	-- FIRST: Disconnect and clean up ALL runtime connections before anything else
	-- This ensures old character's connections don't interfere
	if runtime.MoveCharacter then
		runtime.MoveCharacter:Disconnect()
		runtime.MoveCharacter = nil
	end
	if runtime.SlideMovementConn then
		runtime.SlideMovementConn:Disconnect()
		runtime.SlideMovementConn = nil
	end
	if runtime.SlideDecayConn then
		runtime.SlideDecayConn:Disconnect()
		runtime.SlideDecayConn = nil
	end
	if runtime.SpearDecayConn then
		runtime.SpearDecayConn:Disconnect()
		runtime.SpearDecayConn = nil
	end
	if runtime.SpearLandConn then
		runtime.SpearLandConn:Disconnect()
		runtime.SpearLandConn = nil
	end

	-- Destroy animations / forces
	if runtime.SlideAnimTrack then
		runtime.SlideAnimTrack:Stop()
		runtime.SlideAnimTrack:Destroy()
		runtime.SlideAnimTrack = nil
	end
	if runtime.SlideForce then
		runtime.SlideForce:Destroy()
		runtime.SlideForce = nil
	end
	if runtime.SpearForce then
		runtime.SpearForce:Destroy()
		runtime.SpearForce = nil
	end
	if runtime.SpearJumpTrack then
		runtime.SpearJumpTrack:Stop()
		runtime.SpearJumpTrack:Destroy()
		runtime.SpearJumpTrack = nil
	end

	-- THEN: Reset state flags
	state.RunHeld = false
	state.IsRunning = false
	state.IsSliding = false
	state.IsSpearJumping = false
	state.IsSlidePaused = false
	state.SlideHeld = false

	-- FINALLY: Set new character references
	Character = char
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")
	RunningSound = RootPart:FindFirstChild("Running")
	
	-- Ensure AutoRotate is enabled for new character
	Humanoid.AutoRotate = true
	
	if OTS_Module and OTS_Module.EnabledShitLock then
		OTS_Module:EnabledShitLock()
	end

	-- Reset character alignment
	if OTS_Module and OTS_Module.SetCharacterAlignment then
		OTS_Module:SetCharacterAlignment(false)
	end
	
end

function Motion:Init(OTS_Module_Param: OTS_ExportType): MotionFunctionsTable
	--local data = GetAbilitiesEvent:InvokeServer(Player)
	--for k, v in pairs(data) do -- add the walk, run and jump speed from server
	--	state[k] = v -- will overide walk and run because have the same name
	--end
	
	ResetMotionValuesEvent.OnClientEvent:Connect(function()
		self:ApplyUpdatedAttributes()
	end)

	state.WalkSpeed = LOCAL_PLAYER:GetAttribute("CurrentWalkSpeed")
	state.RunSpeed = LOCAL_PLAYER:GetAttribute("CurrentRunSpeed")

	OTS_Module = OTS_Module_Param

	-- Wait for character
	if LOCAL_PLAYER.Character then
		self:OnCharacterAdded(LOCAL_PLAYER.Character)
	end

	LOCAL_PLAYER.CharacterAdded:Connect(function(character)
		self:OnCharacterAdded(character)
	end)

	-- Return the control functions
	return {
		StartSprint = StartSprint,
		StopSprint = StopSprint,
		StartSlide = StartSlide,
		SpearJump = SpearJump,
		IsPlayerSliding = IsPlayerSliding,
		StopSlideHold = StopSlideHold,
		IsPlayerSpearJumping = Motion.IsPlayerSpearJumping
	}
end

function Motion:ApplyUpdatedAttributes()
	if not Humanoid then return end

	-- Pull latest attributes from player
	state.WalkSpeed = LOCAL_PLAYER:GetAttribute("CurrentWalkSpeed")
	state.RunSpeed = LOCAL_PLAYER:GetAttribute("CurrentRunSpeed")
	local jumpPower = LOCAL_PLAYER:GetAttribute("CurrentJumpPower")

	-- Apply them to Humanoid directly
	Humanoid.WalkSpeed = state.WalkSpeed
	Humanoid.JumpPower = jumpPower
end

-- Sprint Functions
function StartSprint()
	if state.IsRunning or state.IsSliding or state.IsSpearJumping then return end
	
	if RootPart.Velocity.Magnitude < 0.1 then
		return
	end
	
	state.RunHeld = true
	Humanoid.WalkSpeed = state.RunSpeed
	state.IsRunning = true
	if RunningSound then
		RunningSound.PlaybackSpeed = 2.4
	end
	
	StartSprintEvent:FireServer()
end

function StopSprint()
	state.RunHeld = false
	state.IsRunning = false
	Humanoid.WalkSpeed = state.WalkSpeed
	if RunningSound then
		RunningSound.PlaybackSpeed = 1.85
	end
	
	EndSprintEvent:FireServer()
end

-- Slide Hold Control Function
function StopSlideHold()
	state.SlideHeld = false
end


function IsPlayerSliding() : boolean
	return state.IsSliding
end

-- Internal Slide Logic
local function ResetSlideRuntime()
	if runtime.MoveCharacter then
		runtime.MoveCharacter:Disconnect()
		runtime.MoveCharacter = nil
	end
	if runtime.SlideMovementConn then
		runtime.SlideMovementConn:Disconnect()
		runtime.SlideMovementConn = nil
	end
	if runtime.SlideDecayConn then
		runtime.SlideDecayConn:Disconnect()
		runtime.SlideDecayConn = nil
	end
	if runtime.SlideForce then
		runtime.SlideForce:Destroy()
		runtime.SlideForce = nil
	end
	if runtime.SlideAnimTrack then
		runtime.SlideAnimTrack:Stop()
		runtime.SlideAnimTrack:Destroy()
		runtime.SlideAnimTrack = nil
	end
end

function StartSlide()
	if state.IsSpearJumping or state.IsSliding then return end

	local currentState = Humanoid:GetState()
	local isAirborne = currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping
	if isAirborne then return end

	ResetSlideRuntime() -- ensure previous slide cleaned

	state.IsSliding = true
	state.IsSlidePaused = false
	Humanoid.AutoRotate = false
	state.SlideHeld = true
	--Humanoid.JumpPower = 0
	state.CanJump = false

	-- Disable shift zoom effect
	if OTS_Module and OTS_Module.DisabledShitLock then
		OTS_Module:DisabledShitLock()
	end

	-- Move Character
	if not runtime.MoveCharacter then
		runtime.MoveCharacter = RunService.RenderStepped:Connect(function()
			Humanoid:Move(RootPart.CFrame.LookVector* 100)
		end)
	else
		runtime.MoveCharacter:Disconnect()
		runtime.MoveCharacter = RunService.RenderStepped:Connect(function()
			Humanoid:Move(RootPart.CFrame.LookVector* 100)
		end)
	end
	
	if RunningSound then
		RunningSound.PlaybackSpeed = 0
	end

	-- Slide Animation
	runtime.SlideAnimTrack = Humanoid:LoadAnimation(Assets.SlideAnim)
	runtime.SlideAnimTrack:Play()
	
	local EventrConnection
	EventrConnection = runtime.SlideAnimTrack:GetMarkerReachedSignal("SlidePusse"):Connect(function()
		if runtime.SlideAnimTrack and runtime.SlideAnimTrack.IsPlaying then
			runtime.SlideAnimTrack:AdjustSpeed(0)
			state.IsSlidePaused = true
			EventrConnection:Disconnect()
		end
	end)

	-- Slide Force
	runtime.SlideForce = Instance.new("BodyVelocity")
	runtime.SlideForce.MaxForce = Vector3.new(1,0,1) * 8000
	runtime.SlideForce.Velocity = RootPart.CFrame.LookVector * 100
	runtime.SlideForce.Parent = RootPart

	local startTime = tick()
	local startVelocity = runtime.SlideForce.Velocity

	runtime.SlideMovementConn = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / 3, 0, 1)
		if runtime.SlideForce and not state.IsSpearJumping then
			runtime.SlideForce.Velocity = startVelocity * (1 - alpha)
		end
		if alpha >= 1 then
			if state.IsSlidePaused and runtime.SlideAnimTrack then
				runtime.SlideAnimTrack:AdjustSpeed(1)
				state.IsSlidePaused = false
			end
			
			wait(0.46)
			
			StopSlide()
			if runtime.MoveCharacter then
				runtime.MoveCharacter:Disconnect()
				runtime.MoveCharacter = false
			end
		end
	end)
end

function StopSlide()

	if not state.IsSliding then return end
	state.IsSliding = false

	Humanoid.AutoRotate = true
	state.CanJump = true
	
	ResetSlideRuntime() -- cleanup connections, force, animation

	if RunningSound then
		if state.IsRunning then
			RunningSound.PlaybackSpeed = 2.4
		else
			RunningSound.PlaybackSpeed = 1.85
		end
	end
	
	if not state.IsSpearJumping  then
		-- Disable shift zoom effect
		if OTS_Module and OTS_Module.EnabledShitLock then
			OTS_Module:EnabledShitLock()
		end
	end
end

-- Spear Jump Function
function SpearJump()
	if not state.IsSliding or state.IsSpearJumping then return end

	if runtime.SlideForce then
		runtime.SlideForce:Destroy()
		runtime.SlideForce = nil
	end

	state.IsSpearJumping = true
	Humanoid.AutoRotate = true
	StopSlide()

	if OTS_Module and OTS_Module.SetCharacterAlignment then
		OTS_Module:SetCharacterAlignment(true)
	end
	
	if runtime.SpearForce then
		runtime.SpearForce:Destroy()
		runtime.SpearForce = nil
	end
	
	if runtime.SpearDecayConn then
		runtime.SpearDecayConn:Disconnect()
		runtime.SpearDecayConn = nil
	end
	
	-- Move Character
	if not runtime.MoveCharacter then
		runtime.MoveCharacter = RunService.RenderStepped:Connect(function()
			Humanoid:Move(RootPart.CFrame.LookVector* 100)
		end)
	else
		runtime.MoveCharacter:Disconnect()
		runtime.MoveCharacter = RunService.RenderStepped:Connect(function()
			Humanoid:Move(RootPart.CFrame.LookVector* 100)
		end)
	end
	
	-- Camera-directed velocity
	local camera = workspace.CurrentCamera
	local look = camera.CFrame.LookVector.Unit
	local pitch = math.deg(math.atan2(look.Y, math.sqrt(look.X^2 + look.Z^2)))
	local velocity = pitch > 1 and look or (Vector3.new(look.X, 0, look.Z).Unit * math.cos(math.rad(1)) + Vector3.new(0, math.sin(math.rad(1)), 0)).Unit

	runtime.SpearForce = Instance.new("BodyVelocity")
	runtime.SpearForce.MaxForce = Vector3.new(1, 1, 1) * 1000
	runtime.SpearForce.Velocity = velocity * 100
	runtime.SpearForce.Parent = RootPart

	runtime.SpearJumpTrack = Humanoid:LoadAnimation(Assets.SpearJumpAnim)
	runtime.SpearJumpTrack:Play()

	-- Listen for animation markers to kill the animation
	local floatingConn, landedConn

	floatingConn = runtime.SpearJumpTrack:GetMarkerReachedSignal("lsFloating"):Connect(function()
		if runtime.SpearJumpTrack then
			runtime.SpearJumpTrack:Stop(0)
			runtime.SpearJumpTrack:Destroy()
			runtime.SpearJumpTrack = nil
		end
		if floatingConn then floatingConn:Disconnect() end
		if landedConn then landedConn:Disconnect() end
	end)

	landedConn = runtime.SpearJumpTrack:GetMarkerReachedSignal("Landed"):Connect(function()
		if runtime.SpearJumpTrack then
			runtime.SpearJumpTrack:Stop(0)
			runtime.SpearJumpTrack:Destroy()
			runtime.SpearJumpTrack = nil
		end
		if floatingConn then floatingConn:Disconnect() end
		if landedConn then landedConn:Disconnect() end
	end)

	-- Apply decay
	local startTime = tick()
	local startVelocity = runtime.SpearForce.Velocity
	
	DeductStaminaEvent:FireServer()

	runtime.SpearDecayConn = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / 1, 0, 1)
		local decay = 1 - 0.75 * alpha
		if runtime.SpearForce then
			runtime.SpearForce.Velocity = startVelocity * decay
		end

		if alpha >= 1 and runtime.SpearForce then
			runtime.SpearForce:Destroy()
			runtime.SpearForce = nil
			runtime.SpearDecayConn:Disconnect()
		end
	end)

	-- Cleanup on land
	runtime.SpearLandConn = Humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed or
			newState == Enum.HumanoidStateType.Running or
			newState == Enum.HumanoidStateType.RunningNoPhysics then

			if runtime.SpearForce then runtime.SpearForce:Destroy() end
			if runtime.SpearJumpTrack then
				runtime.SpearJumpTrack:Stop()
				runtime.SpearJumpTrack:Destroy()
				runtime.SpearJumpTrack = nil
			end

			state.IsSpearJumping = false

			if OTS_Module and OTS_Module.SetCharacterAlignment then
				OTS_Module:SetCharacterAlignment(false)
			end

			if OTS_Module and OTS_Module.EnabledShitLock then
				OTS_Module:EnabledShitLock()
			end

			if runtime.SlideAnimTrack then
				runtime.SlideAnimTrack:Stop(0)
				runtime.SlideAnimTrack:Destroy()
				runtime.SlideAnimTrack = nil
			end

			if runtime.SpearLandConn then
				runtime.SpearLandConn:Disconnect()
				runtime.SpearLandConn = nil
			end

			if runtime.MoveCharacter then 
				runtime.MoveCharacter:Disconnect() 
				runtime.MoveCharacter = nil
			end
			
			if floatingConn then floatingConn:Disconnect() end
			if landedConn then landedConn:Disconnect() end
			
			-- disabled on hold to re slide after spear jump
			-- Only start sliding again if the player is still holding the slide button
			--if state.SlideHeld then
			--	local currentState = Humanoid:GetState()
			--	local isAirborne = currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping
			--	local isMoving = Humanoid.MoveDirection.Magnitude > 0.1

			--	-- Only slide if conditions are met (not airborne and moving)
			--	if not isAirborne and isMoving then
			--		StartSlide()
			--	end
			--end
		end
	end)

end

function Motion.IsPlayerSpearJumping()
	return state.IsSpearJumping
end

function Motion.IsPlayerSilding()
	return state.IsSliding
end

function Motion.IsPlayerMoving() : boolean
	if not Humanoid then return false end

	if Humanoid:GetState() == Enum.HumanoidStateType.Running 
		and Humanoid.MoveDirection.Magnitude > 0 then
		return true
	end

	return false
end
return Motion


