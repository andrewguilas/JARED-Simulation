-- Initializes the cafeteria and runs the simulation

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Cafeteria = require(ServerScriptService.Server.Cafeteria)

local newRoom = Workspace.Room

local function main()
	local newCafeteria = Cafeteria.new()

	newCafeteria:setRoom(
		newRoom,
		newRoom.Floor.SpawnArea,
		{Start = newRoom.ServingArea.Path.ServingAreaStart, End = newRoom.ServingArea.Path.ServingAreaEnd},
		{Start = newRoom.DisposalArea.DisposalArea1.Path.DisposalAreaStart, End = newRoom.DisposalArea.DisposalArea1.Path.DisposalAreaEnd}
	)

	for _, table in ipairs(newRoom.Tables:GetChildren()) do
		for _, seat in ipairs(table:GetChildren()) do
			if seat:IsA("Seat") then
				seat.Disabled = true
				newCafeteria:addSeat(seat)
			end
		end
    end
	
	newCafeteria:start()
end

main()