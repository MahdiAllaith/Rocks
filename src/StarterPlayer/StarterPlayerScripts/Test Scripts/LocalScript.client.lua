-- COMPLETE GuiObjectClass FUNCTIONALITY GUIDE WITH EXAMPLES

local GuiObjectClass = require("path/to/GuiObjectClass")

-- ========================================
-- 1. CREATION AND BASIC SETUP
-- ========================================

-- Create a wrapped GUI object from any GuiObject
local myFrame = script.Parent.MyFrame -- Your GuiObject (Frame, ImageLabel, TextLabel, etc.)
local wrappedObject = GuiObjectClass.new(myFrame)

-- ========================================
-- 2. CHAINABLE METHODS (Return self for chaining)
-- ========================================

-- Notify - Add notification badges/counters to corners
wrappedObject:Notify() -- Default notification (upper right corner)

-- Notify with options
wrappedObject:Notify({
	Corner = "UpperLeft", -- "UpperLeft" | "UpperRight" | "BottomLeft" | "BottomRight"
	Color = Color3.fromRGB(255, 0, 0), -- Custom color (currently not implemented in the code)
	ClearSignal = mySignal -- Signal that clears this specific notification when fired
})

-- Multiple notifications stack up
wrappedObject:Notify():Notify():Notify() -- Shows count "3"

-- ClearNotices - Remove all notifications
wrappedObject:ClearNotices()

-- ToggleShimmer - Add animated shimmer effect
wrappedObject:ToggleShimmer(true) -- Enable with default white shimmer

-- ToggleShimmer with custom parameters
wrappedObject:ToggleShimmer(true, {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),   -- Red
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)), -- Yellow
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 0))    -- Green
	},
	Rotation = 45 -- Angle of shimmer effect
})

-- Disable shimmer
wrappedObject:ToggleShimmer(false)

-- ToggleToolTip - Add hover tooltips
-- Basic tooltip with built-in styles
wrappedObject:ToggleToolTip(true, {
	TitleText = "Settings Menu",
	DescriptionText = "Click to open the settings panel",
	Style = "INFO", -- "INFO" | "WARNING"
	MouseOffset = Vector2.new(15, -5), -- Offset from mouse cursor
	AnchorPoint = Vector2.new(0, 0) -- Tooltip anchor point
})

-- Tooltip locked to element (doesn't follow mouse)
wrappedObject:ToggleToolTip(true, {
	TitleText = "Important Button",
	DescriptionText = "This button performs a critical action",
	Style = "WARNING",
	LockedToElement = true, -- Tooltip appears above/below element
	AnchorPoint = Vector2.new(0.5, 0) -- Center horizontally
})

-- Custom styled tooltip using the default template
wrappedObject:ToggleToolTip(true, {
	TitleText = "Custom Tooltip",
	DescriptionText = "This has custom styling",
	CustomizeTooltip = function(frame)
		frame.TopFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		frame.BottomFrame.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		frame.TopFrame.Icon.Image = "rbxassetid://12345678" -- Custom icon
	end
})

-- Completely custom tooltip
local customTooltipTemplate = script.MyCustomTooltip -- Your custom GuiObject
wrappedObject:ToggleToolTip(true, {
	CustomToolTip = {
		ToolTip = customTooltipTemplate,
		OnCreate = function(tooltip)
			-- Customize the cloned tooltip when created
			tooltip.CustomLabel.Text = "Custom tooltip content"
			tooltip.Size = UDim2.fromOffset(200, 100)
		end,
		OnEnterHover = function(tooltip)
			-- Show tooltip with animation
			tooltip.Visible = true
			local tween = TweenService:Create(tooltip, TweenInfo.new(0.2), {
				BackgroundTransparency = 0
			})
			tween:Play()
		end,
		OnExitHover = function(tooltip)
			-- Hide tooltip with animation
			local tween = TweenService:Create(tooltip, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			})
			tween:Play()
			tween.Completed:Wait() -- Can yield to delay destruction
			tooltip.Visible = false
		end
	},
	MouseOffset = Vector2.new(10, -10)
})

-- Disable tooltip
wrappedObject:ToggleToolTip(false)

-- ========================================
-- 3. REGULAR METHODS (Return values, not chainable)
-- ========================================

-- GetObject - Get the original GuiObject
local originalObject = wrappedObject:GetObject()
originalObject.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

-- GetNotices - Get current notification count
print("Current notifications:", wrappedObject:GetNotices())

-- IsShimmerEnabled - Check if shimmer is enabled
print("Shimmer enabled:", wrappedObject:IsShimmerEnabled())

-- Destroy - Clean up the wrapped object
wrappedObject:Destroy() -- Removes from cache and cleans up all effects

-- ========================================
-- 4. STATIC CLASS METHODS
-- ========================================

-- GetObjectByObject - Find wrapped object by GuiObject
local foundObject = GuiObjectClass:GetObjectByObject(myFrame)
if foundObject then
	print("Found wrapped object!")
end

-- BelongsToClass - Check if object is a WrappedGuiObject
if GuiObjectClass:BelongsToClass(wrappedObject) then
	print("This is a wrapped GUI object!")
end

-- ========================================
-- 5. CHAINING EXAMPLES
-- ========================================

-- Complex chaining example
wrappedObject
	:Notify({Corner = "UpperRight"})
	:ToggleShimmer(true, {
		Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)), -- Gold shimmer
		Rotation = 30
	})
	:ToggleToolTip(true, {
		TitleText = "Enhanced Button",
		DescriptionText = "This button has notifications, shimmer, and tooltip effects",
		Style = "INFO",
		LockedToElement = true
	})

