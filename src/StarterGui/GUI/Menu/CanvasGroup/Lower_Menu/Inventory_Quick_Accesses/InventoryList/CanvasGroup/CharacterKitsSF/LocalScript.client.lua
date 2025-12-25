local scrollingFrame = script.Parent
local layout = scrollingFrame:WaitForChild("UIListLayout")

local function updateCanvasSize()
	-- allow autosize children to settle first
	warn(layout.AbsoluteContentSize.Y)
	task.defer(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)
end

-- Run once
updateCanvasSize()

-- Listen for children changes + size changes
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
