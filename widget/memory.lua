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

-- Memory infos, aligned to htop, neofetch, free -h
local function worker(args)
    local args   = args or {}
    local theme = args.theme or {}
    args.timeout = args.timeout or 2
    local setting  = args.setting or function(mem)
        -- setting, mem.now.text
        if mem.now.used / 1024 > 1 then
            mem.now.text = util.markup_span(string.format("%.2fG(%.0f%%)", mem.now.used/1024, mem.now.perc), theme.mem_high_color or "#e0da37")
        else
            mem.now.text = string.format("%sM(%.0f%%)", mem.now.used, mem.now.perc)
        end
        mem.wtext:set_markup(mem.now.text)
    end

    -- get now: {total, free, buf, cache, swap, swapf, share, srec,
    --           used, swapused, perc} in MB
    args.update = args.update or function (mem)
        spawn.easy_async('cat /proc/meminfo', function(stdout, stderr, reason, exit_code)
            if exit_code ~= 0 then
                mem.now.used = -1
                mem.now.perc = -1
                setting(mem)
                return
            end
            for line in string.gmatch(stdout, "[^\r\n]+") do
                -- ref: https://github.com/lcpz/lain/issues/271
                local k, v = string.match(line, "([%a]+):[%s]+([%d]+).+")
                if     k == "MemTotal"     then mem.now.total = math.floor(v / 1024 + 0.5)
                elseif k == "MemFree"      then mem.now.free  = math.floor(v / 1024 + 0.5)
                elseif k == "Buffers"      then mem.now.buf   = math.floor(v / 1024 + 0.5)
                elseif k == "Cached"       then mem.now.cache = math.floor(v / 1024 + 0.5)
                elseif k == "SwapTotal"    then mem.now.swap  = math.floor(v / 1024 + 0.5)
                elseif k == "SwapFree"     then mem.now.swapf = math.floor(v / 1024 + 0.5)
                --elseif k == "Shmem"        then mem.now.share = math.floor(v / 1024 + 0.5)
                elseif k == "SReclaimable" then mem.now.srec  = math.floor(v / 1024 + 0.5)
                end
            end
            mem.now.used = mem.now.total --+ mem.now.share
                - mem.now.free - mem.now.buf - mem.now.cache - mem.now.srec
            mem.now.swapused = mem.now.swap - mem.now.swapf
            mem.now.perc = math.floor(mem.now.used / mem.now.total * 100)
            setting(mem)
        end)
    end

    local mem = core.worker(args)
    if theme.mem then
        mem.wicon:set_image(theme.mem)
    end
    mem.timer:emit_signal('timeout')

    return mem
end

return worker
