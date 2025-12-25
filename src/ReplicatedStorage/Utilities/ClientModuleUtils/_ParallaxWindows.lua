--!strict
--[[
	A client-side parallax corrected image projector (what a weird name)
	Made by Fake_Bobcat (youtube.com/@Bumcat or @bumcat1 on Discord)

	HOW TO USE:
	As this is a client-side only effect, the module must be called from a local script or a script using the client run context
	To apply the effect to a part, it must be a BasePart
	
	1. To set the module up, call [var] = [module].new() in a local script.
	2. For any face you want to apply the effect to, use [var]:AddFrame(part, normalEnum, UIElements). UIElements should be a list of UI
	   elements that will get parented to the frame and have the parallax effect applied, they need to be sized and positioned using scale only
	   You can also remove a face using :RemoveFace(), and AddFrame returns the frame instance so you can access the UIElements you placed inside,
	   or just delete it, which will also delete the frame.
	3. Use :Step() to update the effect on all added parts. It's recommended to put this in RunService.RenderStepped.
	   as an argument, the module will automatically use the local player's camera position
	4. Use :UpdateSettings(GuisettingsTable, FramesettingsTable) to apply your own settings at any time. The default settings are listed below.
	   Note: If you want to reset the settings to default, call :UpdateSettings() with no arguments
	5. If you want to get rid of the effect and clean all surfaces, use :Clear()
]]

local ParallaxWindows = {}
ParallaxWindows.__index = ParallaxWindows

-- default settings, can be overriden with custom settings by using :UpdateFaceSettings() and :UpdateFrameSettings()
local DEFAULT_GUI_SETTINGS = {
	["MaxFramerate"] = 60, -- Max Frame rate that the GUI will run at
	["MinFramerate"] = 10, -- Min Frame rate that the GUI will run at (for when the GUI is out of Update Distance)
	-- Frame rates will automatically adjust between these two distances below
	["MaxUpdateDistance"] = 10, -- Distance that the GUI will cap at the max frame rate
	["MinUpdateDistance"] = 200, -- Distance that the GUI will cap at the min frame rate
	["LazyCheckingModifier"] = 10, -- If a frame is not visible, this modifier is applied so that the module checks less frequently
	-- SurfaceGui settings
	["ZOffset"] = 0,
	["AlwaysOnTop"] = false,
	["Brightness"] = 1,
	["LightInfluence"] = 1,
	["MaxDistance"] = 1000,
	["PixelsPerStud"] = 100,
	["SizingMode"] = Enum.SurfaceGuiSizingMode.PixelsPerStud,
}

local DEFAULT_FRAME_SETTINGS = {
	["UpdateRange"] = 100, -- Distance at which the Image is no longer Updated
	["ZIndex"] = 0, -- ZIndex of the frame
	["Image"] = "rbxassetid://18838056070", -- ImageId
	["Rotation"] = 0, -- rotation of the image
	["ImageTransparency"] = 0, -- Transparency of the image when in range
	["BackgroundTransparency"] = 1, -- Transparency of the image background when in range
	["ImageColor3"] = Color3.fromRGB(255, 255, 255), -- Color of the image
	["BackgroundColor3"] = Color3.fromRGB(255, 255, 255), -- Color of the image background
	["ResampleMode"] = Enum.ResamplerMode.Default, -- Resampling mode
	["ScaleType"] = Enum.ScaleType.Stretch, -- Scaling type
	["TileSize"] = UDim2.new(1,0,1,0), -- Tile Size
	["Interactable"] = false, -- Whether or not the frame is interactable
	["Active"] = false, -- Whether or not the frame is active
	["ImageSize"] = Vector3.new(8, 8, 0), -- Size of the image in studs per tile, dont use Z value, just using V3 cause its more efficient than V2
	["PosOffset"] = Vector3.new(), -- Positional offset for parallax from the face
	["ExtraOffset"] = UDim2.new(), -- Extra positional offset added onto final position
}

-- sets up folders where SurfaceParts and SurfaceGuis will be stored
local function SetUpFolders(obj: ParallaxWindow, isparallel: boolean?): boolean?
	if obj.GuiFolder ~= nil then return end
	-- search playergui for already existing folder, if none found, create a new one
	local folder = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ParallaxWindows_SurfaceGuis")
	if folder ~= nil then
		obj.GuiFolder = folder
		return
	elseif not isparallel then
		obj.GuiFolder = Instance.new("Folder")
		obj.GuiFolder.Name = "ParallaxWindows_SurfaceGuis"
		if game:GetService("RunService"):IsRunning() then
			obj.GuiFolder.Parent = game.Players.LocalPlayer.PlayerGui
		else
			obj.GuiFolder.Parent = game.StarterGui --for when testing effect with StudioExecutor
		end
		return
	end
	return true
end

