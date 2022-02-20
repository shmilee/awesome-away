---------------------------------------------------------------------------
--
--  sinfo module for away, tools to show screen info and call xrandr
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local naughty = require("naughty")
local awful = require("awful")
local gfs = require("gears.filesystem")
local utilloaded, util = pcall(require, "away.util")
local pairs, tonumber, type = pairs, tonumber, type
local string = { gmatch=string.gmatch, match = string.match,
    format=string.format, rep = string.rep }
local math = { ceil=math.ceil }
local table = { insert=table.insert, concat=table.concat, unpack=table.unpack }
local os = { remove = os.remove }
local io = { open = io.open }


-- data0: preferred screen info set by user
-- data: current screen info get from xrandr
local sinfo = { data0=nil, data=nil }
local cmd = "xrandr --listmonitors"

-- parse output, like this:
-- Monitors: 2
--  0: +*eDP1 1366/310x768/170+0+0  eDP1
--  1: +HDMI1 3840/1220x2160/690+1366+0  HDMI1
-- return data:
--  'Count', 'Primary', 'Search', 'mi'={W,w,H,h,X,Y,N,dpix,dpiy,DPI}
-- Search key, like this:
--  eDP1-1366/310x768/170, HDMI1-3840/1220x2160/690,
--  eDP1-310x170, HDMI1-1220x690
function sinfo.parse(output)
    local res = { Count=0, Primary=nil, Search={} }
    for s in string.gmatch(output, "[^\r\n]+") do
        local i = string.match(s, 'Monitors:%s*(%d+)')
        if i then
            res['Count'] = tonumber(i)
        else
            local i, p, size, W, w, H, h, X, Y, N = string.match(s,
                '%s*(%d+):%s*([%+%*]*)%w+%s*((%d+)/(%d+)x(%d+)/(%d+))%+(%d+)%+(%d+)%s*(%w+)')
            if i then
                i = tonumber(i)+1
                local M = string.format('m%d', i)
                W, w = tonumber(W), tonumber(w)
                H, h = tonumber(H), tonumber(h)
                X, Y = tonumber(X), tonumber(Y)
                local dpix = math.ceil(W/(w/10/2.54)*100)/100
                local dpiy = math.ceil(H/(h/10/2.54)*100)/100
                local DPI = math.ceil((W^2+H^2)^0.5/((w^2+h^2)^0.5/10/2.54)*100)/100
                res[M] = { i=i, W=W, w=w, H=H, h=h, X=X, Y=Y, N=N,
                           dpix=dpix, dpiy=dpiy, DPI=DPI }
                res['Search'][N .. '-' .. size] = M
                res['Search'][string.format('%s-%dx%d', N, w, h)] = M
                if p == '+*' then
                    res['Primary'] = M
                end
            end
        end
    end
    return res
end

-- add sinfo.data['Connected'] = { Names }
function sinfo.update()
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        if exit_code == 0 then
            sinfo.data = sinfo.parse(stdout)
            sinfo.data['Connected'] = {}
            if sinfo.data['Count'] > 0 then
                for i=1,sinfo.data['Count'] do
                    local M = sinfo.data[string.format('m%d', i)]
                    if sinfo.data[M] then
                        table.insert(sinfo.data['Connected'], M.N)
                    end
                end
            end
        end --TODO
    end)
end

-- @param info0 string, like output of 'xrandr --listmonitors'
function sinfo.init(info0)
    sinfo.data0 = sinfo.parse(info0 or '')
    sinfo.update()
end

function sinfo.showdata(data)
    local noti = ''
    if data and data['Count'] > 0 then
        for i=1,data['Count'] do
            local M = data[string.format('m%d', i)]
            if M then
                if i>1 then
                    noti = noti .. '\n\n'
                end
                --local query_str = {}
                --for i,v in pairs(M) do
                --    table.insert(query_str, i .. '=' .. tostring(v))
                --end
                --naughty.notify({ text = table.concat(query_str, '&') })
                noti = noti .. string.format(
                    "Monitor: %d\nName: %s\nDPI: %.2f\nGeometry: %dx%d",
                    M.i, M.N, M.DPI, M.W, M.H)
            end
        end
    end
    naughty.notify({ text = noti })
end

function sinfo.get_monitor(data, key)
    if data and data['Search'][key] then
        local M = data['Search'][key]
        return data[M] or nil
    end
    return nil
end

function sinfo.table_index(tab, el)
    for i, v in pairs(tab) do
        if v == el then
            return i
        end
    end
    return nil
end

