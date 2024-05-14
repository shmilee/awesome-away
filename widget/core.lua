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

    base.updatebuttons = awful.util.table.join(
        awful.button({}, 1, base.update),
        awful.button({}, 2, base.update),
        awful.button({}, 3, base.update))

    if args.timeout ~= nil then
        base.timer = gears.timer({ timeout=args.timeout, autostart=true, callback=base.update })
    end

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

    base.updatebuttons = awful.util.table.join(
        awful.button({}, 1, base.update),
        awful.button({}, 2, base.update),
        awful.button({}, 3, base.update))

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

    if args.timeout ~= nil then
        base.timer = gears.timer({ timeout=args.timeout, autostart=true, callback=base.update })
    end

    return base
end

-- @param workers children workers
-- @param args for wibox.widget
--      like selected worker widgets(wicon, wtext)
--      like default layout=wibox.layout.fixed.horizontal
function core.group(workers, args)
    local workers  = workers or {}
    local args     = args or {}
    args.layout    = args.layout or wibox.layout.fixed.horizontal
    if args.layout == 'horizontal' or args.layout == 'h' then
        args.layout = wibox.layout.fixed.horizontal
    elseif args.layout == 'vertical' or args.layout == 'v' then
        args.layout = wibox.layout.fixed.vertical
    end
    local wlayout = wibox.widget(args)
    local function update_workers()
        for _, w in ipairs(workers) do
            w.update()
        end
    end
    local updatebuttons = awful.util.table.join(
        awful.button({}, 1, update_workers),
        awful.button({}, 2, update_workers),
        awful.button({}, 3, update_workers)
    )
    local function attach(self, obj)
        obj:connect_signal("mouse::enter", function()
            for _, w in ipairs(self.workers) do
                w:show()
            end
        end)
        obj:connect_signal("mouse::leave", function()
            for _, w in ipairs(self.workers) do
                w:hide()
            end
        end)
    end
    return {
        workers = workers, wlayout = wlayout,
        update_workers = update_workers, updatebuttons = updatebuttons,
        attach = attach,
    }
end

return core