type FrameSettings = typeof(DEFAULT_FRAME_SETTINGS)
type GuiSettings = typeof(DEFAULT_GUI_SETTINGS)
type self = {
	Default_GuiSettings: { [any]: any },
	Default_FrameSettings: { [any]: any },
	GuiSettings: { [any]: any },
	FrameSettings: { [any]: any },
	TargetParts: { [any]: any },
	GuiFolder: any,
	LastStep: number,
	MaxUpdates: number
}
export type ParallaxWindow = typeof(setmetatable({} :: self, ParallaxWindows))

function ParallaxWindows.new(): ParallaxWindow
	local obj = {
		Default_GuiSettings = {},
		Default_FrameSettings = {},
		GuiSettings = {},
		FrameSettings = {},
		TargetParts = {},
		GuiFolder = nil,
		LastStep = os.clock(),
		MaxUpdates = 100,
	}
	setmetatable(obj, ParallaxWindows)
	obj.Default_GuiSettings = table.clone(DEFAULT_GUI_SETTINGS)
	obj.Default_FrameSettings = table.clone(DEFAULT_FRAME_SETTINGS)
	SetUpFolders(obj)

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function ParallaxWindows:UpdateSettings(guiSettings: GuiSettings, frameSettings: FrameSettings)
	if self.Default_GuiSettings == nil then
		self.Default_GuiSettings = {}
	end
	if self.Default_FrameSettings == nil then
		self.Default_FrameSettings = {}
	end

	if guiSettings then
		assert(type(guiSettings) == "table", "Expected table as parameter")

		for i,v in DEFAULT_GUI_SETTINGS do
			if guiSettings[i] ~= nil then
				self.Default_GuiSettings[i] = guiSettings[i]
			elseif self.Default_GuiSettings[i] == nil then
				self.Default_GuiSettings[i] = v
			end
		end
	end

	if frameSettings then
		assert(type(frameSettings) == "table", "Expected table as parameter")

		for i,v in DEFAULT_FRAME_SETTINGS do
			if frameSettings[i] ~= nil then
				self.Default_FrameSettings[i] = frameSettings[i]
			elseif self.Default_FrameSettings[i] == nil then
				self.Default_FrameSettings[i] = v
			end
		end
	end
end

-- updates individual settings per gui (overrides global settings). Supports all default settings
function ParallaxWindows:UpdateFaceSettings(targetPart: BasePart, normal:Enum.NormalId?, settingsTable)
	local target = self.TargetParts[targetPart][normal]
	if not target then return end
	local targetGui = target.SurfaceGui
	if not targetGui then return end
	if self.GuiSettings[targetGui] == nil then
		self.GuiSettings[targetGui] = {}
	end

	if settingsTable == nil then 
		self.GuiSettings[targetGui] = nil
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in settingsTable do
		self.GuiSettings[targetGui][i] = v
	end
end

-- updates individual settings per frame (overrides global settings). Supports all default settings
function ParallaxWindows:UpdateFrameSettings(targetFrame: Frame, settingsTable)
	if self.FrameSettings[targetFrame] == nil then
		self.FrameSettings[targetFrame] = {}
	end

	if settingsTable == nil then
		self.FrameSettings[targetFrame] = nil
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in settingsTable do
		self.FrameSettings[targetFrame][i] = v
	end
end

---------------------- PARALLAX FUNCTIONS ----------------------

-- gets the offset of a normal from the targetPart's origin
local function GetNormalOffset(normal: Enum.NormalId, targetPart: BasePart)
	local offset = Vector3.new()
	local rotation = CFrame.new()

	if normal == Enum.NormalId.Front then
		offset = (targetPart.Size.Z / 2) * targetPart.CFrame.LookVector
		rotation = CFrame.Angles(0, 0, 0)
	elseif normal == Enum.NormalId.Back then
		offset = (targetPart.Size.Z / 2) * -targetPart.CFrame.LookVector
		rotation = CFrame.Angles(0, math.rad(180), 0)
	elseif normal == Enum.NormalId.Left then
		offset = (targetPart.Size.X / 2) * -targetPart.CFrame.RightVector
		rotation = CFrame.Angles(0, math.rad(90), 0)
	elseif normal == Enum.NormalId.Right then
		offset = (targetPart.Size.X / 2) * targetPart.CFrame.RightVector
		rotation = CFrame.Angles(0, math.rad(-90), 0)
	elseif normal == Enum.NormalId.Top then
		offset = (targetPart.Size.Y / 2) * targetPart.CFrame.UpVector
		rotation = CFrame.Angles(math.rad(90), 0, 0)
	elseif normal == Enum.NormalId.Bottom then
		offset = (targetPart.Size.Y / 2) * -targetPart.CFrame.UpVector
		rotation = CFrame.Angles(math.rad(-90), 0, 0)
	end

	return offset, rotation
end

