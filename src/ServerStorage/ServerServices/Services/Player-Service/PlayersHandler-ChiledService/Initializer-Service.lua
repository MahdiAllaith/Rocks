local FUtilies = require(game.ReplicatedStorage.Utilities.FunctionUtils)

local ClassesTypes = require(script.Parent["ClassesType-Enum"])

local Initializer = {}

local ClassesFolder = script.Parent:WaitForChild("Classes - Credentials")

function Initializer.InitializePlayer(player: Player, DataTable) : ClassesTypes.ClassMap
	local Classes = {} :: ClassesTypes.ClassMap
	
	for _, classMoudel in ipairs(ClassesFolder:GetChildren()) do
		local class = require(classMoudel)
		
		if (FUtilies.t["function"](class.Init)) then
			local object = class.Init(player, DataTable)
			-- a quick fix for type enum to access by name because classes name have - in them so insted of renaming all faster
			local rawName = classMoudel.Name
			local className = rawName:gsub("-", "") -- Remove dashes
			Classes[className] = object
			
			--Classes[classMoudel.Name] = object
		else
			warn("Init Not a Fucntion")
		end
	end
	
	return Classes
end

return Initializer