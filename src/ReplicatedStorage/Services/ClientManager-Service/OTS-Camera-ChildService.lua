local CLASS = {}
CLASS.__index = CLASS

--// TYPES //--
export type OTS_Camera = {
	SetActiveCameraSettings: (self: OTS_Camera, cameraSettings: string) -> (),
	SetCharacterAlignment: (self: OTS_Camera, aligned: boolean) -> (),
	SetMouseStep: (self: OTS_Camera, steppedIn: boolean) -> (),
	SetShoulderDirection: (self: OTS_Camera, shoulderDirection: number) -> (),
	IsPlayerAiming: (self: OTS_Camera) -> boolean,
	Enable: (self: OTS_Camera, activeClasses: {[string]: any}) -> (),
	Disable: (self: OTS_Camera) -> (),
	DisableMobileInput: (self: OTS_Camera) -> (),
	EnableMobileInput: (self: OTS_Camera) -> (),
	EnabledShitLock: (self: OTS_Camera) -> (),
	DisabledShitLock: (self: OTS_Camera) -> (),
	EnableControllerInput: (self: OTS_Camera) -> (),
	DisableControllerInput: (self: OTS_Camera) -> (),
	EnableMouseInput: (self: OTS_Camera) -> (),
	DisableMouseInput: (self: OTS_Camera) -> (),
	CenterCameraYAxisInstant: (self: OTS_Camera) -> (),
	CenterCameraYAxis: (self: OTS_Camera, lerpSpeed: number) -> (),
}


--// SERVICES //--
local PLAYERS_SERVICE = game:GetService("Players")
local RUN_SERVICE = game:GetService("RunService")
local USER_INPUT_SERVICE = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RespawnZoomOutCameraEvent = ReplicatedStorage.Events.Motion:WaitForChild("RespawnZoomOutCamera")


local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

-- Mobile touch constants
local ROTATION_SPEED_TOUCH = Vector2.new(1, 0.66)
local MIN_TOUCH_SENSITIVITY_FRACTION = 0.25


--// Cutome Export //--

local Input = require(ReplicatedStorage.Utilities.ClientModuleUtils._Input)
export type MouseClass = typeof(Input.Mouse)
export type KeyboardClass = typeof(Input.Keyboard)
export type TouchClass = typeof(Input.Touch)
export type GamepadClass = typeof(Input.Gamepad)

export type ActiveInputClasses = {
	Mouse_Input: MouseClass?,
	Keyboard_Input: KeyboardClass?,
	Mobile_Input: TouchClass?,
	Console_Input: GamepadClass?,
}

--// UTILITY FUNCTIONS //--
local function Lerp(x, y, a)
	return x + (y - x) * a
end

-- Helper function to safely get character components
local function getCharacterComponents()
	local character = LOCAL_PLAYER.Character
	if not character then return nil, nil, nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	return character, humanoid, rootPart
end

local function adjustTouchPitchSensitivity(delta: Vector2): Vector2
	local camera = workspace.CurrentCamera
	if not camera then return delta end

	local pitch = camera.CFrame:ToEulerAnglesYXZ()
	if delta.Y*pitch >= 0 then return delta end

	local curveY = 1 - (2*math.abs(pitch)/math.pi)^0.75
	local sensitivity = curveY*(1 - MIN_TOUCH_SENSITIVITY_FRACTION) + MIN_TOUCH_SENSITIVITY_FRACTION
	return Vector2.new(1, sensitivity) * delta
end

--// CONSTRUCTOR //--
function CLASS.new()
	local touchState = {
		Move = Vector2.new(),
		panInputCount = 0,
		touches = {},
		dynamicThumbstickInput = nil,
	}

	local dataTable = setmetatable({
		isMobile = USER_INPUT_SERVICE.TouchEnabled and not USER_INPUT_SERVICE.KeyboardEnabled,
		isController = USER_INPUT_SERVICE.GamepadEnabled,
		
		IsZoomedOut = false,

		-- Camera properties
		SavedCameraSettings = nil,
		SavedMouseBehavior = nil,
		ActiveCameraSettings = nil,
		HorizontalAngle = 0,
		VerticalAngle = 0,
		ShoulderDirection = 1,
		ZoomedShitLock = true,
		
		mouseCameraInputDisabled = false,
		
		m2Active = false,

		-- Touch state
		touchState = touchState,
		touchConnections = {},

		-- Flags
		IsCharacterAligned = false,
		IsMouseSteppedIn = false,
		IsEnabled = false,

		-- Events
		ActiveCameraSettingsChangedEvent = Instance.new("BindableEvent"),
		CharacterAlignmentChangedEvent = Instance.new("BindableEvent"),
		MouseStepChangedEvent = Instance.new("BindableEvent"),
		ShoulderDirectionChangedEvent = Instance.new("BindableEvent"),
		EnabledEvent = Instance.new("BindableEvent"),
		DisabledEvent = Instance.new("BindableEvent"),

		-- Config
		VerticalAngleLimits = NumberRange.new(-45, 45),

		-- Camera settings
		CameraSettings = {
			DefaultShoulder = {
				FieldOfView = 70,
				Offset = Vector3.new(2.5, 2.5, 8),
				Sensitivity = 3.5,
				MobileSensitivity = 5.5,
				ControllerSensitivity = 1.5,
				LerpSpeed = 0.5,
			},
			ZoomedShoulder = {
				FieldOfView = 40,
				Offset = Vector3.new(3.5, 1.5, 11.5),
				Sensitivity = 1.5,
				MobileSensitivity = 1.5,
				ControllerSensitivity = 1.5,
				LerpSpeed = 0.2,
			},
			ZoomedOut = {
				FieldOfView = 90,  -- Wider field of view
				Offset = Vector3.new(2.5, 3, 12),  -- Further back camera
				Sensitivity = 3.5,
				MobileSensitivity = 5.5,
				ControllerSensitivity = 1.5,
				LerpSpeed = 0.5,
			},
			NPC_Intraction = {
				FieldOfView = 40,  -- Wider field of view
				Offset = Vector3.new(2.8, 1, 7),  -- Further back camera
				Sensitivity = 3.5,
				MobileSensitivity = 5.5,
				ControllerSensitivity = 1.5,
				LerpSpeed = 0.1,
			},
		},
	}, CLASS)

	local proxyTable = setmetatable(
		{}, {
			__index = function(self, index)
				return dataTable[index]
			end,
			__newindex = function(self, index, newValue)
				dataTable[index] = newValue
			end
		})

	return proxyTable
end

--// METHODS //--

local function isInDynamicThumbstickArea(pos: Vector3): boolean
	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local thumbstickFrame = touchFrame and touchFrame:FindFirstChild("DynamicThumbstickFrame")

	if not thumbstickFrame then
		return false
	end

	if not touchGui.Enabled then
		return false
	end

	local posTopLeft = thumbstickFrame.AbsolutePosition
	local posBottomRight = posTopLeft + thumbstickFrame.AbsoluteSize

	return
		pos.X >= posTopLeft.X and
		pos.Y >= posTopLeft.Y and
		pos.X <= posBottomRight.X and
		pos.Y <= posBottomRight.Y
end

local function isInJumpButtonArea(pos: Vector3): boolean
	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jumpButton = touchFrame and touchFrame:FindFirstChild("JumpButton")

	if not jumpButton then
		return false
	end

	if not touchGui.Enabled then
		return false
	end

	local posTopLeft = jumpButton.AbsolutePosition
	local posBottomRight = posTopLeft + jumpButton.AbsoluteSize

	return
		pos.X >= posTopLeft.X and
		pos.Y >= posTopLeft.Y and
		pos.X <= posBottomRight.X and
		pos.Y <= posBottomRight.Y
end

