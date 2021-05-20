---------------------------------------------------------------------------
--
--  Bili Video Wallpaper module for away: away.wallpaper.bilivideo
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local core = require("away.wallpaper.core")
local spawn = require("awful.spawn")

local string = { format = string.format }

-- Bili WallPaper: fetch Bilibili's video with meta data
local function get_bilivideowallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or 'Bili'
    local id   = core.assemble_id_with_screen(screen, args.id)
    local choices = args.choices or {
        'dash-flv', 'dash-flv720', 'dash-flv480', 'dash-flv360',
        'flv', 'flv720', 'flv480', 'flv360'}
    args.get_realpath = args.get_realpath or function(url, realsetting)
        local cmd = string.format("you-get --json '%s'", url)
        util.print_debug('get bilivideo info cmd: ' .. cmd, id)
        spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            local data, pos, err
            data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" and data['streams'] then
                local path = nil
                for _, c in pairs(choices) do
                    if data['streams'][c] and data['streams'][c]['src'] then
                        local src1 = data['streams'][c]['src'][1]
                        if type(src1) == 'string' then
                            path = src1
                            break
                        elseif type(src1) == 'table' then
                            path = src1[1]
                            break
                        end
                    end
                end
                if path then
                    util.print_debug('Get real url: ' .. path, id)
                    realsetting(path)
                end
            else
                util.print_info('Faild to fetch json! ' .. stderr, id)
            end
        end)
    end

    return core.get_videowallpaper(screen, args)
end

return get_bilivideowallpaper
