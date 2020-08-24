---------------------------------------------------------------------------
--
--  Bing Wallpaper module for away: away.wallpaper.bing
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local core = require("away.wallpaper.core")
local gfs  = require("gears.filesystem")

local string = { gsub = string.gsub }

-- BingWallPaper: fetch Bing's images with meta data
local function get_bingwallpaper(screen, args)
    local args    = args or {}
    args.id       = args.id or 'Bing'
    args.api      = args.api or 'https://www.bing.com/HPImageArchive.aspx'
    -- idx: TOMORROW=-1, TODAY=0, YESTERDAY=1, ... 7
    args.query    = args.query or { format='js', idx=-1, n=8 }
    args.choices  = args.choices or { 1, 2, 3, 4, 5, 6, 7, 8 }
    --args.curl   = args.curl or 'curl -f -s -m 10'
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-bing"
    --args.timeout_info = args.timeout_info or 86400
    --args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    args.force_hd = args.force_hd or true
    args.get_url  = args.get_url or function(wp, data, choice)
        local suffix = "_1920x1080.jpg"
        if wp.force_hd == "UHD" then
            suffix = "_UHD.jpg"
        end
        if not wp.force_hd and wp.screen.geometry.height < 800 then
            suffix = "_1366x768.jpg"
        end
        if data['images'][choice] then
            return 'https://www.bing.com' .. data['images'][choice]['urlbase'] .. suffix
        else
            return nil
        end
    end
    args.get_name = args.get_name or function(wp, data, choice)
        if data['images'][choice] then
            local name = string.gsub(wp.url[choice], "th%?id%=OHR%.", "")
            return data['images'][choice]['enddate'] .. string.gsub(name, "(.*/)(.*)", "_%2")
        else
            return nil
        end
    end

    return core.get_remotewallpaper(screen, args)
end

return get_bingwallpaper
