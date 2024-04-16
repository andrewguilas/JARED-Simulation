local ServerScriptService = game:GetService("ServerScriptService")

local Simulation = require(ServerScriptService.Simulation)

local function main()
    Simulation.new({
        DOOR_ENTRY_TYPE = "TWO_WAY", -- ONE_WAY/TWO_WAY
        DURATION = 1 * 60, -- (seconds)
        ENTRANCE_RATE = 2, -- (per second)
        EXIT_RATE = 1, -- (per second)
    }):run()
end

main()