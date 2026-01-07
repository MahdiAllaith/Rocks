-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
-----------------------------
-- DEPENDENCIES --
-----------------------------
local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)
local GuiObjectClass = require(ReplicatedStorage.Utilities.ClientModuleUtils._GuiObjectClass)
local ButtonClass = require(ReplicatedStorage.Utilities.ClientModuleUtils).GuiButtonClass
local Screen3DService = ModuleUtils.Screen3D
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)


-----------------------------
-- TYPES --
-----------------------------
export type TransformParams = {
	TweenInfo: TweenInfo,
	
	StartPosition1: UDim2?,
	GoalPosition1: UDim2?,
	StartPosition2: UDim2?,
	GoalPosition2: UDim2?,
}


export type SideButtonsSignals = {
	SettingsButtonSignal: RBXScriptSignal,
	MenuButtonSignal: RBXScriptSignal,
}

export type UnifiedInventorySystemSignals = {
	MenuNavigation: {
		KitsMenuSignal: RBXScriptSignal,
		ModifiersMenuSignal: RBXScriptSignal,
		AllInventoryMenuSignal: RBXScriptSignal,
		MenuCloseSignal: RBXScriptSignal,
	},

	EquippedItems: {
		AbilitiesKitSlotSignal: RBXScriptSignal,
		HealthKitSlotSignal: RBXScriptSignal,
		StaminaKitSlotSignal: RBXScriptSignal,
	},

	EquippedRockModifiers: {
		RockModelSlotSignal: RBXScriptSignal,
		RockHandlerSlotSignal: RBXScriptSignal,
		RockBufferSlotSignal: RBXScriptSignal,
		RockTypeSlotSignal: RBXScriptSignal,
		RockRegularSlotSignal: RBXScriptSignal,
	},

	DynamicInventoryItems: {
		ItemButtons: {
			[string]: {
				PrimaryButtonSignal: RBXScriptSignal,
				ReplicaButtonSignal: RBXScriptSignal,
			}
		},
		ItemSelectionSignal: RBXScriptSignal,
		ModifireOrKitSelectionSignal: RBXScriptSignal
	}
}

export type SwipeButtonsSignalConnections = {
	forwardInputBegan: RBXScriptConnection,
	forwardInputEnded: RBXScriptConnection,
	backInputBegan: RBXScriptConnection,
	backInputEnded: RBXScriptConnection,
	inputChanged: RBXScriptConnection,
}

export type InventoryButtonsSignal = {
	[string]: {
		MainButtonSignal: any,
		ReplicaButtonSignal: any,
	},
	ItemSelectedSignal:RBXScriptSignal
}

export type InventoryCountSignals = {
	RockHandler: any,
	RockModel: any,
	RockBuffer: any,
	HealthKit: any,
	StaminaKit: any,
	AbilitiesKit: any,
}


export type GuiInitializer = {
	Set3DUI: (gui: ScreenGui) -> (),
	InitializeSideButtons: (gui: ScreenGui) -> SideButtonsSignals,
	InitializeUnifiedInventorySystem: (GUI: ScreenGui) -> UnifiedInventorySystemSignals,
	TransformWithPosition: (GuiObject1: GuiObject, GuiObject2: GuiObject, params: TransformParams) -> (),
	TextTransparency: (textLabel: TextLabel, tweenInfo: TweenInfo?, reverse: boolean) -> (),
	setupSwipeMenu: (Menu:Frame, Inventory:Frame, SwipeToInvButton:GuiButton, SwipeToMenuButton:GuiButton, tweenTime:number, handleUpperMenu:RBXScriptSignal) -> SwipeButtonsSignalConnections,
	SwitchFramesWithImageTransparncy: (RockModifier: Frame, CharacterKits: Frame, duration: number?) -> (),
	SwitchFramesWithTextTransparency: (Frame1: Frame, Frame2: Frame, duration: number?) -> (),
	Hide3D_UI_Transparency: (GUI: ScreenGui, fadeOut: boolean, duration: number?) -> (),
	SetMobileInputUI: (Player: Player,
		SlideButtonSignal: RBXScriptSignal,
		SprintButtonStartSignal: RBXScriptSignal,
		SprintButtonEndSignal: RBXScriptSignal,
		EquipButtonSignal: RBXScriptSignal,
		AimButtonSignal: RBXScriptSignal,
		JumpButtonSignal: RBXScriptSignal) -> (),
	DisableMobileButtons: (player: Player) -> (),
	EnableMobileButtons: (player: Player) -> (),
	TweenNPCGUI: (gui:ScreenGui, isVisible:boolean) -> RBXScriptSignal,
	DialogExitSignal: RBXScriptSignal,
	BindDialog: (gui: ScreenGui, dialog: any, currentNodeName:string) -> (),
}

-----------------------------
-- MODULE --
-----------------------------
local GuiInitializer = {} :: GuiInitializer

GuiInitializer.DialogExitSignal = GuiInitializer.DialogExitSignal or ModuleUtils.Signal.new()

local LOCAL_PLAYER = game.Players.LocalPlayer

-----------------------------
-- Private FUNCTIONS --
-----------------------------

-- Convert GUI size into 3D studs
local function preserveSize(component3D, guiObject)
	local guiSize = guiObject.AbsoluteSize
	local scale = 0.001
	component3D.Size = Vector3.new(guiSize.X * scale, guiSize.Y * scale, 0.001)
end

local function calculateDepthOffset(zIndex, maxZIndex)
	local BASE_DEPTH_SPACING = 0.001
	local normalized = (zIndex - 1) / (maxZIndex - 1)
	return -normalized * BASE_DEPTH_SPACING
end

local function findMaxZIndex(guiObject)
	local maxZIndex = guiObject.ZIndex or 1
	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			maxZIndex = math.max(maxZIndex, findMaxZIndex(child))
		end
	end
	return maxZIndex
end

