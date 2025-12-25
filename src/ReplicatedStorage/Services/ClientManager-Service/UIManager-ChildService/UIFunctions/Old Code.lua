-- button initializtion for ui inventory handling 10/9/2025



--local RockHandlerSignal = ModuleUtils.Signal.new()
--local RockModelSignal   = ModuleUtils.Signal.new()
--local RockBufferSignal  = ModuleUtils.Signal.new()
---- Later to handle must create custom Tool Tip ui to display info : Rock Type
--local RockTypeSignal  = ModuleUtils.Signal.new()

--local HealthKitSignal   = ModuleUtils.Signal.new()
--local StaminaKitSignal  = ModuleUtils.Signal.new()
--local AbilitiesKitSignal = ModuleUtils.Signal.new()

--local function setDataObserverHandler()
--	if not game.Players.LocalPlayer.Character then
--		game.Players.LocalPlayer.CharacterAdded:Wait()
--	end

--	local BackPack = game.Players.LocalPlayer:WaitForChild("Backpack")

--	-- Rock modifiers
--	local RockDataFolder = BackPack:WaitForChild("ActiveRockModifiers")
--	local HandlerData = RockDataFolder:WaitForChild("Handler")
--	local ModelData   = RockDataFolder:WaitForChild("Model")
--	local BufferData  = RockDataFolder:WaitForChild("Buffer")

--	-- Character kits
--	local KitsDataFolder = BackPack:WaitForChild("ActiveCharacterKits")
--	local HealthKitData   = KitsDataFolder:WaitForChild("Health")
--	local StaminaKitData  = KitsDataFolder:WaitForChild("Stamina")
--	local AbilitieKitData = KitsDataFolder:WaitForChild("Abilitie")

--	local function observe(dataHolder, signal)
--		return FunctionUtils.Observers.observeAttribute(dataHolder, "Name", function(value)
--			if value == nil or value == "" then
--				signal:Fire(nil) -- nil to disable tooltip
--			else
--				signal:Fire(dataHolder)
--			end
--		end)
--	end

--	observe(HandlerData, RockHandlerSignal)
--	observe(ModelData, RockModelSignal)
--	observe(BufferData, RockBufferSignal)
--	observe(HealthKitData, HealthKitSignal)
--	observe(StaminaKitData, StaminaKitSignal)
--	observe(AbilitieKitData, AbilitiesKitSignal)
--end

--function GuiInitializer.InitializeMenuAndInvButtons(GUI: ScreenGui): MenuButtonsSignal
--	setDataObserverHandler()

--	local LowerMenu = GUI.Menu.Lower_Menu_Canvas.Lower_Menu
--	local Format = FunctionUtils.Format

--	-- Core buttons
--	local CloseButton = GUI.Menu.CloseButton
--	local InvQuickAcc = LowerMenu.Inventory_Quick_Accesses
--	local KitsButton = InvQuickAcc.Kits_Button.KitsButton
--	local ModifiersButton = InvQuickAcc.Rock_Modifiers_Button.ModifiersButton
--	local AllInvantoryButton = InvQuickAcc.All_Inventory_Button.AllInventoryButton

--	-- Kits sub-buttons
--	local CenterCanves = LowerMenu.CenterCanves
--	local CharacterKits = CenterCanves.CharacterKits
--	local RocksModifiers = CenterCanves.RocksModifiers

--	local AbilitiesKitButton = CharacterKits.AbilitiesKit
--	local HealthKitButton = CharacterKits.HealthKit
--	local StaminaKitButton = CharacterKits.StaminaKit

--	-- Rock sub-buttons
--	local RockModelButton = RocksModifiers.RockModelButton
--	local RockHandlerButton = RocksModifiers.RockHandlerButton
--	local RockBufferButton = RocksModifiers.RockBufferButton
--	local RockTypeButton = RocksModifiers.RockTypeImageButton
--	local RockRegImageButton = RocksModifiers.RockImageButton

--	-- Create GuiObject classes in batch
--	local buttonInfoClasses = {
--		AbilitiesKit = GuiObjectClass.new(AbilitiesKitButton),
--		HealthKit = GuiObjectClass.new(HealthKitButton),
--		StaminaKit = GuiObjectClass.new(StaminaKitButton),
--		RockModel = GuiObjectClass.new(RockModelButton),
--		RockHandler = GuiObjectClass.new(RockHandlerButton),
--		RockBuffer = GuiObjectClass.new(RockBufferButton),
--		RockType = GuiObjectClass.new(RockTypeButton),
--		RockRegImage = GuiObjectClass.new(RockRegImageButton)
--	}

