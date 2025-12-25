--!optimize 2
--!native
--[[
This Module is Open Source. You can edit it however you like.
You don't need to credit me when you use it (But i would be happy if you would)
If you any ideas or you know how I can Optimize it, you can reply to my Post on Roblox DevForum.
If you don't know how this thing works, you can check my Post on DevForum. It is hard to use because i made it badly.

https://devforum.roblox.com/t/collideable-particles-fx-self-collisions-update-v32/2279402

!!!REMEMBER!!!
You shouldn't replace every Roblox Particles with this module because it can cause lag.
Even tho this module is optimized, making too many particles can affect performance on low end devices.
If you really need to simulate crazy amount of particles, you can try tweaking some setting to make it more performant at cost of accuracy.
]]
-- VERSION: 4.02
type BaseParticle = {Part:BasePart, Pos:vector, Velocity:vector, Delta:number, LifeTime:number, CamLastTime:boolean, Rand:number}
type Emitter = {
	EmmiterObject:BasePart?, --Object that will Emit Particles
	Folder:Folder?, --Folder where particles will be Parented to when created.
	Part:BasePart?, --Object that the emmiter will emmit.
	Enabled:boolean, --Determines whenever Emitter is Emitting Particles on it's own.

	Collisions:boolean, --Determines if Particles Collide with environment.
	ColliderSize:number, --Size of the collider.
	LifeOnCollision:number, --Lowers the particles lifetime after collision. Setting to 0 makes them disapear on collision, setting it to higher than max lifetime does nothing.
	CollisionChunkSize:number, --After update 4 collisions now use chunks to avoid using too many workspace calls for collisions. Basically set it to a value between 8-16.
	CollisionGroup:string, --Uses Roblox Collisions Groups. Change it to group particles will use for collisions.
	FixHumanoidCollisions:boolean, --As parts with CanCollide turned off no longer collide with particles, by enabling this, you can revert better collisions with players. Still in testing.

	Friction:number, --Changes how much sliding of Particles against surfaces slows them down.
	Bounce:number, --How strongly Particles Bounce. If 1, it bounces with the same velocity. If 0, it doesn't bounce at all. If 0.5, it decreases velocity by half when bouncing.
	Speed:NumberRange, --The starting speed of Particles when they are created.
	InheritSpeed:number, --Determines how much Emitter Velocity affects Particles Velocity
	Spread:Vector2, --The spread of Particles. If 0 they will all go in one direction.
	Rate:number, --How many Particles are created per second.
	LifeTime:NumberRange, --How long Particles will last.
	Drag:number, --How much air slows down the particles. 0.6 seems realistic.
	Acceleration:vector, --Force applied on Particles. Can be used to create Gravity.

	SelfCollisions:boolean, --Performance Hungry! (i think...). Basically makes it possible for collisions between particles.
	SelfCollType:"Default"|"Realistic"|"Fluid", --Type of Collision Algorithm to use when particles collide with eachother.
	Iterations:number, --Only used for Self Collisions. Collisions with environment are calculated at 60 fps. Makes Self Collisions more accurate at cost of performance.
	SelfSize:number, --Radius used for Collisions between particles, do not confuse with ColliderSize.
	Mass:number, --Used for Realistic Type Self Collisions.
	FluidForce:number, --Used for Fluid Type Self Collisions
	SimulateTurbulence:boolean, --Used for simulating. Well, wind turbulence. Objects affect wind, wind affects particles.

	MinimumCachce:number, --Makes it so that amount of cachced particles cannot be smaller than this number. Useful when creating explosions using Emit Function.
	FaceCamera:boolean, --Toggles whenever particles face the camera.
	CameraCulling:boolean, --Toggles whenever particles position update when they are not visible to camera. Should be mostly keep on unless facing issues. If particles use trails, use the TrailFix Property.
	CullingRadius:number?, --Defaults to ColliderSize if nil. Changes how big the sphere is that is used for CameraCulling. It is recommended to set it to the size of the Part that is being emitted in case ColliderSize property is smaller than part.
	RenderDistance:number, --Ingored when CameraCulling is Disabled. Changes how far particles can render. They are still simulated unless you disable the emitter.

	--Explanation on these in the DevForum Post.
	EveryFrame:nil | (Position:vector, Velocity:vector, LifeTime:number)->{[string]:any?},
	OnCollision:nil | (Position:vector, Velocity:vector, LifeTime:number, HitPart:BasePart)->{[string]:any?},
	OnSpawn:nil | (Position:vector, Velocity:vector, LifeTime:number)->{[string]:any?},
	OnDespawn:nil | ()->{[string]:any?},
	BeforePhysics:nil | ()->nil,

	Wind:boolean, --If true, Particles will be affected by wind.
	WindSpeed:number, --How fast wind flows.
	WindScale:number, --How frequent are the changes in the perlin noise of wind.
	WindDifference:NumberRange, --Controls the min and max force by wind. Setting it to (-1, 1) makes the particles sway in both ways.
	WindDirection:vector, --Direction of wind.
	--Wind Strenght is Deprecated. Similar result can be achieved with WindDifference property by setting it to (0, Strenght).

	DistanceFPS:number, --At which Distance Particles will update with lower FPS

	TrailFix:{{string}|string}|boolean|string, --Fix the annyoing Trails. Explanation on DevForum post.

	SyncToRenderToggle:(self: Emitter, boolean)->nil, --Should particles sync with Simulation or Rendering. If false, it will run at 60 fps (that's simulation fps). If true then it will sync with render which can make it look smoother when using more than 60 fps but can cause stuttering.
	AddForce:(self: Emitter)->nil,
	Emit:(self: Emitter, number)->nil,
	Destroy:(self: Emitter)->nil
}

local TheForcesTable = {
	["Repel"] = {["Type"] = "Repel", ["Position"] = vector.zero, ["Range"] = 12, ["Power"] = 15},
	["RepelConstant"] = {["Type"] = "RepelConstant", ["Position"] = vector.zero, ["Range"] = math.huge, ["Power"] = 15},
	["Turbulence"] = {["Type"] = "Turbulence", ["Position"] = vector.zero, ["Power"] = 15, ["Scale"] = 0.25}
}

type moduleType = {
	SelfCollType:{Default:"Default", Realistic:"Realistic", Fluid:"Fluid"}, --Enum
	TypeForce:{Repel:"Repel", RepelConstant:"RepelConstant", Turbulence:"Turbulence"}, --Enum
	NewForce:(string)->{}, --Returns a new force that can be used on emitter.
	new:()->Emitter
}

local module : moduleType = {}

module.SelfCollType = table.freeze {
	Default = "Default",
	Realistic = "Realistic",
	Fluid = "Fluid"
}

module.TypeForce = table.freeze {
	Repel = "Repel",
	RepelConstant = "RepelConstant",
	Turbulence = "Turbulence"
}
--Require a module used for Frustum Culling the particles.
local FRUSTUM = require(script._FrustumCulling)
--Require a module for collisions algorithms.
local CollisionAlgorithms = require(script._CollisionsAlgorithms)

local CollidersForShapes = {
	[Enum.PartType.Block] = CollisionAlgorithms.BoxSphereIntersectionOptimized,
	[Enum.PartType.Ball] = CollisionAlgorithms.BallSphereIntersectionOptimized,
	[Enum.PartType.Cylinder] = CollisionAlgorithms.CylinderSphereIntersectionOptimized,
}

local MeshCollFallback = CollisionAlgorithms.BoxSphereIntersectionOptimized

local Rand : Random = Random.new()
--Reflect vector off a surface normal.
local function Reflect(dir : vector, normal : vector)
	return (dir - (2 *  vector.dot(dir, normal) * normal))
end

local function GetGridPosition(Vec : vector, Size : number)
	return Vec // Size
end

local function ApplyProtertiesInstance(part : Instance, Properties : {})
	for name, val in pairs(Properties) do
		if typeof(val) == "table" then
			local Assign = part:FindFirstChild(name)
			ApplyProtertiesInstance(Assign, val)
		else
			part[name] = val
		end
	end
end
local function ApplyProperties(Properties:{})
	for part, pops in pairs(Properties) do
		for name, val in pairs(pops) do
			if typeof(val) == "table" then
				local Assign = part:FindFirstChild(name)
				ApplyProtertiesInstance(Assign, val)
			else
				part[name] = val
			end
		end
	end
end

--Pregenerate Vectors used to get Adjacent Cells in a Grid
local GridSearch : {vector} = {
	vector.create(1, 0, 0),
	-vector.create(1, 0, 0),
	vector.create(0, 1, 0),
	-vector.create(0, 1, 0),
	vector.create(0, 0, 1),
	-vector.create(0, 0, 1),
	vector.zero,
	vector.create(1, -1, -1),
	vector.create(1, -1, 0),
	vector.create(1, -1, 1),
	vector.create(0, -1, -1),
	vector.create(0, -1, 1),
	vector.create(-1, -1, -1),
	vector.create(-1, -1, 0),
	vector.create(-1, -1, 1),
	vector.create(1, 1, -1),
	vector.create(1, 1, 0),
	vector.create(1, 1, 1),
	vector.create(0, 1, -1),
	vector.create(0, 1, 1),
	vector.create(-1, 1, -1),
	vector.create(-1, 1, 0),
	vector.create(-1, 1, 1),
	vector.create(1, 0, 1),
	vector.create(-1, 0, 1),
	vector.create(1, 0, -1),
	vector.create(-1, 0, -1)

}

function module.NewForce(Type)
	return table.clone(TheForcesTable[Type])
end

--Lookup table that stores functions used when calculating forces on particles.
local AlghoritmForces = {
	["Repel"] = function(Forc, Pos, Vel) 
		if vector.magnitude(Pos - Forc.Position) < Forc.Range then
			return (Forc.Range - vector.magnitude(Pos - Forc.Position)) / Forc.Range * Forc.Power * vector.normalize(Pos - Forc.Position)
		else
			return vector.zero
		end
	end,
	["RepelConstant"] = function(Forc, Pos, Vel) 
		if vector.magnitude(Pos - Forc.Position) < Forc.Range then
			return Forc.Power * vector.normalize(Pos - Forc.Position)
		else
			return vector.zero
		end
	end,
	["Turbulence"] = function(Forc, Pos, Vel) 
		local ScaledForce = Forc.Position * Forc.Scale
		local ScaledPos = Pos* Forc.Scale
		return vector.create(math.noise( ScaledForce.X + ScaledPos.X, ScaledForce.Y, ScaledForce.Z), math.noise( ScaledForce.X, ScaledForce.Y + ScaledPos.Y, ScaledForce.Z), math.noise( ScaledForce.X, ScaledForce.Y, ScaledForce.Z + ScaledPos.Z)) * Forc.Power
	end
}

--Returns a new Emitter.
function module.new()
	debug.setmemorycategory("CollideableParticles") --Useful for debugging
	--You shouldn't change these Values in this script. You need to change them in your script, not in Module.
	local self : Emitter = {}
	self.EmmiterObject = nil --Object that will Emit Particles
	self.Folder = nil --Folder where particles will be Parented to when created.
	self.Enabled = false --Determines whenever Emitter is Emitting Particles on it's own.

	self.SelfCollType = "Realistic"
	self.SelfCollisions = false
	self.CollisionChunkSize = 8
	self.CollisionGroup = "Default"
	self.FixHumanoidCollisions = true
	self.Mass = 50
	self.Iterations = 1
	self.SelfSize = 1
	self.FluidForce = 1
	self.SimulateTurbulence = false
	self.Collisions = true
	self.LifeOnCollision = math.huge
	self.ColliderSize = 1
	self.Part = nil
	self.FaceCamera = false
	self.CameraCulling = true
	self.CullingRadius = nil
	self.RenderDistance = 512

	--You can find explanation of these functions on DevForum Post.
	self.EveryFrame = nil
	self.OnCollision = nil
	self.OnSpawn = nil
	self.OnDespawn = nil
	self.BeforePhysics = nil

	self.MinimumCachce = 20
	self.Friction = 0.6
	self.Bounce = 1
	self.Speed = NumberRange.new(1)
	self.InheritSpeed = 0
	self.Spread = Vector2.new(0, 0)
	self.Rate = 5
	self.LifeTime = NumberRange.new(1)
	self.Drag = 0
	self.Acceleration = vector.zero

	self.Wind = false
	self.WindSpeed = 0.8
	self.WindScale = 0.3
	self.WindDifference = NumberRange.new(0, 1)
	self.WindDirection = vector.create(50, 0, 0)

	self.DistanceFPS = 30
	self.TrailFix = false

	local Forces = {}
	local Particles : {BaseParticle} = {}
	local Cachce : {BasePart} = {}
	local Frame : number = 0
	local Index : number = 0

	function self:AddForce(Force)
		table.insert(Forces, Force)
	end

	--This is a function that you can use to emit particles by yourself. Useful for explosions.
	local function Emit(Rate)
		local Tabel = {}
		local SpreadX : number = self.Spread.X
		local SpreadY : number = self.Spread.Y
		local EmiCFrame : CFrame = self.EmmiterObject.CFrame
		local Size : vector = self.EmmiterObject.Size
		for i : number = 1, Rate do
			Index += 1
			local New = {}
			if #Cachce > 0 then
				New.Part = table.remove(Cachce, #Cachce)
			else
				New.Part = self.Part:Clone()
			end
			New.Part.CanCollide = false
			New.Part.CanTouch = false
			New.Part.CanQuery = false
			New.Part.Anchored = true
			New.Part.Locked = true
			New.Part.Parent = self.Folder

			New.LifeTime = Rand:NextNumber(self.LifeTime.Min, self.LifeTime.Max)
			New.Velocity = vector.zero
			New.Velocity = ((EmiCFrame * CFrame.Angles(math.rad(Rand:NextNumber(-SpreadX, SpreadX)), math.rad(Rand:NextNumber(-SpreadY, SpreadY)), 0)).LookVector * Rand:NextNumber(self.Speed.Min, self.Speed.Max)) + (self.EmmiterObject.AssemblyLinearVelocity * self.InheritSpeed)

			New.Pos = EmiCFrame.Position + EmiCFrame.RightVector *(Rand:NextNumber(-Size.X, Size.X) / 2) + EmiCFrame.UpVector * (Rand:NextNumber(-Size.Y, Size.Y) / 2) + EmiCFrame.LookVector * (Rand:NextNumber(-Size.Z, Size.Z) / 2)
			New.CamLastTime = false

			New.Delta = 0
			New.Rand = Rand:NextInteger(1, 1024)
			table.insert(Particles, 1, New)
			Index %= 12
			if self.OnSpawn then
				Tabel[New.Part] = self.OnSpawn(New.Pos, New.Velocity, 1)
			end
		end
		return Tabel	

	end

	function self:Emit(Ammount)
		local Properties = {}
		local Sav = Emit(Ammount)
		for i, v in pairs(Sav) do
			Properties[i] = v
		end
		for part, pops in pairs(Properties) do
			for name, val in pairs(pops) do
				part[name] = val
			end
		end
	end

	local Last :number = 0
	local Now :number = 0

	local function AdvanceTime(dt)
		Frame %= 36000
		Frame += 1
		local Properties = {}
		if self.Enabled and self.EmmiterObject then
			Now += dt
			local Rate :number = 1 / self.Rate
			local This :number = (Now - Last)
			if Now > Last + Rate then
				local Sav = Emit(This // Rate)
				for i, v in pairs(Sav) do
					Properties[i] = v
				end
				Last += (This // Rate) * Rate
			end
		else
			Last = Now
		end
		if Frame % 36 == 0 then
			if #Cachce > self.MinimumCachce then
				for i = 1, math.ceil((#Cachce - self.MinimumCachce) * 0.5) do
					Cachce[i]:Destroy()
					table.remove(Cachce, i)
				end
			end
		end
		local ColParams :OverlapParams = OverlapParams.new()
		ColParams.FilterType = Enum.RaycastFilterType.Exclude
		ColParams.FilterDescendantsInstances = {self.EmmiterObject, self.Folder}
		ColParams.CollisionGroup = self.CollisionGroup
		ColParams.RespectCanCollide = true
		local RayParams :RaycastParams = RaycastParams.new()
		RayParams.FilterType = Enum.RaycastFilterType.Exclude
		RayParams.FilterDescendantsInstances = {self.EmmiterObject, self.Folder}
		RayParams.CollisionGroup = self.CollisionGroup
		RayParams.RespectCanCollide = true
		if self.BeforePhysics then
			self.BeforePhysics()
		end
		task.desynchronize()
		local ColliderChunks : {[vector]:{BasePart}} = {}
		local Grid = {}
		local Parts : {BasePart} = {}
		local CFrames : {CFrame} = {}
		local TrailFixes : {[Part]:boolean} = {}
		local Cam : Camera = workspace.CurrentCamera
		local CamCFrame : CFrame = Cam.CFrame
		local CameraPlanes = FRUSTUM.getFrustum(Cam, self.RenderDistance)
		local GameTime : number = workspace.DistributedGameTime

		if Cam then
			local CamPos : vector? = nil
			if self.FaceCamera then
				CamPos = CamCFrame.Position
			end
			--debug.profilebegin("Particles") for some reason it's broken so don't use it
			for ind, this in pairs(Particles) do
				this.Delta += dt
				local thisPos : vector = this.Pos
				local thisVelocity : vector = this.Velocity
				local thisDelta : number = this.Delta
				for i, Forc in pairs(Forces) do
					thisVelocity += AlghoritmForces[Forc.Type](Forc, thisPos, thisVelocity) * dt
				end
				if (Frame + this.Rand) % math.ceil(vector.magnitude(CamCFrame.Position - thisPos) / self.DistanceFPS) == 0 then
					this.LifeTime -= thisDelta
					if this.LifeTime <= 0 then
						table.insert(Parts, this.Part)
						table.insert(CFrames, CFrame.new(0, -100, 0))
						if self.TrailFix then
							TrailFixes[this.Part] = false
						end
						table.insert(Cachce, this.Part)
						table.remove(Particles, ind)
						if self.OnDespawn then
							Properties[this.Part] = self.OnDespawn()
						end
						continue
					end
					local LastGrid : vector = GetGridPosition(thisPos, self.SelfSize)
					if self.SimulateTurbulence then
						--Fakes Objects Interacting with Wind which affects Particles
						local Colliders :{BasePart} = workspace:GetPartBoundsInRadius(thisPos, self.ColliderSize + 5, ColParams)
						local Moving : number = 0
						for i, v : BasePart in pairs(Colliders) do
							if vector.magnitude(v.AssemblyLinearVelocity) > 0.1 then
								Moving += 1
							end
						end
						for i, v : BasePart in pairs(Colliders) do
							if vector.magnitude(v.AssemblyLinearVelocity) > 0.1 then
								--this.Velocity += (v.Position - this.Pos).Unit:Cross(v.AssemblyLinearVelocity.Unit) * v.AssemblyLinearVelocity.Magnitude * this.Delta * 1
								local angle :number = math.acos(vector.dot(vector.normalize(v.AssemblyLinearVelocity), vector.normalize(thisPos-v.Position)))
								if angle < math.rad(80) then
									--This is Repel
									thisVelocity += (thisPos - ((CFrame.lookAt(v.Position, v.Position + v.AssemblyLinearVelocity) * CFrame.Angles(math.rad(25), 0, 0)).LookVector * vector.magnitude(thisPos - v.Position) + v.Position)) * thisDelta * vector.magnitude(v.AssemblyLinearVelocity) * 0.3 * (1 / Moving)

								else
									--This is Attract
									thisVelocity -= (thisPos - ((CFrame.lookAt(v.Position, v.Position + v.AssemblyLinearVelocity) * CFrame.Angles(math.rad(-5), 0, 0)).LookVector * vector.magnitude(thisPos - v.Position) + v.Position)) * thisDelta * vector.magnitude(v.AssemblyLinearVelocity) * 0.09 * (1 / Moving)

								end

							end
						end
					end

					local AlongSurfaceDir : vector?
					local Collided = false
					thisVelocity += self.Acceleration * thisDelta --Calculate Acceleration
					if self.Wind then
						thisVelocity += (self.WindDifference.Min + (self.WindDifference.Max - self.WindDifference.Min) * (math.noise(thisPos.X * self.WindScale, thisPos.Y * self.WindScale + GameTime * self.WindSpeed, thisPos.Z * self.WindScale) + 0.5)) * self.WindDirection * thisDelta
					end
					thisVelocity += (self.Drag*vector.magnitude(thisVelocity)*2*vector.normalize(-thisVelocity)) * thisDelta -- Simulate Air Drag
					thisVelocity = thisVelocity == thisVelocity and thisVelocity or vector.zero
					thisPos += thisVelocity * thisDelta --Move the Particle

					if self.Collisions then
						local Chunk : vector = thisPos // self.CollisionChunkSize
						local Col : {BasePart} = ColliderChunks[Chunk]
						if Col == nil then
							Col = workspace:GetPartBoundsInBox(CFrame.new((thisPos // self.CollisionChunkSize) * (vector.one * self.CollisionChunkSize) + vector.one * (self.CollisionChunkSize*0.5)), vector.one * (self.ColliderSize*2 + self.CollisionChunkSize), ColParams)
							if self.FixHumanoidCollisions then
								for colliderI, collider : BasePart in Col do
									if collider.Name == "HumanoidRootPart" then
										for connectedI, connected in collider:GetConnectedParts(true) do
											if not connected.CanCollide then
												if connected.Name ~= "Handle" and connected.Name ~= "HumanoidRootPart" then
													table.insert(Col, connected)
												end
											end
										end
									end
								end
							end
							ColliderChunks[Chunk] = Col
						end
						if #Col > 0 then
							for i, Coller in pairs(Col) do
								local Inside : boolean, Push : vector, Normal : vector
								if Coller:IsA("Part") then
									Inside, Push, Normal = (CollidersForShapes[Coller.Shape] or MeshCollFallback)(Coller.CFrame, Coller.Size, thisPos, self.ColliderSize)
								else
									Inside, Push, Normal = MeshCollFallback(Coller.CFrame, Coller.Size, thisPos, self.ColliderSize)
								end
								if Inside then
									Collided = Coller
									local CalculatedVel : vector = vector.zero
									--local Inside, Push, Normal = BoxPointIntersection(v.CFrame, v.Size, this.Pos)
									--CalculatedPos += (Push + (Normal * (ColliderSize / 2 + 0.01))) - this.Pos
									--CalculatedVel += v.AssemblyLinearVelocity + v.AssemblyAngularVelocity:Cross(this.Pos - v.Position)
									CalculatedVel += Coller:GetVelocityAtPosition(thisPos)


									--this.Velocity += CalculatedVel - this.Velocity + this.Velocity * Bounce
									local relativeVelocity : vector = CalculatedVel - thisVelocity 

									-- Calculate velocity components along normal and tangent directions
									local velocityAlongNormal : number = vector.dot(relativeVelocity, Normal)
									local tangentVelocity : vector = relativeVelocity - Normal * velocityAlongNormal
									AlongSurfaceDir = tangentVelocity
									-- Calculate friction force
									local frictionMagnitude : number = -self.Friction * vector.magnitude(tangentVelocity)
									local frictionForce : vector = vector.normalize(-tangentVelocity) * frictionMagnitude

									-- Calculate bounce vector
									local bounceVector : vector = Normal * (velocityAlongNormal * (self.Bounce + 1))

									-- Calculate final velocity
									local finalVelocity : vector = bounceVector + (frictionForce * thisDelta)

									-- Apply final velocity
									thisVelocity = thisVelocity + finalVelocity
									--this.Pos = CalculatedPos
									thisPos = Push
									-- + this.Velocity * this.Delta
								end
							end
							--CalculatedVel /= #Col

						end
					end

					if Collided then
						this.LifeTime = math.min(this.LifeTime, self.LifeOnCollision)
					end

					if self.CameraCulling then
						local Frusted = FRUSTUM.findInFrustumSphere(CameraPlanes, thisPos, self.CullingRadius or self.ColliderSize)
						--local ben, onScreen = Cam:WorldToScreenPoint(this.Part.Position)
						if Frusted then
							if not this.CamLastTime then
								if self.TrailFix then
									TrailFixes[this.Part] = true
								end
							end
							this.CamLastTime = true
							table.insert(Parts, this.Part)
							table.insert(CFrames, CFrame.lookAt(thisPos, CamPos or (thisPos + (AlongSurfaceDir or thisVelocity))))
							if self.EveryFrame and (not Properties[this.Part]) then
								Properties[this.Part] = self.EveryFrame(thisPos, thisVelocity, this.LifeTime / self.LifeTime.Max)
							end
						else
							if this.CamLastTime then
								table.insert(Parts, this.Part)
								table.insert(CFrames, CFrame.new(0, -100, 0))
								if self.TrailFix then
									TrailFixes[this.Part] = false
								end
								this.CamLastTime = false
							end
						end
						if Collided and self.OnCollision then
							Properties[this.Part] = self.OnCollision(thisPos, thisVelocity, this.LifeTime / self.LifeTime.Max, Collided)
						end
					else 
						table.insert(Parts, this.Part)
						table.insert(CFrames, CFrame.lookAt(thisPos, CamPos or (thisPos + (AlongSurfaceDir or thisVelocity))))
						if Collided and self.OnCollision then
							Properties[this.Part] = self.OnCollision(thisPos, thisVelocity, this.LifeTime / self.LifeTime.Max, Collided)
						elseif self.EveryFrame and (not Properties[this.Part]) then
							Properties[this.Part] = self.EveryFrame(thisPos, thisVelocity, this.LifeTime / self.LifeTime.Max)
						end
					end
					this.Pos = thisPos
					this.Velocity = thisVelocity
					this.Delta = 0
				end

			end
			--debug.profileend()

			if self.SelfCollisions then
				debug.profilebegin("SelfCollide")
				local gridPositions = {}

				for i, this in pairs(Particles) do
					local that : vector = GetGridPosition(this.Pos, self.SelfSize)
					if that == that then
						if Grid[that] then
							Grid[that][i] = true
						else
							Grid[that] = { [i] = true }
						end
					end
					gridPositions[i] = that
				end

				for iteration = 1, self.Iterations do
					for ind, this in ipairs(Particles) do

						local NowGrid = gridPositions[ind]
						local CollsionsTable = {}
						for i, Search in pairs(GridSearch) do
							if Grid[NowGrid + Search] then
								for ii, other in pairs(Grid[NowGrid + Search]) do
									if other then
										CollsionsTable[ii] = other
									end
								end
							end
						end

						local thisPos : vector = this.Pos

						if self.SelfCollType == "Realistic" then
							for i, otrhe in pairs(CollsionsTable) do
								if i ~= ind then
									local other = Particles[i]
									local Dist = vector.magnitude(other.Pos - this.Pos)
									local Look = vector.normalize(this.Pos - other.Pos)
									local Relative = (this.Velocity - other.Velocity)
									if Dist < self.SelfSize then
										if i < ind then
											this.Pos += ((self.SelfSize - Dist) * Look) / self.Iterations
											this.Velocity -= (((1 + self.Bounce) * vector.dot(Relative, Look) / self.Mass) * Look) / self.Iterations
											other.Velocity += (((1 + self.Bounce) * vector.dot(Relative, Look) / self.Mass) * Look) / self.Iterations
										else
											this.Pos += ((self.SelfSize - Dist) * Look) / self.Iterations
											this.Velocity -= (((1 + self.Bounce) * vector.dot(Relative, Look) / self.Mass) * Look) / self.Iterations
											other.Velocity += (((1 + self.Bounce) * vector.dot(Relative, Look) / self.Mass) * Look) / self.Iterations

										end

									end
								end
							end
						elseif self.SelfCollType == "Default" then
							for i, otrhe in pairs(CollsionsTable) do
								if i ~= ind then
									local other = Particles[i]
									local Dist = vector.magnitude(other.Pos - this.Pos)
									local Look = vector.normalize(this.Pos - other.Pos)
									if Dist < self.SelfSize then
										if i < ind then
											this.Pos += ((self.SelfSize - Dist) / self.Iterations) * Look
											this.Velocity += ((self.SelfSize - Dist)  / self.Iterations) * Look
											this.Velocity += other.Velocity * (dt / self.Iterations) 
										else
											this.Pos += ((self.SelfSize - Dist) / (self.Iterations*2)) * Look
											this.Velocity += ((self.SelfSize - Dist)  / (self.Iterations*2)) * Look
											this.Velocity += other.Velocity * (dt / self.Iterations) 
										end

									end
								end
							end
						elseif self.SelfCollType == "Fluid" then
							for i, otrhe in pairs(CollsionsTable) do
								if i ~= ind then
									local other = Particles[i]
									local Dist = vector.magnitude(other.Pos - this.Pos)
									local Look = vector.normalize(this.Pos - other.Pos)
									if Dist < self.SelfSize then
										if i < ind then
											local Pow : vector = (self.FluidForce * (self.SelfSize - Dist)) / self.Iterations * Look
											this.Velocity += Pow
											other.Velocity -= Pow
											--this.Pos +=Pow
										else
											local Pow : vector = (self.FluidForce * (self.SelfSize - Dist)) / (self.Iterations*2) * Look
											this.Velocity += Pow
											other.Velocity -= Pow
											--this.Pos += Pow
										end

									end
								end
							end
						end

						local LastGrid : vector = NowGrid
						local JustGrid : vector = GetGridPosition(this.Pos, self.SelfSize)
						if not (JustGrid ~= JustGrid) then
							if LastGrid ~= NowGrid then
								if Grid[LastGrid] then
									Grid[LastGrid][ind] = nil
								end
								if Grid[JustGrid] then
									Grid[JustGrid][ind] = this
								else
									Grid[JustGrid] = {[ind] = this}
								end
								gridPositions[ind] = JustGrid
							end
						end

					end
				end
				debug.profileend()
			end


		end
		Forces = {}
		task.synchronize()
		workspace:BulkMoveTo(Parts, CFrames, Enum.BulkMoveMode.FireCFrameChanged)
		ApplyProperties(Properties)
		for Part, Toggle in TrailFixes do
			if typeof(self.TrailFix) == "string" then

				Part:FindFirstChild(self.TrailFix).Enabled = Toggle

			elseif typeof(self.TrailFix) == "table" then

				for i, ChildTable in self.TrailFix do
					if typeof(ChildTable) == "string" then
						Part:FindFirstChild(ChildTable).Enabled = Toggle
					elseif typeof(ChildTable) == "table" then

						local foundPart = Part
						for ii, nextChild in ChildTable do
							foundPart = foundPart:FindFirstChild(nextChild)
						end
						foundPart.Enabled = Toggle

					end
				end

			end

		end

	end

	local Step = game:GetService("RunService").PostSimulation:Connect(AdvanceTime)

	function self:SyncToRenderToggle(bool)
		Step:Disconnect()
		if bool then
			Step = game:GetService("RunService").PreRender:Connect(AdvanceTime)
		else
			Step = game:GetService("RunService").PostSimulation:Connect(AdvanceTime)
		end
	end

	function self:Destroy()
		Step:Disconnect()
		for i, v in ipairs(Particles) do
			v.Part:Destroy()
		end
		for i, v in ipairs(Particles) do
			table.remove(Particles, i)
		end
		for i, v in ipairs(Cachce) do
			v:Destroy()
		end
		for i, v in pairs(self) do
			self[i] = nil
		end
		self = nil
	end

	return self
end

return table.freeze(module)