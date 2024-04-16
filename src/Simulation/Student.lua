-- Contains student-specific NPC methods

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local NPC = require(ServerScriptService.Simulation.NPC)
local CONFIGURATION = require(ServerScriptService.Simulation.Configuration).STUDENT

local npcStorage = Workspace.NPCs
local studentTemplate = ServerStorage.Student
local foodTemplate = ServerStorage.Food

local module = {}
module.__index = module
setmetatable(module, NPC)

function module.new()	
	local newNPC = NPC.new()
	local self = setmetatable(newNPC, module)

	local newStudent = studentTemplate:Clone()
	self.Character = newStudent
	self.Humanoid = newStudent.Humanoid
	self.PrimaryPart = newStudent.PrimaryPart
	self.Seat = nil

	self.Character:SetAttribute("LookingAt", nil)
	self.Character:SetAttribute("ActionCode", -1)
	self.Character:SetAttribute("ShowWaypoints", false)

	coroutine.wrap(self.updateWalkSpeed)(self)

	return self
end

function module:spawn(position)
	self.Character.Parent = npcStorage
    self.Character:MoveTo(position)
end

function module:despawn()
	self.Character:Destroy()

	-- Cleanup
	if self.Seat then
		self.Seat.Owner = nil
		-- self.Seat.Seat.Material = Enum.Material.Wood
		-- self.Seat.Seat.BrickColor = BrickColor.new("Fawn brown")
	end
end




function module:spawnInSpawnArea(spawnArea)
	self.Character:SetAttribute("ActionCode", 0)
	self:createPath("PathA")

	local offsetX = math.random(-(spawnArea.Size.X / 2 - 5), (spawnArea.Size.X / 2 - 5))
	local offsetZ = math.random(-(spawnArea.Size.Z / 2 - 5), (spawnArea.Size.Z / 2 - 5))
	local spawnPosition = spawnArea.Position + Vector3.new(offsetX, 5, offsetZ)
	self.Character.Parent = npcStorage
    
    self:spawn(spawnPosition)
end

function module:getFood(despawnArea)
	self.Character:SetAttribute("ActionCode", 1)
	self:createPath("PathB")

	self:walkTo(despawnArea)
	self:despawn()
end

function module:findSeat(seats)
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

function module:giveFood()
    local newFood = foodTemplate:Clone()
	newFood.Parent = self.Character
end

function module:disposeTrash(disposalAreas)
    self.Character:SetAttribute("ActionCode", 3)
	self:createPath("PathD")

    -- get out of seat
	self.Seat.Owner = nil
	if self.Humanoid.Sit then
		self.Humanoid.Jump = true
		
		local seatWeld = self.Seat.Seat:FindFirstChildWhichIsA("Weld")
		if seatWeld then
			seatWeld:Destroy()
		end
	end
	
    -- find closest disposal area
	local distanceToDisposal1 = (self.PrimaryPart.Position - disposalAreas[1].Start.Position).Magnitude
	local distanceToDisposal2 = (self.PrimaryPart.Position - disposalAreas[2].Start.Position).Magnitude
	
	local closestDisposalArea = nil
	if distanceToDisposal1 < distanceToDisposal2 then
		closestDisposalArea = disposalAreas[1]
	else
		closestDisposalArea = disposalAreas[2]
	end

    self:walkTo(closestDisposalArea.Start)
	self:walkTo(closestDisposalArea.End)
	task.wait(CONFIGURATION.DISPOSING_DURATION)
	self.Character.Food:Destroy()
end

function module:walkToExit(spawnArea)
	self.Character:SetAttribute("ActionCode", 4)

	self:walkTo(spawnArea)
	self:despawn()
end




function module:enterRoom(spawnArea, despawnArea)	
	self:spawnInSpawnArea(spawnArea)
	self:getFood(despawnArea)
end

function module:enterRoomSeated(seats)	
	self.Character:SetAttribute("ActionCode", 2)
	self:createPath("PathC")

    local randomSeat = self:findSeat(seats)
	randomSeat.Owner = self.Character
    
    self.Seat = randomSeat
    self:spawn(self.Seat.Seat.Position)
	self.Seat.Seat:Sit(self.Humanoid)

    self:giveFood()
end

function module:exitRoom(disposalAreas, spawnArea)
    self:disposeTrash(disposalAreas)
    self:walkToExit(spawnArea)
end

return module