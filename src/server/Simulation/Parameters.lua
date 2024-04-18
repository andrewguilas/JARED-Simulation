return {
    SIMULATION = {
        DOOR_ENTRY_TYPE = "ONE_WAY", -- ONE_WAY/TWO_WAY
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
            AgentRadius = 3,
			WaypointSpacing = 3,
			Wood = 12,
			Concrete = 6,
			SmoothPlastic = 1,
            -- LeftDoor = math.huge,
		},
    },
    UI = {
        UPDATE_DELAY = 0.03,
        STOP_COLOR = Color3.fromRGB(255, 0, 0),
        SLOW_COLOR = Color3.fromRGB(255, 180, 180),
        WALK_COLOR = Color3.fromRGB(255, 255, 255),
    },
}