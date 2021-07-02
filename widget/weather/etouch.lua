---------------------------------------------------------------------------
--
--  etouch weather widget for away: away.widget.weather.etouch
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local base = require("away.widget.weather.base")
local gfs  = require("gears.filesystem")

local string = { gsub = string.gsub, format = string.format }

-- etouchweather: fetch info from http://wthrcdn.etouch.cn
local function get_etouchweather(args)
    local args = args or {}
    args.id    = args.id or 'etouch'
    args.api   = args.api or 'http://wthrcdn.etouch.cn/weather_mini'
    args.query = args.query or { citykey=101210101 }
    args.curl  = args.curl or 'curl -f -s -m 7 --compressed'

    -- set weather.now {desc, city, wtype, wendu, forecast}
    args.get_info  = args.get_info or function(weather, data)
        if data["desc"] == 'OK' then
            weather.now.desc = true
            weather.now.city = data['data']['city']
            local wtype = data['data']['forecast'][1]['type']
            weather.now.wtype = wtype
            weather.now.wendu = data['data']['wendu'] .. '℃'
            local forecast, now_forecast = data['data']['forecast'], ''
            for i = 1, #forecast do
                local day  = forecast[i]['date']
                local tmin = string.gsub(forecast[i]['low'], '低温', '')
                local tmax = string.gsub(forecast[i]['high'], '高温', '')
                local desc = forecast[i]['type']
                local wind = string.gsub(forecast[i]['fengli'], '.*DATA%[(.*)%]%].*', '%1')
                wind = string.gsub(wind, '<', '&lt;')
                wind = string.gsub(wind, '>', '&gt;')
                util.print_debug(forecast[i]['fengli'] .. '-->' .. wind, args.id)
                now_forecast = now_forecast .. string.format(
                    "<b>%s</b>:  %s,  %s - %s,  %s",
                    day, desc, tmin, tmax, wind)
                if i < #forecast then
                    now_forecast = now_forecast .. "\n"
                end
            end
            weather.now.forecast = now_forecast
        end
    end

    -- edit weather.now {icon, text, notification_icon, notification_text}
    args.setting = args.setting or function(weather)
        if weather.now.desc then
            weather.now.notification_text = string.format(
                "<b>%s %s</b>\n温度: %s\n%s",
                 weather.now.city, weather.now.wtype, weather.now.wendu, weather.now.forecast)
        end
    end

    return base.worker(args)
end

return get_etouchweather
