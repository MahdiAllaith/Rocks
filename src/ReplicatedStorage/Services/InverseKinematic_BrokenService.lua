local IK = {}
IK.__index = IK
IK.Settings = {}

-- GLOBAL SETTINGS --

IK.Settings.FootSurfaceOffset = Vector3.new(0, .15, 0)
IK.Settings.FootMaxDistanceDown = -10 
IK.Settings.ShouldAdjustHipHeight = true 


-- WARNING: Only edit if you know what you're doing

TS = game:GetService('TweenService')
RunService = game:GetService('RunService')

IK.new = function (player, rootscript)

	local self = setmetatable({}, IK)
	self._root = rootscript

	local player = game.Players.LocalPlayer
	local character = player.Character
	local humanoid = character.Humanoid

	humanoid.MaxSlopeAngle = 50 -- Looks better imo, although can edit if you'd like, Default Roblox value is 89

	self.SetupIKControllers(character)


	self._MoveDirectionConnection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if humanoid.MoveDirection.Magnitude > 0 then
			self.UpdateFootSurfaceWeights(0, .1)
		else
			self.UpdateFootSurfaceWeights(1, .5)
		end
	end)



	self._FreeFallingConnection = humanoid.FreeFalling:Connect(function(falling)
		if falling then
			self.UpdateFootSurfaceWeights(0, .1)
		else
			self.UpdateFootSurfaceWeights(1, .5)
		end

	end)



	self._RunConnection = RunService.RenderStepped:Connect(function()
		self:ComputeFootSurface(character)
	end)

	return self
end

IK._var = {}

IK._var.FootSurfaceCalculation = true -- Internal reference for if the calculations should take place.

IK._defaultAttributes = {
	["isFootPlantingEnabled"] = true
}

-- Setup player rig to be controlled by IK.
IK.SetupIKControllers = function(PlayerCharacter)
	DefaultHipHeight = PlayerCharacter.Humanoid.HipHeight
	-- Create IK Controllers
	IK.RightFootIKController = Instance.new('IKControl')
	IK.LeftFootIKController = Instance.new('IKControl')

	IK.RightFootIKController.Parent = PlayerCharacter.Humanoid
	IK.LeftFootIKController.Parent = PlayerCharacter.Humanoid
	--Setup Bone Structure
	IK.RightFootIKController.ChainRoot = PlayerCharacter.RightUpperLeg
	IK.RightFootIKController.EndEffector =  PlayerCharacter.RightFoot

	IK.LeftFootIKController.ChainRoot = PlayerCharacter.LeftUpperLeg
	IK.LeftFootIKController.EndEffector =  PlayerCharacter.LeftFoot
	-- Create Targets
	IK.RightFootIK = Instance.new('Attachment')
	IK.LeftFootIK = Instance.new('Attachment')

	IK.RightFootIK.Parent =  PlayerCharacter.RightFoot
	IK.LeftFootIK.Parent =  PlayerCharacter.LeftFoot

	IK.RightFootIK.WorldPosition = PlayerCharacter.RightFoot.Position + IK.Settings.FootSurfaceOffset
	IK.LeftFootIK.WorldPosition = PlayerCharacter.LeftFoot.Position + IK.Settings.FootSurfaceOffset
	-- Assign Targets to Controllers
	IK.RightFootIKController.Target = IK.RightFootIK
	IK.LeftFootIKController.Target =  IK.LeftFootIK

	--Constraint IK Joints
	local LeftConstraint = Instance.new('HingeConstraint')
	LeftConstraint.Parent = PlayerCharacter.LeftUpperLeg
	local RightConstraint = Instance.new('HingeConstraint')
	RightConstraint.Parent = PlayerCharacter.RightUpperLeg

	LeftConstraint.Attachment0 = (function() local a = Instance.new('Attachment') a.Position = PlayerCharacter.LeftUpperLeg.LeftKneeRigAttachment.Position a.Parent = PlayerCharacter.LeftUpperLeg return a end)()
	LeftConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LeftLowerLeg a.WorldPosition = PlayerCharacter.LeftUpperLeg.LeftKneeRigAttachment.WorldPosition return a end)()

	RightConstraint.Attachment0 = (function() local a = Instance.new('Attachment') a.Position = PlayerCharacter.RightUpperLeg.RightKneeRigAttachment.Position a.Parent = PlayerCharacter.RightUpperLeg return a end)()
	RightConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.RightLowerLeg a.WorldPosition = PlayerCharacter.RightUpperLeg.RightKneeRigAttachment.WorldPosition return a end)()

	local LeftFootConstraint = Instance.new('BallSocketConstraint')
	LeftFootConstraint.Parent = PlayerCharacter.LeftFoot
	local RightFootConstraint = Instance.new('BallSocketConstraint')
	RightFootConstraint.Parent = PlayerCharacter.RightFoot

	LeftFootConstraint.Attachment0 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LeftLowerLeg  a.Position = PlayerCharacter.LeftLowerLeg.LeftAnkleRigAttachment.Position return a end)()
	LeftFootConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LeftFoot  a.Position = PlayerCharacter.LeftFoot.LeftAnkleRigAttachment.Position return a end)()

	RightFootConstraint.Attachment0 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.RightLowerLeg  a.Position = PlayerCharacter.RightLowerLeg.RightAnkleRigAttachment.Position return a end)()
	RightFootConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.RightFoot  a.Position = PlayerCharacter.RightFoot.RightAnkleRigAttachment.Position return a end)()

	LeftFootConstraint.LimitsEnabled = true
	LeftFootConstraint.TwistLimitsEnabled = true
	LeftFootConstraint.TwistLowerAngle = -40
	LeftFootConstraint.TwistUpperAngle = 70
	RightFootConstraint.LimitsEnabled = true
	RightFootConstraint.TwistLimitsEnabled = true
	RightFootConstraint.TwistLowerAngle = -40
	RightFootConstraint.TwistUpperAngle = 70

	local LeftHipConstraint = Instance.new('BallSocketConstraint')
	LeftHipConstraint.Parent = PlayerCharacter.LowerTorso
	local RightHipConstraint = Instance.new('BallSocketConstraint')
	RightHipConstraint.Parent = PlayerCharacter.LowerTorso

	LeftHipConstraint.Attachment0 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LowerTorso a.Position = PlayerCharacter.LowerTorso.LeftHipRigAttachment.Position return a end)()
	LeftHipConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LeftUpperLeg  a.Position = PlayerCharacter.LeftUpperLeg.LeftHipRigAttachment.Position return a end)()

	RightHipConstraint.Attachment0 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.LowerTorso a.Position = PlayerCharacter.LowerTorso.RightHipRigAttachment.Position return a end)()
	RightHipConstraint.Attachment1 = (function() local a = Instance.new('Attachment')  a.Parent = PlayerCharacter.RightUpperLeg  a.Position = PlayerCharacter.RightUpperLeg.RightHipRigAttachment.Position return a end)()

	LeftHipConstraint.LimitsEnabled = true
	LeftHipConstraint.TwistLimitsEnabled = true
	LeftHipConstraint.TwistLowerAngle = -70
	LeftHipConstraint.TwistUpperAngle = 70
	RightHipConstraint.LimitsEnabled = true
	RightHipConstraint.TwistLimitsEnabled = true
	RightHipConstraint.TwistLowerAngle = -70
	RightHipConstraint.TwistUpperAngle = 70


	IK.UpdateFootSurfaceWeights = function(weight, Duration) -- dont call it if it doesn't exist (sorry)
		TS:Create(IK.LeftFootIKController, TweenInfo.new(Duration), {Weight = weight}):Play()
		TS:Create(IK.RightFootIKController, TweenInfo.new(Duration), {Weight = weight}):Play()

	end

