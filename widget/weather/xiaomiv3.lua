---------------------------------------------------------------------------
--
--  xiaomiv3 weather widget for away: away.widget.weather.xiaomiv3
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
local pairs, tonumber = pairs, tonumber

local icon_table = {}
for k, v in pairs(base.icon_table) do
    icon_table[tonumber(v) or v] = k
end
icon_table[32] = "飑"
icon_table[33] = "龙卷风"
icon_table[34] = "若高吹雪"
icon_table[35] = "轻雾"
icon_table[99] = "无"

-- xiaomiv3weather: fetch info from https://weatherapi.market.xiaomi.com
-- ref: https://github.com/jokermonn/-Api/blob/master/XiaomiWeather.md
local function get_xiaomiv3weather(args)
    local args = args or {}
    args.id    = args.id or 'xiaomiv3'
    args.city  = args.city or '杭州'
    args.api   = args.api or 'https://weatherapi.market.xiaomi.com/wtr-v3/weather/all'
    args.query = args.query or {
        latitude = 0,
        longitude = 0,
        locationKey = 'weathercn:101210101',
        appKey = 'weather20151024',
        sign = 'zUFJoAR2ZVrDy1vF3D07',
        isGlobal = 'false',
        locale = 'zh_cn',
        days = 6,
    }
    --args.curl  = args.curl or 'curl -f -s -m 7'

    -- set weather.now {wtype, wendu, aql, forecast, etc} for setting
    args.get_info  = args.get_info or function(weather, data)
        --util.print_debug('get weather info of ' .. args.city, args.id)
        if data['current'] then
            --util.print_debug('weather type: ' .. type(data['current']['weather']), args.id)
            local wtype = tonumber(data['current']['weather'])
            if icon_table[wtype] then
                wtype = icon_table[wtype]
            else
                wtype = icon_table[99]
            end
            weather.now.wtype = wtype
            weather.now.wendu = data['current']['temperature']['value'] .. '℃'
            weather.now.aql = base.aqi2apl(data['aqi']['aqi'])
        end
        if data['forecastDaily'] then
            -- pubTime ~~ os.date('%FT%H:00:00+08:00')
            local forecast, now_forecast = data['forecastDaily'], ''
            for i = 1, 6 do
                local day  = os.date('%m月%d日', os.time()+60*60*24*(i-1))
                local temp = forecast['temperature']['value'][i]['from'] .. '℃ / ' .. forecast['temperature']['value'][i]['to'] ..'℃'
                local desc = tonumber(forecast['weather']['value'][i]['from'])
                local desc_to = tonumber(forecast['weather']['value'][i]['to'])
                if desc ~= desc_to then
                    desc = icon_table[desc] .. '转' .. icon_table[desc_to]
                else
                    desc = icon_table[desc]
                end
                local wind = forecast['wind']['speed']['value'][i]['from']
                local wind_to = forecast['wind']['speed']['value'][i]['to']
                if wind ~= wind_to then
                    wind = wind_to .. ' - ' .. wind .. ' ' .. forecast['wind']['speed']['unit']
                else
                    wind = wind .. ' ' .. forecast['wind']['speed']['unit']
                end
                now_forecast = now_forecast .. string.format(
                    "<b>%s</b>:  %s,  %s, 风速 %s ",
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
                args.city, weather.now.wtype, weather.now.wendu, weather.now.aql, weather.now.forecast)
        end
    end

    return base.worker(args)
end

return get_xiaomiv3weather
