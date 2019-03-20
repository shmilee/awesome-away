---------------------------------------------------------------------------
--
--  weather widget for away: away.widget.weather
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local setmetatable, rawget, require = setmetatable, rawget, require

return setmetatable({}, {
    __index = function(table, key)
        local module = rawget(table, key)
        if not module then
            module = require('away.widget.weather.' .. key)
            table[key] = module
        end
        return module
    end
})
