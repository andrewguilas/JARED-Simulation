-- Contains student-specific NPC methods

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local CONFIGURATION = require(ServerScriptService.Server.Configuration).UI

function module.new(UI, npcStorage)	
	local self = setmetatable({
        UI = UI,
        Data = UI.Data,
        Frame = UI.Frame,
        StudentTemplates = UI.StudentTemplates,
        NPCStorage = npcStorage,
        Frames = {}
    }, module)

    if CONFIGURATION.ENABLED then
        npcStorage.ChildAdded:Connect(function(newStudent)
            self:createStudent(newStudent)
        end)

        npcStorage.ChildRemoved:Connect(function(newStudent)
            self:destroyStudent(newStudent)
        end)

        coroutine.wrap(function()
            while true do
                self:update()
                task.wait(CONFIGURATION.UpdateDelay)
            end
        end)()
    end

	return self
end

function module:createStudent(newStudent)
    local randomTemplate = self.StudentTemplates:GetChildren()[math.random(1, #self.StudentTemplates:GetChildren())]
    local newTemplate = randomTemplate:Clone()
    newTemplate.Parent = self.Frame
    self.Frames[newStudent] = newTemplate
end

function module:destroyStudent(newStudent)
    self[newStudent] = nil
    self.Frames[newStudent]:Destroy()
end

function module:update()
    for student, template  in pairs(self.Frames) do
        if student == nil or student.PrimaryPart == nil then
            continue
        end

        local xPosition = student.PrimaryPart.Position.X / 2 * 10
        local zPosition = student.PrimaryPart.Position.Z / 2 * 10
        
        if student.Humanoid.WalkSpeed == 0 then
            template.ImageColor3 = CONFIGURATION.STOP_COLOR
        elseif student.Humanoid.WalkSpeed < 8 then
            template.ImageColor3 = CONFIGURATION.SLOW_COLOR
        else
            template.ImageColor3 = CONFIGURATION.WALK_COLOR
        end

        template.Position = UDim2.new(0, xPosition, 0, zPosition)
        template.Visible = true
    end

    local studentsValue = #self.NPCStorage:GetChildren()
    local durationValue = math.round(Workspace.DistributedGameTime, 2)
    local heartbeatValue = math.round(1 / RunService.Heartbeat:Wait(), 2)

    self.Data.Students.Text = "Students: " .. tostring(studentsValue)
    self.Data.Duration.Text = "Duration: " .. tostring(durationValue)
    self.Data.Heartbeat.Text = "Heartbeat: " .. tostring(heartbeatValue)
end

return module