-- @param dpi
-- @param complete true if need all monitors connected
-- @param monitors = {
--  { key='Search key', scale=1.0 },  -- monitor 1
--  { },  -- monitor 2
--  ...
-- }
-- return cmd string: xrandr --dpi %d --fb %dx%d [monitor1 args] ...
--  or nil if complete is true and find one monitor not connected
function sinfo.template_D(dpi, complete, monitors)
    local res = {}
    local Connected = { table.unpack(sinfo.data['Connected']) } -- TODO
    local i, fbw, fbh, posx = 0, 0, 0, 0
    for _, v in pairs(monitors) do
        local MC = sinfo.get_monitor(sinfo.data, v.key)
        local M = sinfo.get_monitor(sinfo.data0, v.key)
        if MC and M then
            if utilloaded then
                util.print_debug(
                    "sinfo Search: " .. v.key .. ", get " .. tostring(M.N))
            end
            i = i + 1
            local sW = math.ceil(M.W*v.scale)//2*2
            local sH = math.ceil(M.H*v.scale)//2*2
            table.insert(res, string.format(
                '--output %s --mode %dx%d --scale %s --panning %dx%d+%d+%d',
                M.N, M.W, M.H, v.scale, sW, sH, posx, 0))
            fbw, fbh = fbw + sW, fbh + sH
            posx = posx + sW
            if i == 1 then
                table.insert(res, '--primary')
            end
            -- remove 
            local idx = sinfo.table_index(Connected, M.N)
        else
            if complete then
                naughty.notify({
                    text = "Monitor " .. v.key .. " not connected!" })
                return nil
            end
        end
    end
    table.insert(res, 1, string.format(
        'xrandr --dpi %d --fb %dx%d', dpi or 96, fbw, fbh))
    return table.concat(res, ' ')
end

-- @param xcmd string
-- @param callback function
function sinfo.run(xcmd, callback)
    awful.spawn.easy_async_with_shell(xcmd, function(out, err, reason, ecode)
        if utilloaded then
            util.print_info(
                "Run command: " .. xcmd .. ", DONE with exit code " .. ecode)
        end
        if type(callback) == 'function' then
            callback()
        end
    end)
end

sinfo.Xresources = gfs.get_xdg_cache_home() .. 'sinfo.Xresources'

-- save dpi to sinfo.Xresources (~/.cache/sinfo.Xresources),
-- and xrdb -merge it, then restart awesome
function sinfo.save_dpi_merge_restart(dpi)
    dpi = dpi or 96
    os.remove(sinfo.Xresources)
    sinfo.run(string.format("echo 'Xft.dpi: %d' > %s", dpi, sinfo.Xresources),
        function()
            sinfo.run("xrdb -merge " .. sinfo.Xresources, function()
                if utilloaded then
                    local line = string.rep('-', 15)
                    util.print_info(line .. " Restart awesome " .. line)
                end
                awesome.restart()
            end)
        end
    )
end

-- read dpi from sinfo.Xresources, then call callback to set dpi
-- @param callback function fired with dpi as argument
function sinfo.read_set_dpi(callback)
    if type(callback) == 'function' then
        local dpi = 96 -- default
        if gfs.file_readable(sinfo.Xresources) then
            -- awful.spawn.easy_async deprecated, get dpi immediately
            local file = io.open(sinfo.Xresources, 'r')
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

-- @param args = {
--  { menuname='A', template=function, dpi=96, monitors={args for template} },
--  { menuname='B', ... },
-- }
function sinfo.menu(args)
    local menu = {
        { "update", function()
            sinfo.update()
        end },
        { "show0", function()
            sinfo.showdata(sinfo.data0)
        end },
        { "showX", function()
            sinfo.showdata(sinfo.data)
        end },
        { "showA", function()
            local s = awful.screen.focused()
            naughty.notify({ text = string.format(
                "Screen: %d\nDPI: %d\nGeometry: %dx%d",
                s.index, s.dpi, s.geometry.width, s.geometry.height) })
        end },
        { string.rep('-', 10), function () end }, -- sep
    }
    for _, v in pairs(args or {}) do
        local template = sinfo.template_D
        if type(v) == 'table' then
            if type(v.template) == 'function' then
                template = v.template
            end
            -- add to menu
            table.insert(menu, { v.menuname, function()
                local xcmd = template(v.dpi, v.monitors)
                sinfo.run(xcmd, function()
                    sinfo.update()
                    sinfo.save_dpi_merge_restart(v.dpi)
                end)
            end })
        end
    end
    return menu
end

return sinfo
