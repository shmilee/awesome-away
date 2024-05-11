---------------------------------------------------------------------------
--
--  API usage monitor module for away: away.widget.apiusage
--
--  Copyright (c) 2024 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local awful = require("awful")
local util  = require("away.util")
local core  = require("away.widget.core")

local string = { format = string.format }
local table = { insert = table.insert, concat = table.concat }
local pairs, type = pairs, type

function worker(args)
    local args     = args or {}
    local id       = args.id or nil
    local api      = args.api or {}
    local query    = args.query or {}
    local header   = args.header or {}
    local postdata     = args.postdata or ''  -- then method = POST
    local curl     = args.curl or 'curl -f -s -m 7'
    local get_info = args.get_info or function(self, data) end
    local setting  = args.setting or nil -- function(self) end
    args.timeout = args.timeout or 3600 -- 1 hour
    args.font    = args.font or nil

    local query_str = {}
    for i,v in pairs(query) do
        table.insert(query_str, i .. '=' .. v)
    end
    query_str = table.concat(query_str, '&')
    local header_str = {}
    for i,v in pairs(header) do
        table.insert(header_str, string.format("--header '%s:%s'", i, v))
    end
    header_str = table.concat(header_str, ' ')
    local cmd = curl
    if postdata ~= '' then  -- POST
        cmd = string.format("%s -X POST --data '%s'", cmd, postdata)
    end
    if header_str ~= '' then
        cmd = string.format("%s %s", cmd, header_str)
    end
    if query_str ~= '' then
        cmd = string.format("%s '%s?%s'", cmd, api, query_str)
    else
        cmd = string.format("%s '%s'", cmd, api)
    end
    util.print_info('API-usage cmd: ' .. cmd, id)

    -- update self.now.xxxx: notification_text, text, icon(optional)
    function args.update(self)
        util.async(cmd, function(stdout, stderr, reason, exit_code)
            local data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" then
                get_info(self, data)
            else
                util.print_error('Failed to get API-usage: ' .. err, id)
                util.print_info(' ==> stdout: ' .. stdout, id)
            end
            if setting then
                setting(self)
            end
            if self.now.icon then
               self.wicon:set_image(self.now.icon)
            end
            self.wtext:set_markup(self.now.text)
        end)
    end

    local usage = core.popup_worker(args)
    usage.timer:emit_signal('timeout')

    buttons = awful.util.table.join(
        awful.button({}, 1, usage.update),
        awful.button({}, 2, usage.update),
        awful.button({}, 3, usage.update))
    usage.wicon:buttons(buttons)
    usage.wtext:buttons(buttons)

    return usage
end

return worker
