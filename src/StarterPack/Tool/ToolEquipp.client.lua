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
	if input.KeyCode == Enum.KeyCode.One then
		toggleTool()
	end
end)

-- Mobile Button Setup
local function onAction(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		toggleTool()
	end
end

ContextActionService:BindAction(
	ACTION_NAME,
	onAction,
	true,
	Enum.KeyCode.ButtonR1 -- This adds a button on mobile UI (right-hand side)
)

ContextActionService:SetPosition(ACTION_NAME, UDim2.new(1, -70, 1, -150)) -- Position like the jump button
ContextActionService:SetTitle(ACTION_NAME, "Equip")
