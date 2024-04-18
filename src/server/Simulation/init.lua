--[[

    Handler for simulation

]]

local module = {}
module.__index = module

local Cafeteria = require(script.Cafeteria)
local UI = require(script.UI)

function module.new(cafeteria, templates, ui)
    local self = setmetatable({
        Cafeteria = Cafeteria.new(cafeteria, templates),
        UI = UI.new(ui),
    }, module)

    return self
end

function module:run(PARAMETERS)
    task.wait(3)
    coroutine.wrap(self.Cafeteria.run)(self.Cafeteria, PARAMETERS)
    coroutine.wrap(self.UI.run)(self.UI, PARAMETERS)
end

return module