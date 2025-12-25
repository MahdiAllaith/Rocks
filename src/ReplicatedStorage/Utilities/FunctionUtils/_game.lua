--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local _Signal = require("../ModuleUtils/_Signal")
local Players = game:GetService("Players")
local _table = require("./_table")

local sfxSoundGroup: SoundGroup? do
	local master = SoundService:FindFirstChild("Master")
	if master then
		sfxSoundGroup = master:FindFirstChild("SFX")
	end
end

local Module = {}
local rng = Random.new(tick())

-----------------------------
-- UTIL FUNCTIONS --
-----------------------------

-- Allows you to call a lambda function to avoid creating closures.
function Module.call<T1..., T2...>(fn: (T1...) -> (T2...), ...: T1...): T2...
	return fn(...)
end

-- Reduces memory usage for RBXScriptSignal handlers by only capturing a single upvalue.
-- Upvalue memory usage is <code>32 + 28n</code> bytes where <code>n</code> is the number of upvalues.
function Module.connect(signal: RBXScriptSignal, fn, ...)
	assert(typeof(signal) == "RBXScriptSignal", "invalid signal given to connect")
	local args = table.pack(fn, ...)

	return signal:Connect(function(...)
		-- Fast path: no bound args
		local fn = args[1]
		if args.n == 1 then
			return fn(...)
		end
		local signalArgCount = select("#", ...)
		-- Fast path: no signal args
		if signalArgCount == 0 then
			return fn(table.unpack(args, 2, args.n))
		end

		-- General case: combine signal args + bound args
		local totalCount = signalArgCount + args.n
		local totalArgs = table.create(totalCount)

		for i = 1, signalArgCount do
			totalArgs[i] = select(i, ...)
		end

		for i = 2, args.n do
			local boundIndex = i - 1
			totalArgs[signalArgCount + boundIndex] = args[i]
		end

		return fn(table.unpack(totalArgs, 1, totalCount))
	end)
end

do
	local throttleState: { [any]: { [any]: boolean } } = _table.weakCache("k")
	-- Runs <strong>func</strong> immediately and blocks further calls until the deferred delay is over.
	-- <strong>identifier</strong> is stored per function and is not global.
	function Module.throttleDefer<T, A...>(
		identifier: T,
		func: (T, A...) -> (),
		...: A...
	): boolean
		throttleState[func] = throttleState[func] or {}

		if throttleState[func][identifier] then
			return false
		end

		throttleState[func][identifier] = true
		task.defer(function()
			throttleState[func][identifier] = nil
		end)

		task.spawn(func, identifier, ...)
		return true
	end

	local timeThrottle: { [any]: number } = {}
	-- Runs <strong>func</strong> immediately and blocks further calls until the time delay is over.
	-- <strong>identifier</strong> is stored per function and is not global.
	function Module.throttle<T, A...>(
		identifier: T,
		delay: number,
		func: (T, A...) -> (),
		...: A...
	): boolean
		local now = os.clock()
		local last = timeThrottle[identifier]
		if last and now - last < delay then
			return false
		end

		timeThrottle[identifier] = now
		task.spawn(func, identifier, ...)

		task.delay(delay, function()
			-- to avoid memory leaks
			if timeThrottle[identifier] == now then
				timeThrottle[identifier] = nil
			end
		end)

		return true
	end
end

function Module.cloneTweenInfo(tweenInfo: TweenInfo, overrides: { [any]: any }?): TweenInfo
	local time = if overrides then overrides.Time or tweenInfo.Time else tweenInfo.Time
	local easingStyle = if overrides then overrides.EasingStyle or tweenInfo.EasingStyle else tweenInfo.EasingStyle
	local easingDirection = if overrides then overrides.EasingDirection or tweenInfo.EasingDirection else tweenInfo.EasingDirection
	local repeatCount = if overrides then overrides.RepeatCount or tweenInfo.RepeatCount else tweenInfo.RepeatCount
	local reverses = if overrides then overrides.Reverses or tweenInfo.Reverses else tweenInfo.Reverses
	local delayTime = if overrides then overrides.DelayTime or tweenInfo.DelayTime else tweenInfo.DelayTime

	return TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
end

function Module.inFirstPerson(distanceDelta: number?): boolean
	assert(RunService:IsClient(), "inFirstPerson() can only be called by client.")
	local dist = (workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.Focus.Position).Magnitude

	local distanceDelta = distanceDelta or 0
	local threshold = math.max(0, 0.501 + distanceDelta)

	return dist <= threshold
