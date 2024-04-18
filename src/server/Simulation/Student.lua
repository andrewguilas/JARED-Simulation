--[[

    Handler for student related methods
    Implements NPC class

    Action Codes
    - Spawning: 0
    - Getting food: 1
    - Disposing trash: 2
    - Exiting cafeteria: 3

]]

local module = {}
module.__index = module

local NPC = require(script.Parent.NPC)

setmetatable(module, NPC)

local function getRandomPosition(part, buffer)
	local offsetX = math.random(-(part.Size.X / 2 - buffer), (part.Size.X / 2 - buffer))
	local offsetZ = math.random(-(part.Size.Z / 2 - buffer), (part.Size.Z / 2 - buffer))
	local spawnPosition = part.Position + Vector3.new(offsetX, buffer, offsetZ)
    
    return spawnPosition
end

local function getClosestDisposalArea(primaryPart, disposalAreas)
    local distances = {}
	local closestPart = nil
    local closestPartDistance = math.huge

    for _, part in ipairs(disposalAreas) do
        local distance = (primaryPart.Position - part.Start.Position).Magnitude
        distances[part] = distance
    end

    for part, distance in pairs(distances) do
        if distance < closestPartDistance then
            closestPart = part
            closestPartDistance = distance
        end
    end

    return closestPart
end

function module.new(id, PARAMETERS)
    local newNPC = NPC.new(id, PARAMETERS)
	local self = setmetatable(newNPC, module)
    self.Seat = nil

    return self
end

function module:spawnSeated(npcTemplate, randomSeat)
    self:spawn(npcTemplate, randomSeat.Seat.Position)
    self.Character:SetAttribute("ActionCode", 0)

    self.Seat = randomSeat
    self.Seat.Owner = self.ID
	self.Seat.Seat:Sit(self.Humanoid)
end

function module:giveFood(foodTemplate)
    self:giveTool(foodTemplate)
end

function module:spawnEntrance(npcTemplate, spawnArea)
	local spawnPosition = getRandomPosition(spawnArea, 5)

    self:spawn(npcTemplate, spawnPosition)
    self.Character:SetAttribute("ActionCode", 0)
end

function module:getFood(despawnArea)
	self.Character:SetAttribute("ActionCode", 1)
	self:walkTo(despawnArea)
end

function module:exitSeat()
    self.Seat.Owner = nil
	if self.Humanoid.Sit then
		self.Humanoid.Jump = true
		
        -- destroy weld connecting npc & seat if jumping doesn't work
		local seatWeld = self.Seat.Seat:FindFirstChildWhichIsA("Weld")
		if seatWeld then
			seatWeld:Destroy()
		end
	end
end

function module:disposeTrash(disposalAreas, DISPOSING_DURATION)
    self.Character:SetAttribute("ActionCode", 2)

    local closestDisposalArea = getClosestDisposalArea(self.PrimaryPart, disposalAreas)
    self:walkTo(closestDisposalArea.Start)
	self:walkTo(closestDisposalArea.End)

	task.wait(DISPOSING_DURATION)
	self.Character.Food:Destroy()
end

function module:exitRoom(spawnArea)
    self.Character:SetAttribute("ActionCode", 3)
    self:walkTo(spawnArea)
end

return module