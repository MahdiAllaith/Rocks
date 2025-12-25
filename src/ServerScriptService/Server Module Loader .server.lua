local GlobleModuleLoader = require(game:GetService("ReplicatedStorage").ServicesLoader)
local ServerModuleLoader = require(game:GetService("ServerStorage").ServerServices.ServerServicesLoader)

local Globle = GlobleModuleLoader:FetchAllServices()
local Server = ServerModuleLoader:FetchAllServices()