local function setMobileControlsEnabled(enabled)
	local player = PLAYERS_SERVICE.LocalPlayer
	local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	local Controls = PlayerModule:GetControls()

	if enabled then
		Controls:Enable()
	else
		Controls:Disable()
	end
end

local shiftLockActive

function shiftLock(active)
	shiftLockActive = active
	local character, humanoid, rootPart = getCharacterComponents()
	if not humanoid or not rootPart then return end

	-- When shift lock is active, disable automatic rotation so we can control it manually.
	humanoid.AutoRotate = not active

	if active then		
		RUN_SERVICE:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
			-- Check if components still exist
			local _, currentHumanoid, currentRootPart = getCharacterComponents()
			if not currentRootPart then 
				-- Character respawned, unbind and return
				RUN_SERVICE:UnbindFromRenderStep("ShiftLock")
				return 
			end

			USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter -- Lock the mouse to center

			-- Get the camera's Y rotation
			local camera = workspace.CurrentCamera
			local _, yRotation = camera.CFrame:ToEulerAnglesYXZ()

			-- Update only the rotation of the HRP without affecting its position.
			currentRootPart.CFrame = CFrame.new(currentRootPart.Position) * CFrame.Angles(0, yRotation, 0)
		end)
	else
		RUN_SERVICE:UnbindFromRenderStep("ShiftLock")
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default -- Restore default mouse behavior
	end
end

function CLASS:EnabledShitLock()
	self.ZoomedShitLock = true
end

function CLASS:DisabledShitLock()
	self.ZoomedShitLock = false
end

function CLASS:DisableMouseInput()
	if self.isMobile then
		warn("OTS Camera System: Not on mouse device - DisableMouseInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.mouseCameraInputDisabled = true
	print("OTS Camera System: Mouse camera input disabled")
end

function CLASS:EnableMouseInput()
	if self.isMobile then
		warn("OTS Camera System: Not on mouse device - EnableMouseInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.mouseCameraInputDisabled = false
	print("OTS Camera System: Mouse camera input enabled")
end


function CLASS:SetActiveCameraSettings(cameraSettings)
	assert(cameraSettings ~= nil and typeof(cameraSettings) == "string", "Invalid cameraSettings")
	assert(self.CameraSettings[cameraSettings] ~= nil, "Unrecognized cameraSettings")
	if not self.IsEnabled then
		warn("OTS Camera disabled; cannot set camera settings")
		return
	end
	
	-- Added by IronBeliver for isZooming function
	if cameraSettings == "ZoomedShoulder" then
		self.m2Active = true -- just check for if zooming bool return
		
		if self.ZoomedShitLock  then
			shiftLock(true)
		end
	else
		self.m2Active = false -- just check for if zooming bool return
		shiftLock(false)
	end
	
	
	
	self.ActiveCameraSettings = cameraSettings
	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
end

function CLASS:SetCharacterAlignment(aligned)
	assert(aligned ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(aligned) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(aligned))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change character alignment without enabling OTS camera system")
		return
	end

	local character, humanoid, rootPart = getCharacterComponents()
	if humanoid then
		humanoid.AutoRotate = not aligned
	end

	self.IsCharacterAligned = aligned
	self.CharacterAlignmentChangedEvent:Fire(aligned)
end

function CLASS:SetMouseStep(steppedIn)
	assert(steppedIn ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(steppedIn) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(steppedIn))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change mouse step without enabling OTS camera system")
		return
	end

	self.IsMouseSteppedIn = steppedIn
	self.MouseStepChangedEvent:Fire(steppedIn)
	if (steppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter

		-- added by IronBeliever
		USER_INPUT_SERVICE.MouseIconEnabled = false
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default

		-- added by IronBeliever
		USER_INPUT_SERVICE.MouseIconEnabled = true
	end
end

function CLASS:SetShoulderDirection(shoulderDirection)
	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change shoulder direction without enabling OTS camera system")
		return
	end

	self.ShoulderDirection = shoulderDirection
	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
end
----

--// //--
function CLASS:SaveCameraSettings()
	local currentCamera = workspace.CurrentCamera
	self.SavedCameraSettings = {
		FieldOfView = currentCamera.FieldOfView,
		CameraSubject = currentCamera.CameraSubject,
		CameraType = currentCamera.CameraType
	}
end

function CLASS:LoadCameraSettings()
	local currentCamera = workspace.CurrentCamera
	for setting, value in pairs(self.SavedCameraSettings) do
		currentCamera[setting] = value
	end
end

	local touchState = {
		Move = Vector2.new(),
		panInputCount = 0,
		touches = {}, -- {[InputObject] = sunk}
		dynamicThumbstickInput = nil,
	}

function CLASS:incPanInputCount()
	touchState.panInputCount = math.max(0, touchState.panInputCount + 1)
end

function CLASS:decPanInputCount()
	touchState.panInputCount = math.max(0, touchState.panInputCount - 1)
end

function CLASS:setupTouchInput()
	if not self.isMobile then return end

	-- Clear existing connections
	for _, conn in pairs(self.touchConnections) do
		conn:Disconnect()
	end
	self.touchConnections = {}

	local function touchBegan(input: InputObject, sunk: boolean)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end

		-- Always ignore touches that start in UI areas (thumbstick or jump button)
		if isInDynamicThumbstickArea(input.Position) or isInJumpButtonArea(input.Position) then
			self.touchState.dynamicThumbstickInput = input
			return
		end

		-- Only count non-sunk touches for camera panning
		if not sunk then
			self:incPanInputCount()
		end

		-- register the finger
		self.touchState.touches[input] = sunk
	end

	local function touchEnded(input: InputObject, sunk: boolean)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end

		-- reset the DT input
		if input == self.touchState.dynamicThumbstickInput then
			self.touchState.dynamicThumbstickInput = nil
		end

		-- reset pan state if one unsunk finger lifts
		if self.touchState.touches[input] == false then
			self.decPanInputCount()
		end

		-- unregister input
		self.touchState.touches[input] = nil
	end

	local function touchChanged(input, sunk)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end

		-- ignore movement from UI elements (thumbstick, jump button, etc.)
		if input == self.touchState.dynamicThumbstickInput then
			return
		end

		-- fixup unknown touches
		if self.touchState.touches[input] == nil then
			self.touchState.touches[input] = sunk
		end

		-- collect unsunk touches (only these should affect camera)
		local unsunkTouches = {}
		for touch, touchSunk in pairs(self.touchState.touches) do
			if not touchSunk then
				table.insert(unsunkTouches, touch)
			end
		end

		-- Only register camera movement from touches that are:
		-- 1. Not sunk by UI
		-- 2. Not in control areas (thumbstick/jump button)
		if #unsunkTouches >= 1 and self.touchState.touches[input] == false then
			-- Don't add movement if this touch started in a control area
			if not (isInDynamicThumbstickArea(input.Position) or isInJumpButtonArea(input.Position)) then
				local delta = input.Delta
				self.touchState.Move += Vector2.new(delta.X, delta.Y)
			end
		end
	end

	local function inputBegan(input, sunk)
		touchBegan(input, sunk)
	end

	local function inputChanged(input, sunk)
		touchChanged(input, sunk)
	end

	local function inputEnded(input, sunk)
		touchEnded(input, sunk)
	end

	-- Connect input events
	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputBegan:Connect(inputBegan))
	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputChanged:Connect(inputChanged))
	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputEnded:Connect(inputEnded))
end

