local module = {}
module.__index = module

local NPC = require(script.Parent.NPC)

setmetatable(module, NPC)

local function getClosestDisposalArea(primaryPart, disposalAreas)
    local distances = {}
    for _, disposalArea in ipairs(disposalAreas) do
        local distance = (primaryPart.Position - disposalArea.Start.Position).Magnitude
        distances[disposalArea] = distance
    end

	local closestDisposalArea = nil
    local closestDisposalAreaDistance = math.huge
    for disposalArea, distance in pairs(distances) do
        if distance < closestDisposalAreaDistance then
            closestDisposalArea = disposalArea
            closestDisposalAreaDistance = distance
        end
    end

    return closestDisposalArea
end

function module.new(id, PARAMETERS)
    local newNPC = NPC.new(id, PARAMETERS)
	local self = setmetatable(newNPC, module)
    self.Seat = nil

    --[[

    Action Codes
    - Getting food: 0
    - Disposing trash: 1
    - Exiting cafeteria: 2

    ]]

    return self
end

function module:spawnSeated(npcTemplate, randomSeat)
    self:spawn(npcTemplate, randomSeat.Seat.Position)
    
    self.Seat = randomSeat
    self.Seat.Owner = self.ID
	self.Seat.Seat:Sit(self.Humanoid)
end

function module:giveFood(foodTemplate)
    self:giveTool(foodTemplate)
end

function module:spawnEntrance(npcTemplate, spawnArea)
	local offsetX = math.random(-(spawnArea.Size.X / 2 - 5), (spawnArea.Size.X / 2 - 5))
	local offsetZ = math.random(-(spawnArea.Size.Z / 2 - 5), (spawnArea.Size.Z / 2 - 5))
	local spawnPosition = spawnArea.Position + Vector3.new(offsetX, 5, offsetZ)
    
    self:spawn(npcTemplate, spawnPosition)
end

function module:getFood(despawnArea)
	self.Character:SetAttribute("ActionCode", 0)
	self:walkTo(despawnArea)
end

function module:exitSeat()
    self.Seat.Owner = nil
	if self.Humanoid.Sit then
		self.Humanoid.Jump = true
		
		local seatWeld = self.Seat.Seat:FindFirstChildWhichIsA("Weld")
		if seatWeld then
			seatWeld:Destroy()
		end
	end
end

function module:disposeTrash(disposalAreas, DISPOSING_DURATION)
    self.Character:SetAttribute("ActionCode", 1)

    local closestDisposalArea = getClosestDisposalArea(self.PrimaryPart, disposalAreas)
    self:walkTo(closestDisposalArea.Start)
	self:walkTo(closestDisposalArea.End)

	task.wait(DISPOSING_DURATION)
	self.Character.Food:Destroy()
end

function module:exitRoom(spawnArea)
    self.Character:SetAttribute("ActionCode", 2)
    self:walkTo(spawnArea)
end

return module