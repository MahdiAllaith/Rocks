--!native
type Plane = {P:Vector3, M:number}
local module = {}

local function distancePlaneFromOrigin(position, normal)
	return -position:Dot(normal)
end

function module.getFrustum(camera : Camera, renderDistance)
	local cameraCF = camera.CFrame

	local cameraHorizontalLimit = math.rad(camera.MaxAxisFieldOfView) / 2
	local cameraverticalLimit = math.rad(camera.FieldOfView) / 2

	-- Near Plane
	local nearPlaneCF = cameraCF * CFrame.new(0, 0, camera.NearPlaneZ)
	local nearNormal = -nearPlaneCF.LookVector
	local p1 = {P = nearNormal, M = (-nearNormal):Dot(nearPlaneCF.Position)}

	-- Far Plane
	local farPlaneCF = cameraCF * CFrame.new(0, 0, -renderDistance)
	local farNormal = farPlaneCF.LookVector
	local p2 = {P = farNormal, M = (-farNormal):Dot(farPlaneCF.Position)}

	-- Right Plane
	local rightPlaneCF = cameraCF * CFrame.Angles(0, cameraHorizontalLimit, 0)
	local rightNormal = -rightPlaneCF.RightVector
	local p3 = {P = rightNormal, M = (-rightNormal):Dot(cameraCF.Position)}

	-- Left Plane
	local leftPlaneCF = cameraCF * CFrame.Angles(0, -cameraHorizontalLimit, 0)
	local leftNormal = leftPlaneCF.RightVector
	local p4 = {P = leftNormal, M = (-leftNormal):Dot(cameraCF.Position)}

	-- Low Plane
	local lowPlaneCF = cameraCF * CFrame.Angles(-cameraverticalLimit, 0, 0)
	local lowNormal = -lowPlaneCF.UpVector
	local p5 = {P = lowNormal, M = (-lowNormal):Dot(cameraCF.Position)}

	-- Up Plane
	local upPlaneCF = cameraCF * CFrame.Angles(cameraverticalLimit, 0, 0)
	local upNormal = upPlaneCF.UpVector
	local p6 = {P = upNormal, M = (-upNormal):Dot(cameraCF.Position)}

	return {p1, p2, p3, p4, p5, p6} :: {Plane}
end


function module.findInFrustumPoint(planes : {Plane}, objectPos)
	for i, plane in planes do
		if (objectPos:Dot(plane["P"]) + plane["M"]) >= 0 then
			return false
		end
	end

	return true
end
type plane = {}
function module.findInFrustumSphere(planes : {Plane}, objectPos : Vector3, size : number)
	for i, plane in planes do
		if (objectPos:Dot(plane["P"]) + plane["M"]) >= size then
			return false
		end
	end

	return true
end

function module.findInFrustumAABB(planes : {Plane}, mins, maxs)
	local ret = "INSIDE"  -- Start assuming the box is inside unless proven otherwise.

	for i, plane in ipairs(planes) do
		local normal = plane["P"]
		local dist = plane["M"]

		local vmin = Vector3.new(
			(normal.X > 0) and mins.X or maxs.X,
			(normal.Y > 0) and mins.Y or maxs.Y,
			(normal.Z > 0) and mins.Z or maxs.Z
		)

		-- Determine the "most positive" vertex in relation to the plane normal
		local vmax = Vector3.new(
			(normal.X > 0) and maxs.X or mins.X,
			(normal.Y > 0) and maxs.Y or mins.Y,
			(normal.Z > 0) and maxs.Z or mins.Z
		)

		-- If the "most negative" vertex is outside the frustum, the entire box is outside
		if normal:Dot(Vector3.new(vmin.X, vmin.Y, vmin.Z)) + dist > 0 then
			return false
		end

		-- If the "most positive" vertex is inside, the box might intersect
		if normal:Dot(Vector3.new(vmax.X, vmax.Y, vmax.Z)) + dist >= 0 then
			ret = "Intersect"
		end
	end

	return ret  -- Could still be "INSIDE" if never updated to "Intersect"
end

function module.CalculateOBBVertices(cf : CFrame, size : Vector3)
	local vertices = {}
	for i = -1, 1, 2 do
		for j = -1, 1, 2 do
			for k = -1, 1, 2 do
				local corner = Vector3.new(i * size.X / 2, j * size.Y / 2, k * size.Z / 2)
				local vertex = cf:PointToWorldSpace(corner)
				table.insert(vertices, vertex)
			end
		end
	end
	return vertices
end

function module.findInFrustumBox(planes : {Plane}, Cf : CFrame, size : Vector3)
	local vertices = module.CalculateOBBVertices(Cf, size)
	for _, plane in ipairs(planes) do
		local allOut = true
		for _, vertex in ipairs(vertices) do
			if vertex:Dot(plane["P"]) + plane["M"] <= 0 then
				allOut = false
				break
			end
		end
		if allOut then
			return false -- All vertices are outside this plane
		end
	end
	return true -- No plane could exclude all vertices
end

return module
