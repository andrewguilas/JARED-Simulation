--[[

    Handler for NPC related methods

]]

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local PARAMETERS = require(script.Parent.Parameters)
local DataCollection = require(script.Parent.DataCollection)

local function showWaypoints(waypoints, waypointParts, color, duration)
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
		waypointPart.BrickColor = color
		waypointPart.Material = Enum.Material.Neon
		waypointPart.CanCollide = false
		waypointPart.Anchored = true
		waypointPart.Size = Vector3.new(1, 1, 1)
		waypointPart.Parent = waypointsFolder

		table.insert(waypointParts, waypointPart)

        if duration then
		    Debris:AddItem(waypointPart, duration)
        end

        task.wait()
	end

end

local function destroyWaypoints(waypointParts)
	for _, waypointPart in ipairs(waypointParts) do
		waypointPart:Destroy()
	end
end

local function checkCollision(character, npcStorage)
	local rayOrigin = character.Torso.CFrame.p
	local rayDirection = character.Torso.CFrame.lookVector * PARAMETERS.STUDENT.SLOW_DISTANCE
	
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

    -- if other npc is sitting in a chair, go through them
    if otherNPC.Humanoid.Sit == true then
		character:SetAttribute("LookingAt", nil)
        return false
    end

	character:SetAttribute("LookingAt", otherNPC.Name)

	if character:GetAttribute("LookingAt") == otherNPC.Name and otherNPC:GetAttribute("LookingAt") == character.Name then
		DataCollection.addCollision(npcStorage.Parent.Name, character)
		-- return otherNPC, raycastResult.Distance
	end

	-- if npc spawned first (has a lower id), go through them
	if character:GetAttribute("ID") < otherNPC:GetAttribute("ID") then	
		return false
	end
	
    return otherNPC, raycastResult.Distance
end

local function calculateWalkSpeed(distance)
	return math.round(PARAMETERS.STUDENT.MAX_WALK_SPEED + 3 * (distance - PARAMETERS.STUDENT.SLOW_DISTANCE))
end

function module.new(id)
    return setmetatable({
        Character = nil,
        Humanoid = nil,
        PrimaryPart = nil,
        Path = nil,
		WaypointParts = {},
        ID = id,
		CafeteriaModel = nil,
    }, module)
end

function module:spawn(npcTemplate, position, agentParameters)
    self.Character = npcTemplate:Clone()
    self.Character.Parent = self.CafeteriaModel.NPCs
    self.Character.Name = "Student" .. tostring(self.ID)
    self.Character:SetAttribute("ID", self.ID)
	self.Character:SetAttribute("StoppedDuration", 0)
	self.Character:SetAttribute("ShowWaypoints", false)
    self.Character:MoveTo(position)

	self.Humanoid = self.Character.Humanoid
	self.PrimaryPart = self.Character.PrimaryPart
	self.Path = PathfindingService:CreatePath(agentParameters)

    coroutine.wrap(self.updateWalkSpeed)(self)
end

function module:despawn()
    self.Character:Destroy()

    -- Cleanup
	if self.Seat then
		self.Seat.Owner = nil
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
		task.wait(PARAMETERS.STUDENT.UPDATE_DELAY)
		self:walkTo(destinationPart)
		return
	end

    local waypoints = self.Path:GetWaypoints()
	if PARAMETERS.STUDENT.SHOW_WAYPOINTS or self.Character:GetAttribute("ShowWaypoints") then
		coroutine.wrap(showWaypoints)(waypoints, self.WaypointParts, BrickColor.new("White"))
	end

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
		blockedConnection:Disconnect()
		blockedConnection = nil
	end)

	for _, waypoint in ipairs(waypoints) do
		if blockedConnection == nil then
		    -- print(string.format("Student%s: Path blocked", self.ID))

			task.wait(PARAMETERS.STUDENT.UPDATE_DELAY)
			destroyWaypoints(self.WaypointParts)
			self:walkTo(destinationPart)
			return
		end

		self.Humanoid:MoveTo(waypoint.Position)

		local success = self.Humanoid.MoveToFinished:Wait()
		if not success then
			-- print(string.format("Student%s: Couldn't finish path", self.ID))
			
			if blockedConnection then
				blockedConnection:Disconnect()
				blockedConnection = nil
			end

			task.wait(PARAMETERS.STUDENT.UPDATE_DELAY)
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
		task.wait(PARAMETERS.STUDENT.UPDATE_DELAY)

		if not self.Character:FindFirstChild("Torso") then
			return
		end

		local m = PARAMETERS.SIMULATION.LAYOUTS[self.CafeteriaModel.Name].WALK_SPEED_CONSTANT or 1

		local currentStoppedDuration = self.Character:GetAttribute("StoppedDuration")
		local otherNPC, distance = checkCollision(self.Character, self.CafeteriaModel.NPCs)
		if otherNPC and currentStoppedDuration < 10 then
			self.Character.Head.BrickColor = BrickColor.new("Really red")
			local newWalkSpeed = calculateWalkSpeed(distance)
			self.Humanoid.WalkSpeed = newWalkSpeed * m

			if newWalkSpeed > 0 then
				self.Character:SetAttribute("StoppedDuration", currentStoppedDuration + PARAMETERS.STUDENT.UPDATE_DELAY)
			end
		else
			-- slowly accelerate
			if self.Humanoid.WalkSpeed == 0 then
				task.wait(0.5)
			end

			self.Character.Head.BrickColor = BrickColor.new("Bright yellow")
			self.Character:SetAttribute("StoppedDuration", 0)
			self.Humanoid.WalkSpeed = PARAMETERS.STUDENT.MAX_WALK_SPEED * m
		end


	end
end

return module