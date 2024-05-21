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

local function get_curl_cmd(curl, oneapi)
    local cmd = curl
    local header_str = {}
    for i, v in pairs(oneapi.header or {}) do
        table.insert(header_str, string.format("--header '%s:%s'", i, v))
    end
    header_str = table.concat(header_str, ' ')
    if header_str ~= '' then
        cmd = string.format("%s %s", cmd, header_str)
    end
    if oneapi.postdata then  -- POST
        cmd = string.format("%s -X POST --data '%s'", cmd, oneapi.postdata)
    end
    local query_str = {}
    for i, v in pairs(oneapi.query or {}) do
        table.insert(query_str, i .. '=' .. v)
    end
    query_str = table.concat(query_str, '&')
    if query_str ~= '' then
        cmd = string.format("%s '%s?%s'", cmd, oneapi.url, query_str)
    else
        cmd = string.format("%s '%s'", cmd, oneapi.url)
    end
    return cmd
end

local function worker(args)
    local args     = args or {}
    local id       = args.id or nil
    local popup    = args.popup or true  -- use core.popup_worker template
    args.timeout   = args.timeout or 3600 -- 1 hour
    args.font      = args.font or nil
    local curl     = args.curl or 'curl -f -s -m 7'
    local apis     = args.apis or {}  -- several api table
    -- one api table = {
    --      url='',  -- without query
    --      query=nil or {},  -- k=v, k=v
    --      header=nil or {},  -- h=v, h=v
    --      postdata=nil or '',  -- string, if nil then method=GET else POST
    --      get_info=function(self, data) end,  -- data table is the response
    -- }
    local setting  = args.setting or function(self) end  -- final setting

    local handles = {}
    for i, oneapi in pairs(apis) do
        local cmd = get_curl_cmd(curl, oneapi)
        util.print_info(string.format('API-usage cmd %d: %s', i, cmd), id)
        table.insert(handles, {cmd, oneapi.get_info})
    end

    -- update self.now.xxxx: notification_text, text, icon(optional)
    function args.update(self, i)
        -- request one by one, i starts from nil(1)
        i = i or 1
        if i > #handles then return end
        -- one handle = {cmd, callback(self, data)}
        local cmd, callback = handles[i][1], handles[i][2]
        util.async(cmd, function(stdout, stderr, reason, exit_code)
            local data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" then
                util.print_debug(string.format('API-usage cmd %d callback ...', i), id)
                callback(self, data)
            else
                util.print_error(string.format('API-usage %d: %s', i, err), id)
                util.print_info(' ==> stdout: ' .. stdout, id)
            end
            if i < #handles then
                args.update(self, i+1) -- next request
            else -- all requests done
                if setting then
                    setting(self)
                end
                if self.now.icon then
                    self.wicon:set_image(self.now.icon)
                end
                self.wtext:set_markup(self.now.text)
                if self.show and self.notification then
                    -- need to open new naughty.notify
                    self:show()
                end
            end
        end)
    end

    local usage
    if popup then
        usage = core.popup_worker(args)
    else
        usage = core.worker(args)
    end
    usage.id = id
    usage.timer:emit_signal('timeout')

    return usage
end

local apiusage = {
    new = worker, group = core.group, mt = {},
    get_curl_cmd = get_curl_cmd,
}

function apiusage.mt:__call(...)
    return apiusage.new(...)
end

return setmetatable(apiusage, apiusage.mt)