-- Calculate the point at which a vector intersects a plane
function rayToPlaneIntersection(rayVector: Vector3, rayPoint: Vector3, planeNormal: Vector3, planePoint: Vector3)
	local diff = rayPoint - planePoint
	local prod1 = diff:Dot(planeNormal)
	local prod2 = rayVector:Dot(planeNormal)
	local prod3 = prod1/prod2
	return rayPoint - (rayVector*prod3)
end

-- calculate the stud offsets and positions for parallax
function calcParallax(camPos: Vector3, wallCF: CFrame, posOffset: Vector3)

	local wallPos = wallCF.Position

	if math.abs(posOffset.X) < 0.05 then -- For when the Offset is at the wall, lessening the need to do calculations
		return {
			["horOffset"] = -posOffset.Z,
			["verOffset"] = -posOffset.Y,
			["parimgPoint"] = Vector3.new(),  -- Empty as this is just used to calculate size, but since it's against the wall it'll always be full size
			["imgPoint"] = Vector3.new(),
			["camPos"] = camPos,
		}
	end

	local parPoint = wallPos+(wallCF.LookVector*posOffset.X)+(wallCF.UpVector*posOffset.Y)+(wallCF.RightVector*posOffset.Z)

	local imgVector = CFrame.lookAt(camPos,parPoint).LookVector

	local imgPoint = rayToPlaneIntersection(imgVector,camPos,wallCF.LookVector,wallPos)
	local parimgPoint = rayToPlaneIntersection(imgVector,camPos,wallCF.LookVector,parPoint)

	local imgdist = (imgPoint-wallPos).Magnitude
	local hordist = rayToPlaneIntersection(wallCF.UpVector*-imgdist,imgPoint,wallCF.UpVector,wallPos)
	local horOffset = (wallPos-hordist).Magnitude

	local isRight = wallCF.RightVector:Dot(CFrame.lookAt(wallPos,hordist).LookVector) -- If the horizontal point is to the right of the camera

	if isRight > 0 then horOffset *= -1 end

	local verpoint = rayToPlaneIntersection(wallCF.RightVector*-imgdist,imgPoint,wallCF.RightVector,wallPos)
	local verOffset = (wallPos-verpoint).Magnitude

	local isDown = wallCF.UpVector:Dot(CFrame.lookAt(wallPos,verpoint).LookVector) -- If the vertical point is under the camera

	if isDown > 0 then verOffset *= -1 end

	-- horizontal & vertical stud offsets, the position of what the parallax is trying to copy, the position of the frame on the part
	return {
		["horOffset"] = horOffset,
		["verOffset"] = verOffset,
		["parimgPoint"] = parimgPoint, 
		["imgPoint"] = imgPoint,
		["camPos"] = camPos,
	}
end

function getSizeAndPosition(parCalculations: any, surfaceInfo, frameSettings, surfaceGui : SurfaceGui): (UDim2, UDim2)
	local pps = surfaceGui.PixelsPerStud
	-- Get the distance from the camera to the wall and parallax position
	local wallDist, pointDist = (parCalculations.camPos-parCalculations.imgPoint).Magnitude, (parCalculations.camPos-parCalculations.parimgPoint).Magnitude

	local ImgSize = frameSettings.ImageSize :: Vector2
	local absSize = Vector2.new(ImgSize.X*pps,ImgSize.Y*pps) -- Absolute Pixel Size of the frame in pixels (studs to pixels)
	local sizeAmplifier = (wallDist/pointDist)

	local Position
	if surfaceInfo.SurfaceNormal == Enum.NormalId.Top then
		Position = UDim2.new(0.5,parCalculations.verOffset*pps,0.5,-parCalculations.horOffset*pps)
	elseif surfaceInfo.SurfaceNormal == Enum.NormalId.Bottom then
		Position = UDim2.new(0.5,-parCalculations.verOffset*pps,0.5,parCalculations.horOffset*pps)
	else
		Position = UDim2.new(0.5,parCalculations.horOffset*pps,0.5,parCalculations.verOffset*pps)
	end
	local Size = UDim2.new(0,absSize.X*sizeAmplifier,0,absSize.Y*sizeAmplifier)

	return Position, Size -- Size & Position of the parallax corrected image/frame
end

-- Calculates the size and position of the frame using all the other functions
function getParallax(surfaceInfo, frameSettings, camPos: Vector3, wallCF, posOffset: Vector3): (UDim2?, UDim2?)
	if not posOffset or not surfaceInfo then return end
	if not camPos then
		camPos = game.Workspace.CurrentCamera.CFrame.Position
	end

	local targetPart = surfaceInfo.TargetPart
	local normal = surfaceInfo.SurfaceNormal

	if not wallCF then -- If wallCF not calculated then get it
		local offset, rotation = GetNormalOffset(surfaceInfo.SurfaceNormal, targetPart)
		wallCF = targetPart.CFrame * CFrame.new(offset) * rotation
	end

	local parCalculations = calcParallax(camPos,wallCF,posOffset) -- Calculate Parallax logic
	local Position, Size = getSizeAndPosition(parCalculations, surfaceInfo, frameSettings, surfaceInfo.SurfaceGui) -- Transform the logic into udim2 position and size

	return Position, Size
