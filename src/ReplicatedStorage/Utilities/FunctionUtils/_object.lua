--!strict
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Future = require("../ModuleUtils/_Future")
local _game = require("./_game")
local _table = require("./_table")

local Table = require("./_table")

local Logger = require("../ModuleUtils/_Logger")

local Module = {}

--[[
	Grabs all instances with <code>tag</code>.
	<strong>validAncestors</strong>: Optionally filter for instances within the ancestor list.
]]
function Module.getTagged(tag: string, validAncestors: { any }?): { any }
	debug.profilebegin("FunctionUtils::getTagged")
	local tagged: { Instance } = CollectionService:GetTagged(tag)
	if validAncestors then
		tagged = _table.filter(tagged, function(instance)
			local found = false
			for _, ancestor in validAncestors do
				if instance:IsDescendantOf(ancestor) then
					found = true
					break
				end
			end
			return found
		end)
	end
	debug.profileend()
	return tagged
end

-- Returns a future that resolves once the animation track is loaded (Length becomes greater than 0)
function Module.getAnimationTrackLoadedFuture(track: AnimationTrack)
	return Future.new(function(track: AnimationTrack)
		if track.Length == 0 then
			-- GetPropertyChangedSignal does NOT work with the Length property!
			repeat
				task.wait()
			until track.Length > 0
		end
	end, track)
end

-- Creates a new OverlapParams
function Module.overlapParams(
	properties: {
		FilterDescendantsInstances: { any }?,
		FilterType: Enum.RaycastFilterType?,
		CollisionGroup: string?,
		RespectCanCollide: boolean?,
		BruteForceAllSlow: boolean?,
		Tolerance: number?,
		MaxParts: number?
	}?
): OverlapParams
	local params: any = OverlapParams.new()
	if properties then
		for name, value in pairs(properties) do
			params[name] = value
		end
	end
	return params
end

-- Creates a new RaycastParams
function Module.raycastParams(
	properties: {
		FilterDescendantsInstances: { any }?,
		FilterType: Enum.RaycastFilterType?,
		CollisionGroup: string?,
		RespectCanCollide: boolean?,
		BruteForceAllSlow: boolean?,
		IgnoreWater: boolean?,
	}?
): RaycastParams
	local params: any = RaycastParams.new()
	if properties then
		for name, value in pairs(properties) do
			params[name] = value
		end
	end
	return params
end

-- Determines if the two parts can collide with each other based on their CanCollide and CollisionGroup properties.
function Module.areCollideable(part1: BasePart, part2: BasePart): boolean
	local part1Group = part1.CollisionGroup
	local part2Group = part2.CollisionGroup
	return part2.CanCollide and part1.CanCollide and PhysicsService:CollisionGroupsAreCollidable(part1Group, part2Group)
end

@deprecated
-- DEPRECATED (use math library)
-- Given a ground position and model, this returns what the model should be :PivotTo() for a flush ground position.
function Module.getPivotFlushWithGround(groundPoint: CFrame, model: Model): CFrame
	local pivot = model:GetPivot()
	local center, size = model:GetBoundingBox()

	local bottomWorld = Vector3.new(
		center.X,
		center.Y - size.Y / 2,
		center.Z
	)

	local offset = pivot:PointToObjectSpace(bottomWorld)

	return groundPoint * CFrame.new(-offset)
end

@deprecated
-- DEPRECATED (use math library)
-- Resizes the model via <code>:ScaleTo()</code> to ensure it fits within a spherical volume.
function Module.resizeModelToFitRadius(model: Model, radius: number)
	local pivotCFrame, size = model:GetBoundingBox()
	local currentRadius = size.Magnitude * 0.5
	assert(currentRadius > 0, "Model has zero size")

	model:PivotTo(pivotCFrame)

	local scaleFactor = radius / currentRadius
	model:ScaleTo(scaleFactor)
end

@deprecated
-- DEPRECATED (use math library)
-- Returns the central bottom point of the model's bounding box (includes orientation)
function Module.getBottomPositionOfModel(model: Model): Vector3
	local boundingBox, size = model:GetBoundingBox()
	return (boundingBox * CFrame.new(0, -size.Y / 2, 0)).Position
end

-- Returns the 'depth' of <code>descendant</code> in the child hierarchy of <code>root</code>.
-- If the descendant is not found in <code>root</code>, then this function will return 0.
function Module.getDepthInHierarchy(descendant: Instance, root: Instance): number
	local depth = 0
	local current: Instance? = descendant
	while current and current ~= root do
		current = current.Parent
		depth += 1
	end
	if not current then
		depth = 0
	end
	return depth
end

-- Default searchDepth is removal of tags for all descendents, 1 is for just the passed object.
function Module.removeAllTags(obj: Instance, searchDepth: number?)
	if searchDepth ~= nil then
		assert(typeof(searchDepth) == "number" and searchDepth >= 1, "findWithPredicate: searchDepth must be positive number")
	end

	local function removeTags(instance: any, tags: {string})
		for _, tag in ipairs(tags) do
			instance:RemoveTag(tag)
		end
	end

	local tags = obj:GetTags()
	removeTags(obj, tags)

	if not searchDepth then
		for _, desc in ipairs(obj:GetDescendants()) do
			local tags = desc:GetTags()
			removeTags(desc, tags)
		end
	elseif searchDepth == 1 then
		return
	else
		local function recurse(node: Instance, depth: number)
			for _, child in ipairs(node:GetChildren()) do
				local tags = child:GetTags()
				removeTags(child, tags)
				if depth < searchDepth then
					recurse(child, depth + 1)
				end
			end
		end
		recurse(obj, 1)
	end
