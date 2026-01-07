local TweenService = game:GetService("TweenService")
local parent = script.Parent

local smash1 = parent.Smash1
local smash2 = parent.Smash2
local smash3 = parent.Smash3

--local sound = parent["Rock Impact 1 (SFX)"]

function Smasher(tweenDuration, smashPart)
	local originalPosition = smashPart.Position
	local targetPosition = originalPosition + Vector3.new(0, 12, 0) -- Move up by 10 studs

	-- Tween to move the part up slowly
	local tweenUp = TweenService:Create(
		smashPart,
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Position = targetPosition}
	)

	-- Tween to move the part back down to its original position
	local tweenDown = TweenService:Create(
		smashPart,
		TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{Position = originalPosition}
	)

	-- Play the up tween
	tweenUp:Play()
	tweenUp.Completed:Wait() -- Wait for the up tween to finish

	-- Play the down tween
	tweenDown:Play()
	tweenDown.Completed:Wait() -- Wait for the down tween to finish

	-- Play the sound when the part returns to its original position
	--sound:Play()
end

-- Function to run all Smasher functions concurrently
local function runAllConcurrently()
	-- Use coroutines or spawn to run all Smasher functions at the same time
	coroutine.wrap(function()
		while true do
			Smasher(4, smash1) -- Move smash1 up and down over 4 seconds
		end
	end)()

	coroutine.wrap(function()
		while true do
			Smasher(3, smash2) -- Move smash2 up and down over 3 seconds
		end
	end)()

	coroutine.wrap(function()
		while true do
			Smasher(2, smash3) -- Move smash3 up and down over 2 seconds
		end
	end)()
end

-- Start running all Smasher functions concurrently
runAllConcurrently()