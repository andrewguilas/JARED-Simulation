--[[

    Handler for 2D UI minimap

]]

local module = {}
module.__index = module

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PARAMETERS = require(script.Parent.Parameters)
local DataCollection = require(script.Parent.DataCollection)

local function formatStopwatch(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end

local function getGradientColor(percentage)
    -- Ensure the percentage is within the valid range
    percentage = math.max(0, math.min(100, percentage))
    
    -- Define RGB values for green and red
    local green = {0, 255, 0}
    local red = {255, 0, 0}
    
    -- Interpolate between green and red based on the percentage
    local color = {}
    for i = 1, 3 do
        color[i] = math.floor(green[i] + (red[i] - green[i]) * (percentage / 100))
    end
    
    -- Return the interpolated color
    return Color3.fromRGB(color[1], color[2], color[3])
end

function module.new(ui, cafeteriaModel)
    local self = setmetatable({
        UI = ui,
        LayoutName = cafeteriaModel.Name,
        Layout = nil,
        NPCStorage = cafeteriaModel.NPCs,
        Frames = {},
    }, module)

    self.UI.Loading.Visible = false
    
    self.Layout = self.UI.Background.UIGridLayout.LayoutTemplate:Clone()
    self.Layout.LayoutOrder = PARAMETERS.SIMULATION.LAYOUTS[self.LayoutName].LAYOUT_ORDER
    self.Layout.Parent = self.UI.Background
    self.Layout.Map.Image = PARAMETERS.SIMULATION.LAYOUTS[self.LayoutName].IMAGE_ID
    self.Layout.Stats.Layout.Text = self.LayoutName

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
            self:updatePositions()
            task.wait(PARAMETERS.UI.UPDATE_POSITIONS_DELAY)
        end
    end)()

    coroutine.wrap(function()
        while true do
            self:updateStats()
            task.wait(PARAMETERS.UI.UPDATE_STATS_DELAY)
        end
    end)()

    coroutine.wrap(function()
        while true do
            self:updateHeatmap()
            task.wait(PARAMETERS.UI.UPDATE_HEATMAP_DELAY)
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

function module:updatePositions()
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
end

function module:updateStats()
    local studentCount = #self.NPCStorage:GetChildren()
    local maxCapacity = PARAMETERS.SIMULATION.MAX_CAPACITY
    local duration = formatStopwatch(Workspace.DistributedGameTime)
    local fps = math.round(1 / RunService.Heartbeat:Wait())
    local averageEnterDuration = DataCollection.getAverageEnterDuration(self.LayoutName) or 0
    local averageExitDuration = DataCollection.getAverageExitDuration(self.LayoutName) or 0

    self.Layout.Stats.FPS.Text = string.format("%s FPS", fps)
    self.Layout.Stats.Capacity.Text = string.format("%s/%s", studentCount, maxCapacity)
    self.Layout.Stats.RunTime.Text = string.format("%s", duration)
    self.Layout.Stats.AverageTimes.Text = string.format("%s-%s", math.round(averageEnterDuration), math.round(averageExitDuration))
end

function module:updateHeatmap()
    -- local positions = DataCollection.getPositions(self.LayoutName)
    local positions = DataCollection.getCollisions(self.LayoutName)
    for index, coordinate in pairs(positions) do
        local node = self.Layout.Heatmap:FindFirstChild(index)
        if node == nil then
            node = Instance.new("Frame")
            node.Name = index
            node.Position = UDim2.new(0, coordinate.X, 0, coordinate.Y)
            node.Size = UDim2.new(0, PARAMETERS.UI.HEATMAP_NODE_SIZE, 0, PARAMETERS.UI.HEATMAP_NODE_SIZE)
            node.BackgroundColor3 = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            node.BorderSizePixel = 0
            -- node.Text = "0"
            node.Parent = self.Layout.Heatmap
        end

        local multiplier = 1 - coordinate.Percentage
        node.BackgroundColor3 = Color3.fromRGB(255, 255 * multiplier, 255 * multiplier)
        -- node.Text = math.round(coordinate.Percentage * 100)
    end
end

return module