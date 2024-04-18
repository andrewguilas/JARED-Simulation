--[[

    Initial script for simulation

]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local Simulation = require(script.Simulation)

local cafeteria = Workspace.Cafeteria
local templates = ServerStorage
local UI = StarterGui.UI

local function main()
    local simulation = Simulation.new(cafeteria, templates, UI)
    simulation:run()
end

main()