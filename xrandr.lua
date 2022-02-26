---------------------------------------------------------------------------
--
--  xrandr module for away
--  generate awful menu items to call xrandr and show screen info
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local capi = { screen = screen, }
local naughty = require("naughty")
local awful = require("awful")
local gfs = require("gears.filesystem")
local utilloaded, util = pcall(require, "away.util")
local pairs, tonumber, type, setmetatable = pairs, tonumber, type, setmetatable
local string = { gmatch=string.gmatch, match = string.match,
    format=string.format, rep = string.rep }
local math = { ceil=math.ceil, floor=math.floor, max=math.max, min=math.min }
local table = { insert=table.insert, concat=table.concat,
    unpack=table.unpack, remove=table.remove }
local os = { remove = os.remove }
local io = { open = io.open }

local function get_monitor_info(self, key)
    local mi = self['Search'][key]
    if mi then
        return self[mi]
    else
        return nil
    end
end

local function show_monitors_info(self)
    local noti = ''
    if self['Count'] > 0 then
        for i=1,self['Count'] do
            local Mi = self[string.format('m%d', i)]
            if Mi then
                if i>1 then
                    noti = noti .. '\n\n'
                end
                --local query_str = {}
                --for i,v in pairs(Mi) do
                --    table.insert(query_str, i .. '=' .. tostring(v))
                --end
                --naughty.notify({ text = table.concat(query_str, '&') })
                noti = noti .. string.format(
                    "Monitor: %d\nName: %s\nDPI: %.2f\nGeometry: %dx%d",
                    Mi.i, Mi.N, Mi.DPI, Mi.W, Mi.H)
            end
        end
    end
    naughty.notify({ text = noti })
end

local xcmd_list = "xrandr --listmonitors"
local re = {}
re.WwHh = '(%d+)/(%d+)x(%d+)/(%d+)%+(%d+)%+(%d+)'
re.list = '%s*(%d+):%s*([%+%*]*)[%w-]+%s*' .. re.WwHh .. '%s*([%w-]+)'

-- parse `xrandr --listmonitors` output, like this:
--      Monitors: 2
--       0: +*eDP1 1366/310x768/170+0+0  eDP1
--       1: +HDMI1 3840/1220x2160/690+1366+0  HDMI1
-- return monitors info table:
--      'Count', 'Primary', 'Search', 'Searchkey',
--      'mi'={i,key,W,w,H,h,X,Y,N,dpix,dpiy,DPI},
--      :get(key), :show()
-- Search key, like this: eDP1-310x170, HDMI1-1220x690
local function parse_listmonitors(output)
    local res = { Count=0, Primary=nil, Search={}, Searchkey={},
                  get=get_monitor_info, show=show_monitors_info }
    for s in string.gmatch(output, "[^\r\n]+") do
        local i = string.match(s, 'Monitors:%s*(%d+)')
        if i then
            res['Count'] = tonumber(i)
        else
            local i, p, W, w, H, h, X, Y, N = string.match(s, re.list)
            if i then
                i = tonumber(i)+1
                local M = string.format('m%d', i)
                local key = string.format('%s-%sx%s', N, w, h)
                W, w = tonumber(W), tonumber(w)
                H, h = tonumber(H), tonumber(h)
                X, Y = tonumber(X), tonumber(Y)
                local dpix = math.ceil(W/(w/10/2.54)*100)/100
                local dpiy = math.ceil(H/(h/10/2.54)*100)/100
                local DPI = math.ceil((W^2+H^2)^0.5/((w^2+h^2)^0.5/10/2.54)*100)/100
                res[M] = { i=i, key=key, W=W, w=w, H=H, h=h, X=X, Y=Y, N=N,
                           dpix=dpix, dpiy=dpiy, DPI=DPI }
                res['Search'][key] = M
                table.insert(res['Searchkey'], key)
                if p == '+*' then
                    res['Primary'] = M
                end
            end
        end
    end
    return res
end

-- @param cmd string
-- @param callback function
-- @param shell call easy_async_with_shell if true
-- @param pass_args pass stdout, stderr, reason, ecode to callback if true
local function async_run(cmd, callback, shell, pass_args)
    local spawn_async
    if shell then
        spawn_async = awful.spawn.easy_async_with_shell
    else
        spawn_async = awful.spawn.easy_async
    end
    spawn_async(cmd, function(stdout, stderr, reason, ecode)
        if utilloaded then
            util.print_info(
                "Run command: " .. cmd .. ", DONE with exit code " .. ecode)
        end
        if type(callback) == 'function' then
            if pass_args then
                callback(stdout, stderr, reason, ecode)
            else
                callback()
            end
        end
    end)
