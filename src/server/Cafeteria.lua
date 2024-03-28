-- Contains methods to run simulations in the cafeteria

local ServerScriptService = game:GetService("ServerScriptService")

local student = require(ServerScriptService.Server.Student)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).Cafeteria

local module = {}
module.__index = module

function module.new()
	local self = setmetatable({
		Room = nil,
		SpawnArea = nil,
		ServingArea = {
			Start = nil,
			End = nil,
		},
		Seats = {},
		DisposalArea = {
			Start = nil,
			End = nil,
		}
	}, module)
	
	return self
end

function module:setRoom(room, spawnArea, servingArea, disposalArea)
	self.Room = room
	self.SpawnArea = spawnArea
	self.ServingArea = servingArea
	self.DisposalArea = disposalArea
end

function module:addSeat(seat)
	table.insert(self.Seats, {
		Seat = seat,
		Owner = nil,
	})
end

function module:spawnStudent()
	local newStudent = student.new()

	newStudent:enterRoom(self.SpawnArea)
	newStudent:getFood(self.ServingArea)
	newStudent:findSeat(self.Seats)
	task.wait(CONFIGURATION.EatingDuration)
	newStudent:disposeTrash(self.DisposalArea)
	newStudent:exitRoom(self.SpawnArea)

end

function module:start()	
	task.wait(CONFIGURATION.SimulationDelay)

	for count = 1, CONFIGURATION.MaxCapacity, 1 do
		print("Spawning student " .. tostring(count) .. "...")
		local spawnStudentTask = coroutine.create(self.spawnStudent)
		coroutine.resume(spawnStudentTask, self)

		task.wait(CONFIGURATION.SpawnDelay)
	end

end

return module
