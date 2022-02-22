---------------------------------------------------------------------------
--
--  ALSA volume widget for away: away.widget.alsa
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local awful  = require("awful")
local gears  = require("gears")
local string = { match = string.match, format = string.format }

-- ALSA volume
local function worker(args)
    local args    = args or {}
    local amixer  = args.amixer or "amixer"
    local channel = args.channel or "Master"
    local togglechannel = args.togglechannel
    local theme = args.theme or {}
    local setting = args.setting or function(volume)
        volume.set_now(volume) -- use default set_now
    end
    args.timeout = args.timeout or 60

    local cmd = string.format("%s get %s", amixer, channel)
    if togglechannel then
        cmd = { awful.util.shell, "-c", string.format("%s get %s; %s get %s",
        amixer, channel, amixer, togglechannel) }
    end

    -- get now: {level, status}
    args.update = args.update or function (volume)
        awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            if exit_code ~= 0 then
                volume.now.level = -1
                volume.now.status = 'N/A'
                setting(volume)
                return
            end
            -- ref: https://github.com/lcpz/lain/blob/master/widget/alsa.lua
            local l, s = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
            l = tonumber(l)
            if volume.now.level ~= l or volume.now.status ~= s then
                volume.now.level = l
                volume.now.status = s
                setting(volume)
            end
        end)
    end

    local volume = core.worker(args)
    volume.timer:emit_signal('timeout')

    -- default set now: {icon, text}
    -- need theme.{vol_mute,vol_no,vol_low,vol} etc.
    volume.set_now = args.set_now or function (volume)
        local color
        if volume.now.status == "N/A" or volume.now.status == "off" then
            volume.now.icon = theme.vol_mute
            color = theme.vol_mute_color or "#EB8F8F"
        elseif volume.now.level == 0 then
            volume.now.icon = theme.vol_no
            color = theme.vol_no_color or "#EB8F8F"
        elseif volume.now.level <= 50 then
            volume.now.icon = theme.vol_low
            color = theme.vol_low_color or "#7493D2"
        else
            volume.now.icon = theme.vol
            color = theme.vol_color or theme.fg_normal
        end
        volume.now.text = util.markup_span(volume.now.level .. "% ", color)
        if volume.now.icon then
            volume.wicon:set_image(volume.now.icon)
        end
        volume.wtext:set_markup(volume.now.text)
    end

    -- buttons
    local buttoncmds = args.buttoncmds or {}
    local buttoncallupdate = args.buttoncallupdate or {
        left="off", middle=nil, right=nil, up=nil, down=nil }
    local step = args.step or "2%"
    volume.wtext:buttons(gears.table.join(
        awful.button({}, 1, function() -- left click
            awful.spawn.easy_async(buttoncmds.left or "xterm -e alsamixer",
                function(stdout, stderr, reason, exit_code)
                    if buttoncallupdate.left ~= "off" then
                        volume.update()
                    end
                end
            )
        end),
        awful.button({}, 2, function() -- middle click
            awful.spawn.easy_async(buttoncmds.middle or string.format("%s -q set %s 100%%", amixer, channel),
                function(stdout, stderr, reason, exit_code)
                    if buttoncallupdate.middle ~= "off" then
                        volume.update()
                    end
                end
            )
        end),
        awful.button({}, 3, function() -- right click
            awful.spawn.easy_async(buttoncmds.right or string.format("%s -q set %s playback toggle", amixer, channel),
                function(stdout, stderr, reason, exit_code)
                    if buttoncallupdate.right ~= "off" then
                        volume.update()
                    end
                end
            )
        end),
        awful.button({}, 4, function() -- scroll up
            awful.spawn.easy_async(buttoncmds.up or string.format("%s -q set %s %s+", amixer, channel, step),
                function(stdout, stderr, reason, exit_code)
                    if buttoncallupdate.up ~= "off" then
                        volume.update()
                    end
                end
            )
        end),
        awful.button ({}, 5, function() -- scroll down
            awful.spawn.easy_async(buttoncmds.down or string.format("%s -q set %s %s-", amixer, channel, step),
                function(stdout, stderr, reason, exit_code)
                    if buttoncallupdate.down ~= "off" then
                        volume.update()
                    end
                end
            )
        end)
    ))

    -- laptopkeys
    volume.laptopkeys = args.laptopkeys or gears.table.join(
        -- keycode 123 = XF86AudioRaiseVolume
        awful.key({}, "XF86AudioRaiseVolume", function()
            awful.spawn.easy_async(string.format("%s -q set %s %s+", amixer, channel, step),
                function(stdout, stderr, reason, exit_code)
                    volume.update()
                end
            )
        end),
        -- keycode 122 = XF86AudioLowerVolume
        awful.key({}, "XF86AudioLowerVolume", function()
            awful.spawn.easy_async(string.format("%s -q set %s %s-", amixer, channel, step),
                function(stdout, stderr, reason, exit_code)
                    volume.update()
                end
            )
        end),
        -- keycode 121 = XF86AudioMute
        awful.key({}, "XF86AudioMute", function()
            awful.spawn.easy_async(string.format("%s -q set %s playback toggle", amixer, channel),
                function(stdout, stderr, reason, exit_code)
                    volume.update()
                end
            )
        end),
        -- keycode 198 = XF86AudioMicMute
        awful.key({}, "XF86AudioMicMute", function ()
            awful.spawn(string.format("%s sset Capture toggle", amixer))
        end)
    )

    return volume
end

return worker