-- Recursive layering, skipping "StopSub3D" tagged objects
local function applyStrictZLayering(guiObject, parentOffset, maxZIndex, parentIsCanvas, GUI3D)
	-- 🚫 Skip this branch if it has the "StopSub3D" tag
	if CollectionService:HasTag(guiObject, "StopSub3D") then
		return
	end

	local children = {}

	-- Special case: skip recursion on "Buttons"
	if guiObject.Name == "Buttons" and guiObject:IsA("Frame") then
		local component3D = GUI3D:GetComponent3D(guiObject)
		if component3D then
			component3D:Enable()
			preserveSize(component3D, guiObject)
			local depthOffset = calculateDepthOffset(guiObject.ZIndex or 1, maxZIndex)
			component3D.offset = parentOffset * CFrame.new(0, 0, depthOffset)
		end
		return
	end

	for _, child in ipairs(guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	table.sort(children, function(a, b)
		return (a.ZIndex or 1) < (b.ZIndex or 1)
	end)

	local component3D = nil
	if not parentIsCanvas then
		component3D = GUI3D:GetComponent3D(guiObject)
		if component3D then
			component3D:Enable()
			preserveSize(component3D, guiObject)
			local depthOffset = calculateDepthOffset(guiObject.ZIndex or 1, maxZIndex)
			component3D.offset = parentOffset * CFrame.new(0, 0, depthOffset)
		end
	end

	for i, child in ipairs(children) do
		local childOffset = (component3D and component3D.offset or parentOffset)
			* CFrame.new(0, 0, -i * 0.001)

		-- Recursive call (skips automatically if tagged StopSub3D)
		applyStrictZLayering(child, childOffset, maxZIndex, guiObject:IsA("CanvasGroup"), GUI3D)
	end
end

-----------------------------
-- Public functions --
-----------------------------
function GuiInitializer.Set3DUI(GUI: ScreenGui)
	local Frame1 = GUI.PlayerBar
	local Frame2 = GUI.SideMenu

	local GUI3D = Screen3DService.new(GUI, 5)

	local Frame3D_1 = GUI3D:GetComponent3D(Frame1)
	local Frame3D_2 = GUI3D:GetComponent3D(Frame2)
	Frame3D_1:Enable()
	Frame3D_2:Enable()
	preserveSize(Frame3D_1, Frame1)
	preserveSize(Frame3D_2, Frame2)

	local maxZIndex1 = findMaxZIndex(Frame1)
	local maxZIndex2 = findMaxZIndex(Frame2)

	applyStrictZLayering(Frame1, CFrame.new(0, 0, -0.001), maxZIndex1, false, GUI3D)
	applyStrictZLayering(Frame2, CFrame.new(0, 0,  0.001) * CFrame.Angles(0, math.rad(-2), 0), maxZIndex2, false, GUI3D)

	print("3D UI applied! (StopSub3D respected)")
end

function GuiInitializer.InitializeSideButtons(GUI: ScreenGui): SideButtonsSignals
	local MenuButton = GUI.SideMenu.Frame2.ButtonsImage.MenuButton.MenuImageButton
	local SettingsButton = GUI.SideMenu.Frame2.ButtonsImage.SettingButton.SettingsImageButton

	local SettingButtonClass = ButtonClass.new(SettingsButton, {
		AutoDeselect = true,
		OneClick = false,
		ClickSound = nil,
		HoverSound = nil})

	local MenuButtonClass = ButtonClass.new(MenuButton, {
		AutoDeselect = true,
		OneClick = false,
		ClickSound = nil,
		HoverSound = nil}) 

	SettingButtonClass:ModifyTheme("Hover", {
		Properties = {
			Enter = { ImageColor3 = Color3.fromRGB(18, 149, 236) },
			Exit  = { ImageColor3 = Color3.fromRGB(255, 255, 255) },
		},
		EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
		ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
	})

	MenuButtonClass:ModifyTheme("Hover", {
		Properties = {
			Enter = { ImageColor3 = Color3.fromRGB(204, 0, 0) },
			Exit  = { ImageColor3 = Color3.fromRGB(255, 255, 255) },
		},
		EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
		ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
	})

	return {
		SettingsButtonSignal = SettingButtonClass.Signals.Activated,
		MenuButtonSignal     = MenuButtonClass.Signals.Activated,
	}
end


-- Static Equipment Signals (for equipped items)
local EquippedRockHandlerSignal: ModuleUtils.Signal<any>  = ModuleUtils.Signal.new()
local EquippedRockModelSignal: ModuleUtils.Signal<any>    = ModuleUtils.Signal.new()
local EquippedRockBufferSignal: ModuleUtils.Signal<any>   = ModuleUtils.Signal.new()
local EquippedRockTypeSignal: ModuleUtils.Signal<any>     = ModuleUtils.Signal.new()

local EquippedHealthKitSignal: ModuleUtils.Signal<any>    = ModuleUtils.Signal.new()
local EquippedStaminaKitSignal: ModuleUtils.Signal<any>   = ModuleUtils.Signal.new()
local EquippedAbilitiesKitSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()

-- Dynamic Inventory Signals (for inventory items)
local InventoryItemDataSignals = {}
local InventoryCategoryCountSignals = {}

local NewInventoryItemSignal: ModuleUtils.Signal<any>       = ModuleUtils.Signal.new()
local ItemSelectionSignal: ModuleUtils.Signal<any>          = ModuleUtils.Signal.new()
local ModifireOrKitSelectionSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()

-- Category count signals
local RockHandlerInventoryCountSignal: ModuleUtils.Signal<any>  = ModuleUtils.Signal.new()
local RockModelInventoryCountSignal: ModuleUtils.Signal<any>    = ModuleUtils.Signal.new()
local RockBufferInventoryCountSignal: ModuleUtils.Signal<any>   = ModuleUtils.Signal.new()
local HealthKitInventoryCountSignal: ModuleUtils.Signal<any>    = ModuleUtils.Signal.new()
local StaminaKitInventoryCountSignal: ModuleUtils.Signal<any>   = ModuleUtils.Signal.new()
local AbilitiesKitInventoryCountSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()

-- Store count signals for export
InventoryCategoryCountSignals.RockHandler  = RockHandlerInventoryCountSignal
InventoryCategoryCountSignals.RockModel    = RockModelInventoryCountSignal
InventoryCategoryCountSignals.RockBuffer   = RockBufferInventoryCountSignal
InventoryCategoryCountSignals.HealthKit    = HealthKitInventoryCountSignal
InventoryCategoryCountSignals.StaminaKit   = StaminaKitInventoryCountSignal
InventoryCategoryCountSignals.AbilitiesKit = AbilitiesKitInventoryCountSignal

-- Track created inventory buttons and their cleanup functions
local DynamicInventoryButtons = {}

local function setupEquippedItemsObserver()
	if not game.Players.LocalPlayer.Character then
		game.Players.LocalPlayer.CharacterAdded:Wait()
	end

	local PlayerBackpack = game.Players.LocalPlayer:WaitForChild("Backpack")

	-- Rock modifiers folder structure
	local EquippedRockModifiersFolder = PlayerBackpack:WaitForChild("ActiveRockModifiers")
	local HandlerEquipmentData = EquippedRockModifiersFolder:WaitForChild("Handler")
	local ModelEquipmentData   = EquippedRockModifiersFolder:WaitForChild("Model")
	local BufferEquipmentData  = EquippedRockModifiersFolder:WaitForChild("Buffer")

	-- Character kits folder structure
	local EquippedCharacterKitsFolder = PlayerBackpack:WaitForChild("ActiveCharacterKits")
	local HealthKitEquipmentData   = EquippedCharacterKitsFolder:WaitForChild("Health")
	local StaminaKitEquipmentData  = EquippedCharacterKitsFolder:WaitForChild("Stamina")
	local AbilitiesKitEquipmentData = EquippedCharacterKitsFolder:WaitForChild("Abilities")

	local function observeEquipmentAttribute(dataHolder, signal)
		return FunctionUtils.Observers.observeAttribute(dataHolder, "Name", function(value)
			if value == nil or value == "" then
				signal:Fire(nil) -- nil to disable tooltip
			else
				signal:Fire(dataHolder)
			end
		end)
	end

	observeEquipmentAttribute(HandlerEquipmentData, EquippedRockHandlerSignal)
	observeEquipmentAttribute(ModelEquipmentData, EquippedRockModelSignal)
	observeEquipmentAttribute(BufferEquipmentData, EquippedRockBufferSignal)
	observeEquipmentAttribute(HealthKitEquipmentData, EquippedHealthKitSignal)
	observeEquipmentAttribute(StaminaKitEquipmentData, EquippedStaminaKitSignal)
	observeEquipmentAttribute(AbilitiesKitEquipmentData, EquippedAbilitiesKitSignal)
end

local function setupInventoryItemsObserver()
	if not game.Players.LocalPlayer.Character then
		game.Players.LocalPlayer.CharacterAdded:Wait()
	end

	local PlayerBackpack = game.Players.LocalPlayer:WaitForChild("Backpack")
	local PlayerInventoryFolder = PlayerBackpack:WaitForChild("Inventory")

	-- Observer for category count attributes
	local function observeCategoryCountAttribute(attributeName, signal)
		return FunctionUtils.Observers.observeAttribute(PlayerInventoryFolder, attributeName, function(value)
			signal:Fire(value or 0)
		end)
	end

	-- Set up category count observers
	observeCategoryCountAttribute("RockHandlerModifierCount", RockHandlerInventoryCountSignal)
	observeCategoryCountAttribute("RockModelModifierCount", RockModelInventoryCountSignal)
	observeCategoryCountAttribute("RockBufferModifierCount", RockBufferInventoryCountSignal)
	observeCategoryCountAttribute("CharacterHealthKitCount", HealthKitInventoryCountSignal)
	observeCategoryCountAttribute("CharacterStaminaKitCount", StaminaKitInventoryCountSignal)
	observeCategoryCountAttribute("CharacterAbilitiesKitCount", AbilitiesKitInventoryCountSignal)

	-- Function to create observers for individual inventory item folders
	local function createInventoryItemObservers(itemFolder)
		local itemFolderName = itemFolder.Name

		-- Create signal for this inventory item
		if not InventoryItemDataSignals[itemFolderName] then
			InventoryItemDataSignals[itemFolderName] = ModuleUtils.Signal.new()
		end

		local itemSignal = InventoryItemDataSignals[itemFolderName]

		-- Observer for Name attribute
		local nameAttributeObserver = FunctionUtils.Observers.observeAttribute(itemFolder, "Name", function(value)
			if value == nil or value == "" then
				itemSignal:Fire(nil, itemFolderName) -- Pass folder name for identification
			else
				itemSignal:Fire(itemFolder, itemFolderName)
			end
		end)

		-- Observer for Amount attribute
		local amountAttributeObserver = FunctionUtils.Observers.observeAttribute(itemFolder, "Amount", function(value)
			if value == nil or value == 0 then
				itemSignal:Fire(nil, itemFolderName)
			else
				itemSignal:Fire(itemFolder, itemFolderName)
			end
		end)

		return nameAttributeObserver, amountAttributeObserver
	end

	-- Function to handle existing inventory folders
	local function processExistingInventoryFolders()
		for _, child in ipairs(PlayerInventoryFolder:GetChildren()) do
			if child:IsA("Folder") then
				createInventoryItemObservers(child)
			end
		end
	end

	-- Process existing folders
	processExistingInventoryFolders()

	-- Listen for new inventory folders being added
	PlayerInventoryFolder.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			task.wait() -- Wait for attributes to be set
			createInventoryItemObservers(child)

			-- Fire signal for GUI side
			NewInventoryItemSignal:Fire(child)
		end
	end)

	-- Listen for inventory folders being removed
	PlayerInventoryFolder.ChildRemoved:Connect(function(child)
		if child:IsA("Folder") then
			local itemFolderName = child.Name
			if InventoryItemDataSignals[itemFolderName] then
				InventoryItemDataSignals[itemFolderName]:Fire(nil, itemFolderName) -- Trigger cleanup
			end
		end
	end)
end

