---------------------------------------------------------------------------
--
--  menu module for away, tools to build awful.menu
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local awful = require("awful")
local menubar = require("menubar")
local mb_icon_theme = require("menubar.icon_theme")
local utilloaded, util = pcall(require, "away.util")
local pairs, type, setmetatable = pairs, type, setmetatable
local table = { insert=table.insert, sort=table.sort }
local string = { byte=string.byte, format = string.format }

-- @attr osi_wm_name: Name of the WM for the OnlyShowIn entry
-- @attr items: table items for awful.menu
-- @attr icon_theme: icon theme for application icons
-- @attr categories_name: category name with nice name
local awaymenu = {
    osi_wm_name="", items=nil, icon_theme=nil,
    categories_name={
        multimedia="影音",
        development="开发",
        education="教育",
        games="游戏",
        graphics="图像",
        office="办公",
        internet="互联网",
        settings="设置",
        tools="系统",
        utility="工具",
    },
    mt = {},
}

-- Look up an image file based on a given icon name and icon theme
-- @param i icon name
-- @param theme icon theme
function awaymenu.find_icon(i, theme)
    local it = theme or awaymenu.icon_theme
    return menubar.utils.lookup_icon(i) or mb_icon_theme(it):find_icon_path(i)
end

-- Configure menubar categories name with nice name
-- @param names category nice names table
function awaymenu.menubar_nice_category_name(names)
    local names = names or awaymenu.categories_name
    for k, v in pairs(menubar.menu_gen.all_categories) do
        if names[k] ~= nil then
            menubar.menu_gen.all_categories[k].name = names[k]
        end
    end
end

-- parse all visible menu entries (see menu_gen.generate result)
-- @return table items
-- ref: https://github.com/lcpz/awesome-freedesktop/blob/master/menu.lua
function awaymenu._parse_entries(entries)
    local _items = {}
    if utilloaded then
        util.print_debug('Parse all visible menu entries.')
    end
    -- Set category and icon
    for k, v in pairs(menubar.menu_gen.all_categories) do
        _items[k] = { k, {}, awaymenu.find_icon(v.icon_name) }
    end
    -- Get items table
    for _, v in pairs(entries) do
        if _items[v.category] ~= nil then
            table.insert(_items[v.category][2], { v.name, v.cmdline, v.icon })
            util.print_debug(string.format('Entry: %s,%s, %s, %s', v.name, v.cmdline, v.icon, v.Name))
        end
    end
    local items = {}
    local sortfun = function (a, b)
        return string.byte(a[1]) < string.byte(b[1])
    end
    for _, v in pairs(_items) do
        if #v[2] > 0 then
            --Sort entries alphabetically (by name)
            table.sort(v[2], sortfun)
            -- Replace category name with nice name
            if awaymenu.categories_name[v[1]] ~= nil then
                v[1] = awaymenu.categories_name[v[1]]
            end
            -- get used categories
            table.insert(items, v)
        end
    end
    -- Sort categories alphabetically
    table.sort(items, sortfun)
    return items
end

-- use menubar.menu_gen to generate items for awful.menu
-- @param args.osi_wm_name Name of the WM for the OnlyShowIn entry
-- @param args.icon_theme icon theme for application icons
-- @param args.categories_name category name with nice name
function awaymenu.init(args)
    local args   = args or {}
    awaymenu.osi_wm_name = args.osi_wm_name or ""
    awaymenu.icon_theme = args.icon_theme or nil
    if args.categories_name then
        awaymenu.categories_name = args.categories_name
    end
    local awesome_wm_name = menubar.utils.wm_name -- save old
    menubar.utils.wm_name = awaymenu.osi_wm_name
    menubar.menu_gen.generate(function(entries) -- callback for async
        menubar.utils.wm_name = awesome_wm_name -- restore old
        awaymenu.items = awaymenu._parse_entries(entries)
    end)
end

