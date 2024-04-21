local PARAMETERS = require(script.Parent.Parameters)

local globalData = {}
local methods = {}

local function main()
    for layoutName, _ in pairs(PARAMETERS.SIMULATION.LAYOUTS) do
        globalData[layoutName] = {
            EnterDurations = {},
            ExitDurations = {},
            HighestCollisionCount = 0,
            Collisions = {},
            NPCs = {},
        }
    end

    game:BindToClose(methods.printData)
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

local function getMedian(tbl)
    -- Check if the array is empty
    if #tbl == 0 then
        return nil, "Array is empty"
    end

    -- Sort the array in ascending order
    table.sort(tbl)

    -- Get the length of the array
    local length = #tbl

    -- Check if the array has only one element
    if length == 1 then
        return tbl[1]
    end

    -- Check if the number of elements is odd
    if length % 2 == 1 then
        -- If odd, return the middle element
        return tbl[(length + 1) / 2]
    else
        -- If even, return the average of the two middle elements
        local middle1 = tbl[length / 2]
        local middle2 = tbl[length / 2 + 1]
        return (middle1 + middle2) / 2
    end
end

local function getUIPosition(position)
    return math.abs(math.round(position * 3 / PARAMETERS.UI.HEATMAP_NODE_SIZE) * PARAMETERS.UI.HEATMAP_NODE_SIZE)
end

local function arrayToCSV(array)
    return table.concat(array, ',')
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

function methods.addCollision(layoutName, npc)
    local xPosition = getUIPosition(npc.PrimaryPart.Position.X)
    local yPosition = getUIPosition(npc.PrimaryPart.Position.Z)
    local index = string.format("%s.%s", xPosition, yPosition)

    if globalData[layoutName].Collisions[index] == nil then
        globalData[layoutName].Collisions[index] = {
            X = xPosition,
            Y = yPosition,
            Count = 1,
            Percentage = 0,
        }

        return
    end

    globalData[layoutName].Collisions[index].Count += 1

    if globalData[layoutName].Collisions[index].Count > globalData[layoutName].HighestCollisionCount then
        globalData[layoutName].HighestCollisionCount = globalData[layoutName].Collisions[index].Count
    end

    -- note: positions don't get updated until methods.getCollisions() is called
end

function methods.getCollisions(layoutName)
    for _, data in pairs(globalData[layoutName].Collisions) do
        data.Percentage = data.Count / globalData[layoutName].HighestCollisionCount
    end

    return globalData[layoutName].Collisions
end

function methods.printData()
    for layoutName, data in pairs(globalData) do
        print(string.format("%s_ENTER,%s", layoutName, arrayToCSV(data.EnterDurations)))
        print(string.format("%s_EXIT,%s", layoutName, arrayToCSV(data.ExitDurations)))

        local collisions = {}
        for position, collisionData in pairs(data.Collisions) do
            for _ = 1, collisionData.Count do
                table.insert(collisions, position)
            end
        end
        print(string.format("%s_COLLISIONS,%s", layoutName, arrayToCSV(collisions)))

    end
end

main()

return methods