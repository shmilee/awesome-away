---------------------------------------------------------------------------
--
--  XXX Wallpaper module for away: away.wallpaper.XXX
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

-- XXX WallPaper: fetch XXX's images with meta data
local function get_XXXwallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or 'XXX'
    args.api   = args.api or ""
    args.query = args.query or {
    }
    args.choices  = args.choices or util.simple_range(1, 10, 1)
    args.curl     = args.curl or 'curl -f -s -m 10'
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-XXX"
    args.timeout_info = args.timeout_info or 86400
    args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    args.force_hd = args.force_hd or true
    args.get_url  = args.get_url or function(wp, data, choice)
        return
    end
    args.get_name = args.get_name or function(wp, data, choice)
        return
    end

    return core.get_remotewallpaper(screen, args)
end

return get_XXXwallpaper