function GuiInitializer.InitializeUnifiedInventorySystem(GUI: ScreenGui) : UnifiedInventorySystemSignals
	setupEquippedItemsObserver()
	setupInventoryItemsObserver()

	local MenuContainer = GUI.Menu
	local LowerMenuCanvas = MenuContainer.Lower_Menu_Canvas
	local LowerMenuFrame = LowerMenuCanvas.Lower_Menu
	local AllInventoryPanel = LowerMenuCanvas.All_Inventory.InventoryAll

	local TextFormatter = FunctionUtils.Format

	-- Static UI Elements (Main menu buttons)
	local MenuCloseButton = MenuContainer.CloseButton
	local QuickAccessPanel = LowerMenuFrame.Inventory_Quick_Accesses
	local KitsMenuButton = QuickAccessPanel.Kits_Button.KitsButton
	local ModifiersMenuButton = QuickAccessPanel.Rock_Modifiers_Button.ModifiersButton
	local AllInventoryMenuButton = QuickAccessPanel.All_Inventory_Button.AllInventoryButton

	-- Static Equipment UI Elements (Equipment slots)
	local CenterContentCanvas = LowerMenuFrame.CenterCanves
	local EquippedCharacterKitsPanel = CenterContentCanvas.CharacterKits
	local EquippedRockModifiersPanel = CenterContentCanvas.RocksModifiers

	local EquippedAbilitiesKitSlot = EquippedCharacterKitsPanel.AbilitiesKit
	local EquippedHealthKitSlot = EquippedCharacterKitsPanel.HealthKit
	local EquippedStaminaKitSlot = EquippedCharacterKitsPanel.StaminaKit

	local EquippedRockModelSlot = EquippedRockModifiersPanel.RockModelButton
	local EquippedRockHandlerSlot = EquippedRockModifiersPanel.RockHandlerButton
	local EquippedRockBufferSlot = EquippedRockModifiersPanel.RockBufferButton
	local EquippedRockTypeSlot = EquippedRockModifiersPanel.RockTypeImageButton
	local EquippedRockRegularSlot = EquippedRockModifiersPanel.RockImageButton

	-- Dynamic Inventory UI Elements (Inventory lists)
	local InventoryListCanvas = QuickAccessPanel.InventoryList.CanvasGroup
	local RockModifiersInventoryScrollFrame = InventoryListCanvas.RockModifiersSF
	local CharacterKitsInventoryScrollFrame = InventoryListCanvas.CharacterKitsSF

	local RockModelsInventoryContainer = RockModifiersInventoryScrollFrame.RockModelsList.ItemsHolderFrame
	local RockHandlersInventoryContainer = RockModifiersInventoryScrollFrame.RockHandlersList.ItemsHolderFrame
	local RockBuffersInventoryContainer = RockModifiersInventoryScrollFrame.RockBuffersList.ItemsHolderFrame

	local RockModelsCountDisplay = RockModifiersInventoryScrollFrame.RockModelsList.TopFrame.ItemsAmount
	local RockHandlersCountDisplay = RockModifiersInventoryScrollFrame.RockHandlersList.TopFrame.ItemsAmount
	local RockBuffersCountDisplay = RockModifiersInventoryScrollFrame.RockBuffersList.TopFrame.ItemsAmount

	local HealthKitsInventoryContainer = CharacterKitsInventoryScrollFrame.HealthKitsList.ItemsHolderFrame
	local StaminaKitsInventoryContainer = CharacterKitsInventoryScrollFrame.StaminaKitsList.ItemsHolderFrame
	local AbilitiesKitsInventoryContainer = CharacterKitsInventoryScrollFrame.AbilitiesKitsList.ItemsHolderFrame

	local HealthKitsCountDisplay = CharacterKitsInventoryScrollFrame.HealthKitsList.TopFrame.ItemsAmount
	local StaminaKitsCountDisplay = CharacterKitsInventoryScrollFrame.StaminaKitsList.TopFrame.ItemsAmount
	local AbilitiesKitsCountDisplay = CharacterKitsInventoryScrollFrame.AbilitiesKitsList.TopFrame.ItemsAmount

	-- Create GuiObject classes for equipped items tooltips
	local equippedItemTooltipClasses = {
		AbilitiesKit = GuiObjectClass.new(EquippedAbilitiesKitSlot),
		HealthKit = GuiObjectClass.new(EquippedHealthKitSlot),
		StaminaKit = GuiObjectClass.new(EquippedStaminaKitSlot),
		RockModel = GuiObjectClass.new(EquippedRockModelSlot),
		RockHandler = GuiObjectClass.new(EquippedRockHandlerSlot),
		RockBuffer = GuiObjectClass.new(EquippedRockBufferSlot),
		RockType = GuiObjectClass.new(EquippedRockTypeSlot),
		RockRegular = GuiObjectClass.new(EquippedRockRegularSlot)
	}

	-- Optimized tooltip connection function
	local function connectEquipmentTooltipSignal(signal, tooltipClass)
		signal:Connect(function(EquipmentDataHolder)
			if not EquipmentDataHolder then
				tooltipClass:ToggleToolTip(false)
				return
			end

			local ItemAttributes = EquipmentDataHolder:GetAttributes()
			local itemName = ItemAttributes.Name or ""
			local itemType = ItemAttributes.ItemType or ""

			tooltipClass:ToggleToolTip(true, {
				TitleText       = TextFormatter.addSpaceBeforeUpperCase(itemName),
				DescriptionText = ItemAttributes.Description,
				RarityText      = ItemAttributes.Rarity,
				ItemTypeText    = TextFormatter.addSpaceBeforeUpperCase(itemType),
				Style           = "INFO"
			})
		end)
	end

	-- Connect all equipped item tooltip signals
	connectEquipmentTooltipSignal(EquippedRockHandlerSignal, equippedItemTooltipClasses.RockHandler)
	connectEquipmentTooltipSignal(EquippedRockModelSignal, equippedItemTooltipClasses.RockModel)
	connectEquipmentTooltipSignal(EquippedRockBufferSignal, equippedItemTooltipClasses.RockBuffer)
	connectEquipmentTooltipSignal(EquippedHealthKitSignal, equippedItemTooltipClasses.HealthKit)
	connectEquipmentTooltipSignal(EquippedStaminaKitSignal, equippedItemTooltipClasses.StaminaKit)
	connectEquipmentTooltipSignal(EquippedAbilitiesKitSignal, equippedItemTooltipClasses.AbilitiesKit)

	-- Button configuration template
	local standardButtonConfig = {
		AutoDeselect = true,
		OneClick = false,
		ClickSound = nil,
		HoverSound = nil,
	}

	-- Create Button Classes for all interactive elements
	local interactiveButtonClasses = {
		MenuClose = ButtonClass.new(MenuCloseButton, standardButtonConfig),
		KitsMenu = ButtonClass.new(KitsMenuButton, standardButtonConfig),
		ModifiersMenu = ButtonClass.new(ModifiersMenuButton, standardButtonConfig),
		AllInventoryMenu = ButtonClass.new(AllInventoryMenuButton, standardButtonConfig),
		EquippedAbilitiesKit = ButtonClass.new(EquippedAbilitiesKitSlot, standardButtonConfig),
		EquippedHealthKit = ButtonClass.new(EquippedHealthKitSlot, standardButtonConfig),
		EquippedStaminaKit = ButtonClass.new(EquippedStaminaKitSlot, standardButtonConfig),
		EquippedRockModel = ButtonClass.new(EquippedRockModelSlot, standardButtonConfig),
		EquippedRockHandler = ButtonClass.new(EquippedRockHandlerSlot, standardButtonConfig),
		EquippedRockBuffer = ButtonClass.new(EquippedRockBufferSlot, standardButtonConfig),
		EquippedRockType = ButtonClass.new(EquippedRockTypeSlot, standardButtonConfig),
		EquippedRockRegular = ButtonClass.new(EquippedRockRegularSlot, standardButtonConfig)
	}

	-- Theme configurations
	local backgroundColorHoverTheme = function(hoverColor, defaultColor, includeCallbacks, buttonElement)
		local themeConfig = {}

		if includeCallbacks and buttonElement then
			themeConfig.Callbacks = {
				Enter = function(self)
					TweenService:Create(
						buttonElement.Parent.Background,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
						{ ImageColor3 = hoverColor }
					):Play()
				end,
				Exit = function(self)
					TweenService:Create(
						buttonElement.Parent.Background,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
						{ ImageColor3 = defaultColor }
					):Play()
				end,
			}
		end

		return themeConfig
	end

	local imageColorHoverTheme = function(hoverColor, defaultColor, includeCallbacks)
		local themeConfig = {
			Properties = {
				Enter = { ImageColor3 = hoverColor },
				Exit  = { ImageColor3 = defaultColor },
			},
			EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
			ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
		}

		if includeCallbacks then
			themeConfig.Callbacks = {
				Enter = function(self)  end,
				Exit  = function(self)  end,
			}
		end

		return themeConfig
	end
	
	local imageColorSelectionTheme = {
		Properties = {
			Enter = {
				ImageColor3 = Color3.fromRGB(188, 0, 0),
			},
			Exit = {
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			},
		},
		EnterTweenInfo = {
			ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		},
		ExitTweenInfo = {
			ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		},
		Callbacks = {
			Enter = function(self)
				ModifireOrKitSelectionSignal:Fire(self._button.Name, true)
			end,
			Exit = function(self)
				ModifireOrKitSelectionSignal:Fire(self._button.Name, false)
			end,
		}
	}

	-- Apply themes efficiently
	local defaultWhite = Color3.fromRGB(255, 255, 255)
	local hoverRed = Color3.fromRGB(188, 0, 0)

	interactiveButtonClasses.MenuClose:ModifyTheme("Hover", backgroundColorHoverTheme(Color3.fromRGB(199, 0, 0), defaultWhite, false, MenuCloseButton))
	interactiveButtonClasses.KitsMenu:ModifyTheme("Hover", backgroundColorHoverTheme(Color3.fromRGB(18, 149, 236), defaultWhite, true, KitsMenuButton))
	interactiveButtonClasses.ModifiersMenu:ModifyTheme("Hover", backgroundColorHoverTheme(Color3.fromRGB(204, 0, 0), defaultWhite, true, ModifiersMenuButton))
	interactiveButtonClasses.AllInventoryMenu:ModifyTheme("Hover", backgroundColorHoverTheme(Color3.fromRGB(243, 178, 14), defaultWhite, true, AllInventoryMenuButton))

	-- Apply image color themes with callbacks where needed
	interactiveButtonClasses.EquippedAbilitiesKit:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, false))
	interactiveButtonClasses.EquippedHealthKit:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedStaminaKit:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedRockModel:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedRockHandler:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedRockBuffer:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedRockType:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	interactiveButtonClasses.EquippedRockRegular:ModifyTheme("Hover", imageColorHoverTheme(hoverRed, defaultWhite, true))
	
	-- Apply Selection callbacks where needed
	interactiveButtonClasses.EquippedAbilitiesKit:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedHealthKit:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedStaminaKit:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedRockModel:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedRockHandler:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedRockBuffer:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedRockType:ModifyTheme("Selection", imageColorSelectionTheme)
	interactiveButtonClasses.EquippedRockRegular:ModifyTheme("Selection", imageColorSelectionTheme)

	-- Set up inventory category count display observers
	RockHandlerInventoryCountSignal:Connect(function(count)
		RockHandlersCountDisplay.Text = tostring(count)
	end)

	RockModelInventoryCountSignal:Connect(function(count)
		RockModelsCountDisplay.Text = tostring(count)
	end)

	RockBufferInventoryCountSignal:Connect(function(count)
		RockBuffersCountDisplay.Text = tostring(count)
	end)

	HealthKitInventoryCountSignal:Connect(function(count)
		HealthKitsCountDisplay.Text = tostring(count)
	end)

	StaminaKitInventoryCountSignal:Connect(function(count)
		StaminaKitsCountDisplay.Text = tostring(count)
	end)

	AbilitiesKitInventoryCountSignal:Connect(function(count)
		AbilitiesKitsCountDisplay.Text = tostring(count)
	end)

	-- Function to determine parent container based on item attributes
	local function getInventoryItemParentContainer(itemAttributes)
		local itemType = itemAttributes.ItemType

		if itemType == "RockModifire" then
			local modifierCategory = itemAttributes.ModifierCategory
			if modifierCategory == "Handler" then
				return RockHandlersInventoryContainer
			elseif modifierCategory == "Model" then
				return RockModelsInventoryContainer
			elseif modifierCategory == "Buffer" then
				return RockBuffersInventoryContainer
			end
		elseif itemType == "Kit" then
			local kitType = itemAttributes.TypeKit
			if kitType == "Health" then
				return HealthKitsInventoryContainer
			elseif kitType == "Stamina" then
				return StaminaKitsInventoryContainer
			elseif kitType == "Abilities" then
				return AbilitiesKitsInventoryContainer
			end
		end

		-- Default to AllInventoryPanel for unknown types
		return nil
	end

	-- Function to create dynamic inventory item button
	local function createDynamicInventoryButton(inventoryItemFolder, itemFolderName)
		local itemAttributes = inventoryItemFolder:GetAttributes()
		local categoryContainer = getInventoryItemParentContainer(itemAttributes)
		
		-- Create main inventory item button
		local primaryInventoryButton = Instance.new("ImageButton")
		primaryInventoryButton.BackgroundTransparency = 1
		primaryInventoryButton.Name = itemFolderName .. "_InventoryButton"
		primaryInventoryButton.Image = "rbxassetid://124692060751675"

		-- Create replica for AllInventoryPanel
		local allInventoryReplicaButton = primaryInventoryButton:Clone()
		allInventoryReplicaButton.Name = itemFolderName .. "_AllInventoryButton"
		allInventoryReplicaButton.Parent = AllInventoryPanel

		-- Parent main button appropriately
		if categoryContainer then
			primaryInventoryButton.Parent = categoryContainer
		else
			primaryInventoryButton.Parent = AllInventoryPanel
		end

		-- Create button classes for both buttons
		local primaryButtonClass = ButtonClass.new(primaryInventoryButton, standardButtonConfig)
		local replicaButtonClass = ButtonClass.new(allInventoryReplicaButton, standardButtonConfig)

		-- Apply hover themes
		local inventoryItemHoverTheme = {
			Properties = {
				Enter = { ImageColor3 = Color3.fromRGB(188, 0, 0) },
				Exit  = { ImageColor3 = Color3.fromRGB(255, 255, 255) },
			},
			EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
			ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
			Callbacks = {
				Enter = function(self)  end,
				Exit  = function(self)  end,
			}
		}

		local inventoryItemSelectionTheme = {
			Properties = {
				Enter = {
					ImageColor3 = Color3.fromRGB(188, 0, 0),
				},
				Exit = {
					ImageColor3 = Color3.fromRGB(255, 255, 255),
				},
			},
			EnterTweenInfo = {
				ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			},
			ExitTweenInfo = {
				ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			},
			Callbacks = {
				Enter = function(self)
					ItemSelectionSignal:Fire(self._button.Name, true)
				end,
				Exit = function(self)
					ItemSelectionSignal:Fire(self._button.Name, false)
				end,
			}
		}

		primaryButtonClass:ModifyTheme("Hover", inventoryItemHoverTheme)
		replicaButtonClass:ModifyTheme("Hover", inventoryItemHoverTheme)

		primaryButtonClass:ModifyTheme("Selection", inventoryItemSelectionTheme)
		replicaButtonClass:ModifyTheme("Selection", inventoryItemSelectionTheme)

		-- Create tooltip classes for both buttons
		local primaryButtonTooltipClass = GuiObjectClass.new(primaryInventoryButton)
		local replicaButtonTooltipClass = GuiObjectClass.new(allInventoryReplicaButton)

		-- Function to update tooltips for both buttons
		local function updateInventoryItemTooltips(dataHolder)
			if not dataHolder then
				primaryButtonTooltipClass:ToggleToolTip(false)
				replicaButtonTooltipClass:ToggleToolTip(false)
				return
			end

			local currentItemAttributes = dataHolder:GetAttributes()

			local itemName = currentItemAttributes.Name or ""
			local itemType = currentItemAttributes.ItemType or ""

			local tooltipConfiguration = {
				TitleText       = TextFormatter.addSpaceBeforeUpperCase(itemName),
				DescriptionText = currentItemAttributes.Description,
				RarityText      = currentItemAttributes.Rarity,
				ItemTypeText    = TextFormatter.addSpaceBeforeUpperCase(itemType),
				Style           = "INFO"
			}

			primaryButtonTooltipClass:ToggleToolTip(true, tooltipConfiguration)
			replicaButtonTooltipClass:ToggleToolTip(true, tooltipConfiguration)
		end

		-- Store button information for cleanup and management
		DynamicInventoryButtons[itemFolderName] = {
			primaryButton = primaryInventoryButton,
			replicaButton = allInventoryReplicaButton,
			primaryButtonClass = primaryButtonClass,
			replicaButtonClass = replicaButtonClass,
			primaryButtonTooltipClass = primaryButtonTooltipClass,
			replicaButtonTooltipClass = replicaButtonTooltipClass,
			updateTooltips = updateInventoryItemTooltips
		}

		-- Initial tooltip setup
		updateInventoryItemTooltips(inventoryItemFolder)

		return DynamicInventoryButtons[itemFolderName]
	end

	-- Function to cleanup dynamic inventory button
	local function cleanupDynamicInventoryButton(itemFolderName)
		local buttonInfo = DynamicInventoryButtons[itemFolderName]
		if buttonInfo then
			-- Destroy GUI elements
			if buttonInfo.primaryButton then
				buttonInfo.primaryButton:Destroy()
			end
			if buttonInfo.replicaButton then
				buttonInfo.replicaButton:Destroy()
			end

			-- Clear from tracking
			DynamicInventoryButtons[itemFolderName] = nil
		end
	end

	-- Connect to all existing and future inventory item signals
	local function connectToInventoryItemSignal(itemFolderName)
		if InventoryItemDataSignals[itemFolderName] then
			InventoryItemDataSignals[itemFolderName]:Connect(function(inventoryDataHolder, signalFolderName)
				if not inventoryDataHolder then
					-- Cleanup button
					cleanupDynamicInventoryButton(signalFolderName)
				else
					-- Create or update button
					local existingButtonInfo = DynamicInventoryButtons[signalFolderName]
					if not existingButtonInfo then
						createDynamicInventoryButton(inventoryDataHolder, signalFolderName)
					else
						-- Update existing tooltips
						existingButtonInfo.updateTooltips(inventoryDataHolder)
					end
				end
			end)
		end
	end

	-- Connect to existing inventory item signals
	for itemFolderName, signal in pairs(InventoryItemDataSignals) do
		connectToInventoryItemSignal(itemFolderName)
	end

	-- Watch for new inventory item signals being created
	local originalInventorySignalsTable = InventoryItemDataSignals
	setmetatable(InventoryItemDataSignals, {
		__newindex = function(t, k, v)
			rawset(t, k, v)
			connectToInventoryItemSignal(k)
		end
	})

	-- Handler for when new inventory item folder is added
	NewInventoryItemSignal:Connect(function(newItemChild)
		local newItemFolderName = newItemChild.Name

		-- The signal creation is already handled by setupInventoryItemsObserver
		-- So here we just connect UI when the new signal appears
		if InventoryItemDataSignals[newItemFolderName] then
			connectToInventoryItemSignal(newItemFolderName)
		end
	end)

	-- Prepare dynamic inventory button signals for external use
	local dynamicInventoryButtonSignals = {}
	for itemFolderName, buttonInfo in pairs(DynamicInventoryButtons) do
		if buttonInfo.primaryButtonClass and buttonInfo.replicaButtonClass then
			dynamicInventoryButtonSignals[itemFolderName] = {
				PrimaryButtonSignal = buttonInfo.primaryButtonClass.Signals.Activated,
				ReplicaButtonSignal = buttonInfo.replicaButtonClass.Signals.Activated,
			}
		end
	end

	-- Return comprehensive signal structure
	return {
		-- Static Menu Navigation Signals
		MenuNavigation = {
			KitsMenuSignal = interactiveButtonClasses.KitsMenu.Signals.Activated,
			ModifiersMenuSignal = interactiveButtonClasses.ModifiersMenu.Signals.Activated,
			AllInventoryMenuSignal = interactiveButtonClasses.AllInventoryMenu.Signals.Activated,
			MenuCloseSignal = interactiveButtonClasses.MenuClose.Signals.Activated,
		},

		-- Static Equipment Slot Signals (for equipped items) Not being used but i will keep them for know.
		EquippedItems = {
			AbilitiesKitSlotSignal = interactiveButtonClasses.EquippedAbilitiesKit.Signals.Activated,
			HealthKitSlotSignal = interactiveButtonClasses.EquippedHealthKit.Signals.Activated,
			StaminaKitSlotSignal = interactiveButtonClasses.EquippedStaminaKit.Signals.Activated,
		},

		EquippedRockModifiers = {
			RockModelSlotSignal = interactiveButtonClasses.EquippedRockModel.Signals.Activated,
			RockHandlerSlotSignal = interactiveButtonClasses.EquippedRockHandler.Signals.Activated,
			RockBufferSlotSignal = interactiveButtonClasses.EquippedRockBuffer.Signals.Activated,
			RockTypeSlotSignal = interactiveButtonClasses.EquippedRockType.Signals.Activated,
			RockRegularSlotSignal = interactiveButtonClasses.EquippedRockRegular.Signals.Activated,
		},

		-- Dynamic Inventory Item Signals (for inventory items)
		DynamicInventoryItems = {
			ItemButtons = dynamicInventoryButtonSignals,
			ItemSelectionSignal = ItemSelectionSignal,
			ModifireOrKitSelectionSignal = ModifireOrKitSelectionSignal
		}
	}