function CLASS:DisableMobileInput()
	if not self.isMobile then
		warn("OTS Camera System: Not on mobile device - DisableMobileInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.mobileCameraInputDisabled = true
	self:cleanupTouchInput()

	-- Disable Roblox thumbstick
	setMobileControlsEnabled(false)

	print("OTS Camera System: Mobile input disabled (including thumbstick)")
end


function CLASS:EnableMobileInput()
	if not self.isMobile then
		warn("OTS Camera System: Not on mobile device - EnableMobileInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.mobileCameraInputDisabled = false
	self:setupTouchInput()

	-- Enable Roblox thumbstick
	setMobileControlsEnabled(true)

	print("OTS Camera System: Mobile input enabled (including thumbstick)")
end

function CLASS:DisableControllerInput()
	if not self.isController then
		warn("OTS Camera System: Not on controller - DisableControllerInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.controllerCameraInputDisabled = true
	print("OTS Camera System: Controller input disabled (right stick won't move camera)")
end

function CLASS:EnableControllerInput()
	if not self.isController then
		warn("OTS Camera System: Not on controller - EnableControllerInput has no effect")
		return
	end

	if not self.IsEnabled then
		warn("OTS Camera System: Camera system is not enabled")
		return
	end

	self.controllerCameraInputDisabled = false
	print("OTS Camera System: Controller input enabled (right stick moves camera)")
end



function CLASS:cleanupTouchInput()
	for _, conn in pairs(self.touchConnections) do
		conn:Disconnect()
	end
	self.touchConnections = {}

	-- Reset touch state
	self.touchState.touches = {}
	self.touchState.dynamicThumbstickInput = nil
	self.touchState.Move = Vector2.new()
	self.touchState.panInputCount = 0
end

function CLASS:resetTouchStateForFrame()
	self.touchState.Move = Vector2.new()
end

function CLASS:getRotationActivated(): boolean
	if self.isMobile then
		return self.touchState.panInputCount > 0
	else
		-- For mouse, we can check if right mouse button is held or mouse is moving
		return USER_INPUT_SERVICE:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
end
----

--// //--
function CLASS:Update()
	local currentCamera = workspace.CurrentCamera
	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]

	--// Address mouse behavior and camera type //--
	if (self.IsMouseSteppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
	currentCamera.CameraType = Enum.CameraType.Scriptable
	---

	if self.isMobile then
		-- Check if mobile camera input is disabled
		if not self.mobileCameraInputDisabled then
			--// Address touch input //--
			local mobileSensitivity = activeCameraSettings.MobileSensitivity or activeCameraSettings.Sensitivity
			local touchDelta = adjustTouchPitchSensitivity(self.touchState.Move) * mobileSensitivity
			self.HorizontalAngle -= touchDelta.X * ROTATION_SPEED_TOUCH.X / currentCamera.ViewportSize.X
			self.VerticalAngle -= touchDelta.Y * ROTATION_SPEED_TOUCH.Y / currentCamera.ViewportSize.Y
			self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
		end

		-- Always reset touch movement for next frame (even when disabled)
		self:resetTouchStateForFrame()
		----
	else
		-- adjusted by ironbeliever
		if not self.mouseCameraInputDisabled then
			--// Address mouse input //--
			local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
			self.HorizontalAngle -= mouseDelta.X/currentCamera.ViewportSize.X
			self.VerticalAngle -= mouseDelta.Y/currentCamera.ViewportSize.Y
			self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
		end
		
		--// Address controller input //--
		if self.isController and not self.controllerCameraInputDisabled then
			local gamepadState = USER_INPUT_SERVICE:GetGamepadState(Enum.UserInputType.Gamepad1)
			for _, input in ipairs(gamepadState) do
				if input.KeyCode == Enum.KeyCode.Thumbstick2 then -- Right stick
					local stickDelta = input.Position
					if math.abs(stickDelta.X) > 0.1 or math.abs(stickDelta.Y) > 0.1 then
						local controllerSensitivity = activeCameraSettings.ControllerSensitivity
						self.HorizontalAngle += stickDelta.X * controllerSensitivity * -0.03
						self.VerticalAngle -= stickDelta.Y * controllerSensitivity * -0.03
						self.VerticalAngle = math.rad(math.clamp(
							math.deg(self.VerticalAngle),
							self.VerticalAngleLimits.Min,
							self.VerticalAngleLimits.Max
						))
					end
				end
			end
		end
	end

	local character, humanoid, humanoidRootPart = getCharacterComponents()
	if humanoidRootPart then

		--// Lerp field of view //--
		currentCamera.FieldOfView = Lerp(
			currentCamera.FieldOfView, 
			activeCameraSettings.FieldOfView, 
			activeCameraSettings.LerpSpeed
		)
		----

		--// Address shoulder direction //--
		local offset = activeCameraSettings.Offset
		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
		----

		--// Calculate new camera cframe //--
		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
			CFrame.Angles(0, self.HorizontalAngle, 0) *
			CFrame.Angles(self.VerticalAngle, 0, 0) *
			CFrame.new(offset)

		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
		----
		--// Raycast for obstructions //--
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		local raycastResult = workspace:Raycast(
			humanoidRootPart.Position,
			newCameraCFrame.Position - humanoidRootPart.Position,
			raycastParams
		)
		----

		--// Address obstructions if any //--
		if (raycastResult ~= nil) then
			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
		end
		----

		--// Address character alignment //--
		if (self.IsCharacterAligned == true) and humanoid then
			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
				CFrame.Angles(0, self.HorizontalAngle, 0)
			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed/2)
		end
		----

		currentCamera.CFrame = newCameraCFrame

	else
		-- Character doesn't exist (respawning), don't disable the camera system
		-- Just skip this frame update and wait for character to respawn
		return
	end
end


function CLASS:ConfigureStateForEnabled()
	self:SaveCameraSettings()
	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")

	-- Wait for character to exist before setting alignment
	local character, humanoid, rootPart = getCharacterComponents()
	if humanoid then
		self:SetCharacterAlignment(false)
	end

	-- Only set mouse step for non-mobile devices
	if not self.isMobile then
		self:SetMouseStep(true)
	end

	self:SetShoulderDirection(1)

	--// Calculate angles //--
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local x, y, z = cameraCFrame:ToOrientation()
	local horizontalAngle = y
	local verticalAngle = x
	----

	self.HorizontalAngle = horizontalAngle
	self.VerticalAngle = verticalAngle

	-- Setup touch input for mobile
	if self.isMobile then
		self:setupTouchInput()
	end
end

function CLASS:ConfigureStateForDisabled()
	if self.SavedCameraSettings then
		self:LoadCameraSettings()
	end
	if self.SavedMouseBehavior then
		USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
	end
	self:SetActiveCameraSettings("DefaultShoulder")

	-- Only set character alignment if character exists
	local character, humanoid, rootPart = getCharacterComponents()
	if humanoid then
		self:SetCharacterAlignment(false)
	end

	self:SetMouseStep(false)
	self:SetShoulderDirection(1)
	self.HorizontalAngle = 0
	self.VerticalAngle = 0

	-- Cleanup touch input
	if self.isMobile then
		self:cleanupTouchInput()
	end

	-- Clean up shift lock if active
	if shiftLockActive then
		RUN_SERVICE:UnbindFromRenderStep("ShiftLock")
		shiftLockActive = false
	end
end
function CLASS:IsPlayerAiming()
	return self.m2Active
end

function CLASS:SetZoomOut(zoomOut)
    -- If no argument passed, toggle the state
    if zoomOut == nil then
        zoomOut = not self.IsZoomedOut
    end
    
    assert(typeof(zoomOut) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(zoomOut))
    
    if not self.IsEnabled then
        warn("OTS Camera System Logic Warning: Attempt to change zoom without enabling OTS camera system")
        return
    end
    
    -- Set the zoom state
	self.IsZoomedOut = zoomOut
	
	warn(zoomOut)
    
    if self.IsZoomedOut then
        -- Zoom out
        self:SetActiveCameraSettings("ZoomedOut")
    else
        -- Return to default
        self:SetActiveCameraSettings("DefaultShoulder")
    end
    
    --return self.IsZoomedOut  -- Return the current state
end

function CLASS:Enable()
	assert(not self.IsEnabled, "Already enabled")
	self.IsEnabled = true
	self.EnabledEvent:Fire()

	self:ConfigureStateForEnabled()
	
	-- bind the zoom out camera to server event for respawn
	RespawnZoomOutCameraEvent.OnClientEvent:Connect(function(player, Boolean:boolean)
		self:SetZoomOut(Boolean)
	end)

	-- Bind update loop
	RUN_SERVICE:BindToRenderStep(
		UPDATE_UNIQUE_KEY,
		Enum.RenderPriority.Camera.Value - 10,
		function()
			if self.IsEnabled then self:Update() end
		end
	)
	
	return {
		SetShoulderDirection = function(shoulder) self:SetShoulderDirection(shoulder) end,
		SetMouseStep = function(steppedIn) self:SetMouseStep(steppedIn) end,
		SetActiveCameraSettings = function(settings) self:SetActiveCameraSettings(settings) end,
	}
	
end

function CLASS:CenterCameraYAxis(duration)
	-- Duration in seconds for the smooth transition (defaults to 0.3 seconds)
	duration = duration or 0.3

	assert(typeof(duration) == "number", "OTS Camera System Argument Error: number expected for duration, got " .. typeof(duration))
	assert(duration > 0, "OTS Camera System Argument Error: duration must be greater than 0")

	if not self.IsEnabled then
		warn("OTS Camera System Logic Warning: Attempt to center camera without enabling OTS camera system")
		return
	end

	-- Stop any existing centering animation
	if self.centeringCoroutine then
		task.cancel(self.centeringCoroutine)
	end

	-- Start a new centering animation
	self.centeringCoroutine = task.spawn(function()
		local startVerticalAngle = self.VerticalAngle
		local targetVerticalAngle = 0
		local elapsed = 0

		while elapsed < duration do
			local dt = task.wait()
			elapsed += dt

			-- Calculate alpha (0 to 1) based on elapsed time
			local alpha = math.min(elapsed / duration, 1)

			-- Smooth interpolation (ease-out)
			alpha = 1 - (1 - alpha)^3  -- Cubic ease-out for smoother motion

			-- Lerp between start and target
			self.VerticalAngle = Lerp(startVerticalAngle, targetVerticalAngle, alpha)

			-- Clamp to ensure it stays within limits
			self.VerticalAngle = math.rad(math.clamp(
				math.deg(self.VerticalAngle), 
				self.VerticalAngleLimits.Min, 
				self.VerticalAngleLimits.Max
				))
		end

		-- Ensure we end exactly at target
		self.VerticalAngle = targetVerticalAngle
		self.centeringCoroutine = nil
	end)
end

-- Alternative: Instant center (no lerp)
function CLASS:CenterCameraYAxisInstant()
	if not self.IsEnabled then
		warn("OTS Camera System Logic Warning: Attempt to center camera without enabling OTS camera system")
		return
	end

	-- Immediately set vertical angle to 0 (looking straight ahead)
	self.VerticalAngle = 0

	return self.VerticalAngle
end

function CLASS:Disable()
	assert(self.IsEnabled, "Already disabled")
	self:ConfigureStateForDisabled()
	self.IsEnabled = false
	self.DisabledEvent:Fire()
	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
end




return CLASS.new() :: OTS_Camera



--local CLASS = {}
--CLASS.__index = CLASS
--export type OTS_Camera = {
--	SetActiveCameraSettings: (self: OTS_Camera, cameraSettings: string) -> (),
--	SetCharacterAlignment: (self: OTS_Camera, aligned: boolean) -> (),
--	SetMouseStep: (self: OTS_Camera, steppedIn: boolean) -> (),
--	SetShoulderDirection: (self: OTS_Camera, shoulderDirection: number) -> (),
--	IsPlayerAiming: (self: OTS_Camera) -> boolean,
--	Enable: (self: OTS_Camera) -> (),
--	Disable: (self: OTS_Camera) -> (),
--	-- Add other public methods/properties you need autocomplete for
--}
----// SERVICES //--

--local PLAYERS_SERVICE = game:GetService("Players")
--local RUN_SERVICE = game:GetService("RunService")
--local USER_INPUT_SERVICE = game:GetService("UserInputService")
--local CONTEXT_ACTION_SERVICE = game:GetService("ContextActionService")
--local USER_GAME_SETTINGS = UserSettings():GetService("UserGameSettings")

----// CONSTANTS //--

--local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
--local MOUSE = LOCAL_PLAYER:GetMouse()

--local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

---- Mobile touch constants (from Roblox CameraInput)
--local ROTATION_SPEED_TOUCH = Vector2.new(1, 0.66) -- (rad/inputdelta)
--local MIN_TOUCH_SENSITIVITY_FRACTION = 0.25 -- 25% sensitivity at 90°

----// VARIABLES //--

----// Mobile Touch Handling //--
--local function adjustTouchPitchSensitivity(delta: Vector2): Vector2
--	local camera = workspace.CurrentCamera

--	if not camera then
--		return delta
--	end

--	-- get the camera pitch in world space
--	local pitch = camera.CFrame:ToEulerAnglesYXZ()

--	if delta.Y*pitch >= 0 then
--		-- do not reduce sensitivity when pitching towards the horizon
--		return delta
--	end

--	-- set up a line to fit:
--	-- 1 = f(0)
--	-- 0 = f(±pi/2)
--	local curveY = 1 - (2*math.abs(pitch)/math.pi)^0.75

--	-- remap curveY from [0, 1] -> [MIN_TOUCH_SENSITIVITY_FRACTION, 1]
--	local sensitivity = curveY*(1 - MIN_TOUCH_SENSITIVITY_FRACTION) + MIN_TOUCH_SENSITIVITY_FRACTION

--	return Vector2.new(1, sensitivity)*delta
--end

--local function isInDynamicThumbstickArea(pos: Vector3): boolean
--	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
--	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
--	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
--	local thumbstickFrame = touchFrame and touchFrame:FindFirstChild("DynamicThumbstickFrame")

--	if not thumbstickFrame then
--		return false
--	end

--	if not touchGui.Enabled then
--		return false
--	end

--	local posTopLeft = thumbstickFrame.AbsolutePosition
--	local posBottomRight = posTopLeft + thumbstickFrame.AbsoluteSize

--	return
--		pos.X >= posTopLeft.X and
--		pos.Y >= posTopLeft.Y and
--		pos.X <= posBottomRight.X and
--		pos.Y <= posBottomRight.Y
--end

--local function isInJumpButtonArea(pos: Vector3): boolean
--	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
--	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
--	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
--	local jumpButton = touchFrame and touchFrame:FindFirstChild("JumpButton")

--	if not jumpButton then
--		return false
--	end

--	if not touchGui.Enabled then
--		return false
--	end

--	local posTopLeft = jumpButton.AbsolutePosition
--	local posBottomRight = posTopLeft + jumpButton.AbsoluteSize

--	return
--		pos.X >= posTopLeft.X and
--		pos.Y >= posTopLeft.Y and
--		pos.X <= posBottomRight.X and
--		pos.Y <= posBottomRight.Y
--end

----// CONSTRUCTOR //--

--function CLASS.new()

--	--// Events //--
--	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
--	local characterAlignmentChangedEvent = Instance.new("BindableEvent")
--	local mouseStepChangedEvent = Instance.new("BindableEvent")
--	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
--	local enabledEvent = Instance.new("BindableEvent")
--	local disabledEvent = Instance.new("BindableEvent")
--	----

--	-- Touch state variables
--	local touchState = {
--		Move = Vector2.new(),
--		panInputCount = 0,
--		touches = {}, -- {[InputObject] = sunk}
--		dynamicThumbstickInput = nil,
--	}

--	function CLASS:incPanInputCount()
--		touchState.panInputCount = math.max(0, touchState.panInputCount + 1)
--	end

--	function CLASS:decPanInputCount()
--		touchState.panInputCount = math.max(0, touchState.panInputCount - 1)
--	end

--	local function resetTouchState()
--		touchState.touches = {}
--		touchState.dynamicThumbstickInput = nil
--		touchState.Move = Vector2.new()
--		touchState.panInputCount = 0
--	end

--	local dataTable = setmetatable(
--		{
--			isMobile = USER_INPUT_SERVICE.TouchEnabled and not USER_INPUT_SERVICE.KeyboardEnabled,
--			isController = USER_INPUT_SERVICE.GamepadEnabled,

--			--// Properties //--
--			SavedCameraSettings = nil,
--			SavedMouseBehavior = nil,
--			ActiveCameraSettings = nil,
--			HorizontalAngle = 0,
--			VerticalAngle = 0,
--			ShoulderDirection = 1,
--			----

--			--// Touch State //--
--			touchState = touchState,
--			touchConnections = {},
--			----

--			--// Flags //--
--			IsCharacterAligned = false,
--			IsMouseSteppedIn = false,
--			IsEnabled = false,
--			----

--			--// Events //--
--			ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
--			ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
--			CharacterAlignmentChangedEvent = characterAlignmentChangedEvent,
--			CharacterAlignmentChanged = characterAlignmentChangedEvent.Event,
--			MouseStepChangedEvent = mouseStepChangedEvent,
--			MouseStepChanged = mouseStepChangedEvent.Event,
--			ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
--			ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
--			EnabledEvent = enabledEvent,
--			Enabled = enabledEvent.Event,
--			DisabledEvent = disabledEvent,
--			Disabled = disabledEvent.Event,
--			----

--			--// Configurations //--
--			VerticalAngleLimits = NumberRange.new(-45, 45),
--			----

--			--// Camera Settings //--
--			CameraSettings = {

--				DefaultShoulder = {
--					FieldOfView = 70,
--					Offset = Vector3.new(2.5, 2.5, 8),
--					Sensitivity = 3.5,
--					MobileSensitivity = 3.5,
--					ControllerSensitivity = 1.5,
--					LerpSpeed = 0.5
--				},

--				ZoomedShoulder = {
--					FieldOfView = 40,
--					Offset = Vector3.new(3, 2, 8),
--					Sensitivity = 1.5,
--					MobileSensitivity = 1.5,
--					ControllerSensitivity = 1.5,
--					LerpSpeed = 0.5
--				}

--			}
--			----

--		},
--		CLASS
--	)
--	local proxyTable = setmetatable(
--		{

--		},
--		{
--			__index = function(self, index)
--				return dataTable[index]
--			end,
--			__newindex = function(self, index, newValue)
--				dataTable[index] = newValue
--			end
--		}
--	)

--	return proxyTable
--end

----// FUNCTIONS //--

--local function Lerp(x, y, a)
--	return x + (y - x) * a
--end

----// METHODS //--

----// Touch Input Methods //--
--function CLASS:setupTouchInput()
--	if not self.isMobile then return end

--	-- Clear existing connections
--	for _, conn in pairs(self.touchConnections) do
--		conn:Disconnect()
--	end
--	self.touchConnections = {}

--	local function touchBegan(input: InputObject, sunk: boolean)
--		if input.UserInputType ~= Enum.UserInputType.Touch then return end

--		-- Always ignore touches that start in UI areas (thumbstick or jump button)
--		if isInDynamicThumbstickArea(input.Position) or isInJumpButtonArea(input.Position) then
--			self.touchState.dynamicThumbstickInput = input
--			return
--		end

--		-- Only count non-sunk touches for camera panning
--		if not sunk then
--			self:incPanInputCount()
--		end

--		-- register the finger
--		self.touchState.touches[input] = sunk
--	end

--	local function touchEnded(input: InputObject, sunk: boolean)
--		if input.UserInputType ~= Enum.UserInputType.Touch then return end

--		-- reset the DT input
--		if input == self.touchState.dynamicThumbstickInput then
--			self.touchState.dynamicThumbstickInput = nil
--		end

--		-- reset pan state if one unsunk finger lifts
--		if self.touchState.touches[input] == false then
--			self.decPanInputCount()
--		end

--		-- unregister input
--		self.touchState.touches[input] = nil
--	end

--	local function touchChanged(input, sunk)
--		if input.UserInputType ~= Enum.UserInputType.Touch then return end

--		-- ignore movement from UI elements (thumbstick, jump button, etc.)
--		if input == self.touchState.dynamicThumbstickInput then
--			return
--		end

--		-- fixup unknown touches
--		if self.touchState.touches[input] == nil then
--			self.touchState.touches[input] = sunk
--		end

--		-- collect unsunk touches (only these should affect camera)
--		local unsunkTouches = {}
--		for touch, touchSunk in pairs(self.touchState.touches) do
--			if not touchSunk then
--				table.insert(unsunkTouches, touch)
--			end
--		end

--		-- Only register camera movement from touches that are:
--		-- 1. Not sunk by UI
--		-- 2. Not in control areas (thumbstick/jump button)
--		if #unsunkTouches >= 1 and self.touchState.touches[input] == false then
--			-- Don't add movement if this touch started in a control area
--			if not (isInDynamicThumbstickArea(input.Position) or isInJumpButtonArea(input.Position)) then
--				local delta = input.Delta
--				self.touchState.Move += Vector2.new(delta.X, delta.Y)
--			end
--		end
--	end

--	local function inputBegan(input, sunk)
--		touchBegan(input, sunk)
--	end

--	local function inputChanged(input, sunk)
--		touchChanged(input, sunk)
--	end

--	local function inputEnded(input, sunk)
--		touchEnded(input, sunk)
--	end

--	-- Connect input events
--	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputBegan:Connect(inputBegan))
--	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputChanged:Connect(inputChanged))
--	table.insert(self.touchConnections, USER_INPUT_SERVICE.InputEnded:Connect(inputEnded))
--end

