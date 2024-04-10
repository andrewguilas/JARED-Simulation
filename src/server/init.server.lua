-- Initializes the cafeteria and runs the simulation

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local Cafeteria = require(ServerScriptService.Server.Cafeteria)
local UIHandler = require(ServerScriptService.Server.UI)

local newRoom = Workspace.Room
local npcStorage = Workspace.NPCs
local UI = StarterGui.UI

local function main()
	UIHandler.new(UI, npcStorage)

	local newCafeteria = Cafeteria.new()

	newCafeteria:setRoom(
		newRoom,
		newRoom.Floor.SpawnArea,
		{
			newRoom.ServingArea.Path.Point1,
			newRoom.ServingArea.Path.Point2,
			newRoom.ServingArea.Path.Point3,
			newRoom.ServingArea.Path.Point4,
			newRoom.ServingArea.Path.Point5,
			newRoom.ServingArea.Path.Point6,
			newRoom.ServingArea.Path.Point7,
			newRoom.ServingArea.Path.Point8,
			newRoom.ServingArea.Path.Point9,
			newRoom.ServingArea.Path.Point10,
		},
		{
			{Start = newRoom.DisposalArea.DisposalA.Path.DisposalAreaStart, End = newRoom.DisposalArea.DisposalA.Path.DisposalAreaEnd},
			{Start = newRoom.DisposalArea.DisposalB.Path.DisposalAreaStart, End = newRoom.DisposalArea.DisposalB.Path.DisposalAreaEnd},
		}
	)

	for _, table in ipairs(newRoom.Tables:GetChildren()) do
		for _, chair in ipairs(table:GetChildren()) do
			local seat = chair:FindFirstChildWhichIsA("Seat")
			if seat then
				seat.Disabled = true
				newCafeteria:addSeat(seat)
			end
		end
    end
	
	newCafeteria:start()
end

main()