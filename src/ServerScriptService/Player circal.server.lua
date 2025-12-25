--local Players = game:GetService("Players")
--local CollectionService = game:GetService("CollectionService")

--local THROW_RADIUS = 60
--local CHECK_INTERVAL = 0.5 -- Seconds between range checks

---- 🌀 Create a circular indicator that follows the player using Attachments & Align
--local function createThrowCircle(player, rootPart)
--	local circle = Instance.new("Part")
--	circle.Name = "ThrowRadius_" .. player.Name
--	circle.Shape = Enum.PartType.Cylinder
--	circle.Size = Vector3.new(THROW_RADIUS * 2, THROW_RADIUS * 2 *2, THROW_RADIUS * 2*2)
--	circle.Anchored = false
--	circle.CanCollide = false
--	circle.Material = Enum.Material.ForceField
--	circle.BrickColor = BrickColor.new("Bright blue")
--	circle.Transparency = 0.6
--	circle.Parent = rootPart -- parent to rootPart

--	-- Create Attachments
--	local attachment0 = Instance.new("Attachment")
--	attachment0.Name = "RootAttachment"
--	attachment0.Parent = rootPart
--	attachment0.Position = Vector3.new(0, 0, 0)

--	local attachment1 = Instance.new("Attachment")
--	attachment1.Name = "CircleAttachment"
--	attachment1.Parent = circle
--	attachment1.Position = Vector3.new(0, 0, 0)
--	attachment1.Orientation = Vector3.new(0, 0, 90)

--	-- AlignPosition to keep circle at rootPart's position with an offset downwards
--	local alignPos = Instance.new("AlignPosition")
--	alignPos.Attachment0 = attachment1
--	alignPos.Attachment1 = attachment0
--	alignPos.RigidityEnabled = true
--	alignPos.MaxForce = 10000
--	alignPos.Parent = circle

--	-- AlignOrientation to keep circle flat on the ground regardless of player rotation
--	local alignOri = Instance.new("AlignOrientation")
--	alignOri.Attachment0 = attachment1
--	alignOri.Attachment1 = attachment0
--	alignOri.RigidityEnabled = true
--	alignOri.MaxTorque = 10000
--	alignOri.Parent = circle	
	

--	return circle
--end

---- 🏷️ Adds a tag to a player if not already tagged
--local function addInRangeTag(targetPlayer, sourcePlayer)
--	local tagName = "InRange_" .. sourcePlayer.Name
--	if not CollectionService:HasTag(targetPlayer, tagName) then
--		CollectionService:AddTag(targetPlayer, tagName)
--	end
--end

---- ❌ Removes tag from a player
--local function removeInRangeTag(targetPlayer, sourcePlayer)
--	local tagName = "InRange_" .. sourcePlayer.Name
--	if CollectionService:HasTag(targetPlayer, tagName) then
--		CollectionService:RemoveTag(targetPlayer, tagName)
--	end
--end

---- 🔁 Starts checking for other players inside the radius
--local THROW_RADIUS = 60

--local function startRadiusTracker(player, rootPart)
--	local circle = createThrowCircle(player, rootPart)
--	circle.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))

--	local touchingParts = {}

--	-- When something touches the circle
--	circle.Touched:Connect(function(hit)
--		if not touchingParts[hit] then
--			touchingParts[hit] = true

--			local hitPos = hit.Position
--			local distance = (rootPart.Position - hitPos).Magnitude

--			if distance > THROW_RADIUS then
--				print("Touched by:", hit.Name, "Parent:", hit.Parent and hit.Parent.Name, " — OUT OF RANGE! Distance:", distance)
--			else
--				print("Touched by:", hit.Name, "Parent:", hit.Parent and hit.Parent.Name, " — In Range. Distance:", distance)
--			end
--		end
--	end)

--	-- Check periodically which parts are no longer touching
--	while player.Parent and rootPart.Parent and circle.Parent do
--		for part, _ in pairs(touchingParts) do
--			-- If the part is destroyed or too far from the circle, consider it no longer touching
--			if not part or not part.Parent then
--				touchingParts[part] = nil
--				print("No longer touched by: destroyed part")
--			else
--				local distance = (circle.Position - part.Position).Magnitude
--				local TOUCH_THRESHOLD = 1.5 -- Adjust based on size

--				if distance > TOUCH_THRESHOLD then
--					touchingParts[part] = nil
--					print("No longer touched by:", part.Name, "Parent:", part.Parent and part.Parent.Name)
--				end
--			end
--		end
--		task.wait(0.2)
--	end
--end



---- 👋 Handle new players
--Players.PlayerAdded:Connect(function(player)
--	player.CharacterAdded:Connect(function(character)
--		local rootPart = character:WaitForChild("HumanoidRootPart", 5)
--		if rootPart then
--			startRadiusTracker(player, rootPart)
--		end
--	end)
--end)
