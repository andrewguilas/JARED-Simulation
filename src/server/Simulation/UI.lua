--[[

    Handler for 2D UI minimap

]]

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PARAMETERS = require(script.Parent.Parameters)

local function formatStopwatch(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

function module.new(ui, cafeteriaModel)
    local self = setmetatable({
        UI = ui,
        Layout = nil,
        NPCStorage = cafeteriaModel.NPCs,
        Frames = {},
    }, module)

    self.Layout = self.UI.Background.UIGridLayout.LayoutTemplate:Clone()
    self.Layout.Parent = self.UI.Background
    self.Layout.Map.Image = PARAMETERS.SIMULATION.LAYOUTS[cafeteriaModel.Name]["IMAGE_ID"]
    self.Layout.Stats.Layout.Text = cafeteriaModel.Name

    return self
end

function module:run()
    self.NPCStorage.ChildAdded:Connect(function(newStudent)
        self:createStudent(newStudent)
    end)

    self.NPCStorage.ChildRemoved:Connect(function(newStudent)
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
    local newTemplate = self.UI.Background.UIGridLayout.StudentTemplate:Clone()
    newTemplate.Visible = false
    newTemplate.Parent = self.Layout.Map

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

        local xPosition = student.PrimaryPart.Position.X * 3 * -1
        local zPosition = student.PrimaryPart.Position.Z * 3 * -1
        
        template.Visible = true

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

    local studentCount = #self.NPCStorage:GetChildren()
    local maxCapacity = PARAMETERS.SIMULATION.MAX_CAPACITY
    local duration = formatStopwatch(Workspace.DistributedGameTime)
    local heartbeat = math.round(1 / RunService.Heartbeat:Wait())

    self.Layout.Stats.Capacity.Text = string.format("%s/%s", studentCount, maxCapacity)
    self.Layout.Stats.RunTime.Text = string.format("%s", duration)
    self.Layout.Stats.AverageTimes.Text = string.format("%s-%s", 0, 0) -- TO DO
end

return module