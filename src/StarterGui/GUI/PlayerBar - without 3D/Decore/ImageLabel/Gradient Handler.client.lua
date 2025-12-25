local TweenService = game:GetService("TweenService")
local Gradient = script.Parent.UIGradient

-- Number of keypoints
local numPoints = 6
local pulseIndex = 2 -- the special keypoint
local pulseTime = 0.5
local pulseInterval = 3

-- Create initial keypoints
local keypoints = {}

-- First 6 keypoints evenly spaced (last one exactly 1.0)
for i = 0, numPoints-1 do
	local time = i / (numPoints-1) -- 0, 0.2, 0.4, ..., 1
	keypoints[i+1] = ColorSequenceKeypoint.new(time, Color3.fromRGB(255,255,255)) -- white
end

-- Special pulse keypoint (time = 0.1, color white)
table.insert(keypoints, pulseIndex, ColorSequenceKeypoint.new(0.1, Color3.fromRGB(255,255,255)))

Gradient.Color = ColorSequence.new(keypoints)

-- Function to pulse the special keypoint
local function Pulse()
	-- Change to red
	keypoints[pulseIndex] = ColorSequenceKeypoint.new(0.1, Color3.fromRGB(255,0,0))
	Gradient.Color = ColorSequence.new(keypoints)

	-- Tween time from 0.1 → 1
	local tweenValue = Instance.new("NumberValue")
	tweenValue.Value = 0.1
	local tweenInfo = TweenInfo.new(pulseTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(tweenValue, tweenInfo, {Value = 1})

	tweenValue:GetPropertyChangedSignal("Value"):Connect(function()
		keypoints[pulseIndex] = ColorSequenceKeypoint.new(tweenValue.Value, Color3.fromRGB(255,0,0))

		-- Keep last keypoint exactly at 1.0
		keypoints[#keypoints] = ColorSequenceKeypoint.new(1.0, keypoints[#keypoints].Value)

		-- Sort except the last keypoint
		local sorted = {}
		for i = 1, #keypoints-1 do
			table.insert(sorted, keypoints[i])
		end
		table.sort(sorted, function(a,b) return a.Time < b.Time end)
		sorted[#sorted+1] = keypoints[#keypoints] -- add last keypoint at 1
		Gradient.Color = ColorSequence.new(sorted)
	end)

	tween:Play()
	tween.Completed:Wait()

	-- Reset to white and original time
	keypoints[pulseIndex] = ColorSequenceKeypoint.new(0.1, Color3.fromRGB(255,255,255))

	-- Keep last keypoint exactly at 1.0
	keypoints[#keypoints] = ColorSequenceKeypoint.new(1.0, keypoints[#keypoints].Value)

	-- Sort except last keypoint
	local sorted = {}
	for i = 1, #keypoints-1 do
		table.insert(sorted, keypoints[i])
	end
	table.sort(sorted, function(a,b) return a.Time < b.Time end)
	sorted[#sorted+1] = keypoints[#keypoints]
	Gradient.Color = ColorSequence.new(sorted)
end

-- Loop the pulse every second
while true do
	task.wait(pulseInterval)
	Pulse()
end