end

-- DEPRECATED --
do
	local SPEED_OF_SOUND = 343 -- meters per second
	local METERS_PER_STUD = 0.28 -- 1 stud is approx 0.28 meter

	-- <strong><code>!DEPRECATED!</code></strong>
	-- <strong><code>!YIELDS!</code></strong>
	-- Use <code>Math.getSoundTravelDuration()</code> instead
	-- This will yield for the exact duration it takes for sound to travel the given distance.
	function Module.yieldForSoundTravel(distanceInStuds: number)
		warn("yieldForSoundTravel() is deprecated")
		local distanceInMeters = distanceInStuds * METERS_PER_STUD
		local timeToYield = distanceInMeters / SPEED_OF_SOUND

		task.wait(timeToYield)
	end
end
-- --

-- <strong><code>!YIELDS!</code></strong>
-- Pauses the current thread until the end of the current resumption cycle.
function Module.defer()
	local current = coroutine.running()
	task.defer(function()
		if coroutine.status(current) == "suspended" then
			task.spawn(current)
		end
	end)
	return coroutine.yield()
end

-- This function will yield until all supplied signals fire once with a timeout.
-- -1 for no timeout
-- <strong><code>!YIELDS!</code></strong>
function Module.waitForAll<Func, T...>(timeoutInSeconds: number, ...: RBXScriptSignal | _Signal.SignalType<Func, T...>): (boolean, T...)
	local events = table.pack(...)
	local connections = {} :: { any }
	local totalCount = #events
	local count = 0
	local thread = coroutine.running()

	local function onEvent()
		if not connections then
			return
		end

		count += 1
		if count >= totalCount then
			connections = nil
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, true)
			end
		end
	end

	for i, event: RBXScriptSignal in ipairs(events) do
		connections[i] = event:Once(onEvent)
	end

	if timeoutInSeconds >= 0 then
		task.delay(timeoutInSeconds, function()
			if not connections then
				return
			end

			for _, connection in connections do
				connection:Disconnect()
			end
			connections = nil
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, true)
			end
		end)
	end

	return coroutine.yield()
end

-- <strong><code>!YIELDS!</code></strong>
function Module.waitForEither<Func, T...>(eventYes: RBXScriptSignal | _Signal.SignalType<Func, T...>, eventNo: RBXScriptSignal | _Signal.SignalType<Func, T...>): boolean
	local eventYes = eventYes -- fixes type annotation issue
	local eventNo = eventNo -- fixes type annotation issue
	local thread = coroutine.running()

	local connection1 = nil
	local connection2 = nil
	
	connection1 = eventYes:Once(function(...)
		if connection1 == nil then
			return
		end

		connection1:Disconnect()
		connection2:Disconnect()
		connection1 = nil
		connection2 = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, true, ...)
		end
	end)

	connection2 = eventNo:Once(function(...)
		if connection2 == nil then
			return
		end

		connection1:Disconnect()
		connection2:Disconnect()
		connection1 = nil
		connection2 = nil
		
		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, false, ...)
		end
	end)

	return coroutine.yield()
end

-- -1 for no timeout
-- <strong><code>!YIELDS!</code></strong>
function Module.waitForAny(timeoutInSeconds: number, ...: RBXScriptSignal | _Signal.SignalType<any, ...any>): (boolean, ...any)
	local thread = coroutine.running()
	local connections = {} :: { any }

	local function disconnectAll()
		for _, connection in connections do
			connection:Disconnect()
		end

		connections = nil
	end

	local function onEvent(...)
		if not connections then
			return
		end

		disconnectAll()
		
		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, false, ...)
		end
	end

	for _, event in {...} do
		table.insert(connections, event:Once(onEvent))
	end

	if timeoutInSeconds >= 0 then
		task.delay(timeoutInSeconds, function()
			if not connections then
				return
			end

			disconnectAll()
			
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, true)
			end
		end)
	end

	return coroutine.yield()
end

-- <strong><code>!YIELDS!</code></strong>
function Module.waitWithTimeout<Func, T...>(event: RBXScriptSignal | _Signal.SignalType<Func, T...>, timeoutInSeconds: number): (boolean, T...)
	local event = event
	local thread = coroutine.running()
	local connection

	local function onOnce(...)
		if not connection then
			return
		end

		connection:Disconnect()
		connection = nil
		
		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, false, ...)
		end
	end

	connection = event:Once(onOnce)

	task.delay(timeoutInSeconds, function()
		if not connection then
			return
		end

		connection:Disconnect()
		connection = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, true)
		end
	end)

	return coroutine.yield()
