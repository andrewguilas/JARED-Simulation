local module = {}
module.__index = module

local Student = require(script.Parent.Student)

local function getRandomSeat(seats)
    local remainingSeats = {}
	for _, seat in ipairs(seats) do
		if seat.Owner == nil then
			table.insert(remainingSeats, seat)
		end
	end

	if #remainingSeats == 0 then
		warn("No more available seats")
		return
	end

	local randomNumber = math.random(1, #remainingSeats)
	-- print("Random seat is seat " .. tostring(randomNumber))
	local randomSeat = remainingSeats[randomNumber]

    return randomSeat
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
    local studentsSeatedCount = self.PARAMETERS.SIMULATION.EXIT_RATE * self.PARAMETERS.SIMULATION.DURATION

    print(string.format("Spawning %s students in seats...", studentsSeatedCount))

    for _ = 1, studentsSeatedCount do
        local newStudent = Student.new(self.TotalStudentCount, self.PARAMETERS)
        
        local randomSeat = getRandomSeat(self.Seats)
        newStudent:spawnSeated(self.Templates.Student, randomSeat)
        newStudent:giveFood(self.Templates.Food)

        table.insert(studentsSeated, newStudent)

        self.TotalStudentCount += 1
        task.wait(0.02)
    end

    return studentsSeated
end

function module:spawnStudentsEntrance()
    print(string.format("Spawning students at %s students/second...", self.PARAMETERS.SIMULATION.ENTRANCE_RATE))

    while true do
        if self.TotalStudentCount >= self.PARAMETERS.SIMULATION.MAX_CAPACITY then
            break
        end

        local newStudent = Student.new(self.TotalStudentCount, self.PARAMETERS)
        newStudent:spawnEntrance(self.Templates.Student, self.SpawnArea)
        
        coroutine.wrap(function()
            newStudent:getFood(self.DespawnArea)
            newStudent:despawn()
        end)()

        self.TotalStudentCount += 1
        task.wait(1 / self.PARAMETERS.SIMULATION.ENTRANCE_RATE)
    end
end

function module:despawnStudents(students)
    print(string.format("Despawning %s students at %s students/sec...", #students, self.PARAMETERS.SIMULATION.EXIT_RATE))

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