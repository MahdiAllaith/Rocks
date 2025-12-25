local myServicesFolder = script.Parent
local servicesFolder = myServicesFolder:WaitForChild("Services")

local runService = game:GetService("RunService")

local myServices = {}

myServices["Services"] = {}

function myServices:GetService(_serviceName)

	local getServiceAttempts = 3
	local attemptCooldown = 0.5

	local function attempt()

		for serviceName, serviceData in pairs(self["Services"]) do

			if serviceName == _serviceName then

				return serviceData

			end

		end

	end

	for i = 1, getServiceAttempts, 1 do

		task.wait(attemptCooldown)

		local attemptResult = attempt()

		if attemptResult then

			return attemptResult

		end

	end
end

function myServices:FetchAllServices()
	if #self["Services"] == 0 then

		for i, serviceModule in pairs(servicesFolder:GetChildren()) do

			if serviceModule:IsA("ModuleScript") and (serviceModule:GetAttribute("ServiceRunType") == "Server") then

				local serviceName = serviceModule.Name
				local serviceData = require(serviceModule)

				if serviceData["Init"] then

					task.spawn(function()

						local initResult = serviceData:Init()

						if initResult then

							print('[SERVER MODULE LOADER]: Successfully initiated "'..serviceName..'" service')

						else

							warn('[SERVER MODULE LOADER]: Error while initiating "'..serviceName..'" service')

						end

					end)

				end

				self["Services"][serviceName] = serviceData

			end

		end

	end

	return myServices["Services"]

end

return myServices