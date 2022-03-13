---------------------------------------------------------------------------
--
--  Wallpaper module for away: away.wallpaper.core
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util  = require("away.util")
local gears = require("gears")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local os     = { remove = os.remove }
local string = {
    format = string.format,
    match = string.match, gmatch = string.gmatch,
}
local table  = { concat = table.concat, insert = table.insert }
local next, type, pairs, tostring = next, type, pairs, tostring

local core = {}

function core.assemble_id_with_screen(screen, id)
    if type(screen) == 'screen' then
        return string.format("Screen %s %s", screen.index, id)
    else
        return string.format("Screen %s %s", screen, id)
    end
end

function core.delete_timer(wallpaper, key)
    if wallpaper[key] then
        util.print_info('Delete ' .. key .. ' of ' .. wallpaper.id)
        wallpaper[key]:stop()
        wallpaper[key] = nil
    end
end

function core.print_using(wallpaper)
    local wall = wallpaper.path and wallpaper.path[wallpaper.using]
    if wall then
        util.print_info('Using Wallpaper ' .. wall, wallpaper.id)
        naughty.notify({ title = 'Using Wallpaper ' .. wall })
    else
        util.print_info('Using Wallpaper nil', wallpaper.id)
        naughty.notify({ title = 'Using Wallpaper nil' })
    end
end

-- RemoteWallPaper: fetch remote images with meta data
function core.get_remotewallpaper(screen, args)
    local rwallpaper    = { screen=screen, url=nil, path=nil, using=nil }
    local args          = args or {}
    local id            = core.assemble_id_with_screen(screen, args.id or nil)
    local api           = args.api or ''
    local query         = args.query or {}
    local choices       = args.choices or {}
    local curl          = args.curl or 'curl -f -s -m 10'
    local cachedir      = args.cachedir or '/tmp'
    local timeout_info  = args.timeout_info or 86400
    local async_update  = args.async_update or false
    local setting       = args.setting or function(rwp)
        gears.wallpaper.maximized(rwp.path[rwp.using], rwp.screen, false)
    end
    rwallpaper.id = id
    rwallpaper.force_hd = args.force_hd or false
    rwallpaper.get_url  = args.get_url or function(rwp, data, choice)
        return ''
    end
    rwallpaper.get_name = args.get_name or function(rwp, data, choice)
        return ''
    end

    -- check cachedir
    if not gears.filesystem.is_dir(cachedir) then
        local ok, err = gears.filesystem.make_directories(cachedir)
        if not ok then
            util.print_error('Faild to make cachedir ' .. cachedir, id)
            return nil
        end
    end

    function rwallpaper.update_info()
        local query_str = {}
        for i,v in pairs(query) do
            table.insert(query_str, i .. '=' .. v)
        end
        query_str = table.concat(query_str, '&')
        local cmd = string.format("%s '%s?%s'", curl, api, query_str)
        util.print_debug('update_info cmd: ' .. cmd, id)
        spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            rwallpaper.url = {}
            rwallpaper.path = {}
            local data, pos, err
            data, pos, err = util.json.decode(stdout, 1, nil)
            if not err and type(data) == "table" then
                for _, c in pairs(choices) do
                    rwallpaper.url[c] = rwallpaper.get_url(rwallpaper, data, c)
                    if rwallpaper.url[c] then
                        rwallpaper.path[c] = cachedir .. '/' .. rwallpaper.get_name(rwallpaper, data, c)
                        util.print_debug('Add ' .. rwallpaper.path[c], id)
                    end
                end
            else
                util.print_info('Faild to fetch json! ' .. stderr, id)
            end
            if async_update then
                rwallpaper.update()
            end
        end)
    end

    local recursion_try = 0
    function rwallpaper.update()
        if rwallpaper.url == nil then
            return false
        else
            if next(rwallpaper.url) == nil then
                -- rwallpaper.url is empty, Net Unreachable
                return false
            end
            local i = next(rwallpaper.url, rwallpaper.using)
            if i == nil then
                i = next(rwallpaper.url, i)
            end
            if rwallpaper.path[i] == nil then
                -- rwallpaper.path[i] is broken
                return false
            end
            rwallpaper.using = i
            if gears.filesystem.file_readable(rwallpaper.path[i]) then
                if util.get_file_size(rwallpaper.path[i]) == 0 then
                    util.print_info('Size 0 ' .. rwallpaper.path[i], id)
                    recursion_try = recursion_try + 1
                    if recursion_try <= util.recursion_try_limit then
                        util.print_info('Recursion try ' .. tostring(recursion_try), id)
                        rwallpaper.update()
                    end
                else
                    util.print_info('Setting ' .. rwallpaper.path[i], id)
                    recursion_try = 0
                    setting(rwallpaper)
                end
            else
                local cmd = string.format("%s %s -o %s", curl, rwallpaper.url[i], rwallpaper.path[i])
                util.print_debug('Download cmd: ' .. cmd, id)
                spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
                    if exit_code == 0 and util.get_file_size(rwallpaper.path[i]) ~= 0 then
                        util.print_debug('Save file to ' .. rwallpaper.path[i], id)
                        util.print_info('Setting ' .. rwallpaper.path[i], id)
                        recursion_try = 0
                        setting(rwallpaper)
                    else
                        util.print_info('Faild to download ' .. rwallpaper.path[i] .. '!' .. stderr, id)
                        os.remove(rwallpaper.path[i])
                        recursion_try = recursion_try + 1
                        if recursion_try <= util.recursion_try_limit then
                            util.print_info('Recursion try ' .. tostring(recursion_try), id)
                            rwallpaper.update()
                        end
                    end
                end)
            end
        end
    end

    function rwallpaper.print_using()
        core.print_using(rwallpaper)
    end

    rwallpaper.timer_info = gears.timer({ timeout=timeout_info, autostart=true, callback=rwallpaper.update_info })
    rwallpaper.timer_info:emit_signal('timeout')

    return rwallpaper