end














function GuiInitializer.TransformWithPosition(
	GuiObject1: GuiObject,
	GuiObject2: GuiObject,
	params: TransformParams
)
	assert(params.TweenInfo, "TweenInfo is required!")
	
	local Tween1
	local Tween2
	
	-- === GuiObject1 ===
	if params.StartPosition1 then
		GuiObject1.Position = params.StartPosition1
	end
	if params.GoalPosition1 then
		Tween1 = TweenService:Create(GuiObject1, params.TweenInfo, {
			Position = params.GoalPosition1,
		})
	end

	-- === GuiObject2 ===
	if params.StartPosition2 then
		GuiObject2.Position = params.StartPosition2
	end
	if params.GoalPosition2 then
		Tween2 = TweenService:Create(GuiObject2, params.TweenInfo, {
			Position = params.GoalPosition2,
		})
	end
	
	FunctionUtils.Game.spawn(function()
		if Tween1 then Tween1:Play() end
		if Tween2 then Tween2:Play() end
	end)
end

function GuiInitializer.TextTransparency(textLabel: TextLabel, tweenInfo: TweenInfo?, reverse: boolean)
	assert(textLabel and textLabel:IsA("TextLabel"), "GuiObject must be a TextLabel")

	-- Default TweenInfo if none provided
	tweenInfo = tweenInfo or TweenInfo.new(
		0.5,                     -- Time
		Enum.EasingStyle.Quad,   -- EasingStyle
		Enum.EasingDirection.Out -- EasingDirection
	)

	-- Determine start and goal transparency
	local startTransparency = reverse and 0 or 1
	local goalTransparency = reverse and 1 or 0

	-- Set initial transparency
	textLabel.TextTransparency = startTransparency

	-- Tween only the TextTransparency
	local tween = TweenService:Create(textLabel, tweenInfo, {
		TextTransparency = goalTransparency
	})

	tween:Play()
	return tween
end

function GuiInitializer.setupSwipeMenu(Menu:Frame,
	Inventory:Frame,
	SwipeToInvButton:GuiButton,
	SwipeToMenuButton:GuiButton,
	tweenTime:number,
	handleUpperMenu:RBXScriptSignal) : SwipeButtonsSignalConnections	
	
	-- DESTINATION POSITIONS
	local A_HOME, A_OFF = 0, -1
	local B_HOME, B_OFF = 0, 1

	-- Internal
	local screenHeight = workspace.CurrentCamera.ViewportSize.Y
	local dragging = false
	local startY

	-- Initial positions
	Menu.Position = UDim2.new(0, 0, A_HOME, 0)
	Inventory.Position = UDim2.new(0, 0, B_OFF, 0)

	-- Animate frames and toggle buttons
	local function animateFrames(forward)
		if forward then
			TweenService:Create(Menu, TweenInfo.new(tweenTime), {Position = UDim2.new(0, 0, A_OFF, 0)}):Play()
			TweenService:Create(Inventory, TweenInfo.new(tweenTime), {Position = UDim2.new(0, 0, B_HOME, 0)}):Play()
			SwipeToInvButton.Visible = false
			SwipeToMenuButton.Visible = true
		else
			TweenService:Create(Menu, TweenInfo.new(tweenTime), {Position = UDim2.new(0, 0, A_HOME, 0)}):Play()
			TweenService:Create(Inventory, TweenInfo.new(tweenTime), {Position = UDim2.new(0, 0, B_OFF, 0)}):Play()
			SwipeToInvButton.Visible = true
			SwipeToMenuButton.Visible = false
		end
	end

	-- Drag handling
	local function startDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startY = input.Position.Y
		end
	end


	local function updateDrag(input, forwardButton)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local deltaY
			--if forwardButton then
			--	-- drag down (Menu → Inventory)
			--	deltaY = (input.Position.Y - startY) / screenHeight
			--	deltaY = math.clamp(deltaY, 0, 1)
			--	Menu.Position = UDim2.new(0, 0, A_HOME + deltaY, 0)
			--	Inventory.Position = UDim2.new(0, 0, B_OFF + deltaY, 0)
			--else
			--	-- drag up (Inventory → Menu)
			--	deltaY = (startY - input.Position.Y) / screenHeight
			--	deltaY = math.clamp(deltaY, 0, 1)
			--	Menu.Position = UDim2.new(0, 0, A_OFF - deltaY, 0)
			--	Inventory.Position = UDim2.new(0, 0, B_HOME - deltaY, 0)
			--end
			
			if forwardButton then
				-- reverse: drag UP for Menu → Inventory
				deltaY = (startY - input.Position.Y) / screenHeight
				deltaY = math.clamp(deltaY, 0, 1)
				Menu.Position = UDim2.new(0, 0, A_HOME - deltaY, 0)
				Inventory.Position = UDim2.new(0, 0, B_OFF - deltaY, 0)
			else
				-- reverse: drag DOWN for Inventory → Menu
				deltaY = (input.Position.Y - startY) / screenHeight
				deltaY = math.clamp(deltaY, 0, 1)
				Menu.Position = UDim2.new(0, 0, A_OFF + deltaY, 0)
				Inventory.Position = UDim2.new(0, 0, B_HOME + deltaY, 0)
			end
		end
	end

	local function endDrag(input, forwardButton)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			local deltaY
			local dragThreshold = 0.25
			if forwardButton then
				deltaY = (startY - input.Position.Y) / screenHeight
			else
				deltaY = (input.Position.Y - startY) / screenHeight
			end
			if deltaY > dragThreshold then
				animateFrames(forwardButton)
				handleUpperMenu:Fire(forwardButton)
			else
				animateFrames(not forwardButton)
			end
		end
	end

	-- Connections
	local signals = {}

	-- Buttons only start the drag
	signals.forwardInputBegan = SwipeToInvButton.InputBegan:Connect(startDrag)
	signals.backInputBegan = SwipeToMenuButton.InputBegan:Connect(startDrag)

	-- Use global UserInputService for updates and release
	signals.inputChanged = UserInputService.InputChanged:Connect(function(input)
		local forwardButton = SwipeToInvButton.Visible
		updateDrag(input, forwardButton)
	end)

	signals.inputEnded = UserInputService.InputEnded:Connect(function(input)
		local forwardButton = SwipeToInvButton.Visible
		endDrag(input, forwardButton)
	end)
	-- Initialize buttons
	SwipeToInvButton.Visible = true
	SwipeToMenuButton.Visible = false

	return signals 
