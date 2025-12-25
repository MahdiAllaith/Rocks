
local TweenService = game:GetService("TweenService")

local TweenHandler = {}
TweenHandler.ActiveTweens = {}

function TweenHandler.Create(Object: Instance, Info: TweenInfo, Properties: {[string]: a?}, CompleteCallback: () -> ()): Tween
	if TweenHandler.ActiveTweens[Object] then
		TweenHandler.ActiveTweens[Object].Tween:Cancel()

		for Name, Value in TweenHandler.ActiveTweens[Object].Goal do
			Object[Name] = Value
		end

		table.remove(TweenHandler.ActiveTweens, table.find(TweenHandler.ActiveTweens, Object))
	end

	print(Info)

	local Tween = TweenService:Create(Object, Info, Properties)
	TweenHandler.ActiveTweens[Object] = {Goal = Properties, Tween = Tween}

	Tween.Completed:Once(function()
		if CompleteCallback then
			CompleteCallback()
		end

		table.remove(TweenHandler.ActiveTweens, table.find(TweenHandler.ActiveTweens, Object))
		Tween:Destroy()
	end)

	return Tween
end

return TweenHandler