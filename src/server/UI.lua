-- Contains student-specific NPC methods

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local CONFIGURATION = require(ServerScriptService.Server.Configuration)

local function formatStopwatch(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function module.new(UI, npcStorage)	
	local self = setmetatable({
        UI = UI,
        Data = UI.Data,
        Frame = UI.Frame,
        StudentTemplates = UI.StudentTemplates,
        NPCStorage = npcStorage,
        Frames = {}
    }, module)

    if CONFIGURATION.UI.ENABLED then
        npcStorage.ChildAdded:Connect(function(newStudent)
            self:createStudent(newStudent)
        end)

        npcStorage.ChildRemoved:Connect(function(newStudent)
            self:destroyStudent(newStudent)
        end)

        coroutine.wrap(function()
            while true do
                self:update()
                task.wait(CONFIGURATION.UI.UpdateDelay)
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

        local xPosition = student.PrimaryPart.Position.X / 2 * 10 * -1
        local zPosition = student.PrimaryPart.Position.Z / 2 * 10 * -1
        
        if student.Humanoid.WalkSpeed == 0 then
            template.ImageColor3 = CONFIGURATION.UI.STOP_COLOR
        elseif student.Humanoid.WalkSpeed < 8 then
            template.ImageColor3 = CONFIGURATION.UI.SLOW_COLOR
        else
            template.ImageColor3 = CONFIGURATION.UI.WALK_COLOR
        end

        template.Position = UDim2.new(0, xPosition, 0, zPosition)
        template.Visible = true
    end

    local studentsValue = #self.NPCStorage:GetChildren()
    local durationValue = formatStopwatch(Workspace.DistributedGameTime * CONFIGURATION.CAFETERIA.SIMULATION_SPEED)
    local heartbeatValue = math.round(1 / RunService.Heartbeat:Wait(), 2)

    self.Data.Students.Text = string.format("Students: %s/%s", studentsValue, CONFIGURATION.CAFETERIA.MAX_CAPACITY)
    self.Data.Duration.Text = string.format("Duration: %s", durationValue)
    self.Data.Heartbeat.Text = string.format("Heartbeat: %s", tostring(heartbeatValue))
end

return module