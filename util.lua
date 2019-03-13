---------------------------------------------------------------------------
--
--  Utility module for away: away.util
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local io, debug, table = io, debug, table
local pairs, pcall, require = pairs, pcall, require

local util = {}
util.curdir = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]

-- Return a sequence of numbers from head to tail by step
function util.simple_range(head, tail, step)
    local res = {}
    while head <= tail do
        table.insert(res, head)
        head = head + step
    end
    return res
end

-- Return first available module in the candidates
function util.find_available_module(candidates)
    local c, status, module
    for _, c in pairs(candidates) do
        status, module = pcall(require, c)
        if status then
            return module
        end
    end
    return nil
end

util.json = util.find_available_module({
    'cjson', 'dkjson', 'lain.util.dkjson',
})

-- Return path file size in bytes
function util.get_file_size(path)
    local file = io.open(path, "rb")
    local size = file:seek("end")
    file:close()
    return size
end

return util
