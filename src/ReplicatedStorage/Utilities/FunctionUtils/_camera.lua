--!strict
--@author: crusherfire
--@date: 12/28/24
--[[@description:
	Camera utility functions. Great for Viewport Frames!
]]
-----------------------------
-- SERVICES --
-----------------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-----------------------------
-- DEPENDENCIES --
-----------------------------

-----------------------------
-- TYPES --
-----------------------------

-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Computes the diameter of a cuboid.
function Module.getCuboidDiameter(size: Vector3): number
	return math.sqrt(size.X^2 + size.Y^2 + size.Z^2)
end

-- Fits a sphere to the camera, computing how far back to zoom the camera from the center of the sphere.
function Module.fitSphereToCamera(radius: number, fovDeg: number, aspectRatio: number)
	local halfFov = 0.5 * math.rad(fovDeg)
	if aspectRatio < 1 then
		halfFov = math.atan(aspectRatio * math.tan(halfFov))
	end
	return radius / math.sin(halfFov)
end

-- Uses spherical bounding box to calculate how far back to move a camera.
-- If you need a more accurate calculation for rectangular bounding boxes, use <code>fitCameraAlignedBoundingBoxToCamera()</code>.
function Module.fitBoundingBoxToCamera(size: Vector3, fovDeg: number, aspectRatio: number): number
	-- See: https://community.khronos.org/t/zoom-to-fit-screen/59857/12
	local radius = Module.getCuboidDiameter(size) / 2
	return Module.fitSphereToCamera(radius, fovDeg, aspectRatio)
end

-- Given the camera-aligned bounding box of an object, this calculates how far back to move the camera.
-- Use <code>Math.getCameraAlignedBoundingBox()</code>.
function Module.fitCameraAlignedBoundingBoxToCamera(size: Vector3, cameraFovDeg: number, aspectRatio: number): number
	-- Convert vertical FOV to radians
	local vFov = math.rad(cameraFovDeg)

	-- Compute horizontal FOV based on aspect ratio
	local hFov = 2 * math.atan(aspectRatio * math.tan(vFov / 2))

	-- Extract the box width/height
	local boxWidth  = size.X
	local boxHeight = size.Y

	-- Compare box aspect ratio to screen aspect ratio
	local boxAspect = boxWidth / boxHeight
	local screenAspect = aspectRatio

	if boxAspect > screenAspect then
		-- Box is relatively wide -> horizontal dimension is the limiting factor.
		-- Distance = (boxWidth/2) / tan(horizontalHalfFov)
		return (boxWidth / 2) / math.tan(hFov / 2)
	else
		-- Box is tall (or square-ish) -> vertical dimension is the limiting factor.
		-- Distance = (boxHeight/2) / tan(verticalHalfFov)
		return (boxHeight / 2) / math.tan(vFov / 2)
	end
end

-- Checks if a position is on screen on a camera.
function Module.isOnScreen(camera: Camera, position: Vector3): boolean
	local _, onScreen = camera:WorldToScreenPoint(position)
	return onScreen
end

-- Takes <code>worldPos</code> and converts it to a screen position that is clamped along the screen's edges if <code>worldPos</code> is out of the camera's view.
-- <strong>padding</strong>: Optional padding for calculating the clamped screen position.
-- <strong>camera</strong>: Default camera is <code>workspace.CurrentCamera</code>
-- Returns the clamped screen position & a boolean indicating if the position was clamped.
function Module.toClampedScreenSpace(worldPos: Vector3, padding: Vector2?, camera: Camera?): (Vector2, boolean)
	local camera = camera or workspace.CurrentCamera
	local padding = padding or Vector2.zero
	
	local viewportSize = camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X/2, viewportSize.Y/2)
	local viewPos, onScreen = camera:WorldToViewportPoint(worldPos)
	
	local screenPos = Vector2.new(viewPos.X, viewPos.Y)
	local direction = (screenPos - screenCenter)
	
	local wasBehind = viewPos.Z < 0
	if wasBehind then
		direction = -direction
	end
	
	local maxX = viewportSize.X - padding.X
	local maxY = viewportSize.Y - padding.Y

	-- Proposed position, relative to center
	local proposed = screenCenter + direction

	-- Then clamp
	local clampedX = math.clamp(proposed.X, padding.X, maxX)
	local clampedY = math.clamp(proposed.Y, padding.Y, maxY)
	
	local wasXClamped = (clampedX ~= proposed.X)
	local wasYClamped = (clampedY ~= proposed.Y)
	local wasClamped = wasXClamped or wasYClamped or wasBehind
	
	if (wasBehind) and (not wasXClamped and not wasYClamped) and direction.Magnitude > 0 then
		-- Calculate how far we can go in X or Y before hitting the boundary
		local scaleX, scaleY

		if direction.X > 0 then
			scaleX = (maxX - screenCenter.X) / direction.X
		else
			scaleX = (padding.X - screenCenter.X) / direction.X
		end

		if direction.Y > 0 then
			scaleY = (maxY - screenCenter.Y) / direction.Y
		else
			scaleY = (padding.Y - screenCenter.Y) / direction.Y
		end

		-- Pick the smaller absolute scale so that we hit an edge on X or Y
		local scale = math.min(math.abs(scaleX), math.abs(scaleY))
		direction = direction * scale

		-- Recompute proposed and clamp again
		proposed = screenCenter + direction
		clampedX = math.clamp(proposed.X, padding.X, maxX)
		clampedY = math.clamp(proposed.Y, padding.Y, maxY)
	end
	
	return Vector2.new(clampedX, clampedY), wasClamped
end

-- Client-only!
-- Returns what the camera's default CFrame would be calculated by the Roblox camera scripts.
-- Also accounts for <code>CameraOffset</code> on <code>myHumanoid</code>.
-- <strong>zoomDist</strong>: Default is 12.5 or <code>LocalPlayer.CameraMinZoomDistance</code> if greater than 12.5
function Module.getDefaultCameraCFrame(myHumanoid: Humanoid, zoomDist: number?): CFrame
	assert(RunService:IsClient(), "getDefaultCameraCFrame() is client-only!")
	local myRoot = myHumanoid.RootPart :: BasePart
	local zoomDist = math.max(Players.LocalPlayer.CameraMinZoomDistance, 12.5)
	local lookAt = myRoot.CFrame.Position + Vector3.new(0, myRoot.Size.Y/2 + 0.5, 0) + myHumanoid.CameraOffset
	local at = (myRoot.CFrame * CFrame.new(0, zoomDist/2.6397830596715992, zoomDist/1.0352760971197642)).Position + myHumanoid.CameraOffset
	return CFrame.lookAt(at, lookAt)
end

function Module.getAspectRatio(camera: Camera?): number
	local camera = camera or workspace.CurrentCamera
	return camera.ViewportSize.X / camera.ViewportSize.Y
end

function Module.getViewportCenter(camera: Camera?): Vector2
	local camera = camera or workspace.CurrentCamera
	return Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end

-----------------------------
-- HANDLERS --
-----------------------------

-----------------------------
-- MAIN --
-----------------------------
return Module