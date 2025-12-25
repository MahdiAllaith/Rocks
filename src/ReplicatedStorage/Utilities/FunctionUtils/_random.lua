local _Random = {}

local rng = Random.new(tick())

-- <strong>percentChance</strong>: Should be a value between 0-100.
-- <strong>luck</strong>: Represents how many rerolls.
function _Random.rollChance(percentChance: number, luck: number?): boolean
	if percentChance <= 0 then
		return false
	end
	luck = luck or 0
	local rolls = math.ceil(math.abs(luck :: number))
	local num2 = rng:NextNumber(0, 100)

	for i = 1, rolls do
		local b = rng:NextNumber(0, 100)
		num2 = if luck > 0 then math.min(num2, b) else math.max(num2, b)
	end
	if num2 <= percentChance then
		return true
	end
	return false
end

function _Random.range(minF: number, maxF: number, seed: number)
	assert(minF and typeof(minF) == "number", "minF is invalid or nil")
	assert(maxF and typeof(maxF) == "number", "maxF is invalid or nil")

	local RBLX_Random = Random.new(seed or math.random() * 1000000)
	local randomValue = RBLX_Random:NextInteger(minF, maxF)

	return randomValue
end

function _Random.object(objectsList: {} | Instance, recursive: boolean)
	assert(objectsList and typeof(objectsList) == "table" or typeof(objectsList) == "Instance", "objectsList is invalid or nil")

	local list = typeof(objectsList) == "Instance" and (recursive and objectsList:GetDescendants() or objectsList:GetChildren()) or objectsList
	local randomObject = list[_Random.range(1, #list)]

	return randomObject
end

function _Random.randomString(length: number, includeCapitals: boolean)
	local random = Random.new()
	local letters = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}

	local function getRandomLetter()
		return letters[random:NextInteger(1,#letters)]
	end


	local length = length or 10
	local str = ''
	for i = 1, length do
		local randomLetter = getRandomLetter()
		if includeCapitals and random:NextNumber() > .5 then
			randomLetter = string.upper(randomLetter)
		end
		str = str .. randomLetter
	end
	return str
end

return _Random
