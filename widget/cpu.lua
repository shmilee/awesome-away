---------------------------------------------------------------------------
--
--  CPU widget for away: away.widget.cpu
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local ipairs = ipairs
local io = { open = io.open }
local math = { floor = math.floor }
local table = { insert = table.insert }
local string = {
    sub = string.sub, gmatch = string.gmatch, format = string.format }

-- CPU usage
local function worker(args)
    local args  = args or {}
    local theme = args.theme or {}
    args.timeout = args.timeout or 2
    args.font    = args.font or nil
    local setting = args.setting or function(cpu)
        if cpu.now.usage > 50 then
            cpu.now.text = util.markup_span(cpu.now.usage .. "% ", theme.cpu_high_color or "#e33a6e")
        else
            cpu.now.text = cpu.now.usage .. "% "
        end
        cpu.wtext:set_markup(cpu.now.text)
        local notification = ''
        for j = 2, #cpu.usage do
            notification = notification .. string.format('\ncpu%d: %d%%', j-2, cpu.usage[j])
        end
        cpu.now.notification_text = string.format("<b>%s%%</b>:%s", cpu.usage[1], notification)
    end

    -- get now: {uasge}
    -- ref: https://github.com/vicious-widgets/vicious/blob/master/widgets/cpu_linux.lua
    args.update = args.update or function (cpu)
        local cpu_lines = {}
        -- Get CPU stats
        local f = io.open("/proc/stat")
        for line in f:lines() do
            if string.sub(line, 1, 3) ~= "cpu" then break end
            cpu_lines[#cpu_lines+1] = {}
            for i in string.gmatch(line, "[%s]+([^%s]+)") do
                table.insert(cpu_lines[#cpu_lines], i)
            end
        end
        f:close()
        cpu.usage  = {}
        -- Ensure tables are initialized correctly
        for i = #cpu.total + 1, #cpu_lines do
            cpu.total[i]  = 0
            cpu.active[i] = 0
            cpu.usage[i]  = 0
        end
        for i, v in ipairs(cpu_lines) do
            -- Calculate totals
            local total_new = 0
            for j = 1, #v do
                total_new = total_new + v[j]
            end
            local active_new = total_new - (v[4] + v[5])
            -- Calculate percentage
            local diff_total  = total_new - cpu.total[i]
            local diff_active = active_new - cpu.active[i]
            if diff_total == 0 then diff_total = 1E-6 end
            cpu.usage[i]      = math.floor((diff_active / diff_total) * 100)
            -- Store totals
            cpu.total[i]   = total_new
            cpu.active[i]  = active_new
        end

        cpu.now.usage = cpu.usage[1]
        setting(cpu)
    end

    local cpu = core.popup_worker(args)
    cpu.total = {}
    cpu.active = {}
    if theme.cpu then
        cpu.wicon:set_image(theme.cpu)
    end
    cpu.now.notification_icon = args.notification_icon or theme.cpu

    cpu.timer:emit_signal('timeout')
    return cpu
end

return worker