end


local xrandr = { mt={} }
local Xresources = gfs.get_xdg_cache_home() .. 'away.Xresources'

-- save dpi Xcursor.size to away.Xresources (~/.cache/away.Xresources),
-- and xrdb -merge it, then restart awesome
function xrandr.save_dpi_merge_restart(dpi)
    dpi = dpi or 96
    local csize = math.min(math.floor(dpi/96+0.5)*16, 64)
    os.remove(Xresources)
    async_run(string.format(
        "echo 'Xft.dpi: %d\nXcursor.size: %d' > %s", dpi, csize, Xresources),
        function()
            async_run("xrdb -merge " .. Xresources, function()
                for s in capi.screen do
                    if s.dpi ~= dpi then
                        if utilloaded then
                            local line = string.rep('-', 15)
                            util.print_info(line .. " Restart awesome " .. line)
                        end
                        awesome.restart() -- no need break
                    end
                end
            end, true)
        end,
        true
    )
end

-- read dpi from away.Xresources, then call callback to set dpi
-- @param callback function fired with dpi as argument
function xrandr.read_set_dpi(callback)
    if type(callback) == 'function' then
        local dpi = 96 -- default
        if gfs.file_readable(Xresources) then
            -- awful.spawn.easy_async deprecated, get dpi immediately
            local file = io.open(Xresources, 'r')
            if file then
                local m = string.match(file:read(), 'Xft.dpi:%s*(%d+)%s*')
                file:close()
                if m then
                    dpi = tonumber(m)
                end
            end
        end
        callback(dpi)
    end
end

local function table_index(tab, el)
    for i, v in pairs(tab) do
        if v == el then
            return i
        end
    end
    return nil
end

-- filter needed monitors, add '--output' args
--   data:connected monitors   |   | 2 | 3 | 4 |   |
--   data0:known monitors      | 1 | 2 |   | 4 | 5 |
--   input:needed monitors     | 1 | 2 | 3 |   |   |
-- @param data, data0 table
-- @param monitors: {  { key='Search key', ... },  -- needed monitor 1
--  'Search key2', ... }
-- @param complete true if require all needed monitors connected
-- @return nil or needed and connected monitors with corresponding args: {
--      { M, M0, monitor input {}, '--output M.N --primary' }, -- M0 info from data0
--      ... 
--  }
-- @return nil or '--output --off' args: '--output M4.N --off ...'
function xrandr.filter_monitors(data, data0, monitors, complete)
    local res, off, i, args = {}, {}, 0, nil
    local connected = { table.unpack(data.Searchkey) }
    for _, v in pairs(monitors) do
        if type(v) == 'string' then
            v = { key=v }
        end
        local M, M0 = data:get(v.key), data0:get(v.key)
        if utilloaded then
            util.print_info("Search: " .. v.key .. ", get " .. tostring(M and M.N))
        end
        if M then
            i = i + 1
            args = string.format('--output %s', M.N)
            if i == 1 then
                args = args .. ' --primary'
            end
            table.insert(res, { M, M0, v, args})
            local idx = table_index(connected, v.key)
            if idx then
                table.remove(connected, idx) -- remove needed
            end
        else
            if complete then
                naughty.notify({ text = "Monitor " .. v.key .. " not connected!" })
                res = {}
                break
            end
        end
    end
    for _, v in pairs(connected) do -- connected & not needed
        local M = data:get(v)
        table.insert(off, string.format('--output %s --off', M.N))
    end
    if #res == 0 then
        res = nil
    end
    if #off == 0 then
        off = nil
    end
    return res, off and table.concat(off, ' ')
end

