---------------------------------------------------------------------------
--
--  Utility module for away: away.util
--
--  Copyright (c) 2019-2023 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local io, os, debug, table = io, os, debug, table
local print, tostring, pairs, ipairs, rawset, pcall, require
    = print, tostring, pairs, ipairs, rawset, pcall, require
local string = { format = string.format, gmatch = string.gmatch }
local awfulloaded, awful = pcall(require, "awful")
local gfsloaded, gfs = pcall(require, "gears.filesystem")
local gtabloaded, gtable = pcall(require, "gears.table")

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
        T = os.date('%F %H:%M:%S')
        msg = T .. " Away" .. leveltxt .. ': ' .. msgprefix .. tostring(msg)
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
    'cjson', 'dkjson', 'away.third_party.dkjson',
    'third_party.dkjson', 'awesome-away.third_party.dkjson',
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
        table.insert(attrs, string.format('background="%s"', bg))
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

-- awful part

local spawn_async, spawn_async_with_shell
if awfulloaded then
    spawn_async = awful.spawn.easy_async
    spawn_async_with_shell = awful.spawn.easy_async_with_shell
else
    -- ref: https://github.com/vicious-widgets/vicious/blob/master/spawn.lua
    function spawn_async_with_shell(cmd, callback)
        local out_stream = io.popen(cmd)
        local stdout = out_stream:read("*all")
        local success, reason, code = out_stream:close() -- requiring Lua 5.2
        local stderr = 'empty stderr due to limitation of io.popen'
        callback(stdout, stderr, reason, code)
        return success
    end
    spawn_async = spawn_async_with_shell
end

-- @param spawn_async function to use
local function async_run(spawn_async, cmd, callback, pass_args)
    spawn_async(cmd, function(stdout, stderr, reason, ecode)
        util.print_info(
            "Run command: " .. cmd .. ", DONE with exit code " .. ecode)
        if type(callback) == 'function' then
            if pass_args or (pass_args == nil) then
                callback(stdout, stderr, reason, ecode)
            else
                callback()
            end
        end
    end)
end

-- @param cmd string
-- @param callback function
-- @param pass_args boolean, default true
--      pass stdout, stderr, reason, ecode to callback if true
function util.async(cmd, callback, pass_args)
    async_run(spawn_async, cmd, callback, pass_args)
end

function util.async_with_shell(cmd, callback, pass_args)
    async_run(spawn_async_with_shell, cmd, callback, pass_args)
end

-- @param program string
-- @param args string Options and arguments for program
-- @param matcher string A matching string to find the instance
-- @param start string For autostart(default) or restart
function util.single_instance(program, args, matcher, start)
    if not program then
        return nil
    end
    local cmd = program
    if args then
        cmd = cmd .. " " .. args
    end
    if not matcher then
        matcher = cmd
    end
    start = start or 'autostart'
    util.async_with_shell("pgrep -f -u $USER -x '" .. matcher .. "'", function(stdout, stderr, reason, code)
        if code == 0 then
            util.print_info("[SI] '" .. matcher .. "' is running! PID=" .. stdout)
            if start ~= 'autostart' then
                for pid in string.gmatch(stdout, "[^\r\n]+") do
                    util.async_with_shell('kill ' .. pid, function(o, e, r, c)
                        util.print_info("[SI] Restart '" .. matcher .. "'!")
                        util.async_with_shell(cmd)  -- to restart
                    end)
                    break  -- only kill first match
                end
            end
        else -- autostart
            util.print_info("[SI] Autostart '" .. program .. "'!")
            util.async_with_shell(cmd)
        end
    end)
end

-- gfs part

if gfsloaded then
    util.get_xdg_config_home = gfs.get_xdg_config_home
    util.get_xdg_cache_home = gfs.get_xdg_cache_home
    util.file_readable = gfs.file_readable
else
    function util.get_xdg_config_home()
        return (os.getenv("XDG_CONFIG_HOME")
            or os.getenv("HOME") .. "/.config") .. "/"
    end

    function util.get_xdg_cache_home()
        return (os.getenv("XDG_CACHE_HOME")
            or os.getenv("HOME") .. "/.cache") .. "/"
    end

    function util.file_readable(filename)
        local f = io.open(filename, "rb")
        if f then f:close() end
        return f ~= nil
    end
end

-- gtable part

if gtabloaded then
    util.table_crush = gtable.crush
    util.table_hasitem = gtable.hasitem
    util.table_merge = gtable.merge
else
    -- update table *t*
    function util.table_crush(t, set, raw)
        if raw then
            for k, v in pairs(set) do
                rawset(t, k, v)
            end
        else
            for k, v in pairs(set) do
                t[k] = v
            end
        end
        return t
    end
    --- Check if a table has an item and return its key.
    function util.table_hasitem(t, item)
        for k, v in pairs(t) do
            if v == item then
                return k
            end
        end
    end
    --- Merge items from one table to another one.
    function util.table_merge(t, set)
        for _, v in ipairs(set) do
            table.insert(t, v)
        end
        return t
    end
end
util.table_update = util.table_crush

return util
