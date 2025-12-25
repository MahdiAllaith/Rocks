--[[-- CameraBobbing.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local Module = {}

local Connection: RBXScriptConnection?
local Enabled = false

local DeltaTimeOffset = 1 / 60
local BobbingOffset = CFrame.new()
local RunningSpeedThreshold = 16

local function GetHumanoid(): Humanoid?
	local player = Players.LocalPlayer
	local character = player and (player.Character or player.CharacterAdded:Wait())
	return character and character:FindFirstChildOfClass("Humanoid")
end

function Module.Enable()
	if Enabled then return end
	local Humanoid = GetHumanoid()
	if not Humanoid then return end

	Enabled = true
	Connection = RunService.RenderStepped:Connect(function(DeltaTime)
		local Offset = DeltaTime / DeltaTimeOffset
		local IsMoving = Humanoid.MoveDirection.Magnitude > 0.01
		local IsRunning = Humanoid.WalkSpeed > RunningSpeedThreshold

		local ZDirection = -math.round(Humanoid.MoveDirection:Dot(Camera.CFrame.RightVector))
		BobbingOffset = BobbingOffset:Lerp(
			CFrame.Angles(
				IsMoving and IsRunning and math.rad(math.sin(time() * 20)) / 3.5 * Offset or
					IsMoving and math.rad(math.sin(time())) / 50 * Offset or 0,

				IsMoving and IsRunning and math.rad(math.sin(time() * 10)) / 3 * Offset or 
					IsMoving and math.rad(math.cos(time())) / 50 * Offset or 0,

				math.rad(ZDirection * 2) * Offset
			),
			0.3
		)

		Camera.CFrame = Camera.CFrame * BobbingOffset
	end)
end

function Module.Disable()
	if not Enabled then return end
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
	Enabled = false
end

Module.Enable()
return Module
]]

-- CameraBobbing.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local Module = {}

local Connection: RBXScriptConnection?
local Enabled = false

-- CONFIGURATION
local DeltaTimeOffset = 1 / 60
local BobbingOffset = CFrame.new()
local RunningSpeedThreshold = 16       -- > this = running, <= this = walking
local WalkShakeIntensity = 0.15        -- walking shake strength
local RunShakeIntensity = 0.3
-- running shake strength

local function GetHumanoid(): Humanoid?
	local player = Players.LocalPlayer
	local character = player and (player.Character or player.CharacterAdded:Wait())
	return character and character:FindFirstChildOfClass("Humanoid")
end

function Module.Enable()
	if Enabled then return end
	local Humanoid = GetHumanoid()
	if not Humanoid then return end

	Enabled = true
	Connection = RunService.RenderStepped:Connect(function(DeltaTime)
		local Offset = DeltaTime / DeltaTimeOffset
		local MoveMagnitude = Humanoid.MoveDirection.Magnitude
		local IsMoving = MoveMagnitude > 0.01

		-- check walking vs running
		local Intensity = Humanoid.WalkSpeed > RunningSpeedThreshold
			and RunShakeIntensity
			or WalkShakeIntensity

		-- sideways tilt (strafe)
		local ZDirection = -math.round(Humanoid.MoveDirection:Dot(Camera.CFrame.RightVector))

		-- apply bobbing
		BobbingOffset = BobbingOffset:Lerp(
			CFrame.Angles(
				IsMoving and math.rad(math.sin(time() * (Intensity == RunShakeIntensity and 20 or 10))) * Intensity * Offset or 0,
				IsMoving and math.rad(math.cos(time() * (Intensity == RunShakeIntensity and 15 or 8))) * Intensity * Offset or 0,
				IsMoving and math.rad(ZDirection * 2) * Offset or 0
			),
			0.3
		)

		Camera.CFrame = Camera.CFrame * BobbingOffset
	end)
end

function Module.Disable()
	if not Enabled then return end
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
	Enabled = false
end

Module.Enable()
return Module
