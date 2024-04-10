-- Contains default NPC methods

local PathFindingService = game:GetService("PathfindingService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local CONFIGURATION = require(ServerScriptService.Server.Configuration).STUDENT

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
			Wood = 3,
			Concrete = 2,
			SmoothPlastic = 1,
			PathA = 1,
			PathB = 1,
			PathC = 1,
			PathD = 1,
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
		if name == "AgentCanJump" then
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
	self.Path:ComputeAsync(self.Character.HumanoidRootPart.Position, destinationPart.Position)
	if self.Path.Status == Enum.PathStatus.NoPath then
		self:walkTo(destinationPart)
		return
	end

    local waypoints = self.Path:GetWaypoints()

	-- local visualizeWaypointsTask = coroutine.create(self.visualizeWaypoints)
	-- coroutine.resume(visualizeWaypointsTask, self, waypoints, true)

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
		blockedConnection:Disconnect()
		blockedConnection = nil
	end)

	for _, waypoint in ipairs(waypoints) do
		if blockedConnection == nil then
			-- print("Path blocked!")
			task.wait(1)
			self:destroyWaypoints()
			self:walkTo(destinationPart)
			return
		end

		self.Humanoid:MoveTo(waypoint.Position)
		local success = self.Humanoid.MoveToFinished:Wait(3)
		if not success then
			-- print("Couldn't make it!")
			blockedConnection:Disconnect()
			blockedConnection = nil
			task.wait(1)
			self:destroyWaypoints()
			self:walkTo(destinationPart)
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

			-- if both npc's are looking at each other,
			-- the npc with the lower id will act
			if otherNPC:GetAttribute("LookingAt") == self.Character.Name then
				local otherNPCID = otherNPC:GetAttribute("ID")
				if otherNPCID > self.States.ID then
					return otherNPC, raycastResult.Distance
				else
					return nil
				end
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
		else
			self:setWalkSpeed(CONFIGURATION.MAX_WALK_SPEED)
		end

		task.wait(0.5)
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