end


function GuiInitializer.SwitchFramesWithImageTransparncy(Frame1: Frame, Frame2: Frame, duration: number?)
	duration = duration or 0.2 -- default duration

	local function tweenImages(frame: Frame, startTransparency: number, endTransparency: number)
		local images = {}
		for _, il in ipairs(FunctionUtils.Object.findAllWhichAreA("ImageLabel", frame)) do
			table.insert(images, il)
			il.ImageTransparency = startTransparency
		end
		for _, ib in ipairs(FunctionUtils.Object.findAllWhichAreA("ImageButton", frame)) do
			table.insert(images, ib)
			ib.ImageTransparency = startTransparency
		end

		local tweens = {}
		for _, obj in ipairs(images) do
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
			local tween = TweenService:Create(obj, tweenInfo, {ImageTransparency = endTransparency})
			table.insert(tweens, tween)
			tween:Play()
		end

		return tweens
	end

	-- Start tweens simultaneously
	local fadeOutTweens = tweenImages(Frame1, 0, 1)
	wait(0.2)
	Frame1.Visible = false
	Frame2.Visible = true
	local fadeInTweens = tweenImages(Frame2, 1, 0)

end

function GuiInitializer.SwitchFramesWithTextTransparency(Frame1: Frame, Frame2: Frame, duration: number?)
	duration = duration or 0.2 -- default duration

	local function tweenTextLabels(frame: Frame, startTransparency: number, endTransparency: number)
		local textLabels = {}
		for _, tl in ipairs(FunctionUtils.Object.findAllWhichAreA("TextLabel", frame)) do
			table.insert(textLabels, tl)
			tl.TextTransparency = startTransparency
		end

		local tweens = {}
		for _, obj in ipairs(textLabels) do
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
			local tween = TweenService:Create(obj, tweenInfo, {TextTransparency = endTransparency})
			table.insert(tweens, tween)
			tween:Play()
		end

		return tweens
	end

	-- Fade out Frame1
	local fadeOutTweens = tweenTextLabels(Frame1, 0, 1)
	task.wait(duration) -- let the fade play

	Frame1.Visible = false
	Frame2.Visible = true

	-- Fade in Frame2
	local fadeInTweens = tweenTextLabels(Frame2, 1, 0)

end



function GuiInitializer.Hide3D_UI_Transparency(GUI: ScreenGui, fadeOut: boolean, duration: number?)
	duration = duration or 0.2
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local targetTransparency = fadeOut and 1 or 0

	-- Get the first two SurfaceGuis under the GUI
	local surfaceGuis = {}
	for _, obj in ipairs(GUI:GetChildren()) do
		if obj:IsA("SurfaceGui") then
			table.insert(surfaceGuis, obj)
			if #surfaceGuis >= 2 then break end
		end
	end

	-- Iterate through the two SurfaceGuis
	for _, surfaceGui in ipairs(surfaceGuis) do
		-- Find all Frames, ImageLabels, ImageButtons, and TextLabels under this SurfaceGui
		local frames = FunctionUtils.Object.findAll("Black", surfaceGui)
		local imageLabels = FunctionUtils.Object.findAllWhichAreA("ImageLabel", surfaceGui)
		local imageButtons = FunctionUtils.Object.findAllWhichAreA("ImageButton", surfaceGui)
		local textLabels = FunctionUtils.Object.findAllWhichAreA("TextLabel", surfaceGui)

		-- Tween all ImageLabels
		for _, img in ipairs(imageLabels) do
			img.ImageTransparency = fadeOut and 0 or 1 -- start transparency
			local tween = TweenService:Create(img, tweenInfo, {ImageTransparency = targetTransparency})
			tween:Play()
		end

		-- Tween ImageButtons and adjust visibility after tween finishes
		for _, btn in ipairs(imageButtons) do
			btn.Visible = true -- always visible during tween
			btn.ImageTransparency = fadeOut and 0 or 1
			local tween = TweenService:Create(btn, tweenInfo, {ImageTransparency = targetTransparency})
			local signal
			signal = tween.Completed:Connect(function()
				btn.Visible = not fadeOut -- hide if faded out, show if faded back in
				signal:Disconnect()
			end)
			tween:Play()
		end

		-- Tween all TextLabels
		for _, txt in ipairs(textLabels) do
			txt.TextTransparency = fadeOut and 0 or 1 -- start transparency
			local tween = TweenService:Create(txt, tweenInfo, {TextTransparency = targetTransparency})
			tween:Play()
		end

		-- Optionally, tween Frames' background transparency if needed
		for _, frame in ipairs(frames) do
			frame.BackgroundTransparency = fadeOut and 1 or 0
		end
	end
end

--function GuiInitializer.SetMobileInputUI(
--	Player: Player,
--	SlideButtonSignal: RBXScriptSignal,
--	SprintButtonStartSignal: RBXScriptSignal,
--	SprintButtonEndSignal: RBXScriptSignal,
--	EquipButtonSignal: RBXScriptSignal,
--	AimButtonSignal: RBXScriptSignal
--)
--	local Touch_GUI = Player.PlayerGui:WaitForChild("TouchGui")
--	local ButtonsFolder = Player.PlayerGui:WaitForChild("MobileButtons")
--	local TouchControlFrame = Touch_GUI:WaitForChild("TouchControlFrame")
--	local JumpButton = TouchControlFrame:WaitForChild("JumpButton")

--	JumpButton.Image = "rbxassetid://94657407000695"

--	-- Original JumpButton reference values
--	local OriginalSize = UDim2.new(0, 70, 0, 70)
--	local OriginalPosition = UDim2.new(1, -95, 1, -90)

--	local function computeScale(current: UDim2, original: UDim2)
--		local scaleX = current.X.Offset / original.X.Offset
--		local scaleY = current.Y.Offset / original.Y.Offset
--		return scaleX, scaleY
--	end

--	local function computePositionScale(current: UDim2, original: UDim2)
--		local offsetXScale = current.X.Offset / original.X.Offset
--		local offsetYScale = current.Y.Offset / original.Y.Offset
--		return offsetXScale, offsetYScale
--	end

--	local SlideButton = ButtonsFolder:WaitForChild("SlideButton")
--	local SprintButton = ButtonsFolder:WaitForChild("SprintButton")
--	local EquipButton = ButtonsFolder:WaitForChild("EquipButton")
--	local AimButton = ButtonsFolder:WaitForChild("AimButton")

--	-- Move buttons under TouchControlFrame
--	for _, button in ipairs({ SlideButton, SprintButton, EquipButton, AimButton }) do
--		button.Parent = TouchControlFrame
--	end

--	-- Hide + fade setup for AimButton
--	AimButton.Visible = false
--	AimButton.ImageTransparency = 1

--	local standardButtonConfig = {
--		AutoDeselect = true,
--		OneClick = false,
--		ClickSound = nil,
--		HoverSound = nil,
--	}

--	local SlideButtonClass = ButtonClass.new(SlideButton, standardButtonConfig)
--	local SprintButtonClass = ButtonClass.new(SprintButton, standardButtonConfig)
--	local EquipButtonClass = ButtonClass.new(EquipButton, standardButtonConfig)
--	local AimButtonClass = ButtonClass.new(AimButton, standardButtonConfig)

--	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--	----------------------------------------------------------------------
--	-- EQUIP BUTTON LOGIC (controls AimButton visibility)
--	----------------------------------------------------------------------
--	local equipActive = false
--	local equipImage = EquipButton:WaitForChild("EquipImage")

--	EquipButtonClass:ModifyTheme("Selection", {
--		Callbacks = {
--			Enter = function()
--				equipActive = not equipActive
--				EquipButtonSignal:Fire(equipActive)

--				local newColor = equipActive and Color3.fromHex("#FF0000") or Color3.fromRGB(255, 255, 255)
--				TweenService:Create(equipImage, tweenInfo, { ImageColor3 = newColor }):Play()

--				-- Handle AimButton fade in/out
--				if equipActive then
--					AimButton.Visible = true
--					AimButton.ImageTransparency = 1
--					TweenService:Create(AimButton, tweenInfo, { ImageTransparency = 0 }):Play()
--				else
--					local fadeOut = TweenService:Create(AimButton, tweenInfo, { ImageTransparency = 1 })
--					fadeOut:Play()
--					fadeOut.Completed:Connect(function()
--						AimButton.Visible = false
--					end)
--				end
--			end,
--			Exit = function() end,
--		},
--	})

--	----------------------------------------------------------------------
--	-- AIM BUTTON LOGIC (only active when equipped)
--	----------------------------------------------------------------------
--	local aimActive = false
--	local aimImage = AimButton:WaitForChild("AimImage")

--	AimButtonClass:ModifyTheme("Selection", {
--		Callbacks = {
--			Enter = function()
--				if not equipActive then return end -- ignore if not equipped
--				aimActive = not aimActive
--				AimButtonSignal:Fire(aimActive)

--				local newColor = aimActive and Color3.fromHex("#FF0000") or Color3.fromRGB(255, 255, 255)
--				TweenService:Create(aimImage, tweenInfo, { ImageColor3 = newColor }):Play()
--			end,
--			Exit = function() end,
--		},
--	})

