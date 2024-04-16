-- Contains default NPC methods

local PathFindingService = game:GetService("PathfindingService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CONFIGURATION = require(ServerScriptService.Simulation.Configuration).STUDENT

local npcStorage = Workspace.NPCs

local module = {}
module.__index = module

function module.new()
    local self = setmetatable({
        Character = nil,
        Humanoid = nil,
        PrimaryPart = nil,
        Path = nil,
		WaypointParts = {},
		AgentParameters = {
			AgentCanJump = false,
			WaypointSpacing = 3,
			-- AgentRadius = 2,
			Wood = 3,
			Concrete = 2,
			SmoothPlastic = 1,
		},
		States = {
			MoveState = "WALK",
			ID = nil,
		}
    }, module)

	return self
end

function module:createPath(pathName)	
	for name, weight in pairs(self.AgentParameters) do
		if table.find({"AgentCanJump", "WaypointSpacing", "AgentRadius"}, name) then
			continue
		elseif name == pathName then
			self.AgentParameters[name] = 0.5
		elseif name == "Wood" then
			self.AgentParameters[name] = math.huge
		elseif name == "Concrete" then
			self.AgentParameters[name] = 2
		else
			self.AgentParameters[name] = 1
		end
	end

	self.Path = PathFindingService:CreatePath(self.AgentParameters)
end

function module:walkTo(destinationPart)
	local destinationPosition = Vector3.new(destinationPart.Position.X, self.Character.HumanoidRootPart.Position.Y, destinationPart.Position.Z)
	if CONFIGURATION.LOG_OUTPUT then 
		print(string.format("Student%s: Walking to %s at %s", self.States.ID, destinationPart.Name, tostring(destinationPosition))) 
	end

	self.Path:ComputeAsync(self.Character.HumanoidRootPart.Position, destinationPosition)
	if self.Path.Status == Enum.PathStatus.NoPath then
		if CONFIGURATION.LOG_OUTPUT then 
			print(string.format("Student%s: Walking to %s (no path)", self.States.ID, destinationPart.Name))
		end

		task.wait(0.5)
		self:walkTo(destinationPart)

		return
	end

    local waypoints = self.Path:GetWaypoints()

	if CONFIGURATION.SHOW_WAYPOINTS or self.Character:GetAttribute("ShowWaypoints") == true then
		coroutine.wrap(self.visualizeWaypoints)(self, waypoints, true)
	end

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
		blockedConnection:Disconnect()
		blockedConnection = nil
	end)

	for _, waypoint in ipairs(waypoints) do
		if blockedConnection == nil then
			if CONFIGURATION.LOG_OUTPUT then 
				print(string.format("Student%s: Walking to %s (path blocked)", self.States.ID, destinationPart.Name))
			end

			task.wait(0.5)
			self:destroyWaypoints()
			self:walkTo(destinationPart)
			
			return
		end

		-- 10 second max cooldown to resume walking
		for sec = 1, 10 * 2 do
			if self.Humanoid.WalkSpeed ~= 0 then
				break
			end
			task.wait(0.5)
		end

		self.Humanoid:MoveTo(waypoint.Position)

		local success = self.Humanoid.MoveToFinished:Wait(3)
		if not success then
			if CONFIGURATION.LOG_OUTPUT then 
				print(string.format("Student%s: Walking to %s (couldn't make it)", self.States.ID, destinationPart.Name))
			end
			
			if blockedConnection then
				blockedConnection:Disconnect()
				blockedConnection = nil
			end

			task.wait(0.5)
			self:destroyWaypoints()
			self:walkTo(destinationPart)
			return
		end
	end

	if blockedConnection then
		blockedConnection:Disconnect()
	end

	self:destroyWaypoints()
end

function module:checkCollision()
	local rayOrigin = self.Character.Torso.CFrame.p
	local rayDirection = self.Character.Torso.CFrame.lookVector * CONFIGURATION.SLOW_DISTANCE
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {npcStorage}
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult then
		local otherNPC = raycastResult.Instance.Parent
		if otherNPC:FindFirstChild("Humanoid") then
			self.Character:SetAttribute("LookingAt", otherNPC.Name)

			-- if other npc is sitting in a chair, go through it
			if otherNPC.Humanoid.Sit == true then
				return nil
			end

			-- if both npc's are looking at each other,
			-- the npc with without the right of way will stop
			if otherNPC:GetAttribute("LookingAt") == self.Character.Name then
				-- if other npc is further in the cafeteria (lower action code), they have the right of way
				if otherNPC:GetAttribute("ActionCode") < self.Character:GetAttribute("ActionCode") then
					return otherNPC, raycastResult.Distance
				end

				-- if other npc spawned first (has a higher id), they have the right of way
				local otherNPCID = otherNPC:GetAttribute("ID")
				if otherNPCID > self.States.ID then
					return otherNPC, raycastResult.Distance
				end

				return nil
			else
				return otherNPC, raycastResult.Distance
			end
		end
	end

	self.Character:SetAttribute("LookingAt", nil)
end

function module:setWalkSpeed(walkSpeed)
	self.Humanoid.WalkSpeed = walkSpeed
end

function module:calculateWalkSpeed(distance)
	local speed = CONFIGURATION.MAX_WALK_SPEED * (1 / (1 + 2.718 ^ (CONFIGURATION.WALK_SPEED_K * (distance - CONFIGURATION.SLOW_DISTANCE))))
	if speed <= 1 then
		speed = 0
	end

	return speed
end

function module:updateWalkSpeed()
	while true do
		if not self.Character:FindFirstChild("Torso") then
			return
		end

		local otherNPC, distance = self:checkCollision()
		if otherNPC then
			local newWalkSpeed = self:calculateWalkSpeed(distance)
			self:setWalkSpeed(newWalkSpeed)

			if newWalkSpeed == 0 then
				if self.Character:GetAttribute("StoppedDuration") == nil then
					self.Character:SetAttribute("StoppedDuration", 0)
				end
				self.Character:SetAttribute("StoppedDuration", self.Character:GetAttribute("StoppedDuration") + 0.5)
			else
				self.Character:SetAttribute("StoppedDuration", 0)
			end
		else
			self.Character:SetAttribute("StoppedDuration", 0)
			self:setWalkSpeed(CONFIGURATION.MAX_WALK_SPEED)
		end

		task.wait(0.25)
	end
end

function module:visualizeWaypoints(waypoints, isSuccess)
	local waypointsFolder = Workspace:FindFirstChild("Waypoints")
	if not waypointsFolder then
		waypointsFolder = Instance.new("Folder")
		waypointsFolder.Name = "Waypoints"
		waypointsFolder.Parent = Workspace
	end

	for _, waypoint in ipairs(waypoints) do
		local waypointPart = Instance.new("Part")
		waypointPart.Shape = Enum.PartType.Ball
		waypointPart.Position = waypoint.Position
		waypointPart.BrickColor = isSuccess and BrickColor.new("White") or BrickColor.new("Really red")
		waypointPart.Material = Enum.Material.Neon
		waypointPart.CanCollide = false
		waypointPart.Anchored = true
		waypointPart.Size = Vector3.new(1, 1, 1)
		waypointPart.Parent = waypointsFolder

		table.insert(self.WaypointParts, waypointPart)
		task.wait()
		-- Debris:AddItem(waypointPart, 5)
	end
end

function module:destroyWaypoints()
	for _, waypointPart in ipairs(self.WaypointParts) do
		waypointPart:Destroy()
	end
end

return module