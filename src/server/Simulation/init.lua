--[[

    Handler for simulation

]]

local module = {}
module.__index = module

local Cafeteria = require(script.Cafeteria)
local UI = require(script.UI)

function module.new(cafeteria, templates, ui)
    return setmetatable({
        Cafeteria = Cafeteria.new(cafeteria, templates),
        UI = UI.new(ui),
    }, module)
end

function module:run()
    task.wait(3)
    coroutine.wrap(self.Cafeteria.run)(self.Cafeteria)
    coroutine.wrap(self.UI.run)(self.UI)
end

return module