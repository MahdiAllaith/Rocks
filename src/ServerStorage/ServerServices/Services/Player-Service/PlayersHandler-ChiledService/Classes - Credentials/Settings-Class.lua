local SettingsClass = {}
SettingsClass.__index = SettingsClass

function SettingsClass.Init()
	local self = setmetatable({}, SettingsClass)
	
	return self
end

return SettingsClass
