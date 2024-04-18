local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local module = {}

function module.show(waypoints, color, duration)
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

    return waypointParts
end

function module.destroy(waypointParts)
	for _, waypointPart in ipairs(waypointParts) do
		waypointPart:Destroy()
	end
end

return module