--strict
--@author: IronBeliever
--@date: 8/30/25
--[[@description:
	A Service the handles all UI for the player based on client devices passed as prams.
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local ClientModuleUtils = require(ReplicatedStorage.Utilities.ClientModuleUtils)
local Input = ClientModuleUtils.Input
local ButtonClass = ClientModuleUtils.GuiButtonClass

local UIFunctions = require(script.UIFunctions)
local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)


-----------------------------
-- TypeS --
-----------------------------
export type InputClasses = {
	MouseKeyboard: {any}?,
	Gamepad: any?,
	Touch: any?,
}

export type GUISignales = {
	DisableTouchInputSignal : RBXScriptSignal,
	EnableTouchInputSignal : RBXScriptSignal,
	EnableConsoleInputSignal : RBXScriptSignal,
	EnableMouseKeyboardInputSignal: RBXScriptSignal,
	EndNPCIntractionSignal: RBXScriptSignal
}

-- CONSTANTS --
local LOCAL_PLAYER = game.Players.LocalPlayer
-----------------------------
-- VARIABLES --
-----------------------------
local Module = {}

local deviceResolutionType
local IsInventoryOpen
local IsRockModifersOpen = true -- false will mean its chracterkits open

local GUI = LOCAL_PLAYER.PlayerGui:WaitForChild("GUI")
local NPC_IntractionGUI = LOCAL_PLAYER.PlayerGui:WaitForChild("NPC_IntractionGUI")

local UpperMenuBar = GUI.Menu.Upper_Menu_Title
local Menu = GUI.Menu.Lower_Menu_Canvas.Lower_Menu
local Inventory = GUI.Menu.Lower_Menu_Canvas.All_Inventory

local CenterRockModifiers = Menu.CenterCanves.RocksModifiers
local CenterCharacterKits = Menu.CenterCanves.CharacterKits

local InventoryListCanves = Menu.Inventory_Quick_Accesses.InventoryList.CanvasGroup
local RockModifierScrollFrame = InventoryListCanves.RockModifiersSF
local CharacterKitsScrollFrame = InventoryListCanves.CharacterKitsSF

local MenuText = UpperMenuBar.Menu_Name.Menu_Text
local InventoryText = UpperMenuBar.Menu_Name.Inventory_Text
local CharacterText = UpperMenuBar.Menu_Name.Character_Kits_Text.Character
local KitsText = UpperMenuBar.Menu_Name.Character_Kits_Text.Kits
local ModifiersText = UpperMenuBar.Menu_Name.Rock_Modifiers_Text.Modifires
local RockText = UpperMenuBar.Menu_Name.Rock_Modifiers_Text.Rock

local CharacterKitsTextFrame = UpperMenuBar.Menu_Name.Character_Kits_Text
local RockModifiersTextFrame = UpperMenuBar.Menu_Name.Rock_Modifiers_Text

local SwipeToInvButton = GUI.Menu.SwipeToInvButton
local SwipeToMenuButton = GUI.Menu.SwipeToMenuButton

local RockRegImageButton = GUI.Menu.Lower_Menu_Canvas.Lower_Menu.CenterCanves.RocksModifiers.RockImageButton

local Checkers = {
	MenuOpen = false,
	SettingsOpne = false
}

local EndNPCIntraction: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function UpperMenuToInventory(InOrOut: boolean)
	local tInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local TextTInfo = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	UIFunctions.TextTransparency(
		MenuText,
		TextTInfo,
		InOrOut)

	UIFunctions.TextTransparency(
		CharacterText,
		TextTInfo,
		InOrOut)

	UIFunctions.TextTransparency(
		KitsText,
		TextTInfo,
		InOrOut)

	UIFunctions.TextTransparency(
		ModifiersText,
		TextTInfo,
		InOrOut)

	UIFunctions.TextTransparency(
		RockText,
		TextTInfo,
		InOrOut)

	UIFunctions.TextTransparency(
		InventoryText,
		tInfo,
		not InOrOut)
end

local function HandleUIBasedOnDevice(GUI : ScreenGui, DeviceType: string)
	local UserInputService = game:GetService("UserInputService")
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local width = viewportSize.X
	local height = viewportSize.Y

	local deviceResolutionType = "Desktop"
	local scaleFactor = 1.0

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		if width < 580 or height <= 320 then
			deviceResolutionType = "Small Phone"
			scaleFactor = 0.45 -- Reduce by 55%
			
		elseif (width >= 600 and width <= 780) or (height > 320 and height <= 420) then
			deviceResolutionType = "Phone"
			scaleFactor = 0.50 -- Reduce by 38%
			
		elseif (width > 780 and width <= 900) or (height > 320 and height <= 500) then
			deviceResolutionType = "Big Phone"
			scaleFactor = 0.65 -- Reduce by 35%
			
		elseif width >= 900 or height >= 500 then
			deviceResolutionType = "Tablet"
			scaleFactor = 0.8  -- Reduce by 20%
		end	
	else
		-- Desktop/PC - check resolution
		if width >= 3840 then
			-- 4K
			deviceResolutionType = "4K"
			scaleFactor = 1.2  -- Increase by 20%
		elseif width >= 2560 then
			-- 2K
			deviceResolutionType = "2K"
			scaleFactor = 1.1  -- Increase by 10%
		else
			-- Regular desktop
			deviceResolutionType = "Desktop"
			scaleFactor = 1.0  -- No change
		end
	end

	warn("Device Type: " .. deviceResolutionType)
	warn("Screen Resolution: " .. width .. "x" .. height)
	warn("Scale Factor: " .. scaleFactor .. " (" .. (scaleFactor * 100) .. "%)")

	-- Function to scale a single frame/element
	local function scaleFrame(frame)
		if frame:IsA("GuiObject") then
			-- Scale Size offset only
			local currentSize = frame.Size
			local newXOffset = math.round(currentSize.X.Offset * scaleFactor)
			local newYOffset = math.round(currentSize.Y.Offset * scaleFactor)
			frame.Size = UDim2.new(0, newXOffset, 0, newYOffset)
		end
	end

	-- Process all children of the GUI
	for _, child in pairs(GUI:GetChildren()) do
		if child:IsA("Frame") then
			scaleFrame(child)
		end

	end

	if DeviceType == "Mobile" then
		UIFunctions.SetMobileInputUI(LOCAL_PLAYER)
	end

	return true
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function Module:OpenMenu()
	Checkers.MenuOpen = true
	GUI.Menu.Visible = true
	UIFunctions.Hide3D_UI_Transparency(GUI, true)
end

function Module:CloseMenu()
	Checkers.MenuOpen = false
	GUI.Menu.Visible = false
	UIFunctions.Hide3D_UI_Transparency(GUI, false)
end

function Module:OpenSettings()
	Checkers.SettingsOpne = true
	GUI.Settings.Visible = true
end

function Module:CloseSettings()
	Checkers.SettingsOpne = false
	GUI.Settings.Visible = false
end

function Module:GoToInventory()
	IsInventoryOpen = true
	
	local tInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	UpperMenuToInventory(true)
	
	local A_HOME, A_OFF = 0, 1
	local B_HOME, B_OFF = 0, -1

	UIFunctions.TransformWithPosition(Menu, Inventory, {
		TweenInfo = tInfo,

		StartPosition1 = UDim2.new(0, 0, 0, 0),
		GoalPosition1 = UDim2.new(0, 0, -1, 0),

		StartPosition2 = UDim2.new(0, 0, 1, 0),
		GoalPosition2 = UDim2.new(0, 0, 0, 0),
	})
	

end

function Module:BackToMenu()
	IsInventoryOpen = false
	
	local tInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	UpperMenuToInventory(false)

	UIFunctions.TransformWithPosition(Menu, Inventory, {
		TweenInfo = tInfo,

		StartPosition1 = UDim2.new(0, 0, -1, 0),
		GoalPosition1 = UDim2.new(0, 0, 0, 0),

		StartPosition2 = UDim2.new(0, 0, 0, 0),
		GoalPosition2 = UDim2.new(0, 0, 1, 0),
	})
end

function Module:ChangedDevice(NewdeviceResolutionType:string)
	deviceResolutionType = NewdeviceResolutionType
end

function Module:IsInventoryOpen() : boolean
	return IsInventoryOpen
end

function Module:GetStarterConsoleMousePonter()
	return RockRegImageButton
end


-----------------------------
-- MAIN --
-----------------------------
local SelectedItem = nil
local Selected_Equiped_Modifier_Or_Kit_Item = nil

function Module:IsItemButtonSelected()
	return SelectedItem
end

function Module:IsEquipedItemButtonSelected()
	return Selected_Equiped_Modifier_Or_Kit_Item
end

function Module:setMobileButtons(SlideButtonSignal: RBXScriptSignal,
	SprintButtonStartSignal: RBXScriptSignal,
	SprintButtonEndSignal: RBXScriptSignal,
	EquipButtonSignal: RBXScriptSignal,
	AimButtonSignal: RBXScriptSignal,
	JumpButtonSignal: RBXScriptSignal)
	
	UIFunctions.SetMobileInputUI(LOCAL_PLAYER,SlideButtonSignal,
		SprintButtonStartSignal,
		SprintButtonEndSignal,
		EquipButtonSignal,
		AimButtonSignal,
		JumpButtonSignal)
end

local function UnSetIntractionUI()
	UIFunctions.Hide3D_UI_Transparency(GUI, false)

	if deviceResolutionType == "Touch" then
		UIFunctions.EnableMobileButtons(LOCAL_PLAYER)
	end

end

function Module:SetIntractionUI(Data, reEnablePromptSignal:RBXScriptSignal)
	-- first close menu if open or settings is open
	if Checkers.MenuOpen then
		self.CloseMenu()
	elseif Checkers.SettingsOpne then
		self.CloseSettings()
	end

	UIFunctions.Hide3D_UI_Transparency(GUI, true)

	if deviceResolutionType == "Touch" then
		UIFunctions.DisableMobileButtons(LOCAL_PLAYER)
	end
	
	UIFunctions.TweenNPCGUI(NPC_IntractionGUI, true)	
	UIFunctions.BindDialog(NPC_IntractionGUI, Data, nil)
	
	local signal
	signal = UIFunctions.DialogExitSignal:Connect(function()
		UIFunctions.TweenNPCGUI(NPC_IntractionGUI, false)	
		reEnablePromptSignal:Fire()
		EndNPCIntraction:Fire()
		UnSetIntractionUI()
		signal:Disconnect()
	end)
	
end




function Module:Init(Type :string) : GUISignales
	deviceResolutionType = Type
	
	-- signals for the manager to disable/enable mobile input for clear input for mobile
	local DisableTouchInput: ModuleUtils.Signal<any>
	local EnableTouchInput: ModuleUtils.Signal<any> 
	local EnableGamepadInput: ModuleUtils.Signal<any> 
	local EnableMouseKeyboardInput: ModuleUtils.Signal<any> 
	
	-- a signal that will be returned to manager for fireing OTS to disable camera touch input
	DisableTouchInput = ModuleUtils.Signal.new()
	EnableTouchInput = ModuleUtils.Signal.new()
	EnableGamepadInput = ModuleUtils.Signal.new()
	EnableMouseKeyboardInput = ModuleUtils.Signal.new()
	
	local SideButtonSignals = UIFunctions.InitializeSideButtons(GUI)
	local AllInventorySignals = UIFunctions.InitializeUnifiedInventorySystem(GUI)
	
	AllInventorySignals.DynamicInventoryItems.ItemSelectionSignal:Connect(function(ItemButtonName: string, SelectOrUn:boolean)
		if SelectOrUn then
			-- Selecting this item
			SelectedItem = ItemButtonName
			Selected_Equiped_Modifier_Or_Kit_Item = nil
		else
			-- Deselecting this item
			if SelectedItem == ItemButtonName then
				SelectedItem = nil
			end
		end
	end)
	
	AllInventorySignals.DynamicInventoryItems.ModifireOrKitSelectionSignal:Connect(function(ItemButtonName: string, SelectOrUn:boolean)
		if SelectOrUn then
			-- Selecting equiped item
			Selected_Equiped_Modifier_Or_Kit_Item = ItemButtonName
			SelectedItem = nil
		else
			-- Deselecting equiped item
			if Selected_Equiped_Modifier_Or_Kit_Item == ItemButtonName then
				Selected_Equiped_Modifier_Or_Kit_Item = nil
			end
		end
	end)
	
	SideButtonSignals.MenuButtonSignal:Connect(function()
		self:OpenMenu()
		UIFunctions.Hide3D_UI_Transparency(GUI, true)
		if deviceResolutionType == "Touch" then
			UIFunctions.DisableMobileButtons(LOCAL_PLAYER)
			DisableTouchInput:Fire()
		end
	end)

	SideButtonSignals.SettingsButtonSignal:Connect(function()
		self:OpenSettings()
	end)

	
	AllInventorySignals.MenuNavigation.KitsMenuSignal:Connect(function()
		if IsRockModifersOpen then
			IsRockModifersOpen = false
			-- done this way to make sure the tweens play all at the same tiem
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithImageTransparncy(CenterRockModifiers, CenterCharacterKits, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithImageTransparncy(RockModifierScrollFrame, CharacterKitsScrollFrame, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithTextTransparency(RockModifiersTextFrame, CharacterKitsTextFrame, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithTextTransparency(RockModifierScrollFrame, CharacterKitsScrollFrame, 0.2)
			end)
		end
	end)

	AllInventorySignals.MenuNavigation.ModifiersMenuSignal:Connect(function()
		if not IsRockModifersOpen then
			IsRockModifersOpen = true
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithImageTransparncy(CenterCharacterKits, CenterRockModifiers, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithImageTransparncy(CharacterKitsScrollFrame, RockModifierScrollFrame, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithTextTransparency(CharacterKitsTextFrame, RockModifiersTextFrame, 0.2)
			end)
			FunctionUtils.Game.spawn(function()
				UIFunctions.SwitchFramesWithTextTransparency(CharacterKitsScrollFrame, RockModifierScrollFrame, 0.2)
			end)
		end
	end)

	AllInventorySignals.MenuNavigation.AllInventoryMenuSignal:Connect(function()
		self.GoToInventory()
		SwipeToInvButton.Visible = false
		SwipeToMenuButton.Visible = true
	end)
	
	AllInventorySignals.MenuNavigation.MenuCloseSignal:Connect(function()
		self:CloseMenu()
		self:BackToMenu()
		
		UIFunctions.Hide3D_UI_Transparency(GUI, false)
		
		if deviceResolutionType == "Touch" then
			EnableTouchInput:Fire()
			UIFunctions.EnableMobileButtons(LOCAL_PLAYER)
		elseif deviceResolutionType == "Gamepad" then
			EnableGamepadInput:Fire()
		elseif deviceResolutionType == "MouseKeyboard" then
			EnableMouseKeyboardInput:Fire()
		end
	end)
	
	local UpperMenuHandler: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()

	UpperMenuHandler:Connect(function(ToWhatFrame:boolean) -- true for inventory, false for menu
		UpperMenuToInventory(ToWhatFrame)
	end)
	
	
	local SwipeButtonsSignals = UIFunctions.setupSwipeMenu(Menu, Inventory,SwipeToInvButton,SwipeToMenuButton,0.4, UpperMenuHandler)
	
	if HandleUIBasedOnDevice(GUI) then
		UIFunctions.Set3DUI(GUI)
	end
	
	return {
		DisableTouchInputSignal = DisableTouchInput,
		EnableTouchInputSignal = EnableTouchInput,
		EnableConsoleInputSignal = EnableGamepadInput,
		EnableMouseKeyboardInputSignal = EnableMouseKeyboardInput,
		EndNPCIntractionSignal = EndNPCIntraction
	}

end

return Module
