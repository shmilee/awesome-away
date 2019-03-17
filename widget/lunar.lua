---------------------------------------------------------------------------
--
--  Lunar widget for away: away.widget.lunar
--  农历(阴阳历) ~= 阴历
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local gears = require("gears")
local wibox = require("wibox")

local os = { date = os.date }

-- Lunar widget
local lunar = {}

-- 调用寿星天文历库(寿星万年历)
-- https://github.com/yuangu/sxtwl_cpp
-- http://www.nongli.net/sxwnl/
local sxtwl = util.find_available_module({'sxtwl'})
if sxtwl then
    lunar.lunar = sxtwl.Lunar()
end

-- 结果索引
local Gan = {"甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"}
local Zhi = {"子", "丑", "寅", "卯", "辰", "巳",
             "午", "未", "申", "酉", "戌", "亥"}
local ShX = {"鼠", "牛", "虎", "兔", "龙", "蛇",
             "马", "羊", "猴", "鸡", "狗", "猪"}
local numCn = {"零", "一", "二", "三", "四", "五",
               "六", "七", "八", "九", "十"}
local jqmc = {"冬至", "小寒", "大寒",
              "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
              "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
              "立秋", "处暑","白露", "秋分", "寒露", "霜降",
              "立冬", "小雪", "大雪"}
local ymc = {"十一", "十二", "正", "二", "三", "四",
             "五", "六", "七", "八", "九", "十"}
local rmc = {"初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八",
             "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六",
             "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四",
             "廿五", "廿六", "廿七", "廿八", "廿九", "三十", "卅一"}

local function worker(args)
    local args     = args or {}
    local timeout  = args.timeout or 3600
    local settings = args.settings or function(lunar) end

    lunar.widget = wibox.widget.textbox('')
    function lunar.update()
        if lunar.lunar then
            local d = os.date('*t')
            local ld= lunar.lunar:getDayBySolar(d.year, d.month, d.day)
            lunar.now = {
                year = Gan[ld.Lyear2.tg+1] .. Zhi[ld.Lyear2.dz+1] .. "年",
                month = ymc[ld.Lmc+1] .. "月",
                day = rmc[ld.Ldi+1] .. "日",
                jq = jqmc[ld.qk+1] or '', -- 节气，不存在则为jqmc[0] -> ''
            }
            if ld.Lleap then
                lunar_now.month = "润" .. lunar_now.month
            end
            settings(lunar)
        else
            lunar.widget:set_markup('N/A')
        end
    end

    lunar.timer = gears.timer({ timeout=timeout, autostart=true, callback=lunar.update })
    lunar.timer:emit_signal('timeout')

    return lunar.widget
end

return worker
