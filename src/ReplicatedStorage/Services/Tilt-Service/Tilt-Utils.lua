local module = {}

local CollectionService = game:GetService("CollectionService")

-- checker if player ownership of motor6D
function module.IsOwnMotor6D(player, motor)
	if not player.Character then
		return false 
	end
	
	return motor:IsDescendantOf(player.Character)
end

--not used any more, but checker for if cfram is valid
function module.IsBadCFrame(cf)
	if typeof(cf) ~= "CFrame" then return true end
	for _, v in ipairs({cf:GetComponents()}) do
		if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
			return true
		end
	end
	return false
end


-- FIXED: Proper buffer compression functions
local MAX_ABS = 100 -- adjust as needed for vector range

function module.bufferVectorComp(vector:Vector3) : buffer
	local function quantize(f)
		f = math.clamp(f, -MAX_ABS, MAX_ABS)
		local norm = (f + MAX_ABS) / (2 * MAX_ABS)
		return math.floor(norm * 255 + 0.5)
	end

	local buf = buffer.create(3)
	buffer.writeu8(buf, 0, quantize(vector.X))
	buffer.writeu8(buf, 1, quantize(vector.Y))
	buffer.writeu8(buf, 2, quantize(vector.Z))
	return buf
end

function module.bufferVectorDecomp(buf: buffer) :Vector3
	local function dequantize(b)
		local norm = b / 255
		return norm * 2 * MAX_ABS - MAX_ABS
	end

	local x = buffer.readu8(buf, 0)
	local y = buffer.readu8(buf, 1)
	local z = buffer.readu8(buf, 2)
	
	local rotationVector = Vector3.new(dequantize(x), dequantize(y), dequantize(z)) 
	
	-- Clamp rotation values to prevent extreme rotations
	local clampedRotation = Vector3.new(
		math.clamp(rotationVector.X, -math.pi/2, math.pi/2), -- Pitch
		math.clamp(rotationVector.Y, -math.pi/2, math.pi/2), -- Yaw  
		math.clamp(rotationVector.Z, -math.pi/4, math.pi/4)  -- Roll
	)

	return clampedRotation
end


-- same approach but defrent syntax

---- ALTERNATIVE: Even more compressed version (3 bytes total, but with precision loss)
--local function bufferVectorCompQuantized(vector: Vector3)
--	local buf = buffer.create(3) -- 3 bytes total
--	-- Convert from radians (-π/2 to π/2) to 0-255 range
--	local x = math.floor((vector.X + math.pi/2) / math.pi * 255)
--	local y = math.floor((vector.Y + math.pi/2) / math.pi * 255) 
--	local z = math.floor((vector.Z + math.pi/4) / (math.pi/2) * 255)

--	buffer.writeu8(buf, 0, math.clamp(x, 0, 255))
--	buffer.writeu8(buf, 1, math.clamp(y, 0, 255))
--	buffer.writeu8(buf, 2, math.clamp(z, 0, 255))
--	return buf
--end

--local function bufferVectorDecompQuantized(buf: buffer)
--	local x = buffer.readu8(buf, 0) / 255 * math.pi - math.pi/2
--	local y = buffer.readu8(buf, 1) / 255 * math.pi - math.pi/2
--	local z = buffer.readu8(buf, 2) / 255 * (math.pi/2) - math.pi/4
--	return Vector3.new(x, y, z)
--end


return module
