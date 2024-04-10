local ServerScriptService = game:GetService("ServerScriptService")

local student = require(ServerScriptService.Server.Student)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).CAFETERIA
local getRandomRow = require(ServerScriptService.Server.Methods.GetRandomRow)

local module = {}
module.__index = module

local function calculateEatingDuration()
    local randomRow = getRandomRow(CONFIGURATION.EATING_DURATION)
    return randomRow["MINUTE"] * 60
end

function module.new(groupCount, cafeteria)
	local self = setmetatable({
        Count = groupCount,
        Students = {},
        Table = nil,
        Cafeteria = cafeteria,
        IsEatingDone = true,
    }, module)
	
	return self
end

function module:spawnGroup()
    self.Table = self:findTable()
    local eatingDuration = calculateEatingDuration()

    print(string.format("Spawning group of size %s, chose table %s, eating for %s sec", self.Count, tostring(self.Table), eatingDuration))

	for count = 1, self.Count do
		coroutine.wrap(self.spawnStudent)(self)
		task.wait(CONFIGURATION.SPAWN_DELAY)
	end

    task.wait(eatingDuration)
    self.IsEatingDone = true
end

function module:spawnStudent()
	local id = self.Cafeteria.StudentCount
	local newStudent = student.new()    
	newStudent.Character.Name = "Student" .. tostring(id)
	newStudent.States.ID = id
	newStudent.Character:SetAttribute("ID", id)

    table.insert(self.Students, newStudent)
    self.Cafeteria.StudentCount += 1

    newStudent:enterRoom(self.Cafeteria.SpawnArea)
	newStudent:getFood(self.Cafeteria.ServingArea)
	newStudent:findSeat(self.Table)
    
    while (self.IsEatingDone == false) do
        task.wait(1)
    end

	newStudent:disposeTrash(self.Cafeteria.DisposalAreas)
	newStudent:exitRoom(self.Cafeteria.SpawnArea)
end

function module:findTable()
    local availableTables = {}
    local availableSeats = {}
    for _, aTable in ipairs(self.Cafeteria.Tables) do
        local availableSeatCount = 0
        for __, seat in ipairs(aTable) do
            if seat.Owner == nil then
                table.insert(availableSeats, seat)
                availableSeatCount += 1
            end
        end

        if availableSeatCount >= self.Count then
            table.insert(availableTables, aTable)
        end
    end

    if #availableTables ~= 0 then
        -- warn("No more available tables for an entire group")
        availableSeats[1].Owner = true
        return availableSeats
    end

	local randomNumber = math.random(1, #availableTables)
	local randomTable = availableTables[randomNumber]
    local ownedSeats = 0
    for __, seat in ipairs(randomTable) do
        -- make the seat "owned", but not occupied
        -- ignore seats already taken
        if seat.Owner == nil then
            seat.Owner = true
            ownedSeats += 1
        end
    end

    return randomTable
end

return module