end

do
	local MAX_POOL_SIZE = 50
	local freeThreads: { thread } = {}

	local function runCallback(callback, thread, ...)
		local success, err = pcall(callback, ...)
		if not success then
			warn(err)
		end
		if #freeThreads < MAX_POOL_SIZE then
			table.insert(freeThreads, thread)
		end
	end

	local function yielder()
		while true do
			runCallback(coroutine.yield())
		end
	end
	
	-- Similar to task.spawn, but doesn't return any threads.
	-- This is a 'fast spawn' that recycles thread for improved performance.
	function Module.spawn<T...>(callback: (T...) -> (), ...: T...)
		local thread
		if #freeThreads > 0 then
			thread = freeThreads[#freeThreads]
			freeThreads[#freeThreads] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end

		task.spawn(thread, callback, thread, ...)
	end
end

do
	type RaycastResultData = {
		Instance: Instance,
		Position: Vector3,
		Normal: Vector3,
		Material: Enum.Material,
		Distance: number
	}

	function Module.createRemoteCompatibleRaycastResult(result: RaycastResult): RaycastResultData
		return {
			Instance = result.Instance,
			Position = result.Position,
			Normal = result.Normal,
			Material = result.Material,
			Distance = result.Distance
		} :: RaycastResultData
	end

	-- Client-only!
	function Module.getMouseRay(params: RaycastParams, maxDistance: number?): Ray
		assert(RunService:IsClient(), "getMouseRay can only be used from client-side!")
		local mousePos = UserInputService:GetMouseLocation()
		maxDistance = maxDistance or 5000
		return workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	end
	
	-- Client-only!
	function Module.raycastFromMouse(params: RaycastParams, maxDistance: number?): (RaycastResult?, Ray)
		assert(RunService:IsClient(), "raycastFromMouse can only be used from client-side!")
		local mousePos = UserInputService:GetMouseLocation()
		maxDistance = maxDistance or 5000
		local mouseRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)

		local direction = mouseRay.Direction * maxDistance
		local result = workspace:Raycast(mouseRay.Origin, direction, params)

		return result, Ray.new(mouseRay.Origin, direction)
	end
	
	-- Client-only!
	function Module.raycastFromScreenCenter(params: RaycastParams, maxDistance: number?): (RaycastResult?, Ray)
		assert(RunService:IsClient(), "raycastFromScreenCenter can only be used from client-side!")
		maxDistance = maxDistance or 5000
		local mouseRay = workspace.CurrentCamera:ViewportPointToRay(
			workspace.CurrentCamera.ViewportSize.X/2,
			workspace.CurrentCamera.ViewportSize.Y/2
		)

		local direction = mouseRay.Direction * maxDistance
		local result = workspace:Raycast(mouseRay.Origin, direction, params)

		return result, Ray.new(mouseRay.Origin, direction)
	end
	
	-- Client-only!
	-- Shorthand for <code>UserSettings():GetService("UserGameSettings") :: UserGameSettings</code>
	-- Returns the class that stores all client-side settings, such as graphics quality level.
	function Module.getUserSettings(): UserGameSettings
		return UserSettings():GetService("UserGameSettings")
	end
end

function Module.getPlayerList(exclude: { Player }?): {Player}
	if not exclude then
		return Players:GetPlayers()
	end
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if exclude and table.find(exclude, player) then
			continue
		end
		table.insert(result, player)
	end
	return result
end

-- Currently, :GetPlayerFromCharacter is not safe to call in parallel (which makes no sense).
function Module.getPlayerFromCharacterWriteSafe(character: Model): Player?
	for _, player in Players:GetPlayers() do
		if player.Character == character then
			return player
		end
	end
	return
end

-- DEPRECATED!
-- Use <code>Remotes.fireToAllClientsExcept()</code>
function Module.fireToAllClientsExcept(exception: { Player }, remote: RemoteEvent, ...: any)
	warn("Game.fireToAllClientsExcept() is deprecated")
	local players = Module.getPlayerList(exception)
	for _, player in players do
		remote:FireClient(player, ...)
	end
end

function Module.hasEnumKey(key: string, enumTable: { [any]: any }): boolean
	for _, thing in enumTable do
		if typeof(thing) == "table" then
			local found = Module.hasEnumKey(key, thing)
			if found then
				return found
			end
		elseif thing == key then
			return true
		end
	end

	return false
end

function Module.repeatUntil(repeatCallback: () -> boolean, condition: () -> boolean, yield: boolean)
	assert(repeatCallback ~= nil, "repeatCallback is invalid or nil")

	if yield then
		task.spawn(function()
			repeat repeatCallback() until (condition() == true)
		end)
	else
		repeat repeatCallback() until (condition() == true)
	end
end

-- Caches results from a pure function in a weak table so the same input
-- doesn't need to be calculated again for the same output.
function Module.memoize<T, U>(fn: (T) -> (U)): (T) -> (U)
	local cache = {}
	setmetatable(cache, {__mode = "kv"})
	return function(input: T)
		local result = cache[input]
		if not result[input] then
			result = fn(input)
			cache[input] = result
			return result
		end
		return result
	end
end

-- Returns the game's PlaceVersion
function Module.getBuild(): "STUDIO" | string
	if RunService:IsStudio() then
		return "STUDIO"
	else
		return ("%d"):format(game.PlaceVersion)
	end
end

--[=[
	Gets the game build with a server type specified for debugging
	@return string
]=]
function Module.getBuildWithServerType(): string
	return Module.getBuild() .. "-" .. Module.getServerType()
end

--[=[
	Gets a string label for the current server type
]=]
function Module.getServerType(): "PRIVATE" | "RESERVED" | "STANDARD"
	if game.PrivateServerId ~= "" then
		if game.PrivateServerOwnerId ~= 0 then
			return "PRIVATE"
		else
			return "RESERVED"
		end
	else
		return "STANDARD"
	end
end

-- Indicates if this is a server that was purchased by a player.
function Module.isPrivateServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

-- Indicates if this is a reserved server created through the TeleportService.
function Module.isReservedServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

--[=[
	DEPRECATED
	Use: <code>isPrivateServer()</code>
]=]
function Module.isVIPServer(): boolean
	warn("isVIPServer() is deprecated")
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

-- Alternative to <code>Instance.new()</code> that allows you to apply properties at the same time.
-- If the <code>Parent</code> property is included, it will be applied last.
-- Any properties that are supposed to be numbers but are provided as NumberRange will be randomized via :NextNumber()
-- Any values that are tables are presumed to be new instances that will be made children of the primary instance.
function Module.create(className, properties: { [any]: any }?)
	local instance = Instance.new(className)

	if properties then
		local parent
		for name, value in pairs(properties) do
			if name == "Parent" then
				parent = value
				continue
			elseif typeof(value) == "table" then
				local newInstance = Module.create(name, value)
				newInstance.Parent = instance
				continue
			elseif
				typeof(value) == "NumberRange"
				and typeof(instance[name]) == "number"
			then
				value = rng:NextNumber(value.Min, value.Max)
			end
			local success, err = pcall(function()
				instance[name] = value
			end)
			if not success then
				warn(err)
			end
		end
		instance.Parent = parent
	end

	return instance
end

function Module.createInstanceWithAttributes(properties: { Name: string, Attributes: { [any]: any } }, parent: Instance?)
	-- Create the IntValue
	local intValue = Instance.new("IntValue")
	intValue.Name = properties.Name or "IntValue"
	intValue.Value = 0
	intValue.Parent = parent

	-- Add Attributes if provided
	if properties.Attributes then
		for key, val in pairs(properties.Attributes) do
			local valType = typeof(val)
			if valType == "boolean" 
				or valType == "string" 
				or valType == "number" 
				or valType == "Color3" 
				or valType == "Vector3" 
				or valType == "CFrame" then
				intValue:SetAttribute(key, val)
			else
				warn("Unsupported attribute type for key:", key, "Type:", valType)
			end
		end
	end
end


-- Creates the sound. Automatically parents to SoundService if no parent is provided.
-- Sound has parent set last. Default SoundGroup is SFX (if present)
function Module.createSound(properties: { [string]: any }): Sound
	local sound = Instance.new("Sound")
	local parent, soundGroup = SoundService, sfxSoundGroup
	for property, value in pairs(properties) do
		if property == "Parent" then
			parent = value
			continue
		end
		if property == "SoundGroup" then
			soundGroup = value
			continue
		end
		sound[property] = value
	end
	sound.Parent = parent
	sound.SoundGroup = soundGroup
	return sound
end

-- Automatically cleans up the sound once it ends.
-- Default parent is SoundService.
function Module.playSoundClone(sound: Sound, parent: Instance?): Sound
	local clone = sound:Clone()
	clone.Parent = parent or SoundService
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	clone:Play()
	return clone
end

-- Automatically cleans up the sound once it ends. Parent property will be ignored.
-- Default SoundGroup is SFX (if present)
function Module.playSoundFollow(soundProperties: { [string]: any }, follow: BasePart | Attachment): Sound
	local sound = Instance.new("Sound")
	local soundGroup = sfxSoundGroup
	for name, value in pairs(soundProperties) do
		if name == "SoundGroup" then
			soundGroup = value
			continue
		end
		sound[name] = value
	end
	sound.SoundGroup = soundGroup
	
	local myFollowPart = Instance.new("Part")
	myFollowPart.Transparency = 1
	myFollowPart.Anchored = true
	myFollowPart.CanCollide = false
	myFollowPart.CanQuery = false
	myFollowPart.CanCollide = false
	myFollowPart.Size = if follow:IsA("BasePart") then follow.Size else Vector3.new(1, 1, 1)
	
	sound.Parent = myFollowPart
	myFollowPart.Parent = workspace
	local connection = RunService.RenderStepped:Connect(function()
		myFollowPart.Position = if follow:IsA("Attachment") then follow.WorldPosition else follow.Position
	end)
	sound:Play()
	sound.Ended:Once(function()
		connection:Disconnect()
		myFollowPart:Destroy()
	end)
	
	return sound
end

-- Automatically cleans up the sound once it ends.
-- Default SoundGroup is SFX (if present)
function Module.playSoundInWorld(soundProperties: { [string]: any }, position: Vector3): Sound
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	local sound = Instance.new("Sound")
	local soundGroup = sfxSoundGroup
	for name, value in pairs(soundProperties) do
		if name == "SoundGroup" then
			soundGroup = value
			continue
		end
		sound[name] = value
	end
	sound.SoundGroup = soundGroup
	sound.Parent = attachment
	attachment.Parent = workspace.Terrain
	sound:Play()
	sound.Ended:Once(function()
		attachment:Destroy()
	end)
	return sound
end

-- Plays the song for you and automatically cleans it up.
function Module.playSoundOnce(sound: Sound)
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- Automatically cleans up the sound once it ends.
-- Default parent is the SoundService, Default SoundGroup is SFX (if present)
function Module.playSound(soundProperties: { [string]: any }, parent: Instance?): Sound
	local sound = Instance.new("Sound")
	local parent, soundGroup = parent or SoundService, sfxSoundGroup
	for name, value in pairs(soundProperties) do
		if name == "Parent" then
			parent = value
			continue
		end
		if name == "SoundGroup" then
			soundGroup = value
			continue
		end
		sound[name] = value
	end
	
	-- to handle optional min/max distances
	if soundProperties.MinDistance then
		sound.RollOffMinDistance = soundProperties.MinDistance
	end
	if soundProperties.MaxDistance then
		sound.RollOffMaxDistance = soundProperties.MaxDistance
	end
	
	sound.SoundGroup = soundGroup
	sound.Parent = parent
	if sound.PlayOnRemove then
		sound:Destroy()
	else
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
	return sound
end

-- Automatically cleans up the sound once it ends.
-- Default SoundGroup is SFX (if present)
function Module.playRandomSound(soundIds: {string}, soundProperties: { [string]: any }, parent: Instance): Sound
	local soundId = soundIds[rng:NextInteger(1, #soundIds)]

	local sound = Instance.new("Sound")
	local soundGroup = sfxSoundGroup
	for name, value in pairs(soundProperties) do
		if name == "SoundGroup" then
			soundGroup = value
			continue
		end
		sound[name] = value
	end
	sound.SoundGroup = soundGroup
	sound.SoundId = soundId
	sound.Parent = parent
	if sound.PlayOnRemove then
		sound:Destroy()
	else
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	return sound
end

-- Automatically cleans up the sound once it ends.
function Module.playRandomSoundClone(sounds: { Sound }, source: Instance, destroyFirst: boolean?, volume: number?): Sound
	local soundTemplate = sounds[rng:NextInteger(1, #sounds)]

	local sound = soundTemplate:Clone()
	sound.Volume *= (volume or 1)
	sound:Play()
	
	sound.Parent = source
	if destroyFirst or sound.PlayOnRemove then
		sound.PlayOnRemove = true
		sound:Destroy()
	else
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
	
	return sound
end

return Module
