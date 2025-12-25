--@module ProjectileBeamVisualizer
--@description: Visualizes projectile trajectory for aiming (client-side)
--@author:
--@date:

-----------------------------
-- SERVICES --
-----------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-----------------------------
-- MODULE --
-----------------------------
local ProjectileBeamVisualizer = {}

-----------------------------
-- VARIABLES --
-----------------------------
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local OTS = require(ReplicatedStorage.Services["ClientManager-Service"]["OTS-Camera-ChildService"])

local NUM_SEGMENTS = 60
local BEAM_THICKNESS = 0.5
local BEAM_LENGTH_SCALE = 1
local GRAVITY = Vector3.new(0, -workspace.Gravity, 0)

local beamSegments: {Instance} = {}
local isActive = false
local activeTool: Tool? = nil

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

local function cleanupBeamSegments()
	for _, seg in ipairs(beamSegments) do
		if seg and seg.Parent then
			seg:Destroy()
		end
	end
	table.clear(beamSegments)
end

local function getThrowParameters()
	local character = LocalPlayer.Character
	if not character then return nil end
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then return nil end
	local rightHandPos = rightHand.Position
	local camera = workspace.CurrentCamera
	local facing = camera.CFrame.LookVector.Unit
	return rightHandPos, facing
end

local function computeProjectileParams()
	local rightHandPos, cameraFacing = getThrowParameters()
	if not rightHandPos or not cameraFacing then return nil end

	local throwDistance = LocalPlayer:GetAttribute("ThrowDestince")
	if not throwDistance then throwDistance = 50 end -- fallback

	local startCFrame = rightHandPos
	local targetPos = startCFrame + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)

	local direction = (targetPos - startCFrame)
	local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

	return startCFrame, force
end

local function projectilePosition(fromPosition: Vector3, v0: Vector3, t: number)
	return fromPosition + v0 * t + 0.5 * GRAVITY * t * t
end

local function createBeamSegment(p0: Vector3, p1: Vector3, thickness: number)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.CFrame = CFrame.new((p0 + p1) / 2)
	part.Parent = workspace

	local att0 = Instance.new("Attachment", part)
	att0.Position = part.CFrame:PointToObjectSpace(p0)

	local att1 = Instance.new("Attachment", part)
	att1.Position = part.CFrame:PointToObjectSpace(p1)

	local beam = Instance.new("Beam", part)
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = thickness
	beam.Width1 = thickness
	beam.Color = ColorSequence.new(Color3.new(1, 0, 0))

	return part
end

local function updateTrajectoryBeam()
	local fromPosition, v0 = computeProjectileParams()
	if not fromPosition or not v0 then return end

	cleanupBeamSegments()

	-- Estimate flight time
	local startHeight = fromPosition.Y
	local verticalVelocity = v0.Y
	local gravity = workspace.Gravity

	local discriminant = verticalVelocity ^ 2 + 2 * gravity * startHeight
	if discriminant < 0 then discriminant = 0 end
	local flightTime = (verticalVelocity + math.sqrt(discriminant)) / gravity
	local scaledDuration = flightTime * BEAM_LENGTH_SCALE

	local points = {}
	for i = 0, NUM_SEGMENTS do
		local t = (i / NUM_SEGMENTS) * scaledDuration
		points[i + 1] = projectilePosition(fromPosition, v0, t)
	end

	for i = 1, #points - 1 do
		local seg = createBeamSegment(points[i], points[i + 1], BEAM_THICKNESS)
		table.insert(beamSegments, seg)
	end
end

-----------------------------
-- PUBLIC API --
-----------------------------

function ProjectileBeamVisualizer:Start(tool: Tool?)
	if isActive then return end
	isActive = true
	activeTool = tool or nil
end

function ProjectileBeamVisualizer:Stop()
	isActive = false
	activeTool = nil
	cleanupBeamSegments()
end

-----------------------------
-- MAIN LOOP --
-----------------------------
RunService.RenderStepped:Connect(function()
	if isActive then
		updateTrajectoryBeam()
	else
		cleanupBeamSegments()
	end
end)

return ProjectileBeamVisualizer