end

---------------------- ADD/REMOVE PARTS ----------------------

-- sets up surface part and SurfaceGui for a targeted face
function SetUpSurface(targetPart : BasePart, normal: Enum.NormalId, obj)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.ResetOnSpawn = false
	surfaceGui.ClipsDescendants = true
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.Parent = obj.GuiFolder
	surfaceGui.Adornee = targetPart
	surfaceGui.Face = normal
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 100
	surfaceGui.Enabled = true

	local canvasGroup = Instance.new("CanvasGroup")
	canvasGroup.BackgroundTransparency = 1
	canvasGroup.Size = UDim2.new(1,0,1,0)
	canvasGroup.Parent = surfaceGui

	return surfaceGui
end

function SetUpFrame(targetGui: SurfaceGui)
	local scaleFrame = Instance.new("ImageLabel") -- Actually an imagelabel but lets not talk about that
	scaleFrame.Size = UDim2.new(1, 0, 1, 0)
	scaleFrame.AnchorPoint = Vector2.new(.5, .5)
	scaleFrame.Position = UDim2.new(.5, 0, .5, 0)
	scaleFrame.BackgroundTransparency = 1
	scaleFrame.Name = "ScaleFrame"

	local canvasGroup = targetGui:FindFirstChildWhichIsA("CanvasGroup")
	scaleFrame.Parent = canvasGroup or targetGui

	return scaleFrame
end

-- adds a part's face to the target list. Used for adding the surface gui, but not the frame
function ParallaxWindows:AddFace(targetPart: BasePart, normal: Enum.NormalId?) 
	if normal == nil then
		normal = Enum.NormalId.Front
	end
	if self.TargetParts[targetPart] == nil then
		self.TargetParts[targetPart] = {}
	end
	local surfaceGui = SetUpSurface(targetPart, normal :: Enum.NormalId, self)
	self.GuiSettings[surfaceGui] = table.clone(self.Default_GuiSettings)
	local info = {
		["SurfaceNormal"] = normal,
		["SurfaceGui"] = surfaceGui,
		["TargetPart"] = targetPart,
		["Frames"] = {},
		["LastUpdate"] = 0,
		["Visible"] = false,
		["Framerate"] = 1, -- Current frame rate
	}
	if self.TargetParts[targetPart][normal] == nil then
		self.TargetParts[targetPart][normal] = {}
	end
	self.TargetParts[targetPart][normal] = info

	return surfaceGui
end

-- adds a new frame to the target list (can have multiple frames on the same part). 'targetPart' should be a BasePart and 'normal' should be an Enum.NormalId
function ParallaxWindows:AddFrame(targetPart: BasePart, normal: Enum.NormalId?, UIElements)
	if normal == nil then
		normal = Enum.NormalId.Front
	end
	if self.TargetParts[targetPart] == nil then
		self.TargetParts[targetPart] = {}
	end
	local info = self.TargetParts[targetPart][normal]
	if not info then
		self:AddFace(targetPart, normal)
		info = self.TargetParts[targetPart][normal]
	end
	local surfaceGui = info.SurfaceGui
	local frame = SetUpFrame(surfaceGui)

	self.FrameSettings[frame] = table.clone(self.Default_FrameSettings)

	if UIElements then
		for _,v in UIElements do -- Clone all UIElements to the frame
			v.Parent = frame
		end
	end

	local info = {
		["SurfaceNormal"] = normal,
		["SurfaceGui"] = surfaceGui,
		["TargetPart"] = targetPart,
		["Frame"] = frame,
	}
	table.insert(self.TargetParts[targetPart][normal].Frames,info)

	return frame -- return the frame so they can edit it if they want to
end

-- removes a face from the target list and clears the effect from workspace/gui
function ParallaxWindows:RemoveFace(targetPart: BasePart, normal: Enum.NormalId?)
	if normal == nil then
		normal = Enum.NormalId.Front
	end
	if self.TargetParts[targetPart] == nil then return end
	local info = self.TargetParts[targetPart][normal]
	if info == nil then return end
	self.GuiSettings[info.SurfaceGui] = nil
	info.SurfaceGui:Destroy()
	self.TargetParts[targetPart][normal] = nil
	if next(self.TargetParts[targetPart]) == nil then -- dictionary is empty
		self.TargetParts[targetPart] = nil
	end
end

-- clears all ParallaxWindows from the workspace 
function ParallaxWindows:Clear()
	for _,targetParts in self.TargetParts do
		for normal, info in targetParts do
			info.SurfaceGui:Destroy()
		end
	end

	table.clear(self.GuiSettings)
	table.clear(self.FrameSettings)

	table.clear(self.TargetParts)
