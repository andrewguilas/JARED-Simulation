return {
    SIMULATION = {
        LAYOUTS = {
            ["TWO_WAY_DOOR"] = {
                IMAGE_ID = "rbxassetid://17195958646"
            },
            ["ONE_WAY_DOOR"] = {
                IMAGE_ID = "rbxassetid://17195970077"
            }, 
        },
        ENTER_AMOUNT = 100,
        ENTER_RATE = 2,
        EXIT_AMOUNT = 50,
        EXIT_RATE = 1,
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
            AgentRadius = 2,
			WaypointSpacing = 3,
            Costs = {
                Wood = 12,
                Concrete = 2,
                -- LeftDoor = math.huge,
                -- SmoothPlastic = 1,
                Paths = 1,
            }
		},
    },
    UI = {
        UPDATE_POSITIONS_DELAY = 0.05,
        UPDATE_STATS_DELAY = 1,
        UPDATE_HEATMAP_DELAY = 0.5,
        STOP_COLOR = Color3.fromRGB(255, 0, 0),
        SLOW_COLOR = Color3.fromRGB(255, 180, 180),
        WALK_COLOR = Color3.fromRGB(255, 255, 255),
        HEATMAP_NODE_SIZE = 25, -- multiples of 500 and 250: 1, 2, 5, 10, 25, 50, 125, and 250
    },
}