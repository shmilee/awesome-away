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

local os = { date = os.date }
local string = { format = string.format }

-- 调用寿星天文历库(寿星万年历)
-- https://github.com/yuangu/sxtwl_cpp
-- http://www.nongli.net/sxwnl/
local sxtwl = util.find_available_module({'sxtwl'})
if sxtwl then
    sxtwl = sxtwl.Lunar()
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
    local args   = args or {}
    args.timeout = args.timeout or 3600
    args.font    = args.font or nil

    function args.update(lunar)
        if sxtwl then
            local d = os.date('*t')
            local ld= sxtwl:getDayBySolar(d.year, d.month, d.day)
            lunar.now = {
                y = d.year,
                m = d.month,
                d = d.day,
                month = ymc[ld.Lmc+1] .. "月",
                day = rmc[ld.Ldi+1],
                ly = Gan[ld.Lyear2.tg+1] .. Zhi[ld.Lyear2.dz+1] .. "年",
                lm = Gan[ld.Lmonth2.tg+1] .. Zhi[ld.Lmonth2.dz+1] .. "月",
                ld = Gan[ld.Lday2.tg+1] .. Zhi[ld.Lday2.dz+1] .. "日",
                jq = jqmc[ld.qk+1], -- 节气，不存在则为jqmc[0] -> nil
                cur_dz = ld.cur_dz,
                cur_xz = ld.cur_xz,
                cur_lq = ld.cur_lq,
            }
            if ld.Lleap then
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
                now.notification_text =  string.format(
                    '<b>%s</b>\n公历: %s年%s月%s日\n%s\n距冬至%s天\n距夏至%s天\n距立秋%s天',
                    notitext,
                    now.y, now.m, now.d,
                    now.ly .. now.lm .. now.ld,
                    -now.cur_dz, -now.cur_xz, -now.cur_lq)
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