end

---------------------- CULLING ----------------------

function GetVectorFromNormal(CF: CFrame, NormalID: Enum.NormalId)
	if NormalID == Enum.NormalId.Front then
		return CF.LookVector
	elseif NormalID == Enum.NormalId.Right then
		return CF.RightVector
	elseif NormalID == Enum.NormalId.Top then
		return CF.UpVector
	elseif NormalID == Enum.NormalId.Back then
		return -CF.LookVector
	elseif NormalID == Enum.NormalId.Left then
		return -CF.RightVector
	elseif NormalID == Enum.NormalId.Bottom then
		return -CF.UpVector
	end
	return Vector3.zero
end

function GetCorners(Part : BasePart, wallpos : Vector3, normal : Enum.NormalId)
	local size = Part.Size
	local cf = Part.CFrame
	local u, r, l = cf.UpVector, cf.RightVector, cf.LookVector
	if normal == Enum.NormalId.Front or normal == Enum.NormalId.Back then
		return {
			wallpos,
			wallpos-u*size.Y/2-r*size.X/2,
			wallpos-u*size.Y/2+r*size.X/2,
			wallpos+u*size.Y/2-r*size.X/2,
			wallpos+u*size.Y/2+r*size.X/2,
		}
	elseif normal == Enum.NormalId.Right or normal == Enum.NormalId.Left then
		return {
			wallpos,
			wallpos-u*size.Y/2-l*size.Z/2,
			wallpos-u*size.Y/2+l*size.Z/2,
			wallpos+u*size.Y/2-l*size.Z/2,
			wallpos+u*size.Y/2+l*size.Z/2,
		}
	elseif normal == Enum.NormalId.Top or normal == Enum.NormalId.Bottom then
		return {
			wallpos,
			wallpos-r*size.X/2-l*size.Z/2,
			wallpos-r*size.X/2+l*size.Z/2,
			wallpos+r*size.X/2-l*size.Z/2,
			wallpos+r*size.X/2+l*size.Z/2,
		}
	end
	return {}
end

function CanSee(Camera : Camera, Part : BasePart, wallCF : CFrame, normal : Enum.NormalId)
	-- Can the wall see the player?
	local Vector = GetVectorFromNormal(Part.CFrame,normal)

	if Vector:Dot(CFrame.lookAt(wallCF.Position,Camera.CFrame.Position).LookVector) <= 0 then
		return false
	end

	-- If the player can see any one of the corners or the centre it is considered in view
	local corners = GetCorners(Part, wallCF.Position, normal)

	for _,corner in corners do
		local _,cansee = Camera:WorldToScreenPoint(corner)
		if cansee then
			return true
		end
	end
	return false
end

---------------------- STEP ----------------------