-- stack all connected outputs horizontally with scale support
-- @param data table current screen info get from xrandr:
--      'Count', 'Primary', 'Search', 'Searchkey', 'mi', ...
-- @param data0 table screen info set by user
-- @param dpi number
-- @param monitors = {
--      { key='Search key1', scale=1.0 },  -- monitor 1
--      'Search key2',  -- monitor 2
--      ...
--  }
-- @param complete true if need all monitors connected
-- @return cmd string:
--      xrandr --dpi %d --fb %dx%d [monitor1 args] ...
-- @return nil:
--      no connected monitors
--      or if complete is true and find one monitor not connected
function xrandr.template_hsline(data, data0, dpi, monitors, complete)
    local monitors, off = xrandr.filter_monitors(data, data0, monitors, complete)
    if monitors == nil then
        return nil
    end
    local res, fbw, fbh, posx = {}, 0, 0, 0
    for _, v in pairs(monitors) do
        local M, M0, v, args = v[1], v[2], v[3], v[4]
        local scale = v.scale or 1.0
        M = M0 or M -- use info set by user first
        local sW = math.ceil(M.W*scale)//2*2
        local sH = math.ceil(M.H*scale)//2*2
        args = args .. string.format(
            ' --mode %dx%d --scale %s --panning %dx%d+%d+%d',
            M.W, M.H, scale, sW, sH, posx, 0) -- right-of
        fbw, fbh = fbw + sW, math.max(fbh, sH)
        posx = posx + sW -- right-of
        table.insert(res, args)
    end
    if off ~= nil then
        table.insert(res, off)
    end
    table.insert(res, 1,
        string.format('xrandr --dpi %d --fb %dx%d', dpi, fbw, fbh))
    return table.concat(res, ' ')
end

-- @param args {
--      menuname='A',
--      template=function,  -- default xrandr.template_hsline
--      dpi=96,             -- default 96
--      monitors={          -- default all connected monitors, scale=1.0
--          { key='Search key1', scale=1.0 }, ...,
--      },
--      complete=false,     -- default false
--  }
-- @param data0
-- @return a menu item { menuname, function() ... end }
function xrandr.menu_item(args, data0)
    local template = args.template or xrandr.template_hsline
    local dpi = args.dpi or 96
    local complete = args.complete or false
    local func = function()
        async_run(xcmd_list, function(stdout, stderr, reason, exit_code)
            if exit_code == 0 then
                local data = parse_listmonitors(stdout)
                local monitors = args.monitors or { table.unpack(data.Searchkey) }
                local cmd = template(data, data0, dpi, monitors, complete)
                if cmd then
                    async_run(cmd, function()
                        xrandr.save_dpi_merge_restart(dpi)
                    end, true, false)
                end
            end
        end, false, true)
    end
    return { args.menuname, func }
end

-- parse `xrandr -q` output, like this:
--      Screen 0: ...
--      eDP1 connected primary 1366x768+0+0 (normal ...
--         1366x768      60.00*+
--      DP1 disconnected (normal left inverted right x axis y axis)
--      HDMI1 connected (normal left inverted right x axis y axis)
--         1920x1080     60.00 +  50.00
-- return connected monitors name table, like { eDP1, HDMI1 }
local function simple_parse_q(output)
    local res = {}
    for s in string.gmatch(output, "[^\r\n]+") do
        local N = string.match(s, '^([%w-]+) connected.*%(normal ')
        if N then
            table.insert(res, N)
        end
    end
    return res
end

-- @param args.info string all screen info set by user,
--  like `xrandr --listmonitors` output
-- @param args.items table used to generate awful menu items, see menu_item
-- @return awful menu items
function xrandr.new(args)
    local args = args or {}
    local data0 = parse_listmonitors(args.info or '')
    local items = {
        { "show0", function()
            data0:show()
        end },
        { "showX", function()
            async_run(xcmd_list, function(stdout, stderr, reason, exit_code)
                if exit_code == 0 then
                    local data = parse_listmonitors(stdout)
                    data:show()
                end
            end, false, true)
        end },
        { "showA", function()
            local s = awful.screen.focused()
            naughty.notify({ text = string.format(
                "Screen: %d\nDPI: %d\nGeometry: %dx%d",
                s.index, s.dpi, s.geometry.width, s.geometry.height) })
        end },
        { string.rep('-', 10), function () end }, -- sep
        { "H-all", function()
            async_run('xrandr -q', function(stdout, stderr, reason, exit_code)
                if exit_code == 0 then
                    local cmd = 'xrandr'
                    outs = simple_parse_q(stdout)
                    for i, o in pairs(outs) do
                        cmd = cmd .. ' --output ' .. o .. ' --auto'
                        if i == 1 then
                            cmd = cmd .. ' --primary'
                        else
                            cmd = cmd .. ' --right-of ' .. outs[i-1]
                        end
                    end
                    async_run(cmd, nil, true, false)
                end
            end, false, true)
        end },
    }
    for _, v in pairs(args.items or {}) do
        table.insert(items, xrandr.menu_item(v, data0)) -- add to menu
    end
    return items
end

function xrandr.mt:__call(...)
    return xrandr.new(...)
end

return setmetatable(xrandr, xrandr.mt)