--function CLASS:cleanupTouchInput()
--	for _, conn in pairs(self.touchConnections) do
--		conn:Disconnect()
--	end
--	self.touchConnections = {}

--	-- Reset touch state
--	self.touchState.touches = {}
--	self.touchState.dynamicThumbstickInput = nil
--	self.touchState.Move = Vector2.new()
--	self.touchState.panInputCount = 0
--end

--function CLASS:resetTouchStateForFrame()
--	self.touchState.Move = Vector2.new()
--end

--function CLASS:getRotationActivated(): boolean
--	if self.isMobile then
--		return self.touchState.panInputCount > 0
--	else
--		-- For mouse, we can check if right mouse button is held or mouse is moving
--		return USER_INPUT_SERVICE:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
--	end
--end

----// //--
--function CLASS:SetActiveCameraSettings(cameraSettings)
--	assert(cameraSettings ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(cameraSettings) == "string", "OTS Camera System Argument Error: string expected, got " .. typeof(cameraSettings))
--	assert(self.CameraSettings[cameraSettings] ~= nil, "OTS Camera System Argument Error: Attempt to set unrecognized camera settings " .. cameraSettings)
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change active camera settings without enabling OTS camera system")
--		return
--	end

--	self.ActiveCameraSettings = cameraSettings
--	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
--end