-- main logic of the module, called every interval. Put in RunService.RenderStepped for smooth interpolation
function ParallaxWindows:Step()
	SetUpFolders(self) -- Run every step in case folder was deleted

	local dt = os.clock()-self.LastStep -- Calculate Delta time
	self.LastStep = os.clock()

	local Camera = game.Workspace.CurrentCamera
	local camCF = Camera.CFrame
	local camPos = camCF.Position

	local Default_GuiSettings = self.Default_GuiSettings -- Default Settings
	local Default_FrameSettings = self.Default_FrameSettings

	for frame,frameSetting in self.FrameSettings do -- Clean up deleted frames
		if not frame:IsDescendantOf(self.GuiFolder) then
			self.FrameSettings[frame] = nil
		end
	end

	local MaxUpdates, TotalUpdates = self.MaxUpdates, 0 -- Cap the number of surfaces that can be updated every step

	local ToUpdate = {} -- A list of surfaces to update

	for targetPart, guis in self.TargetParts do -- Get all the surfaceGuis
		if not targetPart:IsDescendantOf(game) then
			for _, info in guis do
				self.GuiSettings[info.SurfaceGui] = nil
				info.SurfaceGui:Destroy()
			end
			self.TargetParts[targetPart] = nil
		end
		for _, info in guis do

			local surfaceGui = info.SurfaceGui

			if not surfaceGui then continue end

			-- Get the cframe of the face
			local offset, rotation = GetNormalOffset(info.SurfaceNormal, targetPart)
			local wallCF = (targetPart.CFrame + offset) * rotation
			local normal = info.SurfaceNormal

			-- Is the surface in view of the player and is the face facing the player
			local canSee = CanSee(Camera,targetPart,wallCF,normal) or false

			info.Visible = canSee

			if not canSee then continue end -- If not in view just skip

			-- set unique settings for the face if applicable
			local newTable = {}
			if self.GuiSettings[surfaceGui] ~= nil then
				for i,v in Default_GuiSettings do
					newTable[i] = self.GuiSettings[surfaceGui][i] or v
				end
			end
			local GuiSettings = newTable
			if next(newTable) ~= nil then
				GuiSettings = newTable
			end

			-- Distance from wall to camera
			local Dist = (wallCF.Position-camPos).Magnitude

			if (Dist > GuiSettings.MinUpdateDistance and GuiSettings.MinFramerate <= 0) or Dist > GuiSettings.MaxDistance then continue end -- Further than the GUI will render

			local Framerate = GuiSettings.MinFramerate + (GuiSettings.MaxFramerate - GuiSettings.MinFramerate) * math.clamp(1 - (Dist-GuiSettings.MaxUpdateDistance) / GuiSettings.MinUpdateDistance,0,1)

			if not info.Visible then
				Framerate /= GuiSettings.LazyCheckingModifier
			end

			local ratetime = 1/Framerate -- Calculate the needed delta time for the surface to be updated

			if GuiSettings.MaxFramerate < 0 then -- Uncap the frame rate
				ratetime = -1
			end

			--if info.LastUpdate < ratetime then -- Not time for this surface to update yet!
			--	continue
			--end

			info.LastUpdate += dt -- Time since the surface was updated in seconds

			table.insert(ToUpdate,{targetPart,info,GuiSettings,{offset,rotation :: any,wallCF,normal,Dist},ratetime})
		end
	end

	-- Sort the surfaces by last updated to the most recently updated, used so that when the max update limit is reached
	-- it will update the oldest ones so that all of the surfaces will get updated over time
	table.sort(ToUpdate,function(a,b)
		return a[2].LastUpdate/a[5] > b[2].LastUpdate/b[5]
	end)

	for _, myinfo in ToUpdate do -- Update all the surfaces
		local targetPart = myinfo[1]
		local info = myinfo[2]
		local GuiSettings = myinfo[3]

		if TotalUpdates >= MaxUpdates and MaxUpdates >= 0 then -- If number of surfaces updated exceeds the max then end the step
			break
		end

		local surfaceGui = info.SurfaceGui

		local offset, rotation, wallCF, normal, Dist = myinfo[4][1],myinfo[4][2],myinfo[4][3],myinfo[4][4],myinfo[4][5]

		info.LastUpdate = 0

		--local instanceSettings = {}
		--instanceSettings.ZOffset = GuiSettings.ZOffset
		--instanceSettings.AlwaysOnTop = GuiSettings.AlwaysOnTop
		--instanceSettings.Brightness = GuiSettings.Brightness
		--instanceSettings.LightInfluence = GuiSettings.LightInfluence
		--instanceSettings.MaxDistance = GuiSettings.MaxDistance
		--instanceSettings.PixelsPerStud = GuiSettings.PixelsPerStud
		--instanceSettings.SizingMode = GuiSettings.SizingMode

		---- declare main variables and set surfaceGui settings
		--for setting,value in instanceSettings do
		--	if surfaceGui[setting] ~= value then
		--		surfaceGui[setting] = value
		--	end
		--end
		surfaceGui.ZOffset = GuiSettings.ZOffset
		surfaceGui.AlwaysOnTop = GuiSettings.AlwaysOnTop
		surfaceGui.Brightness = GuiSettings.Brightness
		surfaceGui.LightInfluence = GuiSettings.LightInfluence
		surfaceGui.MaxDistance = GuiSettings.MaxDistance
		surfaceGui.PixelsPerStud = GuiSettings.PixelsPerStud
		surfaceGui.SizingMode = GuiSettings.SizingMode

		if (Dist > GuiSettings.MinUpdateDistance and GuiSettings.MinFramerate <= 0) or Dist > GuiSettings.MaxDistance then print("Die") continue end -- Further than the GUI will render

		TotalUpdates += 1

		for index, frameinfo in info.Frames do
			local frame = frameinfo.Frame

			if not frame or not frame:IsDescendantOf(self.GuiFolder) then -- Clean up deleted frames
				table.remove(info.Frames,index)
				continue
			end

			-- set unique settings for the frame if applicable
			local newTable = {}
			if self.FrameSettings[frame] ~= nil then
				for i,v in Default_FrameSettings do
					newTable[i] = self.FrameSettings[frame][i] or v
				end
			end
			local frameSettings = newTable
			if next(newTable) ~= nil then
				frameSettings = newTable
			end

			if frameSettings.UpdateRange < Dist then continue end -- Frame is outside of update distance

			-- set frame settings
			--local instanceSettings = {}
			--instanceSettings.ZIndex = frameSettings.ZIndex
			--instanceSettings.Image = frameSettings.Image
			--instanceSettings.Rotation = frameSettings.Rotation
			--instanceSettings.ImageTransparency = frameSettings.ImageTransparency
			--instanceSettings.BackgroundTransparency = frameSettings.BackgroundTransparency
			--instanceSettings.ImageColor3 = frameSettings.ImageColor3
			--instanceSettings.BackgroundColor3 = frameSettings.BackgroundColor3
			--instanceSettings.ResampleMode = frameSettings.ResampleMode
			--instanceSettings.ScaleType = frameSettings.ScaleType
			--instanceSettings.TileSize = frameSettings.TileSize
			--instanceSettings.Interactable = frameSettings.Interactable
			--instanceSettings.Active = frameSettings.Active

			--for setting,value in instanceSettings do
			--	if frame[setting] ~= value then
			--		frame[setting] = value
			--	end
			--end
			frame.ZIndex = frameSettings.ZIndex
			frame.Image = frameSettings.Image
			frame.Rotation = frameSettings.Rotation
			frame.ImageTransparency = frameSettings.ImageTransparency
			frame.BackgroundTransparency = frameSettings.BackgroundTransparency
			frame.ImageColor3 = frameSettings.ImageColor3
			frame.BackgroundColor3 = frameSettings.BackgroundColor3
			frame.ResampleMode = frameSettings.ResampleMode
			frame.ScaleType = frameSettings.ScaleType
			frame.TileSize = frameSettings.TileSize
			frame.Interactable = frameSettings.Interactable
			frame.Active = frameSettings.Active

			-- Get the parallax corrected size and position in udim2 for the frame
			local Position, Size = getParallax(info,frameSettings,camPos,wallCF,frameSettings.PosOffset)

			-- Apply the position and size
			frame.Position = Position + frameSettings.ExtraOffset or UDim2.new(0.5,0,0.5,0) + frameSettings.ExtraOffset
			frame.Size = Size or UDim2.new(1,0,1,0)
		end
	end
