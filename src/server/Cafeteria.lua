-- Contains methods to run simulations in the cafeteria

local ServerScriptService = game:GetService("ServerScriptService")

local student = require(ServerScriptService.Server.Student)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).CAFETERIA

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
	local id = #self.Students
	local newStudent = student.new()
	table.insert(self.Students, newStudent)
	newStudent.Character.Name = "Student" .. tostring(id)
	newStudent.States.ID = id
	newStudent.Character:SetAttribute("ID", id)
	newStudent.Character:SetAttribute("LookingAt", nil)

	newStudent:enterRoom(self.SpawnArea)
	newStudent:getFood(self.ServingArea)
	task.wait(CONFIGURATION.SERVING_DURATION)

	newStudent:findSeat(self.Seats)
	task.wait(CONFIGURATION.EATING_DURATION)

	newStudent:disposeTrash(self.DisposalAreas)
	task.wait(CONFIGURATION.DISPOSING_DURATION)

	newStudent:exitRoom(self.SpawnArea)

end

function module:start()	
	task.wait(CONFIGURATION.SIMULATION_DELAY)

	for count = 1, CONFIGURATION.SPAWN_AMOUNT, 1 do
		local spawnStudentTask = coroutine.create(self.spawnStudent)
		coroutine.resume(spawnStudentTask, self)
		task.wait(CONFIGURATION.SPAWN_DELAY)
	end

end

return module
