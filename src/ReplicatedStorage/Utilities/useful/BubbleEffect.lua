local TweenService = game:GetService("TweenService")
local debounce = false

function BubbleModule(CF, StartSize, StartTr, EndSize, Time) -- Origin CFrame, Mesh ID, Start Size, Start Transparency, End Size, Time
	local Part = script.Parent:Clone()
	Part.CFrame = CF
	Part.Anchored = true
	Part.CanCollide = false
	Part.Massless = true
	Part.Parent = workspace
	Part.Material = Enum.Material.Glass
	Part.Size = StartSize
	Part.Transparency = StartTr

	local RequiredHighlight = Instance.new("Highlight")
	RequiredHighlight.Enabled = false
	RequiredHighlight.Parent = Part

	game.Debris:addItem(Part, Time)

	local Info = TweenInfo.new(
		Time, -- Length
		Enum.EasingStyle.Sine, -- Easing Style
		Enum.EasingDirection.Out, -- Easing Direction
		0, -- Times repeated
		false, -- Reverse
		0 -- Delay
	)

	local Goals =
		{
			Transparency = 1;
			Size = EndSize;
		}

	local Tween = TweenService:Create(Part, Info, Goals)

	Tween:Play()
end


script.Parent.Touched:Connect(function(hit)
	if game.Players:FindFirstChild(hit.Parent.Name) and debounce == false then debounce = true
		--BubbleModule(script.Parent.CFrame, Vector3.new(0.05, 0.05, 0.05), 3, Vector3.new(15, 15, 15), 10) --OTHER VARIANT
		BubbleModule(script.Parent.CFrame, Vector3.new(3, 3, 3), 2, Vector3.new(8, 8, 8), .5)
		BubbleModule(script.Parent.CFrame, Vector3.new(2.6, 2.6, 2.6), 1, Vector3.new(7.2, 7.2, 7.2), .5)
		task.wait(5)	
		debounce = false
	end
end)