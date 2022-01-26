---------------------------------------------------------------------------
--
--  third_party widget module in away: away.third_party.widget
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local setmetatable, rawget, require = setmetatable, rawget, require

return setmetatable({}, {
    __index = function(table, key)
        local module = rawget(table, key)
        if not module then
            module = require('away.third_party.widget.' .. key)
            table[key] = module
        end
        return module
    end
})
