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
local print, tostring, pairs, pcall, require
    = print, tostring, pairs, pcall, require
local string = { format = string.format }

local util = {}
util.curdir = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]
util.recursion_try_limit = 16

-- Simple Log level:
-- 10 DEBUG
-- 20 INFO
-- 30 ERROR
util.log_level = 20
util.log_std = 'stderr' -- 'stdout'

-- Print msg when level>=log_level
function util.print_msg(level, leveltxt, msg, msgprefix)
    if level >= util.log_level then
        if msgprefix then
            msgprefix = tostring(msgprefix) .. ': '
        else
            msgprefix = ''
        end
        msg = "Away: " .. leveltxt .. ' ' .. msgprefix .. tostring(msg)
        if util.log_std == 'stderr' then
            io.stderr:write(msg .. '\n')
            io.flush()
        else
            print(msg)
        end
    end
end

-- Print debug msg when 10>=log_level
function util.print_debug(msg, msgprefix)
    util.print_msg(10, "[D]", msg, msgprefix)
end

-- Print info msg when 20>=log_level
function util.print_info(msg, msgprefix)
    util.print_msg(20, "[I]", msg, msgprefix)
end

-- Print error msg when 30>=log_level
function util.print_error(msg, msgprefix)
    util.print_msg(30, "[E]", debug.traceback(msg), msgprefix)
end

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

-- Set Markup foreground, background color and more, like font, size, etc.
-- see https://docs.gtk.org/Pango/pango_markup.html#the-span-attributes
function util.markup_span(text, fg, bg, more)
    local attrs = {}
    if fg then
        table.insert(attrs, string.format('foreground="%s"', fg))
    end
    if bg then
        table.insert(attrs, string.format('background="%s"', fg))
    end
    more = more or {}
    for i, v in pairs(more) do
        table.insert(attrs, string.format('%s="%s"', i, v))
    end
    attrs = table.concat(attrs, ' ')
    return string.format('<span %s>%s</span>', attrs, text)
end

-- Set Markup convenience Tags, like:
-- b, big, i, s, u, etc.
-- see https://docs.gtk.org/Pango/pango_markup.html#convenience-tags
function util.markup(text, tag)
    return string.format('<%s>%s</%s>', tag, text, tag)
end

return util
