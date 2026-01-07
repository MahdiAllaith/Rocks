--strict
--@author: 
--@date: 
--[[@description:
	
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)



-----------------------------
-- DEPENDENCIES --
-----------------------------
local NotificationGUI = game.Players.LocalPlayer.PlayerGui:WaitForChild("NotificationGUI")
local NotifiaFrame = NotificationGUI:WaitForChild("Notifi_Frame")
local XP_GaneFrame = NotificationGUI:WaitForChild("ExperienceGaneFrame")
-----------------------------
-- TYPES --
-----------------------------


-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

local isRunning = false
local runId = 0
local activeTweens = {}

local TOTAL_DURATION = 1.4
local STEP = 10
local SLIDE_TIME = 0.25
local FADE_TIME = 0.3

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function getAllGuiObjects(root)
	local objects = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") then
			table.insert(objects, d)
		end
	end
	return objects
end

local function stopAllTweens()
	for _, tween in ipairs(activeTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(activeTweens)
end

local function setTransparency(objects, value)
	for _, obj in ipairs(objects) do
		obj.BackgroundTransparency = value

		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			obj.TextTransparency = value
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			obj.ImageTransparency = value
		end
	end
end

local function fadeOutFrame(frame, duration)
	-- Tween main frame background ONLY
	local frameTween = TweenService:Create(
		frame,
		TweenInfo.new(duration),
		{ BackgroundTransparency = 1 }
	)
	frameTween:Play()
	table.insert(activeTweens, frameTween)

	-- Tween child visuals ONLY
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") then
			local tween = TweenService:Create(
				obj,
				TweenInfo.new(duration),
				{ TextTransparency = 1 }
			)
			tween:Play()
			table.insert(activeTweens, tween)

		elseif obj:IsA("ImageLabel") then
			local tween = TweenService:Create(
				obj,
				TweenInfo.new(duration),
				{ ImageTransparency = 1 }
			)
			tween:Play()
			table.insert(activeTweens, tween)
		end
	end
end


local function resetFrame(frame)
	frame.Position = UDim2.fromScale(0.5, 1.5)
	frame.BackgroundTransparency = 0

	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") then
			obj.TextTransparency = 0
		elseif obj:IsA("ImageLabel") then
			obj.ImageTransparency = 0
		end
	end
end

local function getMainFrame(canvas: Instance): Frame?
	for _, child in ipairs(canvas:GetChildren()) do
		if child:IsA("Frame") then
			return child
		end
	end
	return nil
end

local function fadeVisuals(frame: Frame, duration: number)
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") then
			local t = TweenService:Create(
				obj,
				TweenInfo.new(duration),
				{ TextTransparency = 1 }
			)
			t:Play()
			table.insert(activeTweens, t)

		elseif obj:IsA("ImageLabel") then
			local t = TweenService:Create(
				obj,
				TweenInfo.new(duration),
				{ ImageTransparency = 1 }
			)
			t:Play()
			table.insert(activeTweens, t)
		end
	end
end

local function resetVisuals(frame: Frame)
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") then
			obj.TextTransparency = 0
		elseif obj:IsA("ImageLabel") then
			obj.ImageTransparency = 0
		end
	end
end

local function runCounter(
	frame: Frame,
	amountLabel: TextLabel,
	amount: number,
	soundId: string
)
	-- Slide in
	frame.Position = UDim2.fromScale(frame.Position.X.Scale, -1)
	resetVisuals(frame)

	local slideIn = TweenService:Create(
		frame,
		TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(frame.Position.X.Scale, 0) }
	)
	slideIn:Play()
	table.insert(activeTweens, slideIn)
	slideIn.Completed:Wait()

	-- Counting
	amountLabel.Text = "0"

	local steps = math.max(1, math.ceil(amount / STEP))
	local stepTime = math.clamp(
		(TOTAL_DURATION - SLIDE_TIME - FADE_TIME) / steps,
		0.02,
		0.08
	)

	local current = 0
	while current < amount do
		current = math.min(current + STEP, amount)
		amountLabel.Text = tostring(current)

		FunctionUtils.Game.playSound({
			SoundId = soundId,
			Volume = 0.6,
			Looped = false
		}, frame)

		task.wait(stepTime)
	end
end


-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function Module.ShowTextNotification(message)
	runId += 1
	local myRun = runId

	-- Interrupt current notification
	if isRunning then
		stopAllTweens()
		task.wait(0.5) -- Wait for fade
	end

	task.spawn(function()
		isRunning = true

		-- Find TextLabel
		local label
		for _, d in ipairs(NotifiaFrame:GetDescendants()) do
			if d:IsA("TextLabel") then
				label = d
				break
			end
		end
		if not label then
			isRunning = false
			return
		end

		resetFrame(NotifiaFrame)  -- This now properly resets everything
		label.Text = message

		-- Slide in
		local slideTween = TweenService:Create(
			NotifiaFrame,
			TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.5, 0.8) }
		)
		
		FunctionUtils.Game.playSound({
			SoundId = "rbxassetid://79442843148234",
			Volume = 0.5,
			RollOffMode = Enum.RollOffMode.InverseTapered,
			MinDistance = 10,
			MaxDistance = 10000,
			Looped = false
		}, workspace)
		
		task.wait(0.2)
		
		slideTween:Play()
		table.insert(activeTweens, slideTween)

		slideTween.Completed:Wait()
		if myRun ~= runId then return end

		task.wait(2)
		if myRun ~= runId then return end

		stopAllTweens()
		fadeOutFrame(NotifiaFrame, 0.5)
		task.wait(0.5)
		if myRun ~= runId then return end

		resetFrame(NotifiaFrame)
		isRunning = false
	end)
end


function Module.ShowGainIndicator(xpAmount: number, moneyAmount: number)
	runId += 1
	local myRun = runId

	stopAllTweens()

	task.spawn(function()
		-- Resolve XP
		local xpCanvas = XP_GaneFrame:WaitForChild("XP_Canvas")
		local xpFrame = xpCanvas:WaitForChild("XP_Frame")
		local xpLabel = xpFrame:WaitForChild("AmountText")

		-- Resolve Money
		local moneyCanvas = XP_GaneFrame:WaitForChild("MoneyRockCanvas")
		local moneyFrame = moneyCanvas:WaitForChild("MoneyRockFrame")
		local moneyLabel = moneyFrame:WaitForChild("MoneyAmountText")

		-- XP first
		runCounter(
			xpFrame,
			xpLabel,
			xpAmount,
			"rbxassetid://4567255304"
		)
		if myRun ~= runId then return end

		-- Money second
		runCounter(
			moneyFrame,
			moneyLabel,
			moneyAmount,
			"rbxassetid://107440155356185"
		)
		if myRun ~= runId then return end
		
		wait(1)
		-- Fade out visuals
		fadeVisuals(xpFrame, FADE_TIME)
		fadeVisuals(moneyFrame, FADE_TIME)
		task.wait(FADE_TIME)

		-- Reset for reuse
		xpFrame.Position = UDim2.fromScale(xpFrame.Position.X.Scale, -1)
		moneyFrame.Position = UDim2.fromScale(moneyFrame.Position.X.Scale, -1)

		resetVisuals(xpFrame)
		resetVisuals(moneyFrame)
	end)
end




-----------------------------
-- MAIN --
-----------------------------


return Module