end

-- For parallel luau, for computing the step, but not applying changes
function ParallaxWindows:ComputeStep()
	local cancelStep = SetUpFolders(self, true) -- Run every step in case folder was deleted
	if cancelStep then return end -- No Folder exists, and you cannot write in parallel

	local updateData = {} -- Data to return to the executor for when the task is synchronised

	local dt = os.clock()-self.LastStep -- Calculate Delta time
	self.LastStep = os.clock()

	local Camera = game.Workspace.CurrentCamera
	local camCF = Camera.CFrame
	local camPos = camCF.Position

	local Default_GuiSettings = self.Default_GuiSettings -- Default Settings
	local Default_FrameSettings = self.Default_FrameSettings

	for frame,frameSetting in self.FrameSettings do -- Clean up deleted frames
		if not frame:IsDescendantOf(self.GuiFolder) then
			self.FrameSettings[frame] = nil
		end
	end

	local MaxUpdates, TotalUpdates = self.MaxUpdates, 0 -- Cap the number of surfaces that can be updated every step

	local ToUpdate = {} -- A list of surfaces to update

	for targetPart, guis in self.TargetParts do -- Get all the surfaceGuis
		if not targetPart:IsDescendantOf(game) then
			for _, info in guis do
				self.GuiSettings[info.SurfaceGui] = nil
				info.SurfaceGui:Destroy()
			end
			self.TargetParts[targetPart] = nil
		end
		for _, info in guis do

			local surfaceGui = info.SurfaceGui

			if not surfaceGui then continue end

			-- Get the cframe of the face
			local offset, rotation = GetNormalOffset(info.SurfaceNormal, targetPart)
			local wallCF = (targetPart.CFrame + offset) * rotation
			local normal = info.SurfaceNormal

			-- Is the surface in view of the player and is the face facing the player
			local canSee = CanSee(Camera,targetPart,wallCF,normal) or false

			info.Visible = canSee

			if not canSee then continue end -- If not in view just skip

			-- set unique settings for the face if applicable
			local newTable = {}
			if self.GuiSettings[surfaceGui] ~= nil then
				for i,v in Default_GuiSettings do
					newTable[i] = self.GuiSettings[surfaceGui][i] or v
				end
			end
			local GuiSettings = newTable
			if next(newTable) ~= nil then
				GuiSettings = newTable
			end

			-- Distance from wall to camera
			local Dist = (wallCF.Position-camPos).Magnitude

			if (Dist > GuiSettings.MinUpdateDistance and GuiSettings.MinFramerate <= 0) or Dist > GuiSettings.MaxDistance then continue end -- Further than the GUI will render

			local Framerate = GuiSettings.MinFramerate + (GuiSettings.MaxFramerate - GuiSettings.MinFramerate) * math.clamp(1 - (Dist-GuiSettings.MaxUpdateDistance) / GuiSettings.MinUpdateDistance,0,1)

			if not info.Visible then
				Framerate /= GuiSettings.LazyCheckingModifier
			end

			local ratetime = 1/Framerate -- Calculate the needed delta time for the surface to be updated

			if GuiSettings.MaxFramerate < 0 then -- Uncap the frame rate
				ratetime = -1
			end

			--if info.LastUpdate < ratetime then -- Not time for this surface to update yet!
			--	continue
			--end

			info.LastUpdate += dt -- Time since the surface was updated in seconds

			table.insert(ToUpdate,{targetPart,info,GuiSettings,{offset,rotation :: any,wallCF,normal,Dist},ratetime})
		end
	end

	-- Sort the surfaces by last updated to the most recently updated, used so that when the max update limit is reached
	-- it will update the oldest ones so that all of the surfaces will get updated over time
	table.sort(ToUpdate,function(a,b)
		return a[2].LastUpdate/a[5] > b[2].LastUpdate/b[5]
	end)

	for _, myinfo in ToUpdate do -- Update all the surfaces
		local targetPart = myinfo[1]
		local info = myinfo[2]
		local GuiSettings = myinfo[3]

		if TotalUpdates >= MaxUpdates and MaxUpdates >= 0 then -- If number of surfaces updated exceeds the max then end the step
			break
		end

		local surfaceGui = info.SurfaceGui

		local offset, rotation, wallCF, normal, Dist = myinfo[4][1],myinfo[4][2],myinfo[4][3],myinfo[4][4],myinfo[4][5]

		table.insert(updateData,{
			istype = "surface",
			surfaceGui = surfaceGui,
			GuiSettings = GuiSettings,
		})

		info.LastUpdate = 0

		if (Dist > GuiSettings.MinUpdateDistance and GuiSettings.MinFramerate <= 0) or Dist > GuiSettings.MaxDistance then continue end -- Further than the GUI will render

		TotalUpdates += 1

		for index, frameinfo in info.Frames do
			local frame = frameinfo.Frame

			if not frame or not frame:IsDescendantOf(self.GuiFolder) then -- Clean up deleted frames
				table.remove(info.Frames,index)
				continue
			end

			-- set unique settings for the frame if applicable
			local newTable = {}
			if self.FrameSettings[frame] ~= nil then
				for i,v in Default_FrameSettings do
					newTable[i] = self.FrameSettings[frame][i] or v
				end
			end
			local frameSettings = newTable
			if next(newTable) ~= nil then
				frameSettings = newTable
			end

			if frameSettings.UpdateRange < Dist then continue end -- Frame is outside of update distance

			-- Get the parallax corrected size and position in udim2 for the frame
			local Position, Size = getParallax(info,frameSettings,camPos,wallCF,frameSettings.PosOffset)

			-- Insert the position and size

			table.insert(updateData,{
				istype = "frame",
				frame = frame,
				Position = Position + frameSettings.ExtraOffset or UDim2.new(0.5,0,0.5,0) + frameSettings.ExtraOffset,
				Size = Size or UDim2.new(1,0,1,0),
				frameSettings = frameSettings,
			})
		end
	end

	return updateData -- Return computed data