--	----------------------------------------------------------------------
--	-- SLIDE & SPRINT LOGIC
--	----------------------------------------------------------------------
--	local SprintImage = SprintButton:WaitForChild("SprintImage")
--	SprintButtonClass:ModifyTheme("Selection", {
--		Callbacks = {
--			Enter = function()
--				TweenService:Create(SprintImage, tweenInfo, { ImageColor3 = Color3.fromHex("#FF0000") }):Play()
--				SprintButtonStartSignal:Fire()
--			end,
--			Exit = function()
--				TweenService:Create(SprintImage, tweenInfo, { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
--				SprintButtonEndSignal:Fire()
--			end,
--		},
--	})

--	local function setupHoverEffect(button: GuiButton, imageName: string, signal: RBXScriptSignal)
--		local imageObject = button:WaitForChild(imageName)
--		return {
--			Callbacks = {
--				Enter = function()
--					TweenService:Create(imageObject, tweenInfo, { ImageColor3 = Color3.fromHex("#FF0000") }):Play()
--					signal:Fire()
--				end,
--				Exit = function()
--					TweenService:Create(imageObject, tweenInfo, { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
--				end,
--			},
--		}
--	end

--	SlideButtonClass:ModifyTheme("Selection", setupHoverEffect(SlideButton, "SlideImage", SlideButtonSignal))

--	----------------------------------------------------------------------
--	-- SCALE + POSITION SYNC SYSTEM
--	----------------------------------------------------------------------
--	local function applyScaling()
--		local sizeScaleX, sizeScaleY = computeScale(JumpButton.Size, OriginalSize)
--		local posScaleX, posScaleY = computePositionScale(JumpButton.Position, OriginalPosition)

--		local avgSizeScale = (sizeScaleX + sizeScaleY) / 2
--		local avgPosScale = (posScaleX + posScaleY) / 2

--		print(string.format("[JumpButton] Scaled by %.2fx | Moved by %.2fx", avgSizeScale, avgPosScale))

--		for _, button in ipairs({ SlideButton, SprintButton, EquipButton, AimButton }) do
--			button.Size = UDim2.new(
--				button.Size.X.Scale,
--				button.Size.X.Offset * avgSizeScale,
--				button.Size.Y.Scale,
--				button.Size.Y.Offset * avgSizeScale
--			)
--			button.Position = UDim2.new(
--				button.Position.X.Scale,
--				button.Position.X.Offset * avgPosScale,
--				button.Position.Y.Scale,
--				button.Position.Y.Offset * avgPosScale
--			)
--		end
--	end

--	applyScaling()
--	JumpButton:GetPropertyChangedSignal("Size"):Connect(applyScaling)
--	JumpButton:GetPropertyChangedSignal("Position"):Connect(applyScaling)
--end

function GuiInitializer.SetMobileInputUI(
	Player: Player,
	SlideButtonSignal: RBXScriptSignal,
	SprintButtonStartSignal: RBXScriptSignal,
	SprintButtonEndSignal: RBXScriptSignal,
	EquipButtonSignal: RBXScriptSignal,
	AimButtonSignal: RBXScriptSignal,
	JumpButtonSignal: RBXScriptSignal
)
	local TweenService = game:GetService("TweenService")

	--// Create persistent GUI
	local MobileTouchGUI = Player.PlayerGui:FindFirstChild("MobileTouchGUI")
	if not MobileTouchGUI then
		MobileTouchGUI = Instance.new("ScreenGui")
		MobileTouchGUI.Name = "MobileTouchGUI"
		MobileTouchGUI.ResetOnSpawn = false
		MobileTouchGUI.Parent = Player.PlayerGui
	end

	--// Button references - Move from ButtonsFolder to MobileTouchGUI
	local ButtonsFolder = Player.PlayerGui:WaitForChild("MobileTouchGUI")
	
	ButtonsFolder.Enabled = true

	-- Wait until all buttons are loaded
	while not ButtonsFolder or not ButtonsFolder:FindFirstChild("SlideButton") do
		task.wait()
		ButtonsFolder = Player.PlayerGui:WaitForChild("MobileButtons")
	end

	local SlideButton = ButtonsFolder:WaitForChild("SlideButton")
	local SprintButton = ButtonsFolder:WaitForChild("SprintButton")
	local EquipButton = ButtonsFolder:WaitForChild("EquipButton")
	local AimButton = ButtonsFolder:WaitForChild("AimButton")

	-- Move buttons to persistent GUI
	for _, button in ipairs({ SlideButton, SprintButton, EquipButton, AimButton }) do
		button.Parent = MobileTouchGUI
	end

	--// Function to setup touch controls
	local function setupTouchControls()
		local Touch_GUI = Player.PlayerGui:FindFirstChild("TouchGui")

		-- Check if TouchGui is gone for good
		if not Touch_GUI then
			task.wait(2) -- Wait a bit to confirm
			Touch_GUI = Player.PlayerGui:FindFirstChild("TouchGui")
			if not Touch_GUI then
				warn("TouchGui not found - disabling MobileTouchGUI")
				MobileTouchGUI.Enabled = false
				return false
			end
		end

		local TouchControlFrame = Touch_GUI:WaitForChild("TouchControlFrame")
		local JumpButton = TouchControlFrame:WaitForChild("JumpButton")

		Touch_GUI.ResetOnSpawn = false

		-- Jump customization
		JumpButton.Image = "rbxassetid://94657407000695"

		-- Disconnect previous connection if exists
		if JumpButton:GetAttribute("ConnectionEstablished") then
			return true -- Already connected
		end

		JumpButton.InputBegan:Connect(function()
			JumpButtonSignal:Fire()
		end)

		JumpButton:SetAttribute("ConnectionEstablished", true)

		-- Original JumpButton reference values (for scale sync)
		local OriginalSize = UDim2.new(0, 70, 0, 70)
		local OriginalPosition = UDim2.new(1, -95, 1, -90)

		local function computeScale(current: UDim2, original: UDim2)
			return current.X.Offset / original.X.Offset, current.Y.Offset / original.Y.Offset
		end

		local function computePositionScale(current: UDim2, original: UDim2)
			return current.X.Offset / original.X.Offset, current.Y.Offset / original.Y.Offset
		end

		--------------------------------------
		-- SCALE + POSITION SYNC SYSTEM
		--------------------------------------
		local function applyScaling()
			local sizeScaleX, sizeScaleY = computeScale(JumpButton.Size, OriginalSize)
			local posScaleX, posScaleY = computePositionScale(JumpButton.Position, OriginalPosition)

			for _, button in ipairs({ SlideButton, SprintButton, EquipButton, AimButton }) do
				-- Scale size (average is fine)
				local avgSizeScale = (sizeScaleX + sizeScaleY) / 2
				button.Size = UDim2.new(
					button.Size.X.Scale,
					button.Size.X.Offset * avgSizeScale,
					button.Size.Y.Scale,
					button.Size.Y.Offset * avgSizeScale
				)

				-- Scale position separately
				button.Position = UDim2.new(
					button.Position.X.Scale,
					button.Position.X.Offset * posScaleX,
					button.Position.Y.Scale,
					button.Position.Y.Offset * posScaleY
				)
			end
		end

		applyScaling()
		JumpButton:GetPropertyChangedSignal("Size"):Connect(applyScaling)
		JumpButton:GetPropertyChangedSignal("Position"):Connect(applyScaling)

		return true
	end

	--------------------------------------
	-- CONFIGURATION
	--------------------------------------
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local COLOR_RED = Color3.fromHex("#FF0000")
	local COLOR_BLUE = Color3.fromRGB(4, 123, 202)
	local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

	--------------------------------------
	-- EQUIP BUTTON (toggles AimButton)
	--------------------------------------
	local equipActive = false
	local equipImage = EquipButton:WaitForChild("EquipImage")

	EquipButton.MouseButton1Click:Connect(function()
		equipActive = not equipActive
		EquipButtonSignal:Fire(equipActive)

		-- Change equip button color (button + image)
		local targetColor = equipActive and COLOR_RED or COLOR_WHITE
		TweenService:Create(EquipButton, tweenInfo, { ImageColor3 = targetColor }):Play()
		TweenService:Create(equipImage, tweenInfo, { ImageColor3 = targetColor }):Play()

		-- Handle AimButton visibility + fade
		if equipActive then
			AimButton.Visible = true
			AimButton.ImageTransparency = 1
			local aimImage = AimButton:FindFirstChild("AimImage")
			if aimImage then aimImage.ImageTransparency = 1 end

			-- Tween in both button and image
			TweenService:Create(AimButton, tweenInfo, { ImageTransparency = 0 }):Play()
			if aimImage then
				TweenService:Create(aimImage, tweenInfo, { ImageTransparency = 0 }):Play()
			end
		else
			local aimImage = AimButton:FindFirstChild("AimImage")
			local fadeOut = TweenService:Create(AimButton, tweenInfo, { ImageTransparency = 1 })
			fadeOut:Play()

			if aimImage then
				TweenService:Create(aimImage, tweenInfo, { ImageTransparency = 1 }):Play()
			end

			fadeOut.Completed:Connect(function()
				AimButton.Visible = false
			end)
		end
	end)

	--------------------------------------
	-- AIM BUTTON
	--------------------------------------
	local aimActive = false
	local aimImage = AimButton:WaitForChild("AimImage")

	AimButton.MouseButton1Click:Connect(function()
		if not equipActive then return end
		aimActive = not aimActive
		AimButtonSignal:Fire(aimActive)

		local targetColor = aimActive and COLOR_BLUE or COLOR_WHITE
		TweenService:Create(AimButton, tweenInfo, { ImageColor3 = targetColor }):Play()
		TweenService:Create(aimImage, tweenInfo, { ImageColor3 = targetColor }):Play()
	end)

	--------------------------------------
	-- SLIDE BUTTON
	--------------------------------------
	local SlideImage = SlideButton:WaitForChild("SlideImage")

	SlideButton.MouseButton1Click:Connect(function()
		TweenService:Create(SlideImage, tweenInfo, { ImageColor3 = COLOR_RED }):Play()
		SlideButtonSignal:Fire()
		task.delay(0.2, function()
			TweenService:Create(SlideImage, tweenInfo, { ImageColor3 = COLOR_WHITE }):Play()
		end)
	end)

	--------------------------------------
	-- SPRINT BUTTON (hold to sprint)
	--------------------------------------
	local SprintImage = SprintButton:WaitForChild("SprintImage")

	SprintButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(SprintImage, tweenInfo, { ImageColor3 = COLOR_RED }):Play()
			SprintButtonStartSignal:Fire()
		end
	end)

	SprintButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(SprintImage, tweenInfo, { ImageColor3 = COLOR_WHITE }):Play()
			SprintButtonEndSignal:Fire()
		end
	end)

	--------------------------------------
	-- OBSERVER FOR TOUCH GUI RESET
	--------------------------------------
	-- Initial setup
	setupTouchControls()

	-- Observer for when TouchGui gets added/reset
	Player.PlayerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			task.wait(0.1) -- Small delay to ensure everything is loaded
			setupTouchControls()
		end
	end)

	-- Observer for when TouchGui gets removed
	Player.PlayerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			task.wait(2) -- Wait to see if it comes back
			local Touch_GUI = Player.PlayerGui:FindFirstChild("TouchGui")
			if not Touch_GUI then
				warn("TouchGui removed permanently - disabling MobileTouchGUI")
				MobileTouchGUI.Enabled = false
			end
		end
	end)
end


-- Enable all mobile buttons
function GuiInitializer.EnableMobileButtons(Player: Player)
	local MobileTouchGUI = Player.PlayerGui:FindFirstChild("MobileTouchGUI")
	if not MobileTouchGUI then return end

	for _, button in ipairs(MobileTouchGUI:GetChildren()) do
		if button:IsA("ImageButton") or button:IsA("ImageLabel") then
			button.Visible = true
			button.Active = true
		end
	end
end

-- Disable all mobile buttons
function GuiInitializer.DisableMobileButtons(Player: Player)
	local MobileTouchGUI = Player.PlayerGui:FindFirstChild("MobileTouchGUI")
	if not MobileTouchGUI then return end

	for _, button in ipairs(MobileTouchGUI:GetChildren()) do
		if button:IsA("ImageButton") or button:IsA("ImageLabel") then
			button.Visible = false
			button.Active = false
		end
	end
end

local Signal: ModuleUtils.Signal<any>