end

-- LocalWallPaper: Use images in the given dicrectory
function core.get_localwallpaper(screen, args)
    local lwallpaper = { screen=screen, path=nil, using=nil }
    local args       = args or {}
    local id         = core.assemble_id_with_screen(screen, args.id or 'Dir')
    local dirpath    = args.dirpath or nil
    local filetype   = args.filetype or {'jpg', 'jpeg', 'png'}
    local ls         = args.ls or 'ls -a'
    local filter     = args.filter or '.*'
    local async_update = args.async_update or false
    local setting      = args.setting or function(lwp)
        gears.wallpaper.maximized(lwp.path[lwp.using], lwp.screen, false)
    end

    lwallpaper.id = id
    function lwallpaper.update_info()
        lwallpaper.path = {}
        if type(dirpath) ~= 'string' then
            return false
        end
        local cmd = string.format('%s "%s"', ls, dirpath)
        spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
            if exit_code == 0 then
                local i = 0
                for filename in string.gmatch(stdout,'[^\r\n]+') do
                    if string.match(filename, filter) ~= nil then
                        for _, it in pairs(filetype) do
                            if string.match(filename, '%.' .. it .. '$') ~= nil then
                                i = i + 1
                                lwallpaper.path[i] = dirpath .. '/' .. filename
                                util.print_debug('Add ' .. lwallpaper.path[i], id)
                            end
                        end
                    end
                end
                if async_update then
                    lwallpaper.update()
                end
            end
        end)
    end

    local recursion_try = 0
    function lwallpaper.update()
        if lwallpaper.path == nil then
            lwallpaper.update_info()
        end
        local i = next(lwallpaper.path, lwallpaper.using)
        if i == nil then
            i = next(lwallpaper.path, i)
        end
        if i == nil then
            -- lwallpaper.path is empty
            return false
        end
        lwallpaper.using = i
        if gears.filesystem.file_readable(lwallpaper.path[i]) and util.get_file_size(lwallpaper.path[i]) ~= 0 then
            spawn.easy_async('echo', function(stdout, stderr, reason, exit_code)
                util.print_info('Setting ' .. lwallpaper.path[i], id)
                recursion_try = 0
                setting(lwallpaper)
            end)
        else
            util.print_info('Not readable or size 0: ' .. lwallpaper.path[i], id)
            recursion_try = recursion_try + 1
            if recursion_try <= util.recursion_try_limit then
                util.print_info('Recursion try ' .. tostring(recursion_try), id)
                lwallpaper.update()
            end
        end
    end

    function lwallpaper.print_using()
        core.print_using(lwallpaper)
    end

    lwallpaper.update_info()

    return lwallpaper
end

