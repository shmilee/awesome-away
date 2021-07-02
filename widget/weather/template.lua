---------------------------------------------------------------------------
--
--  XXX weather widget for away: away.widget.weather.XXX
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

-- XXX weather: fetch info from http://XXX
local function get_XXXweather(args)
    local args = args or {}
    args.id    = args.id or 'XXX'
    args.api   = args.api or 'http://'
    args.query = args.query or { cityid=101210101 }
    args.curl  = args.curl or 'curl -f -s -m 7'

    -- set weather.now {wtype, forecast, etc} for setting
    args.get_info  = args.get_info or function(weather, data)
        weather.now.wtype = nil
        weather.now.forecast = nil
    end

    -- edit weather.now {icon, text, notification_icon, notification_text}
    args.setting = args.setting or function(weather)
        if weather.now.wtype then
            weather.now.notification_text = string.format('')
        end
    end

    return base.worker(args)
end

-- TODO multi API:
-- 1. 国家气象局 https://www.jianshu.com/p/e3e04cf3fc0f
--    http://www.weather.com.cn/data/cityinfo/101190408.html
--    http://mobile.weather.com.cn/data/forecast/101010100.html?_=1381891660081
-- 2. 中国气象台 www.nmc.cn/f/rest/
--    https://github.com/sonichy/WEATHER_DDE_DOCK/issues/13
--    https://github.com/ZhijianZhang/yiliang-note/blob/master/博客/中央天气网.md

return get_XXXweather
