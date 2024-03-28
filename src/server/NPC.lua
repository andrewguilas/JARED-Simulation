-- Contains default NPC methods

local PathFindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local CONFIGURATION = {
    AgentParameters = {
        AgentCanJump = true
    }
}

local module = {}
module.__index = module

function module.new()
    local self = setmetatable({
        Character = nil,
        Humanoid = nil,
        PrimaryPart = nil,
        Path = PathFindingService:CreatePath(CONFIGURATION.AgentParameters)
    }, module)

    return self
end

function module:walkTo(destinationPart)
	self.Path:ComputeAsync(self.PrimaryPart.Position, destinationPart.Position)

    local waypoints = self.Path:GetWaypoints()

	-- local visualizeWaypointsTask = coroutine.create(visualizeWaypoints)
	-- coroutine.resume(visualizeWaypointsTask, waypoints)

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
		print("Path blocked!")
		blockedConnection:Disconnect()
		blockedConnection = nil
	end)

	for _, waypoint in ipairs(waypoints) do
		if blockedConnection == nil then
			self:walkTo(destinationPart)
			return
		end

		self.Humanoid:MoveTo(waypoint.Position)
		self.Humanoid.MoveToFinished:Wait()
	end

end

function module:setWalkSpeed(walkSpeed)
	self.Humanoid.WalkSpeed = walkSpeed
end

function visualizeWaypoints(waypoints)
	for _, waypoint in ipairs(waypoints) do
		local waypointPart = Instance.new("Part")
		waypointPart.Shape = Enum.PartType.Ball
		waypointPart.Position = waypoint.Position
		waypointPart.BrickColor = BrickColor.new("White")
		waypointPart.Material = Enum.Material.Neon
		waypointPart.Parent = Workspace
		waypointPart.CanCollide = false
		waypointPart.Anchored = true
		waypointPart.Size = Vector3.new(1, 1, 1)

		Debris:AddItem(waypointPart, 3)
		task.wait(0.1)
	end
end

return module