--function CLASS:SetCharacterAlignment(aligned)
--	assert(aligned ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(aligned) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(aligned))
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change character alignment without enabling OTS camera system")
--		return
--	end

--	local character = LOCAL_PLAYER.Character
--	local humanoid = (character ~= nil) and (character:FindFirstChild("Humanoid"))

--	humanoid.AutoRotate = not aligned
--	self.IsCharacterAligned = aligned
--	self.CharacterAlignmentChangedEvent:Fire(aligned)
--end

--function CLASS:SetMouseStep(steppedIn)
--	assert(steppedIn ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(steppedIn) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(steppedIn))
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change mouse step without enabling OTS camera system")
--		return
--	end

--	self.IsMouseSteppedIn = steppedIn
--	self.MouseStepChangedEvent:Fire(steppedIn)
--	if (steppedIn == true) then
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter

--		-- added by IronBeliever
--		USER_INPUT_SERVICE.MouseIconEnabled = false
--	else
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default

--		-- added by IronBeliever
--		USER_INPUT_SERVICE.MouseIconEnabled = true
--	end
--end

--function CLASS:SetShoulderDirection(shoulderDirection)
--	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
--	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change shoulder direction without enabling OTS camera system")
--		return
--	end

--	self.ShoulderDirection = shoulderDirection
--	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
--end
------

