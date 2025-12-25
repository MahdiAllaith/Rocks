--!optimize 2
--!strict

local zoneTypes = script.ZoneTypes

local Types = require(script.Types)
local SimpleZone = require(script.SimpleZone)

export type LessSimpleZone<U, T...> = Types.LessSimpleZone<U, T...>
export type Zone = SimpleZone.Zone

export type QueryOptions = SimpleZone.QueryOptions
export type Box = SimpleZone.Box

return table.freeze {
	fromBoxes = require(zoneTypes.BoxesZone),
	fromParts = require(zoneTypes.PartsZone),
	fromBasePartsVertices = require(zoneTypes.BasePartsVertexZone),
	
	SimpleZone = SimpleZone,
	QueryOptions = SimpleZone.QueryOptions,
	Geometry = require(script.Geometry)
}