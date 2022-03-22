---------------------------------------------------------------------------
--
--  Battery widget for away: away.widget.battery
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local spawn = require("awful.spawn")
local gears = require("gears")
local naughty = require("naughty")

local math   = { floor  = math.floor }
local string = { format = string.format, match = string.match, gmatch = string.gmatch }
local tonumber, pairs = tonumber, pairs

-- Battery infos
local function worker(args)
    local args   = args or {}
    args.timeout = args.timeout or 10
    args.font    = args.font or nil
    local theme  = args.theme or {}
    local setting  = args.setting or function(bat)
        bat.set_now(bat) -- use default set_now
    end

    -- get now: {status, ac,
    --           battery_info, energy_now, energy_full, perc,
    --           notification_text}
    args.update = args.update or function (bat)
        spawn.easy_async('acpi -b -i', function(stdout, stderr, reason, exit_code)
            if exit_code ~= 0 then
                bat.now.status = 'N/A'
                bat.now.notification_text = 'No battery info!'
                setting(bat)
                return
            end
            if string.match(stderr, '^No support') then
                bat.now.status = 'AC'
                bat.now.notification_text = 'No battery. Using AC.'
                setting(bat)
                return
            end

            local battery_info, notification = {}, ''
            -- https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-power
            -- /sys/class/power_supply/<supply_name>/status
            bat.now.status = 'Unknown' -- Discharging, Charging, Unknown, Not charging, Full
            bat.now.ac = true
            for s in string.gmatch(stdout, "[^\r\n]+") do
                local name, status, perc = string.match(s, '(.+): ([%a%s]+), (%d+)%%,?.*')
                if status then
                    battery_info[name] = { status=status, perc=tonumber(perc) }
                    if status == 'Discharging' then
                        bat.now.status = status
                        bat.now.ac = false
                    end
                    if status == 'Charging' then
                        bat.now.status = status
                    end
                    notification = notification .. s .. '\n'
                end
                local name, cap = string.match(s, '(.+):.+last full capacity (%d+)')
                if cap then
                    if battery_info[name] then
                        battery_info[name]['cap'] = tonumber(cap)
                    end
                end
            end
            notification = string.match(notification, '(.+)\n$')
            bat.now.battery_info = battery_info
            bat.now.energy_now, bat.now.energy_full = 0, 0
            for n, v in pairs(battery_info) do
                bat.now.energy_now = bat.now.energy_now + battery_info[n]['cap']*battery_info[n]['perc']
                bat.now.energy_full = bat.now.energy_full + battery_info[n]['cap']
            end
            bat.now.perc = math.floor(bat.now.energy_now / bat.now.energy_full + 0.5)
            bat.now.notification_text = string.format("<b>%s%%</b>:\n%s", bat.now.perc, notification)
            setting(bat)
            bat.observer.status = bat.now.status
            bat.observer:emit_signal('property::status')
        end)
    end

    local bat = core.popup_worker(args)

    -- set now: {icon, text}, low and critical notification
    -- need theme.{ac,bat,bat_low,bat_no} etc.
    bat.set_now = args.set_now or function(bat)
        if bat.now.status == 'N/A' then
            bat.now.icon = theme.ac
            bat.now.text = ' N/A '
        elseif bat.now.status == 'AC' then
            bat.now.icon = theme.ac
            bat.now.text = ' AC '
        else
            if bat.now.perc > 50 then
                bat.now.icon = theme.bat
                bat.now.text = " " .. bat.now.perc .. "% "
            elseif bat.now.perc > 15 then
                bat.now.icon = theme.bat_low
                bat.now.text = util.markup_span(" " .. bat.now.perc .. "% ", theme.bat_low_color or '#EB8F8F')
            else
                bat.now.icon = theme.bat_no
                bat.now.text = util.markup_span(" " .. bat.now.perc .. "% ", theme.bat_no_color or "#D91E1E")
            end
            if bat.now.ac then
                bat.now.icon = theme.ac
            end
        end
        bat.wicon:set_image(bat.now.icon)
        bat.wtext:set_markup(bat.now.text)
        bat.now.notification_icon = bat.now.icon
        -- notifications for low and critical states
        if bat.now.status == "Discharging" then
            if bat.now.perc <= 5 then
                bat.now.notification_id = naughty.notify({
                    title   = "Battery exhausted",
                    text    = "Shutdown imminent",
                    icon    = theme.bat_no,
                    timeout = 15,
                    fg      = "#000000",
                    bg      = "#FFFFFF",
                    replaces_id = bat.now.notification_id,
                }).id
            elseif bat.now.perc <= 15 then
                bat.now.notification_id = naughty.notify({
                    title   = "Battery low",
                    text    = "Plug the cable!",
                    icon    = theme.bat_no,
                    timeout = 15,
                    fg      = "#202020",
                    bg      = "#CDCDCD",
                    replaces_id = bat.now.notification_id,
                }).id
            end
        end
    end

    bat.observer = gears.object({class={}})
    bat.observer.handlers = {}
    bat.observer:connect_signal('property::status', function(obj, val)
        -- self: obj is bat.observer
        for i, handler in pairs(obj.handlers) do
            handler(obj, val)
        end
    end)

    bat.timer:emit_signal('timeout')
    return bat
end

return worker
