-- Contains student-specific NPC methods

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPC = require(ServerScriptService.Server.NPC)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).STUDENT

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

function module:enterRoom(spawnArea)	
	self.Character:SetAttribute("ActionCode", 0)
	self:createPath("PathA")

	local offsetX = math.random(-(spawnArea.Size.X / 2 - 5), (spawnArea.Size.X / 2 - 5))
	local offsetZ = math.random(-(spawnArea.Size.Z / 2 - 5), (spawnArea.Size.Z / 2 - 5))
	local spawnPosition = spawnArea.Position + Vector3.new(offsetX, 5, offsetZ)
	self.Character.Parent = npcStorage
	self.Character:MoveTo(spawnPosition)
end

function module:getFood(servingAreas)
	self.Character:SetAttribute("ActionCode", 1)
	self:createPath("PathB")

	for _, servingAreaPoint in ipairs(servingAreas) do
		-- print("Walking to " .. servingAreaPoint.Name)

		self:walkTo(servingAreaPoint)
		task.wait(CONFIGURATION.SERVING_DURATION)
	end

	local newFood = foodTemplate:Clone()
	newFood.Parent = self.Character
end

function module:findSeat()
	self.Character:SetAttribute("ActionCode", 2)
	self:createPath("PathC")

	self:walkTo(self.Seat.Seat)
	print(self.Seat.Owner, self.Character.Name, self.Seat.Seat.Occupant and self.Seat.Seat.Occupant.Parent.Name)
	self.Seat.Seat:Sit(self.Humanoid)

	task.wait(CONFIGURATION.EATING_DURATION)
end

function module:disposeTrash(disposalAreas)
	self.Character:SetAttribute("ActionCode", 3)
	self:createPath("PathD")

	self.Seat.Owner = nil
	if self.Humanoid.Sit then
		self.Humanoid.Jump = true
	end
	
	local distanceToDisposal1 = (self.PrimaryPart.Position - disposalAreas[1].Start.Position).Magnitude
	local distanceToDisposal2 = (self.PrimaryPart.Position - disposalAreas[2].Start.Position).Magnitude
	
	local closestDisposalArea = nil
	if distanceToDisposal1 < distanceToDisposal2 then
		closestDisposalArea = disposalAreas[1]
	else
		closestDisposalArea = disposalAreas[2]
	end

	-- print("Closest disposal area is " .. closestDisposalArea.Start.Parent.Parent.Name)

	self:walkTo(closestDisposalArea.Start)
	self:walkTo(closestDisposalArea.End)
	task.wait(CONFIGURATION.DISPOSING_DURATION)
	self.Character.Food:Destroy()
end

function module:exitRoom(spawnArea)
	self.Character:SetAttribute("ActionCode", 4)

	self:walkTo(spawnArea)
	self.Character:Destroy()

	-- Cleanup
	if self.Seat then
		self.Seat.Owner = nil
		-- self.Seat.Seat.Material = Enum.Material.Wood
		-- self.Seat.Seat.BrickColor = BrickColor.new("Fawn brown")
	end
end

return module