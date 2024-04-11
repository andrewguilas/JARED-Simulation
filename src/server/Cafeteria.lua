-- Contains methods to run simulations in the cafeteria

local ServerScriptService = game:GetService("ServerScriptService")

local Group = require(ServerScriptService.Server.Group)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).CAFETERIA
local getRandomRow = require(ServerScriptService.Server.Methods.GetRandomRow)

local module = {}
module.__index = module

local function calculateEntryRate(currentMinute)
	for _, row in ipairs(CONFIGURATION.ENTRY_RATE) do
		-- find the minute interval the minute is in
		if currentMinute < row["MINUTE"] then
			return math.round(row["STUDENTS"] / 15) -- number of students every 15 minutes / 15 minutes = number of students every minute
		end
	end
end

local function calculateGroupCounts(entryRate)
	local groupCounts = {}
	while entryRate > 0 do
		local randomRow = getRandomRow(CONFIGURATION.GROUP_SIZE)
		local students = randomRow["STUDENTS"]
		
		-- don't exceed entry rate
		if students > entryRate then
			students = entryRate
		end

		table.insert(groupCounts, students)
		entryRate -= students
	end

	return groupCounts
end

function module.new()
	local self = setmetatable({
		Room = nil,
		SpawnArea = nil,
		ServingArea = {
			Start = nil,
			End = nil,
		},
		Tables = {},
		DisposalArea = {
			Start = nil,
			End = nil,
		},
		StudentCount = 0,
	}, module)
	
	return self
end

function module:setRoom(room, spawnArea, servingArea, disposalAreas)
	self.Room = room
	self.SpawnArea = spawnArea
	self.ServingArea = servingArea
	self.DisposalAreas = disposalAreas
end

function module:addTable(tableTables)
	local seats = {}

	for _, chair in ipairs(tableTables:GetChildren()) do
		local seat = chair:FindFirstChildWhichIsA("Seat")
		if seat then
			local seatData = self:addSeat(seat)
			table.insert(seats, seatData)
		end
	end

	table.insert(self.Tables, seats)
end

function module:addSeat(seat)
	local seatData = {
		Seat = seat,
		Owner = nil,
	}

	seat.Disabled = true

	return seatData
end

function module:start()	
	task.wait(CONFIGURATION.SIMULATION_DELAY)
	math.randomseed(os.time())

	for minute = 1, 60 do
		print(string.format("Minute %s", minute))

		local entryRate = calculateEntryRate(minute)
		local groupCounts = calculateGroupCounts(entryRate)

		for _, groupCount in ipairs(groupCounts) do
			local group = Group.new(groupCount, self)
			coroutine.wrap(group.spawnGroup)(group)

			task.wait(60 / groupCount / CONFIGURATION.SIMULATION_SPEED)
		end

	end
end

return module
