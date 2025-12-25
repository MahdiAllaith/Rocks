--[[--local Frame1 = script.Parent.PlayerBar
--local Frame2 = script.Parent["KillFeed & buttons"]
--local GUI = script.Parent

--local ModuleUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
--local Screen3DService = ModuleUtils.Screen3D

--local GUI3D = Screen3DService.new(GUI,5)

--local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
--local Frame3D_2 = GUI3D:GetComponent3D(Frame2)

--Frame3D_1:Enable()
--Frame3D_2:Enable()

--Frame3D_1.offset = CFrame.new(0,0,-0.01) * CFrame.Angles(0, math.rad(10), 0)
--Frame3D_2.offset = CFrame.new(0,0,0.01) * CFrame.Angles(0, math.rad(-10), 0)

local Frame1 = script.Parent.PlayerBar
local Frame2 = script.Parent["KillFeed & buttons"]
local GUI = script.Parent
local ModuleUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local Screen3DService = ModuleUtils.Screen3D
local GUI3D = Screen3DService.new(GUI, 5)

-- Function to get all descendants in ZIndex order
local function getFramesInZIndexOrder(parentFrame)
	local frames = {}

	-- Get all GuiObject descendants
	for _, child in ipairs(parentFrame:GetDescendants()) do
		if child:IsA("GuiObject") then
			table.insert(frames, child)
		end
	end

	-- Sort by ZIndex (and by hierarchy depth as tiebreaker)
	table.sort(frames, function(a, b)
		if a.ZIndex ~= b.ZIndex then
			return a.ZIndex < b.ZIndex
		end
		-- If ZIndex is the same, sort by hierarchy depth (parents before children)
		local aDepth = 0
		local bDepth = 0
		local tempA, tempB = a.Parent, b.Parent

		while tempA and tempA ~= GUI do
			aDepth = aDepth + 1
			tempA = tempA.Parent
		end

		while tempB and tempB ~= GUI do
			bDepth = bDepth + 1
			tempB = tempB.Parent
		end

		return aDepth < bDepth
	end)

	return frames
end

-- Function to apply proper Z-layering to frames
local function applyZLayering(frames, baseZOffset)
	baseZOffset = baseZOffset or 0
	local layerSpacing = 0.0005  -- Smaller spacing for child elements

	for i, frame in ipairs(frames) do
		local component3D = GUI3D:GetComponent3D(frame)
		if component3D then
			component3D:Enable()

			-- Calculate Z offset based on position in sorted array
			local zOffset = baseZOffset + (i - 1) * layerSpacing
			component3D.offset = CFrame.new(0, 0, zOffset)
		end
	end
end

-- Get all frames in proper ZIndex order for PlayerBar
local playerBarFrames = getFramesInZIndexOrder(Frame1)
print("PlayerBar frames in ZIndex order:")
for i, frame in ipairs(playerBarFrames) do
	print(`{i}: {frame.Name} (ZIndex: {frame.ZIndex})`)
end

-- Get all frames for KillFeed & buttons
local killFeedFrames = getFramesInZIndexOrder(Frame2)

-- Enable the parent frames first
local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
local Frame3D_2 = GUI3D:GetComponent3D(Frame2)

Frame3D_1:Enable()
Frame3D_2:Enable()

-- Apply Z-layering to maintain hierarchy
-- PlayerBar children start at a base offset
applyZLayering(playerBarFrames, -0.01)

-- KillFeed & buttons children start at a different base offset
applyZLayering(killFeedFrames, 0.01)

-- Apply your custom rotations to the parent frames
Frame3D_1.offset = CFrame.new(0, 0, -0.01) * CFrame.Angles(0, math.rad(10), 0)
Frame3D_2.offset = CFrame.new(0, 0, 0.01) * CFrame.Angles(0, math.rad(-10), 0)

-- Alternative approach: If you want to preserve exact 2D appearance
-- You can also manually set specific Z-offsets for problematic frames:
--[[
local backgroundComponent = GUI3D:GetComponent3D(Frame1.BackGround)
local healthComponent = GUI3D:GetComponent3D(Frame1.Health)
local staminaComponent = GUI3D:GetComponent3D(Frame1.Stamina)

if backgroundComponent then backgroundComponent.offset = CFrame.new(0, 0, -0.015) end
if healthComponent then healthComponent.offset = CFrame.new(0, 0, -0.012) end  
if staminaComponent then staminaComponent.offset = CFrame.new(0, 0, -0.010) end

local Frame1 = script.Parent.PlayerBar
local Frame2 = script.Parent["KillFeed & buttons"]
local GUI = script.Parent

local ModuleUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local Screen3DService = ModuleUtils.Screen3D
local GUI3D = Screen3DService.new(GUI, 5)

-- Helper: Convert GUI size to 3D studs
local function preserveSize(component3D, guiObject)
	local guiSize = guiObject.AbsoluteSize
	local scale = 0.01 -- tweak if needed to match screen scaling
	component3D.Size = Vector3.new(guiSize.X * scale, guiSize.Y * scale, 0.001)
end

-- Recursive function to apply Z-layering while preserving hierarchy
-- Recursive function to apply Z-layering strictly by ZIndex
local function applyZLayeringStrict(guiObject, baseOffset)
	local children = {}

	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	-- Sort children by ZIndex ascending (lowest first)
	table.sort(children, function(a, b)
		return (a.ZIndex or 1) < (b.ZIndex or 1)
	end)

	-- Apply this object's offset
	local component3D = GUI3D:GetComponent3D(guiObject)
	if component3D then
		component3D:Enable()
		preserveSize(component3D, guiObject)
		component3D.offset = CFrame.new(0, 0, baseOffset)
	end

	-- Apply offsets recursively, higher ZIndex gets slightly higher offset
	local spacing = 0.001
	for i, child in ipairs(children) do
		local childOffset = baseOffset + i * spacing
		applyZLayeringStrict(child, childOffset)
	end
end


-- Enable parent frames
local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
local Frame3D_2 = GUI3D:GetComponent3D(Frame2)

Frame3D_1:Enable()
Frame3D_2:Enable()
preserveSize(Frame3D_1, Frame1)
preserveSize(Frame3D_2, Frame2)

-- Apply recursive Z-layering for children
applyZLayeringStrict(Frame1, -0.01)
applyZLayeringStrict(Frame2, 0.01)

-- Optional: Apply custom rotation to parent frames
Frame3D_1.offset = CFrame.new(0, 0, -0.01) * CFrame.Angles(0, math.rad(10), 0)
Frame3D_2.offset = CFrame.new(0, 0, 0.01) * CFrame.Angles(0, math.rad(-10), 0)

print("3D UI applied with correct Z-layering and size!")


local Frame1 = script.Parent.PlayerBar
local Frame2 = script.Parent["KillFeed & buttons"]
local GUI = script.Parent

local ModuleUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local Screen3DService = ModuleUtils.Screen3D
local GUI3D = Screen3DService.new(GUI, 5)

-- Helper: Convert GUI size to 3D studs
local function preserveSize(component3D, guiObject)
	local guiSize = guiObject.AbsoluteSize
	local scale = 0.01 -- tweak if needed to match screen scaling
	component3D.Size = Vector3.new(guiSize.X * scale, guiSize.Y * scale, 0.001)
end

-- Recursive function to apply Z-layering strictly by ZIndex
local function applyZLayeringStrict(guiObject, baseOffset)
	local children = {}

	-- Collect only GuiObject children
	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	-- Sort children by ZIndex ascending (lowest drawn first)
	table.sort(children, function(a, b)
		return (a.ZIndex or 1) < (b.ZIndex or 1)
	end)

	-- Apply offset ONLY if it's a renderable element (not containers)
	if guiObject:IsA("ImageLabel") or guiObject:IsA("TextLabel") or guiObject:IsA("ImageButton") then
		local component3D = GUI3D:GetComponent3D(guiObject)
		if component3D then
			component3D:Enable()
			preserveSize(component3D, guiObject)
			component3D.offset = CFrame.new(0, 0, baseOffset)
		end
	end

	-- Apply offsets recursively to children
	local spacing = 0.001
	for i, child in ipairs(children) do
		local childOffset = baseOffset + i * spacing
		applyZLayeringStrict(child, childOffset)
	end
end

-- Enable parent frames
local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
local Frame3D_2 = GUI3D:GetComponent3D(Frame2)

Frame3D_1:Enable()
Frame3D_2:Enable()
preserveSize(Frame3D_1, Frame1)
preserveSize(Frame3D_2, Frame2)

-- Apply recursive Z-layering for children
applyZLayeringStrict(Frame1, -0.01)
applyZLayeringStrict(Frame2, 0.01)

-- Optional: Apply custom rotation to parent frames
Frame3D_1.offset = CFrame.Angles(0, math.rad(10), 0)
Frame3D_2.offset =  CFrame.Angles(0, math.rad(-10), 0)

print("3D UI applied with correct Z-layering and size!")
local Frame1 = script.Parent.PlayerBar
local Frame2 = script.Parent["KillFeed & buttons"]
local GUI = script.Parent

local ModuleUtils = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local Screen3DService = ModuleUtils.Screen3D
local GUI3D = Screen3DService.new(GUI, 5)

-- Configuration
local BASE_DEPTH_SPACING = 0.01  -- Increased for better depth separation
local MAX_ZINDEX = 100  -- Adjust based on your highest ZIndex value

-- Helper: Convert GUI size to 3D studs
local function preserveSize(component3D, guiObject)
	local guiSize = guiObject.AbsoluteSize
	local scale = 0.01
	component3D.Size = Vector3.new(guiSize.X * scale, guiSize.Y * scale, 0.001)
end

-- Calculate depth offset based on ZIndex (higher ZIndex = closer to camera)
local function calculateDepthOffset(zIndex, maxZIndex)
	-- Normalize ZIndex to 0-1 range, then map to depth
	local normalized = (zIndex - 1) / (maxZIndex - 1)
	return -normalized * BASE_DEPTH_SPACING  -- Negative for proper depth ordering
end

-- Recursive function to apply Z-layering with proper depth calculation
local function applyStrictZLayering(guiObject, parentOffset, maxZIndex)
	local children = {}

	-- Collect all GUI children
	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	-- Sort children by ZIndex (lowest first)
	table.sort(children, function(a, b)
		return (a.ZIndex or 1) < (b.ZIndex or 1)
	end)

	-- Apply depth to current object
	local component3D = GUI3D:GetComponent3D(guiObject)
	if component3D then
		component3D:Enable()
		preserveSize(component3D, guiObject)

		-- Calculate this object's depth based on its ZIndex
		local depthOffset = calculateDepthOffset(guiObject.ZIndex or 1, maxZIndex)
		component3D.offset = parentOffset * CFrame.new(0, 0, depthOffset)
	end

	-- Apply to children with their own depth offsets
	for _, child in ipairs(children) do
		applyStrictZLayering(child, component3D and component3D.offset or parentOffset, maxZIndex)
	end
end

-- Find maximum ZIndex in the hierarchy for normalization
local function findMaxZIndex(guiObject)
	local maxZIndex = guiObject.ZIndex or 1

	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			maxZIndex = math.max(maxZIndex, findMaxZIndex(child))
		end
	end

	return maxZIndex
end

-- Enable parent frames
local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
local Frame3D_2 = GUI3D:GetComponent3D(Frame2)

Frame3D_1:Enable()
Frame3D_2:Enable()
preserveSize(Frame3D_1, Frame1)
preserveSize(Frame3D_2, Frame2)

-- Find maximum ZIndex values for normalization
local maxZIndex1 = findMaxZIndex(Frame1)
local maxZIndex2 = findMaxZIndex(Frame2)

-- Apply Z-layering with proper depth calculation
applyStrictZLayering(Frame1, CFrame.new(0, 0, -0.01) * CFrame.Angles(0, math.rad(10), 0), maxZIndex1)
applyStrictZLayering(Frame2, CFrame.new(0, 0, 0.01) * CFrame.Angles(0, math.rad(-10), 0), maxZIndex2)

-- Force specific elements to render in correct order (if needed)
local function forceHealthBarOrder()
	local healthBar = Frame1:FindFirstChild("HealthBar")
	local healthBackground = Frame1:FindFirstChild("HealthBackground")

	if healthBar and healthBackground then
		local healthBar3D = GUI3D:GetComponent3D(healthBar)
		local healthBg3D = GUI3D:GetComponent3D(healthBackground)

		if healthBar3D and healthBg3D then
			-- Ensure background is behind health bar
			local bgOffset = healthBg3D.offset
			local barOffset = healthBar3D.offset

			healthBg3D.offset = CFrame.new(bgOffset.X, bgOffset.Y, bgOffset.Z - 0.001)
			healthBar3D.offset = CFrame.new(barOffset.X, barOffset.Y, barOffset.Z + 0.001)
		end
	end
end

forceHealthBarOrder()

print("3D UI applied with corrected Z-layering!")]]







