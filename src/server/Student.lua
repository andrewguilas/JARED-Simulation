-- Contains student-specific NPC methods

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPC = require(ServerScriptService.Server.NPC)
local CONFIGURATION = require(ServerScriptService.Server.Configuration).Student

local npcStorage = Workspace.NPCs
local studentTemplate = ServerStorage.Student

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
		
	return self
end

function module:enterRoom(spawnArea)	
	local offsetX = math.random(-(spawnArea.Size.X / 2 - 5), (spawnArea.Size.X / 2 - 5))
	local offsetZ = math.random(-(spawnArea.Size.Z / 2 - 5), (spawnArea.Size.Z / 2 - 5))
	local spawnPosition = spawnArea.Position + Vector3.new(offsetX, 5, offsetZ)
	self.Character.Parent = npcStorage
	self.Character:MoveTo(spawnPosition)
end

function module:getFood(servingArea)
	self:walkTo(servingArea.Start)
	
	self:setWalkSpeed(CONFIGURATION.ServingAreaWalkSpeed)
	self:walkTo(servingArea.End)
	
	self:setWalkSpeed(CONFIGURATION.DefaultWalkSpeed)
end

function module:findSeat(seats)
	if self.Seat == nil then
		for _, seat in ipairs(seats) do
			if seat.Owner == nil then
				seat.Owner = self.Character
				self.Seat = seat
				self.Seat.Seat.Material = Enum.Material.Neon
				self.Seat.Seat.BrickColor = BrickColor.new("White")
				break
			end
		end
	end

	if self.Seat == nil then
		warn("No more available seats")
		return
	end

	self:walkTo(self.Seat.Seat)
	self.Seat.Seat:Sit(self.Humanoid)
end

function module:disposeTrash(disposalArea)
	if self.Humanoid.Sit then
		self.Humanoid.Jump = true
	end
	
	self:walkTo(disposalArea.Start)

	self:setWalkSpeed(CONFIGURATION.DisposalAreaWalkSpeed)
	self:walkTo(disposalArea.End)

	self:setWalkSpeed(CONFIGURATION.DefaultWalkSpeed)
end

function module:exitRoom(spawnArea)
	self:walkTo(spawnArea)
	self.Character:Destroy()

	-- Cleanup
	if self.Seat then
		self.Seat.Owner = nil
		self.Seat.Seat.Material = Enum.Material.Wood
		self.Seat.Seat.BrickColor = BrickColor.new("Fawn brown")
	end
end

return module