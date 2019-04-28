---------------------------------------------------------------------------
--
--  Base widget for away: away.widget.core
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")

local core = {}

-- base widget:
-- base.wtext -> textbox; base.wicon -> imagebox
-- base.now -> {}; base.timer
-- args:
--   timeout, update(base)
function core.worker(args)
    local base = {
        wicon = wibox.widget.imagebox(),
        wtext = wibox.widget.textbox(''),
        now = {
            icon = nil,
            text = nil,
        },
    }

    function base.update()
        args.update(base)
    end

    base.timer = gears.timer({ timeout=args.timeout, autostart=true, callback=base.update })

    return base
end

-- popup base widget:
-- base:show(), base:hide(), base:attach(obj)
-- base.wtext -> textbox; base.wicon -> imagebox
-- base.now -> {}; base.timer
-- args:
--   timeout, update(base)
-- optional args:
--   font
function core.popup_worker(args)
    local base = {
        wicon = wibox.widget.imagebox(),
        wtext = wibox.widget.textbox(''),
        now = {
            icon = nil,
            text = nil,
            notification_icon = nil,
            notification_text = nil,
        },
    }

    function base.update()
        args.update(base)
    end

    function base:show()
        self:hide()
        self.notification = naughty.notify({
            text    = self.now.notification_text or 'N/A',
            icon    = self.now.notification_icon,
            font    = args.font,
            timeout = 0,
            screen  = awful.screen.focused()
        })
    end

    function base:hide()
        if self.notification then
            naughty.destroy(self.notification)
            self.notification = nil
        end
    end

    function base:attach(obj)
        obj:connect_signal("mouse::enter", function() self:show() end)
        obj:connect_signal("mouse::leave", function() self:hide() end)
    end

    base.timer = gears.timer({ timeout=args.timeout, autostart=true, callback=base.update })

    return base
end

return core