----// //--
--function CLASS:SaveCameraSettings()
--	local currentCamera = workspace.CurrentCamera
--	self.SavedCameraSettings = {
--		FieldOfView = currentCamera.FieldOfView,
--		CameraSubject = currentCamera.CameraSubject,
--		CameraType = currentCamera.CameraType
--	}
--end

--function CLASS:LoadCameraSettings()
--	local currentCamera = workspace.CurrentCamera
--	for setting, value in pairs(self.SavedCameraSettings) do
--		currentCamera[setting] = value
--	end
--end
------

----// //--
--function CLASS:Update()
--	local currentCamera = workspace.CurrentCamera
--	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]

--	--// Address mouse behavior and camera type //--
--	if (self.IsMouseSteppedIn == true) then
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
--	else
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
--	end
--	currentCamera.CameraType = Enum.CameraType.Scriptable
--	---

--	if self.isMobile then
--		--// Address touch input //--
--		local mobileSensitivity = activeCameraSettings.MobileSensitivity or activeCameraSettings.Sensitivity
--		local touchDelta = adjustTouchPitchSensitivity(self.touchState.Move) * mobileSensitivity
--		self.HorizontalAngle -= touchDelta.X * ROTATION_SPEED_TOUCH.X / currentCamera.ViewportSize.X
--		self.VerticalAngle -= touchDelta.Y * ROTATION_SPEED_TOUCH.Y / currentCamera.ViewportSize.Y
--		self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))

--		-- Reset touch movement for next frame
--		self:resetTouchStateForFrame()
--		----
--	else
--		--// Address mouse input //--
--		local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
--		self.HorizontalAngle -= mouseDelta.X/currentCamera.ViewportSize.X
--		self.VerticalAngle -= mouseDelta.Y/currentCamera.ViewportSize.Y
--		self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))

--		--// Address controller input //--
--		if self.isController then
--			local gamepadState = USER_INPUT_SERVICE:GetGamepadState(Enum.UserInputType.Gamepad1)
--			for _, input in ipairs(gamepadState) do
--				if input.KeyCode == Enum.KeyCode.Thumbstick2 then -- Right stick
--					local stickDelta = input.Position
--					-- Deadzone
--					if math.abs(stickDelta.X) > 0.1 or math.abs(stickDelta.Y) > 0.1 then
--						local controllerSensitivity = activeCameraSettings.ControllerSensitivity
--						-- Apply rotation from stick (fixed orientation)
--						self.HorizontalAngle += stickDelta.X * controllerSensitivity * -0.03 -- right = right
--						self.VerticalAngle -= stickDelta.Y * controllerSensitivity * -0.03 -- up = up (inverted Y)
--						self.VerticalAngle = math.rad(math.clamp(
--							math.deg(self.VerticalAngle),
--							self.VerticalAngleLimits.Min,
--							self.VerticalAngleLimits.Max
--							))
--					end
--				end
--			end
--		end



--	end



--	local character = LOCAL_PLAYER.Character
--	local humanoidRootPart = (character ~= nil) and (character:FindFirstChild("HumanoidRootPart"))
--	if (humanoidRootPart ~= nil) then

--		--// Lerp field of view //--
--		currentCamera.FieldOfView = Lerp(
--			currentCamera.FieldOfView, 
--			activeCameraSettings.FieldOfView, 
--			activeCameraSettings.LerpSpeed
--		)
--		----

--		--// Address shoulder direction //--
--		local offset = activeCameraSettings.Offset
--		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
--		----

--		--// Calculate new camera cframe //--
--		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
--			CFrame.Angles(0, self.HorizontalAngle, 0) *
--			CFrame.Angles(self.VerticalAngle, 0, 0) *
--			CFrame.new(offset)

--		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
--		----

--		--// Raycast for obstructions //--
--		local raycastParams = RaycastParams.new()
--		raycastParams.FilterDescendantsInstances = {character}
--		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
--		local raycastResult = workspace:Raycast(
--			humanoidRootPart.Position,
--			newCameraCFrame.p - humanoidRootPart.Position,
--			raycastParams
--		)
--		----

--		--// Address obstructions if any //--
--		if (raycastResult ~= nil) then
--			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
--			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
--			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
--			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
--		end
--		----

--		--// Address character alignment //--
--		if (self.IsCharacterAligned == true) then
--			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
--				CFrame.Angles(0, self.HorizontalAngle, 0)
--			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed/2)
--		end
--		----

--		currentCamera.CFrame = newCameraCFrame

--	else
--		self:Disable()
--	end
--end

--function CLASS:ConfigureStateForEnabled()
--	self:SaveCameraSettings()
--	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
--	self:SetActiveCameraSettings("DefaultShoulder")
--	self:SetCharacterAlignment(false)

--	-- Only set mouse step for non-mobile devices
--	if not self.isMobile then
--		self:SetMouseStep(true)
--	end

--	self:SetShoulderDirection(1)

--	--// Calculate angles //--
--	local cameraCFrame = workspace.CurrentCamera.CFrame
--	local x, y, z = cameraCFrame:ToOrientation()
--	local horizontalAngle = y
--	local verticalAngle = x
--	----

--	self.HorizontalAngle = horizontalAngle
--	self.VerticalAngle = verticalAngle

--	-- Setup touch input for mobile
--	if self.isMobile then
--		self:setupTouchInput()
--	end
--end

--function CLASS:ConfigureStateForDisabled()
--	self:LoadCameraSettings()
--	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
--	self:SetActiveCameraSettings("DefaultShoulder")
--	self:SetCharacterAlignment(false)
--	self:SetMouseStep(false)
--	self:SetShoulderDirection(1)
--	self.HorizontalAngle = 0
--	self.VerticalAngle = 0

--	-- Cleanup touch input
--	if self.isMobile then
--		self:cleanupTouchInput()
--	end
--end

--function CLASS:Enable()
--	assert(self.IsEnabled == false, "OTS Camera System Logic Error: Attempt to enable without disabling")

--	self.IsEnabled = true

--	self.EnabledEvent:Fire()

--	self:ConfigureStateForEnabled()
--	RUN_SERVICE:BindToRenderStep(
--		UPDATE_UNIQUE_KEY,
--		Enum.RenderPriority.Camera.Value - 10,
--		function()
--			if (self.IsEnabled == true) then
--				self:Update()
--			end
--		end
--	)

--end

--function CLASS:Disable()
--	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to disable without enabling")

--	self:ConfigureStateForDisabled()
--	self.IsEnabled = false
--	self.DisabledEvent:Fire()

--	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
--end
------

----// INSTRUCTIONS //--

--CLASS.__index = CLASS

--local singleton = CLASS.new() :: OTS_Camera


----// Added By IroneBeliver //--
---- Flag to track the state of MouseButton2
--local m2Active = false

--local tweenService = game:GetService("TweenService")


--local Players = game:GetService("Players")
--local UserInputService = game:GetService("UserInputService")
--local RunService = game:GetService("RunService")

