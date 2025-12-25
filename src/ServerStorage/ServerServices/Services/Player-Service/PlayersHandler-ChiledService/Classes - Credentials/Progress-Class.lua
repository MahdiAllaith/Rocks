local ProgressClass = {}
ProgressClass.__index = ProgressClass

function ProgressClass.Init(DATA)
	local self = setmetatable({}, ProgressClass)


	return self
end

return ProgressClass