--	-- Optimized tooltip connection function
--	local function connectTooltipSignal(signal, infoClass)
--		signal:Connect(function(DataHolder)
--			if not DataHolder then
--				infoClass:ToggleToolTip(false)
--				return
--			end

--			local Attributes = DataHolder:GetAttributes()
--			local name = Attributes.Name or ""
--			local itemType = Attributes.ItemType or ""

--			infoClass:ToggleToolTip(true, {
--				TitleText       = Format.addSpaceBeforeUpperCase(name),
--				DescriptionText = Attributes.Description,
--				RarityText      = Attributes.Rarity,
--				ItemTypeText    = Format.addSpaceBeforeUpperCase(itemType),
--				Style           = "INFO"
--			})
--		end)
--	end

--	-- Connect all tooltip signals
--	connectTooltipSignal(RockHandlerSignal, buttonInfoClasses.RockHandler)
--	connectTooltipSignal(RockModelSignal, buttonInfoClasses.RockModel)
--	connectTooltipSignal(RockBufferSignal, buttonInfoClasses.RockBuffer)
--	connectTooltipSignal(HealthKitSignal, buttonInfoClasses.HealthKit)
--	connectTooltipSignal(StaminaKitSignal, buttonInfoClasses.StaminaKit)
--	connectTooltipSignal(AbilitiesKitSignal, buttonInfoClasses.AbilitiesKit)

--	-- Button configuration template
--	local defaultButtonConfig = {
--		AutoDeselect = true,
--		OneClick = false,
--		ClickSound = nil,
--		HoverSound = nil,
--	}

--	-- Create Button Classes in batch
--	local buttonClasses = {
--		Close = ButtonClass.new(CloseButton, defaultButtonConfig),
--		Kits = ButtonClass.new(KitsButton, defaultButtonConfig),
--		Modifiers = ButtonClass.new(ModifiersButton, defaultButtonConfig),
--		AllInventory = ButtonClass.new(AllInvantoryButton, defaultButtonConfig),
--		AbilitiesKit = ButtonClass.new(AbilitiesKitButton, defaultButtonConfig),
--		HealthKit = ButtonClass.new(HealthKitButton, defaultButtonConfig),
--		StaminaKit = ButtonClass.new(StaminaKitButton, defaultButtonConfig),
--		RockModel = ButtonClass.new(RockModelButton, defaultButtonConfig),
--		RockHandler = ButtonClass.new(RockHandlerButton, defaultButtonConfig),
--		RockBuffer = ButtonClass.new(RockBufferButton, defaultButtonConfig),
--		RockType = ButtonClass.new(RockTypeButton, defaultButtonConfig),
--		RockReg = ButtonClass.new(RockRegImageButton, defaultButtonConfig)
--	}

--	-- Theme configurations
--	local backgroundColorTheme = function(enterColor, exitColor, withCallbacks, Button)
--		local theme = {}

--		if withCallbacks and Button then
--			theme.Callbacks = {
--				Enter = function(self)
--					TweenService:Create(
--						Button.Parent.Background,
--						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
--						{ ImageColor3 = enterColor }
--					):Play()
--				end,
--				Exit = function(self)
--					TweenService:Create(
--						Button.Parent.Background,
--						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
--						{ ImageColor3 = exitColor }
--					):Play()
--				end,
--			}
--		end

--		return theme
--	end

--	local imageColorTheme = function(enterColor, exitColor, withCallbacks)
--		local theme = {
--			Properties = {
--				Enter = { ImageColor3 = enterColor },
--				Exit  = { ImageColor3 = exitColor },
--			},
--			EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
--			ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
--		}

--		if withCallbacks then
--			theme.Callbacks = {
--				Enter = function(self)  end,
--				Exit  = function(self)  end,
--			}
--		end

--		return theme
--	end

--	-- Apply themes efficiently
--	local white = Color3.fromRGB(255, 255, 255)
--	local red = Color3.fromRGB(188, 0, 0)

