--strict
--@author: IronBeliever
--@date: 8/28/25
--[[@description:
	A Service hybrid handler for all client input manager for (UI, Motion, Intraction) services.
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePadService = game:GetService("GamepadService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-----------------------------
-- DEPENDENCIES --
-----------------------------
local Motion_Service = require(script["Motion-ChildService"])
local OTS_Service = require(script["OTS-Camera-ChildService"])
local UIManager_Service = require(script["UIManager-ChildService"])
local RockAim_ChildService = require(script["RockAim-ChildService"])
local Intraction_ChildService = require(script["Intraction-ChildService"])

local ClientModuleUtils = require(ReplicatedStorage.Utilities.ClientModuleUtils)
local FunctionUtils = require(ReplicatedStorage.Utilities.FunctionUtils)
local ModuleUtils = require(ReplicatedStorage.Utilities.ModuleUtils)

local Input = ClientModuleUtils.Input
local Game = FunctionUtils.Game

local EquipeItemEvent = ReplicatedStorage.Events.UI.EquipItem
local UnEquipeItemEvent = ReplicatedStorage.Events.UI.UnEquipItem

local DisableMovement = ReplicatedStorage.Events.Motion.DisableMovment
local EnableMovement = ReplicatedStorage.Events.Motion.EnableMovment

local Client_SetIntractionUI = ReplicatedStorage.Events.UI.Client_SetIntractionUI

-----------------------------
-- TYPES --
-----------------------------

-- This is for the OTS-Camera-Service returned functions for input handling.
export type OTSFunctionsTable = {
	SetShoulderDirection: (shoulderDirection: number) -> (),
	SetMouseStep: (steppedIn: boolean) -> (),
	SetActiveCameraSettings: (cameraSettings: string) -> (),
}



-----------------------------
-- VARIABLES --
-----------------------------

-- CONSTANTS --
local LOCAL_PLAYER = game.Players.LocalPlayer

local Service = {}

local Mouse_Input
local Keyboard_Input
local Mobile_Input
local Console_Input
local GUISignals
local DeviceType


-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function GetTool()
	local backpack = LOCAL_PLAYER:FindFirstChild("Backpack")
	local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()

	if not backpack then return nil end

	-- Try to find in character first (if equipped)
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		return tool
	end

	-- Otherwise, look in backpack
	tool = backpack:FindFirstChildOfClass("Tool")
	if tool then
		return tool
	end

	-- Fallback to WaitForChild, but only if you *know* it's being added soon
	return backpack:WaitForChild("Tool", 2) -- timeout avoids infinite yield
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function Service:GiveGamePadVibration(timer :number, power: number)

end

function Service:Init()
	
	local SettingsUiOpened = false
	
	-- Disable roblox default health bar and backpack
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	--Yield until the player's character is loaded
	Game.waitWithTimeout(LOCAL_PLAYER.CharacterAdded, -1)
	local OTSFunctionsTable : OTSFunctionsTable = OTS_Service:Enable()
	local MotionFunctionsTable = Motion_Service:Init(OTS_Service)


	OTSFunctionsTable.SetMouseStep(false)

	GUISignals = UIManager_Service:Init(Input.PreferredInput.Current)

	GUISignals.DisableTouchInputSignal:Connect(function()
		OTS_Service:DisableMobileInput()
		warn("Disabled input")
	end)

	GUISignals.EnableTouchInputSignal:Connect(function()
		OTS_Service:EnableMobileInput()
		warn("Enabled input")
	end)

	GUISignals.EnableConsoleInputSignal:Connect(function()
		--Enables camera movement for controller
		OTS_Service:EnableControllerInput()
		GuiService.GuiNavigationEnabled = false
	end)
	
	Client_SetIntractionUI.Event:Connect(function(a_table_data_ui_spsification, NPC_Name)
		-- disable player movement and disable mobile input if Touch
		DisableMovement:FireServer()
		if DeviceType == "Touch" then
			OTS_Service:DisableMobileInput()
		else
			OTS_Service:DisableMouseInput()
			OTSFunctionsTable.SetMouseStep(false)
		end
		-- set camera 
		OTS_Service:SetActiveCameraSettings("NPC_Intraction")
		OTS_Service:CenterCameraYAxis(0.5)
		
		local reEnablePromptSignal = Intraction_ChildService.PromptSignals[NPC_Name]
		
		UIManager_Service:SetIntractionUI(a_table_data_ui_spsification, reEnablePromptSignal)
	end)
	
	GUISignals.EndNPCIntractionSignal:Connect(function()
		EnableMovement:FireServer()
		if DeviceType == "Touch" then
			OTS_Service:EnableMobileInput()
		else
			-- set to true if client used to have it centered
			OTSFunctionsTable.SetMouseStep(true)
			OTS_Service:EnableMouseInput()
		end
		-- set camera 
		OTS_Service:SetActiveCameraSettings("DefaultShoulder")
	end)

	-- input signals for Mobile user buttons
	local SlideButtonSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	local SprintButtonStartSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	local SprintButtonEndSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	local EquipButtonSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	local AimButtonSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()
	local JumpButtonSignal: ModuleUtils.Signal<any> = ModuleUtils.Signal.new()


	local function CreateServices(newType :string)
		local MouseCentered = true -- if true then disabled alse enabled camera centered.
		--OTSFunctionsTable.SetMouseStep(false) -- just disables mouse center
		local MenuUiOpened = false
		local equipedTool = false
		
		DeviceType = newType

		UIManager_Service:ChangedDevice(newType)

		if Mouse_Input then Mouse_Input:Destroy() Mouse_Input = nil end
		if Keyboard_Input then Keyboard_Input:Destroy() Keyboard_Input = nil end
		if Mobile_Input then Mobile_Input:Destroy() Mobile_Input = nil end
		if Console_Input then Console_Input:Destroy() Console_Input = nil end

		if newType == "MouseKeyboard" then
			-- Add a handler only if mouse and keyborad for close menu button
			-- to enable center camera, as opning menu disables it.
			GUISignals.EnableMouseKeyboardInputSignal:Connect(function()
				if MouseCentered  then
					OTSFunctionsTable.SetMouseStep(true)
				end
				MenuUiOpened = false
			end)

			Mouse_Input = Input.Mouse.new()
			Keyboard_Input = Input.Keyboard.new()

			Mouse_Input.RightDown:Connect(function()
				OTSFunctionsTable.SetActiveCameraSettings("ZoomedShoulder", Motion_Service.IsPlayerSilding())
				RockAim_ChildService:Start(LOCAL_PLAYER.Character:FindFirstChildOfClass("Tool"))

			end)

			Mouse_Input.RightUp:Connect(function()
				OTSFunctionsTable.SetActiveCameraSettings("DefaultShoulder")
				RockAim_ChildService:Stop()
			end)

			Keyboard_Input.KeyDown:Connect(function(keyCode, wasProcessed)
				if keyCode == Enum.KeyCode.B then
					OTSFunctionsTable.SetMouseStep(not MouseCentered)
					MouseCentered = not MouseCentered
				end

				if keyCode == Enum.KeyCode.One  then
					local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()

					if not equipedTool then
						local backpack = LOCAL_PLAYER:FindFirstChild("Backpack")
						local tool = backpack:WaitForChild("Tool")
						tool.Parent = character						equipedTool = true
					else
						character.Humanoid:UnequipTools()
						equipedTool = false
					end
				end

				if keyCode == Enum.KeyCode.Tab then
					if not MenuUiOpened then
						UIManager_Service:OpenMenu()
						MenuUiOpened = true
						
						DisableMovement:FireServer()

						OTSFunctionsTable.SetMouseStep(false)

					else
						UIManager_Service:CloseMenu()
						
						EnableMovement:FireServer()
						
						if UIManager_Service:IsInventoryOpen() then
							UIManager_Service:BackToMenu()
						end
						if MouseCentered then
							OTSFunctionsTable.SetMouseStep(true)
						end
						MenuUiOpened = false
					end
				end

				if keyCode == Enum.KeyCode.Q then
					local ItemButtonName = UIManager_Service:IsItemButtonSelected()
					if ItemButtonName and ItemButtonName ~= nil then
						local parts = string.split(ItemButtonName, "_")
						local ItemName = parts[1]
						local ItemIndex = tonumber(parts[2])
						local SuccessMessege = EquipeItemEvent:InvokeServer(ItemName, ItemIndex)
						warn(SuccessMessege)
					end
				end

				if keyCode == Enum.KeyCode.E then
					local ItemButtonName = UIManager_Service:IsEquipedItemButtonSelected()
					if ItemButtonName then
						-- Decide which ItemType based on keywords in ItemButtonName
						local ItemType
						if string.find(ItemButtonName, "Buffer") then
							ItemType = "Buffer"
						elseif string.find(ItemButtonName, "Model") then
							ItemType = "Model"
						elseif string.find(ItemButtonName, "Handler") then
							ItemType = "Handler"
						elseif string.find(ItemButtonName, "Health") then
							ItemType = "Health"
						elseif string.find(ItemButtonName, "Stamina") then
							ItemType = "Stamina"
						elseif string.find(ItemButtonName, "Abilities") then
							ItemType = "Abilities"
						else
							warn("No matching item type found for:", ItemButtonName)
							return
						end
						-- Call server
						local SuccessMessage = UnEquipeItemEvent:InvokeServer(ItemType)
						warn(SuccessMessage)
					end
				end

				if keyCode == Enum.KeyCode.G then
					OTSFunctionsTable.SetShoulderDirection(1)
				end

				if keyCode == Enum.KeyCode.H then
					OTSFunctionsTable.SetShoulderDirection(-1)
				end

				if keyCode == Enum.KeyCode.LeftShift then
					MotionFunctionsTable.StartSprint()
				end

				if keyCode == Enum.KeyCode.V then
					if Motion_Service.IsPlayerMoving() then
						MotionFunctionsTable.StartSlide()
					end
				end

				if keyCode == Enum.KeyCode.Space then
					if MotionFunctionsTable.IsPlayerSliding() then
						MotionFunctionsTable.SpearJump()
					end
				end
			end)

			Keyboard_Input.KeyUp:Connect(function(keyCode, wasProcessed)
				if keyCode == Enum.KeyCode.LeftShift then
					MotionFunctionsTable.StopSprint()
				end

				if keyCode == Enum.KeyCode.V then
					MotionFunctionsTable.StopSlideHold()
				end

			end)

		elseif newType == "Gamepad" then
			-- disable camera center 
			OTSFunctionsTable.SetMouseStep(false)

			Console_Input = Input.Gamepad.new()
			Console_Input.ButtonDown:Connect(function(button: Enum.KeyCode, processed: boolean)

				if button == Enum.KeyCode.ButtonL2 then
					OTSFunctionsTable.SetActiveCameraSettings("ZoomedShoulder", Motion_Service.IsPlayerSilding())
					RockAim_ChildService:Start(LOCAL_PLAYER.Character:FindFirstChildOfClass("Tool"))
				end

				if button == Enum.KeyCode.ButtonL3 then
					MotionFunctionsTable.StartSprint()
				end

				if button == Enum.KeyCode.ButtonB then
					MotionFunctionsTable.StartSlide()
				end

				if button == Enum.KeyCode.ButtonA then
					if MotionFunctionsTable.IsPlayerSliding() then
						MotionFunctionsTable.SpearJump()
					end
				end

				--if button == Enum.KeyCode.DPadUp then
				--	if not MenuUiOpened then
				--		UIManager_Service:OpenMenu()
				--		MenuUiOpened = true
				--		GuiService.GuiNavigationEnabled = true
				--		--Disable camera movement for controller
				--		OTS_Service:DisableControllerInput()
				--	else
				--		if not UIManager_Service:IsInventoryOpen() then
				--			UIManager_Service:GoToInventory()
				--		end
				--	end
				--end

				--if button == Enum.KeyCode.DPadDown then
				--	if MenuUiOpened then
				--		if not UIManager_Service:IsInventoryOpen() then
				--			UIManager_Service:CloseMenu()
				--			MenuUiOpened = false

				--			GuiService.GuiNavigationEnabled = false
				--			--Enables camera movement for controller
				--			OTS_Service:EnableControllerInput()
				--		else
				--			UIManager_Service:BackToMenu()
				--		end
				--	end
				--end

				-- Start button = toggle menu
				if button == Enum.KeyCode.ButtonStart then
					if not MenuUiOpened then
						-- Open menu
						UIManager_Service:OpenMenu()
						
						EnableMovement:FireServer()
						
						MenuUiOpened = true
						GuiService.GuiNavigationEnabled = true
						OTS_Service:DisableControllerInput()
					else
						-- Close menu
						if not UIManager_Service:IsInventoryOpen() then
							UIManager_Service:CloseMenu()
							
							EnableMovement:FireServer()
							
							MenuUiOpened = false
							GuiService.GuiNavigationEnabled = false
							OTS_Service:EnableControllerInput()
						else
							UIManager_Service:BackToMenu()
						end
					end
				end

				if button == Enum.KeyCode.DPadRight then
					if not MenuUiOpened then
						OTSFunctionsTable.SetShoulderDirection(1)
					end

				end

				if button == Enum.KeyCode.DPadLeft then
					if not MenuUiOpened then
						OTSFunctionsTable.SetShoulderDirection(-1)
					end
				end
			end)


			-- Handles Thumpstick input
			Console_Input.ButtonUp:Connect(function(button: Enum.KeyCode, processed: boolean)
				if button == Enum.KeyCode.ButtonL2 then
					OTSFunctionsTable.SetActiveCameraSettings("DefaultShoulder")
					RockAim_ChildService:Stop()				end

				if button == Enum.KeyCode.ButtonL3 then
					MotionFunctionsTable.StopSprint()
				end

				if button == Enum.KeyCode.ButtonB then
					MotionFunctionsTable.StopSlideHold()
				end
			end)

			Console_Input._gamepadTrove:Connect(UserInputService.InputChanged, function(input)
				if input.UserInputType == Console_Input:GetUserInputType() then
					-- Only handle Right Thumbstick (Thumbstick2)
					if input.KeyCode == Enum.KeyCode.Thumbstick2 then
						local y = input.Position.Y

						if y < -0.5 then
							-- Right thumbstick UP
							if MenuUiOpened and not UIManager_Service:IsInventoryOpen() then
								UIManager_Service:GoToInventory()
							end
						elseif y > 0.5 then
							-- Right thumbstick DOWN
							if MenuUiOpened then
								if not UIManager_Service:IsInventoryOpen() then
									UIManager_Service:CloseMenu()
									MenuUiOpened = false
									GuiService.GuiNavigationEnabled = false
									OTS_Service:EnableControllerInput()
								else
									UIManager_Service:BackToMenu()
								end
							end
						end
					end
				end
			end)




		elseif newType == "Touch" then
			-- disable camera center 
			OTSFunctionsTable.SetMouseStep(false)
			--Mobile_Input = Input.Touch.new()

			--initializing signals connections
			SlideButtonSignal:Connect(function()
				if Motion_Service.IsPlayerMoving() then
					MotionFunctionsTable.StartSlide()
				end
			end)

			SprintButtonStartSignal:Connect(function()
				MotionFunctionsTable.StartSprint()
			end)

			SprintButtonEndSignal:Connect(function()
				MotionFunctionsTable.StopSprint()
			end)

			-- the equipe logic with Bool is set in UIFunction module
			EquipButtonSignal:Connect(function(Status:boolean)
				local backpack = LOCAL_PLAYER:FindFirstChild("Backpack")
				local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()

				if Status then
					-- Try to get the tool safely
					local tool = GetTool()
					if tool then
						tool.Parent = character
					else
						warn("[Equip] No tool found to equip.")
					end
				else
					if character and character:FindFirstChildOfClass("Tool") then
						character:FindFirstChildOfClass("Tool").Parent = backpack
					end
					if character:FindFirstChildOfClass("Humanoid") then
						character.Humanoid:UnequipTools()
					end
				end
			end)


			AimButtonSignal:Connect(function(isAiming: boolean)
				if isAiming then
					OTSFunctionsTable.SetActiveCameraSettings("ZoomedShoulder", Motion_Service.IsPlayerSilding())
					RockAim_ChildService:Start(LOCAL_PLAYER.Character:FindFirstChildOfClass("Tool"))
				else
					OTSFunctionsTable.SetActiveCameraSettings("DefaultShoulder")
					RockAim_ChildService:Stop()
				end
			end)

			JumpButtonSignal:Connect(function()
				if MotionFunctionsTable.IsPlayerSliding() then
					MotionFunctionsTable.SpearJump()
				end
			end)

			-- setting the buttons and binding callback
			UIManager_Service:setMobileButtons(SlideButtonSignal,
				SprintButtonStartSignal,
				SprintButtonEndSignal,
				EquipButtonSignal,
				AimButtonSignal,
				JumpButtonSignal)
		end
	end


	CreateServices(Input.PreferredInput.Current)


	-- observe for Preferred Input change
	Input.PreferredInput.Observe(function(newType)
		CreateServices(newType)
	end)



	return true
end



-----------------------------
-- MAIN --
-----------------------------


return Service