-- add menu theme for each entry, even entries in submenu
-- fix multi screens with different dpi and menu width, height, etc.
-- ref: awful.menu:add(args,..) args.theme;
-- ref: awful.menu:exec(num, ...), menu.new(cmd, self), cmd is table, add cmd.theme
-- @param items table of entry { text, cmd, icon }. If cmd is table, it is sub-items
-- @param theme menu theme, like { width=120, height=20, etc. }
-- @return new items table
function awaymenu._copy_add_sub_theme(items, theme)
    local newit = {}
    for k, _oldv in pairs(items) do
        local v = {} -- copy _oldv
        for i, _ov in pairs(_oldv) do
            v[i] = _ov
        end
        local cmd = v[2] or v.cmd
        if utilloaded then
            util.print_debug(string.format("k=%s, text=%s, cmd=%s, icon=%s",
                k, v[1] or v.text, cmd, v[3] or v.icon))
        end
        if type(cmd) == "table" then
            cmd = awaymenu._copy_add_sub_theme(cmd, theme)
        end
        if v[2] ~= nil then
            v[2] = cmd
        else
            v.cmd = cmd
        end
        v.theme = theme -- add theme
        --util.print_debug(string.format("k=%s, text=%s: height=%s, width=%s, font=%s",
        --    k, v[1] or v.text, theme.height, theme.width, theme.font))
        newit[k] = v
    end
    return newit
end

-- Generate a away menupopup if needed
function awaymenu:_generate()
    if self.awful_menupopup == nil or not self.complete then
        if utilloaded then
            util.print_info(string.format(
                'Get menupopup theme: height=%s, width=%s, font=%s',
                self.theme.height, self.theme.width, self.theme.font
            ))
            util.print_info("Adding theme to all entries ...")
        end
        local before = awaymenu._copy_add_sub_theme(self.before, self.theme)
        local items = awaymenu._copy_add_sub_theme(awaymenu.items or {
                { "menu items?", function() end },
            }, self.theme)
        local after = awaymenu._copy_add_sub_theme(self.after, self.theme)
        if awaymenu.items ~= nil then
            self.complete = true
            if utilloaded then
                util.print_info('Generating complete menupopup ...')
            end
        else
            if utilloaded then
                util.print_info('Generating incomplete menupopup ...')
            end
        end
        if self.awful_menupopup ~= nil then -- incomplete existing one
            self.awful_menupopup:hide()
            self.awful_menupopup = nil
        end
        self.awful_menupopup = awful.menu({ items=before, theme=self.theme })
        for _, v in pairs(items) do
            self.awful_menupopup:add(v)
        end
        for _, v in pairs(after) do
            self.awful_menupopup:add(v)
        end
        setmetatable(self, self.awful_menupopup)
    end
end

-- Show a away menupopup
function awaymenu:show()
    self:_generate()
    self.awful_menupopup:show()
end

-- Hide a away menupopup
function awaymenu:hide()
    self:_generate()
    self.awful_menupopup:hide()
end

-- Toggle a away menupopup
function awaymenu:toggle()
    self:_generate()
    self.awful_menupopup:toggle()
end

-- Update a away menupopup
-- @param args.theme see awaymenu.new
-- @param args.before see awaymenu.new
-- @param args.after see awaymenu.new
-- @param args.skip_items skip to update awaymenu.items or not, default false
function awaymenu:update(args)
    local args = args or {}
    self.theme = args.theme or self.theme
    self.before = args.before or self.before
    self.after = args.after or self.after
    if not args.skip_items then
        local awesome_wm_name = menubar.utils.wm_name -- save old
        menubar.utils.wm_name = awaymenu.osi_wm_name
        menubar.menu_gen.generate(function(entries) -- callback for async
            menubar.utils.wm_name = awesome_wm_name -- restore old
            awaymenu.items = awaymenu._parse_entries(entries)
        end)
    end
    if self.awful_menupopup ~= nil then -- existing one
        self.awful_menupopup:hide()
    end
    self.awful_menupopup = nil
    self.complete = false
end

-- use awful.menu to generate menupopup
-- (lazy evaluation, wait for awaymenu.items)
-- @param args.theme for awful.menu args.theme, like:
--     theme.height and theme.width, theme.font, etc.
--     see: https://awesomewm.org/doc/api/libraries/awful.menu.html#new
-- @param args.before entries before awaymenu.items
-- @param args.after entries after awaymenu.items
-- @return away menupopup
function awaymenu.new(args)
    local args = args or {}
    return {
        theme  = args.theme or {},
        before = args.before or {},
        after  = args.after or {},
        awful_menupopup = nil,
        complete = false,
        _generate = awaymenu._generate,
        toggle = awaymenu.toggle,
        hide = awaymenu.hide,
        show = awaymenu.show,
        update = awaymenu.update,
    }
end

function awaymenu.mt:__call(...)
    return awaymenu.new(...)
end

return setmetatable(awaymenu, awaymenu.mt)
