local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local npcStorage = Workspace.Cafeteria.NPCs

local function formatStopwatch(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function module.new(ui)
    local self = setmetatable({
        UI = ui,
        NPCStorage = npcStorage,
        Frames = {},
        PARAMETERS = nil,
    }, module)

    return self
end

function module:run(PARAMETERS)
    self.PARAMETERS = PARAMETERS

    npcStorage.ChildAdded:Connect(function(newStudent)
        self:createStudent(newStudent)
    end)

    npcStorage.ChildRemoved:Connect(function(newStudent)
        self:destroyStudent(newStudent)
    end)

    coroutine.wrap(function()
        while true do
            self:update()
            -- task.wait(self.PARAMETERS.UI.UPDATE_DELAY)
        end
    end)()
end

function module:createStudent(newStudent)
    local newTemplate = self.UI.StudentTemplate:Clone()
    newTemplate.Parent = self.UI.Frame

    self.Frames[newStudent] = newTemplate
end

function module:destroyStudent(newStudent)
    if self.Frames[newStudent] then
        self.Frames[newStudent]:Destroy()
        self.Frames[newStudent] = nil
    end
end

function module:update()
    local UI_PARAMETERS = self.PARAMETERS.UI

    for student, template in pairs(self.Frames) do
        if student == nil or student.PrimaryPart == nil then
            continue
        end

        local xPosition = student.PrimaryPart.Position.X / 2 * 10 * -1
        local zPosition = student.PrimaryPart.Position.Z / 2 * 10 * -1
        
        if student.Humanoid.WalkSpeed == 0 then
            template.ImageColor3 = UI_PARAMETERS.STOP_COLOR
        elseif student.Humanoid.WalkSpeed < 8 then
            template.ImageColor3 = UI_PARAMETERS.SLOW_COLOR
        else
            template.ImageColor3 = UI_PARAMETERS.WALK_COLOR
        end

        template.Position = UDim2.new(0, xPosition, 0, zPosition)
        template.Visible = true
    end

    local studentsValue = #npcStorage:GetChildren()
    local durationValue = formatStopwatch(Workspace.DistributedGameTime)
    local heartbeatValue = math.round(1 / RunService.Heartbeat:Wait())

    self.UI.Data.Students.Text = string.format("Students: %s/%s", studentsValue, self.PARAMETERS.SIMULATION.MAX_CAPACITY)
    self.UI.Data.Duration.Text = string.format("Duration: %s", durationValue)
    self.UI.Data.Heartbeat.Text = string.format("Heartbeat: %s", tostring(heartbeatValue))
end

return module