end

-- Given an unknown number of arrays containing instances, returns all descendants of all instances in the arrays.
function Module.getDescendants(...: { any }): { any }
	local arrays = {...}
	local result = {}

	local function collect(instance: Instance)
		local descendants = instance:GetDescendants()
		result = Table.mergeArrays(result, descendants)
	end

	-- Iterate over every array in the arguments
	for _, array in ipairs(arrays) do
		for _, instance in ipairs(array) do
			table.insert(result, instance)
			collect(instance)
		end
	end

	return result
end

-- DESCENDANT FIND FUNCTIONS --
do
	--<strong>isValid</strong>: Validates instances to be returned in the result of the function.
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>class</code>.
	function Module.findAllWithPredicate(
		searchIn: any,
		isValid: (instance: any) -> boolean,
		searchDepth: number?
	): { any }
		assert(typeof(searchIn)  == "Instance", "findAllWithPredicate: searchIn must be an Instance")
		assert(typeof(isValid)   == "function", "findAllWithPredicate: isValid must be a function")
		if searchDepth ~= nil then
			assert(
				typeof(searchDepth) == "number" and searchDepth >= 1,
				"findAllWithPredicate: searchDepth must be a positive number"
			)
		end
		debug.profilebegin("FunctionUtils::findAllWithPredicate")
		local results = {}

		if not searchDepth then
			-- no limit -> use the built-in, highly‑optimized path
			for _, obj in ipairs(searchIn:GetDescendants()) do
				if isValid(obj) then
					table.insert(results, obj)
				end
			end
		elseif searchDepth == 1 then
			-- only direct children
			for _, child in ipairs(searchIn:GetChildren()) do
				if isValid(child) then
					table.insert(results, child)
				end
			end
		else
			-- recursive depth-first, tracking current depth
			local function recurse(node: Instance, depth: number)
				for _, child in ipairs(node:GetChildren()) do
					if isValid(child) then
						table.insert(results, child)
					end
					if depth < searchDepth then
						recurse(child, depth + 1)
					end
				end
			end
			recurse(searchIn, 1)
		end

		debug.profileend()
		return results
	end

	-- Finds all instances that have the given name.
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>className</code>.
	-- Default is no limit.
	function Module.findAll(name: string, searchIn: any, searchDepth: number?)
		assert(typeof(name) == "string", "name is invalid or nil")
		assert(typeof(searchIn) == "Instance", "searchIn is invalid or nil")

		return Module.findAllWithPredicate(
			searchIn,
			function(obj)
				return obj.Name == name
			end,
			searchDepth
		)
	end

	-- DEPRECATED. Use findAllWhichAreA or findAllOfClass
	-- NOTE: This function uses :IsA() which is incorrect behavior based on its name.
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>className</code>.
	-- Default is no limit.
	@deprecated
	function Module.findAllFromClass(
		className: string,
		searchIn: any,
		searchDepth: number?
	): { any }
		assert(typeof(className) == "string", "findAllFromClass: className must be a string")
		return Module.findAllWithPredicate(
			searchIn,
			function(obj: Instance)
				return obj:IsA(className)
			end,
			searchDepth
		)
	end

	--[[
		Searches for objects via <strong>:IsA()</strong>.
		<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>className</code>.
		Default is no limit.
	]]
	function Module.findAllWhichAreA(
		className: string,
		searchIn: any,
		searchDepth: number?
	): { any }
		assert(typeof(className) == "string", "findAllWhichAreA: className must be a string")
		return Module.findAllWithPredicate(
			searchIn,
			function(obj: Instance)
				return obj:IsA(className)
			end,
			searchDepth
		)
	end

	--[[
		Searches for objects via the <strong>ClassName</strong> property of the object.
		<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>className</code>.
		Default is no limit.
	]]
	function Module.findAllOfClass(
		className: string,
		searchIn: any,
		searchDepth: number?
	): { any }
		assert(typeof(className) == "string", "findAllOfClass: className must be a string")
		return Module.findAllWithPredicate(
			searchIn,
			function(obj: Instance)
				return obj.ClassName == className
			end,
			searchDepth
		)
	end

	--[[
		This function is more optimal as it grabs all with <code>tagName</code> via CollectionService,
		rather than looking through all descendants of <code>searchIn</code> (if you don't use <code>searchDepth</code>).
		<strong>searchDepth</strong>: Optional argument that defines how far to include elements of <code>className</code>.
		Default is no limit.
	]]
	function Module.findAllWithTag(
		tagName: string,
		searchIn: any,
		searchDepth: number?
	): { any }
		assert(typeof(tagName) == "string", "findAllWithTag: tagName must be a string")
		assert(typeof(searchIn) == "Instance", "findAllWithTag: searchIn must be an Instance")
		debug.profilebegin("FunctionUtils::findAllWithTag")

		if searchDepth then
			-- Recursive search
			local result = Module.findAllWithPredicate(
				searchIn,
				function(obj)
					return obj:HasTag(tagName)
				end,
				searchDepth
			)
			debug.profileend()
			return result
		end

		local tagged = CollectionService:GetTagged(tagName)
		local results = {}

		for _, instance in ipairs(tagged) do
			if instance:IsDescendantOf(searchIn) then
				table.insert(results, instance)
			end
		end

		debug.profileend()
		return results
	end

	--<strong>attributeValue</strong>: Optionally find only those with the matching attribute value.
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>attribute</code>.
	-- Default is no limit.
	function Module.findAllWithAttribute(
		attribute: string,
		searchIn: any,
		attributeValue: any?,
		searchDepth: number?
	): { any }
		assert(typeof(attribute) == "string", "findAllWithAttribute: attribute must be a string")
		return Module.findAllWithPredicate(
			searchIn,
			function(obj)
				local attr = obj:GetAttribute(attribute)
				if attributeValue ~= nil then
					return attr == attributeValue
				else
					return attr ~= nil
				end
			end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>isValid</code>.
	-- Default is no limit.
	function Module.findWithPredicate(
		searchIn: any,
		isValid: (any) -> boolean,
		searchDepth: number?
	): any
		assert(typeof(searchIn) == "Instance", "findWithPredicate: searchIn must be Instance")
		assert(typeof(isValid) == "function", "findWithPredicate: isValid must be function")
		if searchDepth ~= nil then
			assert(typeof(searchDepth) == "number" and searchDepth >= 1, "findWithPredicate: searchDepth must be positive number")
		end
		debug.profilebegin("FunctionUtils::findWithPredicate")
		if not searchDepth then
			for _, obj in ipairs(searchIn:GetDescendants()) do
				if isValid(obj) then
					return obj
				end
			end
			return nil
		end

		if searchDepth == 1 then
			for _, child in ipairs(searchIn:GetChildren()) do
				if isValid(child) then
					return child
				end
			end
			return nil
		end

		-- recursive up to searchDepth
		local function recurse(node: Instance, depth: number): Instance?
			for _, child in ipairs(node:GetChildren()) do
				if isValid(child) then
					return child
				end
				if depth < searchDepth then
					local found = recurse(child, depth + 1)
					if found then
						return found
					end
				end
			end
			return nil
		end

		local result = recurse(searchIn, 1)

		debug.profileend()
		return result
	end

	--[[
		Alias for <code>findWithPredicate()</code>.
	]]
	function Module.findFirstWithPredicate(
		searchIn: any,
		isValid: (any) -> boolean,
		searchDepth: number?
	): any
		return Module.findWithPredicate(searchIn, isValid, searchDepth)
	end

	-- Shorthand for :FindFirstChild
	function Module.find(name: string, searchIn: any, recursive: boolean): any
		assert(typeof(name) == "string", "find: name must be string")
		assert(typeof(searchIn) == "Instance", "find: searchIn must be Instance")
		return searchIn:FindFirstChild(name, recursive)
	end

	--[[
		Alias for <code>find()</code>.
	]]
	function Module.findFirst(name: string, searchIn: any, recursive: boolean): any
		return Module.find(name, searchIn, recursive)
	end

	-- Find first descendant of given a given class via :IsA()
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>className</code>.
	-- Default is no limit.
	function Module.findFromClass(
		className: string,
		searchIn: any,
		searchDepth: number?
	): any
		assert(typeof(className) == "string", "findFromClass: className must be string")
		assert(typeof(searchIn) == "Instance", "findFromClass: searchIn must be Instance")
		return Module.findWithPredicate(
			searchIn,
			function(obj)
				return obj:IsA(className)
			end,
			searchDepth
		)
	end

	--[[
		Alias for <code>findFromClass()</code>.
	]]
	function Module.findFirstFromClass(
		className: string,
		searchIn: any,
		searchDepth: number?
	): any
		return Module.findFromClass(className, searchIn, searchDepth)
	end

	--[[
		If <code>searchDepth</code> is shallow (1) or unlimited, then the search is optimized by using <code>CollectionService:GetTagged()</code>.
		<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>tagName</code>.
		Default is no limit.
	]]
	function Module.findWithTag(
		tagName: string,
		searchIn: any,
		searchDepth: number?
	): any
		assert(typeof(tagName) == "string", "findWithTag: tagName must be string")
		assert(typeof(searchIn) == "Instance", "findWithTag: searchIn must be Instance")

		local isUnlimited = searchDepth == nil or searchDepth < 0
		local isShallow = searchDepth == 1

		if
			not isUnlimited
			and not isShallow
		then
			return Module.findWithPredicate(
				searchIn,
				function(obj)
					return CollectionService:HasTag(obj, tagName)
				end,
				searchDepth
			)
		end

		debug.profilebegin("FunctionUtils::findWithTag")
		for _, instance in CollectionService:GetTagged(tagName) do
			if not instance:IsDescendantOf(searchIn) then
				continue
			end
			if isShallow and instance.Parent ~= searchIn then
				continue
			end
			debug.profileend()
			return instance
		end
		debug.profileend()
		return nil
	end

	--[[
		Alias for <code>findWithTag()</code>.
	]]
	function Module.findFirstWithTag(
		tagName: string,
		searchIn: any,
		searchDepth: number?
	): any
		return Module.findWithTag(tagName, searchIn, searchDepth)
	end

	--<strong>attributeValue</strong>: Optional match for the attribute value.
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>attribute</code>.
	-- Default is no limit.
	function Module.findWithAttribute(
		attribute: string,
		searchIn: any,
		attributeValue: any?,
		searchDepth: number?
	): any
		assert(typeof(attribute) == "string", "findWithAttribute: attribute must be string")
		assert(typeof(searchIn) == "Instance", "findWithAttribute: searchIn must be Instance")

		return Module.findWithPredicate(
			searchIn,
			function(obj)
				local val = obj:GetAttribute(attribute)
				if attributeValue ~= nil then
					return val == attributeValue
				else
					return val ~= nil
				end
			end,
			searchDepth
		)
	end

	--[[
		Alias for <code>findWithAttribute()</code>.
	]]
	function Module.findFirstWithAttribute(
		attribute: string,
		searchIn: any,
		attributeValue: any?,
		searchDepth: number?
	): any
		return Module.findWithAttribute(attribute, searchIn, attributeValue, searchDepth)
	end
end

-- WAIT FUNCTIONS --
do
	@deprecated
	-- DEPRECATED
	function Module.waitForChild(parent: Instance, childMatchesCriteria: (child: Instance) -> (boolean), timeOut: number?): Instance?
		for _, child in parent:GetChildren() do
			if childMatchesCriteria(child) then
				return child
			end
		end

		local thread = coroutine.running()
		local connection = nil :: RBXScriptConnection?

		connection = parent.ChildAdded:Connect(function(child)
			if not connection then
				return
			end

			if childMatchesCriteria(child) then
				connection:Disconnect()
				connection = nil

				task.spawn(thread, child)
			end
		end)

		if timeOut then
			task.delay(timeOut, function()
				if not connection then
					return
				end

				connection:Disconnect()
				connection = nil

				task.spawn(thread, nil)
			end)
		end

		return coroutine.yield()
	end

	-- Yields until a valid child is found.
	function Module.waitForChildWithPredicate(
		parent: Instance,
		isValid: (any) -> boolean,
		timeout: number?
	): any
		for _, child in parent:GetChildren() do
			if isValid(child) then
				return child
			end
		end

		local thread = coroutine.running()
		local connection: RBXScriptConnection?

		connection = parent.ChildAdded:Connect(function(child)
			if not connection then
				return
			end
			if not isValid(child) then
				return
			end

			connection:Disconnect()
			connection = nil
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, child)
			end
		end)

		if timeout then
			task.delay(timeout, function()
				if not connection then
					return
				end

				connection:Disconnect()
				connection = nil

				if coroutine.status(thread) == "suspended" then
					task.spawn(thread)
				end
			end)
		end

		return coroutine.yield()
	end

	function Module.waitForChildWhichIsA(
		parent: Instance,
		className: string,
		timeout: number?
	): any
		assert(typeof(className) == "string", "waitForChildWhichIsA: className must be a string")

		return Module.waitForChildWithPredicate(parent, function(child)
			return child:IsA(className)
		end, timeout)
	end

	function Module.waitForChildWithTag(
		parent: Instance,
		tagName: string,
		timeout: number?
	): any
		assert(typeof(tagName) == "string", "waitForChildWithTag: tagName must be a string")

		return Module.waitForChildWithPredicate(parent, function(child)
			return child:HasTag(tagName)
		end, timeout)
	end

	function Module.waitForChildWithAttribute(
		parent: Instance,
		attributeName: string,
		attributeValue: any?,
		timeout: number?
	): any
		assert(typeof(attributeName) == "string", "waitForChildWithAttribute: attributeName must be a string")

		return Module.waitForChildWithPredicate(parent, function(child)
			local value = child:GetAttribute(attributeName)
			if attributeValue ~= nil then
				return value == attributeValue
			else
				return value ~= nil
			end
		end, timeout)
	end
end

-- WAITFORDESCENDANT FUNCTIONS --
do
	-- Yields until a valid descendant is found.
	function Module.waitForDescendantWithPredicate(
		parent: Instance,
		isValid: (any) -> boolean,
		timeout: number?
	): any
		assert(typeof(parent) == "Instance", "waitForDescendantWithPredicate: parent must be an Instance")
		assert(typeof(isValid) == "function", "waitForDescendantWithPredicate: isValid must be a function")

		for _, descendant in ipairs(parent:GetDescendants()) do
			if isValid(descendant) then
				return descendant
			end
		end

		local thread = coroutine.running()
		local connection: RBXScriptConnection?

		connection = parent.DescendantAdded:Connect(function(descendant)
			if not connection then
				return
			end
			if not isValid(descendant) then
				return
			end

			connection:Disconnect()
			connection = nil

			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, descendant)
			end
		end)

		if timeout then
			task.delay(timeout, function()
				if not connection then
					return
				end

				connection:Disconnect()
				connection = nil

				if coroutine.status(thread) == "suspended" then
					task.spawn(thread)
				end
			end)
		end

		return coroutine.yield()
	end

	function Module.waitForDescendantWhichIsA(
		parent: Instance,
		className: string,
		timeout: number?
	): any
		assert(typeof(className) == "string", "waitForDescendantWhichIsA: className must be a string")

		return Module.waitForDescendantWithPredicate(parent, function(obj)
			return obj:IsA(className)
		end, timeout)
	end

	function Module.waitForDescendantWithTag(
		parent: Instance,
		tagName: string,
		timeout: number?
	): any
		assert(typeof(tagName) == "string", "waitForDescendantWithTag: tagName must be a string")

		return Module.waitForDescendantWithPredicate(parent, function(obj)
			return obj:HasTag(tagName)
		end, timeout)
	end

	function Module.waitForDescendantWithAttribute(
		parent: Instance,
		attributeName: string,
		attributeValue: any?,
		timeout: number?
	): any
		assert(typeof(attributeName) == "string", "waitForDescendantWithAttribute: attributeName must be a string")

		return Module.waitForDescendantWithPredicate(parent, function(obj)
			local value = obj:GetAttribute(attributeName)
			if attributeValue ~= nil then
				return value == attributeValue
			else
				return value ~= nil
			end
		end, timeout)
	end

	function Module.waitForDescendant(
		parent: Instance,
		name: string,
		timeout: number?
	): any
		return Module.waitForDescendantWithPredicate(parent, function(instance)
			return instance.Name == name
		end, timeout)
	end

	--[[
		Yields until the <code>PrimaryPart</code> is available for <code>model</code>.
	]]
	function Module.waitForPrimaryPart(
		model: Model,
		timeout: number?
	): BasePart?
		assert(model:IsA("Model"), "Expected model")
		if model.PrimaryPart then
			return model.PrimaryPart
		end
		local signal = model:GetPropertyChangedSignal("PrimaryPart")
		if timeout then
			_game.waitWithTimeout(signal, timeout)
		else
			signal:Wait()
		end
		return model.PrimaryPart
	end
