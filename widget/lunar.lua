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
local core  = require("away.widget.core")

local os = { time = os.time, date = os.date }
local string = { format = string.format }

-- 调用寿星天文历库(寿星万年历)
-- https://github.com/yuangu/sxtwl_cpp
-- http://www.nongli.net/sxwnl/
local sxtwl = util.find_available_module({'sxtwl'})

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
local ymc = {"正", "二", "三", "四", "五", "六",
             "七", "八", "九", "十", "十一", "十二"}
local rmc = {"初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八",
             "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六",
             "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四",
             "廿五", "廿六", "廿七", "廿八", "廿九", "三十", "卅一"}

local function worker(args)
    local args   = args or {}
    args.timeout = args.timeout or 10800
    args.font    = args.font or nil

    local function get_next_jq(offset_max)
        local current = os.time()
        local res = {}
        for offset = 1, offset_max or 365 do
            local d = os.date('*t', current + 86400*offset)
            local day = sxtwl.fromSolar(d.year, d.month, d.day)
            local jq = day:getJieQi() + 1  -- 1-24, 256
            --print(offset, jqmc[jq], jq)
            if jqmc[jq] then
                table.insert(res, {offset, jqmc[jq]})
            end
        end
        return res
    end

    function args.update(lunar)
        if sxtwl then
            local d = os.date('*t')
            local day = sxtwl.fromSolar(d.year, d.month, d.day)
            local ygz = day:getYearGZ(true) -- true, 春节为界
            local mgz = day:getMonthGZ()
            local dgz  = day:getDayGZ()
            lunar.now = {
                y = d.year,
                m = d.month,
                d = d.day,
                month = ymc[day:getLunarMonth()] .. "月",
                day = rmc[day:getLunarMonth()],
                ly = Gan[ygz.tg+1] .. Zhi[ygz.dz+1] .. "年",
                lm = Gan[mgz.tg+1] .. Zhi[mgz.dz+1] .. "月",
                ld = Gan[dgz.tg+1] .. Zhi[dgz.dz+1] .. "日",
                jq = jqmc[day:getJieQi()+1], -- 节气不存在,则jqmc[256] -> nil
                next_jq = get_next_jq(),
            }
            if day:isLunarLeap() then
                lunar.now.month = "润" .. lunar.now.month
            end
            if args.setting then
                args.setting(lunar)
            else
                local now = lunar.now
                now.icon = nil
                now.text = now.month .. now.day
                now.notification_icon = nil
                local notitext = now.text
                if now.jq then
                    notitext = notitext .. ', ' .. now.jq
                end
                local jq_text = {}
                local jq_filter = {'冬至', '春分', '夏至', '秋分'}
                for i, jq in ipairs(now.next_jq) do
                    if i == 1 or util.table_hasitem(jq_filter, jq[2]) then
                        table.insert(jq_text, string.format('距%s%s天', jq[2], jq[1]))
                    end
                    if #jq_text == 3 then
                        break
                    end
                end
                now.notification_text =  string.format(
                    '<b>%s</b>\n公历: %s年%s月%s日\n%s\n%s',
                    notitext,
                    now.y, now.m, now.d,
                    now.ly .. now.lm .. now.ld,
                    table.concat(jq_text, '\n'))
            end
            if lunar.now.icon then
                lunar.wicon:set_image(lunar.now.icon)
            end
            lunar.wtext:set_markup(lunar.now.text)
        else
            lunar.wtext:set_markup('N/A')
        end
    end

    local lunar = core.popup_worker(args)
    lunar.timer:emit_signal('timeout')

    return lunar
end

return worker