function GuiInitializer.TweenNPCGUI(gui:ScreenGui,isHide:boolean) : RBXScriptSignal
	local frame1 = gui.Frame1
	local frame2 = gui.Frame2
	
	-- callback signal to close the Intaction GUI 
	if not Signal then
		Signal = ModuleUtils.Signal.new()
	end
	
	local tweenInfo = TweenInfo.new(
		1.5, -- time
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	
	if isHide then
		-- Default positions OUTSIDE screen before opening
		frame1.Position = UDim2.new(frame1.Position.X.Scale, frame1.Position.X.Offset, -0.16, 0)
		frame2.Position = UDim2.new(frame2.Position.X.Scale, frame2.Position.X.Offset,  1, 0)
	else
		-- Default positions INSIDE screen before closing animation
		frame1.Position = UDim2.new(frame1.Position.X.Scale, frame1.Position.X.Offset, 0, 0)
		frame2.Position = UDim2.new(frame2.Position.X.Scale, frame2.Position.X.Offset,  0.86, 0)
	end

	-- Target positions/scales based on boolean
	local target1, target2

	if isHide then
		-- Frames appear (enter animation)
		target1 = { Position = UDim2.new(frame1.Position.X.Scale, frame1.Position.X.Offset, 0, 0) }
		target2 = { Position = UDim2.new(frame2.Position.X.Scale, frame2.Position.X.Offset, 0.86, 0) }
	else
		-- Frames hide (exit animation)
		target1 = { Position = UDim2.new(frame1.Position.X.Scale, frame1.Position.X.Offset, -0.16, 0) }
		target2 = { Position = UDim2.new(frame2.Position.X.Scale, frame2.Position.X.Offset, 1, 0) }
	end


	-- Create tweens
	local tween1 = TweenService:Create(frame1, tweenInfo, target1)
	local tween2 = TweenService:Create(frame2, tweenInfo, target2)

	-- Play both tweens
	tween1:Play()
	tween2:Play()
	
	return Signal
end


local optionTempleteClone = script.ButtonFrame -- your module reference

function GuiInitializer.BindDialog(gui: ScreenGui, dialog: any, currentNodeName: string)
	gui.Enabled = true
	local firstOpen = not gui:GetAttribute("HasOpened")
	if firstOpen then
		gui:SetAttribute("HasOpened", true)
	end

	local InteractionFrame = gui.IntractionFrame
	local NPC_Name = InteractionFrame.NPC_Text_Frame.NPC_Name
	local NPC_Text = InteractionFrame.NPC_Text_Frame.NPC_Text
	local Liner = InteractionFrame.NPC_Text_Frame.Liner.ImageLabel
	local OptionsFrame = InteractionFrame.Options

	local isExiting = false

	local function SafeFade(obj, targetProps, duration)
		local props = {}
		for key, value in pairs(targetProps) do
			if obj:IsA("TextLabel") then
				if key == "TextTransparency" then
					props[key] = value
				end
			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				if key == "ImageTransparency" or key == "BackgroundTransparency" then
					props[key] = value
				end
			elseif obj:IsA("Frame") then
				if key == "BackgroundTransparency" then
					props[key] = value
				end
			end
		end
		if next(props) == nil then return nil end
		local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad), props)
		tween:Play()
		return tween
	end

	local function HasTransparencyProperty(obj)
		return obj:IsA("GuiObject")
	end

	local function Resolve(v)
		return typeof(v) == "function" and v(LOCAL_PLAYER) or v
	end

	local nodeData = currentNodeName == nil and dialog or dialog.nodes[currentNodeName]
	if not nodeData then return end

	local npcText = Resolve(nodeData.npcText) or ""

	-- FIRST TIME OPEN: fade in NPC name + liner
	if firstOpen then
		NPC_Name.TextTransparency = 1
		Liner.ImageTransparency = 1
		SafeFade(NPC_Name, { TextTransparency = 0 }, 0.5)
		SafeFade(Liner, { ImageTransparency = 0 }, 0.5).Completed:Wait()
	end

	----------------------------------------------------
	-- FADE OUT OLD TEXT AND BUTTONS
	----------------------------------------------------
	local oldButtons = {}
	for _, child in ipairs(OptionsFrame:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(oldButtons, child)
		end
	end

	for i = #oldButtons, 1, -1 do
		local child = oldButtons[i]
		task.delay(0.1 * (#oldButtons - i), function()
			for _, desc in ipairs(child:GetDescendants()) do
				if HasTransparencyProperty(desc) and not CollectionService:HasTag(desc, "Dont") then
					local fadeProps = {}
					if desc.BackgroundTransparency ~= nil then fadeProps.BackgroundTransparency = 1 end
					if desc:IsA("TextLabel") then fadeProps.TextTransparency = 1 end
					if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
						fadeProps.ImageTransparency = 1
						fadeProps.BackgroundTransparency = 1
					end
					SafeFade(desc, fadeProps, 0.15)
				end
			end
		end)
	end

	if #oldButtons > 0 then
		task.wait(0.15 + 0.1 * #oldButtons)
	end

	for _, child in ipairs(oldButtons) do child:Destroy() end

	if NPC_Text.Text ~= "" then
		SafeFade(NPC_Text, { TextTransparency = 1 }, 0.15).Completed:Wait()
	end
	NPC_Text.Text = ""
	NPC_Text.TextTransparency = 0

	----------------------------------------------------
	-- TYPE NEW NPC TEXT
	----------------------------------------------------
	local textFuture = FunctionUtils.Interface.animateText(NPC_Text, nil, npcText)

	----------------------------------------------------
	-- HANDLE END OF DIALOG (no options)
	----------------------------------------------------
	if not nodeData.options then
		textFuture:After(function()
			if isExiting then return end
			isExiting = true
			NPC_Text.MaxVisibleGraphemes = -1
			if textFuture.Cancel then textFuture:Cancel() end

			local fadeTime = 0.75
			for _, obj in ipairs(InteractionFrame:GetDescendants()) do
				if HasTransparencyProperty(obj) and not CollectionService:HasTag(obj, "Dont") then
					local fadeProps = {}
					if obj:IsA("Frame") then fadeProps.BackgroundTransparency = 1 end
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then fadeProps.TextTransparency = 1 end
					if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
						fadeProps.ImageTransparency = 1
						fadeProps.BackgroundTransparency = 1
					end
					SafeFade(obj, fadeProps, fadeTime)
				end
			end

			task.wait(fadeTime)
			gui.Enabled = false
			gui:SetAttribute("HasOpened", nil)
			GuiInitializer.DialogExitSignal:Fire()
		end)
		return
	end

	----------------------------------------------------
	-- CREATE NEW OPTION BUTTONS (invisible)
	----------------------------------------------------
	local function TweenScale(obj, scale, time)
		local ti = TweenInfo.new(time, Enum.EasingStyle.Quad)
		if not obj:FindFirstChild("_OriginalSize") then
			local originalSize = Instance.new("Vector3Value")
			originalSize.Name = "_OriginalSize"
			originalSize.Value = Vector3.new(obj.Size.X.Offset + obj.Size.X.Scale * obj.Parent.AbsoluteSize.X,
				obj.Size.Y.Offset + obj.Size.Y.Scale * obj.Parent.AbsoluteSize.Y)
			originalSize.Parent = obj
		end

		local original = obj._OriginalSize.Value
		local parentSize = obj.Parent.AbsoluteSize
		local goalSize = UDim2.new(
			(original.X / parentSize.X) * scale, 0,
			(original.Y / parentSize.Y) * scale, 0
		)

		TweenService:Create(obj, ti, { Size = goalSize }):Play()
	end

	local function TweenColor(frame, color, time)
		local ti = TweenInfo.new(time, Enum.EasingStyle.Quad)
		TweenService:Create(frame, ti, { BackgroundColor3 = color }):Play()
	end

	local newButtons = {}
	for i, opt in ipairs(nodeData.options) do
		local btn = optionTempleteClone:Clone() -- USE CLONED TEMPLATE
		btn.Parent = OptionsFrame
		btn.Visible = true
		btn.TextFrame.Text.Text = Resolve(opt.text)

		if btn:FindFirstChild("Button") then
			btn.Button.Active = false
			btn.Button.AutoButtonColor = false
		end

		for _, d in ipairs(btn:GetDescendants()) do
			if HasTransparencyProperty(d) and not CollectionService:HasTag(d, "Dont") then
				if d.BackgroundTransparency ~= nil then d.BackgroundTransparency = 1 end
				if d:IsA("TextLabel") then d.TextTransparency = 1 end
				if d:IsA("ImageLabel") or d:IsA("ImageButton") then
					d.ImageTransparency = 1
					d.BackgroundTransparency = 1
				end
			end
		end

		local btnClass = ButtonClass.new(btn.Button, {
			AutoDeselect = true,
			OneClick = false,
			ClickSound = nil,
			HoverSound = nil
		})

		btnClass:ModifyTheme("Hover", {
			Callbacks = {
				Enter = function(self)
					TweenScale(btn, 1.2, 0.15)
					local f1 = btn:FindFirstChild("Frame1")
					local f2 = btn:FindFirstChild("Frame2")
					if f1 then TweenColor(f1, Color3.fromRGB(158, 0, 3), 0.15) end
					if f2 then TweenColor(f2, Color3.fromRGB(158, 0, 3), 0.15) end
				end,

				Exit = function(self)
					TweenScale(btn, 1, 0.15)
					local f1 = btn:FindFirstChild("Frame1")
					local f2 = btn:FindFirstChild("Frame2")
					if f1 then TweenColor(f1, Color3.fromRGB(255, 255, 255), 0.15) end
					if f2 then TweenColor(f2, Color3.fromRGB(255, 255, 255), 0.15) end
				end,
			}
		})

		table.insert(newButtons, {
			btn = btn,
			btnClass = btnClass,
			opt = opt,
		})
	end

	----------------------------------------------------
	-- FADE IN OPTION BUTTONS AFTER TEXT FINISHES
	----------------------------------------------------
	textFuture:After(function()
		if isExiting then return end

		for i, btnData in ipairs(newButtons) do
			task.delay(0.1 * (i - 1), function()
				if isExiting then return end

				for _, d in ipairs(btnData.btn:GetDescendants()) do
					if HasTransparencyProperty(d) and not CollectionService:HasTag(d, "Dont") then
						local fadeProps = {}
						if d.BackgroundTransparency ~= nil then fadeProps.BackgroundTransparency = 0 end
						if d:IsA("TextLabel") then fadeProps.TextTransparency = 0 end
						if d:IsA("ImageLabel") or d:IsA("ImageButton") then fadeProps.ImageTransparency = 0 end
						SafeFade(d, fadeProps, 0.2)
					end
				end

				task.delay(0.2, function()
					if isExiting then return end
					if btnData.btn:FindFirstChild("Button") then
						btnData.btn.Button.Active = true
						btnData.btn.Button.AutoButtonColor = true
					end
				end)
			end)
		end
	end)

	----------------------------------------------------
	-- CLICK HANDLERS
	----------------------------------------------------
	for _, data in ipairs(newButtons) do
		data.btnClass.Signals.Activated:Connect(function()
			if isExiting then return end
			isExiting = true

			local opt = data.opt

			if opt.onSelect then opt.onSelect(LOCAL_PLAYER) end
			if opt.onExit then opt.onExit(LOCAL_PLAYER) end
			if textFuture.Cancel then textFuture:Cancel() end

			for _, oldData in ipairs(newButtons) do
				if oldData.btnClass then oldData.btnClass:Destroy() end
			end
			table.clear(newButtons)

			if opt.next == nil then
				NPC_Text.MaxVisibleGraphemes = -1
				local fadeTime = 0.75
				for _, obj in ipairs(InteractionFrame:GetDescendants()) do
					if HasTransparencyProperty(obj) then
						local fadeProps = {}
						if obj:IsA("Frame") then fadeProps.BackgroundTransparency = 1 end
						if obj:IsA("TextLabel") then fadeProps.TextTransparency = 1 end
						if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
							fadeProps.ImageTransparency = 1
							fadeProps.BackgroundTransparency = 1
						end
						SafeFade(obj, fadeProps, fadeTime)
					end
				end

				task.wait(fadeTime)
				gui.Enabled = false
				gui:SetAttribute("HasOpened", nil)
				GuiInitializer.DialogExitSignal:Fire()
			else
				GuiInitializer.BindDialog(gui, dialog, opt.next)
			end
		end)
	end
end



--function GuiInitializer.BindDialog(gui: ScreenGui, dialog: any, currentNodeName: string)
--	gui.Enabled = true
--	local firstOpen = not gui:GetAttribute("HasOpened")
--	if firstOpen then
--		gui:SetAttribute("HasOpened", true)
--	end

--	local InteractionFrame = gui.IntractionFrame
--	local NPC_Name = InteractionFrame.NPC_Text_Frame.NPC_Name
--	local NPC_Text = InteractionFrame.NPC_Text_Frame.NPC_Text
--	local Liner = InteractionFrame.NPC_Text_Frame.Liner.ImageLabel
--	local OptionsFrame = InteractionFrame.Options
--	local ButtonTemplate = OptionsFrame.ButtonFrame
--	ButtonTemplate.Visible = false

--	-- Flag to check if dialog is exiting
--	local isExiting = false

--	local function SafeFade(obj, targetProps, duration)
--		local props = {}

--		for key, value in pairs(targetProps) do
--			if obj:IsA("TextLabel") or obj:IsA("TextButton") then
--				if key == "TextTransparency" or key == "BackgroundTransparency" then
--					props[key] = value
--				end
--			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
--				if key == "ImageTransparency" or key == "BackgroundTransparency" then
--					props[key] = value
--				end
--			elseif obj:IsA("Frame") then
--				if key == "BackgroundTransparency" then
--					props[key] = value
--				end
--			end
--		end

--		if next(props) == nil then
--			return nil
--		end

--		local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad), props)
--		tween:Play()
--		return tween
--	end

--	local function HasTransparencyProperty(obj)
--		return obj:IsA("GuiObject") and (
--			obj.BackgroundTransparency ~= nil or
--				(obj:IsA("TextLabel") or obj:IsA("TextButton")) or
--				(obj:IsA("ImageLabel") or obj:IsA("ImageButton"))
--		)
--	end

--	----------------------------------------------------
--	-- Resolve dialog node
--	----------------------------------------------------
--	local function Resolve(v)
--		return typeof(v) == "function" and v(LOCAL_PLAYER) or v
--	end

--	local nodeData = currentNodeName == nil and dialog or dialog.nodes[currentNodeName]
--	if not nodeData then return end

--	local npcText = Resolve(nodeData.npcText) or ""

--	----------------------------------------------------
--	-- FIRST TIME OPEN → fade-in liner + NPC name
--	----------------------------------------------------
--	if firstOpen then
--		NPC_Name.TextTransparency = 1
--		Liner.ImageTransparency = 1

--		SafeFade(NPC_Name, { TextTransparency = 0 }, 0.5)
--		SafeFade(Liner, { ImageTransparency = 0 }, 0.5).Completed:Wait()
--	end

--	----------------------------------------------------
--	-- TEXT CHANGE ANIMATION
--	----------------------------------------------------
--	-- Fade old text away
--	if NPC_Text.Text ~= "" then
--		SafeFade(NPC_Text, { TextTransparency = 1 }, 0.15).Completed:Wait()
--	end
--	NPC_Text.Text = ""
--	NPC_Text.TextTransparency = 0

--	----------------------------------------------------
--	-- FADE OUT OLD OPTION BUTTONS (bottom to top)
--	----------------------------------------------------
--	local oldButtons = {}
--	for _, child in ipairs(OptionsFrame:GetChildren()) do
--		if child:IsA("Frame") and child ~= ButtonTemplate then
--			table.insert(oldButtons, child)
--		end
--	end

--	-- Reverse order for bottom-to-top fade
--	for i = #oldButtons, 1, -1 do
--		local child = oldButtons[i]
--		task.delay(0.1 * (#oldButtons - i), function()
--			for _, desc in ipairs(child:GetDescendants()) do
--				if HasTransparencyProperty(desc) and not CollectionService:HasTag(desc, "Dont") then
--					local fadeProps = {}
--					if desc.BackgroundTransparency ~= nil then
--						fadeProps.BackgroundTransparency = 1
--					end
--					if desc:IsA("TextLabel") then
--						fadeProps.TextTransparency = 1
--					end
--					if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
--						fadeProps.ImageTransparency = 1
--						fadeProps.BackgroundTransparency = 1
--					end
--					SafeFade(desc, fadeProps, 0.15)
--				end
--			end
--		end)
--	end

--	-- Wait for all buttons to fade
--	if #oldButtons > 0 then
--		task.wait(0.15 + (0.1 * #oldButtons))
--	end

--	-- Destroy old buttons
--	for _, child in ipairs(oldButtons) do
--		child:Destroy()
--	end

--	----------------------------------------------------
--	-- Type new text
--	----------------------------------------------------
--	local textFuture = FunctionUtils.Interface.animateText(NPC_Text, nil, npcText)

--	----------------------------------------------------
--	-- EXIT IF NO OPTIONS (end of dialog)
--	----------------------------------------------------
--	if not nodeData.options then
--		-- Wait for text to finish
--		textFuture:After(function()
--			if isExiting then return end
--			isExiting = true

--			-- Stop text animation
--			NPC_Text.MaxVisibleGraphemes = -1

--			if textFuture and textFuture.Cancel then
--				textFuture:Cancel()
--			end

--			-- Fade entire UI out simultaneously
--			local fadeTime = 0.75
--			for _, obj in ipairs(InteractionFrame:GetDescendants()) do
--				if HasTransparencyProperty(obj) and not CollectionService:HasTag(obj, "Dont") then
--					local fadeProps = {}
--					if obj:IsA("Frame") then
--						fadeProps.BackgroundTransparency = 1
--					end
--					if obj:IsA("TextLabel") then
--						fadeProps.TextTransparency = 1
--					end
--					if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
--						fadeProps.ImageTransparency = 1
--						fadeProps.BackgroundTransparency = 1
--					end
--					SafeFade(obj, fadeProps, fadeTime)
--				end
--			end

--			task.wait(fadeTime)
--			gui.Enabled = false
--			gui:SetAttribute("HasOpened", nil)
--			GuiInitializer.DialogExitSignal:Fire()
--		end)
--		return
--	end

--	----------------------------------------------------
--	-- CREATE NEW OPTION BUTTONS (all at once, invisible)
--	----------------------------------------------------
--	local newButtons = {}
--	for i, opt in ipairs(nodeData.options) do
--		local btn = (i == 1) and ButtonTemplate or ButtonTemplate:Clone()
--		btn.Parent = OptionsFrame
--		btn.Visible = true  -- Keep invisible until ready
--		btn.TextFrame.Text.Text = Resolve(opt.text)

--		-- Disable button interaction until visible
--		if btn:FindFirstChild("Button") then
--			btn.Button.Active = false
--			btn.Button.AutoButtonColor = false
--		end

--		-- Start all elements invisible
--		for _, d in ipairs(btn:GetDescendants()) do
--			if HasTransparencyProperty(d) and not CollectionService:HasTag(d, "Dont") then
--				if d.BackgroundTransparency ~= nil and not CollectionService:HasTag(d, "Dont") then
--					d.BackgroundTransparency = 1
--				end
--				if d:IsA("TextLabel") then
--					d.TextTransparency = 1
--				end
--				if d:IsA("ImageLabel") or d:IsA("ImageButton") then
--					d.ImageTransparency = 1
--					d.BackgroundTransparency = 1
--				end
--			end
--		end

--		table.insert(newButtons, { btn = btn, opt = opt })
--	end

--	----------------------------------------------------
--	-- FADE IN BUTTONS AFTER TEXT COMPLETES (top to bottom)
--	----------------------------------------------------
--	textFuture:After(function()
--		if isExiting then return end

--		for i, btnData in ipairs(newButtons) do
--			task.delay(0.1 * (i - 1), function()
--				if isExiting then return end

--				for _, d in ipairs(btnData.btn:GetDescendants()) do
--					if HasTransparencyProperty(d) and not CollectionService:HasTag(d, "Dont") then
--						local fadeProps = {}

--						if d.BackgroundTransparency ~= nil and not CollectionService:HasTag(d, "Dont") then
--							fadeProps.BackgroundTransparency = 0
--						end
--						if d:IsA("TextLabel") then
--							fadeProps.TextTransparency = 0
--							fadeProps.BackgroundTransparency = nil
--						end
--						if d:IsA("ImageLabel") or d:IsA("ImageButton") then
--							fadeProps.ImageTransparency = 0
--						end

--						SafeFade(d, fadeProps, 0.2)
--					end
--				end

--				-- Enable button interaction after fade completes
--				task.delay(0.2, function()
--					if isExiting then return end
--					if btnData.btn:FindFirstChild("Button") then
--						btnData.btn.Button.Active = true
--						btnData.btn.Button.AutoButtonColor = true
--					end
--				end)
--			end)
--		end
--	end)

--	----------------------------------------------------
--	-- CLICK HANDLERS
--	----------------------------------------------------
--	for _, btnData in ipairs(newButtons) do
--		local btn = btnData.btn
--		local opt = btnData.opt
--		btn.Button.MouseButton1Click:Connect(function()
--			if isExiting then return end

--			isExiting = true

--			if opt.onSelect then opt.onSelect(LOCAL_PLAYER) end
--			if opt.onExit then opt.onExit(LOCAL_PLAYER) end

--			if textFuture and textFuture.Cancel then
--				textFuture:Cancel()
--			end

--			if opt.next == nil then
--				isExiting = true

--				-- Stop text animation
--				NPC_Text.MaxVisibleGraphemes = -1

--				-- End conversation - fade everything simultaneously
--				local fadeTime = 0.75
--				for _, obj in ipairs(InteractionFrame:GetDescendants()) do
--					if HasTransparencyProperty(obj) and not CollectionService:HasTag(obj, "Dont") then
--						local fadeProps = {}
--						if obj.BackgroundTransparency ~= nil then
--							fadeProps.BackgroundTransparency = 1
--						end
--						if obj:IsA("TextLabel") or obj:IsA("TextButton") then
--							fadeProps.TextTransparency = 1
--						end
--						if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
--							fadeProps.ImageTransparency = 1
--						end
--						SafeFade(obj, fadeProps, fadeTime)
--					end

--				end

--				task.wait(fadeTime)
--				gui.Enabled = false
--				gui:SetAttribute("HasOpened", nil)
--				GuiInitializer.DialogExitSignal:Fire()
--				return

--			else
--				GuiInitializer.BindDialog(gui, dialog, opt.next)
--			end
--		end)
--	end
--end


return GuiInitializer
