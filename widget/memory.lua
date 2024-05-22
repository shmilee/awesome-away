---------------------------------------------------------------------------
--
--  Memory widget for away: away.widget.memory
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local core  = require("away.widget.core")
local spawn = require("awful.spawn")

local math   = { floor  = math.floor }
local string = { format = string.format, match = string.match, gmatch = string.gmatch }
local ipairs, tonumber = ipairs, tonumber

-- Memory infos, aligned to htop, neofetch, or top
-- Ref:
-- 1. neofetch
-- 2. https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/proc.rst?id=HEAD#n1052
--    Cached includes tmpfs & shmem.
-- Others: https://www.baeldung.com/linux/proc-meminfo
--         https://github.com/lcpz/lain/issues/271
local function worker(args)
    local args   = args or {}
    local theme  = args.theme or {}
    args.timeout = args.timeout or 2
    args.font    = args.font or nil
    local calculate = args.calculate or function(mem)
        local I = mem.now.info
        if I.MemTotal then
            mem.now.used = I.MemTotal - I.MemFree - I.Buffers - I.Cached+I.Shmem - I.SReclaimable
            mem.now.perc = mem.now.used / I.MemTotal * 100
        else
            mem.now.perc, mem.now.used = 0, 0
        end
    end
    local noti_keys = args.noti_keys or {
            'Used',  -- for mem.now.used
            'MemTotal', 'MemFree', 'Buffers', 'Cached', 'Shmem', 'SReclaimable',
            'MemAvailable', -- 'PageTables',
            --'SwapTotal', 'SwapFree', 'SwapCached',
        }
    local setting  = args.setting or function(mem)
        -- setting, mem.now.text
        if mem.now.perc > 40 then
            mem.now.text = util.markup_span(string.format("%.0f%%", mem.now.perc), theme.mem_high_color or "#e0da37")
        else
            mem.now.text = string.format("%.0f%%", mem.now.perc)
        end
        local noti, line = {}, nil
        for i, k in ipairs(noti_keys) do
            local v = mem.now.info[k]  -- kB
            if k == 'Used' then
                k = string.format('%.1f%% %s', mem.now.perc, k)
                v = mem.now.used
            end
            if v ~=nil then
                if v < 1024 then
                    line = string.format('%12s: %.0fK', k, v)
                elseif v < 1024*1024 then
                    line = string.format('%12s: %.1fM', k, v/1024)
                else
                    line = string.format('%12s: %.3fG', k, v/1024/1024)
                end
                table.insert(noti, line)
            end
        end
        mem.now.notification_text = table.concat(noti, '\n')
    end

    -- get now.info: {MemTotal, MemFree, Buffers, Cached, Shmem, SReclaimable, etc.} kB
    args.update = args.update or function (mem)
        spawn.easy_async('cat /proc/meminfo', function(stdout, stderr, reason, exit_code)
            mem.now.info = {}
            if exit_code == 0 then
                for line in string.gmatch(stdout, "[^\r\n]+") do
                    local k, v = string.match(line, "([%a%d()_]+):[%s]+([%d]+).*")
                    mem.now.info[k] = tonumber(v)
                end
            end
            calculate(mem)
            setting(mem)
            mem.wtext:set_markup(mem.now.text)
        end)
    end

    local mem = core.popup_worker(args)
    if theme.mem then
        mem.wicon:set_image(theme.mem)
    end
    mem.now.notification_icon = args.notification_icon or theme.mem
    mem.timer:emit_signal('timeout')

    return mem
end

return worker
