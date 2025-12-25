local main = script.Parent

local Zone = require(main.SimpleZone)

type LessSimpleZoneInternal<U, T...> = {
	UpdateVolume: typeof(
		--[[
			Updates the volume of this <code>Zone</code>.
		]]
		function(self: LessSimpleZone<U, T...>, ...: T...)
		end
	),
	GetRandomPoint: typeof(
		--[[
			Gets a random point within this <code>Zone</code>.
		]]
		function(self: LessSimpleZone<U, T...>): vector
		end
	),
	IsPointWithinZone: typeof(
		--[[
			Checks if <code>point</code> is located within this <code>Zone</code>.
		]]
		function(self: LessSimpleZone<U, T...>, point: vector): (boolean, U?)
		end
	),
	IsBoxWithinZone: typeof(
		--[[
			Checks if <code>box</code> is within this <code>Zone</code>.
		]]
		function(self: LessSimpleZone<U, T...>, cframe: CFrame, size: vector): (boolean, U?)
		end
	),
	CombineWith: typeof(
		--[[
			Combines this <code>Zone</code>s volume with <code>other</code>.
		]]
		function(self: LessSimpleZone<U, T...>, other: LessSimpleZone<U, T...>)
		end
	),
	
	ZoneType: string,
	Volume: any
}

export type LessSimpleZone<U, T...> = Zone.Zone & LessSimpleZoneInternal<U, T...>

return nil