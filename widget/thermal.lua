---------------------------------------------------------------------------
--
--  Temperature widget for away: away.widget.thermal
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local ipairs = ipairs
local io = { open = io.open }
local math = { floor = math.floor }
local table = { insert = table.insert, concat = table.concat }
local string = { format = string.format }

-- thermal temp
local function worker(args)
    local args  = args or {}
    local theme = args.theme or {}
    args.timeout = args.timeout or 10
    args.font    = args.font or nil
    local zone   = args.zone or {
        {name="zone0", file="/sys/class/thermal/thermal_zone0/temp", div = 1000},
        {name="zone1", file="/sys/class/thermal/thermal_zone1/temp", div = 1000},
        {name="zone2", file="/sys/class/thermal/thermal_zone2/temp", div = 1000},
        {name="zone3", file="/sys/class/thermal/thermal_zone3/temp", div = 1000},
    }
    local setting = args.setting or function(temp)
        if temp.now.temperature < 50 then
            temp.now.text = temp.now.temperature .. "°C "
        elseif temp.now.temperature < 75 then
            temp.now.text = util.markup_span(temp.now.temperature .. "°C ", theme.temp_high_color or "#f1af5f")
        else
            temp.now.text = util.markup_span(temp.now.temperature .. "°C ", theme.temp_higher_color or "#D91E1E")
        end
        temp.wtext:set_markup(temp.now.text)
        local noti = {}
        for i, v in ipairs(temp.now.thermal) do
            table.insert(noti, string.format('%s: %d°C', v.name, v.value))
        end
        temp.now.notification_text = table.concat(noti, '\n')
    end

    -- get now: {temperature, thermal}
    args.update = args.update or function (temp)
        local thermal = {}
        temp.now.temperature = 0
        -- Get all
        for i, v in ipairs(zone) do
            local f = io.open(v.file)
            if f then
                local t = f:read("*all")
                f:close()
                if t then
                    local val = math.floor(tonumber(t)/v.div)
                    table.insert(thermal, {name=v.name, value=val})
                    if val > temp.now.temperature then
                        temp.now.temperature = val
                    end
                end
            end
        end
        temp.now.thermal = thermal
        setting(temp)
    end

    local temp = core.popup_worker(args)
    if theme.temp then
        temp.wicon:set_image(theme.temp)
    end
    temp.now.notification_icon = args.notification_icon or theme.temp

    temp.timer:emit_signal('timeout')
    return temp
end

return worker
