local PARAMETERS = {
    SIMULATION = {
        DOOR_ENTRY_TYPE = "TWO_WAY", -- ONE_WAY/TWO_WAY
        DURATION = 1 * 30, -- (seconds)
        ENTRANCE_RATE = 3, -- (students per second)
        EXIT_RATE = 2, -- (students per second)
        MAX_CAPACITY = 150,
        LOG_OUTPUT = false,
    },
    STUDENT = {
        MAX_WALK_SPEED = 16,
        SLOW_DISTANCE = 6,
        UPDATE_DELAY = 0.5,
        DISPOSING_DURATION = 2,
        SHOW_WAYPOINTS = false,
        AGENT_PARAMETERS = {
			AgentCanJump = false,
			WaypointSpacing = 3,
			Wood = 12,
			Concrete = 6,
			SmoothPlastic = 1,
		},
    },
    UI = {
        UPDATE_DELAY = 0.03,
        STOP_COLOR = Color3.fromRGB(255, 0, 0),
        SLOW_COLOR = Color3.fromRGB(255, 180, 180),
        WALK_COLOR = Color3.fromRGB(255, 255, 255),
    },
}

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local Simulation = require(script.Simulation)

local cafeteria = Workspace.Cafeteria
local templates = ServerStorage
local UI = StarterGui.UI

local function main()
    local simulation = Simulation.new(cafeteria, templates, UI)
    simulation:run(PARAMETERS)
end

main()