end

@deprecated
-- Deprecated. Use scheduleDestruction instead
function Module.destroy(object: Instance, destroyAfter: number?)
	assert(object and typeof(object) == "Instance", "object is invalid or nil")

	Debris:AddItem(object, destroyAfter or 0)
end

@deprecated
-- Deprecated.
-- Destroys all objects that match the class via :IsA()
-- You can include a predicate to filter instances to be destroyed and include descendants.
function Module.destroyAllOfClass(searchIn: any, class: string, canDestroy: ((instance: any) -> (boolean))?, descendants: boolean?, destroyAfter: number?)
	assert(class and typeof(class) == "string", "class is invalid or nil")
	assert(searchIn and typeof(searchIn) == "Instance", "object is invalid or nil")
	local destroyAfter = destroyAfter or 0

	local children = if descendants then searchIn:GetDescendants() else searchIn:GetChildren()
	for _, object in ipairs(children) do
		if object:IsA(class) then
			if canDestroy and not canDestroy(object) then
				continue
			end

			if destroyAfter == 0 then
				object:Destroy()
			else
				Debris:AddItem(object, destroyAfter)
			end
		end
	end
end

-- LOAD FUNCTIONS --
do
	--[[
		Collects every Model or Folder in pre-order (parent before children).
	]]
	local function collectContainersPreOrder(
		root: Instance,
		out: { any }?
	): { any }
		local out = out or {}
		if root:IsA("Model") or root:IsA("Folder") then
			table.insert(out, root)
			for _, child in ipairs(root:GetChildren()) do
				collectContainersPreOrder(child, out)
			end
		end
		return out
	end

	--[[
		Gradually instantiates your templateRoot and all descendant Models/Folders
		under destinationParent, in top-down order.
	
		<strong>root</strong>: The instance to be gradually loaded.
		<strong>destination</strong>: The desired parent for <strong>root</strong>.
		<strong>instancesPerFrame</strong>: How many models/folders to load per frame for performance control.
	]]
	function Module.loadModelHierarchyGradually(
		rootModel: Instance,
		destinationParent: Instance,
		instancesPerFrame: number
	): Future.Future<>
		assert(
			typeof(instancesPerFrame) == "number"
				and instancesPerFrame > 0,
			"instancesPerFrame must be > 0"
		)
		assert(
			rootModel:IsA("Model") or rootModel:IsA("Folder"),
			"rootModel must be a Model or Folder"
		)

		-- Gather every container (root + descendants) in pre-order
		local containers = collectContainersPreOrder(rootModel)

		-- Remember where each one originally lived
		local originalParentMap: { [Instance]: Instance } = {}
		for _, c in ipairs(containers) do
			originalParentMap[c] = c.Parent
		end

		-- Detach all containers except the root back to their old parent
		-- (this is a ServerStorage or similar, so no network spike here)
		local ghostParent = originalParentMap[rootModel]
		for i = 2, #containers do
			containers[i].Parent = ghostParent
		end

		-- Return a Future that, on Heartbeat, reparents one batch at a time
		return Future.new(function(
			orderedContainers: { Instance },
			parentMap: { [Instance]: Instance },
			rate: number,
			destination: Instance
		)
			-- move the root itself first (now empty) into the new parent
			local root = orderedContainers[1]
			root.Parent = destination

			local index = 2
			while index <= #orderedContainers do
				for _ = 1, rate do
					local container = orderedContainers[index]
					-- put it back under its original parent (which has already moved)
					container.Parent = parentMap[container]
					index += 1
					if index > #orderedContainers then
						break
					end
				end
				RunService.Heartbeat:Wait()
			end
		end, containers, originalParentMap, instancesPerFrame, destinationParent)
	end