-- VideoWallPaper: Use videos in the given dicrectory
function core.get_videowallpaper(screen, args)
    local args = args or {}
    local id   = core.assemble_id_with_screen(screen, args.id or 'Video')
    local path = args.path or nil
    -- get_realpath = function(url, realsetting) return path or url; end
    local get_realpath = args.get_realpath or nil
    local xwinwrap = args.xwinwrap or 'xwinwrap'
    local xargs    = args.xargs or {
        --'-d -st -ni -s -nf -b -un -argb -fs -fdt', -- -d, kill twice
        '-b -ov -ni -nf -un -s -st -sp -o 0.9',
        --'-fs -sh rectangle',
    }
    local player = args.player or 'mpv'
    local pargs  = args.pargs or {
        '-wid WID --stop-screensaver=no',
        '--hwdec=auto --hwdec-codecs=all',
        '--no-audio --no-osc --no-osd-bar --no-input-default-bindings',
        '--loop-file',
        --'--no-keepaspect',
    }
    local after_prg = args.after_prg or nil
    local timeout       = args.timeout or 0
    local async_update  = args.async_update or true
    local videowall = { screen=screen, id=id, path=nil, pid=nil }
    local xargs_str = table.concat(xargs, ' ')
    local pargs_str = table.concat(pargs, ' ')
    if type(path) == 'string' then
        if (path:match('^http://') or path:match('^https://')
                or gears.filesystem.file_readable(path)) then
            util.print_info('video wallpaper path: ' .. path, id)
            videowall.path = path
        else
            util.print_error('Lost video wallpaper: ' .. path, id)
        end
    else
        util.print_error('Please set video wallpaper path!', id)
    end

    local function get_cmd() -- catch the changed geometry
        local g   = screen.geometry
        local cmd = string.format("%s -g %dx%d+%d+%d %s -- %s %s",
            xwinwrap, g.width, g.height, g.x, g.y, xargs_str, player, pargs_str)
        return cmd
    end

    --pid: https://awesomewm.org/doc/api/libraries/awful.spawn.html#easy_async_with_shell
    local function realsetting(realpath)
        local cmdline = string.format("%s '%s'", get_cmd(), realpath)
        util.print_info('Set video wallpaper cmdline: ' .. cmdline, id)
        videowall.pid = spawn.easy_async_with_shell(cmdline,
            function(stdout, stderr, reason, exit_code)
                if exit_code == 0 then
                    util.print_info('Exit VideoWallpaper without errors!', id)
                    util.print_info('>> stdout: ' .. stdout, id)
                    util.print_info('>> stderr: ' .. stderr, id)
                else
                    util.print_info('Faild to set VideoWallPaper! ' .. stderr, id)
                    videowall.pid = nil
                end
            end
        )
        util.print_info('Set VideoWallpaper with PID: ' .. videowall.pid, id)
    end

    local function videosetting()
        local script = 'echo'
        if after_prg ~= nil then
            script = string.format([[bash -c "
                i=0
                while [ \$i -lt 20 ]; do
                    if pgrep -f -u $USER -x '%s'; then
                        exit 0
                    fi
                    sleep 2
                    ((i += 2))
                done
                exit 1
            "]], after_prg)
        end
        if videowall.path ~= nil then
            spawn.easy_async_with_shell(script, function(a, b, c, exit_code)
                if after_prg ~= nil then
                    if exit_code == 0 then
                        util.print_debug('Find process: ' .. after_prg, id)
                    else
                        util.print_debug('Cannot find process: ' .. after_prg, id)
                    end
                end
                if type(get_realpath) == 'function' then
                    get_realpath(path, realsetting)
                else
                    realsetting(path)
                end
            end)
        else
            videowall.pid = nil
        end
    end

    function videowall.kill_and_set(setting)
        setting = setting or function()
            videowall.pid = nil
        end
        if videowall.pid ~= nil and videowall.pid > 1 then
            spawn.easy_async(string.format('kill %d', videowall.pid),
                function(stdout, stderr, reason, exit_code)
                    if exit_code == 0 then
                        util.print_debug('Killed PID ' .. videowall.pid, id)
                        setting()
                    else
                        util.print_info('Faild to kill PID ' .. videowall.pid .. '!' .. stderr, id)
                        spawn.easy_async(string.format('kill -9 %d', videowall.pid),
                            function(stdout, stderr, reason, exit_code)
                                if exit_code == 0 then
                                    util.print_debug('Killed -9 PID ' .. videowall.pid, id)
                                else
                                    util.print_info('Faild to kill -9 PID ' .. videowall.pid .. '!' .. stderr, id)
                                end
                                setting()
                            end
                        )
                    end
                end
            )
        else
            setting()
        end
    end

    function videowall.update()
        videowall.kill_and_set(videosetting)
    end

    function videowall.print_using()
        if videowall.path == nil then
            util.print_info('Using VideoWallpaper nil', id)
            naughty.notify({ title = 'Using VideoWallpaper nil' })
        else
            util.print_info('Using VideoWallpaper ' .. videowall.path, id)
            naughty.notify({ title = 'Using VideoWallpaper ' .. videowall.path })
        end
    end

    function videowall.delete_timer()
        core.delete_timer(videowall, 'timer')
    end

    if videowall.path ~= nil then
        if timeout > 0 then
            videowall.timer = gears.timer({ timeout=timeout, autostart=true, callback=videowall.update })
        end
        if async_update then
            videowall.update()
        end
    end

    return videowall
end

return core
