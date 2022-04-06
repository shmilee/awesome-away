---------------------------------------------------------------------------
--
--  xrandr_menu module for away
--  generate awful menu items to call xrandr and show screen info
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local capi = { screen = screen, }
local util = require("away.util")
local xrandr = require("away.xrandr")
local naughty = require("naughty")
local pairs, type, setmetatable = pairs, type, setmetatable
local string = { format=string.format, rep = string.rep }
local table = { insert=table.insert, concat=table.concat }

local xrandr_menu = { mt={} }

-- s.dpi ~= dpi, then restart awesome
function xrandr_menu.compare_dpi_restart(dpi)
    for s in capi.screen do
        if s.dpi ~= dpi then
            local line = string.rep('-', 15)
            util.print_info(line .. " Restart awesome " .. line)
            awesome.restart() -- no need break
        end
    end
end

-- @param args table {
--      menuname='A',
--      template=function or string,  -- default xrandr.template_hline_scale
--      complete=false,  -- default false
--      dpi=96,          -- default 96
--      monitors={       -- default all connected monitors, scale=1.0
--          { key='Search key1', scale=1.0 }, ...,
--      },
--  }
-- @return a menu item { menuname, function() ... end }
function xrandr_menu.item(args)
    local args = args or { menuname='xrandr' }
    local template = xrandr.template_hline_scale
    if type(args.template) == 'function' then
        template = args.template
    elseif type(args.template) == 'string' then
        template = xrandr[args.template] or xrandr.template_hline_scale
    end
    local dpi = args.dpi or 96
    local func = function()
        util.async(xrandr.cmd_prop, function(stdout, err, reason, exit_code)
            if exit_code == 0 then
                local data = xrandr.parse_prop_output(stdout)
                local cmd = template(data, args.monitors, args.complete, dpi)
                if cmd then
                    util.async_with_shell(cmd, function()
                        xrandr.save_dpi_and_merge(dpi, function()
                            xrandr_menu.compare_dpi_restart(dpi)
                        end)
                    end, false)
                end
            end
        end)
    end
    return { args.menuname, func }
end

-- @param items table used to generate awful menu items, see menu_item
-- @return awful menu items
function xrandr_menu.new(items)
    local menu_items = {
        { "showX", xrandr.show_connected },
        { "showA", function()
            local text = {}
            for s in capi.screen do
                table.insert(text, string.format(
                    "Screen: %d\nDPI: %d\nGeometry: %dx%d",
                    s.index, s.dpi, s.geometry.width, s.geometry.height))
            end
            naughty.notify({ text=table.concat(text, '\n\n'), timeout=0 })
        end },
        { string.rep('-', 10), function () end }, -- sep
        { "Hline-auto", xrandr.example_call_hline_auto },
    }
    for _, v in pairs(items or {}) do
        table.insert(menu_items, xrandr_menu.item(v)) -- add to menu
    end
    return menu_items
end

function xrandr_menu.mt:__call(...)
    return xrandr_menu.new(...)
end

return setmetatable(xrandr_menu, xrandr_menu.mt)
