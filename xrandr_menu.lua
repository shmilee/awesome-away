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
local pairs, setmetatable = pairs, setmetatable
local string = { format=string.format, rep = string.rep }
local table = { insert=table.insert, concat=table.concat }

local xrandr_menu = { mt={} }

-- @param args table {
--      name='A',
--      template=function or string,  -- default xrandr.template_hline_scale
--      complete=false,  -- default false
--      dpi=96,          -- default 96
--      monitors={       -- default all connected monitors
--          -- default scale=1.0 for xrandr.template_hline_scale
--          { key='Search key1', scale=1.0 }, 'Search key2', ...,
--      },
--  }
-- @return a menu item { name, function() ... end }
function xrandr_menu.item(args)
    local args = args or {}
    return { args.name or 'xrandr', function()
        xrandr.call_template(args, function()
            local dpi = args.dpi or 96
            -- s.dpi ~= dpi, then restart awesome
            for s in capi.screen do
                if s.dpi ~= dpi then
                    local line = string.rep('-', 15)
                    util.print_info(line .. " Restart awesome " .. line)
                    awesome.restart() -- no need break
                end
            end
        end)
    end }
end

-- @param items table used to generate awful menu items, see xrandr_menu.item
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
        { "Hline-scale", xrandr.example_call_hline_scale },
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