end

-- DESTROY FUNCTIONS --
do
	local function collectInstancesPostOrder(instance: Instance): { Instance }
		local result = {}

		local function visit(inst: Instance)
			for _, child in inst:GetChildren() do
				visit(child)
			end
			table.insert(result, inst)
		end

		visit(instance)
		return result
	end

	local function collectContainersPostOrder(root: Instance): { Instance }
		local result: { Instance } = {}

		local function visit(instance: Instance)
			for _, child in instance:GetChildren() do
				visit(child)
			end

			if instance ~= root and (instance:IsA("Model") or instance:IsA("Folder")) then
				table.insert(result, instance)
			end
		end

		visit(root)
		return result
	end

	--[[
		Destroys the root and its descendants starting from the 'leaves' back to the 'root'.
		<strong>instancesPerFrame</strong>: How many instances to destroy per frame for performance control.
	]]
	function Module.destroyHierarchyGradually(root: Instance, instancesPerFrame: number): Future.Future<>
		assert(typeof(instancesPerFrame) == "number" and instancesPerFrame > 0, "instancesPerFrame must be a number greater than 0")
		local instances = collectInstancesPostOrder(root)
		return Future.new(function(instances, instancesPerFrame)
			local index = 1
			while index <= #instances do
				for i = 1, instancesPerFrame do
					local instance = instances[index]
					if instance then
						instance:Destroy()
					end
					index += 1
					if index > #instances then
						break
					end
				end
				RunService.Heartbeat:Wait()
			end
		end, instances, instancesPerFrame)
	end

	--[[
		Destroys all descendants of the root (but not the root itself), starting from the 'leaves' back to the 'root'.
		<strong>instancesPerFrame</strong>: How many instances to destroy per frame for performance control.
	]]
	function Module.destroyDescendantsGradually(root: Instance, instancesPerFrame: number): Future.Future<>
		assert(typeof(instancesPerFrame) == "number" and instancesPerFrame > 0, "instancesPerFrame must be a number greater than 0")
		local instances = collectInstancesPostOrder(root)

		-- Exclude the root itself (last in post-order)
		table.remove(instances, #instances)

		return Future.new(function(instances, instancesPerFrame)
			local index = 1
			while index <= #instances do
				for i = 1, instancesPerFrame do
					local instance = instances[index]
					if instance then
						instance:Destroy()
					end
					index += 1
					if index > #instances then
						break
					end
				end
				RunService.Heartbeat:Wait()
			end
		end, instances, instancesPerFrame)
	end

	--[[
		Destroys all descendant models and folders (excluding the root), starting from the leaves upward.
		Skips destroying individual parts/scripts/etc.
		<strong>instancesPerFrame</strong>: How many models/folders to destroy per frame.
		<strong>shouldDestroy</strong>: Optional predicate to evaluate if the given container (model or folder) should be destroyed.
	]]
	function Module.destroyDescendantModelsGradually(root: Instance, instancesPerFrame: number, shouldDestroy: ( (container: any) -> (boolean) )?): Future.Future<>
		assert(typeof(instancesPerFrame) == "number" and instancesPerFrame > 0, "instancesPerFrame must be a number greater than 0")

		local containers = collectContainersPostOrder(root)
		local shouldDestroy: (any) -> (boolean) = shouldDestroy or function() return true end

		return Future.new(function(instances, instancesPerFrame)
			local index = 1
			while index <= #instances do
				for _ = 1, instancesPerFrame do
					local instance = instances[index]
					if instance and shouldDestroy(instance) then
						instance:Destroy()
					end
					index += 1
					if index > #instances then
						break
					end
				end
				RunService.Heartbeat:Wait()
			end
		end, containers, instancesPerFrame)
	end

	-- Destroys the instance via Debris.
	-- Default delay is 0.
	function Module.scheduleDestruction(
		instance: any,
		destroyAfter: number?
	)
		assert(typeof(instance) == "Instance", "scheduleDestruction: instance must be an Instance")
		local destroyAfter = destroyAfter or 0
		Debris:AddItem(instance, destroyAfter)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>isValid</code>
	-- Default is no limit.
	function Module.destroyAllWithPredicate(
		searchIn: any,
		isValid: (any) -> boolean,
		searchDepth: number?
	)
		assert(typeof(searchIn) == "Instance", "destroyAllWithPredicate: searchIn must be an Instance")
		assert(typeof(isValid) == "function", "destroyAllWithPredicate: isValid must be a function")
		if searchDepth ~= nil then
			assert(
				typeof(searchDepth) == "number" and searchDepth >= 1,
				"destroyAllWithPredicate: searchDepth must be a positive number"
			)
		end

		if not searchDepth then
			for _, obj in ipairs(searchIn:GetDescendants()) do
				if isValid(obj) then
					obj:Destroy()
				end
			end
		elseif searchDepth == 1 then
			for _, child in ipairs(searchIn:GetChildren()) do
				if isValid(child) then
					child:Destroy()
				end
			end
		else
			local function recurse(node: Instance, depth: number)
				for _, child in ipairs(node:GetChildren()) do
					if isValid(child) then
						child:Destroy()
					end
					if depth < searchDepth then
						recurse(child, depth + 1)
					end
				end
			end
			recurse(searchIn, 1)
		end
	end

	-- Uses :IsA()!
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements of <code>className</code>
	-- Default is no limit.
	function Module.destroyAllFromClass(
		className: string,
		searchIn: Instance,
		searchDepth: number?
	)
		assert(typeof(className) == "string", "destroyAllFromClass: className must be a string")
		Module.destroyAllWithPredicate(
			searchIn,
			function(obj) return obj:IsA(className) end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>tagName</code>
	-- Default is no limit.
	function Module.destroyAllWithTag(
		tagName: string,
		searchIn: Instance,
		searchDepth: number?
	)
		assert(typeof(tagName) == "string", "destroyAllWithTag: tagName must be a string")
		Module.destroyAllWithPredicate(
			searchIn,
			function(obj) return obj:HasTag(tagName) end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>attribute</code>
	-- Default is no limit.
	-- <strong>attributeValue</strong>: Optionally match a value.
	function Module.destroyAllWithAttribute(
		attribute: string,
		searchIn: Instance,
		attributeValue: any?,
		searchDepth: number?
	)
		assert(typeof(attribute) == "string", "destroyAllWithAttribute: attribute must be a string")
		Module.destroyAllWithPredicate(
			searchIn,
			function(obj)
				local val = obj:GetAttribute(attribute)
				if attributeValue ~= nil then
					return val == attributeValue
				else
					return val ~= nil
				end
			end,
			searchDepth
		)
	end
end

-- ANCESTRY FIND FUNCTIONS --
do
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements.
	-- Default is no limit.
	function Module.getAncestors(
		instance: any,
		searchDepth: number?
	): { any }
		assert(typeof(instance) == "Instance", "getAncestors: instance must be an Instance")
		if searchDepth ~= nil then
			assert(
				typeof(searchDepth) == "number" and searchDepth >= 1,
				"getAncestors: searchDepth must be a positive number"
			)
		end

		local ancestors = {}
		local depth = 0
		local current = instance.Parent

		while current and (not searchDepth or depth < searchDepth) do
			table.insert(ancestors, current)
			current = current.Parent
			depth += 1
		end

		return ancestors
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>isValid()</code>
	-- Default is no limit.
	function Module.findAllAncestorsWithPredicate(
		instance: any,
		isValid: (any) -> boolean,
		searchDepth: number?
	): { any }
		assert(typeof(isValid) == "function", "findAllAncestorsWithPredicate: isValid must be a function")
		local results   = {}
		for _, anc in ipairs(Module.getAncestors(instance, searchDepth)) do
			if isValid(anc) then
				table.insert(results, anc)
			end
		end
		return results
	end

	---<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for an element with <code>isValid()</code>
	-- Default is no limit.
	function Module.findFirstAncestorWithPredicate(
		instance: any,
		isValid: (any) -> boolean,
		searchDepth: number?
	): any
		assert(typeof(isValid) == "function", "findFirstAncestorWithPredicate: isValid must be a function")
		for _, anc in ipairs(Module.getAncestors(instance, searchDepth)) do
			if isValid(anc) then
				return anc
			end
		end
		return nil
	end

	-- Uses :IsA(), not .ClassName!
	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>className</code>
	-- Default is no limit.
	function Module.findAllAncestorsWhichAre(
		instance: any,
		className: string,
		searchDepth: number?
	): { any }
		assert(typeof(className) == "string", "findAllAncestorsWhichAre: className must be a string")
		return Module.findAllAncestorsWithPredicate(
			instance,
			function(obj)
				return obj:IsA(className)
			end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>tagName</code>
	-- Default is no limit.
	function Module.findAllAncestorsWithTag(
		instance: any,
		tagName: string,
		searchDepth: number?
	): { any }
		assert(typeof(tagName) == "string", "findAllAncestorsWithTag: tagName must be a string")
		return Module.findAllAncestorsWithPredicate(
			instance,
			function(obj)
				return obj:HasTag(tagName)
			end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for element with <code>tagName</code>
	-- Default is no limit.
	function Module.findFirstAncestorWithTag(
		instance: any,
		tagName: string,
		searchDepth: number?
	): any
		assert(typeof(tagName) == "string", "findFirstAncestorWithTag: tagName must be a string")
		return Module.findFirstAncestorWithPredicate(
			instance,
			function(obj) return obj:HasTag(tagName) end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for elements with <code>attribute</code>
	-- Default is no limit.
	-- <strong>attributeValue</strong>: Optionally match a value.
	function Module.findAllAncestorsWithAttribute(
		instance: any,
		attribute: string,
		attributeValue: any?,
		searchDepth: number?
	): { any }
		assert(typeof(attribute) == "string", "findAllAncestorsWithAttribute: attribute must be a string")
		return Module.findAllAncestorsWithPredicate(
			instance,
			function(obj)
				local val = obj:GetAttribute(attribute)
				if attributeValue ~= nil then
					return val == attributeValue
				else
					return val ~= nil
				end
			end,
			searchDepth
		)
	end

	--<strong>searchDepth</strong>: Optional argument that defines how far to recursively search for an element with <code>attribute</code>
	-- Default is no limit.
	-- <strong>attributeValue</strong>: Optionally match a value.
	function Module.findFirstAncestorWithAttribute(
		instance: any,
		attribute: string,
		attributeValue: any?,
		searchDepth: number?
	): any?
		assert(typeof(attribute) == "string", "findFirstAncestorWithAttribute: attribute must be a string")
		return Module.findFirstAncestorWithPredicate(
			instance,
			function(obj)
				local val = obj:GetAttribute(attribute)
				if attributeValue ~= nil then
					return val == attributeValue
				else
					return val ~= nil
				end
			end,
			searchDepth
		)
	end
end

function Module.getNearestPartFromArray(parts: { BasePart }, comparePosition: Vector3): BasePart
	local lastDist = math.huge
	local closestPart = nil
	for _, part in ipairs(parts) do
		local distance = (part.Position - comparePosition).Magnitude
		if distance < lastDist then
			lastDist = distance
			closestPart = part
		end
	end
	return closestPart
end

function Module.snapToRelative(modelToSnap: Model, snapAnchor: BasePart, targetPosition: Vector3)
	assert(modelToSnap and typeof(modelToSnap) == "Instance" and modelToSnap.PrimaryPart, "Model is nil or doesn't have PrimaryPart")

	local offset = snapAnchor.Position - modelToSnap.PrimaryPart.Position
	coroutine.wrap(function()
		repeat task.wait()
			modelToSnap:PivotTo(CFrame.new(targetPosition - offset))
		until (snapAnchor.Position - targetPosition).Magnitude < 1
	end)()

	return targetPosition - offset
end

local activeTweens = {}
function Module.tweenModelScale(model: Model, duration: number, targetScale: number, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?)
	local initialScale = model:GetScale() -- Get the model's original scale
	local timeElapsed = 0

	if activeTweens[model] then
		activeTweens[model]:Disconnect()
	end

	activeTweens[model] = RunService.RenderStepped:Connect(function(dt)
		timeElapsed += dt
		local alpha = TweenService:GetValue(timeElapsed / duration, easingStyle or Enum.EasingStyle.Linear, easingDirection or Enum.EasingDirection.In)
		local currentScale = initialScale + (targetScale - initialScale) * alpha

		-- Ensure the scale is a positive non-zero value
		if currentScale <= 0 then
			currentScale = 0.001
		end

		model:ScaleTo(currentScale)

		if alpha >= 1 then
			activeTweens[model]:Disconnect()
			activeTweens[model] = nil
		end
	end)
end

function Module.setModelCollisionGroup<T>(model: T, collisionGroup: string): T
	assert(typeof(model) == "Instance" and model:IsA("Model"), "Expected model.")
	if not PhysicsService:IsCollisionGroupRegistered(collisionGroup) then
		error(`CollisionGroup: {collisionGroup} is not registered!`)
	end

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = collisionGroup
		end
	end

	return model
end

function Module.createCollisionGroup(name: string, nonCollidableGroups: {string})
	if PhysicsService:IsCollisionGroupRegistered(name) then
		warn(`Collision group with name {name} already exists.`)
		return
	end

	local newCollisionGroup = PhysicsService:RegisterCollisionGroup(name)
	for i, otherGroupName in ipairs(nonCollidableGroups) do
		if not PhysicsService:IsCollisionGroupRegistered(otherGroupName) then
			error(`CollisionGroup: {otherGroupName} is not registered!`)
		end

		if not PhysicsService:CollisionGroupsAreCollidable(name, otherGroupName) then
			PhysicsService:CollisionGroupSetCollidable(name, otherGroupName, false)
		end
	end
end

-- <strong>YIELDS</strong>
-- This yields until there is an attribute
function Module.waitForAttributes(logger: Logger.LoggerType, attributes: {string}, parent: Instance)
	for _, attrName: string in ipairs(attributes) do
		if parent:GetAttribute(attrName) == nil then
			logger:print(`{script.Name} is waiting for attribute {attrName} to initialize on {parent.ClassName} {parent.Name}`)
			parent:GetAttributeChangedSignal(attrName):Wait()
			logger:print(`{attrName} has been initialized on {parent.ClassName} {parent.Name}`)
		end
	end
end

function Module.weldToPrimaryPart(part1: BasePart, model: Model): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Parent = model.PrimaryPart
	weld.Part0 = model.PrimaryPart
	weld.Part1 = part1
	return weld
end

-- If no parent, automatically parents to part0
function Module.weld(part0: BasePart, part1: BasePart, parent: Instance?): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = parent or part0
	return weld
end

-- Copies attributes from one instance to another with options on the copying behavior.
-- Default mode is reconcile.
-- SYNC: Copies all attributes and pastes them on <code>to</code>. Overrides values and removes any attributes not found on <code>from</code>.
-- RECONCILE: Copies all attributes and pastes them on <code>to</code>. Skips same-name attributes and does not delete attributes.
-- OVERRIDE: Copies all attributes and pastes them on <code>to</code>. Can override values but does not delete attributes.
-- REPLACE: Copies only same name attributes on <code>to</code> and overrides them. Does not add or delete attributes.
function Module.copyAttributes(from: Instance, to: Instance, mode: ("SYNC" | "RECONCILE" | "OVERRIDE" | "REPLACE")?)
	local mode = mode or "RECONCILE"

	local attributesToCopy = from:GetAttributes()
	if mode == "SYNC" then
		for name, _ in to:GetAttributes() do
			to:SetAttribute(name, attributesToCopy[name] or nil)
		end
		for name, value in attributesToCopy do
			to:SetAttribute(name, value)
		end
	elseif mode == "RECONCILE" then
		for name, value in attributesToCopy do
			if to:GetAttribute(name) then
				continue
			end
			to:SetAttribute(name, value)
		end
	elseif mode == "OVERRIDE" then
		for name, value in attributesToCopy do
			to:SetAttribute(name, value)
		end
	elseif mode == "REPLACE" then
		for name, value in attributesToCopy do
			if not to:GetAttribute(name) then
				continue
			end
			to:SetAttribute(name, value)
		end
	end
end

return Module
