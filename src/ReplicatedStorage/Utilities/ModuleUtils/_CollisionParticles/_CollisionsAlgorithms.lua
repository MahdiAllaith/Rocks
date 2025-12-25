
--Collision Detection between Ball and Particle.
local function BallSphereIntersection(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local size : number = math.min(size.X, size.Y, size.Z) * 0.5
	local pos : vector = cframe.Position
	local rel : vector = point - pos
	local dist : number= vector.magnitude(rel)
	local normal : vector = vector.normalize(rel)
	local closestPoint : vector = normal * (size + radius) + pos
	if dist < size + radius then
		return true, closestPoint, normal
	else
		return false, closestPoint, normal
	end
end

--Collision Detection between Cylinder and Particle.
local function CylinderSphereIntersection(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local rel : vector = cframe:PointToObjectSpace(point)
	local sx : number, sy : number, sz : number = size.X + radius, size.Y + radius, size.Z + radius
	local rx : number, ry : number, rz : number = rel.X, rel.Y, rel.Z

	local cx : number = math.clamp(rx, -sx*0.5, sx*0.5)
	local distSquared : number = (ry*ry + rz*rz)
	local SizeYZmin : number = math.min(sy, sz)*0.5

	if not (cx == rx and (distSquared <= SizeYZmin * SizeYZmin)) then
		local cy : number = sy * ry / SizeYZmin
		local cz : number = sz * rz / SizeYZmin
		local closestPoint : vector = cframe*vector.create(cx, cy, cz)
		local normal : vector = vector.normalize(point - closestPoint)
		return false, closestPoint, normal
	else
		local dist : number = math.sqrt(distSquared)
		local closestPoint: vector = vector.create(rx, ry / dist * SizeYZmin, rz / dist * SizeYZmin)
		local relToClosestPoint : vector = closestPoint - vector.create(rx, ry, rz)

		local posX : number = rx - sx*0.5
		local negX : number = -rx - sx*0.5 

		local max = math.max(posX, negX)
		if -max > vector.magnitude(relToClosestPoint) then
			local normal : vector = vector.normalize(relToClosestPoint)
			return true, cframe*closestPoint, normal
		elseif max == posX then
			local closestPoint : vector = cframe*vector.create(sx*0.5, ry, rz)
			return true, closestPoint, cframe.XVector
		elseif max == negX then
			local closestPoint : vector = cframe*vector.create(-sx*0.5, ry, rz)
			return true, closestPoint, -cframe.XVector
		end
	end
end

--Collision Detection between Box and Particle.
local function BoxSphereIntersection(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local rel : vector = cframe:PointToObjectSpace(point)
	local sx : number, sy : number, sz : number = size.X + radius, size.Y + radius, size.Z + radius
	local rx : number, ry : number, rz : number = rel.X, rel.Y, rel.Z

	local cx : number = math.clamp(rx, -sx*0.5, sx*0.5)
	local cy : number = math.clamp(ry, -sy*0.5, sy*0.5)
	local cz : number = math.clamp(rz, -sz*0.5, sz*0.5)

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint : vector = cframe*vector.create(cx, cy, cz)
		local normal : vector = vector.normalize(point - closestPoint)
		return false, closestPoint, normal
	end

	local posX : number = rx - sx*0.5 
	local posY : number = ry - sy*0.5 
	local posZ : number = rz - sz*0.5
	local negX : number = -rx - sx*0.5
	local negY : number = -ry - sy*0.5 
	local negZ : number = -rz - sz*0.5

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint : vector = cframe*vector.create(sx*0.5, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint : vector = cframe*vector.create(rx, sy*0.5, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint : vector = cframe*vector.create(rx, ry, sz*0.5)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint : vector = cframe*vector.create(-sx*0.5, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint : vector = cframe*vector.create(rx, -sy*0.5, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint : vector = cframe*vector.create(rx, ry, -sz*0.5)
		return true, closestPoint, -cframe.ZVector
	end
end

--Old code for Collision between Box and Particle.
local function BoxPointIntersection(cframe, size, point) : (boolean, vector, vector)
	local rel = cframe:pointToObjectSpace(point)
	local sx :number, sy :number, sz :number = size.x, size.y, size.z
	local rx :number, ry :number, rz :number = rel.x, rel.y, rel.z

	-- constrain to within the box
	local cx = math.clamp(rx, -sx/2, sx/2)
	local cy = math.clamp(ry, -sy/2, sy/2)
	local cz = math.clamp(rz, -sz/2, sz/2)

	if not (cx == rx and cy == ry and cz == rz) then
		local closestPoint = cframe*vector.create(cx, cy, cz)
		local normal = vector.normalize(point - closestPoint)
		return false, closestPoint, normal
	end

	-- else, they are intersecting, find the surface the point is closest to

	local posX : number = rx - sx/2 
	local posY : number = ry - sy/2 
	local posZ : number = rz - sz/2 
	local negX : number = -rx - sx/2 
	local negY : number = -ry - sy/2 
	local negZ : number = -rz - sz/2

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint = cframe*vector.create(sx/2, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint = cframe*vector.create(rx, sy/2, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint = cframe*vector.create(rx, ry, sz/2)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint = cframe*vector.create(-sx/2, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint = cframe*vector.create(rx, -sy/2, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint = cframe*vector.create(rx, ry, -sz/2)
		return true, closestPoint, -cframe.ZVector
	end
end


--[[
OLDER VERSIONS UP   ^^^
OPTIMIZED VERSIONS BELOW   vvv
]]

--Optimized version Collision Detection between Ball and Particle.
local function BallSphereIntersectionOptimized(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local size : number = math.min(size.X, size.Y, size.Z) * 0.5
	local pos : vector = cframe.Position
	local rel : vector = point - pos
	local dist : number= vector.magnitude(rel)

	if dist < size + radius then
		local normal : vector = vector.normalize(rel)
		local closestPoint : vector = normal * (size + radius) + pos
		return true, closestPoint, normal
	else
		return nil
	end
end

--Optimized version Collision Detection between Cylinder and Particle.
local function CylinderSphereIntersectionOptimized(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local rel : vector = cframe:PointToObjectSpace(point)
	local sx : number, sy : number, sz : number = size.X + radius, size.Y + radius, size.Z + radius
	local rx : number, ry : number, rz : number = rel.X, rel.Y, rel.Z

	local cx : number = math.clamp(rx, -sx*0.5, sx*0.5)
	local distSquared : number = (ry*ry + rz*rz)
	local SizeYZmin : number = math.min(sy, sz)*0.5

	if not (cx == rx and (distSquared <= SizeYZmin * SizeYZmin)) then
		return nil
	else
		local dist : number = math.sqrt(distSquared)
		local closestPoint: vector = vector.create(rx, ry / dist * SizeYZmin, rz / dist * SizeYZmin)
		local relToClosestPoint : vector = closestPoint - vector.create(rx, ry, rz)

		local posX : number = rx - sx*0.5
		local negX : number = -rx - sx*0.5 

		local max = math.max(posX, negX)
		if -max > vector.magnitude(relToClosestPoint) then
			local normal : vector = vector.normalize(relToClosestPoint)
			return true, cframe*closestPoint, normal
		elseif max == posX then
			local closestPoint : vector = cframe*vector.create(sx*0.5, ry, rz)
			return true, closestPoint, cframe.XVector
		elseif max == negX then
			local closestPoint : vector = cframe*vector.create(-sx*0.5, ry, rz)
			return true, closestPoint, -cframe.XVector
		end
	end
end

--Optimized version Collision Detection between Box and Particle.
local function BoxSphereIntersectionOptimized(cframe : CFrame, size : vector, point : vector, radius : number) : (boolean, vector, vector)
	local rel : vector = cframe:PointToObjectSpace(point)
	local sx : number, sy : number, sz : number = size.X + radius, size.Y + radius, size.Z + radius
	local rx : number, ry : number, rz : number = rel.X, rel.Y, rel.Z

	local cx : number = math.clamp(rx, -sx*0.5, sx*0.5)
	local cy : number = math.clamp(ry, -sy*0.5, sy*0.5)
	local cz : number = math.clamp(rz, -sz*0.5, sz*0.5)

	if not (cx == rx and cy == ry and cz == rz) then
		return nil
	end

	local posX : number = rx - sx*0.5 
	local posY : number = ry - sy*0.5 
	local posZ : number = rz - sz*0.5
	local negX : number = -rx - sx*0.5
	local negY : number = -ry - sy*0.5 
	local negZ : number = -rz - sz*0.5

	local max = math.max(posX, posY, posZ, negX, negY, negZ)
	if max == posX then
		local closestPoint : vector = cframe*vector.create(sx*0.5, ry, rz)
		return true, closestPoint, cframe.XVector
	elseif max == posY then
		local closestPoint : vector = cframe*vector.create(rx, sy*0.5, rz)
		return true, closestPoint, cframe.YVector
	elseif max == posZ then
		local closestPoint : vector = cframe*vector.create(rx, ry, sz*0.5)
		return true, closestPoint, cframe.ZVector
	elseif max == negX then
		local closestPoint : vector = cframe*vector.create(-sx*0.5, ry, rz)
		return true, closestPoint, -cframe.XVector
	elseif max == negY then
		local closestPoint : vector = cframe*vector.create(rx, -sy*0.5, rz)
		return true, closestPoint, -cframe.YVector
	elseif max == negZ then
		local closestPoint : vector = cframe*vector.create(rx, ry, -sz*0.5)
		return true, closestPoint, -cframe.ZVector
	end
end

local module = {
	["BallSphereIntersection"] = BallSphereIntersection,
	["CylinderSphereIntersection"] = CylinderSphereIntersection,
	["BoxSphereIntersection"] = BoxSphereIntersection,

	["BallSphereIntersectionOptimized"] = BallSphereIntersectionOptimized,
	["CylinderSphereIntersectionOptimized"] = CylinderSphereIntersectionOptimized,
	["BoxSphereIntersectionOptimized"] = BoxSphereIntersectionOptimized
}

return module