end

-- For parallel luau, for applying the step after computing changes in parallel
function ParallaxWindows:ApplyStep(stepData)
	if stepData == nil or #stepData <= 0 then return end -- Nothing to Update
	SetUpFolders(self) -- Run every step in case folder was deleted

	local Default_GuiSettings = self.Default_GuiSettings -- Default Settings
	local Default_FrameSettings = self.Default_FrameSettings

	for index,data: any in stepData do
		if data.istype == "frame" then
			local frame = data.frame
			if not frame or not frame:IsDescendantOf(self.GuiFolder) then -- Ignore deleted frames
				continue
			end

			local frameSettings = data.frameSettings

			-- set frame settings
			frame.ZIndex = frameSettings.ZIndex
			frame.Image = frameSettings.Image
			frame.Rotation = frameSettings.Rotation
			frame.ImageTransparency = frameSettings.ImageTransparency
			frame.BackgroundTransparency = frameSettings.BackgroundTransparency
			frame.ImageColor3 = frameSettings.ImageColor3
			frame.BackgroundColor3 = frameSettings.BackgroundColor3
			frame.ResampleMode = frameSettings.ResampleMode
			frame.ScaleType = frameSettings.ScaleType
			frame.TileSize = frameSettings.TileSize
			frame.Interactable = frameSettings.Interactable
			frame.Active = false--frameSettings.Active

			-- Set computed size and position
			frame.Position = data.Position
			frame.Size = data.Size
		elseif data.istype == "surface" then
			local surfaceGui = data.surfaceGui
			local GuiSettings = data.GuiSettings

			-- set surfaceGui settings
			surfaceGui.ZOffset = GuiSettings.ZOffset
			surfaceGui.AlwaysOnTop = GuiSettings.AlwaysOnTop
			surfaceGui.Brightness = GuiSettings.Brightness
			surfaceGui.LightInfluence = GuiSettings.LightInfluence
			surfaceGui.MaxDistance = GuiSettings.MaxDistance
			surfaceGui.PixelsPerStud = GuiSettings.PixelsPerStud
			surfaceGui.SizingMode = GuiSettings.SizingMode
		end
	end
end

return ParallaxWindows