--local plr = Players.LocalPlayer
--local shiftLockActive = false -- Global flag: true = shift lock enabled, false = disabled

---- Function to toggle shift lock on/off for the current character
--function shiftLock(active)
--	shiftLockActive = active
--	local character = plr.Character
--	if not character then return end

--	local humanoid = character:FindFirstChildOfClass("Humanoid")
--	local root = character:FindFirstChild("HumanoidRootPart")
--	if not humanoid or not root then return end

--	-- When shift lock is active, disable automatic rotation so we can control it manually.
--	humanoid.AutoRotate = not active

--	if active then		
--		RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
--			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- Lock the mouse to center

--			-- Get the camera's Y rotation
--			local camera = workspace.CurrentCamera
--			local _, yRotation = camera.CFrame:ToEulerAnglesYXZ()

--			-- Update only the rotation of the HRP without affecting its position.
--			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRotation, 0)
--		end)
--	else
--		RunService:UnbindFromRenderStep("ShiftLock")
--		UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- Restore default mouse behavior
--	end
--end


---- Function to enable camera-centered movement
--local function EnableCameraCenteredMovement()
--	shiftLock(true) -- Toggle shift lock
--end


---- Function to disable camera-centered movement
--local function DisableCameraCenteredMovement()
--	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
--	shiftLock(false) --Toggle off shift Lock
--end

---- Function to Check If Player Is Ainaming / Zooming
--function CLASS:IsPlayerAiming()
--	return m2Active
--end

---- InputBegan event handler
--USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
--	if not gameProcessedEvent and singleton.IsEnabled then

--		if inputObject.KeyCode == Enum.KeyCode.G then
--			singleton:SetShoulderDirection(-1)
--		elseif inputObject.KeyCode == Enum.KeyCode.H then
--			singleton:SetShoulderDirection(1)
--		end
--		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
--			if not m2Active then
--				m2Active = true
--				singleton:SetActiveCameraSettings("ZoomedShoulder")
--				if not singleton.isMobile then
--					EnableCameraCenteredMovement()
--				end
--			end
--		end

--		if inputObject.KeyCode == Enum.KeyCode.B then
--			singleton:SetMouseStep(not singleton.IsMouseSteppedIn)
--		end
--	end
--end)

---- InputEnded event handler
--USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
--	if not gameProcessedEvent and singleton.IsEnabled then
--		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
--			if m2Active then
--				m2Active = false
--				singleton:SetActiveCameraSettings("DefaultShoulder")
--				if not singleton.isMobile then
--					DisableCameraCenteredMovement()
--				end
--			end
--		end
--	end
--end)

--return singleton


-- Old module code
--[[--local CLASS = {}
--CLASS.__index = CLASS
--export type OTS_Camera = {
--	SetActiveCameraSettings: (self: OTS_Camera, cameraSettings: string) -> (),
--	SetCharacterAlignment: (self: OTS_Camera, aligned: boolean) -> (),
--	SetMouseStep: (self: OTS_Camera, steppedIn: boolean) -> (),
--	SetShoulderDirection: (self: OTS_Camera, shoulderDirection: number) -> (),
--	IsPlayerAiming: (self: OTS_Camera) -> boolean,
--	Enable: (self: OTS_Camera) -> (),
--	Disable: (self: OTS_Camera) -> (),
--	-- Add other public methods/properties you need autocomplete for
--}
----// SERVICES //--

--local PLAYERS_SERVICE = game:GetService("Players")
--local RUN_SERVICE = game:GetService("RunService")
--local USER_INPUT_SERVICE = game:GetService("UserInputService")

----// CONSTANTS //--

--local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
--local MOUSE = LOCAL_PLAYER:GetMouse()

--local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

----// VARIABLES //--



----// CONSTRUCTOR //--

--function CLASS.new()

--	--// Events //--
--	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
--	local characterAlignmentChangedEvent = Instance.new("BindableEvent")
--	local mouseStepChangedEvent = Instance.new("BindableEvent")
--	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
--	local enabledEvent = Instance.new("BindableEvent")
--	local disabledEvent = Instance.new("BindableEvent")
--	----

--	local dataTable = setmetatable(
--		{
--			isMobile = true,

--			--// Properties //--
--			SavedCameraSettings = nil,
--			SavedMouseBehavior = nil,
--			ActiveCameraSettings = nil,
--			HorizontalAngle = 0,
--			VerticalAngle = 0,
--			ShoulderDirection = 1,
--			----

--			--// Flags //--
--			IsCharacterAligned = false,
--			IsMouseSteppedIn = false,
--			IsEnabled = false,
--			----

--			--// Events //--
--			ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
--			ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
--			CharacterAlignmentChangedEvent = characterAlignmentChangedEvent,
--			CharacterAlignmentChanged = characterAlignmentChangedEvent.Event,
--			MouseStepChangedEvent = mouseStepChangedEvent,
--			MouseStepChanged = mouseStepChangedEvent.Event,
--			ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
--			ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
--			EnabledEvent = enabledEvent,
--			Enabled = enabledEvent.Event,
--			DisabledEvent = disabledEvent,
--			Disabled = disabledEvent.Event,
--			----

--			--// Configurations //--
--			VerticalAngleLimits = NumberRange.new(-45, 45),
--			----

--			--// Camera Settings //--
--			CameraSettings = {

--				DefaultShoulder = {
--					FieldOfView = 70,
--					Offset = Vector3.new(2.5, 2.5, 8),
--					Sensitivity = 3,
--					LerpSpeed = 0.5
--				},

--				ZoomedShoulder = {
--					FieldOfView = 40,
--					Offset = Vector3.new(3, 2, 8),
--					Sensitivity = 1.5,
--					LerpSpeed = 0.5
--				}

--			}
--			----

--		},
--		CLASS
--	)
--	local proxyTable = setmetatable(
--		{

--		},
--		{
--			__index = function(self, index)
--				return dataTable[index]
--			end,
--			__newindex = function(self, index, newValue)
--				dataTable[index] = newValue
--			end
--		}
--	)

--	return proxyTable
--end

----// FUNCTIONS //--

--local function Lerp(x, y, a)
--	return x + (y - x) * a
--end

----// METHODS //--

----// //--
--function CLASS:SetActiveCameraSettings(cameraSettings)
--	assert(cameraSettings ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(cameraSettings) == "string", "OTS Camera System Argument Error: string expected, got " .. typeof(cameraSettings))
--	assert(self.CameraSettings[cameraSettings] ~= nil, "OTS Camera System Argument Error: Attempt to set unrecognized camera settings " .. cameraSettings)
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change active camera settings without enabling OTS camera system")
--		return
--	end

--	self.ActiveCameraSettings = cameraSettings
--	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
--end

--function CLASS:SetCharacterAlignment(aligned)
--	assert(aligned ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(aligned) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(aligned))
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change character alignment without enabling OTS camera system")
--		return
--	end

--	local character = LOCAL_PLAYER.Character
--	local humanoid = (character ~= nil) and (character:FindFirstChild("Humanoid"))

--	humanoid.AutoRotate = not aligned
--	self.IsCharacterAligned = aligned
--	self.CharacterAlignmentChangedEvent:Fire(aligned)
--end

--function CLASS:SetMouseStep(steppedIn)
--	assert(steppedIn ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(steppedIn) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(steppedIn))
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change mouse step without enabling OTS camera system")
--		return
--	end

--	self.IsMouseSteppedIn = steppedIn
--	self.MouseStepChangedEvent:Fire(steppedIn)
--	if (steppedIn == true) then
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter

--		-- added by IronBeliever
--		USER_INPUT_SERVICE.MouseIconEnabled = false
--	else
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default

--		-- added by IronBeliever
--		USER_INPUT_SERVICE.MouseIconEnabled = true
--	end
--end

--function CLASS:SetShoulderDirection(shoulderDirection)
--	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
--	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
--	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
--	if (self.IsEnabled == false) then
--		warn("OTS Camera System Logic Warning: Attempt to change shoulder direction without enabling OTS camera system")
--		return
--	end

--	self.ShoulderDirection = shoulderDirection
--	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
--end
------

----// //--
--function CLASS:SaveCameraSettings()
--	local currentCamera = workspace.CurrentCamera
--	self.SavedCameraSettings = {
--		FieldOfView = currentCamera.FieldOfView,
--		CameraSubject = currentCamera.CameraSubject,
--		CameraType = currentCamera.CameraType
--	}
--end

--function CLASS:LoadCameraSettings()
--	local currentCamera = workspace.CurrentCamera
--	for setting, value in pairs(self.SavedCameraSettings) do
--		currentCamera[setting] = value
--	end
--end
------

----// //--
--function CLASS:Update()
--	local currentCamera = workspace.CurrentCamera
--	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]

--	--// Address mouse behavior and camera type //--
--	if (self.IsMouseSteppedIn == true) then
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
--	else
--		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
--	end
--	currentCamera.CameraType = Enum.CameraType.Scriptable
--	---

--	if self.isMobile  then

--	else
--		--// Address mouse input //--
--		local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
--		self.HorizontalAngle -= mouseDelta.X/currentCamera.ViewportSize.X
--		self.VerticalAngle -= mouseDelta.Y/currentCamera.ViewportSize.Y
--		self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
--		----
--	end



--	local character = LOCAL_PLAYER.Character
--	local humanoidRootPart = (character ~= nil) and (character:FindFirstChild("HumanoidRootPart"))
--	if (humanoidRootPart ~= nil) then

--		--// Lerp field of view //--
--		currentCamera.FieldOfView = Lerp(
--			currentCamera.FieldOfView, 
--			activeCameraSettings.FieldOfView, 
--			activeCameraSettings.LerpSpeed
--		)
--		----

--		--// Address shoulder direction //--
--		local offset = activeCameraSettings.Offset
--		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
--		----

--		--// Calculate new camera cframe //--
--		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
--			CFrame.Angles(0, self.HorizontalAngle, 0) *
--			CFrame.Angles(self.VerticalAngle, 0, 0) *
--			CFrame.new(offset)

--		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
--		----

--		--// Raycast for obstructions //--
--		local raycastParams = RaycastParams.new()
--		raycastParams.FilterDescendantsInstances = {character}
--		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
--		local raycastResult = workspace:Raycast(
--			humanoidRootPart.Position,
--			newCameraCFrame.p - humanoidRootPart.Position,
--			raycastParams
--		)
--		----

--		--// Address obstructions if any //--
--		if (raycastResult ~= nil) then
--			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
--			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
--			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
--			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
--		end
--		----

--		--// Address character alignment //--
--		if (self.IsCharacterAligned == true) then
--			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
--				CFrame.Angles(0, self.HorizontalAngle, 0)
--			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed/2)
--		end
--		----

