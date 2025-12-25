local ModifierHandler = {}

local function findRockHandler(Name:string, Type: string)
	local handlersFolder
	
	if Name ~= nil then
		if Type == "Fire" then
			handlersFolder = script.Fire
		elseif Type == "BlackMagic" then
			handlersFolder = script.BlackMagic
		elseif Type == "Ice" then
			handlersFolder = script.Ice
		elseif Type == "Luminite" then
			handlersFolder = script.Luminite
		elseif Type == "Aura" then
			handlersFolder = script.Aura
		end
		
		if not handlersFolder then
			warn("Error: Handlers folder for type '" .. tostring(Type) .. "' not found")
			return nil
		end
		
		local handler = handlersFolder:FindFirstChild(Name)
		if handler and handler:IsA("ModuleScript") then
			return require(handler)
		else
			warn("Error: Module was not found")
			return nil
		end
		
	end
end

function ModifierHandler.GetRock(mods:{Name:String, Type:String}?, Tool: Tool?, RockModel:Part, Type: string, ForPlayer: Player?)
	local DefaultHandler
	local DefaultBeen
	local DefaultModule	

	if Type == "Clients" then
		if mods == nil or mods.Name == nil then
			-- Will return simulate function but will not be ruuned
			-- because other players need sim function to be called on client event
			return require(script.DefaultRock)
		else
			return findRockHandler(mods.Name, mods.Type)
		end
	elseif Type == "Player" then
		-- Only runs for "Player" Type
		if mods == nil or mods.Name == nil or mods.Type == nil then
			require(script.DefaultRock)(Tool, RockModel, Type)
		else
			findRockHandler(mods.Name, mods.Type)(Tool, RockModel, Type)
		end
	end

	
end


return ModifierHandler
