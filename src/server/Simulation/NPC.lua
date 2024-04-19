--[[

    Handler for NPC related methods

]]

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local Waypoints = require(script.Parent.Waypoints)
local PARAMETERS = require(script.Parent.Parameters)

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

    -- if both npc's are looking at each other,
    -- the npc with without the right of way will stops
    if character:GetAttribute("LookingAt") == otherNPC.Name and otherNPC:GetAttribute("LookingAt") == character.Name then
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

local function calculateWalkSpeed(distance)
	return math.round(PARAMETERS.STUDENT.MAX_WALK_SPEED * (1 / (1 + 2.718 ^ (-(distance - PARAMETERS.STUDENT.SLOW_DISTANCE)))))
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
		self.WaypointParts = coroutine.wrap(Waypoints.show)(waypoints, BrickColor.new("White"))
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
			Waypoints.destroy(self.WaypointParts)
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
			Waypoints.destroy(self.WaypointParts)
			self:walkTo(destinationPart)
			return
		end
	end

    Waypoints.destroy(self.WaypointParts)
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

		local currentStoppedDuration = self.Character:GetAttribute("StoppedDuration")
		local otherNPC, distance = checkCollision(self.Character)
		if otherNPC and currentStoppedDuration < 10 then
			self.Character.Head.BrickColor = BrickColor.new("Really red")
			local newWalkSpeed = calculateWalkSpeed(distance)
			self.Humanoid.WalkSpeed = newWalkSpeed

			if newWalkSpeed > 0 then
				self.Character:SetAttribute("StoppedDuration", currentStoppedDuration + PARAMETERS.STUDENT.UPDATE_DELAY)
			end

			continue
		end

		self.Character.Head.BrickColor = BrickColor.new("Bright yellow")
		self.Character:SetAttribute("StoppedDuration", 0)
		self.Humanoid.WalkSpeed = PARAMETERS.STUDENT.MAX_WALK_SPEED
	end
end

return module