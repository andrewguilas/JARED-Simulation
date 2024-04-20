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
local PARAMETERS = require(script.Parent.Parameters)

setmetatable(module, NPC)

local function getRandomPosition(part, buffer)
	local offsetX = math.random(-(part.Size.X / 2 - buffer), (part.Size.X / 2 - buffer))
	local offsetZ = math.random(-(part.Size.Z / 2 - buffer), (part.Size.Z / 2 - buffer))
	local spawnPosition = part.Position + Vector3.new(offsetX, buffer, offsetZ)
    
    return spawnPosition
end

local function getClosestDisposalArea(primaryPart, disposalAreas)
	local closestDisposalArea = nil
    local closestDisposalAreaDistance = math.huge

    for _, disposalArea in ipairs(disposalAreas) do
        local distance = (primaryPart.Position - disposalArea.Start.Position).Magnitude
        if distance < closestDisposalAreaDistance then
            closestDisposalArea = disposalArea
            closestDisposalAreaDistance = distance
        end
    end

    return closestDisposalArea
end

local function getQuickestDisposalArea(disposalAreas)
    table.sort(disposalAreas, function(a, b) return a.UserCount < b.UserCount end)

    local disposalAreasSorted = {}

    for i, disposalArea in ipairs(disposalAreas) do
        disposalAreasSorted[i - 1] = disposalArea  -- Using i - 1 for zero-based indexing
    end

    return disposalAreasSorted
end

local function chooseDisposalArea(primaryPart, disposalAreas)
    local closestDisposalArea = getClosestDisposalArea(primaryPart, disposalAreas)
    local disposalAreasSorted = getQuickestDisposalArea(disposalAreas)

    if closestDisposalArea == disposalAreasSorted[0] then
        return closestDisposalArea
    end

    local PATHS_DISTANCE = 40
    local switchPathsDuration = PATHS_DISTANCE / PARAMETERS.STUDENT.MAX_WALK_SPEED
    
    -- if it is quicker to switch paths than waiting at the closest disposal, select that disposal
    if switchPathsDuration < PARAMETERS.STUDENT.DISPOSING_DURATION * disposalAreasSorted[1].UserCount then
        return disposalAreasSorted[0]
    else
        return closestDisposalArea
    end
end

local function cloneTable(original)
    local seen = {}  -- Table to keep track of already cloned tables
    local function clone(obj)
        if type(obj) ~= 'table' then return obj end
        if seen[obj] then return seen[obj] end
        local new_table = {}
        seen[obj] = new_table
        for key, value in pairs(obj) do
            new_table[clone(key)] = clone(value)
        end
        return setmetatable(new_table, getmetatable(obj))
    end
    return clone(original)
end

function module.new(id, cafeteriaModel)
    local newNPC = NPC.new(id)
	local self = setmetatable(newNPC, module)
    self.Seat = nil
    self.CafeteriaModel = cafeteriaModel

    return self
end

function module:spawnSeated(npcTemplate, randomSeat)
	local agentParameters = cloneTable(PARAMETERS.STUDENT.AGENT_PARAMETERS)
	if string.find(self.CafeteriaModel.Name, "ONE_WAY") then
        -- make sure students don't go through the doors to get to the closest disposal
		agentParameters["Costs"]["RightDoor"] = math.huge
	end

    self:spawn(npcTemplate, randomSeat.Seat.Position, agentParameters)
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

	local agentParameters = cloneTable(PARAMETERS.STUDENT.AGENT_PARAMETERS)
	if string.find(self.CafeteriaModel.Name, "ONE_WAY") then
        -- make students entering only go through right door
		agentParameters["Costs"]["LeftDoor"] = math.huge
	end

    self:spawn(npcTemplate, spawnPosition, agentParameters)
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

    -- choose a disposal area depending on proximity & business
    local chosenDisposalArea = chooseDisposalArea(self.PrimaryPart, disposalAreas)
    chosenDisposalArea.UserCount += 1
    self:walkTo(chosenDisposalArea.Start)
	self:walkTo(chosenDisposalArea.End)

	task.wait(DISPOSING_DURATION)
	self.Character.Food:Destroy()
    chosenDisposalArea.UserCount -= 1
end

function module:exitRoom(spawnArea)
    self.Character:SetAttribute("ActionCode", 3)
    self:walkTo(spawnArea)
end

return module