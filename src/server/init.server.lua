--[[

    Initial script for simulation

]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local Simulation = require(script.Simulation)
local PARAMETERS = require(script.Simulation.Parameters)

local layouts = ServerStorage.Layouts
local templates = ServerStorage.Templates
local ui = StarterGui.UI

local function main()
    for seconds = 3, 1, -1 do
        print(string.format("Starting simulation in %s seconds...", seconds))
        task.wait(1)
    end
    
    for layoutName, _ in pairs(PARAMETERS.SIMULATION.LAYOUTS) do
        local cafeteria = Workspace:FindFirstChild(layoutName) or layouts[layoutName]:Clone()
        cafeteria.Parent = Workspace

        local simulation = Simulation.new(cafeteria, templates, ui)
        simulation:run()
    end
end

main()