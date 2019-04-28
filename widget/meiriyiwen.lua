---------------------------------------------------------------------------
--
--  每日一文 widget for away: away.widget.meiriyiwen
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local os = { date = os.date }
local math = { floor = math.floor }
local string = { format = string.format }
local type = type

local function worker(args)
    local args   = args or {}
    local api    = args.api or 'https://interface.meiriyiwen.com/article/today?dev=1'
    local curl   = args.curl or 'curl -f -s -m 1.7'
    local cmd    = string.format("%s '%s'", curl, api)
    local setting = args.setting or function(data)
        util.print_debug('meiriyiwen: ' .. (data['data']['title'] or 'N/A'))
        local content = data['data']['content']
        content = content:gsub("<p>", "    ")
        content = content:gsub("</p>", "\n")
        return string.format("\t\t<b>%s</b> (%s)\n%s\n",
            data['data']['title'], data['data']['author'], content)
    end
    local wen = {
        date=nil, text=nil,
        font=args.font or nil,
        font_size=args.font_size or args.fsize or 10,
        ratio=args.ratio or 0,
        height=args.height or 0.88,
    }

    function wen:set(uargs)
        local uargs = uargs or {}
        self.font = uargs.font or self.font
        self.font_size = uargs.font_size or uargs.fsize or self.font_size
        self.ratio = uargs.ratio or 0
        self.height = uargs.height or self.height
    end

    function wen.update(uargs)
        wen:set(uargs)
        if wen.text then
            if wen.date == os.date('%Y%m%d') then
                wen:show()
                return
            end
        end
        awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            local data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" then
                wen.date = data['data']['date']['curr']
                wen.text = setting(data)
                wen:show()
            end
        end)
    end

    function wen:show()
        self:hide()
        local screen = awful.screen.focused()
        local text = self.text
        if self.ratio > 0 then
            local start = text:find('\n', math.floor(text:len()*self.ratio))
            if start then
                text = text:sub(start)
            end
        end
        self.notification = naughty.notify({
            text    = text or 'N/A',
            font    = string.format("%s %s", self.font, self.font_size),
            timeout = 0,
            height  = math.floor(screen.geometry.height*self.height),
            screen  = screen
        })
    end

    function wen:hide()
        if self.notification then
            naughty.destroy(self.notification)
            self.notification = nil
        end
    end

    function wen:attach(obj)
        obj:connect_signal("mouse::enter", function() self.update() end)
        obj:buttons(gears.table.join(
                    awful.button({}, 1, function() self:hide() end),
                    awful.button({}, 2, function() self:hide() end),
                    awful.button({}, 3, function() self:hide() end)))
    end

    return wen
end

return worker
