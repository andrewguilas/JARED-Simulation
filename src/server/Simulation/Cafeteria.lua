--[[

    Handler for cafeteria and management of all students

]]

local module = {}
module.__index = module

local Student = require(script.Parent.Student)

local function getRandomSeat(seats)
    local emptySeats = {}
    for _, seat in ipairs(seats) do
        if seat.Owner == nil then
            table.insert(emptySeats, seat)  
        end
    end
    return emptySeats[math.random(1, #emptySeats)]
end

function module.new(cafeteria, templates)
    local self = setmetatable({
        SpawnArea = cafeteria.Floor.SpawnArea,
        DespawnArea = cafeteria.Floor.DespawnArea,
        DisposalAreas = {},
        Seats = {},
        Templates = {
            Student = templates.Student,
            Food = templates.Food,
        },
        TotalStudentCount = 0,
        PARAMETERS = nil,
    }, module)

    for _, disposalArea in ipairs(cafeteria.DisposalAreas:GetChildren()) do
        table.insert(self.DisposalAreas, {
            Start = disposalArea.Path.DisposalAreaStart,
            End = disposalArea.Path.DisposalAreaEnd,
        })
    end

	for _, _table in ipairs(cafeteria.Tables:GetChildren()) do
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

    print(string.format("Spawning %s students in seats...", self.PARAMETERS.SIMULATION.EXIT_AMOUNT))

    for _ = 1, self.PARAMETERS.SIMULATION.EXIT_AMOUNT do
        coroutine.wrap(function()
            local newStudent = Student.new(self.TotalStudentCount, self.PARAMETERS)
        
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
    print(string.format("Spawning %s students at %s students/second...", self.PARAMETERS.SIMULATION.ENTER_AMOUNT, self.PARAMETERS.SIMULATION.ENTER_RATE))

    for _ = 1, self.PARAMETERS.SIMULATION.ENTER_AMOUNT do
        coroutine.wrap(function()
            local newStudent = Student.new(self.TotalStudentCount, self.PARAMETERS)
            newStudent:spawnEntrance(self.Templates.Student, self.SpawnArea)
            newStudent:getFood(self.DespawnArea)
            newStudent:despawn()
        end)()

        self.TotalStudentCount += 1
        task.wait(1 / self.PARAMETERS.SIMULATION.ENTER_RATE)
    end
end

function module:despawnStudents(students)
    print(string.format("Despawning %s students at %s students/sec...", #students, self.PARAMETERS.SIMULATION.EXIT_AMOUNT))

    for _, student in ipairs(students) do
        coroutine.wrap(function()
            student:exitSeat()
            student:disposeTrash(self.DisposalAreas, self.PARAMETERS.STUDENT.DISPOSING_DURATION)
            student:exitRoom(self.SpawnArea)
            student:despawn()
        end)()

        task.wait(1 / self.PARAMETERS.SIMULATION.EXIT_RATE)
    end
end

function module:run(PARAMETERS)
    self.PARAMETERS = PARAMETERS

    local studentsSeated = self:spawnStudentsSeated()
    coroutine.wrap(self.spawnStudentsEntrance)(self)
    coroutine.wrap(self.despawnStudents)(self, studentsSeated)
end

return module