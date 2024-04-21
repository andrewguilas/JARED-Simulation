--[[

    Handler for cafeteria and management of all students

]]

local module = {}
module.__index = module

local Student = require(script.Parent.Student)
local PARAMETERS = require(script.Parent.Parameters)
local DataCollection = require(script.Parent.DataCollection)

local function getRandomSeat(seats)
    local emptySeats = {}
    for _, seat in ipairs(seats) do
        if seat.Owner == nil then
            table.insert(emptySeats, seat)  
        end
    end
    return emptySeats[math.random(1, #emptySeats)]
end

function module.new(cafeteriaModel, templates)
    local self = setmetatable({
        CafeteriaModel = cafeteriaModel,
        SpawnArea = cafeteriaModel.Floor.SpawnArea,
        DespawnArea1 = cafeteriaModel.Floor.DespawnArea1,
        DespawnArea2 = cafeteriaModel.Floor.DespawnArea2,
        DisposalAreas = {},
        Seats = {},
        Templates = {
            Student = templates.Student,
            Food = templates.Food,
        },
        TotalStudentCount = 0,
    }, module)

    for _, disposalArea in ipairs(self.CafeteriaModel.DisposalAreas:GetChildren()) do
        table.insert(self.DisposalAreas, {
            Start = disposalArea.Path.DisposalAreaStart,
            End = disposalArea.Path.DisposalAreaEnd,
            UserCount = 0,
            Name = disposalArea.Name
        })
    end

	for _, _table in ipairs(self.CafeteriaModel.Tables:GetChildren()) do
        for __, chair in ipairs(_table:GetChildren()) do
            local seat = chair:FindFirstChildWhichIsA("Seat")
            if seat then
                seat.Disabled = true
                table.insert(self.Seats, {
                    Seat = seat,
                    Owner = nil,
                })
            end
        end
	end

    return self
end

function module:spawnStudentsSeated()
    local studentsSeated = {}

    -- print(string.format("Spawning %s students in seats...", PARAMETERS.SIMULATION.EXIT_AMOUNT))

    for _ = 1, PARAMETERS.SIMULATION.EXIT_AMOUNT do
        coroutine.wrap(function()            
            local newStudent = Student.new(self.TotalStudentCount, self.CafeteriaModel)
        
            local randomSeat = getRandomSeat(self.Seats)
            if not randomSeat then
                error("No more seats available")
            end
            
            newStudent:spawnSeated(self.Templates.Student, randomSeat)
            newStudent:giveFood(self.Templates.Food)
    
            table.insert(studentsSeated, newStudent)
            self.TotalStudentCount += 1
        end)()

        task.wait(0.05)
    end

    return studentsSeated
end

function module:spawnStudentsEntrance()
    -- print(string.format("Spawning %s students at %s students/second...", PARAMETERS.SIMULATION.ENTER_AMOUNT, PARAMETERS.SIMULATION.ENTER_RATE))

    for _ = 1, PARAMETERS.SIMULATION.ENTER_AMOUNT do
        coroutine.wrap(function()
            local startTime = os.time()

            local newStudent = Student.new(self.TotalStudentCount, self.CafeteriaModel)
            newStudent:spawnEntrance(self.Templates.Student, self.SpawnArea)
            newStudent:getFood(self.DespawnArea2)
            newStudent:despawn()

            DataCollection.addEnterDuration(self.CafeteriaModel.Name, os.time() - startTime)
        end)()

        self.TotalStudentCount += 1
        task.wait(1 / PARAMETERS.SIMULATION.ENTER_RATE)
    end
end

function module:despawnStudents(students)
    -- print(string.format("Despawning %s students at %s students/sec...", #students, PARAMETERS.SIMULATION.EXIT_AMOUNT))

    for _, student in ipairs(students) do
        coroutine.wrap(function()
            local startTime = os.time()

            student:exitSeat()
            student:disposeTrash(self.DisposalAreas, PARAMETERS.STUDENT.DISPOSING_DURATION)
            student:exitRoom(self.DespawnArea1)
            student:despawn()

            DataCollection.addExitDuration(self.CafeteriaModel.Name, os.time() - startTime)
        end)()

        task.wait(1 / PARAMETERS.SIMULATION.EXIT_RATE)
    end
end

function module:run()
    local studentsSeated = self:spawnStudentsSeated()
    coroutine.wrap(self.spawnStudentsEntrance)(self)
    coroutine.wrap(self.despawnStudents)(self, studentsSeated)
end

return module