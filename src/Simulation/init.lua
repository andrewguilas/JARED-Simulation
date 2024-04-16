local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local Cafeteria = require(ServerScriptService.Simulation.Cafeteria)
local Student = require(ServerScriptService.Simulation.Student)
local UIHandler = require(ServerScriptService.Simulation.UI)

local newRoom = Workspace.Room
local npcStorage = Workspace.NPCs
local UI = StarterGui.UI

function module.new(parameters)
    local self = setmetatable({
        Parameters = parameters,
        Cafeteria = Cafeteria.new(newRoom),
        UI = UIHandler.new(UI, npcStorage),
        Students = {},
    }, module)

    return self
end

function module:spawnStudentsAtEntrance()
    print(string.format("Spawning students to enter at %s/sec...", self.Parameters.ENTRANCE_RATE))
    
    for studentCount = 1, self.Parameters.DURATION do
        local newStudent = Student.new()

        local id = #self.Students
        newStudent.Character.Name = "Student" .. tostring(id)
        newStudent.States.ID = id
        newStudent.Character:SetAttribute("ID", id)
        table.insert(self.Students, newStudent)

        coroutine.wrap(newStudent.enterRoom)(newStudent, self.Cafeteria.SpawnArea, self.Cafeteria.DespawnArea)
        task.wait(1)
    end
end

function module:spawnStudentsSeated()
    local studentsToLeave = {}
    local studentsToLeaveCount = self.Parameters.EXIT_RATE * self.Parameters.DURATION

    print(string.format("Spawning %s students in seats...", studentsToLeaveCount))
    for studentCount = 1, studentsToLeaveCount do
        local newStudent = Student.new()

        local id = #self.Students
        newStudent.Character.Name = "Student" .. tostring(id)
        newStudent.States.ID = id
        newStudent.Character:SetAttribute("ID", id)
        table.insert(self.Students, newStudent)
        table.insert(studentsToLeave, newStudent)

        newStudent:enterRoomSeated(self.Cafeteria.Seats)
        task.wait()
    end

    return studentsToLeave
end

function module:exitStudents(studentsToLeave)
    print(string.format("Making %s students exit at %s/sec...", #studentsToLeave, self.Parameters.EXIT_RATE))

    for _, student in ipairs(studentsToLeave) do
        coroutine.wrap(student.exitRoom)(student, self.Cafeteria.DisposalAreas, self.Cafeteria.SpawnArea)
        task.wait(1 / self.Parameters.EXIT_RATE)
    end
end

function module:run()
    self.UI:run()

    task.wait(3)

    local studentsToLeave = self:spawnStudentsSeated()
    coroutine.wrap(self.spawnStudentsAtEntrance)(self)
    coroutine.wrap(self.exitStudents)(self, studentsToLeave)
end

return module