--	buttonClasses.Close:ModifyTheme("Hover", backgroundColorTheme(Color3.fromRGB(199, 0, 0), white, false, CloseButton))
--	buttonClasses.Kits:ModifyTheme("Hover", backgroundColorTheme(Color3.fromRGB(18, 149, 236), white, true, KitsButton))
--	buttonClasses.Modifiers:ModifyTheme("Hover", backgroundColorTheme(Color3.fromRGB(204, 0, 0), white, true, ModifiersButton))
--	buttonClasses.AllInventory:ModifyTheme("Hover", backgroundColorTheme(Color3.fromRGB(243, 178, 14), white, true, AllInvantoryButton))

--	-- Apply image color themes with callbacks where needed
--	buttonClasses.AbilitiesKit:ModifyTheme("Hover", imageColorTheme(red, white, false))
--	buttonClasses.HealthKit:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.StaminaKit:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.RockModel:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.RockHandler:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.RockBuffer:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.RockType:ModifyTheme("Hover", imageColorTheme(red, white, true))
--	buttonClasses.RockReg:ModifyTheme("Hover", imageColorTheme(red, white, true))

--	-- Return signals
--	return {
--		QuickAccess = {
--			KitsButtonSignal = buttonClasses.Kits.Signals.Activated,
--			ModifiersButtonSignal = buttonClasses.Modifiers.Signals.Activated,
--			AllInvantoryButtonSignal = buttonClasses.AllInventory.Signals.Activated,
--		},

--		Kits = {
--			AbilitiesKitButtonSignal = buttonClasses.AbilitiesKit.Signals.Activated,
--			HealthKitButtonSignal = buttonClasses.HealthKit.Signals.Activated,
--			StaminaKitButtonSignal = buttonClasses.StaminaKit.Signals.Activated,
--		},

--		Rocks = {
--			RockModelButtonSignal = buttonClasses.RockModel.Signals.Activated,
--			RockHandlerButtonSignal = buttonClasses.RockHandler.Signals.Activated,
--			RockBufferButtonSignal = buttonClasses.RockBuffer.Signals.Activated,
--			RockTypeButtonSignal = buttonClasses.RockType.Signals.Activated,
--			RockRegButtonSignal = buttonClasses.RockReg.Signals.Activated,
--		},

--		CloseButtonSignal = buttonClasses.Close.Signals.Activated,
--	}
--end

---- Signal declarations for inventory items
--local InventoryItemSignals = {}
--local InventoryCountSignals = {}

--local NewItemFolderSignal = ModuleUtils.Signal.new()
--local ItemSelectedSignal = ModuleUtils.Signal.new()

---- Count signals for different categories
--local RockHandlerCountSignal = ModuleUtils.Signal.new()
--local RockModelCountSignal = ModuleUtils.Signal.new()
--local RockBufferCountSignal = ModuleUtils.Signal.new()
--local HealthKitCountSignal = ModuleUtils.Signal.new()
--local StaminaKitCountSignal = ModuleUtils.Signal.new()
--local AbilitiesKitCountSignal = ModuleUtils.Signal.new()

---- Store signals for export
--InventoryCountSignals.RockHandler = RockHandlerCountSignal
--InventoryCountSignals.RockModel = RockModelCountSignal
--InventoryCountSignals.RockBuffer = RockBufferCountSignal
--InventoryCountSignals.HealthKit = HealthKitCountSignal
--InventoryCountSignals.StaminaKit = StaminaKitCountSignal
--InventoryCountSignals.AbilitiesKit = AbilitiesKitCountSignal

---- Track created buttons and their cleanup functions
--local InventoryButtons = {}

--local function setInventoryDataObserverHandler()
--	if not game.Players.LocalPlayer.Character then
--		game.Players.LocalPlayer.CharacterAdded:Wait()
--	end

--	local BackPack = game.Players.LocalPlayer:WaitForChild("Backpack")
--	local InventoryFolder = BackPack:WaitForChild("Inventory")

--	-- Observer for count attributes on inventory folder
--	local function observeCountAttribute(attributeName, signal)
--		return FunctionUtils.Observers.observeAttribute(InventoryFolder, attributeName, function(value)
--			signal:Fire(value or 0)
--		end)
--	end

--	-- Set up count observers
--	observeCountAttribute("RockHandlerModifierCount", RockHandlerCountSignal)
--	observeCountAttribute("RockModelModifierCount", RockModelCountSignal)
--	observeCountAttribute("RockBufferModifierCount", RockBufferCountSignal)
--	observeCountAttribute("CharacterHealthKitCount", HealthKitCountSignal)
--	observeCountAttribute("CharacterStaminaKitCount", StaminaKitCountSignal)
--	observeCountAttribute("CharacterAbilitiesKitCount", AbilitiesKitCountSignal)

