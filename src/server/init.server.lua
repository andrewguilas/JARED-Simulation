-- Initializes the cafeteria and runs the simulation

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Cafeteria = require(ServerScriptService.Server.Cafeteria)

local newRoom = Workspace.Room

local function main()
	local newCafeteria = Cafeteria.new()

	newCafeteria:setRoom(
		newRoom,
		newRoom.SpawnArea,
		{Start = newRoom.ServingArea.ServingAreaStart, End = newRoom.ServingArea.ServingAreaEnd},
		{Start = newRoom.DisposalArea.DisposalAreaStart, End = newRoom.DisposalArea.DisposalAreaEnd}
	)

	for _, seat in ipairs(newRoom.Seats:GetChildren()) do
        newCafeteria:addSeat(seat)
    end
	
	newCafeteria:start()
end

main()