---------------------------------------------------------------------------
--
--  tianqi weather widget for away: away.widget.weather.tianqi
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local base = require("away.widget.weather.base")

local os = { date = os.date, time = os.time }
local string = { gsub = string.gsub, format = string.format }

-- tianqi weather: fetch info from https://www.tianqiapi.com/
-- ref: https://www.jianshu.com/p/e3e04cf3fc0f#comment-34740340
local function get_tianqiweather(args)
    local args = args or {}
    args.id    = args.id or 'tianqi'
    args.api   = args.api or 'https://www.tianqiapi.com/api/'
    args.query = args.query or { version='v1' }
    --args.curl  = args.curl or 'curl -f -s -m 1.7'

    -- set weather.now {city, wtype, wendu, aql, forecast, etc} for setting
    args.get_info  = args.get_info or function(weather, data)
        --util.print_debug('get weather info of ' .. data['city'], args.id)     
        if data['data'] then
            weather.now.city = data['city']
            weather.now.wendu = data['data'][1]['tem']
            weather.now.aql = base.aqi2apl(data['data'][1]['air'])
            local wtype = data['data'][1]['wea']
            --util.print_debug('get weather type ' .. wtype, args.id)
            if wtype:match("转(.*)") then
                -- current wea from data['data'][1]['hours']
                local lt_wtype, lt_window = nil, {}
                for i = 1, 3 do
                    lt_window[i] = os.date('%d日%H时', os.time()+(i-1)*60*60)
                end
                for i = 1, #data['data'][1]['hours'] do
                    for j = 1, #lt_window do
                        if data['data'][1]['hours'][i]['day'] == lt_window[j] then
                            lt_wtype = data['data'][1]['hours'][i]['wea']
                            --util.print_debug('get weather type ' .. lt_wtype
                            --    .. ' at ' .. lt_window[j], args.id)
                            break
                        end
                    end
                    if lt_wtype then
                        break
                    end
                end
                if lt_wtype then
                    wtype = lt_wtype
                else
                    wtype = wtype:match("转(.*)")
                    --util.print_debug('change weather type ' .. wtype, args.id)
                end
            end
            weather.now.wtype = wtype
            -- forecast
            local data, now_forecast = data['data'], ''
             for i = 1, #data do
                local day  = data[i]['day']
                local tmin = data[i]['tem2']
                local tmax = data[i]['tem1']
                local desc = data[i]['wea']
                local wind = data[i]['win_speed']
                wind = string.gsub(wind, '<', '&lt;')
                wind = string.gsub(wind, '>', '&gt;')
                now_forecast = now_forecast .. string.format(
                    "<b>%s</b>:  %s,  %s - %s, %s",
                    day, desc, tmin, tmax, wind)
                if i < #data then
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

return get_tianqiweather