--	-- Function to create observers for individual item folders
--	local function createItemObservers(itemFolder)
--		local folderName = itemFolder.Name

--		-- Create signal for this item
--		if not InventoryItemSignals[folderName] then
--			InventoryItemSignals[folderName] = ModuleUtils.Signal.new()
--		end

--		local signal = InventoryItemSignals[folderName]

--		-- Observer for Name attribute
--		local nameObserver = FunctionUtils.Observers.observeAttribute(itemFolder, "Name", function(value)
--			if value == nil or value == "" then
--				signal:Fire(nil, folderName) -- Pass folder name for identification
--			else
--				signal:Fire(itemFolder, folderName)
--			end
--		end)

--		-- Observer for Amount attribute
--		local amountObserver = FunctionUtils.Observers.observeAttribute(itemFolder, "Amount", function(value)
--			if value == nil or value == 0 then
--				signal:Fire(nil, folderName)
--			else
--				signal:Fire(itemFolder, folderName)
--			end
--		end)

--		return nameObserver, amountObserver
--	end

--	-- Function to handle existing folders
--	local function processExistingFolders()
--		for _, child in ipairs(InventoryFolder:GetChildren()) do
--			if child:IsA("Folder") then
--				createItemObservers(child)
--			end
--		end
--	end

--	-- Process existing folders
--	processExistingFolders()

--	-- Listen for new folders being added
--	InventoryFolder.ChildAdded:Connect(function(child)
--		if child:IsA("Folder") then
--			task.wait() -- Wait for attributes to be set
--			createItemObservers(child)

--			-- Fire signal for GUI side
--			NewItemFolderSignal:Fire(child)
--		end
--	end)



--	-- Listen for folders being removed
--	InventoryFolder.ChildRemoved:Connect(function(child)
--		if child:IsA("Folder") then
--			local folderName = child.Name
--			if InventoryItemSignals[folderName] then
--				InventoryItemSignals[folderName]:Fire(nil, folderName) -- Trigger cleanup
--			end
--		end
--	end)
--end

--function GuiInitializer.InitializeQuickInventoryDataButtons(GUI: ScreenGui) : InventoryButtonsSignal
--	setInventoryDataObserverHandler()

--	local LowerMenu = GUI.Menu.Lower_Menu_Canvas.Lower_Menu
--	local AllInventoryFrame = GUI.Menu.Lower_Menu_Canvas.All_Inventory.InventoryAll

--	local InventoryListCanves = LowerMenu.Inventory_Quick_Accesses.InventoryList.CanvasGroup
--	local RockModifierScrollFrame = InventoryListCanves.RockModifiersSF
--	local CharacterKitsScrollFrame = InventoryListCanves.CharacterKitsSF

--	local RockModels_HF = RockModifierScrollFrame.RockModelsList.ItemsHolderFrame
--	local RockHandlers_HF = RockModifierScrollFrame.RockHandlersList.ItemsHolderFrame
--	local RockBuffers_HF = RockModifierScrollFrame.RockBuffersList.ItemsHolderFrame

--	local RockModels_TotalNumber = RockModifierScrollFrame.RockModelsList.TopFrame.ItemsAmount
--	local RockHandlers_TotalNumber = RockModifierScrollFrame.RockHandlersList.TopFrame.ItemsAmount
--	local RockBuffers_TotalNumber = RockModifierScrollFrame.RockBuffersList.TopFrame.ItemsAmount

--	local HealthKit_HF = CharacterKitsScrollFrame.HealthKitsList.ItemsHolderFrame
--	local StaminaKit_HF = CharacterKitsScrollFrame.StaminaKitsList.ItemsHolderFrame
--	local AbilitiesKit_HF = CharacterKitsScrollFrame.AbilitiesKitsList.ItemsHolderFrame

--	local HealthKit_TotalNumber = CharacterKitsScrollFrame.HealthKitsList.TopFrame.ItemsAmount
--	local StaminaKit_TotalNumber = CharacterKitsScrollFrame.StaminaKitsList.TopFrame.ItemsAmount
--	local AbilitiesKit_TotalNumber = CharacterKitsScrollFrame.AbilitiesKitsList.TopFrame.ItemsAmount