end

function IK:ReadAttribute(attributeName)-- Reads one of the runtime settings of the IKController. IMPLEMENTATION TBD
	return IK._defaultAttributes[attributeName]
	--if self._root:GetAttribute(attributeName) then
	--	return self._root:GetAttribute(attributeName)
	--elseif IK._defaultAttributes[attributeName] then

	--	self._root:SetAttribute(attributeName, IK._defaultAttributes[attributeName])
	--	return IK._defaultAttributes[attributeName]
	--else 
	--	warn('IKController: No such attribute of: '.. attributeName ..' exists')
	--	return nil
	--end
end


function IK:ComputeFootSurface(PlayerCharacter) -- Calculates the IK positions ONCE, call on renderstepped to achieve full functionality.
	if IK._var.FootSurfaceCalculation == true and self:ReadAttribute('isFootPlantingEnabled') then

		local Velocity =  PlayerCharacter.HumanoidRootPart.Velocity.magnitude -- Unused, might bring back later.



		local RayParams = RaycastParams.new() 

		RayParams.FilterDescendantsInstances = {PlayerCharacter}
		RayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- cast downwards ray from each foot
		local RightRay = workspace:Raycast(PlayerCharacter.RightFoot.Position + Vector3.new(0,1,0), Vector3.new(0, IK.Settings.FootMaxDistanceDown,0), RayParams)
		local LeftRay = workspace:Raycast(PlayerCharacter.LeftFoot.Position + Vector3.new(0,1,0), Vector3.new(0, IK.Settings.FootMaxDistanceDown,0), RayParams)

		-- this is for visuals, I think it looks weird when a player just sits halfway on a ledge, this was an attempt to rectify that
		if RightRay and LeftRay then
			if (RightRay.Position - PlayerCharacter.RightFoot.Position).Magnitude > 4.4 or (LeftRay.Position - PlayerCharacter.LeftFoot.Position).Magnitude > 4.4 and IK.Settings.ShouldAdjustHipHeight  then
				PlayerCharacter.Humanoid.HipHeight = DefaultHipHeight - .4
			else
				PlayerCharacter.Humanoid.HipHeight = DefaultHipHeight
			end
		end


		-- A whole lot of vector math that I barely understand, good luck.
		-- Foot IKTarget at the Position of the RayHit (the ground), and rotate based on the surface normal
		if RightRay then
			IK.RightFootIK.WorldCFrame = CFrame.fromMatrix(RightRay.Position + IK.Settings.FootSurfaceOffset, RightRay.Normal:Cross(PlayerCharacter.HumanoidRootPart.CFrame.RightVector), PlayerCharacter.HumanoidRootPart.CFrame.RightVector, RightRay.Normal) * CFrame.Angles(0,math.rad(90),math.rad(90))
		end
		if LeftRay then
			IK.LeftFootIK.WorldCFrame = CFrame.fromMatrix(LeftRay.Position + IK.Settings.FootSurfaceOffset, LeftRay.Normal:Cross(PlayerCharacter.HumanoidRootPart.CFrame.RightVector), PlayerCharacter.HumanoidRootPart.CFrame.RightVector, LeftRay.Normal) * CFrame.Angles(0,math.rad(90),math.rad(90))
		end


	else

	end


end


return IK