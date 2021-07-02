---------------------------------------------------------------------------
--
--  Weather base widget for away: away.widget.weather
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local spawn = require("awful.spawn")

local os = { date = os.date }
local string = {
    gsub = string.gsub, format = string.format,
    byte = string.byte }
local math = { floor = math.floor }
local table = { insert = table.insert, concat = table.concat }
local tonumber, tostring, pairs, type = tonumber, tostring, pairs, type

local base = {}

-- borken: http://openweather.weather.com.cn/Home/Help/icon.html
base.icon_table   = {
    ["晴"]               = '00',
    ["多云"]             = '01',
    ["阴"]               = '02',
    ["阵雨"]             = '03',
    ["雷阵雨"]           = '04',
    ["雷阵雨伴有冰雹"]   = '05',
    ["雨夹雪"]           = '06',
    ["小雨"]             = '07',
    ["中雨"]             = '08',
    ["大雨"]             = '09',
    ["暴雨"]             = '10',
    ["大暴雨"]           = '11',
    ["特大暴雨"]         = '12',
    ["阵雪"]             = '13',
    ["小雪"]             = '14',
    ["中雪"]             = '15',
    ["大雪"]             = '16',
    ["暴雪"]             = '17',
    ["雾"]               = '18',
    ["冻雨"]             = '19',
    ["沙尘暴"]           = '20',
    ["小到中雨"]         = '21',
    ["中到大雨"]         = '22',
    ["大到暴雨"]         = '23',
    ["暴雨到大暴雨"]     = '24',
    ["大暴雨到特大暴雨"] = '25',
    ["小到中雪"]         = '26',
    ["中到大雪"]         = '27',
    ["大到暴雪"]         = '28',
    ["浮尘"]             = '29',
    ["扬沙"]             = '30',
    ["强沙尘暴"]         = '31',
    ["霾"]               = '53',
    ["无"]               = 'undefined',
}

function base.encodeURI(s)
    local s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

-- http://www.pm25.com/news/91.html
-- AQI PM2.5 --> Air Pollution Level
function base.aqi2apl(aqi)
    aqi = tonumber(aqi)
    if aqi == nil then
        return 'AQI: N/A'
    end
    local aql={'优', '良',   '轻度污染', '中度污染', '重度污染','重度污染', '严重污染'}
    ----  aqi  0-50, 51-100, 101 - 150,  151 - 200,  201 - - 250 - - - 300, 301 - - 500
    local i=math.floor(aqi/50.16)+1
    if i <= 0 then
        return 'AQI: N/A'
    else
        if i > 7 then i = 7 end
        return "空气质量: " .. tostring(aqi) .. ', ' .. aql[i]
    end
end

function base.worker(args)
    local args     = args or {}
    local id       = args.id or nil
    local api      = args.api or ''
    local query    = args.query or {}
    local curl     = args.curl or 'curl -f -s -m 7'
    local icon_dir = args.icon_dir or util.curdir .. "widget/weather/"
    local get_info = args.get_info or function(weather, data) end
    local setting  = args.setting or nil -- function(weather) end
    args.timeout = args.timeout or 600 -- 10 min
    args.font    = args.font or nil

    local query_str = {}
    for i,v in pairs(query) do
        table.insert(query_str, i .. '=' .. v)
    end
    query_str = table.concat(query_str, '&')
    local cmd = string.format("%s '%s?%s'", curl, api, query_str)
    util.print_info('update cmd: ' .. cmd, id)

    function args.update(weather)
        local h = tonumber(os.date('%H'))
        if h < 18 and h >= 6 then
            weather.icon_dir = icon_dir .. 'day/'
        else
            weather.icon_dir = icon_dir .. 'night/'
        end
        spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            local data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" then
                get_info(weather, data)
            else
                util.print_error('Failed to get weather: ' .. err, id)
                util.print_info(' ==> stdout: ' .. stdout, id)
            end
            if weather.now.wtype then
                local icon = base.icon_table[weather.now.wtype]
                if icon then
                    weather.now.icon = weather.icon_dir .. icon .. ".png"
                else
                    weather.now.icon = weather.icon_dir .. "undefined.png"
                end
                weather.now.text = weather.now.wtype
                weather.now.notification_text = weather.now.forecast
            else
                weather.now.icon = weather.icon_dir .. "undefined.png"
                weather.now.text = 'N/A'
                weather.now.notification_text = "API/connection error or bad/not set city ID"
            end
            weather.now.notification_icon = weather.now.icon
            if setting then
                setting(weather)
            end
            if weather.now.icon then
               weather.wicon:set_image(weather.now.icon)
            end
            weather.wtext:set_markup(weather.now.text)
        end)
    end

    local weather = core.popup_worker(args)
    weather.timer:emit_signal('timeout')

    return weather
end

return base
