local PARAMETERS = require(script.Parent.Parameters)

local globalData = {}
local methods = {}

local function main()
    for layoutName, _ in pairs(PARAMETERS.SIMULATION.LAYOUTS) do
        globalData[layoutName] = {
            EnterDurations = {},
            ExitDurations = {},
            Positions = {},
            CumulativePositions = {},
            NPCs = {},
        }

        --[[
        for xPosition = 0, 490 - PARAMETERS.UI.HEATMAP_NODE_SIZE, PARAMETERS.UI.HEATMAP_NODE_SIZE do
            for yPosition = 0, 250 - PARAMETERS.UI.HEATMAP_NODE_SIZE, PARAMETERS.UI.HEATMAP_NODE_SIZE do
                local index = string.format("%s.%s", xPosition, yPosition)
                globalData[layoutName].Positions[index] = {
                    X = xPosition,
                    Y = yPosition,
                    Count = 0,
                    Percentage = 0,
                }
                globalData[layoutName].CumulativePositions[index] = {
                    X = xPosition,
                    Y = yPosition,
                    Count = 0,
                    Percentage = 0,
                }
            end
        end
        ]]
    end
end

local function getAverage(tbl)
    local sum = 0
    local count = 0
    for _, v in ipairs(tbl) do
        if type(v) == "number" then
            sum = sum + v
            count = count + 1
        else
            return nil, "Table contains non-numeric value"
        end
    end
    if count > 0 then
        return sum / count
    else
        return nil, "Table is empty"
    end
end

function methods.addEnterDuration(layoutName, duration)
    table.insert(globalData[layoutName].EnterDurations, duration)
end

function methods.addExitDuration(layoutName, duration)
    table.insert(globalData[layoutName].ExitDurations, duration)
end

function methods.getAverageEnterDuration(layoutName)
    return getAverage(globalData[layoutName].EnterDurations)
end

function methods.getAverageExitDuration(layoutName)
    return getAverage(globalData[layoutName].ExitDurations)
end

function methods.updatePositions(layoutName)
    for index, _ in pairs(globalData[layoutName].Positions) do
        globalData[layoutName].Positions[index].Count = 0
    end

    local maxValue = 0
    local maxCumulativeValue = 0

    for _, npc in ipairs(globalData[layoutName].NPCs) do
        local xPosition = math.abs(math.round(npc.PrimaryPart.Position.X * 3 / PARAMETERS.UI.HEATMAP_NODE_SIZE) * PARAMETERS.UI.HEATMAP_NODE_SIZE)
        local yPosition = math.abs(math.round(npc.PrimaryPart.Position.Z * 3 / PARAMETERS.UI.HEATMAP_NODE_SIZE) * PARAMETERS.UI.HEATMAP_NODE_SIZE)
        local index = string.format("%s.%s", xPosition, yPosition)

        if xPosition == 500 then
            xPosition = 500 - PARAMETERS.UI.HEATMAP_NODE_SIZE
        end

        if yPosition == 250 then
            yPosition = 250 - PARAMETERS.UI.HEATMAP_NODE_SIZE
        end

        if globalData[layoutName].Positions[index] == nil then
            globalData[layoutName].Positions[index] = {
                X = xPosition,
                Y = yPosition,
                Count = 0,
                Percentage = 0,
            }
            globalData[layoutName].CumulativePositions[index] = {
                X = xPosition,
                Y = yPosition,
                Count = 0,
                Percentage = 0,
            }
        end

        globalData[layoutName].Positions[index].Count += 1
        globalData[layoutName].CumulativePositions[index].Count += 1

        if globalData[layoutName].Positions[index].Count > maxValue then
            maxValue = globalData[layoutName].Positions[index].Count
        end

        if globalData[layoutName].CumulativePositions[index].Count > maxCumulativeValue then
            maxCumulativeValue = globalData[layoutName].CumulativePositions[index].Count
        end
    end

    for _, npc in ipairs(globalData[layoutName].NPCs) do
        local xPosition = math.abs(math.round(npc.PrimaryPart.Position.X * 3 / PARAMETERS.UI.HEATMAP_NODE_SIZE) * PARAMETERS.UI.HEATMAP_NODE_SIZE)
        local yPosition = math.abs(math.round(npc.PrimaryPart.Position.Z * 3 / PARAMETERS.UI.HEATMAP_NODE_SIZE) * PARAMETERS.UI.HEATMAP_NODE_SIZE)
        local index = string.format("%s.%s", xPosition, yPosition)

        globalData[layoutName].Positions[index].Percentage = globalData[layoutName].Positions[index].Count / maxValue
        globalData[layoutName].CumulativePositions[index].Percentage = globalData[layoutName].CumulativePositions[index].Count / maxCumulativeValue
    
    end


end

function methods.getPositions(layoutName)
    methods.updatePositions(layoutName)
    return globalData[layoutName].Positions
end

function methods.getCumulativePositions(layoutName)
    methods.updatePositions(layoutName)
    return globalData[layoutName].CumulativePositions
end

function methods.trackNPC(layoutName, npc)
    table.insert(globalData[layoutName].NPCs, npc)
end

function methods.removeNPC(layoutName, npc)
    for i, v in ipairs(globalData[layoutName].NPCs) do
        if v == npc then
            table.remove(globalData[layoutName].NPCs, i)
            break
        end
    end
end

main()

return methods