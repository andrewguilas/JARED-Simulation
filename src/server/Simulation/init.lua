--[[

    Handler for simulation

]]

local module = {}
module.__index = module

local Cafeteria = require(script.Cafeteria)
local UI = require(script.UI)

function module.new(cafeteriaModel, templates, ui)
    return setmetatable({
        Cafeteria = Cafeteria.new(cafeteriaModel, templates),
        UI = UI.new(ui, cafeteriaModel),
    }, module)
end

function module:run()
    coroutine.wrap(self.Cafeteria.run)(self.Cafeteria)
    coroutine.wrap(self.UI.run)(self.UI)
end

return module