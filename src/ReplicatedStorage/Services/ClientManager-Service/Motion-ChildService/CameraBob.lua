-- CameraShake.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local Module = {}

local Connection: RBXScriptConnection?
local Enabled = false

local DeltaTimeOffset = 1 / 60
local ShakeOffset = CFrame.new()
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

		ShakeOffset = ShakeOffset:Lerp(
			CFrame.Angles(
				IsMoving and math.rad(math.noise(time() * 15)) / 5 * Offset or 0,
				IsMoving and math.rad(math.noise(time() * 20 + 50)) / 4 * Offset or 0,
				IsMoving and math.rad(math.noise(time() * 10 + 100)) / 6 * Offset or 0
			),
			0.25
		)
	
		Camera.CFrame = Camera.CFrame * ShakeOffset
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