-- ========================================
-- 6. PRACTICAL USAGE EXAMPLES
-- ========================================

-- Example 1: Settings Button with Notification
local function createSettingsButton()
	local settingsButton = script.Parent.SettingsButton
	local wrappedSettings = GuiObjectClass.new(settingsButton)

	-- Add tooltip
	wrappedSettings:ToggleToolTip(true, {
		TitleText = "Settings",
		DescriptionText = "Configure your game preferences",
		Style = "INFO"
	})

	-- Add notification when there are pending updates
	local function checkForUpdates()
		-- Simulate checking for updates
		if hasUpdates() then
			wrappedSettings:Notify({
				Corner = "UpperRight",
				ClearSignal = updateAppliedSignal
			})
		end
	end

	return wrappedSettings
end

-- Example 2: Shop Item with Shimmer Effect
local function createShopItem()
	local shopFrame = script.Parent.ShopItem
	local wrappedShop = GuiObjectClass.new(shopFrame)

	-- Add golden shimmer for premium items
	if isPremiumItem then
		wrappedShop:ToggleShimmer(true, {
			Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
			},
			Rotation = 45
		})
	end

	-- Add detailed tooltip
	wrappedShop:ToggleToolTip(true, {
		TitleText = itemName,
		DescriptionText = itemDescription,
		CustomizeTooltip = function(frame)
			-- Custom styling based on item rarity
			if itemRarity == "Legendary" then
				frame.TopFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				frame.BottomFrame.BackgroundColor3 = Color3.fromRGB(200, 170, 0)
			end
		end
	})

	return wrappedShop
end

-- Example 3: Notification System
local function createNotificationSystem()
	local inboxButton = script.Parent.InboxButton
	local wrappedInbox = GuiObjectClass.new(inboxButton)

	-- Function to add new message notification
	local function addMessageNotification()
		local clearSignal = Instance.new("BindableEvent")

		wrappedInbox:Notify({
			Corner = "UpperRight",
			ClearSignal = clearSignal.Event
		})

		-- Clear notification when message is read
		messageReadEvent:Connect(function(messageId)
			if messageId == currentMessageId then
				clearSignal:Fire()
			end
		end)
	end

	-- Function to clear all notifications
	local function clearAllNotifications()
		wrappedInbox:ClearNotices()
	end

	return wrappedInbox, addMessageNotification, clearAllNotifications
end

-- Example 4: Interactive Tutorial Elements
local function createTutorialElement()
	local tutorialFrame = script.Parent.TutorialElement
	local wrappedTutorial = GuiObjectClass.new(tutorialFrame)

	-- Add pulsing shimmer to draw attention
	wrappedTutorial:ToggleShimmer(true, {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
		},
		Rotation = 0
	})

	-- Add helpful tooltip
	wrappedTutorial:ToggleToolTip(true, {
		TitleText = "Tutorial Step 1",
		DescriptionText = "Click here to continue with the tutorial",
		Style = "INFO",
		LockedToElement = true,
		CustomizeTooltip = function(frame)
			frame.TopFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
			frame.BottomFrame.BackgroundColor3 = Color3.fromRGB(70, 170, 225)
		end
	})

	return wrappedTutorial
end

-- Example 5: Status Indicator with Multiple Notifications
local function createStatusIndicator()
	local statusFrame = script.Parent.StatusIndicator
	local wrappedStatus = GuiObjectClass.new(statusFrame)

	-- Different types of status notifications
	local function addErrorNotification()
		wrappedStatus:Notify({Corner = "UpperLeft"}) -- Error count
	end

	local function addWarningNotification()
		wrappedStatus:Notify({Corner = "UpperRight"}) -- Warning count
	end

	local function addInfoNotification()
		wrappedStatus:Notify({Corner = "BottomRight"}) -- Info count
	end

	-- Tooltip showing current status
	wrappedStatus:ToggleToolTip(true, {
		TitleText = "System Status",
		DescriptionText = "Hover to see current system notifications",
		CustomizeTooltip = function(frame)
			local errors = wrappedStatus:GetNotices()
			if errors > 0 then
				frame.TopFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
				frame.BottomFrame.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
			end
		end
	})

	return wrappedStatus, addErrorNotification, addWarningNotification, addInfoNotification
end

-- ========================================
-- 7. TYPE INFORMATION
-- ========================================

--[[
Available Types:

ToolTipStyles = "INFO" | "WARNING"

ToolTipParams = {
    CustomToolTip: {
        ToolTip: GuiObject,
        OnCreate: (tooltip: GuiObject) -> (),
        OnEnterHover: (tooltip: GuiObject) -> (),
        OnExitHover: (tooltip: GuiObject) -> () -- Can yield
    }?,
    MouseOffset: Vector2?,
    LockedToElement: boolean?,
    AnchorPoint: Vector2?,
    DescriptionText: string?,
    TitleText: string?,
    CustomizeTooltip: ((frame: ExampleToolTip) -> ())?,
    Style: ToolTipStyles?
}

NotificationOptions = {
    Corner: "UpperLeft" | "UpperRight" | "BottomLeft" | "BottomRight"?,
    Color: Color3?, -- Currently not implemented
    ClearSignal: GenericSignal? -- Signal to clear this notification
}

ShimmerParams = {
    Color: ColorSequence?,
    Rotation: number?
}
--]]