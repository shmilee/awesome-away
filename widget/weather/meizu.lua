---------------------------------------------------------------------------
--
--  meizu weather widget for away: away.widget.weather.meizu
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local base = require("away.widget.weather.base")

local string = { gsub = string.gsub, format = string.format }

-- meizuweather: fetch info from http://aider.meizu.com/
-- ref: https://github.com/jokermonn/-Api/blob/master/MXWeather.md
local function get_meizuweather(args)
    local args = args or {}
    args.id    = args.id or 'meizu'
    args.api   = args.api or 'http://aider.meizu.com/app/weather/listWeather'
    args.query = args.query or { cityIds=101210101 }
    --args.curl  = args.curl or 'curl -f -s -m 7'

    -- set weather.now {city, wtype, wendu, aql, forecast, etc} for setting
    args.get_info  = args.get_info or function(weather, data)
        if data['code']  == '200' and data['value'][1] then
            local data = data['value'][1]
            --util.print_debug('get weather info of ' .. data['city'], args.id)        
            weather.now.city = data['city']
            local wtype = data['realtime']['weather']
            if wtype:match("转(.*)") then
                wtype = wtype:match("转(.*)")
            end
            weather.now.wtype = wtype
            weather.now.wendu = data['realtime']['temp']
            weather.now.aql = base.aqi2apl(data['pm25']['aqi'])
            local now_forecast = ''
            for i = 1, #data['weathers'] do
                local day  = data['weathers'][i]['date']
                local week = data['weathers'][i]['week']
                local tmin = data['weathers'][i]['temp_night_c']
                local tmax = data['weathers'][i]['temp_day_c']
                local desc = data['weathers'][i]['weather']
                now_forecast = now_forecast .. string.format(
                    "<b>%s %s</b>:  %s,  %s℃ - %s℃",
                    day, week, desc, tmin, tmax)
                if i < #data['weathers'] then
                    now_forecast = now_forecast .. "\n"
                end
            end
            weather.now.forecast = now_forecast
        end
    end

    -- edit weather.now {icon, text, notification_icon, notification_text}
    args.setting = args.setting or function(weather)
        if weather.now.wtype then
            weather.now.notification_text = string.format(
                "<b>%s %s</b>\n温度: %s\n%s\n%s",
                weather.now.city, weather.now.wtype, weather.now.wendu, weather.now.aql, weather.now.forecast)
        end
    end

    return base.worker(args)
end

return get_meizuweather
