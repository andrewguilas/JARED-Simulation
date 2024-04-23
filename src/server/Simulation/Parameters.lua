return {
    SIMULATION = {
        LAYOUTS = {
            ["TWO_WAY"] = {
                ENABLED = true,
                IMAGE_ID = "rbxassetid://17195958646",
                LAYOUT_ORDER = 1,
            },
            ["TWO_WAY_FAR"] = {
                ENABLED = false,
                IMAGE_ID = "rbxassetid://17250608265",
                LAYOUT_ORDER = 2,
            },
            ["ONE_WAY"] = {
                ENABLED = true,
                IMAGE_ID = "rbxassetid://17195970077",
                LAYOUT_ORDER = 3,
            }, 
            ["ONE_WAY_SAME_SIDE"] = {
                ENABLED = true,
                IMAGE_ID = "rbxassetid://17212371736",
                LAYOUT_ORDER = 4,
            },

        },
        ENTER_AMOUNT = 50,
        ENTER_RATE = 2,
        EXIT_AMOUNT = 50,
        EXIT_RATE = 2,
        MAX_CAPACITY = 150,
        LOG_OUTPUT = false,
    },
    STUDENT = {
        MAX_WALK_SPEED = 16,
        SLOW_DISTANCE = 10,
        UPDATE_DELAY = 0.25,
        DISPOSING_DURATION = 5,
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