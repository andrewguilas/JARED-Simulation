return {
    CAFETERIA = {
        SIMULATION_DELAY = 3,
        SPAWN_DELAY = 1, -- 4
        MAX_CAPACITY = 150,
        LOG_OUTPUT = true,
        SIMULATION_SPEED = 10, -- x times as fast, default is 1
        GROUP_SIZE = {
            {STUDENTS = 1, PROBABILITY = 0.10},
            {STUDENTS = 2, PROBABILITY = 0.25},
            {STUDENTS = 3, PROBABILITY = 0.25},
            {STUDENTS = 4, PROBABILITY = 0.25},
            {STUDENTS = 5, PROBABILITY = 0.10},
            {STUDENTS = 6, PROBABILITY = 0.05},
        },
        EATING_DURATION = {
            {MINUTE = 15, PROBABILITY = 0.15},
            {MINUTE = 30, PROBABILITY = 0.40},
            {MINUTE = 45, PROBABILITY = 0.30},
            {MINUTE = 60, PROBABILITY = 0.15},
        },
        ENTRY_RATE = {
            {MINUTE = 15, STUDENTS = 150},
            {MINUTE = 30, STUDENTS = 113},
            {MINUTE = 45, STUDENTS = 75},
            {MINUTE = 60, STUDENTS = 37},
        },
        EXTRA_FOOD = {
            {SERVINGS = 1, PROBABILITY = 0.60},
            {SERVINGS = 2, PROBABILITY = 0.25},
            {SERVINGS = 3, PROBABILITY = 0.10},
            {SERVINGS = 4, PROBABILITY = 0.05},
        }
    },
    STUDENT = {
        MAX_WALK_SPEED = 16,
        WALK_SPEED_K = -1,
        SLOW_DISTANCE = 6,
        STOP_DELAY = 0.5,
        SERVING_DURATION = 5,
        DISPOSING_DURATION = 2,
        SHOW_WAYPOINTS = false,
        LOG_OUTPUT = false,
    },
    UI = {
        ENABLED = true,
        UPDATE_DELAY = 0.1,
        STOP_COLOR = Color3.fromRGB(255, 0, 0),
        SLOW_COLOR = Color3.fromRGB(255, 180, 180),
        WALK_COLOR = Color3.fromRGB(255, 255, 255),
    },
}