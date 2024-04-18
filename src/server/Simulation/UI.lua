--[[

    Handler for 2D UI minimap

]]

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PARAMETERS = require(script.Parent.Parameters)

local npcStorage = Workspace.Cafeteria.NPCs

local function formatStopwatch(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function module.new(ui)
    return setmetatable({
        UI = ui,
        NPCStorage = npcStorage,
        Frames = {},
    }, module)
end

function module:run()
    npcStorage.ChildAdded:Connect(function(newStudent)
        self:createStudent(newStudent)
    end)

    npcStorage.ChildRemoved:Connect(function(newStudent)
        self:destroyStudent(newStudent)
    end)

    coroutine.wrap(function()
        while true do
            self:update()
            task.wait(PARAMETERS.UI.UPDATE_DELAY)
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
    for student, template in pairs(self.Frames) do
        if student == nil or student.PrimaryPart == nil then
            continue
        end

        local xPosition = student.PrimaryPart.Position.X / 2 * 10 * -1
        local zPosition = student.PrimaryPart.Position.Z / 2 * 10 * -1
        
        if student.Humanoid.WalkSpeed == 0 then
            template.ImageColor3 = PARAMETERS.UI.STOP_COLOR
        elseif student.Humanoid.WalkSpeed < 8 then
            template.ImageColor3 = PARAMETERS.UI.SLOW_COLOR
        else
            template.ImageColor3 = PARAMETERS.UI.WALK_COLOR
        end

        template.Position = UDim2.new(0, xPosition, 0, zPosition)
        template.Visible = true
    end

    local studentCount = #npcStorage:GetChildren()
    local maxCapacity = PARAMETERS.SIMULATION.MAX_CAPACITY
    local duration = formatStopwatch(Workspace.DistributedGameTime)
    local heartbeat = math.round(1 / RunService.Heartbeat:Wait())

    self.UI.Data.Students.Text = string.format("Students: %s/%s", studentCount, maxCapacity)
    self.UI.Data.Duration.Text = string.format("Duration: %s", duration)
    self.UI.Data.Heartbeat.Text = string.format("Heartbeat: %s", tostring(heartbeat))
end

return module