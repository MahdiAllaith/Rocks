local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local OTS = require(ReplicatedStorage.Services["ClientManager-Service"]["OTS-Camera-ChildService"])


local NUM_SEGMENTS = 60
local beamThickness = 0.5
local beamLengthScale = 1

-- Use the actual workspace gravity consistently
local GRAVITY = Vector3.new(0, -workspace.Gravity, 0)

local beamSegments = {}
local isAiming = false
local isEquipped = false

local function cleanupBeamSegments()
	for _, seg in ipairs(beamSegments) do
		if seg and seg.Parent then
			seg:Destroy()
		end
	end
	beamSegments = {}
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

-- Match the EXACT physics from your throwing code
local function computeProjectileParams()
	local rightHandPos, cameraFacing = getThrowParameters()
	if not rightHandPos or not cameraFacing then return nil end

	-- Get the throw distance (same as in your throwing code)
	local throwDistance = LocalPlayer:GetAttribute("ThrowDestince")

	-- Calculate start and target positions EXACTLY like in your throwing code
	local startCFrame = rightHandPos
	local targetPos = startCFrame + cameraFacing * throwDistance + Vector3.new(0, -throwDistance * 0.2, 0)

	-- Calculate direction and force EXACTLY like in simulateThrow function
	local direction = (targetPos - startCFrame)
	local force = direction.Unit * math.sqrt(2 * workspace.Gravity * direction.Magnitude)

	return startCFrame, force
end

local function projectilePosition(FromPosition, v0, t)
	return FromPosition + v0 * t + 0.5 * GRAVITY * t * t
end

local function createBeamSegment(p0, p1, thickness)
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
	if not isEquipped then
		cleanupBeamSegments()
		return
	end

	local FromPosition, v0 = computeProjectileParams()
	if not FromPosition or not v0 then return end

	cleanupBeamSegments()

	-- Calculate how long the projectile will be in the air
	-- Using quadratic formula to find when projectile hits ground level or below
	local startHeight = FromPosition.Y
	local verticalVelocity = v0.Y
	local gravity = workspace.Gravity

	-- Solve: startHeight + verticalVelocity*t - 0.5*gravity*t^2 = groundLevel
	-- Assuming ground level is 0 or we want to show a reasonable flight time
	local discriminant = verticalVelocity^2 + 2 * gravity * startHeight
	if discriminant < 0 then
		-- If discriminant is negative, projectile won't hit ground, use a default time
		discriminant = 0
	end
	local flightTime = (verticalVelocity + math.sqrt(discriminant)) / gravity

	-- Scale the flight time for beam visualization
	local scaledDuration = flightTime * beamLengthScale

	local points = {}
	for i = 0, NUM_SEGMENTS do
		local t = (i / NUM_SEGMENTS) * scaledDuration
		table.insert(points, projectilePosition(FromPosition, v0, t))
	end

	for i = 1, #points - 1 do
		local segmentPart = createBeamSegment(points[i], points[i+1], beamThickness)
		table.insert(beamSegments, segmentPart)
	end
end

local tool = script.Parent

local isRightMouseDown = false -- new variable

-- Tool events
tool.Equipped:Connect(function()
	isEquipped = true
end)

tool.Unequipped:Connect(function()
	isEquipped = false
	isRightMouseDown = false
	cleanupBeamSegments()
end)

-- Mouse events for right-click
Mouse.Button2Down:Connect(function()
	if isEquipped then
		isRightMouseDown = true
	end
end)

Mouse.Button2Up:Connect(function()
	isRightMouseDown = false
	cleanupBeamSegments()
end)

-- Render loop
RunService.RenderStepped:Connect(function()
	if isEquipped and isRightMouseDown then
		updateTrajectoryBeam()
	else
		cleanupBeamSegments()
	end
end)
