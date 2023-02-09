---------------------------------------------------------------------------
--
--  Windows Spotlight Wallpaper module for away: away.wallpaper.spotlight
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local core = require("away.wallpaper.core")
local gfs  = require("gears.filesystem")

local string = { gsub = string.gsub }

-- Spotlight WallPaper: fetch Windows spotlight's images with meta data
-- ref: https://github.com/ORelio/Spotlight-Downloader
local function get_spotlightwallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or 'Spotlight'
    args.api   = args.api or "https://arc.msn.com/v3/Delivery/Placement"
    args.query = args.query or {
        pid=338387, -- pid=279978, 209562, 209567, 279978
        fmt='json', ua='WindowsShellClient', cdm=1,
        pl='zh-CN', lc='zh-CN', ctry='CN',
    }
    args.choices  = args.choices or { 1, 2, 3, 4 }
    args.curl     = args.curl or 'curl -f -s -m 10 --header "User-Agent: WindowsShellClient"'
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-spotlight"
    args.timeout_info = args.timeout_info or 1200
    --args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    --args.force_hd = args.force_hd or true
    args.get_url  = args.get_url or function(wp, data, choice)
        if data['batchrsp']['items'][choice] then
            local item, pos, err = util.json.decode(data['batchrsp']['items'][choice]['item'], 1, nil)
            --local inspect = require("away.third_party.inspect")
            --util.print_info('Spotlight check data: ' inspect(item))
            return item['ad']['image_fullscreen_001_landscape']['u'] -- drop 002 ...
        else
            return nil
        end
    end
    args.get_name = args.get_name or function(wp, data, choice)
        if wp.url[choice] then
            return string.gsub(wp.url[choice], "(.*/)(.*)%?.*=(.*)", "%2_%3.jpg")
        else
            return nil
        end
    end

    return core.get_remotewallpaper(screen, args)
end

return get_spotlightwallpaper
