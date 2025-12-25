local actor = script.Parent
local resultEvent = actor.Result

local PartQueryJumpTable: {[string]: (_: WorldRoot, _: BasePart, _: OverlapParams?) -> {BasePart}} = {
	Block = function(worldModel, part, params)
		return worldModel:GetPartBoundsInBox(part.CFrame, part.Size, params)
	end,
	Ball = function(worldModel, part, params)
		return worldModel:GetPartBoundsInRadius(part.Position, part.ExtentsSize.Y, params)
	end,
}

actor:BindToMessageParallel("Query", function(worldModel, params: OverlapParams, part: BasePart)
	local query
	if part:IsA("Part") then
		local fn = PartQueryJumpTable[part.Shape.Name]
		query = fn and fn(worldModel, part, params) or worldModel:GetPartsInPart(part, params)
	else
		query = worldModel:GetPartsInPart(part, params)
	end
	task.defer(resultEvent.Fire, resultEvent, query)
end)