--	-- Set up count display observers
--	RockHandlerCountSignal:Connect(function(count)
--		RockHandlers_TotalNumber.Text = tostring(count)
--	end)

--	RockModelCountSignal:Connect(function(count)
--		RockModels_TotalNumber.Text = tostring(count)
--	end)

--	RockBufferCountSignal:Connect(function(count)
--		RockBuffers_TotalNumber.Text = tostring(count)
--	end)

--	HealthKitCountSignal:Connect(function(count)
--		HealthKit_TotalNumber.Text = tostring(count)
--	end)

--	StaminaKitCountSignal:Connect(function(count)
--		StaminaKit_TotalNumber.Text = tostring(count)
--	end)

--	AbilitiesKitCountSignal:Connect(function(count)
--		AbilitiesKit_TotalNumber.Text = tostring(count)
--	end)

--	-- Function to determine parent frame based on item attributes
--	local function getParentFrame(attributes)
--		local itemType = attributes.ItemType

--		if itemType == "RockModifire" then
--			local modifierCategory = attributes.ModifierCategory
--			if modifierCategory == "Handler" then
--				return RockHandlers_HF
--			elseif modifierCategory == "Model" then
--				return RockModels_HF
--			elseif modifierCategory == "Buffer" then
--				return RockBuffers_HF
--			end
--		elseif itemType == "Kit" then
--			local typeKit = attributes.TypeKit
--			if typeKit == "Health" then
--				return HealthKit_HF
--			elseif typeKit == "Stamina" then
--				return StaminaKit_HF
--			elseif typeKit == "Abilities" then
--				return AbilitiesKit_HF
--			end
--		end

--		-- Default to AllInventoryFrame for unknown types
--		return nil
--	end

--	-- Function to create button for item
--	local function createItemButton(itemFolder, folderName)
--		local attributes = itemFolder:GetAttributes()
--		local parentFrame = getParentFrame(attributes)

--		-- Create main button
--		local imageButton = Instance.new("ImageButton")
--		imageButton.BackgroundTransparency = 1
--		imageButton.Name = folderName .. "_Button"
--		imageButton.Image = "rbxassetid://124692060751675"

--		-- Create replica for AllInventoryFrame
--		local replicaButton = imageButton:Clone()
--		replicaButton.Name = folderName .. "_AllButton"
--		replicaButton.Parent = AllInventoryFrame

--		-- Parent main button appropriately
--		if parentFrame then
--			imageButton.Parent = parentFrame
--		else
--			imageButton.Parent = AllInventoryFrame
--		end

--		-- Create button classes
--		local mainButtonClass = ButtonClass.new(imageButton, {
--			AutoDeselect = true,
--			OneClick = false,
--			ClickSound = nil,
--			HoverSound = nil,
--		})

--		local replicaButtonClass = ButtonClass.new(replicaButton, {
--			AutoDeselect = true,
--			OneClick = false,
--			ClickSound = nil,
--			HoverSound = nil,
--		})

--		-- Apply hover themes
--		local hoverTheme = {
--			Properties = {
--				Enter = { ImageColor3 = Color3.fromRGB(188, 0, 0) },
--				Exit  = { ImageColor3 = Color3.fromRGB(255, 255, 255) },
--			},
--			EnterTweenInfo = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
--			ExitTweenInfo  = { ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad) },
--			Callbacks = {
--				Enter = function(self)  end,
--				Exit  = function(self)  end,
--			}
--		}

--		local selectTheme = {
--			Properties = {
--				Enter = {
--					ImageColor3 = Color3.fromRGB(188, 0, 0),
--				},
--				Exit = {
--					ImageColor3 = Color3.fromRGB(255, 255, 255),
--				},
--			},
--			EnterTweenInfo = {
--				ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
--			},
--			ExitTweenInfo = {
--				ImageColor3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
--			},
--			Callbacks = {
--				Enter = function(self)
--					ItemSelectedSignal:Fire(self._button.Name, true)
--				end,
--				Exit = function(self)
--					ItemSelectedSignal:Fire(self._button.Name, false)
--				end,
--			}
--		}

--		mainButtonClass:ModifyTheme("Hover", hoverTheme)
--		replicaButtonClass:ModifyTheme("Hover", hoverTheme)

