---------------------------------------------------------------------------
--
--  Nationalgeographic Wallpaper module for away: away.wallpaper.nationalgeographic
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

-- Nationalgeographic WallPaper: fetch Nationalgeographic's images with meta data
local function get_nationalgeographicwallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or 'Nationalgeographic'
    --date api "https://www.nationalgeographic.com/photography/photo-of-the-day/_jcr_content/.gallery.2017-08.json"
    args.api   = args.api or "https://www.nationalgeographic.com/photography/photo-of-the-day/_jcr_content/.gallery.json"
    --args.query = args.query or {}
    args.choices  = args.choices or util.simple_range(1, 10, 1)
    --args.curl     = args.curl or 'curl -f -s -m 10'
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-nationalgeographic"
    --args.timeout_info = args.timeout_info or 86400
    --args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    --args.force_hd = args.force_hd or true
    args.get_url  = args.get_url or function(wp, data, choice)
        if data['items'][choice] then
            if wp.force_hd then
                return data['items'][choice]['sizes']['2048']
            else
                return data['items'][choice]['sizes']['1024']
            end
        else
            return nil
        end
    end
    args.get_name = args.get_name or function(wp, data, choice)
        if data['items'][choice] then
            local name = data['items'][choice]['publishDate'] .. '_' .. data['items'][choice]['title']
            name = string.gsub(name, ",", "")
            name = string.gsub(name, " ", "-")
            if wp.force_hd then
                return name .. '_2048.jpg'
            else
                return name .. '_1024.jpg'
            end
        else
            return nil
        end
    end

    return core.get_remotewallpaper(screen, args)
end

return get_nationalgeographicwallpaper
