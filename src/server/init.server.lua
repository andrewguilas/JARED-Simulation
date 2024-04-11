-- Initializes the cafeteria and runs the simulation

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local Cafeteria = require(ServerScriptService.Server.Cafeteria)
local UIHandler = require(ServerScriptService.Server.UI)
local CONFIGURATION = require(ServerScriptService.Server.Configuration)

local newRoom = Workspace.Room
local npcStorage = Workspace.NPCs
local UI = StarterGui.UI

local function updateTime(timeMultiplier)
	CONFIGURATION.CAFETERIA.SPAWN_DELAY = CONFIGURATION.CAFETERIA.SPAWN_DELAY / timeMultiplier
	CONFIGURATION.STUDENT.MAX_WALK_SPEED = CONFIGURATION.STUDENT.MAX_WALK_SPEED * timeMultiplier
	CONFIGURATION.STUDENT.STOP_DELAY = CONFIGURATION.STUDENT.STOP_DELAY / timeMultiplier
	CONFIGURATION.STUDENT.SERVING_DURATION = CONFIGURATION.STUDENT.SERVING_DURATION / timeMultiplier
	CONFIGURATION.STUDENT.DISPOSING_DURATION = CONFIGURATION.STUDENT.DISPOSING_DURATION / timeMultiplier
end

local function main()
	local timeMultiplier = CONFIGURATION.CAFETERIA.SIMULATION_SPEED
	updateTime(timeMultiplier)

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
		newCafeteria:addTable(table)
    end
	
	newCafeteria:start()
end

main()