--		mainButtonClass:ModifyTheme("Selection", selectTheme)
--		replicaButtonClass:ModifyTheme("Selection", selectTheme)

--		-- Create tooltip classes
--		local mainButtonINFO = GuiObjectClass.new(imageButton)
--		local replicaButtonINFO = GuiObjectClass.new(replicaButton)

--		-- Function to update tooltips
--		local function updateTooltips(dataHolder)
--			if not dataHolder then
--				mainButtonINFO:ToggleToolTip(false)
--				replicaButtonINFO:ToggleToolTip(false)
--				return
--			end

--			local currentAttributes = dataHolder:GetAttributes()
--			local Format = FunctionUtils.Format

--			local name = currentAttributes.Name or ""
--			local itemType = currentAttributes.ItemType or ""

--			local tooltipData = {
--				TitleText       = Format.addSpaceBeforeUpperCase(name),
--				DescriptionText = currentAttributes.Description,
--				RarityText      = currentAttributes.Rarity,
--				ItemTypeText    = Format.addSpaceBeforeUpperCase(itemType),
--				Style           = "INFO"
--			}

--			mainButtonINFO:ToggleToolTip(true, tooltipData)
--			replicaButtonINFO:ToggleToolTip(true, tooltipData)
--		end

--		-- Store button info for cleanup
--		InventoryButtons[folderName] = {
--			mainButton = imageButton,
--			replicaButton = replicaButton,
--			mainButtonClass = mainButtonClass,
--			replicaButtonClass = replicaButtonClass,
--			mainButtonINFO = mainButtonINFO,
--			replicaButtonINFO = replicaButtonINFO,
--			updateTooltips = updateTooltips
--		}

--		-- Initial tooltip setup
--		updateTooltips(itemFolder)

--		return InventoryButtons[folderName]
--	end

--	-- Function to cleanup button
--	local function cleanupButton(folderName)
--		local buttonInfo = InventoryButtons[folderName]
--		if buttonInfo then
--			-- Destroy GUI elements
--			if buttonInfo.mainButton then
--				buttonInfo.mainButton:Destroy()
--			end
--			if buttonInfo.replicaButton then
--				buttonInfo.replicaButton:Destroy()
--			end

--			-- Clear from tracking
--			InventoryButtons[folderName] = nil
--		end
--	end

--	-- Connect to all existing and future item signals
--	local function connectToItemSignal(folderName)
--		if InventoryItemSignals[folderName] then
--			InventoryItemSignals[folderName]:Connect(function(dataHolder, signalFolderName)
--				if not dataHolder then
--					-- Cleanup button
--					cleanupButton(signalFolderName)
--				else
--					-- Create or update button
--					local buttonInfo = InventoryButtons[signalFolderName]
--					if not buttonInfo then
--						createItemButton(dataHolder, signalFolderName)
--					else
--						-- Update existing tooltips
--						buttonInfo.updateTooltips(dataHolder)
--					end
--				end
--			end)
--		end
--	end

--	-- Connect to existing signals
--	for folderName, signal in pairs(InventoryItemSignals) do
--		connectToItemSignal(folderName)
--	end

--	-- Watch for new signals being created
--	local originalSignalNew = InventoryItemSignals
--	setmetatable(InventoryItemSignals, {
--		__newindex = function(t, k, v)
--			rawset(t, k, v)
--			connectToItemSignal(k)
--		end
--	})

--	-- Handler if new inventory item folder is added
--	NewItemFolderSignal:Connect(function(child)
--		local folderName = child.Name

--		-- The signal creation is already handled by setInventoryDataObserverHandler
--		-- So here we just connect UI when the new signal appears
--		if InventoryItemSignals[folderName] then
--			connectToItemSignal(folderName)
--		end
--	end)

--	-- Return button signals for external use
--	local buttonSignals = {}
--	for folderName, buttonInfo in pairs(InventoryButtons) do
--		if buttonInfo.mainButtonClass and buttonInfo.replicaButtonClass then
--			buttonSignals[folderName] = {
--				MainButtonSignal = buttonInfo.mainButtonClass.Signals.Activated,
--				ReplicaButtonSignal = buttonInfo.replicaButtonClass.Signals.Activated,
--			}
--		end
--	end

--	return {
--		Buttons = buttonSignals,
--		ItemSelectedSignal = ItemSelectedSignal
--	}

--end