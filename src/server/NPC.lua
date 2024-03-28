-- Contains default NPC methods

local PathFindingService = game:GetService("PathfindingService")

local CONFIGURATION = {
    AgentParameters = {
        AgentCanJump = false
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

	local blockedConnection
	blockedConnection = self.Path.Blocked:Connect(function()
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

return module