local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local tool = script.Parent
local equipped = false

local ACTION_NAME = "ToggleTool"

local function toggleTool()
	local character = player.Character
	if not character then return end

	if equipped then
		player.Character.Humanoid:UnequipTools()
		equipped = false
	else
		tool.Parent = character
		equipped = true
	end
end

-- Equip/Unequip Detection
tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
end)

-- Keyboard Key (1)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Two then
		toggleTool()
	end
end)

