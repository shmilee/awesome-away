---------------------------------------------------------------------------
--
--  xiaomiv2 weather widget for away: away.widget.weather.xiaomiv2
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

-- xiaomiv2weather: fetch info from https://weatherapi.market.xiaomi.com
local function get_xiaomiv2weather(args)
    local args = args or {}
    args.id    = args.id or 'xiaomiv2'
    args.api   = args.api or 'https://weatherapi.market.xiaomi.com/wtr-v2/weather'
    args.query = args.query or { cityId=101210101 }
    --args.curl  = args.curl or 'curl -f -s -m 7'

    -- set weather.now {city, wtype, wendu, aql, forecast, etc} for setting
    args.get_info  = args.get_info or function(weather, data)
        if data['realtime'] then
            weather.now.city = data['aqi']['city']
            local wtype = data['realtime']['weather']
            if wtype:match("转(.*)") then
                wtype = wtype:match("转(.*)")
            end
            weather.now.wtype = wtype
            weather.now.wendu = data['realtime']['temp'] .. '℃'
            weather.now.aql = base.aqi2apl(data['aqi']['aqi'])
        end
        if data['forecast'] then
            -- forecast.date_y == os.date('%Y年%m月%d日')
            local now_forecast = ''
            for i = 1, 6 do
                local day  = os.date('%m月%d日', os.time()+60*60*24*(i-1))
                local temp = data['forecast']['temp'.. i]
                local desc = data['forecast']['weather'.. i]
                local wind = data['forecast']['wind'.. i]
                now_forecast = now_forecast .. string.format(
                    "<b>%s</b>:  %s,  %s,  %s ",
                    day, desc, temp, wind)
                if i < 6 then
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

return get_xiaomiv2weather
