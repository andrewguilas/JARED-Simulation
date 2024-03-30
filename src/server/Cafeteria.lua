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
		},
		Students = {},
	}, module)
	
	return self
end

function module:setRoom(room, spawnArea, servingArea, disposalAreas)
	self.Room = room
	self.SpawnArea = spawnArea
	self.ServingArea = servingArea
	self.DisposalAreas = disposalAreas
end

function module:addSeat(seat)
	table.insert(self.Seats, {
		Seat = seat,
		Owner = nil,
	})
end

function module:spawnStudent()
	local newStudent = student.new()
	table.insert(self.Students, newStudent)
	newStudent.Character.Name = "Student" .. tostring(#self.Students)

	newStudent:enterRoom(self.SpawnArea)
	newStudent:getFood(self.ServingArea)
	newStudent:findSeat(self.Seats)
	task.wait(CONFIGURATION.EatingDuration)

	newStudent:disposeTrash(self.DisposalAreas)
	newStudent:exitRoom(self.SpawnArea)

end

function module:start()	
	task.wait(CONFIGURATION.SimulationDelay)

	for count = 1, CONFIGURATION.MaxCapacity, 1 do
		local spawnStudentTask = coroutine.create(self.spawnStudent)
		coroutine.resume(spawnStudentTask, self)
		task.wait(CONFIGURATION.SpawnDelay)
	end

end

return module
