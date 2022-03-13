---------------------------------------------------------------------------
--
--  Wallpaper module for away: away.wallpaper
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util    = require("away.util")
local core    = require("away.wallpaper.core")
local gears   = require("gears")

local os    = { time = os.time }
local math  = { randomseed = math.randomseed, random = math.random }
local table = { insert = table.insert }
local next, type, tonumber, tostring = next, type, tonumber, tostring

local wallpaper = {}

wallpaper.available = {
    ['local'] = core.get_localwallpaper,
    ['360chrome'] = require("away.wallpaper.360chrome"),
    ['baidu'] = require("away.wallpaper.baidu"),
    ['bing'] = require("away.wallpaper.bing"),
    ['nationalgeographic'] = require("away.wallpaper.nationalgeographic"),
    ['spotlight'] = require("away.wallpaper.spotlight"),
    ['wallhaven'] = require("away.wallpaper.wallhaven"),
    -- Need to sign up
    -- unsplash : https://unsplash.com/documentation
    -- -- client_id, curl xxx -d ''
    -- pixabay : https://pixabay.com/api/docs/
    -- -- key, orientation
}

function wallpaper.turn_on_update_by_tag(wp)
    local nums = #wp.screen.tags
    local id = core.assemble_id_with_screen(wp.screen, 'wallpaper')
    if nums == 0 then
        util.print_error('No tags to do selected signal! ' ..
            'Please check your rc.lua, ' ..
            'and set wallpaper after tags are created!', id)
        wp.update_by_tag = false
    else
        util.print_debug(tostring(nums) .. ' tags to do selected signal.', id)
        for _, tag in pairs(wp.screen.tags) do
            util.print_debug('Done for tag '.. tag.name, id)
            tag:connect_signal("property::selected", function (t)
                if not t.selected then
                    -- selected -> not selected
                    util.print_debug('Tag ' .. t.name .. ' not selected.', id)
                    return
                end
                -- not selected -> selected
                util.print_info('Update as ' .. t.name .. ' is selected.', id)
                wp.update()
        end)
        end
        wp.update_by_tag = true
    end
end

-- Solo Wallpaper
function wallpaper.get_solowallpaper(screen, name, args)
    if wallpaper.available[name] ~= nil then
        args = args or {}
        args.async_update = true
        local swp = wallpaper.available[name](screen, args)
        local timeout = args.timeout or 60
        swp.timer = gears.timer({ timeout=timeout, autostart=true, callback=swp.update })
        function swp.delete_timer()
            core.delete_timer(swp, 'timer')
            core.delete_timer(swp, 'timer_info')
        end
        if args.update_by_tag then
            wallpaper.turn_on_update_by_tag(swp)
        end
        return swp
    else
        return nil
    end
end

-- MISC Wallpaper
function wallpaper.get_miscwallpaper(screen, margs, candidates)
    local id      = core.assemble_id_with_screen(screen, 'MISC')
    local mwp     = { screen=screen, id=id, members={}, using=nil }
    local timeout = margs.timeout or 60
    local random  = margs.random or false

    if type(candidates) ~= 'table' then
        util.print_error('Need table of candidates!', id)
        return nil
    end
    local candidates_on = {}
    local i, j, name, weight, args
    for i=1,#candidates do
        name, weight = candidates[i].name, tonumber(candidates[i].weight)
        if weight and weight > 0 and wallpaper.available[name] ~= nil then
            table.insert(candidates_on, candidates[i])
        end
    end
    if #candidates_on < 1 then
        util.print_error('Need at least one candidate!', id)
        return nil
    end
    mwp.using = 1
    if random then
        math.randomseed(os.time())
        mwp.using = math.random(1, #candidates_on)
    end
    for i=1,#candidates_on do
        name, args = candidates[i].name, candidates[i].args or {}
        weight = tonumber(candidates[i].weight)
        if i == mwp.using then
            args.async_update = true
            -- mwp.using rise with weight
            mwp.using = #mwp.members + 1
        else
            args.async_update = false
        end
        wp = wallpaper.available[name](screen, args)
        if wp then
            for j=1,weight do
                table.insert(mwp.members, wp)
            end
        end
    end
    if #mwp.members < 1 then
        util.print_error('Need at least one member!', id)
        return nil
    end

    local recursion_try = 0
    function mwp.update()
        if random then
            mwp.using = math.random(1,#mwp.members)
        else
            mwp.using = next(mwp.members, mwp.using)
            if mwp.using == nil then
                mwp.using = next(mwp.members, nil)
            end
        end
        local wall = mwp.members[mwp.using]
        if wall and wall.update() ~= false then
            recursion_try = 0
            -- Restart the timer, correct timeout
            mwp.timer:again()
        else
            recursion_try = recursion_try + 1
            if recursion_try <= util.recursion_try_limit then
                util.print_info('Recursion try ' .. tostring(recursion_try), id)
                mwp.update()
            end
        end
    end

    function mwp.print_using()
        local wall = mwp.members[mwp.using]
        wall.print_using()
    end

    mwp.timer = gears.timer({ timeout=timeout, autostart=true, callback=mwp.update })
    function mwp.delete_timer()
        core.delete_timer(mwp, 'timer')
        for i, w in pairs(mwp.members) do
            core.delete_timer(w, 'timer_info')
        end
    end

    if margs.update_by_tag then
        wallpaper.turn_on_update_by_tag(mwp)
    end

    return mwp
end

-- Video Wallpaper
wallpaper.get_videowallpaper = core.get_videowallpaper
wallpaper.get_bilivideowallpaper = require('away.wallpaper.bilivideo')

return wallpaper