--		currentCamera.CFrame = newCameraCFrame

--	else
--		self:Disable()
--	end
--end

--function CLASS:ConfigureStateForEnabled()
--	self:SaveCameraSettings()
--	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
--	self:SetActiveCameraSettings("DefaultShoulder")
--	self:SetCharacterAlignment(false)
--	self:SetMouseStep(true)
--	self:SetShoulderDirection(1)

--	--// Calculate angles //--
--	local cameraCFrame = workspace.CurrentCamera.CFrame
--	local x, y, z = cameraCFrame:ToOrientation()
--	local horizontalAngle = y
--	local verticalAngle = x
--	----

--	self.HorizontalAngle = horizontalAngle
--	self.VerticalAngle = verticalAngle
--end

--function CLASS:ConfigureStateForDisabled()
--	self:LoadCameraSettings()
--	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
--	self:SetActiveCameraSettings("DefaultShoulder")
--	self:SetCharacterAlignment(false)
--	self:SetMouseStep(false)
--	self:SetShoulderDirection(1)
--	self.HorizontalAngle = 0
--	self.VerticalAngle = 0
--end

--function CLASS:Enable()
--	assert(self.IsEnabled == false, "OTS Camera System Logic Error: Attempt to enable without disabling")

--	self.IsEnabled = true

--	self.EnabledEvent:Fire()

--	self:ConfigureStateForEnabled()
--	RUN_SERVICE:BindToRenderStep(
--		UPDATE_UNIQUE_KEY,
--		Enum.RenderPriority.Camera.Value - 10,
--		function()
--			if (self.IsEnabled == true) then
--				self:Update()
--			end
--		end
--	)

--end

--function CLASS:Disable()
--	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to disable without enabling")

--	self:ConfigureStateForDisabled()
--	self.IsEnabled = false
--	self.DisabledEvent:Fire()

--	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
--end
------

----// INSTRUCTIONS //--

--CLASS.__index = CLASS

--local singleton = CLASS.new() :: OTS_Camera


----// Added By IroneBeliver //--
---- Flag to track the state of MouseButton2
--local m2Active = false

--local tweenService = game:GetService("TweenService")


--local Players = game:GetService("Players")
--local UserInputService = game:GetService("UserInputService")
--local RunService = game:GetService("RunService")

--local plr = Players.LocalPlayer
--local shiftLockActive = false -- Global flag: true = shift lock enabled, false = disabled

---- Function to toggle shift lock on/off for the current character
--function shiftLock(active)
--	shiftLockActive = active
--	local character = plr.Character
--	if not character then return end

--	local humanoid = character:FindFirstChildOfClass("Humanoid")
--	local root = character:FindFirstChild("HumanoidRootPart")
--	if not humanoid or not root then return end

--	-- When shift lock is active, disable automatic rotation so we can control it manually.
--	humanoid.AutoRotate = not active

--	if active then		
--		RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
--			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- Lock the mouse to center

--			-- Get the camera's Y rotation
--			local camera = workspace.CurrentCamera
--			local _, yRotation = camera.CFrame:ToEulerAnglesYXZ()

--			-- Update only the rotation of the HRP without affecting its position.
--			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRotation, 0)
--		end)
--	else
--		RunService:UnbindFromRenderStep("ShiftLock")
--		UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- Restore default mouse behavior
--	end
--end


---- Function to enable camera-centered movement
--local function EnableCameraCenteredMovement()
--	shiftLock(true) -- Toggle shift lock
--end


---- Function to disable camera-centered movement
--local function DisableCameraCenteredMovement()
--	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
--	shiftLock(false) --Toggle off shift Lock
--end

---- Function to Check If Player Is Ainaming / Zooming
--function CLASS:IsPlayerAiming()
--	return m2Active
--end

---- InputBegan event handler
--USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
--	if not gameProcessedEvent and singleton.IsEnabled then

--		if inputObject.KeyCode == Enum.KeyCode.G then
--			singleton:SetShoulderDirection(-1)
--		elseif inputObject.KeyCode == Enum.KeyCode.H then
--			singleton:SetShoulderDirection(1)
--		end
--		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
--			if not m2Active then
--				m2Active = true
--				singleton:SetActiveCameraSettings("ZoomedShoulder")
--				EnableCameraCenteredMovement()
--			end
--		end

--		if inputObject.KeyCode == Enum.KeyCode.B then
--			singleton:.(not singleton.IsMouseSteppedIn)
--		end
--	end
--end)

---- InputEnded event handler
--USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
--	if not gameProcessedEvent and singleton.IsEnabled then
--		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
--			if m2Active then
--				m2Active = false
--				singleton:SetActiveCameraSettings("DefaultShoulder")
--				DisableCameraCenteredMovement()
--			end
--		end
--	end
--end)

--return singleton]]