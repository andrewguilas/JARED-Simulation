local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local npcStorage = Workspace.Cafeteria.NPCs

local function checkCollision(character, slowDistance)
	local rayOrigin = character.Torso.CFrame.p
	local rayDirection = character.Torso.CFrame.lookVector * slowDistance
	
    local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {npcStorage}
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not raycastResult then
        character:SetAttribute("LookingAt", nil)
        return false
    end

    local otherNPC = raycastResult.Instance.Parent
    if not otherNPC:FindFirstChild("Humanoid") then
        character:SetAttribute("LookingAt", nil)
        return false
    end

    character:SetAttribute("LookingAt", otherNPC.Name)

    -- if other npc is sitting in a chair, go through them
    if otherNPC.Humanoid.Sit == true then
        return false
    end

    -- if both npc's are looking at each other,
    -- the npc with without the right of way will stop
    if otherNPC:GetAttribute("LookingAt") == character.Name then
        -- if npc is further than other npc in the cafeteria (higher action code), they have the right of way
        if character:GetAttribute("ActionCode") > otherNPC:GetAttribute("ActionCode") then
            return false
        end

        -- if npc spawned first (has a lower id), they have the right of way
        if character:GetAttribute("ID") < otherNPC:GetAttribute("ID") then
            return false
        end
    end

    return otherNPC, raycastResult.Distance
end

local function calculateWalkSpeed(STUDENT_PARAMETERS, distance)
	local speed =STUDENT_PARAMETERS.MAX_WALK_SPEED * (1 / (1 + 2.718 ^ (-(distance -STUDENT_PARAMETERS.SLOW_DISTANCE))))
	if speed <= 1 then
		speed = 0
	end

	return speed
end

local function visualizeWaypoints(waypoints, isSuccess)
	local waypointsFolder = Workspace:FindFirstChild("Waypoints")
	if not waypointsFolder then
		waypointsFolder = Instance.new("Folder")
		waypointsFolder.Name = "Waypoints"
		waypointsFolder.Parent = Workspace
	end

    local waypointParts = {}

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

		table.insert(waypointParts, waypointPart)
		task.wait()
		-- Debris:AddItem(waypointPart, 5)
	end

    return waypointParts
end

local function destroyWaypoints(waypointParts)
	for _, waypointPart in ipairs(waypointParts) do
		waypointPart:Destroy()
	end
end

function module.new(id, PARAMETERS)
    local self = setmetatable({
        Character = nil,
        Humanoid = nil,
        PrimaryPart = nil,
        Path = PathfindingService:CreatePath(PARAMETERS.STUDENT.AGENT_PARAMETERS),
		WaypointParts = {},
        ID = id,
        PARAMETERS = PARAMETERS,
    }, module)

    return self
end

function module:spawn(npcTemplate, position)
    self.Character = npcTemplate:Clone()
    self.Character.Parent = npcStorage
    self.Character.Name = "Student" .. tostring(self.ID)
    self.Character:SetAttribute("ID", self.ID)
    self.Character:MoveTo(position)

	self.Humanoid = self.Character.Humanoid
	self.PrimaryPart = self.Character.PrimaryPart

    coroutine.wrap(self.updateWalkSpeed)(self)
end

function module:despawn()
    self.Character:Destroy()

    -- Cleanup
	if self.Seat then
		self.Seat.Owner = nil
		-- self.Seat.Seat.Material = Enum.Material.Wood
		-- self.Seat.Seat.BrickColor = BrickColor.new("Fawn brown")
	end
end

function module:giveTool(toolTemplate)
    local newTool = toolTemplate:Clone()
	newTool.Parent = self.Character
end

function module:walkTo(destinationPart)
    -- print(string.format("Student%s: Walking to %s at %s", self.ID, destinationPart.Name, tostring(destinationPosition))) 
	local destinationPosition = destinationPart.Position

	self.Path:ComputeAsync(self.Character.HumanoidRootPart.Position, destinationPosition)
	if self.Path.Status == Enum.PathStatus.NoPath then
		-- print(string.format("Student%s: No path", self.ID))
		task.wait(self.PARAMETERS.STUDENT.UPDATE_DELAY)
		self:walkTo(destinationPart)
		return
	end

    local waypoints = self.Path:GetWaypoints()
	if self.PARAMETERS.SHOW_WAYPOINTS or self.Character:GetAttribute("ShowWaypoints") then
		self.WaypointParts = coroutine.wrap(visualizeWaypoints)(waypoints, true)
	end

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
		blockedConnection:Disconnect()
		blockedConnection = nil
	end)

	for _, waypoint in ipairs(waypoints) do
		if blockedConnection == nil then
		    -- print(string.format("Student%s: Path blocked", self.ID))

			task.wait(self.PARAMETERS.STUDENT.UPDATE_DELAY)
			destroyWaypoints(self.WaypointParts)
			self:walkTo(destinationPart)
			return
		end

		-- 10 second max cooldown to resume walking
		for sec = 1, 5 / self.PARAMETERS.STUDENT.UPDATE_DELAY do
			if self.Humanoid.WalkSpeed ~= 0 then
				break
			end
            
			task.wait(self.PARAMETERS.STUDENT.UPDATE_DELAY)
		end

		self.Humanoid.WalkSpeed = self.PARAMETERS.STUDENT.MAX_WALK_SPEED

		self.Humanoid:MoveTo(waypoint.Position)

		local success = self.Humanoid.MoveToFinished:Wait()
		if not success then
			-- print(string.format("Student%s: Couldn't finish path", self.ID))
			
			if blockedConnection then
				blockedConnection:Disconnect()
				blockedConnection = nil
			end

			task.wait(self.PARAMETERS.STUDENT.UPDATE_DELAY)
			destroyWaypoints(self.WaypointParts)
			self:walkTo(destinationPart)
			return
		end
	end

    destroyWaypoints(self.WaypointParts)
	if blockedConnection then
		blockedConnection:Disconnect()
	end
end

function module:updateWalkSpeed()
	while true do
		if not self.Character:FindFirstChild("Torso") then
			return
		end

		local otherNPC, distance = checkCollision(self.Character, self.PARAMETERS.STUDENT.SLOW_DISTANCE)
		if otherNPC then
			local newWalkSpeed = calculateWalkSpeed(self.PARAMETERS.STUDENT, distance)
			self.Humanoid.WalkSpeed = newWalkSpeed

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
			self.Humanoid.WalkSpeed = self.PARAMETERS.STUDENT.MAX_WALK_SPEED
		end

		task.wait(self.PARAMETERS.STUDENT.UPDATE_DELAY)
	end
end

return module